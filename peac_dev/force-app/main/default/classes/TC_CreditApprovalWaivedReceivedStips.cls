public class TC_CreditApprovalWaivedReceivedStips {
	@InvocableMethod
    public static void updateWaivedOrReceived (List <Id> oppIds) {
		TC_ChecklistStipsUtil.updateWaivedOrReceived (oppIds, 'Credit Stips');
    }
}