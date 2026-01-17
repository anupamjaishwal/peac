/************************************************************************************************************************
 @Description: Call Ocrolus API to pull the bank details from the bank statement and update the bank record
 @Author: Rajesh Kumar(LTIMindtree)
 @Created Date: 08/11/2025
 ************************************************************************************************************************/

public with sharing class PEAC_OcrolusRepullBankDetails {
    
    /*********************************************************************************************************************
    * @Description Primary RUN method for executing an Ocrolus Repull Bank. 
    * @Author:Rajesh Kumar
    * @Param: Id recordId - Designed to receive an Opportunity Id argument and executionType
    * @Return: None
    **********************************************************************************************************************/
  
    public static void executeOcrolusPull(String oppId)
    {
        String reqXml = '';
        String respXml = '';
        String errorMessage = '';
        List<Opportunity> oppList = [SELECT id,CaseCenter__c,PK__c FROM Opportunity WHERE Id =:oppId LIMIT 1];
        if(oppList!=null && !oppList.isEmpty())
        {
            try{
                reqXml = prepareXML(oppList[0]);
                // do callout
                respXml = TC_GdsScoreService.doCallout(reqXml, oppId);
            }catch (Exception ex) {
                errorMessage = String.valueOf (ex);
                MARLIN_IntegrationLog.addLog('GDS Ocrolus', '', 'Error', reqXml, respXml, '', errorMessage + ex.getStackTraceString());
            }finally {
                MARLIN_IntegrationLog.insertLogs ();
            }
            
        }
        
    }
    /*********************************************************************************************************************
    * @Description Primary RUN method for preparing an Ocrolus Repull Bank Payload. 
    * @Author:Rajesh Kumar
    * @Param: Opportunity record
    * @Return: String xml - Returns a string as XML body
    **********************************************************************************************************************/
  
    public static String prepareXML(Opportunity opp)
    {
        String xml = '<?xml version="1.0"?><APPLICATIONDATA>';
        xml += '<INFOLEASENUMBER>'+ opp.CaseCenter__c +'</INFOLEASENUMBER>';
        xml += '<CallType>Ocrolus</CallType>';
        xml += '<book_uuid></book_uuid>';
        xml += '<PKNumber>'+ opp.PK__c +'</PKNumber>';
        xml += '</APPLICATIONDATA>';
        return xml;
    }
}