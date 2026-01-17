/**
 * Callpoint for the GDS score api
 *
 * GDS doesn't have a bulk api, so the logic isn't bulkified. After talking with Marlin it was determined only 1 or 2 records would get sent over at once
 * Each request is fired off in it's own async context, this is to control the execution and avoid limits
 *  there are certain limitation issues with this approach, but can be handled programiticly easier.
 */
public with sharing class TC_GdsScoreApi {
    
    public static String errorMessage = '';

    
    /**
    * @description Primary RUN method for executing a GDS Score callout. 
    * @author Joseph Cadd | 02-19-2021 
    * @param Id recordId - Designed to receive an Opportunity Id argument
    * @return String errorMessage - Returns a string containing any/all errors that occurred. (Empty string = success)
    **/
    public static String runGdsScore (Id recordId) {
        String reqXml;
        String respXml;
        TC_GDSScoreReqRespBean reqResp = new TC_GDSScoreReqRespBean ();

        // automated process workaround
        /* ore = ORE__c.getInstance(Userinfo.getProfileId());
        if (ore == null) ore = new ORE__c();
        ORE__c ore2 = ORE__c.getOrgDefaults ();*/
        
        
        try {
            // If Gating Criteria is FALSE, do not send to GDS!
            Opportunity opp = [SELECT Id, Gating_Criteria_Met__c FROM Opportunity WHERE Id = :recordId];
            if (opp <> null) {
                if (opp.Gating_Criteria_Met__c == 0) {
                    throw new GdsScoreApiException('Gating criteria is not met! GDS scoring will not run.');
                }
            }

            // create request bean
            reqResp = TC_GdsScoreMapper.mapSalesforceToBean (recordId);
            // create request xml
            reqXml = TC_GdsScoreXmlUtil.serializeRequest(reqResp);
            // do callout
            respXml = TC_GdsScoreService.doCallout(reqXml, recordId);
            // map xml back to bean
            TC_GdsScoreXmlUtil.deSerializeResponse (reqResp, respXml);
            //added by Tyler for SAL-3159
			reqResp.xmlResponse = respXml != null ? respXml : reqResp.xmlResponse;
            // automated process workaround
            /*ore.GDS_Validation_Bypass__c = true;
            upsert ore;
            
            ore2.GDS_Validation_Bypass__c = true;
			upsert ore2;*/
            
            // map bean to salesforce records
            TC_GdsScoreMapper.mapBeanToSalesforce (reqResp);
            
        } catch (Exception e) {
            errorMessage = String.valueOf (e);
            MARLIN_IntegrationLog.addLog('GDS Score', '', 'Error', reqXml, respXml, '', errorMessage);
        } finally {
            MARLIN_IntegrationLog.insertLogs ();
            dmlSObjectCalloutRecords (reqResp);

            /* automated process workaround

            ore.GDS_Validation_Bypass__c = false;
            upsert ore;
            ore2.GDS_Validation_Bypass__c = false;
            upsert ore2;*/
        }
        return errorMessage;

    }

    // for use with apex triggers or process builders
    public static void runGdsScoreFromTriggeredAction (Set <Id> recordIds) {
        System.debug(LoggingLevel.Error, '*** recordIds: ' + recordIds);
        // todo add a limit and ensure this isn't being called from an async context
        // limit of 50 from non async
        
        
        // fire off autonumber, infolease logic, then when completed run gds. Logic is chained via platform events
        
        List <GDS_Action__e> actions = new List <GDS_Action__e> (); 
        
        // check for app number, if there's already an app number skip step
        // Updating the logic here for SAL-2317, we need to pull the guarantors and update them when re-scoring
        Map <Id, Opportunity> opps = new Map <Id, Opportunity> ([SELECT Id, Name, Application__c, (SELECT Id FROM Guarantor__r WHERE Included_in_Last_Score__c = FALSE) FROM Opportunity WHERE Id IN :recordIds]);
        List<Guarantor__c> guarantorToUpdate = new List<Guarantor__c>();
        for (Id recordId : recordIds) {
            Opportunity opp = opps.get(recordId);
            if (opp.Application__c == null) actions.add (new GDS_Action__e (Action__c = Label.TC_Gds_AppNumber, Record_Id__c = recordId));
            if (opp.Application__c != null) actions.add (new GDS_Action__e (Action__c = Label.TC_Gds_Infolease, Record_Id__c = recordId));
            //SAL-2317
            if (!opp.Guarantor__r.isEmpty()) for (Guarantor__c g : opp.Guarantor__r) g.Included_in_Last_Score__c = true;
            guarantorToUpdate.addAll(opp.Guarantor__r);

            //gdsActions.add (new GDS_Action__e (Action__c = Label.TC_Gds_Infolease, Record_Id__c = recordId));
            //System.enqueueJob (new TC_GDSScoreQueueable (recordId));
        }
        System.debug(LoggingLevel.Error, '*** actions: ' + actions);
        EventBus.publish(actions);
        //SAL-2317
        Database.update(guarantorToUpdate);
    }
    
    public static void dmlSObjectCalloutRecords (TC_GDSScoreReqRespBean reqResp) {
        // upsert gds score records
        
        List <Gds_Score_Request_Company__c> companyRequests = new List <Gds_Score_Request_Company__c> ();
        
        if (reqResp.company1 != new Gds_Score_Request_Company__c ()) companyRequests.add (reqResp.company1);
        if (reqResp.dealer != new Gds_Score_Request_Company__c ()) companyRequests.add (reqResp.dealer);
        if (reqResp.broker != new Gds_Score_Request_Company__c ()) companyRequests.add (reqResp.broker);
        if (reqResp.cc != new Gds_Score_Request_Company__c ()) companyRequests.add (reqResp.cc);
        
        upsert companyRequests;
        upsert reqResp.pgs;
        
        if (reqResp.broker.Id != null) reqResp.scoreReq.Broker__c = reqResp.broker.Id;
        if (reqResp.dealer.Id != null) reqResp.scoreReq.Dealer__c = reqResp.dealer.Id;
        if (reqResp.company1.Id != null) reqResp.scoreReq.Company_1__c = reqResp.company1.Id;
        if (reqResp.cc.Id != null) reqResp.scoreReq.Corporate_Guarantor__c = reqResp.cc.Id;
        
        for (Integer i = 0;i<4 && i < reqResp.pgs.size(); i++) {
            Integer pgFieldNum = i+1;
            reqResp.scoreReq.put ('Personal_Guarantor_' + pgFieldNum + '__c',reqResp.pgs[i].Id);
        }
        
        reqResp.scoreReq.Mapping_Error_Message__c = errorMessage;
        
        // checking for nulls just incase, something weird happens in the catch
        if (Limits.getCpuTime() != null && Limits.getLimitCpuTime() != null) reqResp.scoreReq.CPU_Time_Usage__c  = String.valueOf (Limits.getCpuTime()) + '/' + String.valueOf (Limits.getLimitCpuTime());
        if (Limits.getQueries() != null && Limits.getLimitQueries() != null) reqResp.scoreReq.SOQL_Query_Usage__c  = String.valueOf (Limits.getQueries()) + '/' + String.valueOf(Limits.getLimitQueries());
    
        upsert reqResp.scoreReq;
        
    }

    public class GdsScoreApiException extends Exception {}
}