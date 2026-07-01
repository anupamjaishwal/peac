public with sharing class PEAC_LeaseFieldsTrackingHandler {
    private static final String METADATA_DEVELOPER_NAME = 'Lease_Opportunity';
    private static final String TRACKER_OBJECT_NAME = 'Opportunity';
    private static final String ACTION_MODIFIED = 'Modified';
    private static final String VALIDATION_CONFIG_NAME = 'Lease Calculate Pricing';
    private static final String PROPOSAL_STAGE = 'Proposal';
    
    private static final String VALIDATION_MESSAGE = 'One or more pricing fields have been modified. Please click Calculate Pricing button before moving to the next stage.';

    // Pricing Error changes start
    private static final String NO_RATE_FOUND_ERROR = 'No rate found for selected Rate Card';
    // Pricing Error changes end
    
    @TestVisible
    private static Boolean isClearingLeasePricingTracking = false;

    private static Set<String> cachedTrackedFields;
    private static Set<String> cachedValidationStages;
    private static Set<String> cachedBypassProfiles;
    private static Map<String, Integer> cachedStageOrderByName;
    
    public static void beforeUpdate(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap, Set<Id> oppsAdvancedStageName) {
        if (isClearingLeasePricingTracking) {
            return;
        }
        
        if (oldMap == null || newMap == null || newMap.isEmpty()) {
            return;
        }
        
        Set<String> trackedFields = getTrackedLeaseFields();
        if (trackedFields.isEmpty()) {
            return;
        }
        
        Map<String, Schema.SObjectField> oppFieldMap = Schema.SObjectType.Opportunity.fields.getMap();
        
        List<Field_Tracker__c> trackersToInsert = new List<Field_Tracker__c>();
        Set<Id> leaseOppIdsForValidation = new Set<Id>();
        Set<Id> leaseOppIdsWithTrackedFieldChange = new Set<Id>();
        Set<Id> leaseOppIdsToQueryTrackers = new Set<Id>();
        Set<String> changedOppFieldKeys = new Set<String>();
        
        for (Opportunity newOpp : newMap.values()) {
            Opportunity oldOpp = oldMap.get(newOpp.Id);
            
            if (oldOpp == null || !isLeaseOpportunity(newOpp)) {
                continue;
            }

            if (!isAtOrAfterProposal(newOpp.StageName)) {
                continue;
            }
            
            Boolean pricingFieldChanged = false;
            
            for (String fieldApi : trackedFields) {
                if (!oppFieldMap.containsKey(fieldApi)) {
                    System.debug('PEAC_LeaseFieldsTrackingHandler invalid metadata field: ' + fieldApi);
                    continue;
                }
                
                if (hasMeaningfulFieldChanged(oldOpp, newOpp, fieldApi)) {
                    pricingFieldChanged = true;
                    changedOppFieldKeys.add(buildOppFieldKey(newOpp.Id, fieldApi));
                }
            }
            
            if (pricingFieldChanged) {
                newOpp.Scored_Field_Modified__c = true;
                newOpp.Payment_Amount__c = null;
                leaseOppIdsWithTrackedFieldChange.add(newOpp.Id);
            }
            
            if (isConfiguredForwardStageMove(oldOpp, newOpp, oppsAdvancedStageName)) {
                leaseOppIdsForValidation.add(newOpp.Id);
            }
        }

        leaseOppIdsToQueryTrackers.addAll(leaseOppIdsWithTrackedFieldChange);
        leaseOppIdsToQueryTrackers.addAll(leaseOppIdsForValidation);

        Map<Id, Set<String>> existingTrackedFieldsByOppId = getExistingLeaseTrackedFieldsByOppId(
            leaseOppIdsToQueryTrackers,
            trackedFields
        );

        // Pricing Error changes start
        Map<Id, Boolean> noRateFoundByOppId = getNoRateFoundPricingErrorByOppId(leaseOppIdsForValidation);
        // Pricing Error changes end

        // Lookup Display Value Tracking - Start
        Map<Id, String> lookupDisplayValueById = getLookupDisplayValueById(oldMap, newMap, changedOppFieldKeys, trackedFields, oppFieldMap);
        // Lookup Display Value Tracking - End
        
        for (Opportunity newOpp : newMap.values()) {
            Opportunity oldOpp = oldMap.get(newOpp.Id);
            
            if (oldOpp == null || !isLeaseOpportunity(newOpp) || !leaseOppIdsWithTrackedFieldChange.contains(newOpp.Id)) {
                continue;
            }
            
            for (String fieldApi : trackedFields) {
                if (!changedOppFieldKeys.contains(buildOppFieldKey(newOpp.Id, fieldApi))) {
                    continue;
                }
                
                Set<String> existingFields = existingTrackedFieldsByOppId.get(newOpp.Id);
                
                if (existingFields == null || !existingFields.contains(fieldApi)) {
                    trackersToInsert.add(
                        createTracker(newOpp.Id, fieldApi, getFieldLabel(oppFieldMap, fieldApi), oldOpp, newOpp, lookupDisplayValueById)
                    );
                }
            }
        }
        
        for (Opportunity newOpp : newMap.values()) {
            Opportunity oldOpp = oldMap.get(newOpp.Id);
            
            if (oldOpp == null || !isLeaseOpportunity(newOpp) || !leaseOppIdsForValidation.contains(newOpp.Id)) {
                continue;
            }
            
            Set<String> existingFields = existingTrackedFieldsByOppId.get(newOpp.Id);
            Boolean hasExistingTracker = existingFields != null && !existingFields.isEmpty();
            
            // Pricing Error changes start
            // Do not block stage movement when latest pricing error contains "No rate found for selected Rate Card" ( for no rate cards also)
            if ((newOpp.Scored_Field_Modified__c == true || hasExistingTracker) && noRateFoundByOppId.get(newOpp.Id) != true) {
                newOpp.addError(VALIDATION_MESSAGE);
            }
            // Pricing Error changes end
        }
        
        if (!trackersToInsert.isEmpty()) {
            Database.insert(trackersToInsert, false);
        }
    }
    
    public static void clearLeasePricingTracking(Set<Id> opportunityIds) {
        if (opportunityIds == null || opportunityIds.isEmpty()) {
            return;
        }
        
        Set<String> trackedFields = getTrackedLeaseFields();
        if (trackedFields.isEmpty()) {
            return;
        }
        
        try {
            isClearingLeasePricingTracking = true;

            Set<Id> oppIds = new Set<Id>();
            oppIds.addAll(opportunityIds);

            Set<String> fieldNames = new Set<String>();
            fieldNames.addAll(trackedFields);

            String objectName = TRACKER_OBJECT_NAME;

            List<Field_Tracker__c> trackersToDelete = [
                SELECT Id
                FROM Field_Tracker__c
                WHERE Opportunity__c IN :oppIds
                AND Object_Name__c = :objectName
                AND Field_Name__c IN :fieldNames
                LIMIT 10000
            ];
            
            if (!trackersToDelete.isEmpty()) {
                delete trackersToDelete;
            }
            
            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            
            for (Id oppId : opportunityIds) {
                oppsToUpdate.add(new Opportunity(
                    Id = oppId,
                    Scored_Field_Modified__c = false,
                    Payment_Amount__c = null
                ));
            }
            
            if (!oppsToUpdate.isEmpty()) {
                update oppsToUpdate;
            }
        } catch (Exception ex) {
            System.debug('PEAC_LeaseFieldsTrackingHandler.clearLeasePricingTracking: ' + ex.getMessage());
        } finally {
            isClearingLeasePricingTracking = false;
        }
    }
    
    private static Boolean isConfiguredForwardStageMove(Opportunity oldOpp, Opportunity newOpp, Set<Id> oppsAdvancedStageName) {
        if (oldOpp == null || newOpp == null) {
            return false;
        }
        
        if (oldOpp.StageName == newOpp.StageName) {
            return false;
        }
        
        if (oppsAdvancedStageName == null || !oppsAdvancedStageName.contains(newOpp.Id)) {
            return false;
        }
        
        Set<String> stageSet = getConfiguredValidationStages();
        if (stageSet.isEmpty()) {
            return false;
        }
        
        if (!stageSet.contains(newOpp.StageName)) {
            return false;
        }
        
        Set<String> bypassProfileSet = getConfiguredBypassProfiles();
        String profileName = newOpp.Opportunity_CurrentUser_Profile__c;
        
        if (String.isNotBlank(profileName) && bypassProfileSet.contains(profileName.trim())) {
            return false;
        }
        
        return true;
    }
    
    private static Map<Id, Set<String>> getExistingLeaseTrackedFieldsByOppId(Set<Id> opportunityIds, Set<String> trackedFields) {
        Map<Id, Set<String>> result = new Map<Id, Set<String>>();
        
        if (opportunityIds == null || opportunityIds.isEmpty() || trackedFields == null || trackedFields.isEmpty()) {
            return result;
        }

        Set<Id> oppIds = new Set<Id>();
        oppIds.addAll(opportunityIds);

        Set<String> fieldNames = new Set<String>();
        fieldNames.addAll(trackedFields);

        String objectName = TRACKER_OBJECT_NAME;

        List<Field_Tracker__c> existingTrackers = [
            SELECT Opportunity__c, Field_Name__c
            FROM Field_Tracker__c
            WHERE Opportunity__c IN :oppIds
            AND Object_Name__c = :objectName
            AND Field_Name__c IN :fieldNames
        ];
        
        for (Field_Tracker__c tracker : existingTrackers) {
            if (tracker.Opportunity__c == null || String.isBlank(tracker.Field_Name__c)) {
                continue;
            }

            if (!result.containsKey(tracker.Opportunity__c)) {
                result.put(tracker.Opportunity__c, new Set<String>());
            }
            
            result.get(tracker.Opportunity__c).add(tracker.Field_Name__c);
        }
        
        return result;
    }

    // New Pricing Changes - Start
    private static Map<Id, Boolean> getNoRateFoundPricingErrorByOppId(Set<Id> opportunityIds) {
        Map<Id, Boolean> result = new Map<Id, Boolean>();

        if (opportunityIds == null || opportunityIds.isEmpty()) {
            return result;
        }

        for (Pricing_Result__c pricingResult : [
            SELECT Opportunity__c, Error_Message__c
            FROM Pricing_Result__c
            WHERE Opportunity__c IN :opportunityIds
            ORDER BY CreatedDate DESC
        ]) {
            if (pricingResult.Opportunity__c == null || result.containsKey(pricingResult.Opportunity__c)) {
                continue;
            }

            result.put(
                pricingResult.Opportunity__c,
                String.isNotBlank(pricingResult.Error_Message__c) &&
                pricingResult.Error_Message__c.contains(NO_RATE_FOUND_ERROR)
            );
        }

        return result;
    }
    // New Pricing Changes - End
    
    private static Set<String> getConfiguredValidationStages() {
        if (cachedValidationStages != null) {
            return cachedValidationStages;
        }

        cachedValidationStages = new Set<String>();

        RescoreIsMandatoryForLoan__c validationInfo = RescoreIsMandatoryForLoan__c.getInstance(VALIDATION_CONFIG_NAME);
        if (validationInfo == null) {
            return cachedValidationStages;
        }

        cachedValidationStages = splitToSet(validationInfo.StageName__c);
        return cachedValidationStages;
    }

    private static Set<String> getConfiguredBypassProfiles() {
        if (cachedBypassProfiles != null) {
            return cachedBypassProfiles;
        }

        cachedBypassProfiles = new Set<String>();

        RescoreIsMandatoryForLoan__c validationInfo = RescoreIsMandatoryForLoan__c.getInstance(VALIDATION_CONFIG_NAME);
        if (validationInfo == null) {
            return cachedBypassProfiles;
        }

        cachedBypassProfiles = splitToSet(validationInfo.ProfileName__c);
        return cachedBypassProfiles;
    }

    private static Set<String> splitToSet(String rawValue) {
        Set<String> values = new Set<String>();
        
        if (String.isBlank(rawValue)) {
            return values;
        }
        
        for (String item : rawValue.split(';')) {
            if (String.isNotBlank(item)) {
                values.add(item.trim());
            }
        }
        
        return values;
    }
    
    private static Boolean isLeaseOpportunity(Opportunity opp) {
        return opp != null && opp.Loan_Record_Type__c != true;
    }
    
    private static Set<String> getTrackedLeaseFields() {
        if (cachedTrackedFields != null) {
            return cachedTrackedFields;
        }

        cachedTrackedFields = new Set<String>();
        
        FieldTrackingForLoan__mdt config = FieldTrackingForLoan__mdt.getInstance(METADATA_DEVELOPER_NAME);
        
        if (config == null || String.isBlank(config.FieldNames__c)) {
            return cachedTrackedFields;
        }
        
        for (String fieldApi : config.FieldNames__c.split(';')) {
            if (String.isNotBlank(fieldApi)) {
                cachedTrackedFields.add(fieldApi.trim());
            }
        }
        
        return cachedTrackedFields;
    }
    
    private static Boolean hasMeaningfulFieldChanged(Opportunity oldOpp, Opportunity newOpp, String fieldApi) {
        if (String.isBlank(fieldApi)) {
            return false;
        }
        
        Object oldValue = oldOpp.get(fieldApi);
        Object newValue = newOpp.get(fieldApi);
        
        if (isBlankValue(oldValue) && isBlankValue(newValue)) {
            return false;
        }

        if (isBlankValue(oldValue) && !isBlankValue(newValue)) {
            return false;
        }
        
        if (!isBlankValue(oldValue) && isBlankValue(newValue)) {
            return true;
        }
        
        return !oldValue.equals(newValue);
    }

    private static Boolean isBlankValue(Object value) {
        if (value == null) {
            return true;
        }

        if (value instanceof String && String.isBlank((String) value)) {
            return true;
        }

        return false;
    }

    private static Boolean isAtOrAfterProposal(String stageName) {
        if (String.isBlank(stageName)) {
            return false;
        }

        Map<String, Integer> stageOrderByName = getStageOrderByName();

        if (!stageOrderByName.containsKey(PROPOSAL_STAGE) || !stageOrderByName.containsKey(stageName)) {
            return false;
        }

        return stageOrderByName.get(stageName) >= stageOrderByName.get(PROPOSAL_STAGE);
    }

    private static Map<String, Integer> getStageOrderByName() {
        if (cachedStageOrderByName != null) {
            return cachedStageOrderByName;
        }

        cachedStageOrderByName = new Map<String, Integer>();

        List<Schema.PicklistEntry> stageValues = Opportunity.StageName.getDescribe().getPicklistValues();

        for (Integer i = 0; i < stageValues.size(); i++) {
            cachedStageOrderByName.put(stageValues[i].getValue(), i);
        }

        return cachedStageOrderByName;
    }
    
    private static Field_Tracker__c createTracker(Id oppId, String fieldApi, String fieldLabel, Opportunity oldOpp, Opportunity newOpp, Map<Id, String> lookupDisplayValueById) {
        return new Field_Tracker__c(
            Object_Name__c = TRACKER_OBJECT_NAME,
            Opportunity__c = oppId,
            Record_Id__c = oppId,
            Field_Label__c = fieldLabel,
            Field_Name__c = fieldApi,
            Action__c = ACTION_MODIFIED,
            // Lookup Display Value Tracking - Start
            Old_Value__c = getDisplayValue(fieldApi, oldOpp.get(fieldApi), lookupDisplayValueById),
            New_Value__c = getDisplayValue(fieldApi, newOpp.get(fieldApi), lookupDisplayValueById)
            // Lookup Display Value Tracking - End
        );
    }

    // Lookup Display Value Tracking - Start
    private static Map<Id, String> getLookupDisplayValueById(
        Map<Id, Opportunity> oldMap,
        Map<Id, Opportunity> newMap,
        Set<String> changedOppFieldKeys,
        Set<String> trackedFields,
        Map<String, Schema.SObjectField> oppFieldMap
    ) {
        Map<Id, String> lookupDisplayValueById = new Map<Id, String>();

        if (oldMap == null || newMap == null || changedOppFieldKeys == null || changedOppFieldKeys.isEmpty() ||
            trackedFields == null || trackedFields.isEmpty() || oppFieldMap == null || oppFieldMap.isEmpty()) {
            return lookupDisplayValueById;
        }

        Map<String, Set<Id>> idsByObjectName = new Map<String, Set<Id>>();

        for (String fieldApi : trackedFields) {
            if (String.isBlank(fieldApi) || !oppFieldMap.containsKey(fieldApi)) {
                continue;
            }

            Schema.DescribeFieldResult fieldDescribe = oppFieldMap.get(fieldApi).getDescribe();

            if (fieldDescribe.getType() != Schema.DisplayType.REFERENCE) {
                continue;
            }

            for (Opportunity newOpp : newMap.values()) {
                if (newOpp == null || !changedOppFieldKeys.contains(buildOppFieldKey(newOpp.Id, fieldApi))) {
                    continue;
                }

                Opportunity oldOpp = oldMap.get(newOpp.Id);

                if (oldOpp == null) {
                    continue;
                }

                collectLookupId(idsByObjectName, oldOpp.get(fieldApi));
                collectLookupId(idsByObjectName, newOpp.get(fieldApi));
            }
        }

        for (String objectName : idsByObjectName.keySet()) {
            Set<Id> recordIds = idsByObjectName.get(objectName);

            if (recordIds == null || recordIds.isEmpty()) {
                continue;
            }

            Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);

            if (objectType == null || !objectType.getDescribe().fields.getMap().containsKey('Name')) {
                continue;
            }

            String queryString = 'SELECT Id, Name FROM ' + objectName + ' WHERE Id IN :recordIds';

            for (SObject recordItem : Database.query(queryString)) {
                lookupDisplayValueById.put((Id) recordItem.get('Id'), String.valueOf(recordItem.get('Name')));
            }
        }

        return lookupDisplayValueById;
    }

    private static void collectLookupId(Map<String, Set<Id>> idsByObjectName, Object lookupValue) {
        if (lookupValue == null) {
            return;
        }

        Id lookupId = (Id) lookupValue;
        String objectName = String.valueOf(lookupId.getSObjectType());

        if (!idsByObjectName.containsKey(objectName)) {
            idsByObjectName.put(objectName, new Set<Id>());
        }

        idsByObjectName.get(objectName).add(lookupId);
    }

    private static String getDisplayValue(String fieldApi, Object fieldValue, Map<Id, String> lookupDisplayValueById) {
        if (fieldValue == null) {
            return null;
        }

        if (fieldValue instanceof Id) {
            String lookupDisplayValue = lookupDisplayValueById != null ? lookupDisplayValueById.get((Id) fieldValue) : null;
            return String.isNotBlank(lookupDisplayValue) ? lookupDisplayValue : String.valueOf(fieldValue);
        }

        return String.valueOf(fieldValue);
    }
    // Lookup Display Value Tracking - End

    private static String getFieldLabel(Map<String, Schema.SObjectField> fieldMap, String fieldApi) {
        if (fieldMap != null && fieldMap.containsKey(fieldApi)) {
            return fieldMap.get(fieldApi).getDescribe().getLabel();
        }
        
        return fieldApi;
    }
    
    private static String buildOppFieldKey(Id oppId, String fieldApi) {
        return String.valueOf(oppId) + ':' + fieldApi;
    }
}