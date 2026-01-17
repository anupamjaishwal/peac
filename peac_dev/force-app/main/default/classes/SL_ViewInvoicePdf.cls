public with sharing class SL_ViewInvoicePdf {
    
    @AuraEnabled
    public static string hubExecute(String methodName, List<String> parameters){
        String result = '';
        try {
            switch on methodName {
                when 'generateUrl'{
                    result = generateUrl(parameters[0]);
                }
            }
        } catch (Exception e) {
            system.debug('e: ' + e);
            system.debug('e.getMessage(): ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
        return result;
    }

    static string generateUrl(String recordId){
        String invoiceLink = '';
        String contractId = '';
        String result = '';
        Boolean isIL10 = false;
        Boolean isMigrated = false;
        List<Invoice__c> calledInvoice = [SELECT Id, Name, Contract__r.Infolease_Environment__c, Contract__r.Name,
            Contract__r.CCAN__c, Contract__r.RecordTypeId, Migrated__c, Invoice_Date__c
            FROM Invoice__c WHERE Id = :recordId];
        system.debug('calledInvoice: ' + calledInvoice);

        if(calledInvoice.size() > 0 && calledInvoice[0].Contract__r != null){
            if(calledInvoice[0].Migrated__c == '001'){
                invoiceLink = SL_OnBaseCallout.buildOnBaseUrl(calledInvoice[0].Contract__r, 'LC - EndUser Invoices', calledInvoice[0].Name);
                isMigrated = true;
            }else{
                isIL10 = TC_BWUtility.isIL10Record(calledInvoice[0].Contract__r);
                if(!isIL10){
                    // DP-1584 Misael Romero
                    // invoiceLink = buildIL9Url(calledInvoice[0]);
                    invoiceLink = buildIL10Url(calledInvoice[0], isIL10);
                }else{
                    invoiceLink = buildIL10Url(calledInvoice[0]);
                }
            }
            contractId = calledInvoice[0].Contract__c;
        }
        if(invoiceLink.contains('errorMessage: ')){
            result = '{"errorMessage": '+ JSON.serialize(invoiceLink.substringAfter('errorMessage: '))
                + (contractId != ''? ', "contractId": ' + JSON.serialize(contractId): '') + '}';
        }else{
            result = '{"invoiceLink": ' + JSON.serialize(invoiceLink) 
                + ', "contractId": ' + JSON.serialize(contractId) + ', "isIL10": ' + JSON.serialize(isIL10)
                + ', "isMigrated": ' + JSON.serialize(isMigrated) + '}';
        }
        return result;
    }

    @testVisible
    static String buildIL9Url(Invoice__c theInvoice){
        Bridgeware_Service_Setting__c bridgewareSetting = TC_BridgewareUtility.getInstance().getServiceSettings();
        String encryptionAlgorithm = 'AES256';
        String marlinBillPayCsr = bridgewareSetting.IL9_Osg_Url__c + '/API.aspx?req=';
        String marlinKey = '8576570478FB4B6B8B2E026090345BEB';
        // String marlinKey = '8576570478FB4B6B8B2E026090345B124326790D63EA49CA81701A98DD60EBA3';
        String marlinIV = 'D372FAFB49884181'; // D372FAFB49884181 D372FAFB49884181D372FAFB49884181
        String requestXml = '<REQUEST clientId="7ba3ba55-0e0e-4e2d-8c0a-6c3be31cb8a8" reqId="1" ts="'
            + String.valueOfGmt(Datetime.now()) + '.' + String.valueOf(Integer.valueOf(Math.random() * 1000)).leftPad(3, '0') + '" type="DOCPDFBYINVNBRRCNT"><PARAMETER key="invNbr" val="';
        requestXml += theInvoice.Name; // invoice Number
        requestXml += '" /><PARAMETER key="contentDisposition" val="INLINE" /></REQUEST>';
        // blocksize is not needed for AES so the below is not needed
        // Integer blockSize = 8;
        // Integer padding = blockSize - Math.mod(requestXml.length(), blockSize);
        // Map<Integer, String> charsByCodePoint = new Map<Integer, String>{
        //     /*0 => '\u0000',*/
        //     1 => '\u0001',
        //     2 => '\u0002',
        //     3 => '\u0003',
        //     4 => '\u0004',
        //     5 => '\u0005',
        //     6 => '\u0006',
        //     7 => '\u0007',
        //     8 => '\u0008'
        // };
        // requestXml = requestXml + charsByCodePoint.get(padding).repeat(padding);
        Blob encrypted = Crypto.encrypt(encryptionAlgorithm, Blob.valueOf(marlinKey),
            Blob.valueOf(marlinIV), Blob.valueOf(requestXml));
        String encodedString = EncodingUtil.base64Encode(encrypted);
        Blob decrypted = Crypto.decrypt(encryptionAlgorithm, Blob.valueOf(marlinKey), Blob.valueOf(marlinIV), encrypted);
        String decryptedString = decrypted.toString();
        system.debug('decriptedString: ' + decryptedString);
        System.assertEquals(requestXml, decryptedString);
        String url = marlinBillPayCsr + encodedString;
        
        return url;
    }

    static String buildIL10Url(Invoice__c theInvoice){
        return buildIL10Url(theInvoice, true);
    }

    static String buildIL10Url(Invoice__c theInvoice, Boolean isIL10){
        Bridgeware_Service_Setting__c bridgewareSetting = TC_BridgewareUtility.getInstance().getServiceSettings();
        // so invNumberToSend was theInvoice.Name + ' ' + theInvoice.Contract__r.Name
        Boolean canIncludeContractName = true;
        List<String> dateParts = Label.SL_DateToUseContractNumber.split('/');
        Date dateToUseContractName = Date.newInstance(Integer.valueOf(dateParts[2]), Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]));
        if(!isIL10 && theInvoice.Invoice_Date__c <= dateToUseContractName){
            canIncludeContractName = false;
        }
        String invNumberToSend = EncodingUtil.urlEncode(theInvoice.Name, 'UTF-8').replaceAll('\\+', '%20');
        String url = bridgewareSetting.IL10_Osg_Url__c + '?AccountNumber=' 
            + theInvoice.Contract__r.CCAN__c + (canIncludeContractName? '&documentNumber=' 
            + theInvoice.Contract__r.Name: '') + '&DocumentKey=' 
             + invNumberToSend + '&IncludeArchived=true';
        System.debug('osg url: ' + url);
        Http h = new Http ();
        HttpRequest req = new HttpRequest ();
        req.setMethod('GET');
        req.setHeader('accept', 'text/plain');
        req.setHeader('x-api-key', bridgewareSetting.IL10_Osg_ApiKey__c);
        req.setEndpoint(url);
        req.setTimeout(120000);
        HttpResponse resp = h.send(req);
        if(resp.getStatusCode() == 200){
            IL10PdfWrapper jsonBody = (IL10PdfWrapper)JSON.deserialize(resp.getBody(), IL10PdfWrapper.class);
            if((jsonBody.errors == null || jsonBody.errors.size() == 0) && !String.isBlank(jsonBody.data)){
                String fileTitle = 'Invoice_' + theInvoice.Name + '.pdf';
                blob blobContent = EncodingUtil.base64Decode(jsonBody.data);
                List<ContentDocument> existingDoc = [SELECT Id, Title FROM ContentDocument WHERE Title = :fileTitle];
                if(existingDoc.size() > 0){
                    delete existingDoc;
                }
                ContentVersion cv = new ContentVersion(
                        Title          = fileTitle,
                        VersionData    = blobContent,
                        ContentLocation = 'S',
                        PathOnClient = fileTitle);
                insert cv;
                List<ContentVersion> documents = [SELECT Id, ContentDocumentId  FROM ContentVersion where id=:cv.id];
    
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.LinkedEntityId = theInvoice.Id;
                cdl.ContentDocumentId = documents[0].ContentDocumentId;
                cdl.ShareType = 'V';
                cdl.Visibility = 'AllUsers';
                insert cdl;
                // Site dpSite = [SELECT Id, name FROM Site WHERE Name = 'Dealer_Portal1'];
                // SiteDetail dpSiteDetail = [SELECT SecureURL FROM SiteDetail WHERE DurableId = :dpSite.Id];
                // url = dpSiteDetail.SecureURL + '/sfsites/c/sfc/servlet.shepherd/document/download/' + cdl.ContentDocumentId + '?operationContext=S1';
                url = cdl.ContentDocumentId;
            }else{
                url = 'errorMessage: ' + jsonBody.message + ', [' + String.join(jsonBody.errors, ',') + ']';
            }
        }else{
            url = 'errorMessage: ' + resp.getBody();
        }
        system.debug('osg url generated: ' + url);
        return url;
    }

    public class IL10PdfWrapper{
        public String data;
        public Boolean succeeded;
        public List<String> errors;
        public String message; 
    }

}