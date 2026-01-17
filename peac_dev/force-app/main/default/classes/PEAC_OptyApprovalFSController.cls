/**************************************************************************************************************
@Author:D Balakrishna(LTIMindtree)
@Description:This class contains the business logic that ensures fulfillment of requirement of displaying Approval Section fields which fetches left side data from Approver and Right Side data from Opportunity
@User Story:SAL-5999
@Created Date:November-25-2025
**************************************************************************************************************/
public with sharing class PEAC_OptyApprovalFSController {
    @AuraEnabled(cacheable=true)
    public static Approved_Offer__c getTopApprovedOffer(Id opptyId) {
        if (opptyId == null) return null;
        List<Approved_Offer__c> rows = [SELECT Id,Approved_Frequency__c,Select_for_approval__c,Offer_Amount__c,Term__c FROM Approved_Offer__c
            WHERE Opportunity__c = :opptyId AND Select_for_approval__c = true AND Offer_Amount__c > 0
            ORDER BY Offer_Amount__c DESC LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0];
    }
    public PEAC_OptyApprovalFSController() {

    }
}