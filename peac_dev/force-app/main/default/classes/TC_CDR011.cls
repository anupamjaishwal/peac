/**
 * Created by tamarack on 1/8/20.
 */

public with sharing class TC_CDR011 implements TC_CDRInterface {

    /**
     * CDR-011 Check Equip Approval Stip for 855331.7237
     * @description: https://marlinbusiness.atlassian.net/browse/SAL-1033
     * If:
     *    1. Decision_Status__c = Approved
     *    2. Dealer on Opportunity is marked as Primary_Dealer__c = TRUE
     *    3. Dealer_Number__c = 855331.7237
     * Then:
     *    1. set Stipulations__c = Equipment Approval
     * @param oldMap Map of old records from opportunity trigger
     * @param newMap Map of new records from opportunity trigger
     * @param filterIds Set of relevant opp Ids from opportunity trigger
     * @param relatedRecordsWrapper Wrapper object of related records to DML at end of CDRs
     */

    public static void runRule(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap
            , Set<Id> filterIds, TC_CreditDecision.relatedRecords relatedRecordsWrapper) {

        List<Broker__c> brokerList = new List<Broker__c>();
        if (!filterIds.isEmpty()) {
            brokerList = new List<Broker__c>([
                    SELECT Id, Opportunity__c
                    FROM Broker__c
                    WHERE Broker_Dealer_Number__c = '855331.7237' AND Opportunity__c IN: filterIds
            ]);
        }

        Map<Id, Broker__c> oppBrokerMap = new Map<Id, Broker__c>();
        for (Broker__c broker : brokerList) {
            oppBrokerMap.put(broker.Opportunity__c, broker);
        }

        for (Id oppId : filterIds) {
            if (newMap.get(oppId).Decision_Status__c == 'A' && oppBrokerMap.containsKey(oppId)
                    && (newMap.get(oppId).Stipulations__c == null
                    || (newMap.get(oppId).Stipulations__c != null && !newMap.get(oppId).Stipulations__c.contains('Equipment Approval')))) {
                if (newMap.get(oppId).Stipulations__c != null) newMap.get(oppId).Stipulations__c += ';';
                newMap.get(oppId).Stipulations__c += 'Equipment Approval';
                TC_ChatterHelper.addMessage(relatedRecordsWrapper.relatedChatterMap, oppId, 'Set Stipulations to \'Equipment Approval\'');
            }
        }

        /*
        Logic switched from Dealer to Broker
        List<Dealer__c> dealerList = new List<Dealer__c>();
        if (!filterIds.isEmpty()) {
            dealerList = new List<Dealer__c>([
                    SELECT Id, Opportunity__c
                    FROM Dealer__c
                    WHERE Primary_Dealer__c = TRUE AND Dealer__r.Dealer_Number__c = '855331.7237' AND Opportunity__c IN: filterIds
            ]);
        }

        Map<Id, Dealer__c> oppDealerMap = new Map<Id, Dealer__c>();
        for (Dealer__c dealer : dealerList) {
            oppDealerMap.put(dealer.Opportunity__c, dealer);
        }

        for (Id oppId : filterIds) {
            if (newMap.get(oppId).Decision_Status__c == 'A' && oppDealerMap.containsKey(oppId)
                    && (newMap.get(oppId).Stipulations__c == null
                        || (newMap.get(oppId).Stipulations__c != null && !newMap.get(oppId).Stipulations__c.contains('Equipment Approval')))) {
                newMap.get(oppId).Stipulations__c = 'Equipment Approval';
                TC_ChatterHelper.addMessage(relatedRecordsWrapper.relatedChatterMap, oppId, 'Set Stipulations to \'Equipment Approval\'');
            }
        }
        */

    }

}