/**
 * Created by andrewmayer on 9/15/20.
 * Trigger condition on the EF Approved offer for calculating the rate factor
 */

public with sharing class TC_EfOfferCalculateRateFactor implements TC_TriggerActionI{


    public void doAction(TC_TriggerContext tc) {
        Map <Id, EF_Approved_Offers__c> oldMap = (Map <Id, EF_Approved_Offers__c>) tc.getOldMap ();
        List <EF_Approved_Offers__c> newList = (List <EF_Approved_Offers__c>) tc.getNewList ();

        List <EF_Approved_Offers__c> updateList = new List <EF_Approved_Offers__c> ();
        Set <Id> oppIds = new Set <Id> ();

        for (EF_Approved_Offers__c offer : newList) {
            if (oldMap == null
                    || offer.Yield__c != oldMap.get (offer.Id).Yield__c
                    || offer.Term_in_Months__c != oldMap.get (offer.Id).Term_in_Months__c
                    || offer.Advanced_Rental__c != oldMap.get (offer.Id).Advanced_Rental__c
            ) {
                updateList.add (offer);
                oppIds.add (offer.Opportunity__c);
            }
        }

        if (updateList.isEmpty ()) return; //TC_possibleOfferstest

        Map <Id, Opportunity> relatedOpps = new Map <Id, Opportunity> ([SELECT Id, Deferral_Periods__c, Deferral_Payments__c, Purchase_Options__c, Required_Adv_Payments__c, Portal_User_ID__c FROM Opportunity WHERE Id IN :oppIds]);

        TC_EfOfferRateFactorCalculator.calculate (updateList, relatedOpps);
        TC_EfOfferRateFactorCalculator.calculateFMV(updateList, relatedOpps);
    }
}