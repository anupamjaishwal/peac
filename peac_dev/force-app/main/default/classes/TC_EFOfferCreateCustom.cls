/**
 * Created by andrewmayer on 9/16/20.
 *
 * // This created to fix the issue of custom selected offer not having a system generated offer to references
 * when checking the users authority to select
 */

public with sharing class TC_EFOfferCreateCustom implements TC_TriggerActionI{

    public static final Id SYSTEM_GEN_RT = Schema.SObjectType.EF_Approved_Offers__c.getRecordTypeInfosByName().get('System').getRecordTypeId();

    public void doAction(TC_TriggerContext tc) {
        List <EF_Approved_Offers__c> newList = (List <EF_Approved_Offers__c>) tc.getNewList ();

        Set <Id> oppIds = new Set <Id> ();

        for (EF_Approved_Offers__c offer : newList) {
            if (offer.RecordTypeId != SYSTEM_GEN_RT) oppIds.add(offer.Opportunity__c);
        }
        if (oppIds.isEmpty()) return;

        Map <Id, Opportunity> opps = new Map <Id, Opportunity> ([SELECT Id, (SELECT Id, Term_in_Months__c, Yield__c FROM EF_Approved_Offers__r ORDER BY Term_in_Months__c ASC) FROM Opportunity WHERE Id IN :oppIds]);
        List <EF_Approved_Offers__c> newSystemGens = new List <EF_Approved_Offers__c> ();

        // see if term for custom offer already exists, if not create on and interpolate it
        for (EF_Approved_Offers__c offer : newList) {

            // don't do greater than 60 or less than 24. 60 and 24 will be matches so we don't need to check them. No custom for SFP
            if (offer.RecordTypeId != SYSTEM_GEN_RT && offer.Term_in_Months__c >= 24 && offer.Term_in_Months__c <= 60 && opps.get (offer.Opportunity__c) != null) {
                Decimal lowerTermRate;
                Decimal lowerTerm;
                Decimal higherTermRate;
                //Decimal higherTerm;
                Boolean termExistsAlready = false;
                Decimal extraMonths = 0;

                for (EF_Approved_Offers__c offerLooper : opps.get (offer.Opportunity__c).EF_Approved_Offers__r) {
                    if (offerLooper.Term_in_Months__c == offer.Term_in_Months__c) {
                        termExistsAlready = true;
                        break;
                    } else if (offerLooper.Term_in_Months__c > offer.Term_in_Months__c) {
                        higherTermRate = offerLooper.Yield__c;
                        extraMonths = offer.Term_in_Months__c - lowerTerm;
                        break;
                    } else {
                        lowerTermRate = offerLooper.Yield__c;
                        lowerTerm = offerLooper.Term_in_Months__c;
                    }
                }
                if (!termExistsAlready){
                    // other processes default the rest. Rate factor/Monthly payment
                    newSystemGens.add (new EF_Approved_Offers__c (Opportunity__c = offer.Opportunity__c
                            , Term_in_Months__c = offer.Term_in_Months__c
                            , RecordTypeId = SYSTEM_GEN_RT
                            , Yield__c = TC_Rate.interpolate(lowerTermRate, higherTermRate, extraMonths)
                    ));
                }
            }
        }

        if (!newSystemGens.isEmpty()) insert newSystemGens;


    }
}