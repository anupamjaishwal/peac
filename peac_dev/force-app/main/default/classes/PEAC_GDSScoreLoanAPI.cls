/************************************************************************************************************************
 @Description: Callpoint for the GDS score api
                GDS doesn't have a bulk api, so the logic isn't bulkified. After talking with Marlin it was determined 
                only 1 or 2 records would get sent over at once
                Each request is fired off in it's own async context, this is to control the execution and avoid limits
                there are certain limitation issues with this approach, but can be handled programiticly easier.
 @Author: Rajesh Kumar(LTIMindtree)
 @Created Date: 06/16/2025
 ************************************************************************************************************************/
public with sharing class PEAC_GDSScoreLoanAPI {
    
    public static String errorMessage = '';
    public static String callType = 'SF';
    /*********************************************************************************************************************
    * @Description Primary RUN method for executing a GDS Score callout. 
    * @Author:Rajesh Kumar
    * @Param: Id recordId - Designed to receive an Opportunity Id argument and executionType
    * @Return: String errorMessage - Returns a string containing any/all errors that occurred. (Empty string = success)
    **********************************************************************************************************************/
    public static String runGdsScore (Id recordId) {
        String reqXml;
        String respXml;
        PEAC_GDSScoreLoanReqRespBean reqResp = new PEAC_GDSScoreLoanReqRespBean ();

               
        try {
            
            // create request bean
            reqResp = PEAC_GdsScoreLoanMapper.mapSalesforceToBean (recordId);
            // create request xml
            reqXml = PEAC_GdsScoreLoanXmlUtil.serializeRequest(reqResp);
            // do callout
            respXml = TC_GdsScoreService.doCallout(reqXml, recordId);
            // map xml back to bean
            //PEAC_GdsScoreLoanXmlUtil.deSerializeResponse (reqResp, respXml);
            //added by Tyler for SAL-3159
			reqResp.xmlResponse = respXml != null ? respXml : reqResp.xmlResponse;
                       
            // map bean to salesforce records
            //PEAC_GdsScoreLoanMapper.mapBeanToSalesforce (reqResp);
            
        } catch (Exception ex) {
            errorMessage = String.valueOf (ex);
            MARLIN_IntegrationLog.addLog('GDS Score', '', 'Error', reqXml, respXml, '', errorMessage + ex.getStackTraceString());
        } finally {
            MARLIN_IntegrationLog.insertLogs ();
            dmlSObjectCalloutRecords (reqResp);
        PEAC_GuarantorHandler.updateSyncGuarantor(recordId);
            
        }
        return errorMessage;

    }

    public static void dmlSObjectCalloutRecords (PEAC_GDSScoreLoanReqRespBean reqResp) {
        // upsert gds score records
        // upsert gds score records
        List <Gds_Score_Request_Company__c> companyRequestsList = new List <Gds_Score_Request_Company__c> ();
        if (reqResp.company1 != new Gds_Score_Request_Company__c ()) companyRequestsList.add (reqResp.company1);
        if (reqResp.broker != new Gds_Score_Request_Company__c ()) companyRequestsList.add (reqResp.broker);
        
        upsert companyRequestsList;

        upsert reqResp.pgs;
        if(reqResp.opp!=null){
            update reqResp.opp;
        }
        if (reqResp.company1.Id != null)
        {
            reqResp.scoreReq.Company_1__c = reqResp.company1.Id;
        }
        if (reqResp.broker.Id != null)
        {
            reqResp.scoreReq.Broker__c = reqResp.broker.Id;
        } 
        for (Integer i = 0;i<4 && i < reqResp.pgs.size(); i++) {
            Integer pgFieldNum = i+1;
            reqResp.scoreReq.put ('Personal_Guarantor_' + reqResp.pgs[i].PG_Number__c + '__c',reqResp.pgs[i].Id);
        }
        reqResp.scoreReq.Mapping_Error_Message__c = errorMessage;
        
        // checking for nulls just incase, something weird happens in the catch
        if (Limits.getCpuTime() != null && Limits.getLimitCpuTime() != null) reqResp.scoreReq.CPU_Time_Usage__c  = String.valueOf (Limits.getCpuTime()) + '/' + String.valueOf (Limits.getLimitCpuTime());
        if (Limits.getQueries() != null && Limits.getLimitQueries() != null) reqResp.scoreReq.SOQL_Query_Usage__c  = String.valueOf (Limits.getQueries()) + '/' + String.valueOf(Limits.getLimitQueries());
    
        upsert reqResp.scoreReq Gds_Score_External_Id__c;
        
    }

    public class PEAC_GDSScoreLoanAPIException extends Exception {}
}