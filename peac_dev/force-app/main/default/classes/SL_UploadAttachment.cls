public class SL_UploadAttachment {
    private Contract__c contractRecord {get;set;} 
    public String contractName {get; set;}
    public String lParentId = '';
    static final String FILL_CUSTOMER_MESSAGE = 'The Customer Account Name is required in order to Send to Onbase';

    public SL_UploadAttachment() { 
        Id id = ApexPages.currentPage().getParameters().get('id');
        contractRecord = (id == null) ? new Contract__c() : 
            [SELECT Name, Application_Number__c FROM Contract__c WHERE Id = :id];
        contractName = contractRecord.Name;
    }
    
    @AuraEnabled(Cacheable = true)
    public static List<Contract__c> getOtherContracts(Id contractId) {
        Contract__c currentContract = [SELECT Id, Customer__c FROM Contract__c WHERE Id = :contractId];
        List<Contract__c> otherContracts = [SELECT Id, Name, Status__c, Customer__c FROM Contract__c WHERE Id != :contractId AND Customer__c = :currentContract.Customer__c];
        return otherContracts;
    }

    @AuraEnabled
    public static string hubExecute(String methodName, List<String> methodParameters){
        try {
            String result = '';
            switch on methodName {
                when 'saveAttachment'{
                    result = saveAttachment((Id)methodParameters[0], methodParameters[1], methodParameters[2]);
                }
                when 'saveOtherContracts'{
                    result = saveOtherContracts(methodParameters[0], methodParameters[1], methodParameters[2]);
                }
                when 'justSaveAttachment'{
                     result = SL_DealerPortalCAAttachment.createAttachment(methodParameters[0], methodParameters[1], methodParameters[2]);
                }
                when 'appendChunk'{
                    result = SL_DealerPortalCAAttachment.appendChunk(methodParameters[0], methodParameters[1], methodParameters[2], methodParameters[3]);
               }
               when 'sendToOnBaseFromAcc'{
                    result = sendToOnBaseFromAcc(methodParameters[0]);
                }
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static string saveAttachment(Id parentId, String fileName, String fileBody){
        String finalResult = '';
        Database.SaveResult result;
        Attachment attachment = new Attachment();
        attachment.body = EncodingUtil.base64Decode(EncodingUtil.urlDecode(fileBody, 'UTF-8'));
        attachment.name = fileName;
        attachment.parentId = parentId;
        result = Database.insert(attachment);
        if (result != null && result.isSuccess()){
            // no longer needed, class SL_AttachmentTriggerHandler now does this update for opportunity_Attachment__c and Contract_Attachment__c
            // Contract_Attachment__c customAttachment = [select id from Contract_Attachment__c where id = :parentId];
            // customAttachment.name = fileName;
            // customAttachment.Attachment__c = result.getId();
            // update customAttachment;
            finalResult = 'success';
        }
        return finalResult;
    }

    @testVisible
    static string saveOtherContracts(String contractAttachmentId, String sourceContractId, String contractIdList){
        String finalResult = '';
        List<String> contractIds = contractIdList == ''? new List<String>(): contractIdList.split(',');
        List<Contract_Attachment__c> otherCAttachments = new List<Contract_Attachment__c>();
        List<Attachment> otherAttachments = new List<Attachment>();
        Contract_Attachment__c sourceCAttachment = [SELECT id, Name, Contract__c, Description__c, Type_Group__c, Type__c, Status__c, Contract__r.Customer__c, Contract__r.Customer__r.Name FROM Contract_Attachment__c WHERE Id = :contractAttachmentId];
        Attachment sourceAttachment = [SELECT id, body, Name, ParentId  FROM Attachment WHERE ParentId = :contractAttachmentId];
        if(contractIds.size() > 0){
            for(String contractId : contractIds){
                Contract_Attachment__c clonedCAttachment = sourceCAttachment.clone();
                clonedCAttachment.Contract__c = (Id)contractId;
                otherCAttachments.add(clonedCAttachment);
            }
            insert otherCAttachments;
            for(Contract_Attachment__c contractAttachment : otherCAttachments){
                Attachment clonedAttachment = sourceAttachment.clone();
                clonedAttachment.ParentId = contractAttachment.Id;
                otherAttachments.add(clonedAttachment);
            }
            insert otherAttachments;
        }
        finalResult = 'success';
        if(String.isBlank(sourceCAttachment.Contract__r.Customer__c) || String.isBlank(sourceCAttachment.Contract__r.Customer__r.Name)){
            finalResult = FILL_CUSTOMER_MESSAGE;
        }else{
            contractIds.add(sourceContractId);
            System.enqueueJob(new SL_UploadAttachmentQ(contractIds));
            finalResult = 'success';
        }
        return finalResult;
    }

    public PageReference back() {
        return new PageReference('/'+contractRecord.Id);
    }

    public Pagereference success(){
        return new PageReference('/lightning/r/'+ contractRecord.Id + '/related/Contract_Attachments__r/view');
    }
    
    public void sendAttachmentToOnBase() {
    	
        try {
            List<Contract_Attachment__c> lAttachmentList = [select id,Attachment__c,Name, Type__c,
                                                                    Contract__r.Application_Number__c,
                                                                    Contract__r.CCAN__c,
                                                                    Contract__r.Customer__c,
                                                                    Contract__r.Customer__r.Name
                													from Contract_Attachment__c 
                													where Contract__c = :contractRecord.Id 
                													And (Sent_To_OnBase__c = False OR Updated_Rapport__c = False)];
			
			System.Debug('On Base List to process:' + lAttachmentList);

            Boolean isOkToSend = true;
            if (lAttachmentList.Size() == 0) {
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                                                           'No attachment to process'));
                isOkToSend = false;
            }  
            if(isOkToSend && (String.isBlank(lAttachmentList[0].Contract__r.Customer__c) || String.isBlank(lAttachmentList[0].Contract__r.Customer__r.Name))){
                    ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, FILL_CUSTOMER_MESSAGE));
                    isOkToSend = false;
            }
            
            if(isOkToSend){
                SL_OnBaseCallout.sendRapportAttachmentToOnBase(contractRecord.Id,True);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, 'Request submitted!'));
            }

        } catch (Exception e) {
            ApexPages.AddMessages(e);
        }    	
		
    }
    
    
  	static public String sendToOnBaseFromAcc(Id AccountId) {
    String response = '';
    try {
        List<OnBase_Attachment__c> lAttachmentList = [SELECT Id, Account__c, Account__r.Name FROM OnBase_Attachment__c
                                      WHERE Account__c = :AccountId
                                      AND Sent_To_OnBase__c = False];
  
         System.Debug('On Base List to process:' + lAttachmentList);

        Boolean isOkToSend = true;
        if (lAttachmentList.Size() == 0) {
          response = 'No attachment to process';
          isOkToSend = false;
        }  
        if(isOkToSend && String.isBlank(lAttachmentList[0].Account__c)){
          response= FILL_CUSTOMER_MESSAGE;
          isOkToSend = false;
        }
        
        if(isOkToSend){
          SL_OnBaseCallout.sendAttachmentsToOnBase(AccountId);
          response= 'success';
        }

        return response;

    } catch (Exception e) {
      return 'error';
    }    	

  }
}