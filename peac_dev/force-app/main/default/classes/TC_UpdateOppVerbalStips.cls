public class TC_UpdateOppVerbalStips {
    public static void updateOppVerbalStips(Map<Id, Account> oldMap, Map<Id, Account> newMap) {

        Set<Id> accountPDLChangedIdSet = new Set<Id>();
        for (Account account : newMap.values()) {
            if (account.Preferred_Dealer_Level__c != null &&
                    account.Preferred_Dealer_Level__c != oldMap.get(account.Id).Preferred_Dealer_Level__c) {
                accountPDLChangedIdSet.add(account.Id);
            }
        }

        List<Dealer__c> dealerList = new List<Dealer__c>();
        if (!accountPDLChangedIdSet.isEmpty()) {
            dealerList = new List<Dealer__c>([
                    SELECT Dealer__r.Preferred_Dealer_Level__c, Opportunity__c
                    FROM Dealer__c
                    WHERE Dealer__c IN: accountPDLChangedIdSet
            ]);
        }


        Map<Id, Dealer__c> oppIdDealerMap = new Map<Id, Dealer__c>();

        for (Dealer__c dealer : dealerList) {
            oppIdDealerMap.put(dealer.Opportunity__c, dealer);
        }

        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        if (!oppIdDealerMap.keySet().isEmpty()) {
            oppMap = new Map<Id, Opportunity>([
                    SELECT AccountId, Waived_Stipulations__c, No_Verbal__c, Primary_Dealer__c, Credit_Amount__c
                    FROM Opportunity
                    WHERE Id IN: oppIdDealerMap.keySet()
                    AND StageName = 'Decision'
                    AND Loan_Record_Type__c = false
                    AND Last_Date_Scorex_Retrieved__c != null
            ]);
        }

        Map<Id, Id> accountRetrieveNoVerbalIdOpportunityMap = new Map<Id, Id>();
        for (Opportunity opp : oppMap.values()) {
            String pdl = newMap.get(oppIdDealerMap.get(opp.Id).Dealer__c).Preferred_Dealer_Level__c;
            Decimal ca = opp.Credit_Amount__c;
            if (pdl != null && ca != null) {
                if ((pdl.equals('1') && ca <= 50000) || (pdl.equals('2') && ca <= 30000) || (pdl.equals('3') && ca <= 20000)) {
                    opp.No_Verbal__c = 'Yes';
                } else {
                    accountRetrieveNoVerbalIdOpportunityMap.put(opp.AccountId, opp.Id);
                }

                if ((pdl == '1' || pdl == '2' || pdl == '3') && ca <= 20000) {
                    List<String> waivedStipsList = new List<String>{
                            'Copy of drivers\'s license',
                            'Corporate Officer to Sign',
                            'Proof of equipment location'};
                    opp.Waived_Stipulations__c = String.join(waivedStipsList, ';');
                }
            }
        }

        Map<Id, Account> accountRetrieveNoVerbalMap = new Map<Id, Account>();
        if (!accountRetrieveNoVerbalIdOpportunityMap.keySet().isEmpty()) {
            accountRetrieveNoVerbalMap = new Map<Id, Account>([
                    SELECT No_Verbal__c
                    FROM Account
                    WHERE Id IN: accountRetrieveNoVerbalIdOpportunityMap.keySet()
            ]);
        }

        for (Id accountId : accountRetrieveNoVerbalIdOpportunityMap.keySet()) {
            oppMap.get(accountRetrieveNoVerbalIdOpportunityMap.get(accountId)).No_Verbal__c =
                    newMap.containsKey(accountId) ? newMap.get(accountId).No_Verbal__c :
                    accountRetrieveNoVerbalMap.get(accountId).No_Verbal__c;
        }

        update oppMap.values();
    }
}