public class MARLIN_OnBaseCallout {

    /****************************************************************************************
* @Author       Huron Team
* @Date         March 21, 2017
* @Description  Rapport Call
*****************************************************************************************/



    /**************************************************/
    //To call Onbase Service
    /**************************************************/
    //added list of string parameter so Opportunity Attachments can be specified SAL-3037
    public static String sendAttachmentsToOnBase (String aOptyId, Boolean aLogFlag, Boolean aUpdateRapportFlag, List<String> onbaseIds) {

        //String Endpoint = 'http://testonbase2.marlinfinance.com/IntellafloOBGateway/api/document/AddDocument';
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
        Boolean lUpdateRapportFlag = False;

        List<Opportunity_Attachment__c> lUpdateList = new List<Opportunity_Attachment__c>();
        Map<String, String> lDocIdToDocURLMap = new Map<String, String>();
        Map<String, String> lDocIdToDocResMap = new Map<String, String>();
        Map<String, String> lDocIdToErrorMap = new Map<String, String>();
        Map<String, Boolean> lDocIdToUpdateRapportMap = new Map<String, Boolean>();

        //SAL-2787 added .MSG filetype
        Map<String, String> lFileExtToFileTypeMap = new Map<String, String> {
            'xml' => 'XML', 'xls' => 'MS Excel Spreadsheet', 'xlsx' => 'MS Excel Spreadsheet',
            'pdf' => 'PDF', 'doc' => 'MS Word Document', 'docx' => 'MS Word Document',
            'ppt' => 'MS Power Point', 'pptx' => 'MS Power Point',
            'jpg' => 'Image File Format', 'jpeg' => 'Image File Format',
            'gif' => 'Image File Format', 'png' => 'Image File Format',
            'htm' => 'HTML', 'html' => 'HTML',
            'msg' => 'MS Outlook Message'
        };

        Integer counter = 0;

        //added logic to check if list of Ids is being passed in for SAL-3037
        List<Opportunity_Attachment__c> lOpptyAttList;

        if(onbaseIds == null){
            lOpptyAttList = [
            select id,Opportunity__c,Type__c,Opportunity__r.Application__c,Description__c,
                Sent_To_OnBase__c,Updated_Rapport__c,Document_URL__c,OnBase_Response__c,
                Opportunity__r.CCAN__c, Opportunity__r.Account.Name
            from Opportunity_Attachment__c
            where Opportunity__c = :aOptyId
            ORDER BY CREATEDDATE
            ];
        }
        else {
            lOpptyAttList = [
            select id,Opportunity__c,Type__c,Opportunity__r.Application__c,Description__c,
                Sent_To_OnBase__c,Updated_Rapport__c,Document_URL__c,OnBase_Response__c,
                Opportunity__r.CCAN__c, Opportunity__r.Account.Name
            from Opportunity_Attachment__c
            where Id IN :onbaseIds
            ORDER BY CREATEDDATE
            ];
        }
        


        List <Dealer__c> primaryDealers = new List <Dealer__c> ([
            SELECT Id
            ,Name
            ,Dealer__r.Dealer_Number__c
            FROM Dealer__c
            WHERE Opportunity__c = :aOptyId AND Primary_Dealer__c = true LIMIT 1]);
        System.debug ('##### made it');
		
        for (Opportunity_Attachment__c optyAttachment : lOpptyAttList) {

            try {
                
                

                counter++;
                
                System.debug ('##### begining Limits.getHeapSize(): ' + counter + ' ' + Limits.getHeapSize() );

                if (optyAttachment.Sent_To_OnBase__c == True && optyAttachment.Updated_Rapport__c == True)
                    continue;

                if (optyAttachment.Sent_To_OnBase__c == True && counter > 3)
                    continue;

                /*Attachment att = [
                    select id,name,parentid,parent.name,
                        body,bodylength,contenttype,createddate,
                        description
                    from Attachment
                    where parentid = :optyAttachment.Id
                ];*/
                Attachment att = [
                    select id,name,parentid,parent.name
                        ,bodylength,contenttype,createddate,
                        description
                    from Attachment
                    where parentid = :optyAttachment.Id
                ];
                
                System.debug ('##### begining after query Limits.getHeapSize(): ' + counter + ' ' + Limits.getHeapSize() );

                lFileName = String.ValueOf(att.name);
                Integer dotIndex = lFileName.lastIndexOf('.');
                if (dotIndex != -1)
                    lFileExtension = lFileName.Substring(dotIndex + 1, lFileName.length());

                lFileType = lFileExtension == '' ? 'pdf' : lFileExtToFileTypeMap.Get(lFileExtension.toLowerCase());
                if (String.IsBlank(lFileType))
                    lFileType = 'pdf';

                /*  Opportunity_Attachment__c optyAttachment = [select id,Opportunity__c,Type__c,Opportunity__r.Application__c,Description__c,
                                                              Opportunity__r.CCAN__c, Opportunity__r.Account.Name
                                                              from Opportunity_Attachment__c
                                                              where id = :lParentId];
                                                              */
                lAppNumber = optyAttachment.Opportunity__r.Application__c;
                lFileDesc = optyAttachment.Description__c;
                lDocType = optyAttachment.Type__c;
                
                System.debug ('##### before decode Limits.getHeapSize(): ' + counter + ' ' + Limits.getHeapSize() );
                // String docBody = EncodingUtil.base64Encode(att.body); uncomment
                
                // newly added
                //String docBody = EncodingUtil.base64Encode([select body from Attachment where parentid = :optyAttachment.Id][0].body);
                System.debug ('##### after decode Limits.getHeapSize(): ' + counter + ' ' + Limits.getHeapSize() );

                OnBaseWrapper wrapper = new OnBaseWrapper();

                wrapper.Name = att.Name;
                wrapper.DocType = optyAttachment.Type__c;
                wrapper.FileExtension = lFileExtension;
                wrapper.FileType = lFileType;
                wrapper.CreateDate = String.valueOf(att.CreatedDate);
                //wrapper.bytes = docBody;
                // newlyadded
                wrapper.bytes = EncodingUtil.base64Encode([select body from Attachment where parentid = :optyAttachment.Id][0].body);

                if (optyAttachment.Type__c != 'DL - Misc' && optyAttachment.Type__c != 'DL - Application') {
                    wrapper.Keywords.add (new OnBaseWrapper.OnBaseKeyword('Application #', optyAttachment.Opportunity__r.Application__c, null));
                    wrapper.Keywords.add (new OnBaseWrapper.OnBaseKeyword('CCAN #', optyAttachment.Opportunity__r.CCAN__c, null));
                    wrapper.Keywords.add (new OnBaseWrapper.OnBaseKeyword('Name', optyAttachment.Opportunity__r.Account.Name, null));
                }


                if (!primaryDealers.isEmpty() && (optyAttachment.Type__c == 'DL - Misc' || optyAttachment.Type__c == 'DL - Application')) {
                    wrapper.Keywords.add (new OnBaseWrapper.OnBaseKeyword('Dealer Name', primaryDealers[0].Name, null));

                    String dealerNumberString = primaryDealers[0].Dealer__r.Dealer_Number__c != null ? primaryDealers[0].Dealer__r.Dealer_Number__c.replaceAll('[^0-9]', '') : '';
                    wrapper.Keywords.add (new OnBaseWrapper.OnBaseKeyword('Dealer #', dealerNumberString, null));
                }
				
                System.debug ('##### before serializing Limits.getHeapSize(): ' + counter + ' ' + Limits.getHeapSize() );
                lRequestMsg = JSON.serialize(wrapper); 
                System.debug ('##### after serializing Limits.getHeapSize(): ' + counter + ' ' + Limits.getHeapSize() );

//                lRequestMsg = '{' +
//                    '"Name": "' + att.Name + '",' +
//                    '"DocType": "' + optyAttachment.Type__c + '",' +
//                    '"FileExtension": "' + lFileExtension + '",' +
//                    '"FileType": "' + lFileType + '",' +
//                    '"CreateDate": "' + att.CreatedDate + '",' +
//                    '"bytes":"' + docBody + '",' +
//                    '"Keywords":[{"Name":"Application #","CurrentValue":"' + optyAttachment.Opportunity__r.Application__c
//                    + '","UpdatedValue":null},{"Name":"CCAN #","CurrentValue":"'
//                    + optyAttachment.Opportunity__r.CCAN__c + '","UpdatedValue":null},{"Name":"Name","CurrentValue":"'
//                    + optyAttachment.Opportunity__r.Account.Name + '","UpdatedValue":null}]' +
//                    '}';


                System.debug('Request Message OnBase: ' + lRequestMsg);

                if (optyAttachment.Sent_To_OnBase__c != True) {
                    
                    /* new */
                	String validationData = TC_OnBaseRequest.getHeader();
                    
                    HttpRequest lReq = new HttpRequest();
                    lReq.setEndpoint(TC_OnBaseRequest.getAddDocumentUrl());
                    lReq.setMethod('POST');
                    lReq.setHeader('ValidationData', validationData);
                    lReq.setHeader('Content-Type', 'application/json');
                    System.debug ('##### before set body Limits.getHeapSize(): ' + counter + ' ' + Limits.getHeapSize() );
                    // lReq.setBody(lRequestMsg); uncomment
                    lReq.setBody(JSON.serialize(wrapper));// new
                    //System.debug ('????? body:' + JSON.serialize(wrapper));
                    wrapper = null;
                    System.debug ('##### after set body Limits.getHeapSize(): ' + counter + ' ' + Limits.getHeapSize() );
                    lReq.setTimeout(lTimeout);

                    Http h = new Http();
                    HttpResponse lRes = h.send(lReq);


                    //Process the response
                    if (lRes.getStatusCode() != 200) {
                        MARLIN_IntegrationLog.LogException('OnBase API', aOptyId, 'Error', lRequestMsg, lRes.getBody(), String.valueOf(lRes.getStatusCode()), lRes.getStatus()); // SAL-816
                        return 'Status Code: ' + lRes.getStatusCode() + ', Status Message: ' + lRes.getStatus();
                    }


                    lResponseMessage = lRes.getBody();
                    system.debug('Response is: ' + lResponseMessage);


                    lDocURL = SL_OnBaseCallout.getCreatedDocUrl(lResponseMessage);

                }   // end of sent to onbase check
                else {

                    lDocURL = optyAttachment.Document_URL__c;
                    lResponseMessage = optyAttachment.Document_URL__c;
                }

                lDocIdToDocURLMap.Put(optyAttachment.Id, lDocURL);
                lDocIdToDocResMap.Put(optyAttachment.Id, lResponseMessage);
                lUpdateRapportFlag = False;

                // logic to send update to Rapport
                if (aUpdateRapportFlag == True && !String.IsBlank(lDocURL) && counter < 4) {

                    String lUpdateMsg = MARLIN_RapportHelper.createUpdateApplicationDocumentMsg(lAppNumber, lFileName, lDocType, lDocURL.replaceAll('&', '&amp;'), counter);
                    System.Debug('Update Message for Doc:' + lUpdateMsg);
                    MARLIN_RapportCallout.updateApplicationInRapport(optyAttachment.Opportunity__c, lUpdateMsg, False);
                    lUpdateRapportFlag = True;
                }

                lDocIdToUpdateRapportMap.Put(optyAttachment.Id, lUpdateRapportFlag);
            } catch (Exception e) {

                lExceptionFlag = 'Y';
                lReturnStatus = e.getMessage() + '=>>> ' + e.getStackTraceString();
                lDocIdToErrorMap.Put(optyAttachment.Id, lReturnStatus);

            }
            
            System.debug ('##### end Limits.getHeapSize(): ' + counter + ' ' + Limits.getHeapSize() );

        }// end of for loop     


        for (String lDoc : lDocIdToDocURLMap.keyset()) {
            Opportunity_Attachment__c lOA = new Opportunity_Attachment__c(
                Id = lDoc,
                Sent_To_OnBase__c = True,
                Document_URL__c = lDocIdToDocURLMap.Get(lDoc),
                OnBase_Response__c = lDocIdToDocResMap.Get(lDoc),
                Updated_Rapport__c = lDocIdToUpdateRapportMap.Get(lDoc)
            );
            lUpdateList.Add(lOA);

        }

        System.Debug('Success:' + lUpdateList);
        update lUpdateList;
        Marlin_IntegrationLog.LogException('OnBase API', aOptyId, 'Success', JSON.serialize(lUpdateList), '', '200', 'OK');

        List<Integration_Log__c> lUpdateLogList = new List<Integration_Log__c>();

        for (String lDoc : lDocIdToErrorMap.keyset()) {

            Integration_Log__c lIntLog = new Integration_Log__c(
                Name = 'OnBase API',
                Record_Id__c = 'lDoc',
                Status__c = 'Error',
                Error_Code__c = '500',
                Error_Message__c = lDocIdToErrorMap.Get(lDoc)
            );

            lUpdateLogList.Add(lIntLog);
        }

        System.Debug('Error:' + lUpdateLogList);
        insert lUpdateLogList;

        lReturnStatus = 'Success' ;
        return lReturnStatus;
    }


