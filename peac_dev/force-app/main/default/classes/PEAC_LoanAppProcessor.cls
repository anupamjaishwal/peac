/************************************************************************************************************************
 @Description: Orchestration of Loan app to submit, rescore and submit from portal. Invoke the list of
                business process and orchestrate the callout.
 @Author: Rajesh Kumar(LTIMindtree)
 @Created Date: 06/16/2025
 ************************************************************************************************************************/

public with sharing class PEAC_LoanAppProcessor implements Queueable, Database.AllowsCallouts {
    String executionType;
    Id oppId;
    private static Set<Id> processedOpps = new Set<Id>();
    public PEAC_LoanAppProcessor(String executionType, Id oppId)
    {
        this.executionType = executionType;
        this.oppId = oppId;
    }
    public void execute(QueueableContext qc)
    {
        
        Set<Id> accIdSet = getAccountIds(oppId);
        Set<Id> oppIdSet = New Set<Id>();
        oppIdSet.add(oppId);
        if(executionType == Label.PEAC_Initiate_Loan_App_to_GDS)
        {
           
            //1.Generate Account CCID if not there                
            PEAC_AutoCCIDNumber.updateCCIDNumber(accIdSet);
            //2.Generate loan app number if not there
            PEAC_AutoCaseCenterNumber.updateOppAppNumber(oppIdSet);
            //3.Send attachment to onbase
            sendAttachmentsToOnbaseAndOcrolus(oppId);
            //4.Call Ocrolus to book the app
            //EventBus.publish(new TC_Ocrolus_Add_Book__e(Opportunity_Id__c = oppId));
        
            //TC_OcrolusCtrl.processOcrolusAttachmentList(oppId);
            //Call Storeprocedures and GDS
            //Now calling this from flow
            //EventBus.publish(new GDS_Action__e(Record_Id__c = oppId,Action__c = Label.PEAC_Initial_Submission));
           
        }
        else if(executionType == Label.PEAC_Initial_Submission || executionType == Label.PEAC_Teaser_Initial_Submission)
        {
            //added the below code for Teaser loan app
            if(executionType == Label.PEAC_Teaser_Initial_Submission)
            {
                //1.Generate Account CCID if not there                
                PEAC_AutoCCIDNumber.updateCCIDNumber(accIdSet);
                //2.Generate loan app number if not there
                PEAC_AutoCaseCenterNumber.updateOppAppNumber(oppIdSet);
            }
            //Call HCL for store procedures and from there system calls gds for scoring
            If(!test.isrunningtest()){
                System.enqueueJob(new SL_CaseCenterStoredProcedureQueueable(new List<String>{'getGdsGetCustCreditExpLoan', 'getGDSFraudFlags'},oppId, executionType));         
            }
        }
        else if(executionType == Label.PEAC_Portal_Loan_APP || executionType == Label.PEAC_Rescore)
        {
            //1.Generate Account CCID if not there                
            PEAC_AutoCCIDNumber.updateCCIDNumber(accIdSet);
            //2.Generate loan app number if not there
            PEAC_AutoCaseCenterNumber.updateOppAppNumber(oppIdSet);
            //3.Call HCL for store procedures and from there system calls gds for scoring
            If(!test.isrunningtest()){
                System.enqueueJob(new SL_CaseCenterStoredProcedureQueueable(new List<String>{'getGdsGetCustCreditExpLoan', 'getGDSFraudFlags'},oppId, executionType));     
            }
        }
        else if(executionType == Label.PEAC_Pull_Bank_Details_Action)
        {
            PEAC_GDSScoreLoanAPI.callType = 'Ocrolus';
            PEAC_OcrolusRepullBankDetails.executeOcrolusPull(oppId);
        }
    }
    public static Set<Id> getAccountIds(Id oppId)
    {
        Set <Id> accIdSet = New Set<Id>();
        for(Opportunity opp:[SELECT Id,AccountId FROM Opportunity WHERE Id =:oppId LIMIT 1])
        {
            if(opp.AccountId !=null)
            {
               accIdSet.add(opp.AccountId);
            }
        }
        return accIdSet;
    }
    @AuraEnabled
    public static void runGDSRescore(String oppId) {
        if (processedOpps.contains(oppId)) return;
        processedOpps.add(oppId);
        
       // markRescorePivotNow(oppId);
        EventBus.publish(new GDS_Action__e(Record_Id__c = oppId, Action__c = Label.PEAC_Rescore));
    }

    
    @AuraEnabled
    public static void pullBankDetails(string oppId) {
        if (processedOpps.contains(oppId)) {
            return;
        }
        processedOpps.add(oppId);
        EventBus.publish (new GDS_Action__e  (Record_Id__c  = oppId,Action__c = Label.PEAC_Pull_Bank_Details_Action));
    }

    public static void sendAttachmentsToOnbaseAndOcrolus(String oppId){
        Set<Id> onbaseAttIds = new Set<Id>();
        List<String> attachmentsIds = new List<String>();
        List<String> bigAttachmentsIds = new List<String>();

        for(Opportunity_Attachment__c  oa : [SELECT Id FROM Opportunity_Attachment__c WHERE Opportunity__c =: oppId]){
            onbaseAttIds.add(oa.Id);
        }




        for (Attachment att : [SELECT ID,Name, BodyLength, ParentId, CreatedDate FROM Attachment WHERE ParentId IN :onbaseAttIds])
        {
            if (att.BodyLength < 7000000) {
                attachmentsIds.add(att.ParentId);
            }
            else{
                bigAttachmentsIds.add(att.ParentId);
            }
        }

        if(bigAttachmentsIds.size()>0)
        {                        
            SL_OnBaseCallout.sendOnbaseAttachemntToHCL(oppId, bigAttachmentsIds);
        }
        if(attachmentsIds.size()>0)
        {
            MARLIN_OnBaseCalloutForCC.sendCCAttachmentToOnBase(oppId,True, attachmentsIds);
        }
        if (!attachmentsIds.isEmpty() && bigAttachmentsIds.isEmpty()) {
            EventBus.publish(new TC_Ocrolus_Add_Book__e(Opportunity_Id__c = oppId));
        }
    }
}