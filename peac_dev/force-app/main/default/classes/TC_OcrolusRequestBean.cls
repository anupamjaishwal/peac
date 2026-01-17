/**
 * Created by tamarack on 2019-07-23.
 */

public with sharing class TC_OcrolusRequestBean {

    public Map<String, String> contentJSON;
    public Blob pdfBlob;
    public Blob imageBlob;

    public String boundary {
        get { return '-------------------OcrolusBoundary4930020x2dk2d84egschw62899'; }
        set;
    }

    public TC_OcrolusRequestBean(String parameter, String calloutType) {

        if (calloutType.contains('addBook')) {
            // parameter == oppId
            createAddBookBody(parameter);
        }
         /*else {
             parameter == pk
             createImageDoneBody(parameter);
         }*/
    }

    public TC_OcrolusRequestBean(String pk, Attachment attachment) {

        /*if (attachment.Name.substringAfterLast('.') == 'png' || attachment.Name.substringAfterLast('.') == 'jpeg') {
            createUploadImageBody(pk, attachment);
        }*/

        if (attachment.Name.substringAfterLast('.') == 'pdf' ) {
            createUploadPDFBody(pk, attachment);
        }

    }

    public void createAddBookBody(Id oppId) {

        Opportunity opp;
        List<Opportunity> oppList = new List<Opportunity>([SELECT PK__c, Account.Name, CaseCenter__c FROM Opportunity WHERE Id =: oppId]);
        if (!oppList.isEmpty()) opp = oppList[0];

        String bookName = opp.Account.Name + '-' + opp.CaseCenter__c;

        Map<String, String> JSONObj = new Map<String, String>();
        JSONObj.put('name', bookName);
        JSONObj.put('is_public', 'true');
        this.contentJSON = JSONObj;

    }
    /*
    public TC_OcrolusRequestBean(String pk, Attachment attachment) {


        if (attachment.Name.substringAfterLast('.') == 'pdf' ) {
            createUploadPDFBody(pk, attachment);
        }

    }*/
/*
    public void createAddBookBody(Id oppId) {

        Opportunity opp;
        List<Opportunity> oppList = new List<Opportunity>([SELECT PK__c, Account.Name, CaseCenter__c FROM Opportunity WHERE Id =: oppId]);
        if (!oppList.isEmpty()) opp = oppList[0];

        String bookName = opp.Account.Name + '-' + opp.CaseCenter__c;

        Map<String, String> JSONObj = new Map<String, String>();
        JSONObj.put('name', bookName);
        JSONObj.put('is_public', 'true');
        this.contentJSON = JSONObj;

    }*/

    public void createUploadPDFBody(String pk, Attachment attachment) {

        Blob fileBody = attachment.body;
        String fileName = attachment.name;
        String header1 = '--' + boundary + '\r\nContent-Disposition: form-data; name="pk"';
        String header1Encoded = EncodingUtil.base64Encode(Blob.valueOf(header1 + '\r\n\r\n'));
        while (header1Encoded.endsWith('=')) {
            header1 += ' ';
            header1Encoded = EncodingUtil.base64Encode(Blob.valueOf(header1 + '\r\n\r\n'));
        }
        

        String body1Encoded = EncodingUtil.base64Encode(Blob.valueOf(pk + '\r\n'));
     
        String last4Bytes = body1Encoded.substring(body1Encoded.length() - 4, body1Encoded.length());
        if (last4Bytes.endsWith('==')) {
            last4Bytes = last4Bytes.substring(0, 2) + '0K';
            body1Encoded = body1Encoded.substring(0, body1Encoded.length() - 4) + last4Bytes;
        } else if (last4Bytes.endsWith('=')) {
            last4Bytes = last4Bytes.substring(0, 3) + 'N';
            body1Encoded = body1Encoded.substring(0, body1Encoded.length() - 4) + last4Bytes;
        }

        String header = '--' + boundary + '\r\nContent-Disposition: form-data; name="upload"; filename="' + fileName +
                '";\r\nContent-Type: application/octet-stream';
        String headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header + '\r\n\r\n'));
        while (headerEncoded.endsWith('=')) {
            header += ' ';
            headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header + '\r\n\r\n'));
        }

        String bodyEncoded = EncodingUtil.base64Encode(fileBody);
        fileBody = null;
        attachment.body = null;
        System.debug(':::: bodyEncoded lenght  ' + bodyEncoded.length() );
        System.debug(':::: bodyEncoded lenght  ' + bodyEncoded );

        String footer = '--' + boundary + '--';
        String footerEncoded;
        System.debug(':::: createUploadPDFBody  116' );
        last4Bytes = bodyEncoded.substring(bodyEncoded.length() - 4, bodyEncoded.length());
        System.debug(':::: createUploadPDFBody  118' );

        if (last4Bytes.endsWith('==')) {
            last4Bytes = last4Bytes.substring(0, 2) + '0K';
            bodyEncoded = bodyEncoded.substring(0, bodyEncoded.length() - 4) + last4Bytes;
            footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
        } else if (last4Bytes.endsWith('=')) {
            last4Bytes = last4Bytes.substring(0, 3) + 'N';
            bodyEncoded = bodyEncoded.substring(0, bodyEncoded.length() - 4) + last4Bytes;
            footer = '\n' + footer;
            footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
        } else {
            footer = '\r\n' + footer;
            footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
        }
        System.debug(':::: createUploadPDFBody  133' );
        body1Encoded = header1Encoded + body1Encoded + headerEncoded + bodyEncoded + footerEncoded;
        this.pdfBlob = EncodingUtil.base64Decode(body1Encoded);

    }

    /*public void createUploadImageBody(String pk, Attachment attachment) {

        Blob fileBody = attachment.body;
        String fileName = attachment.name;

        string header1 = '--' + boundary + '\r\nContent-Disposition: form-data; name="pk"';
        String header1Encoded = EncodingUtil.base64Encode(Blob.valueOf(header1 + '\r\n\r\n'));
        while (header1Encoded.endsWith('=')) {
            header1 += ' ';
            header1Encoded = EncodingUtil.base64Encode(Blob.valueOf(header1 + '\r\n\r\n'));
        }

        String body1Encoded = EncodingUtil.base64Encode(Blob.valueOf(pk + '\r\n'));
        String last4Bytes = body1Encoded.substring(body1Encoded.length() - 4, body1Encoded.length());
        if (last4Bytes.endsWith('==')) {
            last4Bytes = last4Bytes.substring(0, 2) + '0K';
            body1Encoded = body1Encoded.substring(0, body1Encoded.length() - 4) + last4Bytes;
        } else if (last4Bytes.endsWith('=')) {
            last4Bytes = last4Bytes.substring(0, 3) + 'N';
            body1Encoded = body1Encoded.substring(0, body1Encoded.length() - 4) + last4Bytes;
        }

        String header = '--' + boundary + '\r\nContent-Disposition: form-data; name="file"; filename="' + fileName +
                '";\r\nContent-Type: image/png';
        String headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header + '\r\n\r\n'));
        while (headerEncoded.endsWith('=')) {
            header += ' ';
            headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header + '\r\n\r\n'));
        }

        String bodyEncoded = EncodingUtil.base64Encode(fileBody);

        String footer = '--' + boundary + '--';
        String footerEncoded;
        last4Bytes = bodyEncoded.substring(bodyEncoded.length() - 4, bodyEncoded.length());
        if (last4Bytes.endsWith('==')) {
            last4Bytes = last4Bytes.substring(0, 2) + '0K';
            bodyEncoded = bodyEncoded.substring(0, bodyEncoded.length() - 4) + last4Bytes;
            footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
        } else if (last4Bytes.endsWith('=')) {
            last4Bytes = last4Bytes.substring(0, 3) + 'N';
            bodyEncoded = bodyEncoded.substring(0, bodyEncoded.length() - 4) + last4Bytes;
            footer = '\n' + footer;
            footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
        } else {
            footer = '\r\n' + footer;
            footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
        }

        this.imageBlob = EncodingUtil.base64Decode(headerEncoded + bodyEncoded + header1Encoded + body1Encoded + footerEncoded);

    }

    public void createImageDoneBody(String pk) {

        Map<String, String> JSONObj = new Map<String, String>();
        JSONObj.put('pk', pk);
        JSONObj.put('form_type', 'BANK_ACCOUNT');
        this.contentJSON = JSONObj;

    }*/

}