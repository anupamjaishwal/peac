/** @author : Tamarack Consulting, Inc.
 * @date : 1/8/20
 * @description: Set Facility (SAL-1028)
 *
 */
public with sharing class TC_CDR007 implements TC_CDRInterface {

    /**
     * Sets the facility code based on Program Type
     * @param oldMap The old versions of opportunities
     * @param newMap The new versions of opportunities
     * @param filterIds The filtered set of opportunity IDs which will be modified
     * @param relatedRecords The wrapper class
     */
    public void runRule(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap, Set<Id> filterIds, TC_CreditDecision.RelatedRecords relatedRecords) {

        for (Id oppId : filterIds) {
            /* Checks if the SFP Tier 2 Status and Program Type has changed */
            if (newMap.get(oppId).Program_Type__c <> oldMap.get(oppId).Program_Type__c) {
                /* Entry criteria for Program Type */
                if (newMap.get(oppId).Program_Type__c == '1100') {
                    if (newMap.get(oppId).Stipulations__c <> null) {
                        if (!newMap.get(oppId).Stipulations__c.contains('Email Required')) {
                            newMap.get(oppId).Stipulations__c = newMap.get(oppId).Stipulations__c + ';' + 'Email Required';
                            TC_ChatterHelper.addMessage(relatedRecords.relatedChatterMap, oppId, 'Set Stipulations to ' + newMap.get(oppId).Stipulations__c);
                        }
                    } else {
                        newMap.get(oppId).Stipulations__c = 'Email Required';
                        TC_ChatterHelper.addMessage(relatedRecords.relatedChatterMap, oppId, 'Set Stipulations to ' + newMap.get(oppId).Stipulations__c);
                    }
                }
            }
        }
    }
}