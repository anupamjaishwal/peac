@IsTest
public with sharing class TC_AppSubmittedSetBranchTest {
    
    // @TestSetup
    // static void makeData(){
    //     Account acc = new Account (
    //         Name = 'test', 
    //         RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId()
    //     );
    //     insert acc;
        
    //     Contact c = new Contact (
    //         AccountId = acc.Id, 
    //         FirstName = 'test', 
    //         LastName = 'contact', 
    //         MailingStreet = 'test', 
    //         MailingCity = 'test', 
    //         MailingStateCode = 'MN', 
    //         MailingPostalCode = '11111', 
    //         MailingCountry='United States', 
    //         Phone='5555555555',
    //         Title = 'title', 
    //         SSN__c = '111111111', 
    //         BirthDate = Date.today (), 
    //         Email = 'test123@test.com'
    //     );
    //     insert c;

    //     Opportunity opp = new Opportunity(
    //         AccountId = acc.Id,
    //         StageName = 'test',
    //         CloseDate = date.today () + 10,
    //         Name = 'test'
    //     );
    //     insert opp;
    // }

    @IsTest
    public static void runTest(){
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>();
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();

        TC_AppSubmittedSetBranch.doAction(oldMap, newMap);

    }
}