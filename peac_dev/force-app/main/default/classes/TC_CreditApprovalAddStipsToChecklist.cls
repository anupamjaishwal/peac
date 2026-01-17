public class TC_CreditApprovalAddStipsToChecklist {
    
    @InvocableMethod
    public static void updateStipulations (List <Id> oppIds) {
		TC_ChecklistStipsUtil.updateStipulations (oppIds, 'Credit Stips');
    }
}