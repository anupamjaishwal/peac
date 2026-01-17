@IsTest
public with sharing class TC_SetOppApprovalEmailMergeFieldsTest {
    
    @TestSetup
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
            SSN__c = '111111111', 
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

        Guarantor__c pg = new Guarantor__c(Contact__c = c.Id, Opportunity__c = opp.Id);
        insert pg;
        
    }

    @IsTest
    public static void runTest(){

        List<Opportunity> opps = [SELECT Id, Application_Status__c FROM Opportunity];
        opps[0].Application_Status__c = 'Manually Approved';
        Test.startTest();
        update opps[0];
        Test.stopTest();
        List<Opportunity> oppsAfter = [SELECT Id, PGs_for_Approval_Email__c FROM Opportunity];
        Assert.areEqual('test contact', oppsAfter[0].PGs_for_Approval_Email__c, 'The name(s) of the PG(s) must populate in Opp');
    }
    

}