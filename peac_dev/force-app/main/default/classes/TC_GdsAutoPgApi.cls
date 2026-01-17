/**
 * @description       : SAL-2310 - New Integration call to GDS Auto PG Webservice
 * @author            : Joseph Cadd
 * @group             : 
 * @last modified on  : 12-30-2020
 * @last modified by  : Joseph Cadd
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   12-21-2020   Joseph Cadd   Initial Version
**/
public with sharing class TC_GdsAutoPgApi {
    public static String errorMessage = '';

    /*
    TEST RUN: 
    TC_GdsAutoPgApi.runAutoPG('0066300000CnzxEAAR', TC_GdsAutoPgUtils.TestDwhResponse());
    */
    public static String runAutoPG(Id recordId, TC_DwhStoredProcedureRespBean.resultBean dwhResults) {

        String reqXml;
        String respXml;
        TC_GdsAutoPgReqResp reqResp;
        XMLSerializer serializer = new XMLSerializer();

        try {
            // create request bean
            reqResp = TC_GdsAutoPgMapper.mapSalesforceToBean(recordId, dwhResults);

            // create request xml
            reqXml = serializer.serialize(reqResp.request, false, 'APPLICATIONDATA');
            //reqXml = TC_GdsScoreXmlUtil.serializeRequest(reqResp);

            // Replace tags with non-apex friendly naming
            reqXml = requestXmlReplacements(reqXml);

            System.debug('TC_GdsAutoPgApi runAutoPG reqXml: ' + reqXml);

            // do callout
            respXml = doCallout(reqXml, recordId);

            // map xml back to bean
            // Object testDeser = serializer.deSerializeUnTyped(respXml, new Set<String>{'PGSEQUENCINGOUTPUT'});
            
            //TC_GdsScoreXmlUtil.deSerializeResponse (reqResp, respXml);
		
        
            // MARLIN_IntegrationLog.addLog('GDS Auto PG', recordId, 'Success', reqXml, respXml, '', errorMessage);
        } catch (Exception e) {
            errorMessage = String.valueOf(e);
            System.debug('Error occurred in TC_GdsAutoPgApi: '+errorMessage);
            System.debug('Stack Trace: '+ e.getStackTraceString());
            System.debug('Line Number: '+ e.getLineNumber());
            System.debug('Message: '+ e.getMessage());
            System.debug('Type Name: '+ e.getTypeName());
            MARLIN_IntegrationLog.addLog('GDS Auto PG', '', 'Error', reqXml, respXml, '', errorMessage);
        } finally {
            MARLIN_IntegrationLog.insertLogs(); 

            // map bean to salesforce records
            updateSalesforceRecordData(respXml, reqResp);
        }

        return errorMessage;
    }

    public static String doCallout(String xmlRequest, Id recordId) {
        HttpRequest req = new HttpRequest();
        HTTPResponse resp = new HTTPResponse();
        Http http = new Http();
        String xmlResp = '';
        String salesforceError = '';

        req.setEndpoint(Label.GDS_Score);
        req.setMethod('POST');
        req.setBody(xmlRequest);
        req.setTimeout(120000);

        // extra try catches here to handle this logic differently than the rest
        try {
            MARLIN_IntegrationLog.startDurationTimer();
            resp = http.send(req);
            xmlResp = resp.getBody();
            MARLIN_IntegrationLog.endDurationTimer();

        } catch (Exception e) {
            system.debug('=====exception'+ e);
            salesforceError = String.valueOf(e);
        } finally {
            MARLIN_IntegrationLog.addLog('GDS Auto PG Callout', recordId, xmlResp != null && xmlResp != '' ? 'Success' : 'Failure', xmlRequest, xmlResp, resp.getStatusCode() != null ? String.valueOf (resp.getStatusCode()) : '', salesforceError);
        }
         System.debug ('>>>>> xmlResp: ' + xmlResp);
        
        return xmlResp;
        
    }

    public static void updateSalesforceRecordData(String xmlResponse, TC_GdsAutoPgReqResp reqResp) {
        if (xmlResponse==null || xmlResponse=='') {return;}
        System.debug('TC_GdsAutoPgApi updateSalesforceRecordData xmlresponse: ' + xmlResponse);

        DOM.Document document = new DOM.Document();
        document.load(xmlResponse);
        DOM.XmlNode pgSeqElement = document.getRootElement().getChildElement('PGSEQUENCINGOUTPUT', null);
        system.debug('======pgSeqElement' + pgSeqElement);

        String GatingCriteriaMet = pgSeqElement.getChildElement('GatingCriteriaMet', null)?.getText();
        String PGRequired = pgSeqElement.getChildElement('PGRequired', null)?.getText();
        String FraudPGRequired = pgSeqElement.getChildElement('FraudPGRequired', null)?.getText(); // addition for SAL-3079
        String PGRequired_Reason = pgSeqElement.getChildElement('PGRequired_Reason', null)?.getText();
        String CORPOnly_RiskGrade = pgSeqElement.getChildElement('CORPOnly_RiskGrade', null)?.getText();
        String MaxCorpOnly_Amount = pgSeqElement.getChildElement('MaxCorpOnly_Amount', null)?.getText();
        system.debug('GatingCriteriaMet'+ gatingCriteriaMet);
        system.debug('PGRequired_Reason'+ PGRequired_Reason);
        String Formatted_CORPOnly_RiskGrade = CORPOnly_RiskGrade==null || CORPOnly_RiskGrade=='' ? 'A3' : CORPOnly_RiskGrade;
        Decimal Formatted_PGRequired = PGRequired!=null && PGRequired!='' ? decimal.valueOf(PGRequired) : 0;
        Decimal Formatted_FraudPGRequired = FraudPGRequired!=null && FraudPGRequired!='' ? decimal.valueOf(FraudPGRequired) : 0;
        Decimal Formatted_GatingCriteriaMet = GatingCriteriaMet!=null && GatingCriteriaMet!='' ? decimal.valueOf(GatingCriteriaMet) : 0;

        if (reqResp.objectName == 'Opportunity') {
            Opportunity opp = new Opportunity(Id=reqResp.recordId);
            opp.Corp_Only_Risk_Grade__c = Formatted_CORPOnly_RiskGrade;
            opp.Credit_Risk_Grade__c = Formatted_CORPOnly_RiskGrade; // Addition for SAL-2396
            opp.Max_Corp_Only_Amount__c = MaxCorpOnly_Amount;
            opp.Gating_Criteria_Met__c = Formatted_GatingCriteriaMet;
            opp.PGRequired__c = (Formatted_FraudPGRequired == 1) ? Formatted_FraudPGRequired : Formatted_PGRequired; // SAL-3079
            opp.Fraud_PG_Required__c = Formatted_FraudPGRequired;
            System.debug('PGRequired: ' + opp.PGRequired__c);
            System.debug('FraudPGRequired: ' + opp.Fraud_PG_Required__c);
            System.debug('opp' + opp);
            update opp;
            if(!String.isEmpty(PGRequired_Reason))
            {
               List<Webservice_Field__c> oppWebserviceField = [Select Id,Reason_PG_Required__c from Webservice_Field__c where Opportunity__c=:reqResp.recordId limit 1];
                for(Webservice_Field__c wsf:oppWebserviceField)
                {
                    if(String.isEmpty(wsf.Reason_PG_Required__c))
                    {
                		wsf.Reason_PG_Required__c = PGRequired_Reason; 
                    }
                    else
                    {
                        wsf.Reason_PG_Required__c = wsf.Reason_PG_Required__c+', '+PGRequired_Reason; 
                    }
                }
                update oppWebserviceField;
            }
        } else if (reqResp.objectName == 'Lead') {
            Lead lead = new Lead(Id=reqResp.recordId);
            lead.Corp_Only_Risk_Grade__c = Formatted_CORPOnly_RiskGrade;
            lead.Max_Corp_Only_Amount__c = MaxCorpOnly_Amount;
            lead.Gating_Criteria_Met__c = Formatted_GatingCriteriaMet;
            lead.PGRequired__c = Formatted_PGRequired;
            update lead;
        }
        // GatingCriteriaMet (Data Type: Integer, Accepted Values: 1 or 0, Path: record/PGSEQUENCINGOUTPUT/GatingCriteriaMet)
        // PGRequired (Data Type: Integer, bAccepted Values: 1 or 0, Path: record/PGSEQUENCINGOUTPUT/PGRequired)
        // CORPOnly_RiskGrade (Data Type: String, Path: record/PGSEQUENCINGOUTPUT/CORPOnly_RiskGrade)
        // MaxCorpOnly_Amount (Data Type: Float with 2 decimal places Path: record/PGSEQUENCINGOUTPUT/MaxCorpOnly_Amount)
    }

    public static String requestXmlReplacements(String requestXml) {
        requestXml = requestXml.replaceAll('EQUIP_CODE>', 'EQUIP.CODE>');
        return requestXml;
    }
}