/**
 * Created by andrewmayer on 9/15/20.
 *
 * default yield and term for custom offers
 */

public with sharing class TC_CustomEfOfferDefaults implements TC_TriggerActionI{

    public final Id SYSTEM_GEN_RT = Schema.SObjectType.EF_Approved_Offers__c.getRecordTypeInfosByName().get('System').getRecordTypeId();

    public void doAction(TC_TriggerContext tc) {
        // before insert
        List <EF_Approved_Offers__c> newList = (List <EF_Approved_Offers__c>) tc.getNewList ();

        Set <Id> oppIds = new Set <Id> ();
        for (EF_Approved_Offers__c offer : newList) {
            if (offer.RecordTypeId != SYSTEM_GEN_RT && String.isNotBlank(offer.Opportunity__c)) oppIds.add (offer.Opportunity__c);
        }
        if (oppIds.isEmpty()) return;

        Map <Id, Opportunity> defaultValues = new Map <Id, Opportunity> ([SELECT Id, Yield__c, Terms__c FROM Opportunity WHERE Id IN :oppIds]);

        for (EF_Approved_Offers__c offer : newList) {
            if (offer.RecordTypeId != SYSTEM_GEN_RT && String.isNotBlank(offer.Opportunity__c) && defaultValues.get (offer.Opportunity__c) != null) {
                Opportunity opp = defaultValues.get (offer.Opportunity__c);
                if (offer.Yield__c == null) offer.Yield__c = opp.Yield__c;
                if (offer.Term_in_Months__c == null) offer.Term_in_Months__c = opp.Terms__c;
            }
        }
    }
}