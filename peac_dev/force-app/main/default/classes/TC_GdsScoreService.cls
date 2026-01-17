/**
 * Handles Salesforce to GDS logic (callout)
 */

public with sharing class TC_GdsScoreService { 

    public static String doCallout (String xmlRequest, Id oppId) {
        HttpRequest req = new HttpRequest();
        HTTPResponse resp = new HTTPResponse ();
        Http http = new Http();
        String xmlResp = '';
        String salesforceError = '';

        req.setEndpoint(getGdsEndpoint(oppId));
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
            salesforceError = String.valueOf (e);
        } finally {
            MARLIN_IntegrationLog.addLog('GDS Score Callout', oppId, xmlResp != null && xmlResp != '' ? 'Success' : 'Failure', xmlRequest, xmlResp, resp.getStatusCode() != null ? String.valueOf (resp.getStatusCode()) : '', salesforceError);
        }
        System.debug ('>>>>> xmlResp: ' + xmlResp);
        System.debug ('>>>>> Request: ' + req);
        return xmlResp;
    }

    /******************************************************************************************************************
     * @Description: Get gds callout endpoint for lease and loan app
     * @Param: opportunity Id
     * @Return: String as gds endpoint
     ******************************************************************************************************************/
    public static String getGdsEndpoint(String oppId)
    {

        String gdsEndpoint = '';
        Opportunity opp = [SELECT Id, Loan_Record_Type__c FROM Opportunity WHERE Id =: oppId LIMIT 1];
        List<PEAC_GDS_End_Points__mdt> gdsEndpointList = [SELECT is_loan__c,CallType__c,Endpoint__c FROM PEAC_GDS_End_Points__mdt];
        if (gdsEndpointList !=null && !gdsEndpointList.isEmpty())
        {
            for(PEAC_GDS_End_Points__mdt gdsEndp: gdsEndpointList)
            {
              if (!gdsEndp.is_loan__c && !opp.Loan_Record_Type__c) {
                gdsEndpoint =  gdsEndp.Endpoint__c;
                break;
              }  
              else if(gdsEndp.is_loan__c && opp.Loan_Record_Type__c && PEAC_GDSScoreLoanAPI.callType == gdsEndp.CallType__c)  
              {
                gdsEndpoint =  gdsEndp.Endpoint__c;
                break;
              }         
              
            }
               
        }
        return gdsEndpoint;
    }
}