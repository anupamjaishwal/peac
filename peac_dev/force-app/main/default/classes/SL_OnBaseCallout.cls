public class SL_OnBaseCallout {
  private static Map<String, String> lFileExtToFileTypeMap = new Map<String, String> {
    'xml' => 'XML', 'xls' => 'MS Excel Spreadsheet', 'xlsx' => 'MS Excel Spreadsheet',
    'pdf' => 'PDF', 'doc' => 'MS Word Document', 'docx' => 'MS Word Document',
    'ppt' => 'MS Power Point', 'pptx' => 'MS Power Point',
    'jpg' => 'Image File Format', 'jpeg' => 'Image File Format',
    'gif' => 'Image File Format', 'png' => 'Image File Format',
    'htm' => 'HTML', 'html' => 'HTML',
    'msg' => 'MS Outlook Message'
  };
  static final Id workingCLoan = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get('Working_Capital_Loan').getRecordTypeId();
  private static String jsonResponse;

    public static String sendAttachmentsToOnBase(String recordId, Boolean aLogFlag, Boolean aUpdateRapportFlag) {
        Integer lTimeout = 120000;
        String lReturnStatus = 'Success';
        
        List<Contract_Attachment__c> lUpdateList = new List<Contract_Attachment__c>();
        Map<String, String> lDocIdToDocURLMap = new Map<String, String>();
        Map<String, String> lDocIdToDocResMap = new Map<String, String>();
        Map<String, String> ExceptionsMap = new Map<String, String>();
        List<Integration_Log__c> updateLogList = new List<Integration_Log__c>();

        Integer counter = 0;
        
        List<Contract_Attachment__c> onBaseAttList = [SELECT id,Contract__c,Type__c,Contract__r.Application_Number__c,Description__c,
                Sent_To_OnBase__c,Updated_Rapport__c,Document_URL__c,OnBase_Response__c,
                Contract__r.Name, Contract__r.CCAN__c, Contract__r.Customer__r.Name,
                Contract__r.Customer__r.DBA__c, Contract__r.Customer__r.Tax_ID__c,
                Contract__r.Dealer_Name__r.Dealer_Number__c,
                Contract__r.Booking_Date__c, Contract__r.Gross_Equipment_Cost__c,
                Contract__r.RecordTypeId,
                Type_Group__c, Status__c,
                (SELECT Name, BodyLength, CreatedDate FROM Attachments)
            FROM Contract_Attachment__c
            WHERE Contract__c = :recordId
            ORDER BY CreatedDate
        ];

        for(Contract_Attachment__c childAttachment : onBaseAttList) {
            try {
                counter++;
                String lResponseMessage = '';
                String lDocURL = '';
                String lDocType = '';
                String lFileExtension = 'pdf';
                String lFileType = 'pdf';
                String lFileName = '';
                if(!childAttachment.Sent_To_OnBase__c) {
                    lFileName = childAttachment.Attachments[0].Name;
                    
                    String validationData = '';
                    if(test.isRunningTest()){
                        Test.setMock(HttpCalloutMock.class, new KeywordsMock());
                    }else{
                        validationData = TC_OnBaseRequest.getHeader();
                    }
                    HttpRequest requestKeywords = new HttpRequest();
                    OnBase_Credentials__c creds = OnBase_Credentials__c.getOrgDefaults();
                    // old Onbase Version below
                    // requestKeywords.setEndpoint(creds.Gateway_Url__c + creds.Keywords_For_DocTypes__c + '?docType=' + 
                    //     EncodingUtil.urlEncode(childAttachment.Type__c, 'UTF-8').replaceAll('\\+', '%20'));
                    //new OnBase version below
                    requestKeywords.setEndpoint(creds.Gateway_Url__c + creds.Keywords_For_DocTypes__c + '?docType=' + 
                        EncodingUtil.urlEncode('["' + childAttachment.Type__c + '"]', 'UTF-8').replaceAll('\\+', '%20'));
                    requestKeywords.setMethod('GET');
                    requestKeywords.setHeader('ValidationData', validationData);
                    Integration_Log__c keywordCheckResult = SL_OnBaseCallout.sendRequest(requestKeywords, recordId, lTimeout, childAttachment.Type__c,
                        'For File: '+ lFileName +' The Document Type: ' + childAttachment.Type__c + ' was not accepted by OnBase, please change the Document Type and try again.',
                        new SL_OnBaseWrapper());
                    requestKeywords = null;
                    String availableKeywords = keywordCheckResult.Response_Message__c;

                    if(availableKeywords == '"[]"' || availableKeywords.contains('Status Code: ')){
                        System.debug('Keywords_For_DocTypes__c OnBase said: ' + availableKeywords);
                        updateLogList.add(keywordCheckResult);
                    }else{
                        Attachment att = [SELECT id, Body
                            FROM Attachment WHERE parentid = :childAttachment.Id];
                        Integer dotIndex = lFileName.lastIndexOf('.');
                        if(dotIndex != -1)
                            lFileExtension = lFileName.Substring(dotIndex + 1, lFileName.length());
    
                        lFileType = lFileExtension == '' ? 'pdf' : lFileExtToFileTypeMap.Get(lFileExtension.toLowerCase());
                        if(String.IsBlank(lFileType))
                            lFileType = 'pdf';
    
                        lDocType = childAttachment.Type__c;
                        String tempBody = EncodingUtil.base64Encode(att.Body);
                        att = null;
                        System.debug('tempBody.length(): ' + tempBody.length());
                        Id workingCLoan = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get('Working_Capital_Loan').getRecordTypeId();
                        SL_OnBaseWrapper wrapper = new SL_OnBaseWrapper();
                        wrapper.Name = lFileName;
                        wrapper.DocumentGroup = childAttachment.Type_Group__c;
                        wrapper.DocType = childAttachment.Type__c;
                        wrapper.FileExtension = lFileExtension;
                        wrapper.FileType = lFileType;
                        wrapper.CreateDate = String.valueOf(childAttachment.Attachments[0].CreatedDate);
                        wrapper.bytes = '~replaceMeWithActualFileBody~';
                        
                        String formattedContract = childAttachment.Contract__r.Name.replaceAll('-', '').left(13);
                        
                        availableKeywords = availableKeywords.replaceAll('\\\\\"', '"');
                        if(String.isNotBlank(childAttachment.Contract__r.Customer__r.DBA__c)
                            && availableKeywords.contains('"Name":"DBA Name"')){
                            wrapper.Keywords.add(new SL_OnBaseKeyword('DBA Name', childAttachment.Contract__r.Customer__r.DBA__c.left(150), null));
                        }
                        if(childAttachment.Contract__r.Booking_Date__c != null
                            && availableKeywords.contains('"Name":"Booking Date"')){
                            wrapper.Keywords.add(new SL_OnBaseKeyword('Booking Date', String.valueOf(childAttachment.Contract__r.Booking_Date__c).left(27), null));
                        }
                        if(String.isNotBlank(childAttachment.Status__c)
                        && availableKeywords.contains('"Name":"Status"')){
                            wrapper.Keywords.add(new SL_OnBaseKeyword('Status', childAttachment.Status__c.left(30), null));
                        }
                        if(String.isNotBlank(childAttachment.Contract__r.Customer__r.Tax_ID__c)
                        && availableKeywords.contains('"Name":"Fed ID #"')){
                            wrapper.Keywords.add(new SL_OnBaseKeyword('Fed ID #', childAttachment.Contract__r.Customer__r.Tax_ID__c.left(40), null));
                        }
                        wrapper.Keywords.add(new SL_OnBaseKeyword('Submission Date', String.valueOf(Date.today()), null));
                        if(childAttachment.Type_Group__c == 'Funding Stream' && childAttachment.Contract__r.RecordTypeId == workingCLoan){
                            if(String.isNotBlank(childAttachment.Contract__r.Application_Number__c)
                                && availableKeywords.contains('"Name":"Loan Application #"')){
                                wrapper.Keywords.add(new SL_OnBaseKeyword('Loan Application #', childAttachment.Contract__r.Application_Number__c.left(16), null));
                            }
                            wrapper.Keywords.add(new SL_OnBaseKeyword('Account #', formattedContract.left(12), null));
                            String ccId = formattedContract.Substring(3, 9);
                            String applicationNumber = '';
                            if(String.isNotBlank(applicationNumber)
                                && availableKeywords.contains('"Name":"Application #"')){
                                wrapper.Keywords.add(new SL_OnBaseKeyword('Application #', applicationNumber.left(9), null));
                            }
                            wrapper.Keywords.add(new SL_OnBaseKeyword('Company Name', childAttachment.Contract__r.Customer__r.Name.left(150), null));
                            if(String.isNotBlank(ccId)
                                && availableKeywords.contains('"Name":"CC ID"')){
                                wrapper.Keywords.add(new SL_OnBaseKeyword('CC ID', ccId.left(9), null));
                            }
                        } else {
                            wrapper.Keywords.add(new SL_OnBaseKeyword('Name', childAttachment.Contract__r.Customer__r.Name.left(50), null));
                            wrapper.Keywords.add(new SL_OnBaseKeyword('Contract #', formattedContract, null));
                            if(String.isNotBlank(childAttachment.Contract__r.Application_Number__c)
                                && availableKeywords.contains('"Name":"Application #"')){
                                wrapper.Keywords.add(new SL_OnBaseKeyword('Application #', childAttachment.Contract__r.Application_Number__c.left(9), null));
                            }
                            if(String.isNotBlank(childAttachment.Contract__r.CCAN__c)
                                && availableKeywords.contains('"Name":"CCAN #"')){
                                wrapper.Keywords.add(new SL_OnBaseKeyword('CCAN #', childAttachment.Contract__r.CCAN__c.left(9), null));
                            }
                            if(childAttachment.Contract__r.Gross_Equipment_Cost__c != null
                            && availableKeywords.contains('"Name":"Lease Amount"')){
                                wrapper.Keywords.add(new SL_OnBaseKeyword('Lease Amount', String.valueOf(childAttachment.Contract__r.Gross_Equipment_Cost__c).left(22), null));
                            }
                            if(String.isNotBlank(childAttachment.Contract__r.Dealer_Name__r.Dealer_Number__c)
                            && availableKeywords.contains('"Name":"Dealer #"')){
                                wrapper.Keywords.add(new SL_OnBaseKeyword('Dealer #', childAttachment.Contract__r.Dealer_Name__r.Dealer_Number__c.left(10), null));
                            }
                        }
                        
                        HttpRequest lReq = new HttpRequest();
                        lReq.setEndpoint(TC_OnBaseRequest.getAddDocumentUrl());
                        lReq.setMethod('POST');
                        lReq.setHeader('ValidationData', validationData);
                        
                        String tempJson = JSON.serialize(wrapper);
                        String tempClosing = tempJson.substringAfter('~replaceMeWithActualFileBody~');
                        String tempBeforeBody = tempJson.substringBefore('~replaceMeWithActualFileBody~');
                        tempJson = '';
                        lReq.setBody(tempBeforeBody + tempBody + tempClosing);
                        tempJson = null;
                        tempBody = null;
                        tempBeforeBody = '';
                        tempClosing = '';
                        if(test.isRunningTest()){
                            Test.setMock(HttpCalloutMock.class, new OnBaseMock());
                        }
                        Integration_Log__c uploadFileResult = SL_OnBaseCallout.sendRequest(lReq, recordId, lTimeout, '', '', wrapper);
                        lReq = null;
                        lResponseMessage = uploadFileResult.Response_Message__c;
                        if(!lResponseMessage.contains('Status Code: ')){
                            lDocURL = getCreatedDocUrl(lResponseMessage);
                        }
                        updateLogList.add(uploadFileResult);
                    }
                }
                else {
                    lDocURL = childAttachment.Document_URL__c;
                    lResponseMessage = childAttachment.Document_URL__c;
                }

                lDocIdToDocURLMap.Put(childAttachment.Id, lDocURL);
                lDocIdToDocResMap.Put(childAttachment.Id, lResponseMessage);
            } catch(Exception e) {
                lReturnStatus = e.getMessage() + '=>>> ' + e.getStackTraceString();
                ExceptionsMap.Put(childAttachment.Id, lReturnStatus);

            }
            
        }// end of for loop     


        for(String lDoc : lDocIdToDocURLMap.keyset()) {
            String docUrl = lDocIdToDocURLMap.get(lDoc);
            String onBaseResponse = lDocIdToDocResMap.Get(lDoc);
            if(docUrl != null && onBaseResponse != null){
                Contract_Attachment__c lOA = new Contract_Attachment__c(
                    Id = lDoc,
                    Sent_To_OnBase__c = true,
                    Document_URL__c = docUrl,
                    OnBase_Response__c = onBaseResponse,
                    Updated_Rapport__c = false,
                    Attachment__c = null
                );
                lUpdateList.Add(lOA);
            }
        }
        List<Attachment> deleteAfterUpload = [SELECT Id FROM Attachment WHERE ParentId IN : lDocIdToDocURLMap.keyset()];
        
        System.Debug('Success:' + lUpdateList);
        update lUpdateList;
        delete deleteAfterUpload;        

        for(String lDoc : ExceptionsMap.keyset()) {
            Integration_Log__c lIntLog = new Integration_Log__c(
                Name = 'OnBase API',
                Record_Id__c = 'No Id',
                Status__c = 'Error',
                Error_Code__c = '500',
                Error_Message__c = ExceptionsMap.Get(lDoc)
            );
            updateLogList.Add(lIntLog);
        }
        insert updateLogList;
        if(lUpdateList.size() == 0){
            lReturnStatus = 'No Updates done';
        }
        return lReturnStatus;
    }

    @future(callout=true)
    public Static void calloutFromQToOnBase(String recordId, List<String> nextContractIds, List<String> idsToRetry, Boolean isFirstTime) {
        String uploadResult = sendAttachmentsToOnBase(recordId, false, true);
        String failedId = null;
        if(uploadResult == 'No Updates done'){
            idsToRetry.add(recordId);
        }
        if(nextContractIds.size() != 0){
            System.enqueueJob(new SL_UploadAttachmentQ(nextContractIds, idsToRetry, isFirstTime));
        }else{
            if(isFirstTime && idsToRetry.size() > 0){
                System.enqueueJob(new SL_UploadAttachmentQ(idsToRetry, new List<String>(), false));
            }
        }
    }

    @future(callout=true)
    public Static void sendRapportAttachmentToOnBase(String recordId, Boolean aUpdateRapportFlag) {

        try {
            aUpdateRapportFlag =(aUpdateRapportFlag == null) ? True : aUpdateRapportFlag;
            System.Debug('Contract For processing:' + recordId + ':' + aUpdateRapportFlag);
            sendAttachmentsToOnBase(recordId, False, aUpdateRapportFlag);

        } catch(Exception e) {
            System.Debug(e);
        }

    }

    @AuraEnabled
    public static string retrieveDocuments(Id recordId, Boolean isFS){
        try {
            HttpRequest requestFiles = new HttpRequest();
            String maxDocCount = '50';
            jsonResponse = '';
            String gatewayUrl = '';
            String validationData = '';
            String filter = '';
            if(!Test.isRunningTest()){
                validationData = TC_OnBaseRequest.getHeader();
            }
            OnBase_Credentials__c onBaseCredentials = OnBase_Credentials__c.getOrgDefaults();
            gatewayUrl = onBaseCredentials.Gateway_Url__c;
            List<SL_OnBaseKeyword> keywords = new List<SL_OnBaseKeyword>();
            string endPointURL = onBaseCredentials.Retrieve_Documents__c;
            if(recordId.getSObjectType() == Contract__c.SObjectType){
                Contract__c contract = [SELECT Name, Application_Number__c FROM Contract__c WHERE Id = :recordId];
                String keyWordName = '';
                String applicationNumber = contract.Application_Number__c != null? contract.Application_Number__c.remove('-').left(9): '';
                if(isFS){
                    keyWordName = 'Loan Application #';
                }else{
                    keyWordName = 'Application #';
                }
                keywords.add(new SL_OnBaseKeyword(keyWordName, applicationNumber, null));
                endPointURL = onBaseCredentials.Retrieve_Documents__c;
            }else if(recordId.getSObjectType() == Opportunity.SObjectType){
    
            }else if(recordId.getSObjectType() == Account.SObjectType){
                Account acc = [SELECT Name, CCAN__c FROM Account WHERE Id = :recordId];

                keywords.add(new SL_OnBaseKeyword('CCAN #', acc.CCAN__c, null));
                //endPointURL = onBaseCredentials.Retrieve_Documents_From_Account__c + '?filter={"DocTypes":["CS - Misc"],"Keywords":[{"Name":"CCAN%20%23","CurrentValue":"4114568"}]}';
            } 
            // maxdocumentcount seems to not be required
            // filter = '{"MaxDocumentCount":' + maxDocCount + ',"Keywords":' + JSON.serialize(keywords, true) + '}';
            filter = '{"Keywords":' + JSON.serialize(keywords, true) + '}';
            // old OnBase version Below
            // requestFiles.setEndpoint(gatewayUrl + onBaseCredentials.Retrieve_Documents__c + '?filter=' + 
            //     EncodingUtil.urlEncode(filter, 'UTF-8').replaceAll('\\+', '%20'));
            // requestFiles.setMethod('GET');
            //new OnBase Version below
            requestFiles.setEndpoint(gatewayUrl + endPointURL);
            requestFiles.setMethod('POST');
            requestFiles.setBody(filter);
            requestFiles.setHeader('ValidationData', validationData);
            SL_OnBaseWrapper requestLogger = new SL_OnBaseWrapper();
            requestLogger.Name = requestFiles.getEndpoint();
            requestLogger.DocumentGroup = filter;
            Integration_Log__c filesResult = SL_OnBaseCallout.sendRequest(requestFiles, recordId, 120000, '',
                '', requestLogger, true);
            if(filesResult.Error_Code__c!='200'){
                System.debug('filter: ' + filter);
                String theMessage = '';
                if(filesResult.Response_Message__c == 'An error has occurred.'
                    || filesResult.Response_Message__c == 'Status Code: 500, Status Message: Internal Server Error'){
                    jsonResponse = '{"Documents":[]}';
                }else{
                    theMessage = filesResult.Response_Message__c;
                    jsonResponse = '{"Error":{"Message": "' + theMessage + '"}}';
                }
                insert filesResult;
            }else{
                System.debug('jsonResponse before replaceAll: ' + jsonResponse);
                insert filesResult;
                // jsonResponse = jsonResponse.replaceAll('\\\\\"', '"').removeStart('"').removeEnd('"');
                if(jsonResponse.contains('\\\"')){
                    jsonResponse = jsonResponse.removeStart('"').removeEnd('"');
                }
                System.debug('jsonResponse: ' + jsonResponse);
                
            }
            return jsonResponse;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static String buildOnBaseUrl(SObject parentObject, String docType){
        return buildOnBaseUrl(parentObject, docType, null);
    }

    public static String buildOnBaseUrl(SObject parentObject, String docType, String uniqueIdentifier){
        String url = '';
        Boolean isFS = false;
        Id recordId = null;
        if(parentObject.getSObjectType() == Contract__c.SObjectType){
            Contract__c theContract = (Contract__c)parentObject;
            isFS = theContract.RecordTypeId == workingCLoan;
            recordId = theContract.Id;
        }else if(parentObject.getSObjectType() == Opportunity.SObjectType){

        }else if(parentObject.getSObjectType() == Account.SObjectType){

        } 
        if(recordId != null){
            String jsonAllDocs = retrieveDocuments(recordId, isFS);
            jsonAllDocs = jsonAllDocs.replace('\\"', '"').removeStart('"').removeEnd('"');
            SL_RetrieveDocsWrapper allDocs = (SL_RetrieveDocsWrapper)JSON.deserialize(jsonAllDocs, 
                SL_RetrieveDocsWrapper.class);
            for(SL_RetrievedDoc doc: allDocs.Documents){
                String extractedIdentifier = doc.Name.substringAfter(docType + ' - ').substringBefore(' ');
                if(doc.DocType == docType
                && (uniqueIdentifier == null || uniqueIdentifier == extractedIdentifier)){
                    url = doc.DocPopUrl;
                    break;
                }
            }
        }
        if(String.isBlank(url)){
            url = 'errorMessage: No Document found for the specified ID and Document Type.';
        }
        return url;
    }

    private static Integration_Log__c sendRequest(HttpRequest theRequest, String recordId, Integer timeout, String onBaseDocType, String errorMess,
        SL_OnBaseWrapper disenbodiedWrapper){
        return sendRequest(theRequest, recordId, timeout, onBaseDocType, errorMess, disenbodiedWrapper, false);
    }

    private static Integration_Log__c sendRequest(HttpRequest theRequest, String recordId, Integer timeout, String onBaseDocType, String errorMess,
        SL_OnBaseWrapper disenbodiedWrapper, Boolean returnFullResponse){
        Http h = new Http();
        theRequest.setHeader('Content-Type', 'application/json');
        theRequest.setTimeout(timeout);
        HttpResponse lRes = h.send(theRequest);

        Integration_Log__c resultsLog = new Integration_Log__c();
        String bodyWithNoBytes = JSON.serialize(disenbodiedWrapper);
        disenbodiedWrapper = null;
        system.debug('theRequest endpoint: ' + theRequest.getEndpoint());
        system.debug('theRequest body: ' + theRequest.getBody());
        system.debug('response body: ' + lRes.getBody());
        system.debug('lRes: ' + lRes);
        if(lRes.getStatusCode() != 200) {
            resultsLog = SL_LogException('OnBase API', recordId, 'Error', bodyWithNoBytes, lRes.getBody(), String.valueOf(lRes.getStatusCode()), lRes.getStatus());
            resultsLog.Response_Message__c = 'Status Code: ' + lRes.getStatusCode() + ', Status Message: ' + lRes.getStatus();
        }
        else{
            String availableKeywords = lRes.getBody();
            if(theRequest.getMethod() == 'GET' && availableKeywords == '"[]"'){
                resultsLog = SL_LogException('OnBase API', recordId, 'Error', 'GET docType=' + onBaseDocType, availableKeywords, '200', errorMess);
            }else {
                String responseBody = lRes.getBody().left(12000000);
                resultsLog = SL_LogException('OnBase API', recordId, 'Success', bodyWithNoBytes, responseBody, '200', 'OK');
                responseBody = null;
                if(returnFullResponse){
                    jsonResponse = lRes.getBody();
                }
            }
            
        }
        return resultsLog;
    }

    public static Integration_Log__c SL_LogException(String aIntName,String aRecordId, String aStatus,String aReqMessage,String aResMessage,String aErrCode,String aErrMessage){
        Integration_Log__c lIntLog = new Integration_Log__c(
            Name = aIntName,
            Record_Id__c = aRecordId,
            Status__c = aStatus,
            Request_Message__c = aReqMessage.left(32768),
            Response_Message__c = aResMessage.left(131072),
            Error_Code__c = aErrCode,
            Error_Message__c = aErrMessage
        );
        return lIntLog;
    }

    public class SL_OnBaseWrapper {
        public String Name;
        public String DocumentGroup;
        public String DocType;
        public String FileExtension;
        public String FileType;
        public String CreateDate;
        public String bytes;
        public List <SL_OnBaseKeyword> Keywords;
    
        public SL_OnBaseWrapper () {
            Keywords = new List <SL_OnBaseKeyword> ();
    
        }
    }
    public class SL_OnBaseKeyword {
        public String Name;
        public String CurrentValue;
        public String UpdatedValue;

        public SL_OnBaseKeyword (String Name, String CurrentValue, String UpdatedValue) {
            this.Name = Name;
            this.CurrentValue = CurrentValue;
            this.UpdatedValue = UpdatedValue;
        }

    }

    public class SL_RetrieveDocsWrapper{
        public List<SL_RetrievedDoc> Documents;

        public SL_RetrieveDocsWrapper(){
            this.Documents = new List<SL_RetrievedDoc>();
        }
    }
    public class SL_RetrievedDoc{
        public String Name;
        public String DocType;
        public String DocPopUrl;
        public List <SL_OnBaseKeyword> Keywords;
    }

    public class KeywordsMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {

            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(SL_SCTestData.ONBASE_FAKE_RESPONSE_JSON_KEYWORDS);
            res.setStatusCode(200);
            return res;
        }
    }

    public class OnBaseMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {

            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(SL_SCTestData.ONBASE_FAKE_RESPONSE_JSON);
            res.setStatusCode(200);
            return res;
        }
    }


    @future(callout=true)
    public static void sendAttachmentsToOnBase(String recordId) {
      Integer lTimeout = 120000;
      String lReturnStatus = 'Success';
      system.debug('sendAttachmentsToOnBase(String recordId');
      List<OnBase_Attachment__c> lUpdateList = new List<OnBase_Attachment__c>();
      Map<String, String> lDocIdToDocURLMap = new Map<String, String>();
      Map<String, String> lDocIdToDocResMap = new Map<String, String>();
      Map<String, String> exceptionsMap = new Map<String, String>();
      List<Integration_Log__c> updateLogList = new List<Integration_Log__c>();
    
      Integer counter = 0;
  
      List<OnBase_Attachment__c> onBaseAttList = [SELECT Id, Type__c, Description__c, Sent_To_OnBase__c, 
        Document_URL__c, OnBase_Response__c, Status__c, Account__c, Account__r.Name, 
        Account__r.CCAN__c, Account__r.Tax_ID__c, Account__r.DBA__c, Account__r.Dealer_Number__c,
        (SELECT Name, BodyLength, CreatedDate FROM Attachments)
        FROM OnBase_Attachment__c WHERE Account__c = :recordId AND Sent_To_OnBase__c = false ORDER BY CreatedDate];
  
        for(OnBase_Attachment__c childAttachment : onBaseAttList) {
          try {
              counter++;
              String lResponseMessage = '';
              String lDocURL = null;
              String lDocType = '';
              String lFileExtension = 'pdf';
              String lFileType = 'pdf';
              String lFileName = '';
      
              if(!childAttachment.Sent_To_OnBase__c) {
                lFileName = childAttachment.Attachments[0].Name;
                
                String validationData = '';
                if(test.isRunningTest()){
                    Test.setMock(HttpCalloutMock.class, new KeywordsMock());
                }else{
                    validationData = TC_OnBaseRequest.getHeader();
                }
                HttpRequest requestKeywords = new HttpRequest();
                OnBase_Credentials__c creds = OnBase_Credentials__c.getOrgDefaults();
                // old Onbase Version below
                // requestKeywords.setEndpoint(creds.Gateway_Url__c + creds.Keywords_For_DocTypes__c + '?docType=' + 
                //       EncodingUtil.urlEncode(childAttachment.Type__c, 'UTF-8').replaceAll('\\+', '%20'));
                    // new onbase version below
                requestKeywords.setEndpoint(creds.Gateway_Url__c + creds.Keywords_For_DocTypes__c + '?docType=' + 
                        EncodingUtil.urlEncode('["' + childAttachment.Type__c + '"]', 'UTF-8').replaceAll('\\+', '%20'));
                requestKeywords.setMethod('GET');
                requestKeywords.setHeader('ValidationData', validationData);
                Integration_Log__c keywordCheckResult = sendRequest(requestKeywords, recordId, lTimeout, childAttachment.Type__c,
                    'For File: '+ lFileName +' The Document Type: ' + childAttachment.Type__c + ' was not accepted by OnBase, please change the Document Type and try again.',
                    new SL_OnBaseCallout.SL_OnBaseWrapper());
                requestKeywords = null;
                String availableKeywords = keywordCheckResult.Response_Message__c;
                if(availableKeywords == '"[]"' || availableKeywords.contains('Status Code: ')){
                    System.debug('Keywords_For_DocTypes__c OnBase said: ' + availableKeywords);
                    updateLogList.add(keywordCheckResult);
                }else{
                      Attachment att = [SELECT id, Body
                          FROM Attachment WHERE parentid = :childAttachment.Id];
                      Integer dotIndex = lFileName.lastIndexOf('.');
                      if(dotIndex != -1)
                          lFileExtension = lFileName.Substring(dotIndex + 1, lFileName.length());
  
                      lFileType = lFileExtension == '' ? 'pdf' : lFileExtToFileTypeMap.Get(lFileExtension.toLowerCase());
                      if(String.IsBlank(lFileType))
                          lFileType = 'pdf';
  
                      lDocType = childAttachment.Type__c;
                      String tempBody = EncodingUtil.base64Encode(att.Body);
                      att = null;
                      System.debug('tempBody.length(): ' + tempBody.length());
                      SL_OnBaseWrapper wrapper = new SL_OnBaseWrapper();
                      wrapper.Name = lFileName;
                      //wrapper.DocumentGroup = 'Titled Vehicles';//childAttachment.Type_Group__c;
                      wrapper.DocType = childAttachment.Type__c;
                      wrapper.FileExtension = lFileExtension;
                      wrapper.FileType = lFileType;
                      wrapper.CreateDate = String.valueOf(childAttachment.Attachments[0].CreatedDate);
                      wrapper.bytes = '~replaceMeWithActualFileBody~';
                      
                      availableKeywords = availableKeywords.replaceAll('\\\\\"', '"');
                      if(String.isNotBlank(childAttachment.Account__r.DBA__c)
                          && availableKeywords.contains('"Name":"DBA Name"')){
                          wrapper.Keywords.add(new SL_OnBaseKeyword('DBA Name', childAttachment.Account__r.DBA__c.left(150), null));
                      }

                      if(String.isNotBlank(childAttachment.Status__c)
                      && availableKeywords.contains('"Name":"Status"')){
                          wrapper.Keywords.add(new SL_OnBaseKeyword('Status', childAttachment.Status__c.left(30), null));
                      }
                      if(String.isNotBlank(childAttachment.Account__r.Tax_ID__c)
                      && availableKeywords.contains('"Name":"Fed ID #"')){
                          wrapper.Keywords.add(new SL_OnBaseKeyword('Fed ID #', childAttachment.Account__r.Tax_ID__c.left(40), null));
                      }
                      //wrapper.Keywords.add(new SL_OnBaseKeyword('Submission Date', String.valueOf(Date.today()), null));
                      //wrapper.Keywords.add(new SL_OnBaseKeyword('Company Name', childAttachment.Account__r.Name.left(150), null));
                      //wrapper.Keywords.add(new SL_OnBaseKeyword('Name', childAttachment.Account__r.Name.left(50), null));
                      
                      if(String.isNotBlank(childAttachment.Account__r.CCAN__c)
                          && availableKeywords.contains('"Name":"CCAN #"')){
                        wrapper.Keywords.add(new SL_OnBaseKeyword('CCAN #', childAttachment.Account__r.CCAN__c.left(9), null));
                      }
  
                      if(String.isNotBlank(childAttachment.Account__r.Dealer_Number__c)
                          && availableKeywords.contains('"Name":"Dealer #"')){
                        wrapper.Keywords.add(new SL_OnBaseKeyword('Dealer #', childAttachment.Account__r.Dealer_Number__c.left(10), null));
                      }
                      
                      HttpRequest lReq = new HttpRequest();
                      lReq.setEndpoint(TC_OnBaseRequest.getAddDocumentUrl());
                      lReq.setMethod('POST');
                      lReq.setHeader('ValidationData', validationData);
                      
                      String tempJson = JSON.serialize(wrapper);
                      String tempClosing = tempJson.substringAfter('~replaceMeWithActualFileBody~');
                      String tempBeforeBody = tempJson.substringBefore('~replaceMeWithActualFileBody~');
                      tempJson = '';
                      lReq.setBody(tempBeforeBody + tempBody + tempClosing);
                      tempJson = null;
                      tempBody = null;
                      tempBeforeBody = '';
                      tempClosing = '';
                      if(test.isRunningTest()){
                          Test.setMock(HttpCalloutMock.class, new OnBaseMock());
                      }
                      Integration_Log__c uploadFileResult = SL_OnBaseCallout.sendRequest(lReq, recordId, lTimeout, '', '', wrapper);
                      lReq = null;
                      lResponseMessage = uploadFileResult.Response_Message__c;
                      if(!lResponseMessage.contains('Status Code: ')){
                        lDocURL = getCreatedDocUrl(lResponseMessage);
                      }
                      updateLogList.add(uploadFileResult);
                  }
              }
              else {
                lDocURL = childAttachment.Document_URL__c;
                lResponseMessage = childAttachment.Document_URL__c;
              }
  
              lDocIdToDocURLMap.Put(childAttachment.Id, lDocURL);
              lDocIdToDocResMap.Put(childAttachment.Id, lResponseMessage);
          } catch(Exception e) {
            lReturnStatus = e.getMessage() + '=>>> ' + e.getStackTraceString();
            ExceptionsMap.Put(childAttachment.Id, lReturnStatus);
          }
      }// end of for loop 
  
      for(String lDoc : lDocIdToDocURLMap.keyset()) {
        String docUrl = lDocIdToDocURLMap.get(lDoc);
        String onBaseResponse = lDocIdToDocResMap.Get(lDoc);

        if(docUrl != null && onBaseResponse != null){
          OnBase_Attachment__c lOA = new OnBase_Attachment__c(
              Id = lDoc,
              Sent_To_OnBase__c = true,
              Document_URL__c = docUrl,
              OnBase_Response__c = onBaseResponse,
              Attachment__c = null
          );
          lUpdateList.Add(lOA);
        }
      }
      List<Attachment> deleteAfterUpload = [SELECT Id FROM Attachment WHERE ParentId IN : lUpdateList];
      update lUpdateList;
      delete deleteAfterUpload;        
  
      for(String lDoc : ExceptionsMap.keyset()) {
          Integration_Log__c lIntLog = new Integration_Log__c(
              Name = 'OnBase API',
              Record_Id__c = 'No Id',
              Status__c = 'Error',
              Error_Code__c = '500',
              Error_Message__c = ExceptionsMap.Get(lDoc)
          );
          updateLogList.Add(lIntLog);
      }
      insert updateLogList;
   
    }

    public static void sendOnbaseAttachemntToHCL(String opportunityId, List<String> attachmentIds){

      List<String> attachmentJSON = new List<String>();
      String attachmentsString = '';
      
      for(String attchId : attachmentIds){
        String attachmentJSONItem = '';
        attachmentJSONItem += '{\"attachmentid\": \"'+ attchId + '\"}';
        attachmentJSON.add(attachmentJSONItem);
      }
      attachmentsString = String.join(attachmentJSON, ',');

      Opportunity opp = [SELECT Id, Application__c, Account.Name, Account.Tax_ID__c, CCAN__c, Loan_Record_Type__c, CaseCenter__c, PK__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
      
      String appNumber ='';
      String body = '';
      String pkNumber = '';
      if(opp.Loan_Record_Type__c){
        appNumber = opp.CaseCenter__c;
        pkNumber = opp.PK__c==null ? '' : opp.PK__c;
        body = '{\"Application Number\": \"'+appNumber+'\",\n'+
                '\"OpportunityId\": \"'+opp.Id+'\",\n' +      
                '\"Legal Business Name\": \"'+opp.Account.Name+'\",\n'+
                '\"Business Tax ID\": \"'+opp.Account.Tax_ID__c+'\",\n'+
                '\"PK Number\": \"'+pkNumber+'\",\n' +
                '\"AttachmentIds\": ['+attachmentsString+']}';
      }
      else{
        appNumber= opp.Application__c;
        body = '{\"Application Number\": \"'+appNumber+'\",\n'+
      '\"OpportunityId\": \"'+opp.Id+'\",\n' +      
      '\"Legal Business Name\": \"'+opp.Account.Name+'\",\n'+
      '\"Business Tax ID\": \"'+opp.Account.Tax_ID__c+'\",\n'+
      '\"PK Number\": \"'+opp.PK__c+'\",\n' +
      '\"AttachmentIds\": ['+attachmentsString+']}';
      }      

      System.debug('REQUEST');      
      System.debug(body);

      Opportunity_Attachment_HCL__c mc = Opportunity_Attachment_HCL__c.getOrgDefaults();
      HttpRequest req = new HttpRequest();
      req.setEndpoint('callout:DP_MCS'+'/sfdocuments/v1/createUploadDocSFOnbaseAPI/');
      if(!Test.isRunningTest())req.setHeader('x-api-key', mc.x_api_key__c);
      //req.setHeader('Content-Type', 'application/json');
      req.setMethod('POST');
      req.setBody(body);
      System.debug(req.getEndpoint() + 'Endpoint');
        System.debug(mc.x_api_key__c + 'Header');
      Http http = new Http();
      if(!Test.isRunningTest()){
        HTTPResponse res = http.send(req);
        System.debug('RESPONSE ' + res);
      }
    }

    public static void sendOnbaseAttachemntToHCL(String opportunityId){

        List<String> attachmentIds = new List<String>(); 
        for(Opportunity_Attachment__c attch : [SELECT ID  FROM Opportunity_Attachment__c WHERE Opportunity__c = :opportunityId AND Sent_To_OnBase__c = False])
        {
             attachmentIds.add(attch.ID);
        }
        sendOnbaseAttachemntToHCL(opportunityId, attachmentIds);
    }

    public static String getCreatedDocUrl(String responseJson){
        String docUrl = '';
        System.debug('getCreatedDocUrl');


        responseJson = responseJson.Replace('\\\\u0026', '&');
                System.debug('responseJson ' + responseJson);

        SL_RetrieveDocsWrapper createdDocs = (SL_RetrieveDocsWrapper)JSON.deserialize(responseJson, 
            SL_RetrieveDocsWrapper.class);
        if(createdDocs != null && createdDocs.Documents != null && createdDocs.Documents.size() > 0){
            docUrl = createdDocs.Documents[0].DocPopUrl;
        }

                System.debug('docUrl');

        return docUrl;
    }
 


}