public with sharing class SL_AccountTriggerEmailsQ implements Queueable {
    List<Id> accountsToEmail;
    String emailType;

    public SL_AccountTriggerEmailsQ(List<Id> accountsToEmail, String emailType) {
        this.accountsToEmail = accountsToEmail;
        this.emailType = emailType;
    }
    

    public void execute(QueueableContext context) {
        system.debug('this.emailType:'+this.emailType);
        switch on this.emailType {
            when 'IF_Decision_Status_Updated'{
                List<Messaging.SingleEmailMessage> mailPouch = new List<Messaging.SingleEmailMessage>();
                sendEmailToIFCredit(mailPouch, this.accountsToEmail, false);
                system.debug(mailPouch+'   mailPouch:'+mailPouch.size());
                Messaging.sendEmail(mailPouch);
            }
        }
    }

    public static void sendEmailToIFCredit(List<Messaging.SingleEmailMessage> mailPouch, List<Id> accountIds, Boolean isSubmitted){
        
        List <OrgWideEmailAddress> noreply = new List <OrgWideEmailAddress> ([SELECT Id, Address, DisplayName from OrgWideEmailAddress WHERE address = 'noreply@peacsolutions.com']);
        
        Map<String, String> templatesByIFStatus = new Map<String, String>{'Approved' => 'IF_Approved', 'Rejected' => 'IF_Rejected',
            'More Information' => 'IF_More_Info'};
        MAp<String, EmailTemplate> EmailTemplateMAp = new Map<String, EmailTemplate>();
        for(EmailTemplate et : [SELECT Id, Name, DeveloperName,  FolderName, Subject
            FROM EmailTemplate WHERE Folder.Name = 'Email Notification' AND (DeveloperName = :templatesByIFStatus.values() OR DeveloperName = 'IF_Decision_Status_Updated')]){
            EmailTemplateMAp.put(et.DeveloperName, et);
        }
            
        for(Account targetAccount :[SELECT Id, Name, OwnerId, Dealer_Number__c, toLabel(IF_Decision_Status__c),
        (SELECT Id, Contact.Email, ContactId, Roles FROM AccountContactRelations WHERE Roles = 'Primary Contact') FROM Account 
                WHERE Id IN :accountIds]){
            
            List<AccountContactRelation> primaryContact = targetAccount.AccountContactRelations;
            system.debug('primaryContact[0].Contact.Email:'+primaryContact);
          //  if(primaryContact.size() > 0 && String.isNotBlank(primaryContact[0].Contact.Email)){
                
                String templateDevName = isSubmitted? 'IF_Decision_Status_Updated': templatesByIFStatus.get(targetAccount.IF_Decision_Status__c);
                EmailTemplate et = EmailTemplateMAp.get(templateDevName);
                List<String> emailBodyList = new List<String>();
                emailBodyList.add(et.Subject);
                
                Messaging.SingleEmailMessage renderStoredEmailTemplate = Messaging.renderStoredEmailTemplate(et.Id, primaryContact[0].ContactId, targetAccount.Id);
                List<Messaging.RenderEmailTemplateBodyResult> renderEmailTemplate = Messaging.renderEmailTemplate(primaryContact[0].ContactId, targetAccount.Id, emailBodyList);
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                /*mail.setTemplateId(templateId);
                mail.setWhatId(targetAccount.Id);
                mail.setTargetObjectId(primaryContact[0].ContactId);
                mail.setToAddresses(new String[] {primaryContact[0].Contact.Email});
                mail.setToAddresses(new String[] {'ifcredit@peacsolutions.com', 'ifsales@peacsolutions.com'});
                if(noreply.size() > 0){
                    mail.setOrgWideEmailAddressId(noreply[0].Id);
                }*/
                List<String> ccAddresses = new List<String>{'ifcredit@peacsolutions.com', 'ifsales@peacsolutions.com', 'sakuthota@peacsolutions.com'};
                mail = CustomSendMailUtil.SetCustomSingleEmail(
                                    ccAddresses,
                                    renderEmailTemplate[0].getMergedBody(),
                                    null,//(emailTemplateList[0].HtmlValue == null ? renderEmailTemplate[1].getMergedBody() : ''), 
                                    renderStoredEmailTemplate.getHTMLBody(),//(emailTemplateList[0].HtmlValue != null? renderEmailTemplate[1].getMergedBody() : ''),
                                    noreply[0].id
                                 );
                                 system.debug('mail:'+mail);
               // List<String> ccAddresses = new List<String>{'ifcredit@peacsolutions.com', 'ifsales@peacsolutions.com'};
                // need to remove the below lines once I confirm it is working
                // ccAddresses.add('misael.romero@silverlinecrm.com');
                // ccAddresses.add('sara.martinez@silverlinecrm.com');
                // ccAddresses.add('BRay@peacsolutions.com');
                // ccAddresses.add('SAkuthota@peacsolutions.com');
               // mail.setCcAddresses(ccAddresses);
                //mail.saveAsActivity = false;
                mailPouch.add(mail);
           // }
            
        }
    }
}