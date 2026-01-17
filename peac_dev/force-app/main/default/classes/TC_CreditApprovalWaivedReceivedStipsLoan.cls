public class TC_CreditApprovalWaivedReceivedStipsLoan {
	@InvocableMethod
    public static void updateWaivedOrReceived (List <Id> oppIds) {
		TC_ChecklistStipsUtil.updateWaivedOrReceived (oppIds, 'Loan Credit Stips');
    }
}