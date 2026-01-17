/** 
 * @description Gets called on Document link trigger to clone attachments on stip checklist to the opportunity's onbase attachments
 * Created by: Trohweder 6/30/21
 * SAL-3037
 */
public with sharing class TC_ContDocumentLinkTriggerHelper {

    /** 
     * @param links list of inserted content document links
    * @description Gets called on Document link trigger to clone attachments on stip checklist to the opportunity's onbase attachments
    * Created by: Trohweder 6/30/21
    * SAL-3037
    */
    public static void createOnBaseAttachments(List<ContentDocumentLink> links){

        Set<Id> checklistItemIds = new Set<Id>();
        Set<Id> contentDocIds = new Set<Id>();
        List<ContentDocumentLink> neededLinks = new List<ContentDocumentLink>();
        Map<Id, Opportunity_Attachment__c> onBaseAttachments = new Map<Id, Opportunity_Attachment__c>();
        List<Attachment> attachments = new List<Attachment>();

        for(ContentDocumentLink link : links){
            if(link.LinkedEntityId.getSObjectType().getDescribe().getName() == 'TC_Origination__Checklist_Item_with_Attachments__c'){
                checklistItemIds.add(link.LinkedEntityId);
                contentDocIds.add(link.ContentDocumentId);
                neededLinks.add(link);
            }
        }

        if(neededLinks.size() > 0){
            Map<Id, TC_Origination__Checklist_Item_with_Attachments__c> checklistItemMap = new Map<Id, TC_Origination__Checklist_Item_with_Attachments__c>([
            SELECT Id, TC_Origination__Checklist__r.TC_Origination__Opportunity__c, TC_Origination__Checklist__r.Name
            FROM TC_Origination__Checklist_Item_with_Attachments__c
            WHERE Id IN :checklistItemIds
            ]);

            List<Contentversion> versions = [SELECT Id, Title, FileExtension, VersionData, FileType, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN :contentDocIds];
            Map<Id, ContentVersion> versionMap = new Map<Id, ContentVersion>();
            for(Contentversion version : versions){
                versionMap.put(version.ContentDocumentId, version);
            }

            for(ContentDocumentLink link : neededLinks){
                if(checklistItemMap.get(link.LinkedEntityId).TC_Origination__Checklist__r.Name.toLowerCase().indexOf('stips') != -1){
                    Opportunity_Attachment__c att = new Opportunity_Attachment__c(
                    Opportunity__c = checklistItemMap.get(link.LinkedEntityId).TC_Origination__Checklist__r.TC_Origination__Opportunity__c 
                    , Name=versionMap.get(link.ContentDocumentId).Title
                    , Type__c='CR - Misc');
                
                    onBaseAttachments.put(link.ContentDocumentId, att);
                }
            }

            insert onBaseAttachments.values();

            for(Id key : onBaseAttachments.keyset()){
                Attachment attachment = new Attachment(parentId=onBaseAttachments.get(key).Id, Name=versionMap.get(key).Title, body=versionMap.get(key).VersionData, ContentType=versionMap.get(key).FileType, IsPrivate=false);
                attachments.add(attachment);
            }

            insert attachments;
        }
    }
}