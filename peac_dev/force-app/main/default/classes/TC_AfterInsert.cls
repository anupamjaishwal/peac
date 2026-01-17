public class TC_AfterInsert {
public static void afterInsert(List <Opportunity> triggerNew) {
        TC_CreateUpdateVarPaymtRecIns.createUpdateVarialbePaymentRecordInsert(triggernew);
        TC_SubmitToAspire.submitToAspire (triggerNew);
        TC_BookToInfoLease.bookToInfoLease (triggerNew);
    }
}