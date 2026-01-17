/** @author : Tamarack Consulting, Inc.
 * @date : 1/10/20
 * @description: Sets OFAC Required to True if OFAC Override is true. And sets # of Payments equal to Terms if Max Term Approved is null.
 *
 */
public with sharing class TC_CDR003 implements TC_CDRInterface {
    /**
     * @description Sets OFAC Required to True if OFAC Override is true. And sets # of Payments equal to Terms if Max Term Approved is null.
     * @param oldMap The old versions of opportunities
     * @param newMap The new versions of opportunities
     * @param filterIds The filtered set of opportunity IDs which will be modified
     * @param relatedRecords The wrapper class
     */
    public void runRule(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap, Set<Id> filterIds, TC_CreditDecision.RelatedRecords relatedRecords) {

        for (Id oppId : filterIds){
            if (newMap.get(oppId).OFAC_Override__c && (TC_CreditDecision.gdsRanFirstTime(oppId) ||
                    oldMap.get (oppId).OFAC_Override__c != newMap.get(oppId).OFAC_Override__c)){
                newMap.get(oppId).OFAC_Required__c = 'True';
                TC_ChatterHelper.addMessage(relatedRecords.relatedChatterMap, oppId, 'OFAC Required set to True.');
            }
            if (newMap.get(oppId).Max_Term_Approved__c == null && (TC_CreditDecision.gdsRanFirstTime(oppId) ||
                    oldMap.get (oppId).Max_Term_Approved__c != newMap.get(oppId).Max_Term_Approved__c)){
                newMap.get(oppId).of_Payments__c = newMap.get(oppId).Terms__c;
                TC_ChatterHelper.addMessage(relatedRecords.relatedChatterMap, oppId, '# of Payments set equal to Terms.');
            }
        }
    }

}