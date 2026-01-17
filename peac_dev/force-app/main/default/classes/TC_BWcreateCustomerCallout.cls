/**
 * Created by jhber on 3/12/2019.
 */

public with sharing class TC_BWcreateCustomerCallout {
    
    // new instance variable
    public String recordId;

    public TC_BWCustomerResponseBean createCustomer(TC_BWCustomerRequestBean request) {

        TC_BWCustomerResponseBean respBean;

        TC_BWUtility util = TC_BWUtility.getInstance();
        IL10_Flag__c il10Setting = IL10_Flag__c.getValues('GeneralSetting');
        Boolean isIL10 = il10Setting.use_IL10__c; // this is IL10 only, regardless of record
        String requestJSON = JSON.serialize(request, true);
        //Have to add extra "input" object layer
        String editrequestJSON = isIL10? '{"inputs": ' + requestJSON + '}': requestJSON;
        System.debug('editrequestJSON: ' + editrequestJSON);
        util.logInfo(editrequestJSON);
        
        HttpResponse resp = new HttpResponse ();
        Http h = new Http ();
		HttpRequest req = new HttpRequest ();
        String errorMessage = '';

        if (request != null) {
            try {
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

                resp = h.send(req);

                util.logInfo('createCustomer response body\n' + resp.getBody());
                // String responseJSON = isIL10? '{"response": ' + resp.getBody() + '}': resp.getBody();
                String responseJSON = resp.getBody();
                System.debug('responseJSON: ' + responseJSON);
                if(isIL10){
                    responseJSON = TC_BWResponseBean.unWrap(responseJSON);
                }
                System.debug('StatusCode:' + resp.getStatusCode());
                if (resp.getStatusCode() == 200) {
                    util.logInfo('createCustomer response string\n' + responseJSON);
                    respBean = (TC_BWCustomerResponseBean) JSON.deserialize(responseJSON, TC_BWCustomerResponseBean.class);
                    util.logInfo('TC_BWCustomerResponseBean ######\n' + respBean);
                    
                    if (respBean.response.errors != null && !respBean.response.errors.isEmpty ()) {
                        
                        // infolease returns a ccan not being crated as an error if one already exists, but we don't want to treat it like one
                        String message = '';
                        for (String error : respBean.response.errors) {
                            System.debug ('????? error:' + error);
                            System.debug ('!error.containsIgnoreCase (\'already exists\')' + !error.containsIgnoreCase ('already exists'));
                            if (!error.containsIgnoreCase ('already exists')) message += error + ',';
                        }
                        if (String.isNotBlank(message) && message.contains(',')) message.removeEnd (',');
                        
                        //String message = String.join (respBean.response.errors,',');
                        if (!String.isNotBlank(message)) throw new TC_BWcreateCustomerCalloutException (message); 
                        
                    }


                } else {
                    util.logError(resp.getStatusCode() + ' - ' + resp.getStatus() + '\n' + resp.getBody());
                    if (!util.getServiceSettings().Mock_Callout__c) respBean = (TC_BWCustomerResponseBean) JSON.deserialize(responseJSON, TC_BWCustomerResponseBean.class);
                }

            } catch (Exception e) {
                errorMessage = e.getMessage();
                System.debug(new TC_BWcreateCustomerCalloutException (errorMessage + e.getStackTraceString()));
                throw new TC_BWcreateCustomerCalloutException (errorMessage);
            } finally {
                // newly added
                MARLIN_IntegrationLog.addLog('Infolease Create Customer'
                                             , recordId
                                             , errorMessage == '' ? 'Success': 'Error'
                                             , req != null ? req.getBody() : ''
                                             , resp != null ? resp.getBody() : ''
                                             , resp.getStatusCode() != null ? String.valueOf (resp.getStatusCode()) : ''
                                             , errorMessage);
            }
        } else {
            respBean = new TC_BWCustomerResponseBean ();
        }
        return respBean;
    }

    public class TC_BWcreateCustomerCalloutException extends Exception {}
}