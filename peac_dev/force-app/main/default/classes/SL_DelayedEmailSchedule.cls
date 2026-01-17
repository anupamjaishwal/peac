public with sharing class SL_DelayedEmailSchedule implements Schedulable, Database.Stateful {
    String fromAddress;
    String toAddress;
    String contactId;
    String templateId;
    String recordId;
    String fileName;
    String fileBody;

    public SL_DelayedEmailSchedule(String fromAddress, String toAddress, String contactId, String templateId, String recordId,
    String fileName, String fileBody){
        this.fromAddress = fromAddress;
        this.toAddress = toAddress;
        this.contactId = contactId;
        this.templateId = templateId;
        this.recordId = recordId;
        this.fileName = fileName;
        this.fileBody = fileBody;
    }

    public void execute(SchedulableContext ctx) {
        CronTrigger job = [SELECT Id, CreatedById FROM CronTrigger WHERE Id =:ctx.getTriggerId()];
        User sender = [SELECT Id, Name, Email FROM User WHERE Id =:job.CreatedById];
        Contract__c contract = [SELECT Id, Name FROM Contract__c WHERE Id = :recordId];
        Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(templateId, contactId, String.valueOf(contract.Id));
        message.setWhatId(recordId);
        if(fromAddress == sender.Email){
            message.setReplyTo(fromAddress);
            message.setSenderDisplayName(sender.Name);
        }else{
            Id oweaId = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :fromAddress][0].Id;
            message.setOrgWideEmailAddressId(oweaId);
        }
        message.setToAddresses(new String[]{toAddress});

        // the below is for classic email templates
        // List<EmailTemplate> templates = [SELECT Id, Subject, DeveloperName, HtmlValue FROM EmailTemplate WHERE Id = :templateId];
        // if(templates.size() == 1){
        //     List<Messaging.RenderEmailTemplateBodyResult> mergedTemplate = 
        //             Messaging.renderEmailTemplate(contactId, contract.Id,
        //                 new List<String> {templates[0].Subject, 
        //                     templates[0].HtmlValue});
        //     message.setSubject(mergedTemplate[0].getMergedBody());
        //     message.setPlainTextBody(mergedTemplate[1].getMergedBody()); mergedTemplate[1]
        // }
        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setFileName(fileName);
        efa.setBody(EncodingUtil.base64Decode(EncodingUtil.urlDecode(fileBody, 'UTF-8')));
        message.setFileAttachments(new List<Messaging.EmailFileAttachment>{efa});
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{message});
    }
}