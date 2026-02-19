trigger TC_ContentDocumentLinkTrigger on ContentDocumentLink (before insert) {
    TC_ContDocumentLinkTriggerHelper.createOnBaseAttachments(trigger.new);
}