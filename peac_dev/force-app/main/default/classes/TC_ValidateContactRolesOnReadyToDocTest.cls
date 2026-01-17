@isTest
public with sharing class TC_ValidateContactRolesOnReadyToDocTest {
    @TestSetup
    static void dataSetup(){

        ORE__c o = new ORE__c(Bypass__c = true);
        insert o;

        Marlin_Configuration__c m = new Marlin_Configuration__c(Req_Dealer_Pri_Contact_Start_Date__c = date.today()-90);
        insert m;

        Account acc = new Account (
            Name = 'test', 
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
            // SSN__c = '1111111', 
            BirthDate = Date.today (), 
            Email = 'test123@test.com'
        );
        insert c;

        Opportunity opp = new Opportunity(
            AccountId = acc.Id,
            Resubmitted_to_Credit__c = true,
            Credit_Decision__c = false,
            CloseDate = date.today()+100,
            Probability = 80,
            Deferral_Payments__c = '30 days',
            StageName = 'test',
            Ready_to_Doc__c = 'No',
            RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Express Decision'][0].Id,
            Name = 'test'
        );
        insert opp;

    }

    @IsTest
    public static void noPrimaryContact(){
        List<Opportunity> opps = [SELECT Id, Ready_to_Doc__c, CreatedDate, record_type_name__c, RecordTypeId, Loan_Record_Type__c, StageName FROM Opportunity];
        List<Contact> contacts = [SELECT Id FROM Contact];
        Test.startTest();
        insert new OpportunityContactRole(Role = '', OpportunityId = opps[0].Id, ContactId = contacts[0].Id );
        opps[0].Ready_to_Doc__c = 'Yes';
        List<Database.SaveResult> oppResults = Database.update(opps, false);
        System.debug('queries after update Opportunity: ' + System.Limits.getQueries());
        Test.stopTest();
        List<Opportunity> oppsAfter = [SELECT Ready_to_Doc__c FROM Opportunity];
        if(!oppResults[0].isSuccess()){
            System.debug(oppResults[0].getErrors()[0]?.getMessage());
            System.debug(oppResults[0].getErrors()[0]);
        }
        system.debug('oppsAfter[0].Ready_to_Doc__c: ' + oppsAfter[0].Ready_to_Doc__c);
        System.assert(oppResults[0].getErrors()[0]?.getMessage().contains('Opportunity must have either Dealer Primary Contact or Dealer Sales Rep Contact in Contact Roles (with valid email) when Ready to Doc = Yes'));
    }

}