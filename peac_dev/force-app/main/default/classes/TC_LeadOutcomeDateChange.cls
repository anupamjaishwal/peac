/**
 * @description This class will make adjustments based on the lead out come changing
 * @see         SAL-1865
 */
public without sharing class TC_LeadOutcomeDateChange implements TC_TriggerActionI {

    public void doAction(TC_TriggerContext tc) {

        List<Lead> newLs = tc.getNewList() == null ? (List<Lead>) tc.getOldMap().values() : tc.getNewList();
        List<Lead> oldLs = tc.getOldMap() == null ? null : tc.getOldMap().values();
        bulkBefore(newLs, oldLs);

        if (tc.isBefore()) processBefore(newLs, oldLs);
    }

    /**
     * @description     This function will process the bulk changes to the record and do any fills that are needed
     *
     * @param newList   The triggered records
     * @param oldList   The previous versions of the triggered records
     */
    private void bulkBefore(List<Lead> newList, List<Lead> oldList) {

    }

    /**
     * @description     This function will process the before actions
     *
     * @param newList   The triggered records
     * @param oldList   The previous version of the triggered records
     */
    private void processBefore(List<Lead> newList, List<Lead> oldList) {
        Map<Id, Lead> oldMap = oldList != null ? new Map<Id, Lead> (oldList) : null;

        for (Lead l : newList == null ? oldMap.values() : newList) {
            adjustLeadOutcomeDate(l, oldMap != null ? oldMap.get(l.Id) : null);
        }
    }

    /**
     * @description This function will adjust the lead outcome date if the lead out come changes
     * @see         SAL-1865
     * @param l     The triggered record
     * @param lOld  The previous version of the triggered record
     *
     * @return      The adjusted record
     */
    private Lead adjustLeadOutcomeDate(Lead l, Lead lOld) {
        if (String.isNotBlank(l.Lead_Outcome__c) && fieldDiff(l, lOld, 'Lead_Outcome__c')) l.LeadOutcomeDate__c = Date.today();

        return l;
    }

    /**
     * @description     Checks if the field has changed
     *
     * @param l         The triggered record
     * @param lOld      The previous version of the triggered record
     * @param fieldNm   The field to check
     *
     * @return          If the field is different
     */
    private Boolean fieldDiff(Lead l, Lead lOld, String fieldNm) {
        return lOld == null || (l.get(fieldNm) != lOld.get(fieldNm));
    }
}