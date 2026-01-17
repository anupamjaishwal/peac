public with sharing class SL_DealerPortalCAAttachment {
    @AuraEnabled
    public static string hubExecute(String methodName, List<String> methodParameters){
        String result = '';
        try {
            switch on methodName {
                when 'updateOppAttachment'{
                    result = updateOppAttachment(methodParameters[0], methodParameters[1]);
                }
                when 'getOppAttachments'{
                    result = getOppAttachments(methodParameters[0]);
                }
                when 'createAttachment'{
                    result = createAttachment(methodParameters[0], methodParameters[1], methodParameters[2]);
                }
                when 'appendChunk'{
                    result = appendChunk(methodParameters[0], methodParameters[1], methodParameters[2], methodParameters[3]);
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return result;
    }

    public static String updateOppAttachment(String oppAttachmentId, String attachmentId){
        update new Opportunity_Attachment__c(Id = oppAttachmentId, Attachment__c = attachmentId);
        List<Opportunity_Attachment__c> oppAttachments = [SELECT Id, Opportunity__c FROM Opportunity_Attachment__c WHERE Id = :oppAttachmentId];
        return getOppAttachments(oppAttachments[0].Opportunity__c);
    }

    public static String getOppAttachments(String opportunityId){
        //List<Opportunity_Attachment__c> oppAttachments = [SELECT Id, Name, Dealer_Doc_Type__c, createdById FROM Opportunity_Attachment__c WHERE (Opportunity__c = :opportunityId) OR (Dealer_Doc_Type__c IN ('CR - Credit Application','CR- Invoice/Quote/Proposal','CR - Bank Statements','CR - Financial Statements','CR - Misc','LC - External'))];
        List<Opportunity_Attachment__c> oppAttachments = [SELECT Id, Name, DPSuperUserDocuments__c, Dealer_Doc_Type__c,Type__c, createdById FROM Opportunity_Attachment__c WHERE Opportunity__c = :opportunityId];
        return JSON.serialize(oppAttachments, true);
    }
    @AuraEnabled
    public static Boolean checkSuperUser(){
        Boolean superUser = false;
        List<User> usrList = [select Id, SuperUser__c from User where Id = :UserInfo.getUserId()];
        if(usrList.size() > 0) {
            superUser = usrList.get(0).SuperUser__c;
        }
       return superUser;
    }

    public static String createAttachment(String parentId, String fileName, String fileContent){
        // blob blobContent = EncodingUtil.base64Decode(EncodingUtil.urlDecode(fileContent, 'UTF-8'));
        blob blobContent = EncodingUtil.base64Decode(fileContent);
        Attachment newAttachment = new Attachment(Name = fileName, ParentId = parentId, 
            Body = blobContent);
        insert newAttachment;
        return String.valueOf(newAttachment.Id);
    }
    
    public static String appendChunk(String attachmentId, String moreContent, String partNumber, String isLastPart){
        Attachment incompleteAtt = [SELECT Id, Name, Body, ParentId FROM Attachment WHERE Id = :attachmentId];
        if(EncodingUtil.base64Encode(incompleteAtt.Body).length() + System.Limits.getHeapSize() < System.Limits.getLimitHeapSize()){
            incompleteAtt.Body = EncodingUtil.base64Decode(EncodingUtil.base64Encode(incompleteAtt.Body) + moreContent);
            update incompleteAtt;
        }else{
            Attachment newAttachment = new Attachment(Name = attachmentId + '_' + partNumber, ParentId = incompleteAtt.ParentId, 
                Body = EncodingUtil.base64Decode(moreContent));
            insert newAttachment;
            if(Boolean.valueOf(isLastPart)){
                joinBigAttachment(attachmentId, Integer.valueOf(partNumber));
            }
        }
        return attachmentId;
    }

    @future
    public static void joinBigAttachment(Id attachmentId, Integer totalParts){
        Attachment incompleteAtt = [SELECT Id, Name, Body, ParentId FROM Attachment WHERE Id = :attachmentId];
        Map<Id, Attachment> toDelete = new Map<Id, Attachment>();
        for(Integer i = 2; i <=totalParts; i++){
            String partName = String.valueOf(attachmentId) + '_' + String.valueOf(i);
            Attachment partAttachment = [SELECT Id, Name, Body, ParentId FROM Attachment WHERE Name = :partName AND ParentId = :incompleteAtt.ParentId];
            incompleteAtt.Body = Blob.valueOf(incompleteAtt.Body.toString() + partAttachment.Body.toString());
            toDelete.put(partAttachment.Id, partAttachment);
        }
        update incompleteAtt;
        delete toDelete.values();
    }
}