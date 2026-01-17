/** @author : Tamarack Consulting, Inc.
 * @date : 4/6/20
 * @description: 
 *
 */
public with sharing class TC_AttachmentTriggerHandler {

    public class AttachmentRelation {

        public Opportunity_Attachment__c onBaseAttachment;
        public Attachment attachment;

        public AttachmentRelation(Opportunity_Attachment__c onBaseAttachment, Attachment attachment) {
            this.onBaseAttachment = onBaseAttachment;
            this.attachment = attachment;
        }
    }

    public static void convertBookingSheetsToOnBaseAttachments(List<Attachment> attachments) {

        List<Opportunity_Attachment__c> onBaseAttachments = new List<Opportunity_Attachment__c>();
        List<AttachmentRelation> attachmentRelations = new List<AttachmentRelation>();

        Set<Id> opportunityIds = new Set<Id>();
        for (Attachment a : attachments) {
            if (a.ParentId.getSobjectType() == Schema.Opportunity.getSObjectType()) {
                opportunityIds.add(a.ParentId);
            }
        }
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>([SELECT Id, Loan_Record_Type__c FROM Opportunity WHERE Id IN :opportunityIds]);

        for (Attachment attachment : attachments) {
            if (attachment.ParentId.getSobjectType() == Schema.Opportunity.getSObjectType()) {
                if (attachment.Name.contains('Booking Sheet')) {
                    Opportunity_Attachment__c onBaseAttachment = new Opportunity_Attachment__c();
                    onBaseAttachment.Name = attachment.Name;
                    onBaseAttachment.Description__c = attachment.Description;
                    onBaseAttachment.Type__c = (opportunityMap.get(attachment.ParentId).Loan_Record_Type__c
                            || attachment.Name.contains('Loan')) ? 'FS - Booking Sheet' : 'LC - Booking Sheet - Final';
                    onBaseAttachment.Opportunity__c = attachment.ParentId;
                    onBaseAttachment.Attachment__c = attachment.Id;
                    onBaseAttachments.add(onBaseAttachment);

                    Attachment clonedAttachment = attachment.clone();
                    attachmentRelations.add(new AttachmentRelation(onBaseAttachment, clonedAttachment));
                }
            }
        }

        if (!onBaseAttachments.isEmpty()) {
            insert onBaseAttachments;
        }

        List<Attachment> clonedAttachments = new List<Attachment>();
        for (AttachmentRelation attachmentRelation : attachmentRelations) {
            attachmentRelation.attachment.ParentId = attachmentRelation.onBaseAttachment.Id;
            clonedAttachments.add(attachmentRelation.attachment);
        }
        if (!clonedAttachments.isEmpty()) {
            insert clonedAttachments;
        }

        onBaseAttachments = new List<Opportunity_Attachment__c>();
        for (AttachmentRelation ar : attachmentRelations) {
            onBaseAttachments.add(new Opportunity_Attachment__c(Id = ar.onBaseAttachment.Id, Attachment__c = ar.attachment.Id));
        }
        if (!onBaseAttachments.isEmpty()) {
            update onBaseAttachments;
        }
    }
}