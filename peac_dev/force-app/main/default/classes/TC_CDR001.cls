/** @author : Tamarack Consulting, Inc.
 * @date : 1/8/20
 * @description: Update fields based on Lessor (SAL-1020)
 *
 */
public with sharing class TC_CDR001 implements TC_CDRInterface {
    /**
     * @description Sets fields based on the selected Lessor__c field
     * @param oldMap The old versions of opportunities
     * @param newMap The new versions of opportunities
     * @param filterIds The filtered set of opportunity IDs which will be modified
     * @param relatedRecords The wrapper class
     */
    public void runRule(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap, Set<Id> filterIds, TC_CreditDecision.RelatedRecords relatedRecords) {

        for (Id oppId : filterIds) {
            Boolean fieldsAreChanged = oldMap.get(oppId).Lessor__c <> newMap.get(oppId).Lessor__c
                ||  oldMap.get(oppId).Program_Type__c <> newMap.get(oppId).Program_Type__c;
            
            if (newMap.get(oppId).Region__c <> null && (TC_CreditDecision.gdsRanFirstTime(oppId) ||
                    oldMap.get(oppId).Region__c <> newMap.get(oppId).Region__c)) {
                /* If there are 150 MLC Syndications, then set the region to Marlin Leasing, else set it to MBB */
                //the below was changed so that all lessor codes that start with 4 have a 000 Region code SAL-3640
                //Modified by Rajesh(LTIMindtree)- newMap.get(oppId).Region__c = (newMap.get(oppId).Lessor__c == 150 || (newMap.get(oppId).Lessor__c > 399 && newMap.get(oppId).Lessor__c < 500)) ? '000' : '001';
                //newMap.get(oppId).Region__c = (newMap.get(oppId).Lessor__c == 150 || (newMap.get(oppId).Lessor__c > 399 && newMap.get(oppId).Lessor__c < 500)) ? '000' : '001';
                TC_ChatterHelper.addMessage(relatedRecords.relatedChatterMap, newMap.get(oppId).Id, 'Set Region to ' + newMap.get(oppId).Region__c);
            }

            /* If the Lessor value is applicable, check the Auto ACH Required box on the Credit Stips checklist */
            if ((newMap.get(oppId).Lessor__c == 421 || newMap.get(oppId).Lessor__c == 422 || newMap.get(oppId).Lessor__c == 423 || newMap.get(oppId).Lessor__c == 432 || newMap.get(oppId).Lessor__c == 021) &&
                    (TC_CreditDecision.gdsRanFirstTime(newMap.get(oppId).Id) || fieldsAreChanged)) {
                /* Get the Auto ACH Required checkbox from this opportunity's Credit Stips checklist */
                if (newMap.get(oppId).Stipulations__c <> null) {
                    if (!newMap.get(oppId).Stipulations__c.contains('Auto ACH Required')) {
                        newMap.get(oppId).Stipulations__c = newMap.get(oppId).Stipulations__c + ';' + 'Auto ACH Required';
                        TC_ChatterHelper.addMessage(relatedRecords.relatedChatterMap, oppId, 'Set Stipulations to ' + newMap.get(oppId).Stipulations__c);
                    }
                } else {
                    newMap.get(oppId).Stipulations__c = 'Auto ACH Required';
                    TC_ChatterHelper.addMessage(relatedRecords.relatedChatterMap, oppId, 'Set Stipulations to ' + newMap.get(oppId).Stipulations__c);
                }
            }
        }
    }
}