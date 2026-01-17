public class UploadAttachment {
    public String selectedType {get;set;}
    public Boolean selectedAwesomeness {get;set;}
    public String description {get;set;}
    private Opportunity oppty {get;set;} 
    public String fileName {get;set;}
    public Blob fileBody {get;set;}
    public String responseMessage {get;set;}
    Public String lParentId = '';
    
    public UploadAttachment(ApexPages.StandardController controller) { 
        this.oppty = (Opportunity)controller.getRecord();
    }   
    
    // creates a new Contact_Attachment__c record
    private Database.SaveResult saveCustomAttachment() {
        Opportunity_Attachment__c obj = new Opportunity_Attachment__c();
        obj.Opportunity__c = oppty.Id; 
       	obj.Description__c = description;
        obj.type__c = selectedType;
        return Database.insert(obj);
    }
    
    // create an actual Attachment record with the Contact_Attachment__c as parent
    @TestVisible private Database.SaveResult saveStandardAttachment(Id parentId) {
        Database.SaveResult result;
        
        Attachment attachment = new Attachment();
        attachment.body = this.fileBody;
        attachment.name = this.fileName;
        attachment.parentId = parentId;
        // inser the attahcment
        result = Database.insert(attachment);
        // reset the file for the view state
        fileBody = Blob.valueOf(' ');
        return result;
    }
    
    /**
* Upload process is:
*  1. Insert new Contact_Attachment__c record
*  2. Insert new Attachment with the new Contact_Attachment__c record as parent
*  3. Update the Contact_Attachment__c record with the ID of the new Attachment
**/
    public PageReference processUpload() {
        try {
        	
            if (String.IsBlank(this.fileName)) {
            	
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select a file to attach')); return null;
            }
                    	
            Database.SaveResult customAttachmentResult = saveCustomAttachment();
            
            if (customAttachmentResult == null || !customAttachmentResult.isSuccess()) {ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Could not save attachment.'));return null;
            }
            
            lParentId = customAttachmentResult.getId();
            
            Database.SaveResult attachmentResult = saveStandardAttachment(customAttachmentResult.getId());
            
            if (attachmentResult == null || !attachmentResult.isSuccess()) {ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Could not save attachment.')); return null;
            } else {
                // update the custom attachment record with some attachment info
                Opportunity_Attachment__c customAttachment = [select id from Opportunity_Attachment__c where id = :customAttachmentResult.getId()];
                customAttachment.name = this.fileName;
                customAttachment.Attachment__c = attachmentResult.getId();
                update customAttachment;

                // MARLIN_OnBaseCallout.sendDocToOnbase(attachmentResult.getId());
                // sendAttachmentToOcrolus(customAttachment.Id);
            }
            
        } catch (Exception e) {
            fileBody = null;
            fileName = null;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.FATAL, e.getMessage()));
            return null;
        }
 
        return new PageReference('/lightning/r/'+ oppty.Id + '/related/Attachments__r/view');
    }
    
    public PageReference back() {
        return new PageReference('/'+oppty.Id);
    }

    /*
    public void dragNDropFileSet () {
    }*/

    public List<SelectOption> getDocumentTypes() {
        List<SelectOption> options = new List<SelectOption>();
        String recordTypeName = '';

        List<Opportunity> lOppty = [SELECT Id, RecordType.DeveloperName, Loan_Record_Type__c FROM Opportunity WHERE Id = :oppty.Id];

        if (lOppty.size() == 1) {
            recordTypeName = lOppty[0].RecordType.DeveloperName;
        }

        Schema.DescribeFieldResult fieldResult = Opportunity_Attachment__c.Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry f : ple) {

            if (lOppty[0].Loan_Record_Type__c && f.getLabel().startsWith('FS - ')) {
                options.add(new SelectOption(f.getLabel(), f.getValue()));
            } else if (!lOppty[0].Loan_Record_Type__c && f.getLabel().startsWith('LC - ')) {
                options.add(new SelectOption(f.getLabel(), f.getValue()));
            }
        }
        return options;
    }
		
    public void sendAttachmentToOnBase() {
    	
        try {
                List<Opportunity_Attachment__c> lAttachmentList = [select id,Attachment__c,Name,Opportunity__r.Application__c,
                													Opportunity__r.CaseCenter__c,Opportunity__r.RECORDTYPE.DEVELOPERNAME,
                                                                    Opportunity__r.Loan_Record_Type__c
                													from Opportunity_Attachment__c 
                													where Opportunity__c = :oppty.Id 
                													And (Sent_To_OnBase__c = False OR Updated_Rapport__c = False)];
			
			System.Debug('On Base List to process:' + lAttachmentList);

            List<Id> onbaseIds = new List<Id>();
            List<Id> attachmentIds = new List<Id>();
            List<Id> bigAttachmentIds = new List<Id>();
            List<Id> onbaseIdsFiltered = new List<Id>();

            for(Opportunity_Attachment__c oppAtt :lAttachmentList){
                onbaseIds.add(oppAtt.Id);
            }

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

            

            if (lAttachmentList.Size() == 0) {
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                                                           'No attachment to process'));
            }  

            //else if(lAttachmentList[0].Opportunity__r.RECORDTYPE.DEVELOPERNAME != 'Funding_Stream_Opportunity' 
            else if(!lAttachmentList[0].Opportunity__r.Loan_Record_Type__c && String.IsBlank(lAttachmentList[0].Opportunity__r.Application__c)){ ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '“Send to Onbase” is allowed once the Application has been submitted'));           	
            }  

            //else if(lAttachmentList[0].Opportunity__r.RECORDTYPE.DEVELOPERNAME == 'Funding_Stream_Opportunity' 
            else if(lAttachmentList[0].Opportunity__r.Loan_Record_Type__c && String.IsBlank(lAttachmentList[0].Opportunity__r.CaseCenter__c)){ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '“Send to Onbase” is allowed once the Application has been submitted'));           	
            }             
            else{
            		//if(lAttachmentList[0].Opportunity__r.RECORDTYPE.DEVELOPERNAME == 'Funding_Stream_Opportunity') 
                if(lAttachmentList[0].Opportunity__r.Loan_Record_Type__c) {
                    if(bigAttachmentIds.size()>0)
                    {                        
                        SL_OnBaseCallout.sendOnbaseAttachemntToHCL(oppty.Id, bigAttachmentIds);
                    }
                    if(onbaseIdsFiltered.size()>0){
                        MARLIN_OnBaseCalloutForCC.sendCCAttachmentToOnBase(oppty.Id,True, onbaseIdsFiltered);
                    }
                } 
                else{
                    if(bigAttachmentIds.size()>0)
                    {                        
                        SL_OnBaseCallout.sendOnbaseAttachemntToHCL(oppty.Id, bigAttachmentIds);
                    }
                    if(attachmentIds.size()>0)
                    {
                        MARLIN_OnBaseCallout.sendRapportAttachmentToOnBase(oppty.Id,True, attachmentIds);
                    }


                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, 'Request submitted!'));}
            }

        } catch (Exception e) {ApexPages.AddMessages(e);
        }    	
	//	return new PageReference('/'+oppty.Id);
		
    }

    public void sendAttachmentToOcrolus() {

        //TC_OcrolusCtrl.processOcrolusAttachmentList(oppty.Id);
        // tam add ocrolus
        // // platform event 10-9-2019
        System.debug('::::: works');

        EventBus.publish (new TC_Ocrolus_Add_Book__e (Opportunity_Id__c = oppty.Id));
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, 'Check Integration Logs to confirm if attachments were uploaded to Ocrolus.'));

    }

    public void sendAttachmentToOcrolusOnbase() {
        sendAttachmentToOcrolus();
        sendAttachmentToOnBase();
    }

    public class OcrolusException extends Exception {}

    @AuraEnabled
    public static List<Map<String,String>> getDocumentTypesLWC(Id oppId) {
        List<SelectOption> options = new List<SelectOption>();
        String recordTypeName = '';
        List<Map<String,String>> selectOpt = new List<Map<String,String>>();


        List<Opportunity> lOppty = [SELECT Id, RecordType.DeveloperName, Loan_Record_Type__c FROM Opportunity WHERE Id = :oppId];

        if (lOppty.size() == 1) {
            recordTypeName = lOppty[0].RecordType.DeveloperName;
        }

        Schema.DescribeFieldResult fieldResult = Opportunity_Attachment__c.Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry f : ple) {

            if (lOppty[0].Loan_Record_Type__c && f.getLabel().startsWith('FS - ')) {
                //options.add(new SelectOption(f.getLabel(), f.getValue()));
                selectOpt.add(new Map<String, String>{'value' => f.getValue(), 'label' => f.getLabel()});
            } else if (!lOppty[0].Loan_Record_Type__c && f.getLabel().startsWith('LC - ')) {
                //options.add(new SelectOption(f.getLabel(), f.getValue()));
                selectOpt.add(new Map<String, String>{'value' => f.getValue(), 'label' => f.getLabel()});
            }
        }
        System.debug(' ::: selectOpt ::: ' + selectOpt);
        //return options;
        return selectOpt;
    }
    
	
}