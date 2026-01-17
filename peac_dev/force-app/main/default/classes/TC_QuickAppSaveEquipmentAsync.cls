public class TC_QuickAppSaveEquipmentAsync implements Queueable {
    
    public String clientWrapperJson;
    public Id oppId;
    public String action;
    
    public TC_QuickAppSaveEquipmentAsync (String clientWrapperJson, Id oppId, String action) {
        this.clientWrapperJson = clientWrapperJson;
        this.oppId = oppId;
        this.action = action;
    }
    
    public void execute(QueueableContext context) {
        String errorMessage = '';
        try {
            clientWrapperJson = TC_LoanApplicationCtrl.saveEquipment (clientWrapperJson, true, action);
        } catch (Exception e) {
            errorMessage = e.getMessage ();
        }
        
        TC_Quick_App_Notification__e notification = new TC_Quick_App_Notification__e (Opportunity_Id__c = oppId
                                                                                      , Message__c  = errorMessage
                                                                                     , Status__c = errorMessage != '' ? 'Failure' : 'Success'
                                                                                     ,Json_Data__c = clientWrapperJson
                                                                                     , Action__c =action);
        EventBus.publish(notification);
    }
    
    public class QuickAppAsyncException extends Exception {
        
    }

}