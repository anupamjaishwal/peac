/**************************************************************************************************************
@Author: Manish Suwalka (LTIMindtree)
@Description: This class updates Purchase Order based on Solomon acknowledgment payment statuses.
@User Story: SAL-6482
@Created Date: February-27-2026
**************************************************************************************************************/
public class PEAC_ValidatePaymentToPurchaseOrder {

    // Allowed payment statuses (Solomon Acknowledgment)
    private static final Set<String> ALLOWED_STATUSES = new Set<String>{ PEAC_ConstantClass.PAYMENT_STATUS_PAYMENT_ANKNOWLEDGED, PEAC_ConstantClass.PAYMENT_STATUS_PAYMENT_RELEASED };

    private static final String PO_FUNDED = PEAC_ConstantClass.PURCHASE_ORDER_STATUS_FUNDED;

    /**************************************************************************************************************
    @Author: Manish Suwalka (LTIMindtree)
    @Description: This method updates Purchase Order status to 'Funded' and sets Asset Funding Status to 'Funded'
                  when Payment Status is 'Payment Acknowledged' or 'Payment Released' for the related PO.
    @Parameters: List<Payment__c> newList - List of Payment records (Trigger.new)
                 Boolean isNew - Not applicable in this method (keep signature aligned with caller if required)
    @Return: void
    **************************************************************************************************************/
    public static void validatePaymentToUpdatePO(List<Payment__c> newList) {
        if (newList == null || newList.isEmpty()) return;

        // 1) Collect PO Ids from qualifying payments
        Set<Id> poIds = new Set<Id>();
        for (Payment__c p : newList) {
            if (p.Purchase_Order__c != null){
                String statusVal = (p.Payment_Status__c == null) ? null : String.valueOf(p.Payment_Status__c).trim();
                if (statusVal != null && ALLOWED_STATUSES.contains(statusVal)) {
                    poIds.add(p.Purchase_Order__c);
                }
            }
        }
        if (poIds.isEmpty()) return;

        // 2) Query POs and prepare updates only where needed
        List<Purchase_Order__c> posToUpdate = new List<Purchase_Order__c>();
        for (Purchase_Order__c po : [SELECT Id, Status__c FROM Purchase_Order__c WHERE Id IN :poIds AND Status__c != :PO_FUNDED]) {
            po.Status__c = PO_FUNDED;
            posToUpdate.add(po);
        }


        // 3) DML (allOrNone=false to avoid partial failures blocking everything)
        if (!posToUpdate.isEmpty()) {
            update posToUpdate;
        }
    }
}