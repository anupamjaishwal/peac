//SAL-3220

public class TC_SendScheduleEmailsBatch implements Database.Batchable<SObject>, Database.AllowsCallouts{
    /*public static Date sevenDays = Date.today().addDays(7);
    public static Date eightDays = sevenDays.addDays(1);
    public static Final string SIMPLE = 'Simple';
    public static Final string DOCSOUT = 'Docs Out';*/
    public Database.QueryLocator start(Database.BatchableContext bc){
        /*System.debug('Date Test' + sevenDays);
        String query = 'SELECT id,StageName,Assign_To_CMS_User__r.Email,Owner.Email, Lease_Approval_Expiration__c, Workflow_Type__c, (SELECT email__c,Contact__c FROM Signer_Portal_Status__r) FROM Opportunity WHERE StageName = :DOCSOUT AND Lease_Approval_Expiration__c >= :sevenDays AND Lease_Approval_Expiration__c <= :eightDays AND Workflow_Type__c= :SIMPLE';
        return Database.getQueryLocator(query);*/
        String query = 'SELECT id FROM Opportunity Limit 1';
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext bc, List<Opportunity> opps){
        /*System.debug(opps);
        EmailTemplate emailTemplate = [Select Id,Subject,Description,HtmlValue,DeveloperName,Body from EmailTemplate where name = 'Before Approval Expiration'];
        Map<Id,List<Signer_Portal_Status__c>> toAddr = new Map<Id,List<Signer_Portal_Status__c>>();
        Map<Id,String> fromCms = new Map<Id,String>();
        Map<Id,String> fromOwner = new Map<Id,String>();
        List<String> recipients = new List<String>();
        List<Id> targets = new List<Id>();
        Map<Id,List<Signer_Portal_Status__c>> setTarget = new Map<Id,List<Signer_Portal_Status__c>>();
        for(Opportunity op : opps){
            toAddr.put(op.id,op.Signer_Portal_Status__r);
            fromCms.put(op.id,op.Assign_To_CMS_User__r.Email);
            fromOwner.put(op.id,op.Owner.Email);
            setTarget.put(op.id,op.Signer_Portal_Status__r);
        }
        for(Opportunity opp : opps){
            if(opp.Lease_Approval_Expiration__c != null && opp.Workflow_Type__c == 'Simple'){
                List<Signer_Portal_Status__c> toEmails = opp.Signer_Portal_Status__r;
                Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
                for(Signer_Portal_Status__c toEmail : toEmails){
                    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                    recipients.add(toEmail.email__c);
                    System.debug('to emails..' + toEmail.email__c);
                    message.setTargetObjectId(toEmail.Contact__c);
                    message.setSaveAsActivity(false);
                    message.setTemplateId(emailTemplate.Id);
                    List<String> to = new List<String>();
                    to.add(toEmail.Email__c);
                    message.toAddresses = to;
                    OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'noreply@peacsolutions.com'];
                    if ( owea.size() > 0 ) {
                        message.setOrgWideEmailAddressId(owea.get(0).Id);
                    }
                    /*if(opp.Assign_To_CMS_User__c == null){
                        message.setReplyTo(opp.Owner.Email);
                    }
                    else{
                        message.setReplyTo(opp.Assign_To_CMS_User__r.Email);
                    }*/
                 /*   messages.add(message);
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