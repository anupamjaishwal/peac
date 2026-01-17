global with sharing class TC_OnBaseApex implements TC_ORIGINATION.IOnBaseApex {
    public String doUploadAttachment (String attachmentBody, String attachmentName, String attachmentType, String attachmentId, String parentItemId, String rootItemId, Boolean doneUploading) {
        TC_ORIGINATION__Checklist_Item_with_Attachments__c ci = [SELECT TC_ORIGINATION__Checklist__r.TC_ORIGINATION__Opportunity__c, TC_ORIGINATION__OnBase_Document_Type__c FROM TC_ORIGINATION__Checklist_Item_with_Attachments__c WHERE Id = :parentItemId][0];
        
        if (ci.TC_ORIGINATION__Checklist__r.TC_ORIGINATION__Opportunity__c != null) {
            Opportunity opp = [SELECT Id FROM Opportunity WHERE Id = :ci.TC_ORIGINATION__Checklist__r.TC_ORIGINATION__Opportunity__c][0];
        
            UploadAttachment ctrl = new UploadAttachment (new ApexPages.StandardController (opp));
            ctrl.selectedType = ci.TC_ORIGINATION__OnBase_Document_Type__c;
            ctrl.fileName = attachmentName;
            ctrl.fileBody = EncodingUtil.base64Decode (attachmentBody);
            
            System.debug ('<<<<< ctrl.selectedType ' + ctrl.selectedType);
            
            ctrl.processUpload ();
            ctrl.sendAttachmentToOnBase ();
        }
        
        return '';
    }
}