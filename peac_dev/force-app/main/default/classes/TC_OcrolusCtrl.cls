/**
 * Created by tamarack on 2019-07-19.
 */

public with sharing class TC_OcrolusCtrl  {
    

    public static void processOcrolusAttachmentList(Id oppId) {

        String errorMessage;
        
        // don't send mtds 4-13-2020
        // 
        String likeMTD = '%' + Label.TC_MTDFileType + '%';

        List<Opportunity_Attachment__c> originalAttachmentList = new List<Opportunity_Attachment__c>([SELECT Id,Type__c,
                Name, Sent_To_Ocrolus__c FROM Opportunity_Attachment__c WHERE Opportunity__c = :oppId AND Sent_To_Ocrolus__c = False AND (NOT Type__c LIKE :likeMTD)]);

        if (originalAttachmentList.isEmpty()) {
            errorMessage = 'No attachments to process';
            Marlin_IntegrationLog.LogException('Ocrolus File Upload', oppId, 'Error', '', '', '', errorMessage);
            return;
        }

        String pk;
        List<Opportunity> oppList = new List<Opportunity>([SELECT Pk__c FROM Opportunity WHERE Id =: oppId]);
        if (!oppList.isEmpty() && oppList[0].Pk__c != null) {
            pk = oppList[0].Pk__c;
        } else {
            pk = TC_OcrolusService.addBookCallout(oppId);
            if (String.isEmpty(pk)) {
                return;
            }
        }

        for (Opportunity_Attachment__c oppAttachment : originalAttachmentList) {
            if(oppAttachment.Type__c.contains(Label.TC_BankStatementFileType) && !oppAttachment.Type__c.contains(Label.TC_MTDFileType)) {
                //system.debug('>>>>>?????: Heap size is ' + limits.getHeapSize() + ' enforced is ' + limits.getLimitHeapSize());
                sendAttachmentToOcrolus(oppAttachment, pk);
            } else {
                errorMessage = '"' + oppAttachment.Name + '" is not a bank statement. Not uploaded to Ocrolus';
                Marlin_IntegrationLog.LogException('Ocrolus File Upload', oppAttachment.Id, 'Error', '', '', '', errorMessage);
            }

        }

    }

    public static void sendAttachmentToOcrolus(Opportunity_Attachment__c oppAttachment, String pk) {

        String errorMessage;

        Attachment attachment = new Attachment ();
        List<Attachment> attachList = new List<Attachment>([SELECT Id, Name FROM Attachment WHERE parentId =: oppAttachment.Id]);

        if (!attachList.isEmpty()) {
            attachment = attachList[0];
        } else {
            errorMessage = 'OnBase Attachment "' + oppAttachment.Name + '" has no file attachments. Nothing uploaded to Ocrolus';
            Marlin_IntegrationLog.LogException('Ocrolus File Upload', oppAttachment.Id, 'Error', '', '', '', errorMessage);
            return;
        }

        String attachmentName = attachment.Name.toLowerCase();

        /*if (attachment.Name.substringAfterLast('.') == 'png' || attachment.Name.substringAfterLast('.') == 'jpeg') {

            responseBean = TC_OcrolusService.uploadImageCallout(pk, attachment, oppAttachId);
            if (responseBean.status == '200') {
                responseBean = TC_OcrolusService.doneImageCallout(pk, oppAttachId);
            }

        } else*/ if (attachmentName.contains('.pdf')) {

            //TC_OcrolusService.OcrolusQueueable queueable = new TC_OcrolusService.OcrolusQueueable(pk, attachment.Id, oppAttachment.Id, 'upload');
            //System.enqueueJob(queueable);
            // platform event 10-9-2019
            EventBus.publish (new TC_Ocrolus_Upload_File__e  (PK__c = pk, Att_Id__c = attachment.Id, Opp_Att_Id__c = oppAttachment.Id, Callout_Type__c = 'upload'));

        } else {
            errorMessage = '"' + attachment.Name + '" is of unsupported or unknown file type, upload must be PDF. Not uploaded to Ocrolus';
            Marlin_IntegrationLog.LogException('Ocrolus File Upload', oppAttachment.Id, 'Error', '', '', '', errorMessage);
        }

    }

}