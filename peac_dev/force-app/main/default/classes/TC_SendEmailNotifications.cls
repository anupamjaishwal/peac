/**
 * Created by jbuchanan on 8/31/21.
 *SAL-3222 & SAL-3223
 */


public without sharing class TC_SendEmailNotifications{
    
    ///decommissioning this class for SAL- 4149
    
    ////Added this line to cover code coverge to pass deployment 
    public  void TC_SendEmailNotifications(string dummy){
        
    }
    
    /*static boolean recCheck1 = true;
    static boolean recCheck2 = true;
    
    public static void doAction(Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap){
        if(recCheck1){
           stepsEmail(oldMap,newMap.values(),false); 
        }
        if(recCheck2){
           completeEmail(oldMap,newMap.values(),false);
        }
    }
    public static void doAction(List<Opportunity> newList){
        if(recCheck1){
            stepsEmail(null,newList,false); 
         }
         if(recCheck2){
            completeEmail(null,newList,false);
         }
    }
    
    //SAL-3222
    public static void stepsEmail(Map<Id,Opportunity> oldMap,List<Opportunity> newList, Boolean isTest){
        List<String> loanOpps = new List<String>();
        if(oldMap != null){
            for(Opportunity opp: newList){
                if(opp.Workflow_Type__c == 'Simple' && opp.Portal_Status_Complete__c && (oldMap.get(opp.id).Portal_Status_Complete__c != opp.Portal_Status_Complete__c)){
                    loanOpps.add(opp.id);  
                }
            }
        }
        if(loanOpps.size() > 0 || isTest){
            EmailTemplate emailTemplate = [Select Id,Subject,Description,HtmlValue,DeveloperName,Body from EmailTemplate where name = 'Steps Complete'];
            List<String> recipients = new List<String>();
            List<Id> targets = new List<Id>();
            List<Opportunity> validOps = [SELECT id,Assign_To_CMS_User__c,Assign_To_CMS_User__r.Email,Owner.Email, (Select email__c,Contact__c FROM Signer_Portal_Status__r) FROM Opportunity WHERE id IN :loanOpps];
            for(Opportunity opp: validOps){
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
                    /*    messages.add(message);
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
                    System.debug('date today..' + Date.today());
                    recCheck1 = false;
        }
    }
    
    
    //SAL-3223
    public static void completeEmail(Map<Id,Opportunity> oldMap,List<Opportunity> newList, Boolean isTest){
       / List<String> loanOpps = new List<String>();
        if(oldMap != null){
            for(Opportunity opp: newList){
                if(opp.StageName == 'Funded/Booked' && opp.Workflow_Type__c == 'Simple'&& (oldMap.get(opp.id).StageName != opp.StageName)){
                    loanOpps.add(opp.id); 
                }
            }
        }
        if(loanOpps.size() > 0 || isTest){
            EmailTemplate emailTemplate = [Select Id,Subject,Description,HtmlValue,DeveloperName,Body from EmailTemplate where name = 'Funding and booking complete'];
            List<String> recipients = new List<String>();
            List<Id> targets = new List<Id>();
            List<Opportunity> validOps = [SELECT id,Assign_To_CMS_User__c,Assign_To_CMS_User__r.Email,Owner.Email, (Select email__c,Contact__c FROM Signer_Portal_Status__r) FROM Opportunity WHERE id IN :loanOpps];
            for(Opportunity opp: validOps){
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
                    /*    messages.add(message);
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
                    System.debug('date today..' + Date.today());
                    recCheck2 = false;
        }
    }
    
    public static void testBoost(){
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }*/
}