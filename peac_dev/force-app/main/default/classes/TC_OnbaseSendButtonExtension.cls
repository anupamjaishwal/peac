/** 
 * @description Extension class for page OnBaseSendButton
 * Created by: Trohweder 6/30/21
 * SAL-3037
 */
public with sharing class TC_OnbaseSendButtonExtension {
    /**
     * @description selected used to populate with all selected Opportunity_Attachment__c objects in the list view
     */
    public List<Opportunity_Attachment__c> selected { get; private set; }
    /**
     * @description used to store parent opportunity Id
     */
    public Id oppId{ get; private set; }
    /**
     * @description list to be populated with selected Opportunity_Attachment__c Ids to be sent to OnBase integration
     */
    public List<Id> onbaseIds{ get; private set; }

    
    /** 
     * @description on button click gets selected Opportunity_Attachment__c objects
     * @param controller Standar controller for Opportunity_Attachment__c object recieved from page
     * Created by: Trohweder 6/30/21
     * SAL-3037
     */
    public TC_OnbaseSendButtonExtension(ApexPages.StandardSetController controller)
    {
        selected = controller.getSelected();
        oppId = ApexPages.currentPage().getParameters().get('id');
        onbaseIds = new List<String>();
        if(selected.size() > 0){
            for(Opportunity_Attachment__c attachment : selected){
                onbaseIds.add(attachment.Id);                
            }
        }
    }

    /** 
     * @description on button click navigates back to parent opportunity
     * Created by: Trohweder 6/30/21
     * SAL-3037
     */
    public PageReference back() {
        return new PageReference('/'+oppId);
    }

    /** 
     * @description sends selected Opportunity_Attachment__c objects to OnBase Integration callout
     * Created by: Trohweder 6/30/21
     * SAL-3037
     */
    public void sendAttachmentToOnBase() {
    	
        try {

            Opportunity oppt = [SELECT Id,Loan_Record_Type__c, Application__c, CaseCenter__c FROM Opportunity WHERE Id=:oppId];

            List<Id> attachmentIds = new List<Id>();
            List<Id> bigAttachmentIds = new List<Id>();
            List<Id> onbaseIdsFiltered = new List<Id>();

            for (Attachment att : [SELECT ID,Name, BodyLength, ParentId, CreatedDate FROM Attachment WHERE ParentId IN :onbaseIds])
            {
                if (att.BodyLength < 7000000) {
                    attachmentIds.add(att.ParentId);
                    onbaseIdsFiltered.add(att.ParentId);
                }
                else{
                    bigAttachmentIds.add(att.ParentId);

                }
            }

            if (selected.Size() == 0) {
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                                                           'No attachment to process'));
            }  

            //else if(lAttachmentList[0].Opportunity__r.RECORDTYPE.DEVELOPERNAME != 'Funding_Stream_Opportunity' 
            else if(!oppt.Loan_Record_Type__c && String.IsBlank(oppt.Application__c)){ ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '“Send to Onbase” is allowed once the Application has been submitted'));           	
            }  

            //else if(lAttachmentList[0].Opportunity__r.RECORDTYPE.DEVELOPERNAME == 'Funding_Stream_Opportunity' 
            else if(oppt.Loan_Record_Type__c && String.IsBlank(oppt.CaseCenter__c)){ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '“Send to Onbase” is allowed once the Application has been submitted'));           	
            }             
            else{
            		//if(lAttachmentList[0].Opportunity__r.RECORDTYPE.DEVELOPERNAME == 'Funding_Stream_Opportunity') 
                if(oppt.Loan_Record_Type__c) {
                    if(bigAttachmentIds.size()>0)
                    {                        
                        SL_OnBaseCallout.sendOnbaseAttachemntToHCL(oppt.Id, bigAttachmentIds);
                    }
                    if(onbaseIdsFiltered.size()>0){
                        MARLIN_OnBaseCalloutForCC.sendCCAttachmentToOnBase(oppt.Id,True, onbaseIdsFiltered);
                    }
                } 
                else{
                    if(bigAttachmentIds.size()>0)
                    {                        
                        SL_OnBaseCallout.sendOnbaseAttachemntToHCL(oppt.Id, bigAttachmentIds);
                    }
                    if(attachmentIds.size()>0)
                    {
                        MARLIN_OnBaseCallout.sendRapportAttachmentToOnBase(oppt.Id,True, attachmentIds);
                    }
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, 'Request submitted!'));
                }
            }

        } catch (Exception e) {ApexPages.AddMessages(e);
        }    	
    }
}