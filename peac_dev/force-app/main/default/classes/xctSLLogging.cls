public with sharing class xctSLLogging {

    public static void creatLog(String CallingAPI, String ObjectName, String Request, String Response) {
        creatLog(CallingAPI, ObjectName, '0', Request, Response);
    }
    public static void creatLog(String CallingAPI, String ObjectName, String IDO, String Request, String Response) {
        System.debug('creatLog:' + CallingAPI);
        try {
            DateTime createdOn = DateTime.NOW();
            SF2SLLog__c SLlog = new SF2SLLog__c(CreateDate__c=createdOn, Object__c=ObjectName,LogType__c=CallingAPI, IDField__c=IDO, Request__c=Request, Response__c=Response);
            insert SLlog;
        } catch(DmlException e) {
            System.debug('An unexpected error has occurred: ' + e.getMessage());
        }
    }

}