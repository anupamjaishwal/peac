trigger SL_Attachment on Attachment (after insert, after update) {
    SL_Trigger.dispatchHandler(Attachment.SObjectType, new SL_AttachmentTriggerHandler());
}