/** @author : Tamarack Consulting, Inc.
 * @date : 1/17/20
 * @description: Set Lessor (SAL-1034)
 *
 */
public with sharing class TC_CDR012 implements TC_CDRInterface {

    /**
     * Set the lessor
     * @param oldMap The old versions of opportunities
     * @param newMap The new versions of opportunities
     * @param filterIds The filtered set of IDs of opportunities which will be modified
     * @param relatedRecords The wrapper class
     */
    public void runRule(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap, Set<Id> filterIds, TC_CreditDecision.RelatedRecords relatedRecords) {
        for (Id oppId : filterIds) {

            /* If Program Type is On Balance Sheet Funding, then set Lessor to 401 */
            if (newMap.get(oppId).Program_Type__c == '1100' && (TC_CreditDecision.gdsRanFirstTime(oppId) ||
                    oldMap.get(oppId).Program_Type__c <> newMap.get(oppId).Program_Type__c)) {
                newMap.get(oppId).Lessor__c = 421;
                TC_ChatterHelper.addMessage(relatedRecords.relatedChatterMap, oppId, 'Set Lessor to 401');
            }

            /* If Program Type is SFP Tier 2 and SFP Tier 2 Status is Approved, then set Lessor to 423 */
            else if ((newMap.get(oppId).Program_Type__c == '1200' || newMap.get(oppId).SFP_Tier_2_Status__c == 'Approved') &&
                    (TC_CreditDecision.gdsRanFirstTime(oppId) || oldMap.get(oppId).Program_Type__c <> newMap.get(oppId).Program_Type__c ||
                    oldMap.get(oppId).SFP_Tier_2_Status__c <> newMap.get(oppId).SFP_Tier_2_Status__c)) {
                newMap.get(oppId).Lessor__c = 423;
                TC_ChatterHelper.addMessage(relatedRecords.relatedChatterMap, oppId, 'Set Lessor to 423');
            }

            /* If SFP Tier 2 Status is Rejected, then set Lessor to 001 */
            else if (newMap.get(oppId).SFP_Tier_2_Status__c == 'Rejected' && (TC_CreditDecision.gdsRanFirstTime(oppId) ||
                    oldMap.get(oppId).SFP_Tier_2_Status__c <> newMap.get(oppId).SFP_Tier_2_Status__c)) {
                newMap.get(oppId).Lessor__c = 001;
                TC_ChatterHelper.addMessage(relatedRecords.relatedChatterMap, oppId, 'Set Lessor to 001');
            }

            /* If Branch is Commercial Vehicle Group, then set Lessor to 405 */
            else if (newMap.get(oppId).Branch__c == 'Commercial Vehicle Group' && (TC_CreditDecision.gdsRanFirstTime(oppId) ||
                    oldMap.get(oppId).Branch__c <> newMap.get(oppId).Branch__c)) {
                newMap.get(oppId).Lessor__c = 405;
                TC_ChatterHelper.addMessage(relatedRecords.relatedChatterMap, oppId, 'Set Lessor to 405');
            }

            /* If the Lessor is blank, set it to 401 */
            else if (newMap.get(oppId).Lessor__c == null && (TC_CreditDecision.gdsRanFirstTime(oppId) ||
                    oldMap.get(oppId).Lessor__c <> newMap.get(oppId).Lessor__c)) {
                newMap.get(oppId).Lessor__c = 401;
                TC_ChatterHelper.addMessage(relatedRecords.relatedChatterMap, oppId, 'Set Lessor to 401');
            }
        }
    }
}