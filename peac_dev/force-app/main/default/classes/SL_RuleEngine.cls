public with sharing class SL_RuleEngine {
    public List<SObject> logicObjects; // List of sObjects to evaluate for data instead of logicObjectIds
    public String logicObjectType; // Type of object being evaluated - required when using logicObjects
    public String logicObjectUId; // Unique identifier if records in memory - required when using logicObjects
    public Set<Id> logicObjectIds; // Set of sObject Ids to query to evaluate for data
    public String ruleObjectType; // sObject type with lookup to Rule Configs to evaluate - e.g. Checklist_Item_Template__c

    //returns list of Rules Object Ids mapped to the related Logic Object
    // e.g. Map<OpportunityId, Map<ChecklistTemplateId, TRUE> >
    public Map<Id, Map<Id, Boolean> > ruleResults = new Map<Id, Map<Id, Boolean> >();
    /**
     * @description Global map the links the record to the configs ran and gives a list of the results of the configs ran
     */
    public Map<String, Map<Id, Map<Id, Boolean>>> ruleConditionResult = new Map<String, Map<Id, map<Id, Boolean>>>();
    public Map<String, Map<Id, Boolean> > ruleResultsStr = new Map<String, Map<Id, Boolean> >();
    public Set<Id> ruleConfigIds; // Set of sObject Ids to query to evaluate for data


    public void testRuleConditions() {


        List<String> lookupFields = new List<String>(); // this will be the list ruleObject lookups fields to Rule Configs

        // look for Rule Configs lookup fields on the ruleObjectType
        // current expects only 1 lookup for this type
        // Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        SObject ruleObj = ((SObject)Type.forName(ruleObjectType).newInstance());
        // Map <String, Schema.SObjectField> fieldMap = schemaMap.get(ruleObjectType).getDescribe().fields.getMap();
        Map <String, Schema.SObjectField> fieldMap = ruleObj.getSObjectType().getDescribe().fields.getMap();
        for (Schema.SObjectField f : fieldMap.values()) {
            //is field a reference lookup?
            if (f.getDescribe().getType() == Schema.DisplayType.Reference) {
                //is field referencing the ruleObjectType we want?\
                // System.debug(String.valueOf(f.getDescribe().getReferenceTo()[0]) + ' == \'TCRE__Rule_Config__c');
                if (String.valueOf(f.getDescribe().getReferenceTo()[0]) == 'TCRE__Rule_Config__c') {
                    lookupFields.add(f.getDescribe().getName()); // add lookup field for query and results
                }
            }
        }


        if (lookupFields.size() == 0) {
            throw new ruleEngineException('Rule Object Lookup Field Not Found on sObject Type [' + ruleObjectType + ']');
        }


        //query all Rule Config lookup fields on the ruleObjectType
        String query = 'SELECT Id ';

        for (String lookup : lookupFields) {
            query += ' ,' + lookup;
        }

        query += ' FROM ' + ruleObjectType;


        if (lookupFields.size() > 0) {
            query += ' WHERE ';//Id <> NULL ';

            String lookWhere = '';
            for (String lookup : lookupFields) {
                lookWhere += lookWhere == '' ? lookup + ' <> NULL ' : ' OR ' + lookup + ' <> NULL ';
            }
            query += lookWhere;
        }

        // System.debug('query for rule object =' + String.escapeSingleQuotes(query));
        List<sObject> ruleObjects = Database.query(String.escapeSingleQuotes(query));
        // System.debug('ruleObjects query results = ' + ruleObjects);


        //gather all of the Rule Config Ids
        Set<Id> ruleIds = new Set<Id>();
        for (sObject obj : ruleObjects) {
            // System.debug('obj = ' + obj);
            for (String lookup : lookupFields) {
                if (obj.get(lookup) <> NULL) {
                    ruleIds.add((Id) obj.get(lookup));
                }
            }
        }

        if (ruleConfigIds != null)
            ruleIds = ruleConfigIds;

        // System.debug('ruleIds = ' + ruleIds);

        SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.READABLE,
                [SELECT Id,
                        TCRE__Evaluation_Logic_Picklist__c,
                        TCRE__SObject_Name__c,
                        TCRE__Priority__c,
                        TCRE__Custom_Rule_Evaluation_Logic__c, (
                        SELECT
                                Id,
                                TCRE__Field_Name__c,
                                TCRE__Operator__c,
                                TCRE__Value__c,
                                TCRE__sObject_Override_Apex__c,
                                TCRE__Evaluate_Override_sObject__c
                        FROM TCRE__Rule_Conditions__r ORDER BY CreatedDate ASC
                )
                FROM TCRE__Rule_Config__c
                WHERE Id IN :ruleIds
                ORDER BY TCRE__Priority__c ASC]
        );

        List<TCRE__Rule_Config__c> ruleConfigs = securityDecision.getRecords();
        // System.debug(securityDecision.getRemovedFields());
        if (securityDecision.getRemovedFields().get('TCRE__Rule_Config__c') != null) {
            throw new ruleEngineException('Insufficent read access to fields on Rule Config: ' + securityDecision.getRemovedFields().get('TCRE__Rule_Config__c'));
        }else if (securityDecision.getRemovedFields().get('TCRE__Rule_Condition__c') != null) {
            throw new ruleEngineException('Insufficent read access to fields on Rule Condition: ' + securityDecision.getRemovedFields().get('TCRE__Rule_Condition__c'));
        }


        // System.debug(ruleConfigs);
        // System.debug('ruleConfigs query results = ' + ruleConfigs);

        Map<String, List<TCRE__Rule_Config__c>> objectRulesMap = new Map<String, List<TCRE__Rule_Config__c>>();

        for (TCRE__Rule_Config__c ruleConfig : ruleConfigs) {
            List<TCRE__Rule_Config__c> rules = objectRulesMap.get(ruleConfig.TCRE__SObject_Name__c);

            if (rules == null) {
                rules = new List<TCRE__Rule_Config__c>();
                objectRulesMap.put(ruleConfig.TCRE__SObject_Name__c, rules);
            }

            rules.add(ruleConfig);
        }

        //collect the object from all of the object override classes
        Map<String, Map<Id, List<sObject>>> overrideObjectMap = getOverrideObjectMap(ruleConfigs);


        //what type of logic Object?
        Map<String, List<Id>> objectIdsMap = new Map<String, List<Id>>();

        if (logicObjectIds <> null) { //use logicObjectIds rather than query
            for (Id logicObjectId : logicObjectIds) {
                logicObjectType = String.valueOf(logicObjectId.getSobjectType());
                List<Id> ids = objectIdsMap.get(logicObjectType);

                if (ids == null) {
                    ids = new List<Id>();
                    objectIdsMap.put(logicObjectType, ids);
                }

                ids.add(logicObjectId);

                List<TCRE__Rule_Config__c> rules = objectRulesMap.get(logicObjectType);

                if (rules == null) {
                    rules = new List<TCRE__Rule_Config__c>();
                    objectRulesMap.put(logicObjectType, rules);
                }
            }

        } else {
            objectIdsMap.put(logicObjectType, new List<Id>());
        }

        // System.debug('running objectIdsMap = ' + objectIdsMap);
        for (String logicObjectType : objectIdsMap.keySet()) {
            // System.debug('logicObjectType = ' + logicObjectType);


            if (logicObjectIds <> null) { //use logicObjectIds rather than query
                List<Id> ids = objectIdsMap.get(logicObjectType);
                //query for logicObjects
                //Set<String> queryFields = getQueryFields(ruleConfigs);
                Set<String> queryFields = getQueryFields(objectRulesMap.get(logicObjectType));
                query = '';


                for (String fname : queryFields) {
                    query += ',' + fname;
                }

                query = 'SELECT Id ' + query;
                query += ' FROM ' + logicObjectType + ' ';
                query += ' WHERE Id IN :ids ';

                // System.debug('logicObjects query = ' + String.escapeSingleQuotes(query));

                logicObjects = new List<SObject>();
                try {
                    logicObjects = Database.query(String.escapeSingleQuotes(query)); //NOPMD - multiple queries required since each query in the for loop is for a different object
                } catch (Exception e) {
                    throw new RuleEngineException('ERROR during logicObjects query [' + query + ']: ' + e.getMessage());
                }
            }
            // System.debug(':::::ORIGINAL logicObjects DATA::: = ' + logicObjects);


            /*** Start Rule Evaluation ***/


            // System.debug('running logicObjects = ' + logicObjects);
            for (SObject obj : logicObjects) {
                Map<Id, Boolean> results = new Map<Id, Boolean>();
                Map<Id, Map<Id,Boolean>> configConditionResult = new Map<Id, Map<Id,Boolean>> ();
                // System.debug('~~~ checking obj data = ' + obj);

                if (objectRulesMap.get(logicObjectType) <> null) {
                    for (TCRE__Rule_Config__c conf : objectRulesMap.get(logicObjectType)) {
                        configConditionResult.put(conf.Id, new Map<Id,Boolean>());
                        
                        Boolean ruleState = (conf.TCRE__Evaluation_Logic_Picklist__c == 'Any (OR)' ? false : true);
                        Boolean conditionState = false;

                        String customLogic = conf.TCRE__Custom_Rule_Evaluation_Logic__c;
                        // System.debug('initial custom logic - ' + customLogic);
                        Integer rcCount = 0;

                        // System.debug('conf = ' + conf);
                        for (TCRE__Rule_Condition__c rc : conf.TCRE__Rule_Conditions__r) {
                            rcCount++;
                            Object value = (Object) rc.TCRE__Value__c;

                            //override ruleObjects sObject?
                            if (rc.TCRE__sObject_Override_Apex__c != null) {
                                if (overrideObjectMap.get(rc.TCRE__sObject_Override_Apex__c) != null) {
                                    List<sObject> objList = overrideObjectMap.get(rc.TCRE__sObject_Override_Apex__c).get(obj.Id);
                                    conditionState = true;
                                    for (sObject o : objList) {
                                        // System.debug('%%%% EVALUATING override result object = ' + o);
                                        if(value <> null && ((String) value).startsWith('{!') && ((String) value).endsWith('}')){
                                            // value = parsed api
                                            value = (Object) o.get(((String) value).substringBetween('{!','}'));
                                        }
                                        if (rc.TCRE__Evaluate_Override_sObject__c == 'Any (OR)') {
                                            conditionState |= doCompare(o, rc.TCRE__Field_Name__c, value, rc.TCRE__Operator__c);
                                        } else { // default 'All (AND)'
                                            conditionState &= doCompare(o, rc.TCRE__Field_Name__c, value, rc.TCRE__Operator__c);
                                        }
                                    }
                                }
                            } else { //default rulesObjects
                                if(value <> null && ((String) value).startsWith('{!') && ((String) value).endsWith('}')){
                                    // value = parsed api
                                    value = (Object) obj.get(((String) value).substringBetween('{!','}'));
                                }
                                conditionState = doCompare(obj, rc.TCRE__Field_Name__c, value, rc.TCRE__Operator__c);
                                // if(conditionState && conf.Id == 'a2L4N000001rOnFUAU'){
                                //     // System.debug('condition Id: ' + rc.Id);
                                //     // System.debug('condition: ' + rc);
                                //     // System.debug('conf: ' + conf);
                                // }
                            }
                            configConditionResult.get(conf.Id).put(rc.Id, conditionState);

                            // System.debug('conditionState for this rule evaluated to ' + conditionState);

                            if (conf.TCRE__Evaluation_Logic_Picklist__c == 'Any (OR)') {
                                ruleState = ruleState || conditionState;  // states are ORed together to set rule state
                                if(ruleState){// SAL-6028 Misael Romero
                                    break;
                                }
                            } else if (conf.TCRE__Evaluation_Logic_Picklist__c == 'All (AND)') {
                                ruleState = ruleState && conditionState;  // states are ANDed together to set rule state
                                if(!ruleState){// SAL-6028 Misael Romero
                                    break;
                                }
                            } else if (conf.TCRE__Evaluation_Logic_Picklist__c == 'Custom') {
                                //replace item number with logic boolean
                                // System.debug('custom logic - replacing ' + String.valueOf(rcCount) + ' with ' + String.valueOf(conditionState));
                                //add boundary
                                customLogic = customLogic.replaceAll('\\b' + String.valueOf(rcCount) + '\\b', String.valueOf(conditionState));
                                // System.debug('custom logic update - ' + customLogic);
                            }

                        }// end for rule conditions

                        if (conf.TCRE__Evaluation_Logic_Picklist__c == 'Custom') {
                            // System.debug('BoolEval - custom logic - ' + customLogic);
                            
                            //any remainging numbers?
                            Pattern regex = Pattern.compile('[0-9]');
                            Matcher matches = regex.matcher(customLogic);
                            if (matches.find()) {
                                throw new ruleEngineException('ERROR with custom logic evaluation [' + conf.TCRE__Custom_Rule_Evaluation_Logic__c + '] evaluating to ' + customLogic);
                            }
                            // ruleState = BoolEval.eval(customLogic);
                            ruleState = boolEval(customLogic, obj);
                            // System.debug('final custom logic - ' + ruleState);
                        }

                        // System.debug('FINAL ruleState = ' + ruleState);


                        //do we have a config record where all condition match?
                        if (ruleState == TRUE) {

                            // System.debug('ruleState for conf = TRUE = ' + conf);

                        }

                        // System.debug('adding results = ' + conf.Id);
                        results.put(conf.Id, ruleState);
                        ruleConditionResult.put(obj.Id, configConditionResult);
                    }//end rule Configs

                }
                // System.debug('looking for obj');
                // System.debug('obj.Id = ' + obj.Id);
                // System.debug('results = ' + results);
                // System.debug('ruleResults = ' + ruleResults);
                // System.debug('ruleResultsStr = ' + ruleResultsStr);

                String key;
                if (logicObjectUId == null) {
                    key = obj.Id;
                    // System.debug('putting ' + key + ' = ' + results);
                    ruleResults.put(key, results);
                } else {
                    key = String.valueOf(obj.get(logicObjectUId));
                    // System.debug('putting ' + key + ' = ' + results);
                    ruleResultsStr.put(key, results);
                }

            }//end logicObjects loop
        }//end objectIdsMap loop

        // System.debug('%%%%RETURNING%%%% = ruleResults = ' + ruleResults);
        // System.debug('%%%%RETURNING%%%% = ruleResultsStr = ' + ruleResultsStr);

    }

    private Boolean doCompare(sObject obj, String fieldName, Object condVal, String operator) {

        Boolean conditionState;
        // SAL-6028 Misael Romero
        // String objType = String.valueOf(obj.getSObjectType());

        //describe all fields in the logicObject we are looking at
        // Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        // Map <String, Schema.SObjectField> objFieldMap = schemaMap.get(objType).getDescribe().fields.getMap();
        Map <String, Schema.SObjectField> objFieldMap = obj.getSObjectType().getDescribe().fields.getMap();
        

        Object sObjVal;
        Schema.DisplayType sObjType;
        try {
            // System.debug('fieldName = ' + fieldName);
            if (fieldName.contains('.')) {
                String[] rField = fieldName.split('\\.', 2);
                // System.debug('rField = ' + rField);
                SObject refObj = obj.getSobject(rField[0]);
                // System.debug('obj.getSobject(' + rField[0] + ') = ' + refObj);
                if (refObj == NULL) {
                    //field not returned in query, return null value
                    sObjVal = NULL;
                } else {
                    sObjVal = refObj.get(rField[1]);
                    // System.debug('sObjVal = ' + sObjVal);
                    sObjType = refObj.getSObjectType().getDescribe().fields.getMap().get(rField[1]).getDescribe().getType();
                    // System.debug('sObjType = ' + sObjType);
                }
            } else {
                // System.debug('getting ' + fieldName + ' from obj ' + obj);
                if (obj.get(fieldName) == NULL) {
                    //field not returned in query, return null value
                    sObjVal = NULL;
                } else {
                    sObjVal = obj.get(fieldName);
                    sObjType = objFieldMap.get(fieldName).getDescribe().getType();
                }
            }
        } catch (Exception e) {
            throw new ruleEngineException('ERROR looking for field [' + fieldName + '] : ' + e.getMessage());
        }

        //field types we can compare with String
        if (sObjType == Schema.DisplayType.String
                || sObjType == Schema.DisplayType.Reference
                || sObjType == Schema.DisplayType.Email
                || sObjType == Schema.DisplayType.Picklist
                ) {
            if (operator == '=') {
                // System.debug('constate eval 1');
                conditionState = String.valueOf (sObjVal) == String.valueOf (condVal);
            } else if (operator == '!=') {
                // System.debug('constate eval 2');
                conditionState = String.valueOf (sObjVal) != String.valueOf (condVal);
            } else if (operator == 'Contains') {
                // 8/7/2020 made contains ignore case
                conditionState = String.valueOf (sObjVal).containsIgnoreCase (String.valueOf (condVal));
            }

        } //end if string

        //field types we can compare with Double
        // 8/7/2020 null handling, it bombs when null, also treat nulls like 0
        else if (sObjType == Schema.DisplayType.Currency
                || sObjType == Schema.DisplayType.Integer
                || sObjType == Schema.DisplayType.Percent
                || sObjType == Schema.DisplayType.Double
                ) {
            if (sObjVal == null) sObjVal = 0.0;
            if (condVal == null) condVal = 0.0;
            if (operator == '=') {
                conditionState = Double.valueOf (sObjVal) == Double.valueOf (condVal);
            } else if (operator == '!=') {
                // System.debug('constate eval 4');
                conditionState = Double.valueOf (sObjVal) != Double.valueOf (condVal);
            } else if (operator == '>') {
                // System.debug('constate eval 5');
                conditionState = Double.valueOf (sObjVal) > Double.valueOf (condVal);
            } else if (operator == '<') {
                // System.debug('constate eval 6');
                conditionState = Double.valueOf (sObjVal) < Double.valueOf (condVal);
            } else if (operator == '>=') {
                // System.debug('constate eval 7');
                conditionState = Double.valueOf (sObjVal) >= Double.valueOf (condVal);
            } else if (operator == '<=') {
                // System.debug('constate eval 8');
                conditionState = Double.valueOf (sObjVal) <= Double.valueOf (condVal);
            }


        }//end if Double

        //field types we can compare with DateTime
        else if (sObjType == Schema.DisplayType.Date || sObjType == Schema.DisplayType.DateTime
                ) {

            if (sObjType == Schema.DisplayType.Date) {
                sObjVal = (Date) sObjVal;
            } else {
                DateTime dateTimeObjVal = (DateTime) sObjVal;
                sObjVal = Date.newinstance(dateTimeObjVal.year(), dateTimeObjVal.month(), dateTimeObjVal.day());
            }

            Date conValDate = condVal != null ? (Date.parse(String.valueOf(condVal))) : null;

            if (operator == '=') {
                // System.debug('constate eval 9');
//conditionState = DateTime.valueOf (sObjVal) == DateTime.valueOf (condVal);
//conditionState = (Date) sObjVal == (Date.parse(String.valueOf(condVal)));
                conditionState = (Date) sObjVal == conValDate;
            } else if (operator == '!=') {
                // System.debug('constate eval 10');
//conditionState = DateTime.valueOf (sObjVal) != DateTime.valueOf (condVal);
//conditionState = (Date) sObjVal != (Date.parse(String.valueOf(condVal)));
                conditionState = (Date) sObjVal != conValDate;
            } else if (operator == '>') {
                // System.debug('constate eval 11');
//conditionState = DateTime.valueOf (sObjVal) > DateTime.valueOf (condVal);
//conditionState = (Date) sObjVal > (Date.parse(String.valueOf(condVal)));
                conditionState = (Date) sObjVal > conValDate;
            } else if (operator == '<') {
                // System.debug('constate eval 12');
//conditionState = DateTime.valueOf (sObjVal) < DateTime.valueOf (condVal);
//conditionState = (Date) sObjVal < (Date.parse(String.valueOf(condVal)));
                conditionState = (Date) sObjVal < conValDate;
            } else if (operator == '>=') {
                // System.debug('constate eval 13');
//conditionState = DateTime.valueOf (sObjVal) >= DateTime.valueOf (condVal);
//conditionState = (Date) sObjVal >= (Date.parse(String.valueOf(condVal)));
                conditionState = (Date) sObjVal >= conValDate;
            } else if (operator == '<=') {
                // System.debug('constate eval 14');
//conditionState = DateTime.valueOf (sObjVal) <= DateTime.valueOf (condVal);
//conditionState = (Date) sObjVal <= (Date.parse(String.valueOf(condVal)));
                conditionState = (Date) sObjVal <= conValDate;
            }


        }


        //handle includes
        if (sObjType == Schema.DisplayType.Picklist && operator == 'Includes') {

            Set <String> values = new Set <String> ();

            String condString = String.valueOf(condVal);

            for (String s : condString.split(';')) {
                values.add (s);
            }
            // System.debug('constate eval 15');
            conditionState = values.contains((String) sObjVal);

        }

        if (sObjType == Schema.DisplayType.Boolean) {
            if ((operator == '=' && (Boolean) sObjVal) || (operator == '!=' && !(Boolean) sObjVal)) {
                // System.debug('constate eval 16');
                conditionState = String.valueOf(condVal).equalsIgnoreCase('true');
            } else if ((operator == '!=' && (Boolean) sObjVal) || (operator == '=' && !(Boolean) sObjVal)) {
                // System.debug('constate eval 17');
                conditionState = String.valueOf(condVal).equalsIgnoreCase('false');
            }
        }

        if (sObjType == NULL) {
            if (operator == '=') {
                // System.debug('constate eval 18');
                conditionState = String.valueOf (sObjVal) == String.valueOf (condVal);
            } else if (operator == '!=') {
                // System.debug('constate eval 19');
                conditionState = String.valueOf (sObjVal) != String.valueOf (condVal);
            }
        }

        //one last check
        if (conditionState == NULL) {
            // System.debug('final conditionState value is still null');
            conditionState = FALSE; //default to false
        }


        return conditionState;

    }


    private Map<String, Map<Id, List<sObject>>> getOverrideObjectMap(List<TCRE__Rule_Config__c> ruleConfigs) {

        Map<String, Map<Id, List<sObject>>> overrideObjectMap = new Map<String, Map<Id, List<sObject>>>();
        for (TCRE__Rule_Config__c conf : ruleConfigs) {

            // System.debug('conf = ' + conf);
            for (TCRE__Rule_Condition__c rc : conf.TCRE__Rule_Conditions__r) {

                //override ruleObjects sObject?
                if (rc.TCRE__sObject_Override_Apex__c <> NULL) {

                    TCRE.SObjectOverride impl;
                    try {
                        Type t = Type.forName(rc.TCRE__sObject_Override_Apex__c);
                        impl = (TCRE.SObjectOverride) t.newInstance();
                    } catch (Exception e) {
                        throw new ruleEngineException('SObjectOverride [' + rc.TCRE__sObject_Override_Apex__c + '] class is not found');
                    }

                    overrideObjectMap.put(rc.TCRE__sObject_Override_Apex__c, impl.queryRecords(logicObjectIds));

                }
            }
        }
        return overrideObjectMap;
    }


    private Set<String> getQueryFields(List<TCRE__Rule_Config__c> ruleConfigs) {

        Set<String> queryFields = new Set<String>();
        for (TCRE__Rule_Config__c conf : ruleConfigs) {
            for (TCRE__Rule_Condition__c rc : conf.TCRE__Rule_Conditions__r) {

                //override ruleObjects sObject?
                if (rc.TCRE__sObject_Override_Apex__c == NULL) {
                    queryFields.add(rc.TCRE__Field_Name__c.toLowerCase());
                }
                
                if(String.isNotBlank(rc.TCRE__Value__c) && rc.TCRE__Value__c.startsWith('{!') && rc.TCRE__Value__c.endsWith('}')){
                    // value = parsed api
                    queryFields.add(rc.TCRE__Value__c.substringBetween('{!','}').toLowerCase());
                }
            }
        }
        return queryFields;
    }

    public static Boolean boolEval(String theLogic, SObject obj){
        Boolean result = false;
        if(obj == null){
            obj = (SObject)new Lead();
        }
        theLogic = theLogic.toLowerCase().replaceAll('or', '||').replaceAll('and', '&&');
        FormulaEval.FormulaBuilder testBuild = Formula.builder().withType(obj.getSObjectType()).withReturnType(FormulaEval.FormulaReturnType.BOOLEAN)
                    .withFormula(theLogic);
        result = (Boolean)testBuild.build().evaluate(obj);
        return result;
    }

    public class ruleEngineException extends Exception{ }
}