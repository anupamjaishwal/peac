/**
 * @File Name          : SL_InfoleaseLoggingUtils.cls
 * @Description        : Logging Utils for CCAN Account SF to IL via BW
 * @Author             : Silverline
 * @Group              :
 * @Last Modified By   :
 * @Last Modified On   :
 * @Modification Log   :
 * Ver       Date            Author                 Modification
 * 1.0    10/06/2021      Silverline                Initial Version
 */
public with sharing class SL_InfoleaseLoggingUtils {

    public static List <IL_Integration_Logs__c> logs = new List <IL_Integration_Logs__c>();

    public static SL_InfoleaseUtils util = SL_InfoleaseUtils.getInstance();
    
    
    public static void addLog(String a, Id b, String c, String d, String e){
        // to pass test validations, this must be removed when deploying
    }
    public static void addLog(String a, String b, String c, String d, String e){
        // to pass test validations, this must be removed when deploying
    }
    
    public static void addLog(String aIntName, String aRecordId, String aReqMessage, String resp, String aErrMessage, Boolean isErrorMessage) {
        addLog(aIntName, aRecordId, aReqMessage, resp, aErrMessage, isErrorMessage, 0);
    }

    public static void addLog(String aIntName, String aRecordId, String aReqMessage, String resp, String aErrMessage, Boolean isErrorMessage, Decimal waivedAmount) {
        logs.add (
            new IL_Integration_Logs__c(
                Integration_Name__c = aIntName, 
                Record_Id__c = aRecordId, 
                Request_Text__c = trimMessage (aReqMessage, 32767), 
                Error_Message__c = trimMessage(aErrMessage,32767),
                External_Id__c = isErrorMessage ? trimMessage(aErrMessage,255) : trimMessage(resp,255),
                ResponseText__c = trimMessage (resp, 32768),
                Type__c = isErrorMessage ? 'Error' : 'Success',
                Open_Item_Waived_Amount__c = waivedAmount
                )
            );
    }
    
    private static String trimMessage (String message, Integer fieldLimit) {
         return message != null && message.length() >= fieldLimit ? message.left(fieldLimit) : message;
    }
    
    public static void flush () {
        //separating success and error logs to be controlled by custom setting
        List<IL_Integration_Logs__c> successLogs = new List<IL_Integration_Logs__c>();
        List<IL_Integration_Logs__c> errorLogs = new List<IL_Integration_Logs__c>();
        try {
            // tam update
            for (IL_Integration_Logs__c log : logs) {
                if (log.Record_Id__c != null && log.Record_Id__c instanceof Id && Id.valueOf (log.Record_Id__c).getSObjectType() == Schema.Opportunity.SObjectType) log.Opportunity__c = log.Record_Id__c;
                if (log.Record_Id__c != null && log.Record_Id__c instanceof Id && Id.valueOf (log.Record_Id__c).getSObjectType() == Schema.Account.SObjectType) log.Account__c = log.Record_Id__c;
                if (log.Record_Id__c != null && log.Record_Id__c instanceof Id && Id.valueOf (log.Record_Id__c).getSObjectType() == Schema.Contact.SObjectType) log.Contact__c = log.Record_Id__c;
                if (log.Record_Id__c != null && log.Record_Id__c instanceof Id && Id.valueOf (log.Record_Id__c).getSObjectType() == Schema.Contract__c.SObjectType) log.Contract__c = log.Record_Id__c;
                if (log.Record_Id__c != null && log.Record_Id__c instanceof Id && Id.valueOf (log.Record_Id__c).getSObjectType() == Schema.Contract_Asset__c.SObjectType) log.ContractAsset__c = log.Record_Id__c;
                if (log.Record_Id__c != null && log.Record_Id__c instanceof Id && Id.valueOf (log.Record_Id__c).getSObjectType() == Schema.Insurance__c.SObjectType) log.Insurance__c = log.Record_Id__c;
                if(log.Type__c == 'Error') errorLogs.add(log);
                else if(log.Type__c == 'Success') successLogs.add(log);
            }
            if(util.getServiceSettings().Generate_Success_Logs__c){
                if(util.getServiceSettings().Upsert_Logs__c){
                    Database.upsert(errorLogs, IL_Integration_Logs__c.External_Id__c);
                    Database.upsert(successLogs, IL_Integration_Logs__c.External_Id__c);
                }else {
                    Database.insert(errorLogs);
                    Database.insert(successLogs);
                }
            }else{
                if(util.getServiceSettings().Upsert_Logs__c){
                    Database.upsert(errorLogs, IL_Integration_Logs__c.External_Id__c);
                }else {
                    Database.insert(errorLogs);
                }
            }
            
            logs = new List <IL_Integration_Logs__c> ();
        } catch (Exception e) {
            System.debug ('Error logging errors: '+e.getMessage());
        }    
    }
}