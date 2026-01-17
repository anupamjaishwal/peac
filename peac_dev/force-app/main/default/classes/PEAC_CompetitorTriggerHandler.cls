/**************************************************************************************************************
@Author:D Balakrishna(LTIMindtree)
@Description:This class contains the business logic of Competitor Trigger where in with respect to US requirement handles the check/uncheck functionality of Financial Object records based on Competitor records 
@User Story:SAL-5810
@Created Date:November-25-2025
**************************************************************************************************************/
public class PEAC_CompetitorTriggerHandler {
    private static Boolean hasRun = false;
    public static Boolean isFirstRun() {
        if (hasRun) {
            return false;
        } else {
            hasRun = true;
            return true;
        }
    }	
    // Test-only helper to reset the re-entrancy guard in the same transaction
    @TestVisible
    static void resetHasRunForTest() {
        hasRun = false;
    }
    public void afterInsert(List<Competitor__c> newList) {
        processCompetitorChange(newList, null);
    }
    public void afterUpdate(List<Competitor__c> newList, List<Competitor__c> oldList) {
        processCompetitorChange(newList, oldList);
    }
    public void afterDelete(List<Competitor__c> oldList) {
        processCompetitorChange(null, oldList);
    }
    public void afterUndelete(List<Competitor__c> newList) {
        processCompetitorChange(newList, null);
    }    
    private void processCompetitorChange(List<Competitor__c> newList, List<Competitor__c> oldList) {
        try {
            Set<Id> financialIds = new Set<Id>();
            if (newList != null) {
                for (Competitor__c comp : newList) {
                    if (comp != null && comp.Financial__c != null) {
                        financialIds.add(comp.Financial__c);
                    }
                }
            }
            if (oldList != null) {
                for (Competitor__c comp : oldList) {
                    if (comp != null && comp.Financial__c != null) {
                        financialIds.add(comp.Financial__c);
                    }
                }
            }
            if (financialIds.isEmpty()) {
                System.debug('No Financial IDs found to update.');
                return;
            }
            Map<Id, Integer> countsByFin = new Map<Id, Integer>();
            for (AggregateResult ar : [SELECT Financial__c fId, COUNT(Id) cnt FROM Competitor__c WHERE Financial__c IN :financialIds
                GROUP BY Financial__c]) {
                countsByFin.put((Id) ar.get('fId'), (Integer) ar.get('cnt'));
            }
            List<Financial__c> updates = new List<Financial__c>();
            for (Financial__c fin : [SELECT Id, Competitor__c FROM Financial__c WHERE Id IN :financialIds]) {
                Integer cnt = countsByFin.containsKey(fin.Id) ? countsByFin.get(fin.Id) : 0;
                Boolean shouldBeTrue = (cnt > 0);
                if (fin.Competitor__c != shouldBeTrue) {
                    fin.Competitor__c = shouldBeTrue;
                    updates.add(fin);
                }
            }
            if (!updates.isEmpty()) {
                update updates;
            }

        } catch (Exception ex) {
            System.debug('Error in CompetitorTriggerHandler: ' + ex.getMessage());
        }
    }
}