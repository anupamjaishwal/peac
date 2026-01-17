public with sharing class showCheckListCls{
    
    @Auraenabled
    public static List< TC_Origination__Checklist_Item_with_Attachments__c > getChecklists(String recId){
        system.debug('recId:'+recId);
        return [
            SELECT Id, Name, TC_Origination__Status__c 
            FROM TC_Origination__Checklist_Item_with_Attachments__c 
            WHERE TC_Origination__Checklist_s_Opportunity__c = :recId 
            AND TC_Origination__Included__c = True 
            AND TC_Origination__Internal_External__c = 'External'
            AND TC_Origination__Checklist__r.Name  like '%Credit Stips'
        ];
    }
    
    @Auraenabled
    public static Opportunity_Attachment__c getDocuments(String recId){
        return [SELECT Id, Type__c, Name FROM Opportunity_Attachment__c WHERE Id = :recId];
    }
    
    @AuraEnabled
    public static List<Opportunity_Attachment__c> uploadFile(String type, String contentDocuments, String filename, String recordId) {
        
        List<contentDoc> conDoc = (List<contentDoc>)JSON.deserialize(
               contentDocuments, List<contentDoc>.class);
       Map<String, Opportunity_Attachment__c> OpportunityAttachmentMap = new Map<string, Opportunity_Attachment__c>();
       List<Id> attachIds = new List<string>();
       for(contentDoc cd : conDoc){
           Opportunity_Attachment__c oa = new Opportunity_Attachment__c(
                Name = cd.Name,
                Opportunity__c = recordId,
                Type__c= type,
                Dealer_Doc_Type__c= type
            );
            OpportunityAttachmentMap.put(cd.documentId, oa);
        }
        insert OpportunityAttachmentMap.values();
        List<ContentDocumentLink>  ContentDocumentLinks = new List<ContentDocumentLink>();
        for(contentDoc cd : conDoc){
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = cd.documentId;
            cdl.LinkedEntityId = OpportunityAttachmentMap.get(cd.documentId).Id;
            cdl.ShareType = 'V';
            ContentDocumentLinks.add(cdl);
            attachIds.add(cdl.LinkedEntityId );
        }
        insert ContentDocumentLinks;
        return [SELECT Id, Type__c, Name FROM Opportunity_Attachment__c WHERE Id IN :attachIds];
  }
  
  public class contentDoc{
      public string Name;
      public String documentId;
  }
 
      
}