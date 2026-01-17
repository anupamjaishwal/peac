/** @author : Tamarack Consulting, Inc.
 * @date : 02/07/20
 *
 */
public with sharing class TC_CDR020 implements TC_CDRInterface {
    /**
     * @description Set Initial Approval Date
     * https://marlinbusiness.atlassian.net/browse/SAL-1121
     * @param oldMap The old versions of opportunities
     * @param newMap The new versions of opportunities
     * @param filterIds The filtered set of opportunity IDs which will be modified
     * @param relatedRecords The wrapper class
     */
    public void runRule(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap, Set<Id> filterIds, TC_CreditDecision.RelatedRecords relatedRecords) {

        for (Id oppId : filterIds){
            if ((newMap.get(oppId).Initial_Approval_Date__c == null && (newMap.get(oppId).Application_Status__c == 'Manually Approved' || newMap.get(oppId).Application_Status__c == 'Automatically Approved'))
                    && (TC_CreditDecision.gdsRanFirstTime(oppId)
                        || newMap.get(oppId).Initial_Approval_Date__c != oldMap.get(oppId).Initial_Approval_Date__c
                        || newMap.get(oppId).Application_Status__c != oldMap.get(oppId).Application_Status__c)
                    ){
                newMap.get(oppId).Initial_Approval_Date__c = System.now();
                TC_ChatterHelper.addMessage(relatedRecords.relatedChatterMap, oppId, 'Initial Approval Date set to ' + System.now());
            }
            if ((newMap.get(oppId).Application_Status__c == 'Manually Approved' || newMap.get(oppId).Application_Status__c == 'Automatically Approved')
                    && newMap.get(oppId).Application_Status__c != oldMap.get(oppId).Application_Status__c){
                newMap.get(oppId).Approval_Date__c = System.now();
                TC_ChatterHelper.addMessage(relatedRecords.relatedChatterMap, oppId, 'Approval Date set to ' + System.now());
            }
            if (newMap.get(oppId).Initial_More_Info_Date__c  == null && (newMap.get(oppId).Application_Status__c == 'More Info' || newMap.get(oppId).Application_Status__c == 'Returned to Submitter') && newMap.get(oppId).Application_Status__c != oldMap.get(oppId).Application_Status__c){
                newMap.get(oppId).Initial_More_Info_Date__c = System.now();
                TC_ChatterHelper.addMessage(relatedRecords.relatedChatterMap, oppId, 'Initial More Info Date set to ' + System.now());
            }
        }

    }

}