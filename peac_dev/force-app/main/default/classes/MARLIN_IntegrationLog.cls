public class MARLIN_IntegrationLog {
/****************************************************************************************
* @Author       Huron Team
* @Date         April 04, 2017
* @Description  Integration Call
*****************************************************************************************/	
    public static void LogException(String aIntName,String aRecordId, String aStatus,String aReqMessage,String aResMessage,String aErrCode,String aErrMessage){
        
        Integration_Log__c lIntLog = new Integration_Log__c(
            Name = aIntName,
            Record_Id__c = aRecordId,
            Status__c = aStatus,
            Request_Message__c = (aReqMessage.length() > 32000 ? aReqMessage.left(32000) : aReqMessage),
            Response_Message__c = aResMessage,
            Error_Code__c = aErrCode,
            Error_Message__c = aErrMessage
        );
        
        try{
        	if(System.Label.IntegrationLogFlag == 'Y')
             	insert lIntLog;        
               
        	}catch( QueryException ex ){
        	// supressing error;
        }
    }
    
    @Future
       public static void LogExceptionAsynch(String aIntName,String aRecordId, String aStatus,String aReqMessage,String aResMessage,String aErrCode,String aErrMessage){

        Integration_Log__c lIntLog = new Integration_Log__c(
            Name = aIntName,
            Record_Id__c = aRecordId,
            Status__c = aStatus,
            Request_Message__c = aReqMessage,
            Response_Message__c = aResMessage,
            Error_Code__c = aErrCode,
            Error_Message__c = aErrMessage
        );

        try{
            if(System.Label.IntegrationLogFlag == 'Y')
                insert lIntLog;        
               
        	}catch( QueryException ex ){
        	// supressing error;
        }
    }

    public static Integer startTime = 0;
    public static Integer calloutDuration = 0;

    public static void startDurationTimer() {
        startTime = Limits.getCpuTime();
    }
    public static void endDurationTimer() {
        calloutDuration =  Limits.getCpuTime() - startTime;
    }
    
    // Tamarack Added, bulk logging
    public static List <Integration_Log__c> logs = new List <Integration_Log__c>();
    
    public static void addLog (String aIntName,String aRecordId, String aStatus,String aReqMessage,String aResMessage,String aErrCode,String aErrMessage) {
        logs.add (
            new Integration_Log__c(
                Name = aIntName, 
                Record_Id__c = aRecordId, 
                Status__c = aStatus, 
                Request_Message__c = trimMessage (aReqMessage, 32000), 
                Response_Message__c = trimMessage(aResMessage,131071), 
                Error_Code__c = aErrCode, 
                Error_Message__c = trimMessage(aErrMessage,32767),
                Callout_Duration__c = calloutDuration
                )
            );
    }
    
    private static String trimMessage (String message, Integer fieldLimit) {
         return message != null && message.length() >= fieldLimit ? message.left(fieldLimit) : message;
    }
    
    public static void insertLogs () {
        if (System.Label.IntegrationLogFlag == 'Y') {
            try {
                // tam update
                for (Integration_Log__c log : logs) {
                    if (log.Record_Id__c != null && log.Record_Id__c instanceof Id && Id.valueOf (log.Record_Id__c).getSObjectType() == Schema.Opportunity.SObjectType) log.Opportunity__c = log.Record_Id__c;
                	if (log.Record_Id__c != null && log.Record_Id__c instanceof Id && Id.valueOf (log.Record_Id__c).getSObjectType() == Schema.Account.SObjectType) log.Account__c = log.Record_Id__c;
                    if (log.Record_Id__c != null && log.Record_Id__c instanceof Id && Id.valueOf (log.Record_Id__c).getSObjectType() == Schema.Contact.SObjectType) log.Contact__c = log.Record_Id__c;
                }
                insert logs;
                logs = new List <Integration_Log__c> ();
            } catch (Exception e) {
                System.debug ('Error logging errors');
            }
        }
    }
    
}