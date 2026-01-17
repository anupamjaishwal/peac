/**
 * Created by tamarack on 1/14/20.
 */

public with sharing class TC_CDR005 implements TC_CDRInterface {

    /**
     * CDR-005 Set Verbal and Stips based on Preferred Dealer
     * @description: https://marlinbusiness.atlassian.net/browse/SAL-1024
     * @param oldMap Map of old records from opportunity trigger
     * @param newMap Map of new records from opportunity trigger
     * @param filterIds Set of relevant opp Ids from opportunity trigger
     * @param relatedRecordsWrapper Wrapper object of related records to DML at end of CDRs
     */

    public static void runRule(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap
            , Set<Id> filterIds, TC_CreditDecision.relatedRecords relatedRecordsWrapper) {

        Set<Id> cdr005FilterIdSet = new Set<Id>();
        Set<Id> dealerIdSet = new Set<Id>();
        Set<Id> accountIdSet = new Set<Id>();
        for (Id oppId : filterIds) {
            if (TC_CreditDecision.gdsRanFirstTime(oppId) ||
                    newMap.get(oppId).Credit_Amount__c != oldMap.get(oppId).Credit_Amount__c) {
                cdr005FilterIdSet.add(oppId);
                dealerIdSet.add(newMap.get(oppId).Primary_Dealer__c);
                accountIdSet.add(newMap.get(oppId).AccountId);
            }
        }

        Map<Id, Dealer__c> dealerMap = new Map<Id, Dealer__c>();
        if (!dealerIdSet.isEmpty()) {
            dealerMap = new Map<Id, Dealer__c>([
                    SELECT Dealer__c
                    FROM Dealer__c
                    WHERE Id IN: dealerIdSet
            ]);
        }

        for (Dealer__c dealer : dealerMap.values()) {
            if (!relatedRecordsWrapper.relatedDealerMap.containsKey(dealer.Id)) {
                relatedRecordsWrapper.relatedDealerMap.put(dealer.Id, dealer);
            }
            accountIdSet.add(dealer.Dealer__c);
        }

        List<Account> accountList = new List<Account>();
        if (!accountIdSet.isEmpty()) {
            accountList = new List<Account> ([
                    SELECT No_Verbal__c, Preferred_Dealer_Level__c
                    FROM Account
                    WHERE Id IN: accountIdSet
            ]);
        }

        for (Account account : accountList) {
            if (relatedRecordsWrapper.relatedAccountMap.containsKey(account.Id)) {
                if (relatedRecordsWrapper.relatedAccountMap.get(account.Id).No_Verbal__c == null) {
                    relatedRecordsWrapper.relatedAccountMap.get(account.Id).No_Verbal__c = account.No_Verbal__c;
                }
                if (relatedRecordsWrapper.relatedAccountMap.get(account.Id).Preferred_Dealer_Level__c == null) {
                    relatedRecordsWrapper.relatedAccountMap.get(account.Id).Preferred_Dealer_Level__c = account.Preferred_Dealer_Level__c;
                }
            } else {
                relatedRecordsWrapper.relatedAccountMap.put(account.Id, account);
            }
        }

        for (Id oppId : cdr005FilterIdSet) {
            // Update No Verbal Field
            String pdl = newMap.get(oppId).Primary_Dealer__c != null ?
                    relatedRecordsWrapper.relatedAccountMap.get(relatedRecordsWrapper.relatedDealerMap.get(newMap.get
                            (oppId).Primary_Dealer__c).Dealer__c).Preferred_Dealer_Level__c : null;
            Decimal ca = newMap.get(oppId).Credit_Amount__c;
            if (pdl != null && ca != null) {
                if ((pdl.equals('1') && ca <= 50000) || (pdl.equals('2') && ca <= 30000) || (pdl.equals('3') && ca <= 20000)) {
                    newMap.get(oppId).No_Verbal__c = 'Yes';
                } else {
                    newMap.get(oppId).No_Verbal__c = newMap.get(oppId).AccountId != null ?
                            relatedRecordsWrapper.relatedAccountMap.get(newMap.get(oppId).AccountId).No_Verbal__c :
                            null;
                }
                TC_ChatterHelper.addMessage(relatedRecordsWrapper.relatedChatterMap, oppId, 'Set No Verbal to ' +
                    newMap.get(oppId).No_Verbal__c);

                // Update List of Waived Stipulations
                //Commented out per https://marlinbusiness.atlassian.net/browse/SAL-2159
                /*if ((pdl == '1' || pdl == '2' || pdl == '3') && ca <= 20000) {

                    String stipulationsString = newMap.get(oppId).Stipulations__c == null ? '' : newMap.get(oppId).Stipulations__c;
                    stipulationsString += String.isBlank (stipulationsString) ? 'Copy of drivers\'s license' : newMap.get(oppId).Stipulations__c == null || !newMap.get(oppId).Stipulations__c.contains('Copy of drivers\'s license')? ';Copy of drivers\'s license' : '';
                    stipulationsString += String.isBlank (stipulationsString) ? 'Corporate Officer to Sign' : newMap.get(oppId).Stipulations__c == null || !newMap.get(oppId).Stipulations__c.contains('Corporate Officer to Sign')? ';Corporate Officer to Sign' : '';
                    stipulationsString += String.isBlank (stipulationsString) ? 'Proof of equipment location' : newMap.get(oppId).Stipulations__c == null || !newMap.get(oppId).Stipulations__c.contains('Proof of equipment location')? ';Proof of equipment location' : '';

                    newMap.get(oppId).Stipulations__c = stipulationsString;

                    TC_ChatterHelper.addMessage(relatedRecordsWrapper.relatedChatterMap, oppId, 'Set Stipulations to ' +
                            newMap.get(oppId).Stipulations__c);

                    String waivedStipulationsString = newMap.get(oppId).Waived_Stipulations__c == null ? '' : newMap.get(oppId).Waived_Stipulations__c;
                    
                    waivedStipulationsString += String.isBlank (waivedStipulationsString) ? 'Copy of drivers\'s license' : newMap.get(oppId).Waived_Stipulations__c == null || !newMap.get(oppId).Waived_Stipulations__c.contains('Copy of drivers\'s license')? ';Copy of drivers\'s license' : '';
                    waivedStipulationsString += String.isBlank (waivedStipulationsString) ? 'Corporate Officer to Sign' : newMap.get(oppId).Waived_Stipulations__c == null || !newMap.get(oppId).Waived_Stipulations__c.contains('Corporate Officer to Sign')? ';Corporate Officer to Sign' : '';
                    waivedStipulationsString += String.isBlank (waivedStipulationsString) ? 'Proof of equipment location' : newMap.get(oppId).Waived_Stipulations__c == null || !newMap.get(oppId).Waived_Stipulations__c.contains('Proof of equipment location')? ';Proof of equipment location' : '';

                    newMap.get(oppId).Waived_Stipulations__c = waivedStipulationsString;

                    TC_ChatterHelper.addMessage(relatedRecordsWrapper.relatedChatterMap, oppId, 'Set Waived Stipulations to ' +
                            newMap.get(oppId).Waived_Stipulations__c);
                }*/
            }
        }

    }

}