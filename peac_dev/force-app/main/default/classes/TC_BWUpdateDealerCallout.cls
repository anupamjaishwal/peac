/**
 * Created by jhber on 3/12/2019.
 */

public with sharing class TC_BWUpdateDealerCallout {

    public TC_BWDealerResponseBean updateDealer (TC_BWDealerRequestBean request) {
        TC_BWDealerResponseBean respBean;

        TC_BWUtility util = TC_BWUtility.getInstance();

        String editrequestJSON = JSON.serialize(request, true);
        String dealerNumber = request.Request.DealerNumber;
        IL10_Flag__c il10Setting = IL10_Flag__c.getValues('GeneralSetting');
        Boolean isIL10 = il10Setting.use_IL10__c; // this is IL10 only, regardless of record
        if(isIL10) editrequestJSON='{"inputs":' + editrequestJSON + '}';
        
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
                System.debug('editrequestJSON: ' + editrequestJSON);
                System.debug('editrequestJSON tail: ' + editrequestJSON.right(255));
                req.setTimeout(120000);

                HttpResponse resp = h.send(req);

                util.logInfo('updateDealer response body\n' + resp.getBody());
                String responseJSON = resp.getBody();
                System.debug('responseJSON: ' + responseJSON);
                System.debug('responseJSON tail: ' + responseJSON.right(255));
                if(isIL10 && !responseJSON.contains('"response"')){
                    responseJSON='{"response":'+responseJSON+'}';
                }else{
                    responseJSON = TC_BWResponseBean.unWrap(resp.getBody());
                }

                if (resp.getStatusCode() == 200) {
                    util.logInfo('updateDealer response string\n' + responseJSON);
                    respBean = (TC_BWDealerResponseBean) JSON.deserialize(responseJSON, TC_BWDealerResponseBean.class);
                    util.logInfo('TC_BWDealerResponseBean ######\n' + respBean);
                } else {
                    util.logError(resp.getStatusCode() + ' - ' + resp.getStatus() + '\n' + resp.getBody());
                    respBean = (TC_BWDealerResponseBean) JSON.deserialize(responseJSON, TC_BWDealerResponseBean.class);
                }
                insert new Integration_Log__c(
                    Name = 'Infolease Update Dealer',
                    Record_Id__c = dealerNumber,
                    Status__c = (resp.getStatusCode() == 200 ? 'Success' : 'Error'),
                    Error_Code__c = resp.getStatusCode() + '',
                    Error_Message__c = resp.getStatus(),
                    Request_Message__c = editrequestJSON,
                    Response_Message__c= responseJSON
                );

            } catch (Exception e) {
                System.debug(new TC_BWUpdateDealerCalloutException (e.getMessage() + e.getStackTraceString()));
                throw new TC_BWUpdateDealerCalloutException (e.getMessage());
            }
        } else {
            respBean = new TC_BWDealerResponseBean ();
        }
        return respBean;
    }
    
    public class TC_BWUpdateDealerCalloutException extends Exception {}
}