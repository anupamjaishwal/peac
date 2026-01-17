public class TC_NewDealerRampupNotification {
    public static void newDealerRampupNotification(Map<Id, Account> oldMap, Map<Id, Account> newMap) {
        Set<Id> accIdSet = new Set<Id>();
        for (Account acc : newMap.values()) {
            if ((acc.Account_Dealer_Status__c == 'On Hold' && oldMap.get(acc.Id).Account_Dealer_Status__c != acc.Account_Dealer_Status__c)  && acc.Preferred_Dealer_Level__c != '4') {
                accIdSet.add(acc.Id);
            }
            
        }
       
        
        if (!accIdSet.isEmpty()) {
            Map<Id, List<Dealer__c>> accIdDealerListMap = new Map<Id, List<Dealer__c>>();
            List<Dealer__c> dealerList = new List<Dealer__c>([
                    SELECT Id, Dealer__c, Opportunity__r.Application__c, Opportunity__r.Name, Opportunity__r.Credit_Amount__c
                    FROM Dealer__c
                    WHERE Dealer__c IN :accIdSet]);
            system.debug('======dealerList'+ dealerList);
            for (Dealer__c dealer : dealerList) {
                if (accIdDealerListMap.containsKey(dealer.Dealer__c)) {
                    accIdDealerListMap.get(dealer.Dealer__c).add(dealer);
                } else {
                    accIdDealerListMap.put(dealer.Dealer__c, new List<Dealer__c>{dealer});
                }
            }

            Map<Id, String> accIdOwnerEmailMap = new Map<Id, String>();
            List<Account> accountList = new List<Account>([SELECT Id, Owner.Email FROM Account WHERE Id IN: accIdSet]);
            for (Account account : accountList) {
                accIdOwnerEmailMap.put(account.Id, account.Owner.Email);
            }

            List <OrgWideEmailAddress> noreply = new List <OrgWideEmailAddress> ([select id, Address, DisplayName from OrgWideEmailAddress where address = 'noreply@peacsolutions.com']);
            List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();

            for (Id accId : accIdSet) {
                Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage ();

                if (!noreply.isEmpty()) emailMessage.setOrgWideEmailAddressId(noreply[0].Id);
                emailMessage.setToAddresses (new List <String>{'partnermanagementteam@marlincapitalsolutions.com'});
                emailMessage.setCcAddresses(new List<String>{accIdOwnerEmailMap.get(accId)});
                emailMessage.saveAsActivity = false;
                emailMessage.setSubject('New Dealer Ramp-up Notification');

                String applicationDescriptionHTML = '';
                String applicationDescriptionPlainText = '';
                if (accIdDealerListMap.containsKey(accId)) {
                    applicationDescriptionHTML += '<ul>';
                    applicationDescriptionPlainText += '';
                    for (Dealer__c dealer : accIdDealerListMap.get(accId)) {
                        String descriptionString = dealer.Opportunity__r.Name;

                        descriptionString += ': Application # = ';
                        descriptionString += dealer.Opportunity__r.Application__c != null ? dealer.Opportunity__r.Application__c : 'N/A';

                        descriptionString += '; Credit Amount = ';
                        String currencyString = dealer.Opportunity__r.Credit_Amount__c != null ? (dealer.Opportunity__r.Credit_Amount__c.setScale(2) + 0.001).format() : '0.000';
                        descriptionString += '$' + currencyString.subString(0, currencyString.length()-1);
                        applicationDescriptionHTML += '<li>' + descriptionString + '</li>';
                        applicationDescriptionPlainText += '\n' + descriptionString;
                    }
                    applicationDescriptionHTML += '</ul>';
                } else {
                    applicationDescriptionHTML = '<p>This account is not yet a Dealer for an opportunity.</p>';
                    applicationDescriptionPlainText = '\nThis account is not yet a Dealer for an opportunity.';
                }

                String htmlBody =
                        '<p>New dealer approved within the last 90 days has reached 5 apps and/or $250K in credit amount.</p>' +
                                '<p>Dealer #: ' + newMap.get(accId).Dealer_Number__c + '</p>' +
                                '<p>Dealer Name: ' + newMap.get(accId).Name + '</p>' +
                                '<p>App #\'s Associated with Dealer: ' + applicationDescriptionHTML + '</p>';
                String plainTextBody =
                        'New dealer approved within the last 90 days has reached 5 apps and/or $250K in credit amount.\n' +
                                'Dealer #: ' + newMap.get(accId).Dealer_Number__c + '\n' +
                                'Dealer Name: ' + newMap.get(accId).Name + '\n' +
                                'App #\'s Associated with Dealer:' + applicationDescriptionPlainText;
                emailMessage.setHtmlBody(htmlBody);
                emailMessage.setPlainTextBody(plainTextBody);

                emailList.add(emailMessage);
            }

            system.debug ('>>>>> newDealerRampupNotification emailList size: ' + emailList.size ());

            if (!emailList.isEmpty()) {
                Messaging.SendEmailResult[] results = new List<Messaging.SendEmailResult>();
                if (!Test.isRunningTest()) results = Messaging.sendEmail(emailList);
            }
        }
    }
}