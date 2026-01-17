/**
 * Created by andrewmayer on 9/16/20.
 *
 * updates rate factor on ef approved offer, deferral
 */

public with sharing class TC_OppDeferralChangedUpdateRateFactor{

  public static void doAction(Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
      
    Map <Id, Opportunity> deferralUpdates = new Map <Id, Opportunity> ();

    for (Opportunity opp : newMap.values()) {
      if (opp.Deferral_Payments__c != oldMap.get (opp.Id).Deferral_Payments__c) {
        deferralUpdates.put (opp.Id, opp);
      }
    }
    if (deferralUpdates.isEmpty()) return;

    List <EF_Approved_Offers__c> offers = new List <EF_Approved_Offers__c> ([SELECT Id,Yield__c,Term_in_Months__c, Opportunity__c,Advanced_Rental__c, Residual__c FROM EF_Approved_Offers__c WHERE Opportunity__c IN :deferralUpdates.keySet ()]);
    List<EF_Approved_Offers__c> updatedOffers = TC_EfOfferRateFactorCalculator.calculate (offers, deferralUpdates);
  
    UPDATE updatedOffers;
  }
}