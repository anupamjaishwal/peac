public class TC_SetRecordTypeAfterResubmit {

 public static void setRecordTypeAfterResubmit(Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
        Map<String, Schema.RecordTypeInfo> recordTypeMap = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        Map<String, String> businessGroupDecisionRecordTypeMap = new Map<String, String>();
        for (String recordTypeName : recordTypeMap.keySet()) {
            if (recordTypeName.containsIgnoreCase('Decision')) {
                List<String> recordTypeNameUnderscore = recordTypeName.split('_');
                String businessGroup = recordTypeNameUnderscore.size() == 1 ? recordTypeName.split(' ')[0].toLowerCase() : recordTypeNameUnderscore[0].toLowerCase();
                businessGroupDecisionRecordTypeMap.put(businessGroup, recordTypeName);
            }
        }
        
        for (Opportunity opp : newMap.values()) {
            if (!opp.Credit_Decision__c && opp.Resubmitted_to_Credit__c && opp.StageName == 'Decision' && !opp.record_type_name__c.containsIgnoreCase('Decision')) {
                List<String> recordTypeNameUnderscore = opp.record_type_name__c.split('_');
                String businessGroup = recordTypeNameUnderscore.size() == 1 ? opp.record_type_name__c.split(' ')[0].toLowerCase() : recordTypeNameUnderscore[0].toLowerCase();
                if (businessGroupDecisionRecordTypeMap.containsKey(businessGroup)) {
                    opp.RecordTypeId = recordTypeMap.get(businessGroupDecisionRecordTypeMap.get(businessGroup)).getRecordTypeId();
                } else {
                    opp.addError('Attempt to dynamically reset Decision record type for this Business Group (' + businessGroup + ') has failed: ' + businessGroupDecisionRecordTypeMap);
                }
                
            }
        }
    }
}