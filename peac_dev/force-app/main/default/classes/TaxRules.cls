/**
 * @description       : This class is used to generate tax matrix for a given record asynchronously.
 * @author            :
 * @group             :
 * @last modified on  : 02-20-2025
 * @last modified by  : lvang@northteq.com
 **/
global class TaxRules {
    global class TaxRulesException extends Exception { }
    static Map<String, Set<String> > objectQueryFieldsMap = new Map<String, Set<String> >();

    /**
     * @description : This method is used to generate tax matrix for a given record using future.
     * @author
     * @param recordId
     **/
    @future
    webService static void generateTaxMatrixAsynchronous(String recordId) {
        String error = 'Tax Matrix generated successfully.';
        String errorDetails;
        try {
            generateTaxMatrix(recordId);
        }catch (Exception e) {
            error = e.getMessage();
            errorDetails = e.getStackTraceString() + '';
            system.debug(error);
            System.debug(errorDetails);
        }
        updateParent(recordId, error, errorDetails);

    }


    /**
     * @description : This method is used to generate tax matrix for a given record using future.
     * @author
     * @param recordId
     **/
    @future
    public static void generateTaxMatrixFuture(String recordId, String childRecordIdsJSON) {
        String error = 'Tax Matrix generated successfully.';
        String errorDetails;
        Map<String, Set<Id> > childRecordIds = ( Map<String, Set<Id> >) JSON.deserialize(childRecordIdsJSON,  Map<String, Set<Id> >.class);
        try {
            generateTaxMatrix(recordId, childRecordIds);
        }catch (Exception e) {
            error = e.getMessage();
            errorDetails = e.getStackTraceString() + '';
            system.debug(error);
            System.debug(errorDetails);
        }
        updateParent(recordId, error, errorDetails);
    }


    /**
     * @description : This method is used to generate tax matrix for a given record from flow.  no bulk processing!!!!
     * @author
     * @param objIds
     **/
    @InvocableMethod(label='Generate Tax Matrix')
    global static void runAutoGenerate(List <Id> objIds) {
        if (!objIds.isEmpty () && objIds.size () == 1) {
            SObject parent = Schema.getGlobalDescribe().get(TaxRulesHelper.getSettings().getParentObject()).newSObject();
            parent.Id = objIds[0];
            parent.put(TaxRulesHelper.getSettings().getParentTaxCalculationBeginField(), System.now());
            parent.put(TaxRulesHelper.getSettings().getParentTaxCalculationInProgressField(), true);
            parent.put(TaxRulesHelper.getSettings().getParentTaxCalculationSuccessfulField(), true);
            update parent;

            if (TaxRulesHelper.getSettings().getUsePlatformEventInsteadOfFuture ()) {
                TaxRulesHelper.generateTaxMatrixPlatformEvent(objIds[0], 'Submitted');
            } else {
                generateTaxMatrixAsynchronous(objIds[0]);
            }
        }
    }

    /**
     * @description
     * @author
     * refactored by lvang@northteq.com | 02-20-2025
     * @param recordId
     **/
    public static void generateTaxMatrix(String recordId){
        generateTaxMatrix(recordId, null);
    }

    /**
     * @description
     * @author lvang@northteq.com | 02-20-2025
     * @param recordId
     * @param childRecordIds
     **/
    public static void generateTaxMatrix(String recordId, Map<String, Set<Id> > childRecordIds){
        Set<String> states = new Set<String>();
        Set<Id> ruleConfigIds = new Set<Id>();
        Set<Id> allTrueRuleIds = new Set<Id>();
        Map<Id, List<Id> > recTrueRuleIdsMap = new Map<Id, List<Id> >();
        Map<Id, List<Tax_Rule__c> > taxRuleMap = new Map<Id, List<Tax_Rule__c> >();
        Map<Id, TaxValues> recordTaxValuesMap = new Map<Id, TaxValues>();
        Map<Id, SObject> recordMap = new Map<Id, SObject>();
        Integer counter = 1;
        String invalidRecords = '';
        Set<Id> recIds = new Set<Id> { recordId };
        List<Tax_Object__mdt> childTaxObjects  = TaxRulesHelper.getSettings().getChildTaxObjects();
        List<Tax_Object__mdt> queuedChildTaxObjs = new List<Tax_Object__mdt>();// SAL-5860 Misael Romero

        if (TaxRulesHelper.getSettings().getParentTaxObject() == null) {
            throw new TaxRulesException('Please set up a Taxable Object with Object = "' + TaxRulesHelper.getSettings().getParentObject() + '" and Tax Type = "Regular".');
        }

        objectQueryFieldsMap.put(TaxRulesHelper.getSettings().getParentObject(), new Set<String> {'Name', TaxRulesHelper.getSettings().getParentTaxObject().Tax_State_Field__r.QualifiedApiName});
        for (Tax_Object__mdt childTaxObject : childTaxObjects) {
            String childQuery = TaxRulesHelper.createQueryString(new Set<String> {'Id', childTaxObject.Tax_State_Field__r.QualifiedApiName}, childTaxObject.Object__r.QualifiedApiName, childTaxObject.Lookup_Field_to_Parent__r.QualifiedApiName, recordId);
            if(childRecordIds != null && !childRecordIds.isEmpty() && childRecordIds.get(childTaxObject.Object__r.QualifiedApiName) != null && !childRecordIds.get(childTaxObject.Object__r.QualifiedApiName).isEmpty()){
                system.debug('childTaxObject.Object__r.QualifiedApiName: ' + childTaxObject.Object__r.QualifiedApiName);
                Set<Id> childRecordIdSet = childRecordIds.get(childTaxObject.Object__r.QualifiedApiName);
                system.debug('childRecordIdSet: ' + childRecordIdSet);
                childQuery += ' AND Id IN (';
                for(Id cId : childRecordIdSet){
                    childQuery += '\'' + cId + '\',';
                }
                childQuery = childQuery.removeEnd(',');
                childQuery += ')';
                // SAL-5860 Misael Romero
            List<SObject> childRecords = Database.query(childQuery);

            for (SObject child : childRecords) {
                recIds.add(child.Id);

                if (childTaxObject.Tax_State_Field__r.QualifiedApiName != null){
                    states.add((String) child.get(childTaxObject.Tax_State_Field__r.QualifiedApiName));
                }
            }
                system.debug('recIds: ' + recIds);
                system.debug('childQuery: ' + childQuery);

            objectQueryFieldsMap.put(childTaxObject.Object__r.QualifiedApiName, new Set<String> {'Name'});
                queuedChildTaxObjs.add(childTaxObject);
            }
            
        }
        String recordQuery = TaxRulesHelper.createQueryString(recordId, objectQueryFieldsMap, TaxRulesHelper.getSettings().getParentTaxObject());
        SObject record = Database.query(recordQuery);
        states.add((String) record.get(TaxRulesHelper.getSettings().getParentTaxObject().Tax_State_Field__r.QualifiedApiName));
        List<Tax_Rule__c> taxRules = [
            SELECT Rule_Config__c
            FROM Tax_Rule__c
            WHERE Rule_Config__c != null
            AND State__c IN : states
        ];
        for (Tax_Rule__c tr : taxRules){
            ruleConfigIds.add(tr.Rule_Config__c);
        }
        TCRE.RuleEngine re = new TCRE.RuleEngine();
        re.logicObjectIds = recIds;
        re.ruleConfigIds = ruleConfigIds;
        re.ruleObjectType = Tax_Rule__c.getSObjectType().getDescribe().getName();
        re.TestRuleConditions();
	
        for (Id recId : re.ruleResults.keySet()) {
            List<Id> trueRuleIds = new List<Id>();
            Map<Id, Boolean> ruleResults = re.ruleResults.get(recId);

            for (Id ruleId : ruleResults.keySet()) {
                if (ruleResults.get(ruleId)) {
                    trueRuleIds.add(ruleId);
                    allTrueRuleIds.add(ruleId);
                }
            }

            recTrueRuleIdsMap.put(recId, trueRuleIds);
        }

        taxRules = [
            SELECT Rule_Config__c,
            Rule_Config__r.TCRE__SObject_Name__c,
            City__c,
            Description__c,
            Rate_Code_to_Use__c,
            State__c,
            Tax_Basis_Field__c,
            State_Rate_Code_to_Use__c,
            County_Rate_Code_to_Use__c,
            TCounty_Rate_Code_to_Use__c,
            City_Rate_Code_to_Use__c,
            TCity_Rate_Code_to_Use__c,
            Tax_Type__c,
            State_Misc_Code__c,
            County_Misc_Code__c,
            City_Misc_Code__c,
            State_Late_Charge_Code__c,
            County_Late_Charge_Code__c,
            City_Late_Charge_Code__c
            FROM Tax_Rule__c
            WHERE Rule_Config__c IN : allTrueRuleIds
        ];

        for (Tax_Rule__c taxRule : taxRules) {
            List<Tax_Rule__c> trList = taxRuleMap.get(taxRule.Rule_Config__c);

            if (trList == null) {
                trList = new List<Tax_Rule__c>();
                taxRuleMap.put(taxRule.Rule_Config__c, trList);
            }

            trList.add(taxRule);

            Set<String> queryFields = objectQueryFieldsMap.get(taxRule.Rule_Config__r.TCRE__SObject_Name__c);

            if (queryFields == null) {
                queryFields = new Set<String>();
                queryFields.add('Name');
                objectQueryFieldsMap.put(taxRule.Rule_Config__r.TCRE__SObject_Name__c, queryFields);
            }

            queryFields.add(taxRule.Tax_Basis_Field__c);
        }
        recordQuery = TaxRulesHelper.createQueryString(recordId, objectQueryFieldsMap, TaxRulesHelper.getSettings().getParentTaxObject());
        record = Database.query(recordQuery);
        recordMap.put(recordId, record);

        TaxValues taxValues = new TaxValues();
        taxValues.state = (String) record.get(TaxRulesHelper.getSettings().getParentTaxObject().Tax_State_Field__r.QualifiedApiName);
        taxValues.county = (String) record.get(TaxRulesHelper.getSettings().getParentTaxObject().Tax_County_Field__r.QualifiedApiName);
        taxValues.city = (String) record.get(TaxRulesHelper.getSettings().getParentTaxObject().Tax_City_Field__r.QualifiedApiName);
        taxValues.recordName = (String) record.get('Name');
        recordTaxValuesMap.put(recordId, taxValues);

        for (Tax_Object__mdt childTaxObject : queuedChildTaxObjs) {
            String childQuery = TaxRulesHelper.createQueryString(recordId, objectQueryFieldsMap, childTaxObject);

            if(childRecordIds != null && !childRecordIds.isEmpty() && childRecordIds.get(childTaxObject.Object__r.QualifiedApiName) != null && !childRecordIds.get(childTaxObject.Object__r.QualifiedApiName).isEmpty()){
                Set<Id> childRecordIdSet = childRecordIds.get(childTaxObject.Object__r.QualifiedApiName);
                childQuery += ' AND Id IN (';
                for(Id cId : childRecordIdSet){
                    childQuery += '\'' + cId + '\',';
                }
                childQuery = childQuery.removeEnd(',');
                childQuery += ')';
            }

            List<SObject> childRecords = Database.query(childQuery);

            for (SObject child : childRecords) {
                recordMap.put(child.Id, child);

                taxValues = new TaxValues();
                taxValues.state = (String) (childTaxObject.Tax_State_Field__r.QualifiedApiName == null ? record.get(TaxRulesHelper.getSettings().getParentTaxObject().Tax_State_Field__r.QualifiedApiName) :
                                            child.get(childTaxObject.Tax_State_Field__r.QualifiedApiName));
                taxValues.county = (String) (childTaxObject.Tax_County_Field__r.QualifiedApiName == null ? record.get(TaxRulesHelper.getSettings().getParentTaxObject().Tax_County_Field__r.QualifiedApiName) :
                                             child.get(childTaxObject.Tax_County_Field__r.QualifiedApiName));
                taxValues.city = (String) (childTaxObject.Tax_City_Field__r.QualifiedApiName == null ? record.get(TaxRulesHelper.getSettings().getParentTaxObject().Tax_City_Field__r.QualifiedApiName) : child.get(childTaxObject.Tax_City_Field__r.QualifiedApiName));
                taxValues.parentId = (String) child.get(childTaxObject.Lookup_Field_to_Parent__r.QualifiedApiName);
                taxValues.recordName = (String) child.get('Name');
                recordTaxValuesMap.put(child.Id, taxValues);
            }
        }

        Set<String> rateQueryFields = new Set<String>();
        rateQueryFields.add(TaxRulesHelper.getSettings().getRateStateField());
        rateQueryFields.add(TaxRulesHelper.getSettings().getRateCountyField());
        rateQueryFields.add(TaxRulesHelper.getSettings().getRateCityField());
        rateQueryFields.add(TaxRulesHelper.getSettings().getRateCodeField());
        rateQueryFields.add(TaxRulesHelper.getSettings().getStateTaxRateField());
        rateQueryFields.add(TaxRulesHelper.getSettings().getCountyTaxRateField());
        rateQueryFields.add(TaxRulesHelper.getSettings().getTCountyTaxRateField());
        rateQueryFields.add(TaxRulesHelper.getSettings().getCityTaxRateField());
        rateQueryFields.add(TaxRulesHelper.getSettings().getTCityTaxRateField());

        String rateQuery = TaxRulesHelper.createQueryString(rateQueryFields, TaxRulesHelper.getSettings().getRateObject(), null, null) + ' WHERE ';

        for (Id key : recordTaxValuesMap.keySet()) {
            rateQuery += '(' + TaxRulesHelper.getSettings().getRateStateField() + ' = \'' + recordTaxValuesMap.get(key).state + '\'';
            rateQuery += ' AND ' + TaxRulesHelper.getSettings().getRateCountyField() + ' = \'' + recordTaxValuesMap.get(key).county + '\'';
            rateQuery += ' AND ' + TaxRulesHelper.getSettings().getRateCityField() + ' = \'' + recordTaxValuesMap.get(key).city + '\')';

            if (counter < recordTaxValuesMap.keySet().size())
                rateQuery += ' OR ';

            counter++;
        }

        if (counter == 1){
            return;
        }

        List<SObject> rates = Database.query(rateQuery);
        Map<String, Map<String, Map<String, Map<String, SObject> > > > rateMap = TaxRulesHelper.generateRateMap(rates);

        String taxMatrixQuery = TaxRulesHelper.createQueryString(new Set<String> {'Id'}, 'Tax_Matrix__c', TaxRulesHelper.getSettings().getTaxParentObjectField(), recordId);

        //if child record ids is not null only delete the tax matrix related to the child record
        if(childRecordIds != null && !childRecordIds.isEmpty()){
            taxMatrixQuery += ' AND Tax_Record_Id__c IN (';
            for(String childObject : childRecordIds.keySet()){
                for(Id cId : childRecordIds.get(childObject)){
                    taxMatrixQuery += '\'' + cId + '\',';
                }
            }
            taxMatrixQuery = taxMatrixQuery.removeEnd(',');
            taxMatrixQuery += ')';
        }
        List<Tax_Matrix__c> taxMatrices = Database.query(taxMatrixQuery);
        if (taxMatrices.size() > 0) {
            try {
                delete taxMatrices;
            } catch (DmlException e) {

            }
        }
        taxMatrices = new List<Tax_Matrix__c>();

        for (Id recId : re.ruleResults.keySet()) {
            taxValues = recordTaxValuesMap.get(recId);
            if (!taxValues.isValid())
                invalidRecords += taxValues.recordName + ',\n';
        }

        if (String.isNotEmpty(invalidRecords)) {
            invalidRecords = 'Please populate Tax Jurisdiction for the following records first:\n' + invalidRecords;
            invalidRecords = invalidRecords.left(invalidRecords.length() - 2);
            throw new TaxRulesException(invalidRecords);
        }
        List<SObject> updateRecordList = new List<SObject>();
        for (Id recId : re.ruleResults.keySet()) {
            SObject rec = recordMap.get(recId);
            TaxRulesHelper.clearTaxObjectFields(rec, TaxRulesHelper.getSettings().getTaxObjects(rec.getSObjectType().getDescribe().getName()));
            for (Id ruleId : recTrueRuleIdsMap.get(recId)) {
                for (Tax_Rule__c tr : taxRuleMap.get(ruleId)) {
                    taxMatrices.add(TaxRulesHelper.createTaxMatrix(rec, tr, recordTaxValuesMap.get(recId), rateMap));
                }
            }
            updateRecordList.add(rec);
        }

        if (taxMatrices.size() > 0)
            insert taxMatrices;
            
        if (updateRecordList.size() > 0){
            update updateRecordList;
        }
   

        if (TaxRulesHelper.getSettings().getUsePlatformEventInsteadOfFuture () && TaxRulesQueueable.running == false ) {
            TaxRulesHelper.generateTaxMatrixPlatformEvent(recordId, 'Completed');
        }
    }


    public static void updateParent(String recordId, String error, String errorDetails) {
        sObject parent = Schema.getGlobalDescribe().get(TaxRulesHelper.getSettings().getParentObject()).newSObject();
        parent.Id = recordId;
        parent.put(TaxRulesHelper.getSettings().getParentGenerateTaxMatrixMessageField(), error);
        parent.put(TaxRulesHelper.getSettings().getParentTaxCalculationCompleteField(), System.now());
        parent.put(TaxRulesHelper.getSettings().getParentTaxCalculationInProgressField(), false);
        parent.put(TaxRulesHelper.getSettings().getParentTaxCalculationSuccessfulField(), errorDetails == null);
        parent.put(TaxRulesHelper.getSettings().getParentTaxCalculationErrorField(), error);
        update parent;
    }


}