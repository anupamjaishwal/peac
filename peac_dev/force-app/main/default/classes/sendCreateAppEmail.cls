global without sharing class sendCreateAppEmail {
    @InvocableMethod(
            Label='sendEmail'
            Description='sendEmail to users'
    )    
    global static void sendEmail(List<String> oppId){
        system.debug('oppId;'+oppId);
        opportunity opp = [SELECT Id, Owner.Email,Name, Application__c, Account.Name, UD_DLR_ENTERED_COMMENT__c 
            FROM Opportunity WHERE Id = :oppId[0]];
        OrgWideEmailAddress owe = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply@peacsolutions.com'];
        USer u = [SELECT Id, Contact.Account.SAM__r.Email, Contact.Account.Ambassador__r.Email FROM User where Id = :userinfo.getUserId()];
        system.debug('u;'+u);
       // String baseUrl = URL.getCurrentRequestUrl().toExternalForm();
        String sfdcBaseURL = URL.getOrgDomainURL().toExternalForm();
  
        // Construct the full URL for the Opportunity record
        String opportunityUrl = URL.getOrgDomainUrl().toExternalForm()+'/'+opp.Id;
        
        List<string> emailAddr = new List<String>();
        emailAddr.add(opp.Owner.Email);
        if(u.Contact.Account.SAM__r.Email <> null) emailAddr.add(u.Contact.Account.SAM__r.Email);
        if(u.Contact.Account.Ambassador__r.Email <> null) emailAddr.add(u.Contact.Account.Ambassador__r.Email);
        // just for test, remove the below line before giving this to QA
        // emailAddr.add('misael.romero@silverlinecrm.com');
        system.debug('emailAddr;'+emailAddr);
        Messaging.SingleEmailMessage mail = CustomSendMailUtil.SetCustomSingleEmail(emailAddr, 'Action Needed for Portal Application: '
            +opp.Account.Name+'. Notes were added during partner application entry that need review.',
            'Your partner has entered comments during application submission: '+opp.Account.Name+' '
            +opportunityUrl+' that need your review. Please reference the "dealer entered comments" field in Salesforce for details so you can facilitate any needed changes to the opportunity.',
            null,owe.Id);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        
    }
}