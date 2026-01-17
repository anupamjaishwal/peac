global class BatchToDelDocusignDupAtt implements Database.Batchable<sObject>,Database.Stateful{
    List<Id> tobeDeletedRecordIds = new List<Id>();
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String dynamicQuery = 'SELECT Id,Name,lastModifiedDate,BodyLength,ParentId FROM Attachment WHERE ParentId IN (SELECT Id FROM dsfs__DocuSign_Status__c WHERE dsfs__Opportunity__r.StageName = \'Funded/Booked\') Order By Name,LastModifiedDate ASC';
        return Database.getQueryLocator(dynamicQuery);
    } 
    global void execute(Database.BatchableContext bc, List<Attachment> scope){
        try{
            List<Attachment> atts = new List<Attachment>();
            Map<String,Id> attNames = new Map<String,Id>();    
            for(Attachment att:scope)
            {
                attNames.put(att.ParentId+att.Name,att.Id);                                          
            }
            atts = [select Id,Name,LastModifiedDate,parentId from Attachment where ID IN :scope and ID NOT IN :attNames.Values()];
            
            if(atts.size()>0)
            {
                Database.delete(atts,false);
            }  
        }catch(exception ex)
        {
            
        }
    }
    global void finish(Database.BatchableContext bc){
        
    }
    
}