/** @author : Tamarack Consulting, Inc.
 * @date : 1/8/20
 * @description: ACH Guarantee Form (SAL-1023)
 *
 */

public with sharing class TC_CDR004 implements TC_CDRInterface {

    /**
     * Sets the Stipulations picklist to ACH Guarantee Form
     * @param oldMap The old versions of opportunities
     * @param newMap The new versions of opportunities
     * @param filterIds The filtered set of opportunity IDs which will be modified
     * @param relatedRecords The wrapper class
     */
    public void runRule(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap, Set<Id> filterIds, TC_CreditDecision.RelatedRecords relatedRecords) {
        for (Id oppId : filterIds) {
            /* Preconditions for entering credit rule */
            Boolean lessorIsValid = newMap.get(oppId).Lessor__c == 421 || newMap.get(oppId).Lessor__c == 422
                    || newMap.get(oppId).Lessor__c == 423
                    || newMap.get(oppId).Lessor__c == 424 || newMap.get(oppId).Lessor__c == 432
                    || newMap.get(oppId).Lessor__c == 021;
            Boolean marlinScoreIsValid = newMap.get(oppId).Opportunity_Marlin_Score__c == null || newMap.get(oppId).Opportunity_Marlin_Score__c == 0;
            Boolean fieldsAreChanged = oldMap.get(oppId).Lessor__c <> newMap.get(oppId).Lessor__c
                    || oldMap.get(oppId).Decision_Status__c <> newMap.get(oppId).Decision_Status__c
                    || oldMap.get(oppId).SIC_Code__c <> newMap.get(oppId).SIC_Code__c
                    || oldMap.get(oppId).Opportunity_Marlin_Score__c <> newMap.get(oppId).Opportunity_Marlin_Score__c
                    || oldMap.get(oppId).Program_Type__c <> newMap.get(oppId).Program_Type__c;

            if (newMap.get(oppId).Decision_Status__c == 'A')  {
                if ((lessorIsValid || (newMap.get(oppId).SIC_Code__c == '8661' && marlinScoreIsValid)) &&
                        (TC_CreditDecision.gdsRanFirstTime(oppId) || fieldsAreChanged)) {
                    if (newMap.get(oppId).Stipulations__c <> null) {
                        if (!newMap.get(oppId).Stipulations__c.contains('ACH Guarantee Form')) {
                            newMap.get(oppId).Stipulations__c = newMap.get(oppId).Stipulations__c + ';' + 'ACH Guarantee Form';
                            TC_ChatterHelper.addMessage(relatedRecords.relatedChatterMap, oppId, 'Set Stipulations to '
                                    + newMap.get(oppId).Stipulations__c);
                        }
                    } else {
                        newMap.get(oppId).Stipulations__c = 'ACH Guarantee Form';
                        TC_ChatterHelper.addMessage(relatedRecords.relatedChatterMap, oppId, 'Set Stipulations to '
                                + newMap.get(oppId).Stipulations__c);
                    }
                }
            }
        }
    }
}