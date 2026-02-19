trigger TC_OpportunityAttachment on Opportunity_Attachment__c (before insert, after insert, before update, after update) {
    //if (Trigger.isAfter && Trigger.isInsert) TC_OpportunityAttachmentHelper.sendStatementsOnBaseURLToCC (Trigger.newMap);
    if (Trigger.isAfter && Trigger.isUpdate) {
      TC_OpportunityAttachmentHelper.deleteOldAttachments(Trigger.new);
    }else if(Trigger.isBefore && Trigger.isUpdate){
      TC_OpportunityAttachmentHelper.onBeforeUpdate(Trigger.newMap, Trigger.oldMap);
    }

    if(Trigger.isAfter && Trigger.isInsert){
      TC_OpportunityAttachmentHelper.onBaseUploadNotification(Trigger.new);
    }else if(Trigger.isBefore && Trigger.isInsert){
      TC_OpportunityAttachmentHelper.onBeforeInsert(Trigger.new);
    }
}