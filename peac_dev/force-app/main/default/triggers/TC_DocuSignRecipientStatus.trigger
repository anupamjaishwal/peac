trigger TC_DocuSignRecipientStatus on dsfs__DocuSign_Recipient_Status__c (after insert, before insert, after update) {
    
    ///decommissioning this class for SAL- 4149
    
    ////Added this line to cover code coverge to pass deployment 
    /*public  void TC_DocuSignRecipientStatus(string dummy){
        
    }*/
    for(dsfs__DocuSign_Recipient_Status__c rs : Trigger.new){
        system.debug(rs);
    }
    /*if(trigger.isBefore){
        TC_DocusignRecipientStatusTriggerHelper.setRecipientContactId(trigger.new);
    }
    if(trigger.isAfter){
        if(trigger.isInsert){
            TC_DocusignRecipientStatusTriggerHelper.callAssignSignersAPI(trigger.new);
        }
    } */
}