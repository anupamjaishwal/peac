/**
 * Created by andrewmayer on 9/16/20.
 * updates fields on the opportunity after a offer's selected status is selected/approved
 */

public with sharing class TC_EFOfferStatusIsSelected implements TC_TriggerActionI{

    public Set <String> selectedStatuses = new Set <String> {'Selected','Exception Approved'};
    public static final Id SYSTEM_GEN_RT = Schema.SObjectType.EF_Approved_Offers__c.getRecordTypeInfosByName().get('System').getRecordTypeId();

    public void doAction(TC_TriggerContext tc) {
        // on runs on after update
        Map <Id, EF_Approved_Offers__c> oldMap = (Map <Id, EF_Approved_Offers__c>) tc.getOldMap ();
        Map <Id, EF_Approved_Offers__c> newMap = (Map <Id, EF_Approved_Offers__c>) tc.getNewMap ();

        Map <Id, Opportunity> oppUpdates = new Map <Id, Opportunity> ();
        Set <Id> selected = new Set <Id> ();

        for (EF_Approved_Offers__c offer : newMap.values ()) {
            if (offer.Offer_Selected__c != null
                && selectedStatuses.contains(offer.Offer_Selected__c)
                && (oldMap == null || !selectedStatuses.contains(oldMap.get (offer.Id).Offer_Selected__c) )) {
                selected.add (offer.Id);
                
                /* Removed Section per sal 2884
                oppUpdates.put (offer.Opportunity__c
                , new Opportunity (Id = offer.Opportunity__c
                        , Payment_Amount__c = offer.Monthly_Payment__c
                        , Terms__c = offer.Term_in_Months__c
                        , X_Rate_Factor__c = offer.Rate_Factor__c
                        , Yield__c = offer.Yield__c
                        , of_Payments__c = offer.Term_in_Months__c
                        , EF_Approved_Offers__c = offer.Id));
                */
                Opportunity opp = new Opportunity (
                    Id = offer.Opportunity__c, 
                    Payment_Amount__c = offer.Monthly_Payment__c, 
                    Terms__c = offer.Term_in_Months__c, 
                    X_Rate_Factor__c = offer.Rate_Factor__c, 
                    Yield__c = offer.Yield__c, 
                    of_Payments__c = offer.Term_in_Months__c, 
                    EF_Approved_Offers__c = offer.Id
                );

                // SAL-2884 - If the new “Advanced Rental” field is set to First Payment, update the Opportunity.Required_Adv_Payments__c = 1; or 2 if First & Last Payment
                if (offer.Advanced_Rental__c=='First Payment') {
                    opp.Required_Adv_Payments__c = 1;
                } else if (offer.Advanced_Rental__c=='First & Last Payment') {
                    opp.Required_Adv_Payments__c = 2;
                }

                oppUpdates.put (offer.Opportunity__c, opp);
                
                // only custom has points set
                if (offer.RecordTypeId != SYSTEM_GEN_RT) oppUpdates.get (offer.Opportunity__c).Points__c = offer.Points__c;
            }
        }
        if (selected.isEmpty()) return;

        update oppUpdates.values ();

        // deselect rest
        List <EF_Approved_Offers__c> offersToDeSelect = new List <EF_Approved_Offers__c> ([SELECT Id,Offer_Selected__c FROM EF_Approved_Offers__c WHERE Opportunity__c IN :oppUpdates.keySet() AND Id NOT IN :selected AND Offer_Selected__c IN :selectedStatuses]);
        if (offersToDeSelect.isEmpty()) return;

        for (EF_Approved_Offers__c offer : offersToDeSelect) {
            offer.Offer_Selected__c = 'Not Selected';
        }
        update offersToDeSelect;
    }
}