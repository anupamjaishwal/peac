public with sharing class PEAC_DPOfferSaveService {

    private static final String LEASE_OPPORTUNITY_METADATA_NAME = 'Lease_Opportunity';
    private static final String ACTION_INSERT = 'INSERT';
    private static final String ACTION_UPDATE = 'UPDATE';
    private static final String ACTION_DELETE = 'DELETE';

    // PEAC New Pricing Changes - Start
    @AuraEnabled
    public static PEAC_OfferDataResponse getOfferData(Id opportunityId) {
        if (opportunityId == null) {
            throw new AuraHandledException('Opportunity Id is required.');
        }

       Opportunity opp = [SELECT Id, Name, StageName, Purchase_Options__c, Required_Adv_Payments__c, Terms__c, Max_Term_Approved__c, Equipment_Cost__c, Approved_Amount__c, Payment_Amount__c, Rate_Factor__c, Account_Billing_State_Province__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];

       List<Asset__c> assets = [SELECT Id, Name, Equipment_Code__c, Cost__c, Model__c, Serial_Number__c, Opportunity__c FROM Asset__c WHERE Opportunity__c = :opportunityId ORDER BY CreatedDate ASC];

        PEAC_OfferDataResponse response = new PEAC_OfferDataResponse();
        response.opportunityId = opp.Id;
        response.stageName = opp.StageName;
        response.purchaseOption = opp.Purchase_Options__c;
        response.requiredAdvancePayments = opp.Required_Adv_Payments__c;
        response.term = opp.Terms__c;
        response.maxApprovedTerm = opp.Max_Term_Approved__c;
        response.equipmentCost = opp.Equipment_Cost__c;
        response.approvedAmount = opp.Approved_Amount__c;

        // PEAC New Pricing Changes - Start
        // Per Dealer Portal enhancement, offer tab values should come directly from Opportunity.
        response.monthlyPayment = opp.Payment_Amount__c;
        response.rateFactor = opp.Rate_Factor__c;
        // PEAC New Pricing Changes - End

        response.accountBillingState = opp.Account_Billing_State_Province__c;

        response.assets = new List<PEAC_AssetDTO>();
        for (Asset__c assetRec : assets) {
            PEAC_AssetDTO assetDto = new PEAC_AssetDTO();
            assetDto.id = assetRec.Id;
            assetDto.name = assetRec.Name;
            assetDto.equipmentCode = assetRec.Equipment_Code__c;
            assetDto.cost = assetRec.Cost__c;
            assetDto.model = assetRec.Model__c;
            assetDto.serialNumber = assetRec.Serial_Number__c;
            response.assets.add(assetDto);
        }

        response.equipmentCodeOptions = new List<PEAC_PicklistOptionDTO>();
        for (Schema.PicklistEntry pe : Asset__c.Equipment_Code__c.getDescribe().getPicklistValues()) {
            if (pe.isActive()) {
                PEAC_PicklistOptionDTO optionDto = new PEAC_PicklistOptionDTO();
                optionDto.label = pe.getLabel();
                optionDto.value = pe.getValue();
                response.equipmentCodeOptions.add(optionDto);
            }
        }

        return response;
    }
    // PEAC New Pricing Changes - End

    @AuraEnabled(cacheable=true)
    public static List<PEAC_TrackedFieldDTO> getLeasePricingTrackedFields() {
        List<PEAC_TrackedFieldDTO> results = new List<PEAC_TrackedFieldDTO>();

        FieldTrackingForLoan__mdt config =
            FieldTrackingForLoan__mdt.getInstance(LEASE_OPPORTUNITY_METADATA_NAME);

        if (config == null || String.isBlank(config.FieldNames__c)) {
            return results;
        }

        Map<String, Schema.SObjectField> oppFieldMap =
            Schema.SObjectType.Opportunity.fields.getMap();

        for (String rawFieldApi : config.FieldNames__c.split(';')) {
            String fieldApi = rawFieldApi != null ? rawFieldApi.trim() : null;

            if (String.isBlank(fieldApi) || !oppFieldMap.containsKey(fieldApi)) {
                continue;
            }

            Schema.DescribeFieldResult dfr = oppFieldMap.get(fieldApi).getDescribe();

            PEAC_TrackedFieldDTO dto = new PEAC_TrackedFieldDTO();
            dto.objectApiName = 'Opportunity';
            dto.fieldApiName = fieldApi;
            dto.fieldLabel = dfr.getLabel();
            results.add(dto);
        }

        return results;
    }

    @AuraEnabled
    public static PEAC_PricingResultStatusDTO getLatestPricingResultStatus(Id opportunityId) {
        PEAC_PricingResultStatusDTO response = new PEAC_PricingResultStatusDTO();

        if (opportunityId == null) {
            return response;
        }

       List<Pricing_Result__c> pricingResults = [SELECT Id, Name, Status__c, Error_Message__c, CreatedDate FROM Pricing_Result__c WHERE Opportunity__c = :opportunityId ORDER BY CreatedDate DESC LIMIT 1];

        if (pricingResults.isEmpty()) {
            return response;
        }

        Pricing_Result__c latestResult = pricingResults[0];

        response.hasPricingResult = true;
        response.pricingResultId = latestResult.Id;
        response.pricingResultName = latestResult.Name;
        response.pricingResultStatus = latestResult.Status__c;
        response.pricingErrorMessage = latestResult.Error_Message__c;

        return response;
    }

    @AuraEnabled
    public static PEAC_SaveOfferResponse saveOfferChanges(
        Id opportunityId,
        Map<String, Object> opportunityChanges,
        List<PEAC_AssetChangeDTO> assetChanges,
        Boolean shouldStartPricing
    ) {
        PEAC_SaveOfferResponse response = new PEAC_SaveOfferResponse();
        response.success = false;
        response.pricingStarted = false;
        response.didSaveChanges = false;

        if (opportunityId == null) {
            response.message = 'Opportunity Id is required.';
            return response;
        }

        Boolean hasOpportunityChanges =
            opportunityChanges != null && !opportunityChanges.isEmpty();

        Boolean hasAssetChanges =
            assetChanges != null && !assetChanges.isEmpty();

        if (!hasOpportunityChanges && !hasAssetChanges) {
            response.success = true;
            response.message = 'No changes to save.';
            return response;
        }

        Savepoint sp = Database.setSavepoint();

        try {
            Boolean didSaveAssets = false;
            Boolean didSaveOpportunity = false;

            if (hasAssetChanges) {
                didSaveAssets = processAssetChanges(opportunityId, assetChanges);
            }

            if (hasOpportunityChanges) {
                didSaveOpportunity = updateOpportunityChanges(opportunityId, opportunityChanges);
            }

            response.didSaveChanges = didSaveAssets || didSaveOpportunity;

            if (shouldStartPricing == true && response.didSaveChanges == true) {
                NT_PricingOrchestrator.runPricingOrchestrator(new List<Id>{ opportunityId });
                response.pricingStarted = true;
                populateLatestPricingResult(response, opportunityId);
            }

            response.success = true;

            if (!response.didSaveChanges) {
                response.message = 'No valid changes to save.';
            } else if (response.pricingStarted) {
                response.message = 'Changes saved successfully. Pricing calculation has been started.';
            } else {
                response.message = 'Changes saved successfully.';
            }

            return response;

        } catch (Exception ex) {
            Database.rollback(sp);

            response.success = false;
            response.pricingStarted = false;
            response.didSaveChanges = false;
            response.message = ex.getMessage();
            return response;
        }
    }

    private static void populateLatestPricingResult(
        PEAC_SaveOfferResponse response,
        Id opportunityId
    ) {
        if (response == null || opportunityId == null) {
            return;
        }

        List<Pricing_Result__c> pricingResults = [SELECT Id, Name, Status__c, Error_Message__c FROM Pricing_Result__c WHERE Opportunity__c = :opportunityId ORDER BY CreatedDate DESC LIMIT 1];
        
        if (pricingResults.isEmpty()) {
            return;
        }

        Pricing_Result__c latestResult = pricingResults[0];

        response.pricingResultId = latestResult.Id;
        response.pricingResultName = latestResult.Name;
        response.pricingResultStatus = latestResult.Status__c;
        response.pricingErrorMessage = latestResult.Error_Message__c;
    }

    private static Boolean processAssetChanges(
        Id opportunityId,
        List<PEAC_AssetChangeDTO> assetChanges
    ) {
        List<Asset__c> assetsToInsert = new List<Asset__c>();
        List<Asset__c> assetsToUpdate = new List<Asset__c>();
        Set<Id> assetIdsToDelete = new Set<Id>();
        Set<Id> assetIdsToValidate = new Set<Id>();

        for (PEAC_AssetChangeDTO changeDto : assetChanges) {
            if (changeDto == null || String.isBlank(changeDto.action)) {
                continue;
            }

            String action = changeDto.action.trim().toUpperCase();

            if (action == ACTION_INSERT) {
                Asset__c assetToInsert = new Asset__c();
                assetToInsert.Opportunity__c = opportunityId;

                Boolean hasValidFields =
                    applyFieldsToSObject(assetToInsert, changeDto.fields, Asset__c.SObjectType, true);

                if (hasValidFields) {
                    assetsToInsert.add(assetToInsert);
                }

            } else if (action == ACTION_UPDATE) {
                if (changeDto.recordId == null) {
                    throw new AuraHandledException('Asset Id is required for update.');
                }

                assetIdsToValidate.add(changeDto.recordId);

                Asset__c assetToUpdate = new Asset__c(Id = changeDto.recordId);

                Boolean hasValidFields =
                    applyFieldsToSObject(assetToUpdate, changeDto.fields, Asset__c.SObjectType, false);

                if (hasValidFields) {
                    assetsToUpdate.add(assetToUpdate);
                }

            } else if (action == ACTION_DELETE) {
                if (changeDto.recordId == null) {
                    throw new AuraHandledException('Asset Id is required for delete.');
                }

                assetIdsToValidate.add(changeDto.recordId);
                assetIdsToDelete.add(changeDto.recordId);

            } else {
                throw new AuraHandledException('Unsupported asset action: ' + changeDto.action);
            }
        }

        validateAssetsBelongToOpportunity(opportunityId, assetIdsToValidate);

        Boolean didDml = false;

        if (!assetsToInsert.isEmpty()) {
            if (!Asset__c.SObjectType.getDescribe().isCreateable()) {
                throw new AuraHandledException('You do not have permission to create Asset records.');
            }

            SObjectAccessDecision accessDecision =
                Security.stripInaccessible(AccessType.CREATABLE, assetsToInsert);

            List<SObject> recordsToInsert = accessDecision.getRecords();

            if (!recordsToInsert.isEmpty()) {
                insert recordsToInsert;
                didDml = true;
            }
        }

        if (!assetsToUpdate.isEmpty()) {
            if (!Asset__c.SObjectType.getDescribe().isUpdateable()) {
                throw new AuraHandledException('You do not have permission to update Asset records.');
            }

            SObjectAccessDecision accessDecision =
                Security.stripInaccessible(AccessType.UPDATABLE, assetsToUpdate);

            List<SObject> recordsToUpdate = accessDecision.getRecords();

            if (!recordsToUpdate.isEmpty()) {
                update recordsToUpdate;
                didDml = true;
            }
        }

        if (!assetIdsToDelete.isEmpty()) {
            if (!Asset__c.SObjectType.getDescribe().isDeletable()) {
                throw new AuraHandledException('You do not have permission to delete Asset records.');
            }

            List<Asset__c> assetsForDelete = [SELECT Id FROM Asset__c WHERE Id IN :assetIdsToDelete];

            if (!assetsForDelete.isEmpty()) {
                delete assetsForDelete;
                didDml = true;
            }
        }

        return didDml;
    }

    private static Boolean updateOpportunityChanges(
        Id opportunityId,
        Map<String, Object> opportunityChanges
    ) {
        if (opportunityChanges == null || opportunityChanges.isEmpty()) {
            return false;
        }

        if (!Opportunity.SObjectType.getDescribe().isUpdateable()) {
            throw new AuraHandledException('You do not have permission to update Opportunity records.');
        }

        Opportunity oppToUpdate = new Opportunity(Id = opportunityId);

        Boolean hasValidFields =
            applyFieldsToSObject(oppToUpdate, opportunityChanges, Opportunity.SObjectType, false);

        if (!hasValidFields) {
            return false;
        }

        SObjectAccessDecision accessDecision =
            Security.stripInaccessible(AccessType.UPDATABLE, new List<Opportunity>{ oppToUpdate });

        List<SObject> recordsToUpdate = accessDecision.getRecords();

        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
            return true;
        }

        return false;
    }

    private static void validateAssetsBelongToOpportunity(
        Id opportunityId,
        Set<Id> assetIds
    ) {
        if (assetIds == null || assetIds.isEmpty()) {
            return;
        }

        Set<Id> validAssetIds = new Set<Id>();

        for (Asset__c assetRec : [SELECT Id FROM Asset__c WHERE Id IN :assetIds AND Opportunity__c = :opportunityId]) {
            validAssetIds.add(assetRec.Id);
        }

        for (Id assetId : assetIds) {
            if (!validAssetIds.contains(assetId)) {
                throw new AuraHandledException('Asset does not belong to this Opportunity.');
            }
        }
    }

    private static Boolean applyFieldsToSObject(
        SObject targetRecord,
        Map<String, Object> fieldValues,
        Schema.SObjectType objectType,
        Boolean isCreate
    ) {
        if (targetRecord == null || fieldValues == null || fieldValues.isEmpty()) {
            return false;
        }

        Boolean hasAppliedField = false;

        Map<String, Schema.SObjectField> fieldMap =
            objectType.getDescribe().fields.getMap();

        for (String fieldApi : fieldValues.keySet()) {
            if (String.isBlank(fieldApi)) {
                continue;
            }

            String cleanFieldApi = fieldApi.trim();

            if (cleanFieldApi == 'Id') {
                continue;
            }

            if (!fieldMap.containsKey(cleanFieldApi)) {
                continue;
            }

            Schema.DescribeFieldResult dfr =
                fieldMap.get(cleanFieldApi).getDescribe();

            if (isCreate && !dfr.isCreateable()) {
                continue;
            }

            if (!isCreate && !dfr.isUpdateable()) {
                continue;
            }

            Object normalizedValue = normalizeValue(fieldValues.get(fieldApi), dfr);
            targetRecord.put(cleanFieldApi, normalizedValue);
            hasAppliedField = true;
        }

        return hasAppliedField;
    }

    private static Object normalizeValue(
        Object rawValue,
        Schema.DescribeFieldResult dfr
    ) {
        if (rawValue == null) {
            return null;
        }

        if (rawValue instanceof String && String.isBlank((String) rawValue)) {
            return null;
        }

        Schema.DisplayType fieldType = dfr.getType();

        if (fieldType == Schema.DisplayType.Boolean) {
            if (rawValue instanceof Boolean) {
                return rawValue;
            }
            return Boolean.valueOf(String.valueOf(rawValue));
        }

        if (fieldType == Schema.DisplayType.Date) {
            if (rawValue instanceof Date) {
                return rawValue;
            }
            return Date.valueOf(String.valueOf(rawValue));
        }

        if (fieldType == Schema.DisplayType.DateTime) {
            if (rawValue instanceof Datetime) {
                return rawValue;
            }

            String dtString = String.valueOf(rawValue);
            dtString = dtString.replace('T', ' ');

            if (dtString.endsWith('Z')) {
                dtString = dtString.substring(0, dtString.length() - 1);
            }

            return Datetime.valueOf(dtString);
        }

        if (fieldType == Schema.DisplayType.Currency ||
            fieldType == Schema.DisplayType.Double ||
            fieldType == Schema.DisplayType.Percent) {
            if (rawValue instanceof Decimal) {
                return rawValue;
            }
            return Decimal.valueOf(String.valueOf(rawValue));
        }

        if (fieldType == Schema.DisplayType.Integer) {
            if (rawValue instanceof Integer) {
                return rawValue;
            }
            return Integer.valueOf(String.valueOf(rawValue));
        }

        return rawValue;
    }

    public class PEAC_OfferDataResponse {
        @AuraEnabled public Id opportunityId { get; set; }
        @AuraEnabled public String stageName { get; set; }
        @AuraEnabled public String purchaseOption { get; set; }
        @AuraEnabled public Decimal requiredAdvancePayments { get; set; }
        @AuraEnabled public Decimal term { get; set; }
        @AuraEnabled public Decimal maxApprovedTerm { get; set; }
        @AuraEnabled public Decimal equipmentCost { get; set; }
        @AuraEnabled public Decimal approvedAmount { get; set; }
        @AuraEnabled public Decimal rateFactor { get; set; }
        @AuraEnabled public Decimal monthlyPayment { get; set; }
        @AuraEnabled public String accountBillingState { get; set; }
        @AuraEnabled public List<PEAC_AssetDTO> assets { get; set; }
        @AuraEnabled public List<PEAC_PicklistOptionDTO> equipmentCodeOptions { get; set; }
    }

    public class PEAC_AssetDTO {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String equipmentCode { get; set; }
        @AuraEnabled public Decimal cost { get; set; }
        @AuraEnabled public String model { get; set; }
        @AuraEnabled public String serialNumber { get; set; }
    }

    public class PEAC_PicklistOptionDTO {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }
    }

    public class PEAC_TrackedFieldDTO {
        @AuraEnabled public String objectApiName { get; set; }
        @AuraEnabled public String fieldApiName { get; set; }
        @AuraEnabled public String fieldLabel { get; set; }
    }

    public class PEAC_AssetChangeDTO {
        @AuraEnabled public String action { get; set; }
        @AuraEnabled public Id recordId { get; set; }
        @AuraEnabled public Map<String, Object> fields { get; set; }
    }

    public class PEAC_PricingResultStatusDTO {
        @AuraEnabled public Boolean hasPricingResult { get; set; }
        @AuraEnabled public Id pricingResultId { get; set; }
        @AuraEnabled public String pricingResultName { get; set; }
        @AuraEnabled public String pricingResultStatus { get; set; }
        @AuraEnabled public String pricingErrorMessage { get; set; }

        public PEAC_PricingResultStatusDTO() {
            hasPricingResult = false;
        }
    }

    public class PEAC_SaveOfferResponse {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public Boolean pricingStarted { get; set; }
        @AuraEnabled public Boolean didSaveChanges { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public Id pricingResultId { get; set; }
        @AuraEnabled public String pricingResultName { get; set; }
        @AuraEnabled public String pricingResultStatus { get; set; }
        @AuraEnabled public String pricingErrorMessage { get; set; }
    }
}