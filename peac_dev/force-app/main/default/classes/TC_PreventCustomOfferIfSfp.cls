/**
 * Created by andrewmayer on 9/15/20.
 *
 * Jira: https://marlinbusiness.atlassian.net/browse/SAL-1824
 *  Users should not be able to create Custom EF Approved Offers
 *  if the Opportunity Lessor code is 421 OR 422 OR 423 OR 424
 */

// thought "Is sfp" should be a formula field

public with sharing class TC_PreventCustomOfferIfSfp implements TC_TriggerActionI{

    public Set <Decimal> sfpLessorCodes = new Set <Decimal> {421, 422, 423, 424};
    public String customEfApprovedOfferRt = Schema.SObjectType.EF_Approved_Offers__c.getRecordTypeInfosByName().get('Custom').getRecordTypeId();

    public void doAction(TC_TriggerContext tc) {
        List <EF_Approved_Offers__c> newList = (List <EF_Approved_Offers__c>) tc.getNewList ();

        Set <Id> oppIds = new Set <Id> ();

        for (EF_Approved_Offers__c offer : newList) {
            if (offer.RecordTypeId == customEfApprovedOfferRt && String.isNotBlank(offer.Opportunity__c)) oppIds.add (offer.Opportunity__c);
        }

        if (oppIds.isEmpty()) return;

        Map <Id, Opportunity> opps = new Map <Id, Opportunity> ([SELECT Id , Lessor__c FROM Opportunity WHERE Id IN :oppIds]);

        for (EF_Approved_Offers__c offer : newList) {
            if (offer.RecordTypeId == customEfApprovedOfferRt
                    && String.isNotBlank(offer.Opportunity__c)
                    && opps.get (offer.Opportunity__c) != null
                    && opps.get (offer.Opportunity__c).Lessor__c != null
                    && sfpLessorCodes.contains(opps.get (offer.Opportunity__c).Lessor__c)) {
                offer.addError(Label.TC_Prevent_Custom_Offers_if_SFP);
            }
        }
    }
}