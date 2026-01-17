public with sharing class SL_EmailAlertsFormerWorkFlowsQ implements Queueable {
    Map<Id, List<String>> emailTemplatesByOppId = new Map<Id, List<String>>();
    public SL_EmailAlertsFormerWorkFlowsQ(Map<Id, List<String>> emailTemplatesByOppId) {
        this.emailTemplatesByOppId = emailTemplatesByOppId;
    }
// SAL-5133 Misael Romero
    public void execute(QueueableContext context) {
        sendAlerts(emailTemplatesByOppId);
    }

    public static void sendAlerts(Map<Id, List<String>> emailTemplatesByOppId){
        if(emailTemplatesByOppId.keySet().size() > 0){
            List<Messaging.SingleEmailMessage> mailPouch = new List<Messaging.SingleEmailMessage>();
            List<OrgWideEmailAddress> noreply = new List <OrgWideEmailAddress> ([SELECT Id, Address, DisplayName from OrgWideEmailAddress WHERE address = 'noreply@peacsolutions.com']);
            Id noreplyId = null;
            if(noreply.size() > 0){
                noreplyId = noreply[0].Id;
            }
            Set<String> allEmailTemplates = new Set<String>();
            for(List<String> emailTemplates:emailTemplatesByOppId.values()){
                allEmailTemplates.addAll(emailTemplates);
            }
            Map<String, EmailTemplate> EmailTemplateMap = new Map<String, EmailTemplate>();
            for(EmailTemplate et : [SELECT Id, Name, DeveloperName,  FolderName, Subject
                FROM EmailTemplate WHERE DeveloperName IN :allEmailTemplates]){
                EmailTemplateMap.put(et.DeveloperName, et);
            }
            for(Id oppId : emailTemplatesByOppId.keySet()){
                if(emailTemplatesByOppId.get(oppId).contains('SalesApproved')){
                    List<Id> oppIds = new List<Id>(emailTemplatesByOppId.keySet());
                    TC_PopulateOppMergeFields.populateOppMergeFields(oppIds);
                    break;
                }
            }
            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, Owner.Email, Dealer_Account__r.Ambassador__r.Email FROM Opportunity WHERE Id IN :emailTemplatesByOppId.keySet()]);
            for(Id oppId : emailTemplatesByOppId.keySet()){
                List<String> emailTemplateNames = emailTemplatesByOppId.get(oppId) ?? new List<String>();
                Opportunity opp = oppMap.get(oppId);
                List<String> emailTemplatesToRender = new List<String>{'SalesSubmitted', 'SalesApproved', 'SalesDecline', 'SalesPending'};
                for(String templateDevName :emailTemplateNames){
                    Messaging.SingleEmailMessage renderedEmail = null;
                    if(emailTemplatesToRender.contains(templateDevName)){
                        Id templateId = EmailTemplateMap.get(templateDevName).Id;
                        renderedEmail = Messaging.renderStoredEmailTemplate(templateId, opp.OwnerId, opp.Id);    
                    }
                    if(renderedEmail != null){
                        renderedEmail.setOrgWideEmailAddressId(noreplyId);
                        Account theAccount = opp.Dealer_Account__r;
                        User theOwner = opp.Owner;
                        List<String> toAddresses = new List<String>();
                        if(theOwner != null && theOwner.Email != null){
                        toAddresses.add(theOwner.Email);
                        }
                        if(theAccount != null && theAccount.Ambassador__r != null && theAccount.Ambassador__r.Email != null){
                        toAddresses.add(theAccount.Ambassador__r.Email);
                        }
                        renderedEmail.setToAddresses(toAddresses);
                        List<String> ccAddresses = new List<String>{'mgiordano@marlincapitalsolutions.com', 'SVarghese@marlincapitalsolutions.com'};
                        if(templateDevName == 'SalesDecline' || templateDevName == 'SalesPending'){
                            ccAddresses.add('SGonuguntla@marlincapitalsolutions.com');
                            ccAddresses.add('Bray@marlincapitalsolutions.com');
                            ccAddresses.add('hpadgett@marlincapitalsolutions.com');
                        }
                        // the below are test addresses, remove when going into production
                        // ccAddresses.add('misael.romero@silverlinecrm.com');
                        // ccAddresses.add('SAkuthota@peacsolutions.com');
                        renderedEmail.setCcAddresses(ccAddresses);
                        renderedEmail.setSaveAsActivity(false);
                        mailPouch.add(renderedEmail);
                    }
                }
            }
            if(mailPouch.size() > 0){
                Messaging.sendEmail(mailPouch);
            }
        }
    }
}