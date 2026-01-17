/**
 * @File Name          : SL_InfoleaseUtils.cls
 * @Description        : Utility class for CCAN Account SF to IL via BW
 * @Author             : Silverline
 * @Group              :
 * @Last Modified By   :
 * @Last Modified On   :
 * @Modification Log   :
 * Ver       Date            Author                 Modification
 * 1.0    10/06/2021      Silverline                Initial Version
 */
public with sharing class SL_InfoleaseUtils {

    private static Bridgeware_Service_Setting__c setting;
    private static SL_InfoleaseUtils util;
    public static Boolean isRecursive = false;
    private SL_InfoleaseUtils() {}

    public static SL_InfoleaseUtils getInstance () {
        if (util == null) util = new SL_InfoleaseUtils ();
        return util;
    }

    public Bridgeware_Service_Setting__c getServiceSettings () {
        setting = Bridgeware_Service_Setting__c.getInstance();
        if (setting == null) setting = new Bridgeware_Service_Setting__c();

        return setting;
    }

    public void logInfo (String log) {
        if(getServiceSettings().Enable_Debug_Log__c){
            System.debug(LoggingLevel.INFO, '---INFO---> \n' + log );
        }
    }

    public void logError (String log) {
        if(getServiceSettings().Enable_Debug_Log__c){
            System.debug(LoggingLevel.ERROR, '---ERROR----> \n' + log );
        }
    }
    
    public static void updateRecordWithError(Id recordId){
        if(recordId == null) return;
        List<String> sObjectNamesList = new List<String>{'Account', 'Contract__c', 'Insurance__c', 'Contract_Asset__c'};
        String sObjectName = getsObjectName(recordId);
        if(!sObjectNamesList.contains(sObjectName)) return;

        sObject thisRec = recordId.getSObjectType().newSObject(recordId);
        thisRec.put('Integration_Status__c', 'Error');

        try {
            update thisRec;
            //EventBus.publish( new SL_BW_Integration_Status__e(Message__c = 'I am a test'));
        } catch (Exception e) {
            //supressing error
            System.debug('Error Occurred when Updating Account Integration Status to Error. Details: '+e.getMessage());
        }
    }
    public static void updateRecordWithSynced(Id recordId){

        if(recordId == null) return;
        List<String> sObjectNamesList = new List<String>{'Account', 'Contract__c', 'Insurance__c', 'Contract_Asset__c'};
        String sObjectName = getsObjectName(recordId);
        if(!sObjectNamesList.contains(sObjectName)) return;

        sObject thisRec = recordId.getSObjectType().newSObject(recordId);
        thisRec.put('Integration_Status__c', 'Synced');

        try {
            update thisRec;
            //EventBus.publish( new SL_BW_Integration_Status__e(Message__c = 'I am a test'));
        } catch (Exception e) {
            //supressing error
            System.debug('Error Occurred when Updating Account Integration Status to Synced. Details: '+e.getMessage());
        }
    }

    private static String getsObjectName(Id recordId){
        Schema.sObjectType sObjType = recordId.getSObjectType();
        Schema.DescribeSObjectResult sObjDescribeResult = sObjType.getDescribe();
        return sObjDescribeResult.getName();
    }

    public static Id getUserId(String userName){
        User thisUser;
        try {
            thisUser = [SELECT Id, Name FROM User WHERE Name =: userName LIMIT 1];
        } catch (Exception e) {
            System.debug('User not found: '+e.getMessage());
        }
         
        if (thisUser == null) return null;
        return thisUser.Id;
    }
}