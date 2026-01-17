public with sharing class optyApprovalController {    
    @AuraEnabled(cacheable=true)
    public static Approved_Offer__c getTopApprovedOffer(Id opptyId) {
        if (opptyId == null) return null;

        List<Approved_Offer__c> rows = [
            SELECT Id,
                   Approved_Frequency__c,
                   Select_for_approval__c,
                   Offer_Amount__c,
                   Term__c
            FROM Approved_Offer__c
            WHERE Opportunity__c = :opptyId
              AND Select_for_approval__c = true
              AND Offer_Amount__c > 0
            ORDER BY Offer_Amount__c DESC
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0];
    }

    public optyApprovalController() {
    }
}