/**
 * Created by tamarack on 2019-07-19.
 */

public without sharing class TC_OcrolusService {

    private static final Integer MAX_CALLOUT_FILE_SIZE = 10000000;
    
    public class OcrolusQueueable implements Queueable, Database.AllowsCallouts {

        String pk;
        String calloutType;
        Id attId;
        Id oppAttId;

        public OcrolusQueueable (String pk, Id attId, Id oppAttId, String calloutType) {
            this.pk = pk;
            this.calloutType = calloutType;
            this.attId = attId;
            this.oppAttId = oppAttId;
        }

        public void execute(QueueableContext context) {
            System.debug('::: TC_OcrolusService');
            System.debug('::: TC_OcrolusService calloutType '+calloutType);

            Attachment attachment = [SELECT Id, Name, Body FROM Attachment WHERE Id = :attId][0];
            if (calloutType == 'upload') uploadPDFCallout(pk, attachment, new Opportunity_Attachment__c (Id = oppAttId));
        }

    }

    public static String addBookCallout(Id oppId) {
        
        HTTPResponse resp = new HTTPResponse ();
        TC_OcrolusResponseBean responseBean = new TC_OcrolusResponseBean ();
        HttpRequest req = new HttpRequest();
        Boolean error = false;

        try {

            TC_OcrolusRequestBean requestBean = new TC_OcrolusRequestBean(oppId, 'addBook');

            req.setEndpoint('callout:Ocrolus_API/add');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(requestBean.contentJSON));

            if (requestBean.contentJSON.get('name').contains('null')) {
                responseBean = new TC_OcrolusResponseBean();
                responseBean.status = '';
                throw new OcrolusException('No Case Center # for book name');
            }

            Http http = new Http();
            resp = http.send(req);

            responseBean = (TC_OcrolusResponseBean) JSON.deserialize(resp.getBody(), TC_OcrolusResponseBean.class);

            if (responseBean.status == '200') {
                String pk = responseBean.response.pk;
                Opportunity updateOpp = new Opportunity(Id = oppId, Pk__c = pk);
                update updateOpp;
            } else {
                throw new OcrolusException(responseBean.message);
            }

        } catch (Exception e) {

            System.debug(e.getStackTraceString());
            String message = e.getMessage () != null && e.getMessage ().contains ('{') ? String.valueOf (e.getMessage ()).replace('{','').replace('}','') : e.getMessage ();
            responseBean.message = message;
            error = true;

        } finally {

            String reqBody = req.getBody() != null ? req.getBody() : '';

            String respStr = (resp == null) ? '' : ((resp.getBody() != null) ? resp.getBody().left (131071) : '');
            System.debug ('>>>>> reqBody: ' + reqBody);

            Marlin_IntegrationLog.LogException('Ocrolus File Upload', oppId, error ? 'Error' : 'Success', reqBody,
                    respStr, responseBean.status, responseBean.message);

        }

        if (!error) {
            return responseBean.response.pk;
        } else {
            return '';
        }

    }

    public static void uploadPDFCallout(String pk, Attachment attachment, Opportunity_Attachment__c oppAttach) {

        HTTPResponse resp = new HTTPResponse ();
        TC_OcrolusResponseBean responseBean = new TC_OcrolusResponseBean ();
        HttpRequest req = new HttpRequest();
        Boolean error = false;

        try {
            System.debug ('>>>>> TC_OcrolusService 103: ');
            System.debug ('>>>>> uploadPDFCallout pk: '+pk);
            TC_OcrolusRequestBean requestBean = new TC_OcrolusRequestBean(pk, attachment);
            System.debug ('>>>>> TC_OcrolusService 105: ');
            if (requestBean.pdfBlob.size() > MAX_CALLOUT_FILE_SIZE) {
                throw new OcrolusException('File size is too large (' + String.valueOf(requestBean.pdfBlob.size()) + ' bytes). The maximum ' +
                        'file size is ' + String.valueOf(MAX_CALLOUT_FILE_SIZE) + ' bytes. Not uploaded to Ocrolus');
            }
            System.debug ('>>>>> TC_OcrolusService 110: ');
            req.setHeader('Content-Type', 'multipart/form-data; boundary=' + requestBean.boundary);
            req.setHeader('Accept-Encoding', 'gzip, deflate');
            req.setMethod('POST');
            req.setEndpoint('callout:Ocrolus_API/upload');
            req.setBodyAsBlob(requestBean.pdfBlob);
            req.setTimeout(120000);
            System.debug ('>>>>> TC_OcrolusService 117: ');

            Http http = new Http();
            resp = http.send(req);

            responseBean = (TC_OcrolusResponseBean) JSON.deserialize(resp.getBody(), TC_OcrolusResponseBean.class);
            System.debug ('>>>>> response: ' + resp.getBody());
            if (responseBean != null && responseBean.response != null && responseBean.response.status != null) {
                responseBean.status = responseBean.response.status;
                throw new OcrolusException(responseBean.response.message);
            } else {
                oppAttach.Sent_To_Ocrolus__c = true;
                update oppAttach;
            }

        } catch (Exception e) {

            String message = e.getMessage () != null && e.getMessage ().contains ('{') ?
                    String.valueOf (e.getMessage ()).replace('{','').replace('}','') : e.getMessage ();
            responseBean.message = message;
            error = true;

        } finally {
            System.debug('::: FINALLY uploadPDFCallout');
            System.debug('::: FINALLY uploadPDFCallout ERROR ' + error);
                        System.debug('::: FINALLY  responseBean.message ' +  responseBean.message);


            String respStr = resp.getBody();
            respStr = respStr != null ? respStr.left (131071) : '';
            Marlin_IntegrationLog.LogException('Ocrolus File Upload', oppAttach.Id, error ? 'Error' : 'Success', req.getBody(),
                    respStr, responseBean.status, responseBean.message);

        }

    }

    /*public static TC_OcrolusResponseBean uploadImageCallout(String pk, Attachment attachment, Id oppAttachId) {

        HTTPResponse resp;
        TC_OcrolusResponseBean responseBean;
        HttpRequest req = new HttpRequest();
        Boolean error = false;

        try {

            TC_OcrolusRequestBean requestBean = new TC_OcrolusRequestBean(pk, attachment);

            if (requestBean.imageBlob.size() > MAX_CALLOUT_FILE_SIZE) {
                throw new OcrolusException('File size is too large (' + String.valueOf(requestBean.imageBlob.size()) + ' bytes). The maximum ' +
                        'file size is ' + String.valueOf(MAX_CALLOUT_FILE_SIZE) + ' bytes. Not uploaded to Ocrolus');
            }

            req.setHeader('Content-Type', 'multipart/form-data; boundary=' + requestBean.boundary);
            req.setHeader('Accept-Encoding', 'gzip, deflate');
            req.setMethod('POST');
            req.setEndpoint('callout:Ocrolus_API/upload/image');
            req.setBodyAsBlob(requestBean.imageBlob);
            req.setTimeout(120000);

            Http http = new Http();
            resp = http.send(req);

            responseBean = (TC_OcrolusResponseBean) JSON.deserialize(resp.getBody(), TC_OcrolusResponseBean.class);

            if (responseBean.response.status != null) {
                throw new OcrolusException(responseBean.response.message);
            }

        } catch (Exception e) {

            String message = e.getMessage () != null && e.getMessage ().contains ('{') ? String.valueOf (e.getMessage ()).replace('{','').replace('}','') : e.getMessage ();
            responseBean.message = message;
            error = true;

        } finally {

            String respStr = resp.getBody();
            respStr = respStr != null ? respStr.left (131071) : '';

            responseBean.log = new TC_OcrolusResponseBean.IntegrationLog('Ocrolus File Upload', oppAttachId, error,
                    req.getBody(), respStr, responseBean.status, responseBean.message);
            
        }

        return responseBean;

    }

    public static TC_OcrolusResponseBean doneImageCallout(String pk, Id oppAttachId) {

        HTTPResponse resp;
        TC_OcrolusResponseBean responseBean;
        HttpRequest req = new HttpRequest();
        Boolean error = false;

        try {

            TC_OcrolusRequestBean requestBean = new TC_OcrolusRequestBean(pk, 'doneImage');

            req.setHeader('Content-Type', 'application/json');
            req.setMethod('POST');
            req.setEndpoint('callout:Ocrolus_API/upload/image/done');
            req.setBody(JSON.serialize(requestBean.contentJSON));
            req.setTimeout(120000);

            Http http = new Http();
            resp = http.send(req);

            responseBean = (TC_OcrolusResponseBean) JSON.deserialize(resp.getBody(), TC_OcrolusResponseBean.class);

            if (responseBean.status != '200') {
                throw new OcrolusException(responseBean.message);
            }

        } catch (Exception e) {

            String message = e.getMessage () != null && e.getMessage ().contains ('{') ? String.valueOf (e.getMessage ()).replace('{','').replace('}','') : e.getMessage ();
            responseBean.message = message;
            error = true;

        } finally {

            String reqBody = req.getBody() != null ? req.getBody() : '';

            String respStr;
            if (resp == null) {
                respStr = '';
            } else {
                if (resp.getBody() != null) {
                    respStr = resp.getBody().left (131071);
                } else {
                    respStr = '';
                }
            }

            responseBean.log = new TC_OcrolusResponseBean.IntegrationLog('Ocrolus File Upload', oppAttachId, error,
                    reqBody, respStr, responseBean.status, responseBean.message);

        }

        return responseBean;

    }*/

    public class OcrolusException extends Exception {}

}