public without sharing class SL_DPImperative {
    @AuraEnabled
    public static string hubExecute(String methodName, List<String> parameters){
        String result = '';
        try {
            switch on methodName {
                when 'getCustomerSummary'{
                    result = getCustomerSummary(parameters[0]);
                }
            }
        } catch (Exception e) {
            system.debug('e: ' + e);
            system.debug('e.getMessage(): ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
        return result;
    }

    public static String getCustomerSummary(String customerId){
        String result = '{}';
        User currentUser = [SELECT Id, Name, Contact.AccountId FROM User WHERE Id = :System.UserInfo.getUserId()];
        Id dealerAccountId = currentUser.Contact.AccountId;
        // if(Test.isRunningTest()){
        //     dealerAccountId = SL_SCTestData.dealerAccountId;
        // }
        List<AggregateResult> customerSummary = [SELECT SUM(Total_Amount_Due__c) totalAmountDue, SUM(Total_Past_Due__c) totalAmtPastDue, SUM(Total_Tax_Past_Due__c) totalTax,
            SUM(Misc_Amount_Due__c) miscellaneous, SUM(Past_Due_130__c) pastDue130, SUM(Past_Due_3160__c) pastDue3160, SUM(Past_Due_6190__c) pastDue6190, 
            SUM(Past_Due_90__c) pastDue90, SUM(Contract_Balance_Remaining__c) totalCbr, COUNT(Id) totalActive, SUM(Current_Invoice__c) currentInvoiced,
            SUM(Late_Charge_Amount__c) lateCharges FROM Contract__c 
            WHERE Is_Active__c = true AND Customer__c = :customerId AND Dealer_Name__c = :dealerAccountId
            GROUP BY Customer__c ];
        system.debug('customerSummary: ' + customerSummary);
        if(customerSummary.size() == 1){
            result = JSON.serialize(customerSummary[0], false);
        }
        return result;
    }
    
    @AuraEnabled
    public static void SendOnBaseEmailXBS(String recordId){
        Opportunity opp = [Select Id, Program__c, StageName, Assign_To_CMS_User__c, Application__c from Opportunity Where Id =:recordId Limit 1];
        
        List<Opportunity_Attachment__c> oppAtList = new List<Opportunity_Attachment__c>();
        opp.StageName = 'Docs In';
        oppAtList = [Select Id from Opportunity_Attachment__c Where Opportunity__c =:recordId AND Sent_to_Onbase__c = false];
        OrgWideEmailAddress noReply = [select Id, Address from OrgWideEmailAddress where Address = 'noreply@peacsolutions.com' Limit 1];
        String subject = 'New Portal Document (app #'+opp.Application__c+')';
        String body = 'Please see the attached document that was uploaded to the Dealer Portal: Application Number: '+opp.Application__c;
        if(opp.Program__c<>NULL && opp.Assign_To_CMS_User__c <> null){
            User CMS = [Select Email from User Where Id=:opp.Assign_To_CMS_User__c Limit 1];
            if(opp.Program__c.Contains('XBS')&&opp.StageName=='Docs In'&& oppAtList.size()>0 && CMS.Email<>NULL){                
        		System.Debug('CMS Email '+CMS.Email);
                List<String> recipientL = new List<String>();
                System.debug('Got to the email');
                recipientL.add(CMS.Email);
                // test email recipient
                // recipientL.add('carlos.herrera@silverlinecrm.com');
                Messaging.SingleEmailMessage mail = CustomSendMailUtil.SetCustomSingleEmail(recipientL,subject,body,null,noReply.ID);
                List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
                emails.add(mail);
                List<Messaging.SendEmailResult> results = Messaging.sendEmail(emails);
            }
        }
    }

    public static void updateDealerAccounts(List<Account> accLst){
        update accLst;
    }
}