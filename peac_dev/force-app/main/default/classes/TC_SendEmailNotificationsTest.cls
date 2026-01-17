@IsTest
public with sharing class TC_SendEmailNotificationsTest {
    
     //// Start: Test class to cover codcoverage for decommision(SAL-4149) class-By Raja Sirivella
   static testmethod void test12(){
        Test.startTest();

       TC_SendEmailNotifications cs = new TC_SendEmailNotifications();
       cs.TC_SendEmailNotifications('test');

        Test.stopTest();
    }
    
    
    
    
   /* @TestSetup
    static void makeData(){
        Account acc = new Account (
            Name = 'test acccount', 
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId()
        );
        insert acc;
        
        
        Contact c = new Contact (
            AccountId = acc.Id, 
            FirstName = 'test', 
            LastName = 'contact', 
            MailingStreet = 'test', 
            MailingCity = 'test', 
            MailingStateCode = 'MN', 
            MailingPostalCode = '11111', 
            MailingCountry='United States', 
            Phone='5555555555',
            Title = 'title', 
            //SSNDisplay__c = '111111111', 
            BirthDate = Date.today (), 
            Email = 'test123@test.com'
        );
        insert c;

        Opportunity opp = new Opportunity(
            AccountId = acc.Id,
            StageName = 'test',
            CloseDate = date.today () + 10,
            Name = 'test'
        );
        insert opp;
    }

    @IsTest
    public static void runTest(){
        TC_SendEmailNotifications.testBoost();
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, Portal_Status_Complete__c, Workflow_Type__c FROM Opportunity]);
        List<Opportunity> newList = new List<Opportunity>();
        for(Id key : oldMap.keyset()){
            newList.add(new Opportunity(Id=key, Portal_Status_Complete__c = true, Workflow_Type__c = 'Simple'));
        }
       TC_SendEmailNotifications.stepsEmail(oldMap, newList, true); 
       TC_SendEmailNotifications.completeEmail(oldMap, newList, true); 
    }*/
}