public class showAllDocuments{

    @auraEnabled(cacheable=true)
    
    public static List<attachDoc> generatedDocuments(String parentId){
        system.debug('parentId:'+parentId);
        List<attachDoc> documents = new List<attachDoc>();
        for(ContentDocumentLink cdl : [SELECT Id, LinkedEntityId, ContentDocument.createdDate, ContentDocument.Title, ContentDocument.FileType, ContentDocument.ContentSize, Visibility FROM ContentDocumentLink WHERE LinkedEntityId = :parentId]){
            documents.add(
                new attachDoc(
                    cdl.ContentDocument.Id, cdl.ContentDocument.createdDate, cdl.ContentDocument.Title
                )
            );
        }
        
        for(Attachment att : [SELECT Id, Name, CreatedDate FROM Attachment WHERE ParentId = :parentId]){
            documents.add(
                new attachDoc(
                    att.Id, att.createdDate, att.Name
                )
            );
        }
        return documents;
    }
    
    public class attachDoc{
        
        public attachDoc(String recId, DateTime createDate, String name){
            String sfURL = System.URL.getSalesforceBaseUrl().toExternalForm();

            this.Id = recId;
            this.CreatedDate = createDate.format();
            this.Title = name;
            this.url = recId.startsWith('00P') ? sfURL+'/dealers/servlet/servlet.FileDownload?file='+recId : sfURL+'/dealers/sfc/servlet.shepherd/document/download/'+recId;
        }
        @auraEnabled public String Id;
        @auraEnabled public String CreatedDate;
        @auraEnabled Public String Title;
        @auraEnabled Public String url;
    }

}