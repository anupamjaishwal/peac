public with sharing class SL_DPReportsSchedule implements Schedulable {
    public void execute(SchedulableContext ctx) {
        sendDPReportEmails();
    }

    public static void sendDPReportEmails(){
        List<Messaging.SingleEmailMessage> mailPouch = new List<Messaging.SingleEmailMessage>();
        List <OrgWideEmailAddress> noreply = new List <OrgWideEmailAddress> ([SELECT Id, Address, DisplayName from OrgWideEmailAddress WHERE address = 'noreply@peacsolutions.com']);
        List<EmailTemplate> templateToUse = [SELECT Id, Name, DeveloperName,  FolderName 
            FROM EmailTemplate WHERE Folder.Name = 'Email Notification' AND DeveloperName = 'Service_Passthrough_Notification'];
        Id templateId = null;
        if(templateToUse.size() > 0){
            templateId = templateToUse[0].Id;
            for(Report_Subscription__c subscription : [SELECT Id, Name, User__r.Email, User__r.ContactId, User__r.Contact.Email,
                Report__c, Frequency__c, WeekDay__c, Day__c 
                FROM Report_Subscription__c]){
                String toAddress = subscription.User__r.Email != null? subscription.User__r.Email: subscription.User__r.Contact.Email;
                if(toAddress != null
                    && (subscription.Frequency__c == 'Monthly' && subscription.Day__c == String.valueOf(Date.today().day()))
                    || (subscription.Frequency__c == 'Weekly' && subscription.WeekDay__c == Datetime.now().format('EEEE'))
                    || subscription.Frequency__c == 'Daily'){
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setTemplateId(templateId);
                    mail.setWhatId(subscription.Id);
                    mail.setTargetObjectId(subscription.User__r.ContactId);
                    mail.setToAddresses(new String[] {toAddress});
                    if(noreply.size() > 0){
                        mail.setOrgWideEmailAddressId(noreply[0].Id);
                    }
                    mail.saveAsActivity = false;
                    mailPouch.add(mail);
                }
            }
        }
        if(mailPouch.size() > 0 && !Test.isRunningTest()){
            Messaging.sendEmail(mailPouch);
        }
    }
}