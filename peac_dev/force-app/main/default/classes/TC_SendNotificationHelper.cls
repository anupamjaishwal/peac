public inherited sharing class TC_SendNotificationHelper {
    
    public static Map<Id, List<Messaging.EmailFileAttachment>> oppsWithEmailAttachments(Set<Id> oppIds) {
        
        Map<Id, List<Messaging.EmailFileAttachment>> oppWithEmailAtts = new Map<Id, List<Messaging.EmailFileAttachment>>();
        
        //get latest DocuSign Status record for each opportunity
        Map<Id, Id> docuSignStatusIds = new Map<Id, Id>();
        List<Opportunity> oppWithDocuSignList = [SELECT Id, (Select Id, Name FROM dsfs__R00N80000002fD9vEAE__r ORDER BY CreatedDate Desc LIMIT 1) 
                                                 FROM Opportunity WHERE Id IN :oppIds];
        
        //map Opportuity Id to DocuSign Status Id
        for (Opportunity opp : oppWithDocuSignList) {
            for (dsfs__DocuSign_Status__c ds : opp.dsfs__R00N80000002fD9vEAE__r) {
                docuSignStatusIds.put(opp.Id, ds.Id);
            }
        }
        
        if (docuSignStatusIds.values().size() > 0) {
            //get Attachments 
            List<Attachment> files = [SELECT Id, ParentId, Name, Body, ContentType FROM Attachment WHERE ParentId IN :docuSignStatusIds.values() 
                                      AND (NOT Name LIKE 'Documents - Blank Doc%') AND (NOT Name LIKE 'Certificate%')];
            system.debug('FILES: ' + files);
            
            //get ContentDocuments
            List<ContentDocumentLink> docLinks = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocument.LatestPublishedVersion.VersionData, ContentDocument.FileType FROM ContentDocumentLink WHERE LinkedEntityId IN :docuSignStatusIds.values()
                                                  AND (NOT ContentDocument.Title LIKE 'Documents - Blank Doc%') AND (NOT ContentDocument.Title LIKE 'Certificate%')];
            system.debug('DOCS' + docLinks);
            
            //add each file as an EmailFileAttachment to the opportunities they are mapped to
            for (Opportunity opp : oppWithDocuSignList) {
                for (Attachment file : files) {
                    if (file.ParentId == docuSignStatusIds.get(opp.Id)) {
                        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                        efa.setFileName(file.Name);
                        efa.setBody(file.Body);
                        efa.setContentType(file.ContentType);
                        
                        if (oppWithEmailAtts.containsKey(opp.Id)) {
                            List<Messaging.EmailFileAttachment> emailAtts = oppWithEmailAtts.get(opp.Id);
                            emailAtts.add(efa);
                            oppWithEmailAtts.put(opp.Id, emailAtts);
                        }else {
                            oppWithEmailAtts.put(opp.Id, new List<Messaging.EmailFileAttachment> {efa});
                        }
                    }
                }
                for (ContentDocumentLink file: docLinks) {
                    if (file.LinkedEntityId == docuSignStatusIds.get(opp.Id)) {
                        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                        efa.setFileName(file.ContentDocument.Title);
                        efa.setBody(file.ContentDocument.LatestPublishedVersion.VersionData);
                        
                        if (oppWithEmailAtts.containsKey(opp.Id)) {
                            List<Messaging.EmailFileAttachment> emailAtts = oppWithEmailAtts.get(opp.Id);
                            emailAtts.add(efa);
                            oppWithEmailAtts.put(opp.Id, emailAtts);
                        }else {
                            oppWithEmailAtts.put(opp.Id, new List<Messaging.EmailFileAttachment> {efa});
                        }
                    }
                }
            }
        }
        System.debug('oppWithEmailAtts: ' + oppWithEmailAtts);
        
        return oppWithEmailAtts;
        
    }
}