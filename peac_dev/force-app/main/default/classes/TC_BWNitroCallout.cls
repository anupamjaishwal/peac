/**
 * Created by jhber on 3/12/2019.
 */

public with sharing class TC_BWNitroCallout {

    public String callout (TC_BWRequestBean request, String recordId) {
        //TC_BWResponseBean respBean;
        String responseJSON = '';

        TC_BWUtility util = TC_BWUtility.getInstance();

        String requestJSON = JSON.serialize(request, true);
        //Have to add extra "input" object layer
        String editrequestJSON = '{ "inputs": ' + requestJSON + ' }';
        System.debug ('editrequestJSON: ' + editrequestJSON);
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
                    req.setEndpoint('callout:BridgewareNitro');
                }

                req.setMethod('POST');
                req.setHeader('CONFIG-NAME', util.getServiceSettings().Config_Name__c);
                req.setHeader('Content-Type', 'application/json');
                req.setBody(editrequestJSON);
                req.setTimeout(120000);

                HttpResponse resp = h.send(req);

                util.logInfo('Nitro API response body\n' + resp.getBody());
                responseJSON = TC_BWResponseBean.unWrap(resp.getBody());

                if (resp.getStatusCode() == 200) {
                    util.logInfo('Nitro API response string\n' + responseJSON);
                } else {
                    util.logError(resp.getStatusCode() + ' - ' + resp.getStatus() + '\n' + resp.getBody());
                }
                //respBean = (TC_BWResponseBean) JSON.deserialize(responseJSON, TC_BWResponseBean.class);

            } catch (Exception e) {
                System.debug(new TC_BWNitroCalloutException (e.getMessage() + e.getStackTraceString()));
                throw new TC_BWNitroCalloutException (e.getMessage());
            }
        }
        return responseJSON;
    }

    public class TC_BWNitroCalloutException extends Exception {}
}