public inherited sharing class TC_DealerFundingLimit{
    public static void dummyMethod(){}
   /* public static void updateFundingLimit (Map <Id, Account> oldMap, Map <Id, Account> newMap) {
        Set<Id> accIds = new Set<Id>();
        Map<Id, User> usersMap = new Map<Id, USer>();
        List<Account> accountstoSendEmail = new List<Account>();
        List<Account> ReplenishList = new List<Account>();
        for(Account acc : newMap.values()){
            Account oldAcc = oldMap.get(acc.Id);
            if(oldAcc.Advanced_Funding_Limit__c <> acc.Advanced_Funding_Limit__c || oldAcc.Replenish_Date__c <> acc.Replenish_Date__c){
                //acc.Advanced_Funding_Balance__c =  
                accIds.add(acc.Id);
            }
            if((acc.Advanced_Funding_Balance__c == 0.00 || acc.Advanced_Funding_Balance__c == 0) && acc.Advanced_Funding_Limit__c <> null){
                accountstoSendEmail.add(acc);
                usersMap.put(acc.OwnerId, null);
            }
            if(oldAcc.Replenish_Date__c <> acc.Replenish_Date__c && acc.Advanced_Funding_Limit__c <> null){
                usersMap.put(acc.OwnerId, null);
                ReplenishList.add(acc);
            }
        }
        List<Account> updateAccounts = new List<Account>();
        if(accIds.size() > 0){
            Map<Id, double> oppMap = new Map<Id, Double>();
            for(Opportunity opp : [SELECT Id, Name, Primary_Dealer__r.Dealer__r.Replenish_Date__c, Funded__c, Equipment_Cost__c, Dealer_Account__c, Primary_Dealer__r.Dealer__c FROM Opportunity WHERE  Primary_Dealer__r.Dealer__c IN :accIds]){
                if(opp.Funded__c >= opp.Primary_Dealer__r.Dealer__r.Replenish_Date__c){
                    if(!oppMap.containsKey(opp.Primary_Dealer__r.Dealer__c)){
                        oppMap.put(opp.Primary_Dealer__r.Dealer__c, 0);
                    }
                    oppMap.put(opp.Primary_Dealer__r.Dealer__c, oppMap.get(opp.Primary_Dealer__r.Dealer__c)+opp.Equipment_Cost__c);
                }
            }
            
            for(Id accId : accIds){
                Account acc = newMap.get(accId);
                Account updateAcc = new Account();
                updateAcc.Id = accId;
                if(oppMap.containsKey(accId)){
                    updateAcc.Advanced_Funding_Balance__c = acc.Advanced_Funding_Limit__c - oppMap.get(accId);
                } else {
                    updateAcc.Advanced_Funding_Balance__c = acc.Advanced_Funding_Limit__c;
                }
                updateAccounts.add(updateAcc);
            }
            if(updateAccounts.size() > 0){
                update updateAccounts;
            }
        }
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        if(accountstoSendEmail.size() > 0){
            
            OrgWideEmailAddress owe = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply@peacsolutions.com'];
            for(User u : [SELECT Id, Email FROM User WHERE Id IN :usersMap.keySet()]){
                usersMap.put(u.Id, u);
            }
            for(Account acc : accountstoSendEmail){
                String subject = 'Advance Fund '+acc.Advanced_Funding_Balance__c+' for '+acc.Name+' Dealer# '+acc.Dealer_Number__c;
                String body= 'The Advance funding balance for this dealer is now $0.00. \nPlease update the \'Replenish Date\' tab in SF so Accounting can  fund the Dealer their Advance.';
                List<String> toAddr = new List<String>();
                toAddr.add(usersMap.get(acc.OwnerId).Email);
                system.debug('usersMap.get(acc.OwnerId): ' + usersMap.get(acc.OwnerId));
                system.debug('toAddr: ' + toAddr);
                emails.add(CustomSendMailUtil.SetCustomSingleEmail(toAddr,subject, body,null,owe.id));
            }
            
        }
        if(ReplenishList.size() > 0){
            
            for(Account acc : ReplenishList){
                String subject = acc.Name+' Advance Funding';
                String body= 'Good morning, May we replenish their '+acc.Advanced_Funding_Limit__c+' advance today?';
                List<String> toAddr = new List<String>();
                toAddr.add('bookingsheets@peacsolutions.com');
                toAddr.add('aobulareddygari@peacsolutions.com');
                emails.add(CustomSendMailUtil.SetCustomSingleEmail(toAddr,subject, body,null,null));
            }
        }
        if(emails.size() > 0)
                Messaging.sendEmail(emails);
    }*/
}