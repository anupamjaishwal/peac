/** @author : Tamarack Consulting, Inc.
 * @date : 1/10/20
 * @description: Sets program type based on lessor and SFP tier 2 status
 *
 */
public with sharing class TC_CDR002 implements TC_CDRInterface {
    /**
     * @description Sets program type based on lessor and SFP tier 2 status
     * @param oldMap The old versions of opportunities
     * @param newMap The new versions of opportunities
     * @param filterIds The filtered set of opportunity IDs which will be modified
     * @param relatedRecords The wrapper class
     */
    public void runRule(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap, Set<Id> filterIds, TC_CreditDecision.RelatedRecords relatedRecords) {

        for (Id oppId : filterIds){

            if (TC_CreditDecision.gdsRanFirstTime(oppId) || oldMap.get (oppId).Lessor__c != newMap.get(oppId).Lessor__c ||
                    oldMap.get (oppId).SFP_Tier_2_Status__c != newMap.get(oppId).SFP_Tier_2_Status__c) {
                if (newMap.get(oppId).Lessor__c != null && (newMap.get(oppId).Lessor__c == 421 || newMap.get(oppId).Lessor__c == 423 ||
                        newMap.get(oppId).Lessor__c == 201 || newMap.get(oppId).Lessor__c == 422)) {
                    newMap.get(oppId).Program_Type__c = '1100';
                    TC_ChatterHelper.addMessage(relatedRecords.relatedChatterMap, oppId, 'Program Type set to 1100.');
                } else if ((newMap.get(oppId).SFP_Tier_2_Status__c == 'Approved' || newMap.get(oppId).SFP_Tier_2_Status__c == 'More Info')){
                    newMap.get(oppId).Program_Type__c = '1200';
                    TC_ChatterHelper.addMessage(relatedRecords.relatedChatterMap, oppId, 'Program Type set to 1200.');
                } else if (newMap.get(oppId).SFP_Tier_2_Status__c == 'Rejected'){
                    newMap.get(oppId).Program_Type__c = null;
                    TC_ChatterHelper.addMessage(relatedRecords.relatedChatterMap, oppId, 'Program Type set to null.');
                }
            }

        }
    }

}