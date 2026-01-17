public with sharing class SL_AttachmentTriggerHandler extends SL_Trigger.baseHandler {
    private Map<Id, Contract_Attachment__c> contractAttachments = new Map<Id, Contract_Attachment__c>();

    public override void afterInsert(Map<Id, SObject> newMap){
        for(SObject theObject :newMap.values()){
            getLookupMaps(theObject);
        }
        getInfoFromOthers();
        afterChangesToOthers(newMap, true);
        sendApprovedEmail(newMap);
    }

    public override void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
        for(SObject theObject :newMap.values()){
            getLookupMaps(theObject);
        }
        getInfoFromOthers();
        afterChangesToOthers(newMap, false);
        
    }

    private void getLookupMaps(SObject obj){
        Attachment theAttachment = (Attachment)obj;
        if(theAttachment.ParentId != null){
            this.contractAttachments.put(theAttachment.ParentId, new Contract_Attachment__c());
        }
    }

    private void getInfoFromOthers(){
        this.contractAttachments.putAll([SELECT Id, isFromDocGen__c, Sent_To_OnBase__c, Contract__c, Contract__r.Customer__r.Name, Attachment__c FROM Contract_Attachment__c WHERE Id IN :this.contractAttachments.keySet()]);
    }

    private void afterChangesToOthers(Map<Id, SObject> newMap, Boolean isNew){
        List<String> contractIds = new List<String>();
        List<Contract_Attachment__c> contractAttachmentsToUpdate = new List<Contract_Attachment__c>();
        Map<Id, Attachment> opportunityAttachmentsToUpdate = new Map<Id, Attachment>();
        for(SObject theObject :newMap.values()){
            Attachment theAttachment = (Attachment)theObject;
            Contract_Attachment__c contractAttachment = this.contractAttachments.get(theAttachment.ParentId);
            if(contractAttachment != null && contractAttachment.isFromDocGen__c && !contractAttachment.Sent_To_OnBase__c 
                && contractAttachment.Contract__c != null && contractAttachment.Contract__r.Customer__c != null 
                && String.isNotBlank(contractAttachment.Contract__r.Customer__r.Name)){
                contractIds.add(contractAttachment.Contract__c);
            }
            if(contractAttachment != null && theAttachment.ParentId.getSObjectType().getDescribe().getName() == 'Contract_Attachment__c'){
                contractAttachment.Attachment__c=theObject.Id;
                contractAttachmentsToUpdate.add(contractAttachment);
            }
            
            if(theAttachment.ParentId.getSObjectType().getDescribe().getName() == 'Opportunity_Attachment__c'){
                opportunityAttachmentsToUpdate.put(theAttachment.ParentId, theAttachment);
            }
            
        }
        //Update contract attachment
        if(contractAttachmentsToUpdate.size() > 0){
            update contractAttachmentsToUpdate;
        }
        //Update opportunity attachment
        if(opportunityAttachmentsToUpdate.size() > 0){
            List<Opportunity_Attachment__c> oppAttList = [SELECT Id, Name, Attachment__c FROM Opportunity_Attachment__c WHERE Id IN :opportunityAttachmentsToUpdate.keySet()];
            for(Opportunity_Attachment__c oppa : oppAttList){
                oppa.Attachment__c = opportunityAttachmentsToUpdate.get(oppa.Id).Id;
            }
            update oppAttList;
        }
        if(contractIds.size() > 0){
            System.enqueueJob(new SL_UploadAttachmentQ(contractIds));
        }
    }
    
    
    public void sendApprovedEmail(Map<Id, SObject> newMap) {
        set<id> parentIdSet = new set<id>();
        for(Attachment theAttachment : (List<Attachment>) newMap.values()) {
            if(theAttachment.ParentId.getSObjectType().getDescribe().getName() == 'Opportunity_Attachment__c'){
                parentIdSet.add(theAttachment.ParentId);
            }
        }
        Map<Id, Opportunity> approvedMap = new Map<Id, Opportunity>([select Id, OwnerId, StageName, Application_Status__c, Primary_Broker__c from Opportunity 
                                            where Id IN 
                                            (select Opportunity__c from Opportunity_Attachment__c 
                                             where 
                                             Opportunity__r.Loan_Record_Type__c = true
                                             AND (Dealer_Doc_Type__c = 'Approval Letter' OR Type__c = 'FS - Approval Letter' OR Type__c = 'Approval Letter')
                                             AND Id IN :parentIdSet)
                                           ]);
        System.debug('sendApprovedEmail::');
        if(approvedMap.size() > 0) {
             TC_SendLoanNotifications.checkNotificationCenter(approvedMap, 'Approved_Loan__c', 'Loan Approved');
        }
        
    }



}