public class PEAC_OcrolusDelayQueueable  implements Queueable, Database.AllowsCallouts {
    
    String oppdId;
    
    public PEAC_OcrolusDelayQueueable (String oppdId) {        
        this.oppdId = oppdId;
    }
    
    public void execute(QueueableContext context) {
        sendAttachmentsToOnbaseAndOcrolus(oppdId);
        
    }
    
    public static void sendAttachmentsToOnbaseAndOcrolus(Id oppId) {
        
        if (oppId == null) return;
        
        //Get Opportunity PK
        Opportunity opp = [
            SELECT Id, PK__c
            FROM Opportunity
            WHERE Id = :oppId
            LIMIT 1
        ];
        
        if (String.isBlank(opp.PK__c)) {
            Marlin_IntegrationLog.LogException(
                'Ocrolus File Upload',
                oppId,
                'Error',
                '',
                '',
                '',
                'PK__c is blank on Opportunity'
            );
            return;
        }
        
        // Get Opportunity Attachments
        List<Opportunity_Attachment__c> oppAttachments = [
            SELECT Id, Name, Type__c
            FROM Opportunity_Attachment__c
            WHERE Opportunity__c = :oppId AND Sent_To_Ocrolus__c = false
        ];
        
        if (oppAttachments.isEmpty()) return;
        
        Set<Id> oppAttIds = new Set<Id>();
        for (Opportunity_Attachment__c oa : oppAttachments) {
            oppAttIds.add(oa.Id);
        }
        
        List<Id> smallFileOppAttIds = new List<Id>();
        List<Id> bigFileOppAttIds = new List<Id>();
        
        Map<Id, Attachment> attachmentMap = new Map<Id, Attachment>();
        
        // Handle Classic Attachments
        for (Attachment att : [
            SELECT Id, Name, BodyLength, ParentId
            FROM Attachment
            WHERE ParentId IN :oppAttIds
        ]) {
            
            if (att.BodyLength < 7000000) {
                smallFileOppAttIds.add(att.ParentId);
                attachmentMap.put(att.ParentId, att);
            } else {
                bigFileOppAttIds.add(att.ParentId);
            }
        }
        
        // Handle Files
        Map<Id, ContentDocumentLink> fileMap = new Map<Id, ContentDocumentLink>();
        
        for (ContentDocumentLink doc : [
            SELECT LinkedEntityId,
            ContentDocumentId,
            ContentDocument.LatestPublishedVersion.Title,
            ContentDocument.LatestPublishedVersion.ContentSize,
            ContentDocument.LatestPublishedVersion.FileExtension
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :oppAttIds
        ]) {
            
            Integer size = doc.ContentDocument.LatestPublishedVersion.ContentSize;
            
            if (size < 7000000) {
                smallFileOppAttIds.add(doc.LinkedEntityId);
                fileMap.put(doc.LinkedEntityId, doc);
            } else {
                bigFileOppAttIds.add(doc.LinkedEntityId);
            }
        }
        
        // Send Big Files to HCL
        if (!bigFileOppAttIds.isEmpty()) {
            SL_OnBaseCallout.sendOnbaseAttachemntToHCL(oppId, bigFileOppAttIds);
        }
        
        
        
        // Send Small PDF Files to Ocrolus
        List<TC_Ocrolus_Upload_File__e> eventsToPublish = new List<TC_Ocrolus_Upload_File__e>();
        
        for (Opportunity_Attachment__c oppAttachment : oppAttachments) {
            
            if(oppAttachment.Type__c.contains(Label.TC_BankStatementFileType) && !oppAttachment.Type__c.contains(Label.TC_MTDFileType)){
            // Only process small files
            if (!smallFileOppAttIds.contains(oppAttachment.Id)) {
                continue;
            }
            
            Boolean isPDF = false;
            Id fileId;
            String fileName;
            String errorMessage;
            
            // Case 1: Classic Attachment
            if (attachmentMap.containsKey(oppAttachment.Id)) {
                
                Attachment att = attachmentMap.get(oppAttachment.Id);
                fileId = att.Id;
                fileName = att.Name;
                
                if (att.Name != null && att.Name.toLowerCase().endsWith('.pdf')) {
                    isPDF = true;
                }
                
            }
            // Case 2: File (ContentDocument)
            else if (fileMap.containsKey(oppAttachment.Id)) {
                
                ContentDocumentLink doc = fileMap.get(oppAttachment.Id);
                
                fileId = doc.ContentDocumentId;
                fileName = doc.ContentDocument.LatestPublishedVersion.Title;
                
                if (doc.ContentDocument.LatestPublishedVersion.FileExtension != null &&
                    doc.ContentDocument.LatestPublishedVersion.FileExtension.toLowerCase() == 'pdf') {
                        isPDF = true;
                    }
                
            }
            // No attachment found
            else {
                
                errorMessage = 'OnBase Attachment "' + oppAttachment.Name +
                    '" has no file attachments. Nothing uploaded to Ocrolus';
                
                Marlin_IntegrationLog.LogException(
                    'Ocrolus File Upload',
                    oppAttachment.Id,
                    'Error',
                    '',
                    '',
                    '',
                    errorMessage
                );
                
                continue;
            }
            
            // Not a PDF
            if (!isPDF) {
                
                errorMessage = '"' + fileName + '" is of unsupported or unknown file type, upload must be PDF. Not uploaded to Ocrolus';
                
                Marlin_IntegrationLog.LogException('Ocrolus File Upload', oppAttachment.Id, 'Error', '', '', '', errorMessage);
                
                continue;
            }
            
            // Valid PDF → Publish Event
            eventsToPublish.add(
                new TC_Ocrolus_Upload_File__e( PK__c = opp.PK__c, Att_Id__c = fileId, Opp_Att_Id__c = oppAttachment.Id, Callout_Type__c = 'upload'));
            }

        }
        
        if (!eventsToPublish.isEmpty()) {
            EventBus.publish(eventsToPublish);
        }
    }
    
    
}