    @future(callout=true)
    public Static void sendRapportAttachmentToOnBase (String aOpptyId, Boolean aUpdateRapportFlag) {

        try {
            aUpdateRapportFlag = (aUpdateRapportFlag == null) ? True : aUpdateRapportFlag;
            System.Debug('Oppty For processing:' + aOpptyId + ':' + aUpdateRapportFlag);
            sendAttachmentsToOnBase(aOpptyId, False, aUpdateRapportFlag, null);

        } catch (Exception e) {
            System.Debug(e);
        }

    }

    //Added for SAL-3037 to be able to specify attachments being sent
    @future(callout=true)
    public Static void sendRapportAttachmentToOnBase (String aOpptyId, Boolean aUpdateRapportFlag, List<String> onbaseAttachmentIds) {

        try {
            aUpdateRapportFlag = (aUpdateRapportFlag == null) ? True : aUpdateRapportFlag;
            System.Debug('Oppty For processing:' + aOpptyId + ':' + aUpdateRapportFlag);
            sendAttachmentsToOnBase(aOpptyId, False, aUpdateRapportFlag, onbaseAttachmentIds);

        } catch (Exception e) {
            System.Debug(e);
        }

    }

    /*
    @future (callout=true)
        public Static void sendCaseCentertAttachmentToOnBase(String aOpptyId) {

           try {

                   System.Debug('Oppty For processing:');
                   sendAttachmentsToOnBase(aOpptyId,False,False);

           } catch (Exception e) {
               System.Debug(e);
           }

       }	 */

}