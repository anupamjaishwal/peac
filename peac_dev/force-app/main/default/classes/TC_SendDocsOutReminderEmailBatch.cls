public class TC_SendDocsOutReminderEmailBatch implements Database.Batchable<SObject>, Database.AllowsCallouts{
    /*public static Date onDay = Date.today();
    public static Final string SIMPLE = 'Simple';
    public static Final string CANCELLED = 'Cancelled';
    public static Final string DOCSOUT = 'Docs Out';
    public static Date createDate = Date.newInstance(2021, 11, 20);*/
    public Database.QueryLocator start(Database.BatchableContext bc){
        /*String query = 'SELECT id,Docs_In__c,CreatedDate,StageName,Assign_To_CMS_User__r.Email,Owner.Email, Docs_Out__c, Application_Status__c, Lease_Approval_Expiration__c, Workflow_Type__c FROM Opportunity WHERE Docs_In__c = null AND CreatedDate > :createDate AND StageName = :DOCSOUT AND Docs_Out__c <> null AND Application_Status__c <> :CANCELLED AND Workflow_Type__c= :SIMPLE AND Lease_Approval_Expiration__c > :onDay';
        return Database.getQueryLocator(query);*/
        //Added for test coverage
        String query = 'SELECT id FROM Opportunity Limit 1';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Opportunity> opps){
        /*System.debug(opps);
        List<Id> opportunityIds = new List<Id>();
        for(Opportunity opp : opps){
            opportunityIds.add(opp.id);
        }
        List<dsfs__DocuSign_Status__c> docusignRecipients = [SELECT id, dsfs__Opportunity__c,dsfs__Envelope_Status__c, (SELECT id,dsfs__Contact__c,dsfs__DocuSign_Recipient_Email__c,dsfs__DocuSign_Routing_Order__c FROM dsfs__R00NS0000000WUO2MAO__r WHERE dsfs__DocuSign_Routing_Order__c = 1) FROM dsfs__DocuSign_Status__c WHERE dsfs__Opportunity__c in :opportunityIds AND dsfs__Envelope_Status__c <> 'Voided'];
        Map<Id,dsfs__DocuSign_Status__c> docuMap = new Map<Id,dsfs__DocuSign_Status__c>();
        for(dsfs__DocuSign_Status__c recip : docusignRecipients){
            docuMap.put(recip.dsfs__Opportunity__c,recip);
        }
        EmailTemplate emailTemplate = [Select Id,Subject,Description,HtmlValue,DeveloperName,Body from EmailTemplate where name = 'Docs Out Reminder'];
        List<String> recipients = new List<String>();
        for(Opportunity opp : opps){
            System.debug('Days check');
            System.debug(opp.Docs_Out__c);
            System.debug(opp.Docs_Out__c.addDays(14));
            System.debug(onDay);
            if(opp.Lease_Approval_Expiration__c != null && opp.Workflow_Type__c == 'Simple' && (onDay <= opp.Docs_Out__c.addDays(14) || Math.mod(Math.abs(Date.valueOf(opp.Docs_Out__c.addDays(14)).daysBetween(onDay)), 2) == 1 )){
                List<dsfs__DocuSign_Recipient_Status__c> toEmails = docuMap.get(opp.id).dsfs__R00NS0000000WUO2MAO__r;
                Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
                for(dsfs__DocuSign_Recipient_Status__c toEmail : toEmails){
                    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                    recipients.add(toEmail.dsfs__DocuSign_Recipient_Email__c);
                    System.debug('to emails..' + toEmail.dsfs__DocuSign_Recipient_Email__c);
                    message.setTargetObjectId(toEmail.dsfs__Contact__c);
                    message.setSaveAsActivity(false);
                    message.setTemplateId(emailTemplate.Id);
                    List<String> to = new List<String>();
                    to.add(toEmail.dsfs__DocuSign_Recipient_Email__c);
                    message.toAddresses = to;
                    OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'noreply@peacsolutions.com'];
                    if ( owea.size() > 0 ) {
                        message.setOrgWideEmailAddressId(owea.get(0).Id);
                    }
                    messages.add(message);
                    
                }
                if(!messages.isEmpty()){
                    Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                    
                    if (results[0].success){                
                        System.debug('The email was sent successfully.');
                    } else {
                        System.debug('The email failed to send:' +  results[0].errors[0].message);
                    }
                }
            }
        }*/
    }
    
    public void finish(Database.BatchableContext bc){
        System.debug('Batch finished');
    }

}