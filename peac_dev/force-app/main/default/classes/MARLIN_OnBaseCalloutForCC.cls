public class MARLIN_OnBaseCalloutForCC {

/****************************************************************************************
* @Author       Huron Team
* @Date         March 21, 2018
* @Description  CC Call for OnBase
*****************************************************************************************/


    /**************************************************/
    //To call Onbase Service
    /**************************************************/
    //added list of string parameter so Opportunity Attachments can be specified SAL-3037
    public static String sendAttachmentsToOnBase (String aOptyId, Boolean aLogFlag, List<String> onbaseAttachmentIds) {

        //String Endpoint = System.Label.On_Base_Endpoint;
        Integer lTimeout = 60000;
        String lReturnStatus = '';
        String lExceptionFlag = 'N';
        String lResponseMessage = '';
        String lDocURL = '';
        String lDocType = '';
        String lRequestMsg = '';
        String lStatusMessage = '';
        String lErrorMsg = '';
        String lFileExtension = 'pdf';
        String lFileType = 'pdf';
        String lFileName = '';
        String lAppNumber = '';
        String lFileDesc = '';
        Boolean lUpdateCCFlag = false;

        List<Opportunity_Attachment__c> lUpdateList = new List<Opportunity_Attachment__c>();
        Map<String, String> lDocIdToDocURLMap = new Map<String, String>();
        Map<String, String> lDocIdToDocResMap = new Map<String, String>();
        Map<String, String> lDocIdToErrorMap = new Map<String, String>();
        Map<String, Boolean> lDocIdToUpdateCCMap = new Map<String, Boolean>();
        Map<String, String> lDocPropertyMap = new Map<String, String>();
        Map<String, Map<String, String>> lDocIdToDocDetailsMap = new Map<String, Map<String, String>>();

        // SAL-2787 added support for MSG files
        Map<String, String> lFileExtToFileTypeMap = new Map<String, String> {
            'xml' => 'XML', 'xls' => 'MS Excel Spreadsheet', 'xlsx' => 'MS Excel Spreadsheet',
            'pdf' => 'PDF', 'doc' => 'MS Word Document', 'docx' => 'MS Word Document',
            'ppt' => 'MS Power Point', 'pptx' => 'MS Power Point',
            'jpg' => 'Image File Format', 'jpeg' => 'Image File Format',
            'gif' => 'Image File Format', 'png' => 'Image File Format',
            'htm' => 'HTML', 'html' => 'HTML',
            'msg' => 'MS Outlook Message'
        };

		System.debug ('##### Marlin_OnBaseCalloutForCC');
        //added logic to check if list of Ids is being passed in for SAL-3037
        List <Opportunity_Attachment__c> lOpptyAttList;
        if(onbaseAttachmentIds == null){
            lOpptyAttList = [
            SELECT id
                ,Opportunity__c
                ,Type__c
                ,Opportunity__r.CaseCenter__c
                ,Description__c
                ,Sent_To_OnBase__c
                ,Updated_Rapport__c
                ,Document_URL__c
                ,OnBase_Response__c
                ,Opportunity__r.Account.CCID__c
                ,Opportunity__r.Account.Name

            FROM Opportunity_Attachment__c
            WHERE Opportunity__c = :aOptyId
            ORDER BY CreatedDate
            ];
        }
        else {
            lOpptyAttList = [
            SELECT id
                ,Opportunity__c
                ,Type__c
                ,Opportunity__r.CaseCenter__c
                ,Description__c
                ,Sent_To_OnBase__c
                ,Updated_Rapport__c
                ,Document_URL__c
                ,OnBase_Response__c
                ,Opportunity__r.Account.CCID__c
                ,Opportunity__r.Account.Name

            FROM Opportunity_Attachment__c
            WHERE Id IN :onbaseAttachmentIds
            ORDER BY CreatedDate
            ];
        }
        
        
        System.debug ('##### lOpptyAttList' + lOpptyAttList);


        List <Dealer__c> primaryDealers = new List <Dealer__c> ([
            SELECT Id
                ,Name
                ,Dealer__r.Dealer_Number__c
            FROM Dealer__c
            WHERE Opportunity__c = :aOptyId
            AND Primary_Dealer__c = true
            LIMIT 1]);
        

        for (Opportunity_Attachment__c optyAttachment : lOpptyAttList) {

            try {



                if (optyAttachment.Sent_To_OnBase__c == true && optyAttachment.Updated_Rapport__c == true)
                    continue;
				
                System.debug ('##### loop start:' + Limits.getHeapSize());
                /*
                Attachment att = [
                    SELECT Id
                        ,Name
                        ,ParentId
                        ,Parent.Name
                        ,Body
                        ,BodyLength
                        ,ContentType
                        ,CreatedDate
                        ,Description
                    FROM Attachment
                    WHERE ParentId = :optyAttachment.Id
                ];*/
                
                Attachment att = [
                    SELECT Id
                        ,Name
                        ,ParentId
                        ,Parent.Name
                        ,BodyLength
                        ,ContentType
                        ,CreatedDate
                        ,Description
                    FROM Attachment
                    WHERE ParentId = :optyAttachment.Id
                ];

                lFileName = String.valueOf(att.name);
                Integer dotIndex = lFileName.lastIndexOf('.');

                if (dotIndex != -1)
                    lFileExtension = lFileName.Substring(dotIndex + 1, lFileName.length());

                lFileType = lFileExtension == '' ? 'pdf' : lFileExtToFileTypeMap.Get(lFileExtension.toLowerCase());

                if (String.isBlank(lFileType))
                    lFileType = 'pdf';

                lAppNumber = optyAttachment.Opportunity__r.CaseCenter__c;
                lFileDesc = optyAttachment.Description__c;
                lDocType = optyAttachment.Type__c;
                //String docBody = EncodingUtil.base64Encode(att.body); tam commented out

                OnBaseWrapper wrapper = new OnBaseWrapper();

                wrapper.Name = att.Name;
                wrapper.DocType = optyAttachment.Type__c;
                wrapper.FileExtension = lFileExtension;
                wrapper.FileType = lFileType;
                wrapper.CreateDate = att.CreatedDate.format();
                // wrapper.bytes = docBody; tam commented out
                wrapper.bytes = EncodingUtil.base64Encode([select body from Attachment where parentid = :optyAttachment.Id][0].body);

                if (optyAttachment.Type__c != 'DL - Misc' && optyAttachment.Type__c != 'DL - Application') {
                    wrapper.Keywords.add (new OnBaseWrapper.OnBaseKeyword('Loan Application #', optyAttachment.Opportunity__r.CaseCenter__c, null));
                    wrapper.Keywords.add (new OnBaseWrapper.OnBaseKeyword('CC ID', optyAttachment.Opportunity__r.Account.CCID__c , null));
                    wrapper.Keywords.add (new OnBaseWrapper.OnBaseKeyword('Company Name', optyAttachment.Opportunity__r.Account.Name , null));

                }

                if (!primaryDealers.isEmpty() && (optyAttachment.Type__c == 'DL - Misc' || optyAttachment.Type__c == 'DL - Application')) {
                    wrapper.Keywords.add (new OnBaseWrapper.OnBaseKeyword('Dealer Name', primaryDealers[0].Name, null));

                    String dealerNumberString = primaryDealers[0].Dealer__r.Dealer_Number__c != null ? primaryDealers[0].Dealer__r.Dealer_Number__c.replaceAll('[^0-9]', '') : '';
                    wrapper.Keywords.add (new OnBaseWrapper.OnBaseKeyword('Dealer #', dealerNumberString, null));
                }


                //lRequestMsg = JSON.serialize(wrapper); tam commented out

//                lRequestMsg = '{' +
//                    '"Name": "' + att.Name + '",' +
//                    '"DocType": "' + optyAttachment.Type__c + '",' +
//                    '"FileExtension": "' + lFileExtension + '",' +
//                    '"FileType": "' + lFileType + '",' +
//                    '"CreateDate": "' + att.CreatedDate + '",' +
//                    '"bytes":"' + docBody + '",' +
//                    '"Keywords":[{"Name":"Loan Application #","CurrentValue":"' + optyAttachment.Opportunity__r.CaseCenter__c + '","UpdatedValue":null},{"Name":"CC ID","CurrentValue":"' + optyAttachment.Opportunity__r.Account.CCID__c + '","UpdatedValue":null},{"Name":"Company Name","CurrentValue":"' + optyAttachment.Opportunity__r.Account.Name + '","UpdatedValue":null}]' +
//                    '}';


                System.debug('Request Message OnBase: ' + lRequestMsg);

                lDocPropertyMap.put('ID', att.Id);
                lDocPropertyMap.put('NAME', att.Name);
                lDocPropertyMap.put('DocType', lDocType);
                lDocPropertyMap.put('Description', lFileDesc);
                lDocPropertyMap.put('APP_ID', optyAttachment.Opportunity__r.CaseCenter__c);


                if (!optyAttachment.Sent_To_OnBase__c) {
                    /* new */
                	String validationData = TC_OnBaseRequest.getHeader();
                    
                    HttpRequest lReq = new HttpRequest();

                    lReq.setHeader('ValidationData', validationData);
                    lReq.setHeader('Content-Type', 'application/json');
                    lReq.setEndpoint(TC_OnBaseRequest.getAddDocumentUrl());
                    lReq.setMethod('POST');
                    lReq.setBody(lRequestMsg);
                    lReq.setBody(JSON.serialize(wrapper));
                    lReq.setTimeout(lTimeout);
                    
                    System.debug ('$$$$$ req body: ' + lReq.getBody());

                    Http h = new Http();
                    HttpResponse lRes = h.send(lReq);
                    
                    System.debug ('$$$$$ resp body: ' + lRes.getBody());


                    //Process the response
                    if (lRes.getStatusCode() != 200) {
                        Marlin_IntegrationLog.LogException('CaseCenter OnBase API', aOptyId, 'Error', lRequestMsg, '', String.ValueOf(lRes.getStatusCode()), lRes.getStatus());
                        return 'Status Code: ' + lRes.getStatusCode() + ', Status Message: ' + lRes.getStatus();
                    }


                    lResponseMessage = lRes.getBody();
                    System.debug('Response is: ' + lResponseMessage);


                    if (lResponseMessage.contains('DocPopUrl')) {
                        lDocURL = SL_OnBaseCallout.getCreatedDocUrl(lResponseMessage);
                    }

                }   // end of sent to onbase check

                else {

                    lDocURL = optyAttachment.Document_URL__c;
                    lResponseMessage = optyAttachment.Document_URL__c;
                }
				
                
                /*lDocIdToDocURLMap.put(optyAttachment.Id, lDocURL);
                lDocIdToDocResMap.put(optyAttachment.Id, lResponseMessage);
                lDocPropertyMap.put('DOC_URL', lDocURL);
                //	lUpdateCCFlag = False;

                lDocIdToUpdateCCMap.put(optyAttachment.Id, lUpdateCCFlag);*/
                
                
                //if (optyAttachment.Type__c != null && !optyAttachment.Type__c.contains(Label.TC_MTDFileType)){
                    lDocIdToDocURLMap.put(optyAttachment.Id, lDocURL);
                	lDocIdToDocResMap.put(optyAttachment.Id, lResponseMessage);
                	lDocPropertyMap.put('DOC_URL', lDocURL);

                	lDocIdToUpdateCCMap.put(optyAttachment.Id, lUpdateCCFlag);    
                //}
            } catch (Exception e) {
                System.debug(e);

                lExceptionFlag = 'Y';
                lReturnStatus = e.getMessage() + '=>>> ' + e.getStackTraceString();
                lDocIdToErrorMap.put(optyAttachment.Id, lReturnStatus);

            }
			// if it's mtd, don't send it to case center
				//Type__c 
			            
            //lDocIdToDocDetailsMap.Put(optyAttachment.Id,lDocPropertyMap); comented out before mtd update
            
            if (optyAttachment.Type__c != null && !optyAttachment.Type__c.contains(Label.TC_MTDFileType)) lDocIdToDocDetailsMap.put(optyAttachment.Id, new Map<String, String>(lDocPropertyMap));
            //lDocIdToDocDetailsMap.put(optyAttachment.Id, new Map<String, String>(lDocPropertyMap));
            
            
            System.debug ('##### loop end:' + Limits.getHeapSize());

        }// end of for loop     

        // logic to send update to Case Center
        //if (!lDocIdToDocDetailsMap.isEmpty ()) Marlin_CaseCenterCallout.submitUpdatedAppToCaseCenter(aOptyId, lAppNumber, lDocIdToDocDetailsMap); // mtd update
        //String lUpdateMsg = Marlin_CaseCenterCallout.submitUpdatedAppToCaseCenter(aOptyId, lAppNumber, lDocIdToDocDetailsMap);
        //   	String lUpdateMsg = Marlin_CaseCenterHelper.updateCCWithOnBaseDocs(aOptyId, lAppNumber,lFileName,lDocType, lDocURL.replaceAll('&','&amp;'),counter); already commented out before mtd update


        for (String lDoc : lDocIdToDocURLMap.keyset()) {
            Opportunity_Attachment__c lOA = new Opportunity_Attachment__c(
                Id = lDoc,
                Sent_To_OnBase__c = true,
                Document_URL__c = lDocIdToDocURLMap.Get(lDoc),
                OnBase_Response__c = lDocIdToDocResMap.Get(lDoc),
                Updated_Rapport__c = true
            );

            lUpdateList.Add(lOA);

        }

        System.Debug('Success:' + lUpdateList);
		

        //update lUpdateList;

        //mtd update
        if (!lUpdateList.isEmpty ()) {
            update lUpdateList;

            Marlin_IntegrationLog.logException('CaseCenter OnBase API', aOptyId, 'Success', JSON.serialize(lUpdateList), '', '200', 'OK');
    
            List<Integration_Log__c> lUpdateLogList = new List<Integration_Log__c>();
    
            for (String lDoc : lDocIdToErrorMap.keyset()) {
    
                Integration_Log__c lIntLog = new Integration_Log__c(
                    Name = 'CaseCenter OnBase API',
                    Record_Id__c = 'lDoc',
                    Status__c = 'Error',
                    Error_Code__c = '500',
                    Error_Message__c = lDocIdToErrorMap.Get(lDoc)
                );
    
                lUpdateLogList.Add(lIntLog);
            }
    
            System.debug('Error:' + lUpdateLogList);
                insert lUpdateLogList;
        }

        lReturnStatus = 'Success' ;
        return lReturnStatus;
    }


    @future(callout=true)
    public Static void sendCCAttachmentToOnBase (String aOpptyId, Boolean aLogFlag) {

        try {
            sendAttachmentsToOnBase(aOpptyId, aLogFlag, null);

        } catch (Exception e) {
            System.Debug(e);
        }

    }

    //Added separate callout to also take in list of Ids for SAL-3037
    @future(callout=true)
    public Static void sendCCAttachmentToOnBase (String aOpptyId, Boolean aLogFlag, List<String> onbaseAttachmentIds) {

        try {
            sendAttachmentsToOnBase(aOpptyId, aLogFlag, onbaseAttachmentIds);

        } catch (Exception e) {
            System.Debug(e);
        }

    }


}