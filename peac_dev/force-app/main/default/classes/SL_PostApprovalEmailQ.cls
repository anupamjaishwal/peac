public with sharing class SL_PostApprovalEmailQ implements Queueable {
    List<Id> accountsToEmail;

    public SL_PostApprovalEmailQ(List<Id> accountsToEmail) {
        this.accountsToEmail = accountsToEmail;
    }

    public void execute(QueueableContext context) {
        List<Messaging.SingleEmailMessage> mailPouch = new List<Messaging.SingleEmailMessage>();
        for(Account targetAccount :[SELECT Id, Name, CCAN__c,
                    (SELECT Id, Name, Application__c, Application_Status__c FROM Opportunities 
                    WHERE Application_Status__c IN ('Automatically Approved', 'Manually Approved', 'Approved'))
                FROM Account
                WHERE Id IN :this.accountsToEmail]){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] {'CustomerVerifications@marlincorp.com'});
            // need to remove the below line once I confirm it is working
            //mail.setCcAddresses(new String[] {'misael.romero@silverlinecrm.com', 'sara.martinez@silverlinecrm.com', 'BRay@peacsolutions.com', 'SAkuthota@peacsolutions.com'});
            mail.setSubject('Post Approval Account Name Change');
            String bodyText = 'The name on the account related to approved applications(s) has been changed.\r\n\r\n'
                    + 'Application #(s):\r\n';
            for(Opportunity approvedOpp: targetAccount.Opportunities){
                bodyText += approvedOpp.Application__c + '\r\n';
            }
            bodyText += 'Account Name: ' + targetAccount.Name + '\r\nCCAN: ' + targetAccount.CCAN__c;
            mail.setPlainTextBody(bodyText);
            mailPouch.add(mail);
        }
        Messaging.sendEmail(mailPouch);
    }
}