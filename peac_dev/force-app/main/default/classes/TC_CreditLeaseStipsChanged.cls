/** @author : Northteq Consulting, Inc.
 * @date : 1/20/21
 * @description: This is a replacement for the first entry criteria in the process builder: "Opportunity - Credit Stip
 * Changed". If the lease stipulations field has changed, then update the Credit Stips checklist, which updates the
 * Stips for Approval Email field. This trigger action resolves a bug that causes the Stips for Approval Email merge
 * field to not be populated when DealerApproved emails are sent.
 *
 * Ticket number: SAL-2499
 */
public with sharing class TC_CreditLeaseStipsChanged {

    public static void updateStipulations(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {

        List<Id> oppIds = new List<Id>();

        for (Opportunity opp : newMap.values()) {
            if (opp.Stipulations__c <> oldMap.get(opp.Id).Stipulations__c && !opp.Loan_Record_Type__c) {
                oppIds.add(opp.Id);
            }
        }

        if (oppIds.size() > 0) {
            TC_CreditApprovalAddStipsToChecklist.updateStipulations(oppIds);
        }
    }
}