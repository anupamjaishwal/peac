public class TC_CreditApprovalAddStipsToChecklistLoan {
	@InvocableMethod
    public static void updateStipulations (List <Id> oppIds) {
		TC_ChecklistStipsUtil.updateStipulations (oppIds, 'Loan Credit Stips');
    }
}