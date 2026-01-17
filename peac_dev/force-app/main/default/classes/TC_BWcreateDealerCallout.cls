/**
 * Created by jhber on 3/12/2019.
 */

public with sharing class TC_BWcreateDealerCallout {

    public TC_BWDealerResponseBean createDealer(TC_BWDealerRequestBean request) {
        TC_BWDealerResponseBean respBean;

        TC_BWUtility util = TC_BWUtility.getInstance();

        String requestJSON = JSON.serialize(request, true);
        //Have to add extra "input" object layer
        String editrequestJSON = requestJSON;
        IL10_Flag__c il10Setting = IL10_Flag__c.getValues('GeneralSetting');
        Boolean isIL10 = il10Setting.use_IL10__c; // this is IL10 only regardless of the record
        if(isIL10){
            editrequestJSON = '{"inputs":' + editrequestJSON + '}';
        }
        system.debug('editrequestJSON: ' + editrequestJSON);
        util.logInfo(editrequestJSON);

        if (request != null) {
            try {
                Http h = new Http ();
                HttpRequest req = new HttpRequest ();

                if (util.getServiceSettings().Mock_Callout__c && !String.isEmpty(util.getServiceSettings().Mock_Callout_createCustomer__c)) {
                    Blob headerValue = Blob.valueOf('username' + ':' + 'password');
                    String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
                    req.setHeader('Authorization', authorizationHeader);
                    req.setEndpoint(util.getServiceSettings().Mock_Callout_createCustomer__c);

                } else {
                    if(isIL10){
                        TC_BWUtility.requestToIL10(req);
                    }else{
                        req.setEndpoint('callout:Bridgeware'+'/subroutine');
                    }
                }

                req.setMethod('POST');
                req.setHeader('CONFIG-NAME', util.getServiceSettings().Config_Name__c);
                req.setHeader('Content-Type','application/json');
                req.setBody(editrequestJSON);
                req.setTimeout(120000);

                HttpResponse resp = h.send(req);

                util.logInfo('createDealer response body\n' + resp.getBody());
                String responseJSON = TC_BWResponseBean.unWrap(resp.getBody());
                system.debug('responseJSON: ' + responseJSON);

                if (resp.getStatusCode() == 200) {
                    respBean = (TC_BWDealerResponseBean) JSON.deserialize(responseJSON, TC_BWDealerResponseBean.class);
                    util.logInfo('TC_BWDealerResponseBean ######\n' + respBean);


                } else {
                    util.logError(resp.getStatusCode() + ' - ' + resp.getStatus() + '\n' + resp.getBody());
                    respBean = (TC_BWDealerResponseBean) JSON.deserialize(responseJSON, TC_BWDealerResponseBean.class);
                }
                insert new Integration_Log__c(
                    Name = 'Infolease Create Dealer',
                    Record_Id__c = '',
                    Status__c = (resp.getStatusCode() == 200 ? 'Success' : 'Error'),
                    Error_Code__c = resp.getStatusCode() + '',
                    Error_Message__c = resp.getStatus(),
                    Request_Message__c = editrequestJSON,
                    Response_Message__c= resp.getBody()
                );
            } catch (Exception e) {
                System.debug(new TC_BWcreateDealerCalloutException (e.getMessage() + e.getStackTraceString()));
                throw new TC_BWcreateDealerCalloutException (e.getMessage());
            }
        } else {
            respBean = new TC_BWDealerResponseBean ();
        }
        return respBean;
    }

    public class TC_BWcreateDealerCalloutException extends Exception {}
}