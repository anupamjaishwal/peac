/** @author : Tamarack Consulting, Inc.
 * @date : 4/6/20
 * @description: 
 *
 */
trigger TC_Attachment on Attachment (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        TC_AttachmentTriggerHandler.convertBookingSheetsToOnBaseAttachments(Trigger.new);
    }
}