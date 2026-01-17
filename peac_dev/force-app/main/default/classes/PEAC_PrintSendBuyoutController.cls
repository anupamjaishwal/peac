public class PEAC_PrintSendBuyoutController {
    
    @AuraEnabled
    public static string sendEmail(EmailWrapper emlWrap) {
        if(emlWrap != null) {
            try { 
                List<Task> tskList = new List<Task>();
               // User u = [SELECT Id, Name, Email FROM USer WHERE ID = :userinfo.getUSerID()];
               // PageReference pdf = Page.;
               // pdf.getParameters().put('recId',contractId);
               //Id contractId = ApexPages.currentPage().getRecordId();
                Contract__c contract = [SELECT Id, IsXBS__c,Is_Blind__c, Name, Dealer_Name__r.Name,dealer_name__r.Owner.Email, Dealer_Name__r.Dealer_Number__c FROM Contract__c WHERE Id = :emlWrap.recordId];
                string orgWideAddress;
                if(contract.IsXBS__c) {
                    orgWideAddress = System.label.XFSPrintEmailSendButtonFromAddress;
                } else if(contract.Is_Blind__c) {
                    orgWideAddress = System.label.BlindPrintEmailSendButtonFromAddress;
                } else {
                    orgWideAddress = System.label.NoReplyPrintEmailSendButtonFromAddress;
                }
                
                
                List <OrgWideEmailAddress> noreply = new List <OrgWideEmailAddress> ([SELECT Id, Address, DisplayName from OrgWideEmailAddress WHERE address = :orgWideAddress]);
                
                List<Messaging.EmailFileAttachment> emailAttachments = getEmailAttachment(emlWrap.pdfList);
                List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
				List<string> emailList = emlWrap.emailList.split(',');
                for(string email : emailList) {
                    if(email == null) {
                        continue;
                    }
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail = Messaging.renderStoredEmailTemplate(emlWrap.emailTemplateId,null,emlWrap.recordId);
                    mail.setToAddresses(new String[] {email});
                   // mail.setSubject('Thank you for your request, please find the requested quote for '+contract.Name);
                    //mail.setPlainTextBody('In response to your request, please review the attached buyout figure. This represents the purchase of the leased equipment. This figure does not include the final property taxes, if any, which will be billed separately.');
                    mail.setFileAttachments(emailAttachments);
                    mail.setWhatId(emlWrap.recordId);
                    mail.setUseSignature(false);
                    if ( noreply.size() > 0 ) {
                        mail.setOrgWideEmailAddressId(noreply.get(0).Id);
                    }
                    mailList.add(mail);
                }
                if(mailList.size() > 0) {
                    Messaging.sendEmail(mailList);
                   // insert tskList;
                    attachDocumentOnTask(emailAttachments,emlWrap.recordId);
                    return 'Success';
                }
            } catch(Exception ex) {
                System.debug('PEAC_PrintSendBuyoutController::sendEmail::ErrorMessage::'+ex.getMessage());
            }
        }
        return 'Error';
    }
    
    public static List<Messaging.EmailFileAttachment> getEmailAttachment(List<PDFWrapper> pdfList) {
        List<Messaging.EmailFileAttachment> attachmentList = new List<Messaging.EmailFileAttachment>();
        if(pdfList.size() > 0) {
            for(PDFWrapper pdfWrap : pdfList) {
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                PageReference pdf;
                if(pdfWrap.apexVFPageName == 'SL_PrintBuyout') {
                    pdf = Page.SL_PrintBuyout;
                } else if(pdfWrap.apexVFPageName == 'SL_PrintDetailedBuyout') {
                    pdf = Page.SL_PrintDetailedBuyout;                    
                } else if(pdfWrap.apexVFPageName == 'PEAC_BPCustomerBuyoutLetter') {
                    pdf = Page.PEAC_BPCustomerBuyoutLetter;                    
                }
                for(PDFAttributeWrapper attribute : pdfWrap.pdfAttributeList) {
                    pdf.getParameters().put(attribute.key,attribute.value);
                }
                Blob body;
                if(!Test.isRunningTest()) {
                     body = pdf.getContent();
                } else {
                    body = Blob.valueOf('Test');
                }
                attachment.setContentType('application/pdf');
                attachment.setFileName(pdfWrap.pdfName);
                attachment.setInline(false);
                attachment.Body = body;
                attachmentList.add(attachment);
            }            
        }
        return attachmentList;
    }
    
    public static void attachDocumentOnTask(List<Messaging.EmailFileAttachment> attachmentList, string contractId) {
        try {
            if(attachmentList.size() > 0) {
                List<Contentversion> cvList = new List<ContentVersion>();
                for(Messaging.EmailFileAttachment attach : attachmentList) {
                    
                    ContentVersion cv = new ContentVersion();
                    cv.Title = attach.getFileName();
                    cv.PathOnClient = attach.getFileName();
                    cv.VersionData = attach.Body;
                    cv.IsMajorVersion = true;
                    cvList.add(cv);
                }
                if(cvList.size() > 0) {
                    insert cvList;
                }
                set<Id> contentDocumentIdSet = new set<Id>();
                for(ContentVersion cv : [select ContentDocumentId  from ContentVersion where Id IN :cvList]) {
                    contentDocumentIdSet.add(cv.ContentDocumentId);
                }
                
                List<ContentDocumentLink> cdList = new List<ContentDocumentLink>();
                for(Task tsk : [select Id from Task where Contract__c = :contractId]) {
                    for(string docId : contentDocumentIdSet) {
                        ContentDocumentLink cdl = New ContentDocumentLink();
                        cdl.LinkedEntityId = tsk.Id;
                        cdl.ContentDocumentId = docId;
                        cdl.shareType = 'I'; 
                        cdList.add(cdl);
                    }
                }
                System.debug('cdList::'+cdList);
                if(cdList.size() > 0) {
                    insert cdList;
                }
                
            }
        } catch(Exception ex) {
            System.debug('attachDocumentOnTask::' + ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<EmailTemplate> getEmailTemplates(string recordId) {
        List<EmailTemplate> emailTemplates = new List<EmailTemplate>();
        if(recordId != null) {
            try {
                Contract__c con = [select Id, IsXBS__c from Contract__c where Id = :recordId limit 1];
                string folderName = con.IsXBS__c ? 'XBSDelayedBuyouts' : 'DelayedBuyouts';
                emailTemplates = [SELECT Id, Name, DeveloperName, Subject, HtmlValue, foldername, folderid FROM EmailTemplate WHERE Folder.DeveloperName=:folderName];
            } catch(Exception ex) {
                System.debug('getEmailTemplates::' + ex.getMessage());
            }
        }
        return emailTemplates;
    }
    
    
    public class EmailWrapper {
        @AuraEnabled 
        public string emailList {get; set;}
        @AuraEnabled 
        public string recordId {get; set;}
        @AuraEnabled 
        public string emailTemplateId {get; set;}
        
        @AuraEnabled 
        public List<PDFWrapper> pdfList {get; set;}
        
    }
    
    public class PDFWrapper {
        @AuraEnabled
        public string pdfName {get; set;}
        
        @AuraEnabled
        public string apexVFPageName {get; set;}
        
        @AuraEnabled 
         public List<PDFAttributeWrapper> pdfAttributeList {get; set;}
    }
    
    
    public class PDFAttributeWrapper {
        @AuraEnabled
        public string key {get; set;}
        
        @AuraEnabled 
        public string value {get; set;}
    }

}