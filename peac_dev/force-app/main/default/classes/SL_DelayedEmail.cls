public with sharing class SL_DelayedEmail {
    @AuraEnabled
    public static string hubExecute(String methodName, List<String> methodParameters){
        try {
            String result = '';
            switch on methodName {
                when 'getOWEmailAddresses'{
                    result = getOWEmailAddresses(methodParameters[0]);
                }
                when 'getToAddress'{
                    result = getToAddress(methodParameters[0]);
                }
                when 'scheduleDelivery'{
                    result = scheduleDelivery(methodParameters[0], methodParameters[1],
                        methodParameters[2], methodParameters[3], methodParameters[4], methodParameters[5], methodParameters[6]);
                }
                when 'getScheduledQBs'{
                    result = getScheduledQBs(methodParameters[0]);
                }
                when 'cancelScheduledQB'{
                    result = cancelScheduledQB(methodParameters[0], methodParameters[1]);
                }
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

@testVisible
static String getOWEmailAddresses(String recordId){

    
    List<OrgWideEmailAddress> oWEA = [
        SELECT Id, Address, DisplayName, IsAllowAllProfiles, Purpose
        FROM OrgWideEmailAddress
        WHERE Purpose='UserSelection'
    ];
    
    List<OrgWideEmailAddress> finalList = new List<OrgWideEmailAddress>();
    finalList.add(new OrgWideEmailAddress(
        Address = UserInfo.getUserEmail(),
        DisplayName = UserInfo.getName()
    ));

    List<Messaging.SingleEmailMessage> toValidate = new List<Messaging.SingleEmailMessage>();
    List<EmailMessage> validateTrigger = new List<EmailMessage>();
    List<Messaging.SendEmailResult> validationResults;
    List<Database.SaveResult> triggerResults;

    for(OrgWideEmailAddress oneAddress : oWEA){
        Messaging.SingleEmailMessage fakeMessage = new Messaging.SingleEmailMessage();
        fakeMessage.setOrgWideEmailAddressId(oneAddress.Id);
        fakeMessage.setToAddresses(new List<String>{'invalid@email.com.invalid'});
        fakeMessage.setPlainTextBody('body');
        fakeMessage.setEntityAttachments(
            new List<String>{SObjectType.ContentVersion.keyPrefix + '000000000123'}
        );
        toValidate.add(fakeMessage);

        EmailMessage fakeRecord = new EmailMessage(
            RelatedToId = recordId,
            FromAddress = oneAddress.Address,
            ParentId = SObjectType.Case.keyPrefix + '000000000123'
        );
        validateTrigger.add(fakeRecord);
    }

    validationResults = Messaging.sendEmail(toValidate, false);
    triggerResults = Database.insert(validateTrigger, false);

    for(Integer i = 0; i < oWEA.size(); i++){
        if(validationResults[i].getErrors()[0].getStatusCode() == System.StatusCode.INVALID_CROSS_REFERENCE_KEY
            && triggerResults[i].getErrors()[0].getStatusCode() == System.StatusCode.INVALID_CROSS_REFERENCE_KEY){
            finalList.add(oWEA[i]);
        }
    }   

    Contract__c contract = [
        SELECT Lessor_Code__c, Program__c
        FROM Contract__c
        WHERE Id = :recordId
        LIMIT 1
    ];

    // official Xerox / XBS / XFS validation
    Boolean isXBS = (contract.Program__c != null && contract.Program__c.containsIgnoreCase('XBS'));
    Boolean isLessor111or211 = (contract.Lessor_Code__c == '111' || contract.Lessor_Code__c == '211');

    String folderDevName = (isXBS || isLessor111or211)
        ? 'XBSDelayedBuyouts'
        : 'DelayedBuyouts';


    List<EmailTemplate> emailTemplates = [
        SELECT Id, Name, DeveloperName, Subject, HtmlValue, foldername, folderid
        FROM EmailTemplate
        WHERE Folder.DeveloperName = :folderDevName
    ];

    return '{"oWEA": ' + JSON.serialize(finalList) +
           ', "emailTemplates": ' + JSON.serialize(emailTemplates, true) + '}';
}



    @testVisible
    static String getToAddress(String contactId){
        List<Contact> contacts = [SELECT Id, Email FROM Contact WHERE Id = :contactId];
        String result = '';
        if(contacts.size() > 0 && contacts[0].Email != null){
            result = '{"toAddress": "' + contacts[0].Email + '"}';
        } else{
            result = '{"error": "The specified Contact doesn\'t have a valid Email Address"}';
        }
        return result;
    }

    @testVisible
    static String scheduleDelivery(String fromAddress, String toAddress, String contactId, String templateId, String recordId,
        String fileName, String fileBody){

        List<String> xLessorCodes = new List<String> {'101', '102', '103', '104', '111','113', '211', '213', '471'}; 
        Contract__c contract = [SELECT Id, Lessor_Code__c, Program__c, Name FROM Contract__c WHERE ID=:recordId];

        SL_MessageCodeHelper msgCodeHelper = new SL_MessageCodeHelper();
        Datetime thePresent = null;
        if(System.Test.isRunningTest()){
            thePresent = Datetime.now()/* SL_SCTestData.testNow this gives error when it is in the past*/;
        }else{
            thePresent = Datetime.now();
        }

        Datetime appointedDay;
        if(xLessorCodes.contains(contract.Lessor_Code__c) || 
            (contract.Program__c!= null && contract.Program__c.contains('XBS'))||
            (contract.Program__c!= null && contract.Program__c.contains('XFS'))) //Check if is a Xerox contract, then it will delay the send action for 5 days
        {
            appointedDay = msgCodeHelper.getNextWorkingDay(msgCodeHelper.addBussinessDaysV2(thePresent.date(), 5));
        }
        else{
            appointedDay = msgCodeHelper.getNextWorkingDay(msgCodeHelper.addBussinessDaysV2(thePresent.date(), 3));
        }

            //CREATE EMAIL OBJECT
            Messaging.SingleEmailMessage sem = Messaging.renderStoredEmailTemplate(templateId, contactId, recordId);


                    EmailMessage emailMsg = new EmailMessage(
                        EmailTemplateId	= templateId,
                        FromAddress = fromAddress ,
                        Scheduled_Contact_ID__c = contactId,
                        Subject = 'Buyout Email for Contract '+contract.Name,                 // Email Subject
                        ToAddress = toAddress,           // Recipient's email address
                        RelatedToId = recordId,
                        TextBody = sem.getPlainTextBody(),  // Email Body
                        HTMLBody = sem.getHtmlBody(),
                        Scheduled__c = true, 
                        MessageDate = appointedDay, //change this line to appointedDay
                        Status = '5'
                    );

            // Insert the EmailMessage record into Salesforce
            insert emailMsg;
            //CREATE EMAIL OBJECT

            // Create an Attachment (you can create one from an existing document or file)
            Attachment attach = new Attachment(
                ParentId = emailMsg.Id,  // Link attachment to the EmailMessage
                Name = filename,
                Body = EncodingUtil.base64Decode(EncodingUtil.urlDecode(fileBody, 'UTF-8'))
                );

            // Insert the attachment
            insert attach;



        return 'success';
    }

    @testVisible
    static String getScheduledQBs(String recordId){

        List<EmailMessage> emailsToSend = [SELECT Id, ToAddress, Subject, FromAddress, RelatedToId, Status, toLabel(Status) statusLabel,  CreatedBy.Email, CreatedBy.Name, MessageDate FROM EmailMessage WHERE Scheduled__c = true AND Status='5' AND RelatedToId = :recordId];
        return JSON.serialize(emailsToSend, true);
    }

    @testVisible
    static String cancelScheduledQB(String recordId, String jobId){
        List<EmailMessage> emailsToCancel = [SELECT Id, Status, Scheduled__c  FROM EmailMessage WHERE RelatedToId = :recordId AND Id = :jobId];
        for(EmailMessage em : emailsToCancel){
            em.Scheduled__c = false;
        }
        update emailsToCancel;

        List<EmailMessage> emailsToSend = [SELECT Id, ToAddress, Subject, FromAddress, RelatedToId, Status, toLabel(Status) statusLabel,  CreatedBy.Email, CreatedBy.Name, MessageDate FROM EmailMessage WHERE Scheduled__c = true AND Status='5' AND RelatedToId = :recordId];
        return JSON.serialize(emailsToSend, true);
    }


}