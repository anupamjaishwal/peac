trigger xct_t_PayeeDelete on Payee__c (before delete) {

    for(Payee__c payee : trigger.old){
        if (!String.isBlank(payee.SL_Vendor_ID__c)) { 
            payee.adderror('Payee with a Dynamics SL Vendor cannot be deleted. You can mark it inactive');
        }
    }

}