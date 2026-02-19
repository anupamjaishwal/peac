trigger xct_t_PayeeTrigger on Payee__c (after update,after insert) {

    for(Payee__c payee: Trigger.new){
        String s;
       
        System.debug('xct_t_PayeeTrigger ' + string.valueOf(payee.Update_Sequence__c)  );
        if(trigger.isUpdate) {
           
               //System.debug('UPDATE');
                s = JSON.serialize(payee);
                //System.debug(s);
                if (String.isBlank(payee.SL_Vendor_ID__c)) { 
                    xctDataClass.makeCallout('SFPAYEE', payee.Id, 'ADD', s);
                }
                else {
                    if (  payee.Update_Sequence__c == 0 ) {
                         xctDataClass.makeCallout('SFPAYEE', payee.Id, 'UPDATE', s);
                    }
                    else {
                        if (payee.Update_Sequence__c == 1 && !String.isBlank(payee.SL_Vendor_ID__c) && ( payee.ACH_Available__c == true || payee.Wire_Available__c == true)) {
                            // this should occur after the update from SL for the Vendor ID
                            if ( payee.EbankingExists__c == false) {
                                SolomonEBanking.Depositor( payee, 'ADD');
                            }
                            else {
                                SolomonEBanking.Depositor( payee, 'UPDATE');
                            }
                        }
                    }
                }

        }
        
        if(trigger.isInsert && payee.Payee_Name__c != 'Test Payee') {
           //System.debug('INSERT');
           s = JSON.serialize(payee);
            xctDataClass.makeCallout('SFPAYEE', payee.Id, 'ADD', s);
        }
    }
}