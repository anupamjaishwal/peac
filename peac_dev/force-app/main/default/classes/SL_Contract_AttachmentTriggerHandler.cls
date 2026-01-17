public with sharing class SL_Contract_AttachmentTriggerHandler extends SL_Trigger.baseHandler {
    private Map<Id, Contract__c> contracts = new Map<Id, Contract__c>();
    Map<Id, List<Attachment>> attachments = new Map<Id, List<Attachment>>();

    public override void beforeInsert(List<SObject> newList){
        List<Contract_Attachment__c> theList = new List<Contract_Attachment__c>();
        for(SObject theObject :newList){
            getLookupMaps(theObject);
            theList.add((Contract_Attachment__c)theObject);
        }
        beforeChangesToSelf(theList, true);
    }

    public override void beforeUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
        // checkUpdatedFields(oldMap, newMap);
        List<Contract_Attachment__c> theList = new List<Contract_Attachment__c>();
        for (Id contractAttachmentId :newMap.keySet()){
            SObject theObject = newMap.get(contractAttachmentId);
            getLookupMaps(theObject);
            theList.add((Contract_Attachment__c)theObject);
        }
        beforeChangesToSelf(theList, false);
    }

    public override void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
        // getInfoFromOthers();
        // // afterChangesToOthers() not needed until we also have an afterInsert
        // List<String> contractIds = new List<String>();
        // for(SObject theObject :newMap.values()){
        //     Contract_Attachment__c contractAttachment = (Contract_Attachment__c)theObject;
        //     List<Attachment> filesToSend = this.attachments.get(contractAttachment.Id);
        //     if(filesToSend.size() > 0 && contractAttachment.Contract__c != null){
        //         Contract__c contract = this.contracts.get(contractAttachment.Contract__c);
        //         if(contract.Customer__c != null && String.isNotBlank(contract.Customer__r.Name)){
        //             contractIds.add(contract.Id);
        //         }
        //     }
        // }
        // if(contractIds.size() > 0){
        //     System.enqueueJob(new SL_UploadAttachmentQ(contractIds));
        // }
    }

    private void getLookupMaps(SObject obj){
        Contract_Attachment__c contractAttachment = (Contract_Attachment__c)obj;
        if(contractAttachment.Contract__c != null){
            this.contracts.put(contractAttachment.Contract__c, new Contract__c());
        }
        if(contractAttachment.Id != null){
            this.attachments.put(contractAttachment.Id, new List<Attachment>());
        }
    }

    private void getInfoFromOthers(){
        // this.contracts.putAll([SELECT Id, Customer__c, Customer__r.Name FROM Contract__c WHERE Id IN :this.contracts.keySet()]);
        // List<Attachment> allAttachments = [SELECT Id, Name, ParentId FROM Attachment WHERE ParentId IN :this.attachments.keySet()];
        // for(Id contractAttachmentId : this.attachments.keySet()){
        //     List<Attachment> attachmentsPerId = new List<Attachment>();
        //     for(Attachment attachment : allAttachments){
        //         if(attachment.ParentId == contractAttachmentId){
        //             attachmentsPerId.add(attachment);
        //         }
        //     }
        //     this.attachments.put(contractAttachmentId, attachmentsPerId);
        // }
    }

    private void beforeChangesToSelf(List<Contract_Attachment__c> newList, Boolean isNew){
        for (Contract_Attachment__c contractAttachment :newList){
            if(isNew && String.isEmpty(contractAttachment.Name)){
                contractAttachment.isFromDocGen__c = true;
            }
        }
    }
}