public class SL_sendAttachmentsQueueable implements Queueable, Database.AllowsCallouts {
    private Id oppId;
    private Boolean onlyOcrolus;

    public SL_sendAttachmentsQueueable(Id oppId, Boolean onlyOcrolus) {
        this.oppId = oppId;
        this.onlyOcrolus = onlyOcrolus;
    }
    
    public void execute(QueueableContext context) {
		Set<Id> onbaseAttIds = new Set<Id>();
        List<String> attachmentsIds = new List<String>();
        List<String> bigAttachmentsIds = new List<String>();

        for(Opportunity_Attachment__c  oa : [SELECT Id FROM Opportunity_Attachment__c WHERE Opportunity__c =: oppId]){
            onbaseAttIds.add(oa.Id);
        }

        for (Attachment att : [SELECT ID,Name, BodyLength, ParentId, CreatedDate FROM Attachment WHERE ParentId IN :onbaseAttIds]) {      
            if (att.BodyLength < 7000000) {
                attachmentsIds.add(att.ParentId);
            } else {
                bigAttachmentsIds.add(att.ParentId);
            }
        }


        for(ContentDocumentLink doc : [SELECT ID, LinkedEntityId, ContentDocumentId,  ContentDocument.LatestPublishedVersion.ContentSize, ContentDocument.LatestPublishedVersionId, ContentDocument.LatestPublishedVersion.Title FROM ContentDocumentLink WHERE LinkedEntityId IN :onbaseAttIds]){
            if (doc.ContentDocument.LatestPublishedVersion.ContentSize < 7000000) {
                attachmentsIds.add(doc.LinkedEntityId);
            } else {
                bigAttachmentsIds.add(doc.LinkedEntityId);
            }
            
        }

        if(bigAttachmentsIds.size()>0)
        {                        
            SL_OnBaseCallout.sendOnbaseAttachemntToHCL(oppId, bigAttachmentsIds);
        }
        if(attachmentsIds.size()>0 && !onlyOcrolus)
        {
            MARLIN_OnBaseCalloutForCC.sendCCAttachmentToOnBase(oppId,True, attachmentsIds);
            EventBus.publish(new TC_Ocrolus_Add_Book__e(Opportunity_Id__c = oppId));

        }
        if (!attachmentsIds.isEmpty() && onlyOcrolus) {
            EventBus.publish(new TC_Ocrolus_Add_Book__e(Opportunity_Id__c = oppId));
        }
    }

}