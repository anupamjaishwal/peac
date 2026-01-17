public with sharing class SL_SendDelayedEmailSchedule implements Schedulable, Database.Stateful{
    Boolean isTest;

    public SL_SendDelayedEmailSchedule(Boolean isTest) {
        this.isTest = isTest;

    }

    public void execute(SchedulableContext ctx) {

        Set<String> fromAddresses = new Set<String>();
        Set<String> attachmentIds = new Set<String>();
        List<EmailMessage> emailsToSend = new List<EmailMessage>();

        if(isTest){
            emailsToSend = [SELECT Id, EmailTemplateId, TextBody, HTMLBody, ToAddress, FromAddress, RelatedToId, CreatedById, CreatedBy.Email, CreatedBy.Name, Scheduled_Contact_ID__c, (SELECT ID, Name FROM Attachments)   FROM EmailMessage WHERE Scheduled__c = true AND Status='5'];

        }
        else{
            emailsToSend = [SELECT Id, EmailTemplateId, TextBody,HTMLBody, ToAddress, FromAddress, RelatedToId, CreatedById, CreatedBy.Email, CreatedBy.Name, Scheduled_Contact_ID__c, (SELECT ID, Name FROM Attachments)   FROM EmailMessage WHERE Scheduled__c = true AND Status='5' AND MessageDate = TODAY];
        }
        System.debug('emailsToSend ' + emailsToSend);
        
        for (EmailMessage email : emailsToSend) {
            fromAddresses.add(email.FromAddress);
            attachmentIds.add(email.Attachments[0].Id);
        }

        Map<String, OrgWideEmailAddress> orgWideAddresses = new Map<String, OrgWideEmailAddress>();        
        for(OrgWideEmailAddress owea : [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address IN :fromAddresses]){
            orgWideAddresses.put(owea.Address, owea);
        }


        Map<Id, Attachment> attachmentsMap = new Map<Id, Attachment>();        
        for(Attachment att : [SELECT Id, Name, Body, ParentId FROM Attachment WHERE ID IN :attachmentIds]){
            attachmentsMap.put(att.ParentId, att);
        }

        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();

        for (EmailMessage email : emailsToSend) {

            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setPlainTextBody(email.TextBody);
            message.setHTMLBody(email.HTMLBody);


            if(email.FromAddress == email.CreatedBy.Email || Test.isRunningTest()){
                message.setReplyTo(email.FromAddress);
                message.setSenderDisplayName(email.CreatedBy.Name);
            }else{
                Id oweaId = orgWideAddresses.get(email.fromAddress).Id;
                message.setOrgWideEmailAddressId(oweaId);
            }
            message.setToAddresses(new String[]{email.toAddress});    

            List<Messaging.EmailFileAttachment> fileAttachments = new List<Messaging.EmailFileAttachment>();

            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName(attachmentsMap.get(email.Id).Name);
            efa.setBody(attachmentsMap.get(email.Id).Body);
            fileAttachments.add(efa);

            message.setFileAttachments(fileAttachments);
            
            // Add the email to the list
            emailMessages.add(message);
            
            // Update the status of the email to 'Sent' after processing
            email.Status = '3';
        
        }
        // Send the emails
        if (!emailMessages.isEmpty()) {
            try {
                Messaging.SendEmailResult[] resultMail = Messaging.sendEmail(emailMessages, false);

                for (Messaging.SendEmailResult mr : resultMail) 
                {
                    if (mr.isSuccess()) {
                        //Do something for success
                    }  else {
                        // Operation failed, so get all errors                
                        for(Messaging.SendEmailError err : mr.getErrors()) {
                            System.debug('The following error has occurred.');                    
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('fields that affected this error: ' + err.getFields());
                        }
                    }
                }
            } catch (System.EmailException ex) {
                system.debug('============== email exception caught!!!=============');
            }        
        }

        // Update the EmailMessage records to reflect that the emails have been sent
        update emailsToSend;
    
        }    
    }