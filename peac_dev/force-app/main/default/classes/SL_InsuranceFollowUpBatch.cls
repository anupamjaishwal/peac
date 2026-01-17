public with sharing class SL_InsuranceFollowUpBatch implements Database.Batchable<SObject>, Database.Stateful {
    Map<Id, EmailTemplate> templates;
    Map<Id, User> allUsers;
    
    public SL_InsuranceFollowUpBatch(){
        templates = new Map<Id, EmailTemplate>();
        templates.putAll([SELECT Id, Subject, DeveloperName, HtmlValue FROM EmailTemplate WHERE DeveloperName LIKE 'X%_day_Insurance_Follow_Up']);
        allUsers = new Map<Id, User>();
        allUsers.putAll([SELECT Id, Email FROM User WHERE Email != null AND IsActive = true]);
    }

    public Database.querylocator start(Database.BatchableContext BC){
        return Database.getQueryLocator('SELECT CaseNumber, Subject, OwnerId, CreatedDate '
            +'FROM Case '
            +'WHERE Type = \'Insurance - Follow-up\' AND Status != \'Closed\'');
   }
   public void execute(Database.BatchableContext BC, List<SObject> scope){
        List<Messaging.SingleEmailMessage> toSend = new List<Messaging.SingleEmailMessage>();
        for(sObject s : scope){
            Case insuranceCase = (Case)s;
            Boolean sendIt = false;
            String daysPassed = '';
            String dateOnly = Date.valueOf(insuranceCase.CreatedDate).format();
            if(dateOnly == (Date.Today() - 14).format()){
                sendIt = true;
                daysPassed = '14';
            } else {
                if(dateOnly == (Date.Today() - 30).format()){
                    sendIt = true;
                    daysPassed = '30';
                }
            }
            if(sendIt && insuranceCase.OwnerId.getSObjectType().getDescribe().getName() == 'User'){
                Messaging.SingleEmailMessage thisEmail = new Messaging.SingleEmailMessage();
                EmailTemplate templateToUse = new EmailTemplate();
                for (Id keyId : templates.keySet()){
                    EmailTemplate template = templates.get(keyId);
                    if(template.DeveloperName == 'X' + daysPassed + '_day_Insurance_Follow_Up'){
                        templateToUse = template;
                        break;
                    }
                }
                List<Messaging.RenderEmailTemplateBodyResult> mergedTemplate = 
                    Messaging.renderEmailTemplate(insuranceCase.OwnerId, insuranceCase.Id,
                        new List<String> {templateToUse.Subject, 
                                templateToUse.HtmlValue});
                thisEmail.setSubject(mergedTemplate[0].getMergedBody());
                thisEmail.setHtmlBody(mergedTemplate[1].getMergedBody());
                thisEmail.setSaveAsActivity(false);
                thisEmail.setToAddresses(new List<String>{allUsers.get(insuranceCase.OwnerId).Email});
                toSend.add(thisEmail);
            }

       }
       if(toSend.size() > 0){
           Messaging.sendEmail(toSend);
       }

   }
   public void finish(Database.BatchableContext BC){}
}