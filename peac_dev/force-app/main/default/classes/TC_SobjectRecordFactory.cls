/** @author : Tamarack Consulting, Inc.
 * @date : 10/29/20
 * @description: 
 *
 */
public with sharing class TC_SobjectRecordFactory {

    /**
     * Creates an account record
     *
     * @return An account
     */
    public static Account createAccount(TC_RateCardRequestBean req) {

        Account acc = new Account();
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
        acc.Name = 'STATIC ACCOUNT FOR RATE CARDS - DO NOT DELETE';
        acc.Channel_Approver__c = UserInfo.getUserId();

        return acc;
    }

    /**
     * Creates an opportunity record
     *
     * @param acc The parent account
     * @return An opportunity
     */
    public static Opportunity createOpportunity(Account acc) {

        if (acc.Id <> null) {

            Opportunity opp = new Opportunity();
            opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Express Quote').getRecordTypeId();
            opp.Name = 'STATIC OPPORTUNITY FOR RATE CARDS - DO NOT DELETE';
            opp.AccountId = acc.Id;
            opp.StageName = 'Proposal';
            opp.Primary_Source__c = 'Customer Inbound - Call';
            opp.CloseDate = System.today();

            return opp;
        }

        return null;
    }

    /**
     * @return a list of dummy rate cards for testing purposes
     */
    @TestVisible
    private static List<EF_Approved_Offers__c> createEfApprovedOffers(Opportunity opp, Integer numOfCards, Decimal term, Decimal yield) {

        List<EF_Approved_Offers__c> rateCards = new List<EF_Approved_Offers__c>();

        for (Integer i = 0; i < numOfCards; i++) {
            EF_Approved_Offers__c rateCard = new EF_Approved_Offers__c(
                    Opportunity__c = opp.Id,
                    Term_in_Months__c = term,
                    Yield__c = yield
            );
            rateCards.add(rateCard);
        }

        return rateCards;
    }
}