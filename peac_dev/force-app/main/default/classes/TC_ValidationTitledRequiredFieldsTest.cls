@isTest
public with sharing class TC_ValidationTitledRequiredFieldsTest {
    @TestSetup
    static void dataSetup(){

        ORE__c o = new ORE__c(Bypass__c = true);
        insert o;

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
            Name = 'test'
        );
        Test.startTest();
        insert opp;
        Test.stopTest();
        Asset__c asset = new Asset__c (Opportunity__c = opp.Id, Cost__c = 100, List_Price__c = 10, Equipment_Code__c = 'Titled Vehicles (General)');
        insert asset;
    }
    @IsTest
    public static void ValidationTitledRequiredFieldsTest(){

            List<Opportunity> opp = [SELECT Id, StageName FROM Opportunity];
             Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>();
             Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();
     
             for(Opportunity op : opp){
                    Opportunity o = new Opportunity(
                    Id = op.Id, 
                    Ready_to_Doc__c = 'No'
                    );
                    oldMap.put(op.Id, o);
            }
    
             for(Opportunity op : opp){
                Opportunity o = new Opportunity(
                    Id = op.Id, 
                    Ready_to_Doc__c = 'Yes');
                newMap.put(op.Id, o);
            }
    
            try{
                TC_ValidationTitledRequiredFields.validationTitledRequiredFields(oldMap,newMap);
                }
                catch (DmlException e) {
                    System.debug(e.getMessage());
                    System.debug(e.getStackTraceString());
                }
                catch (Exception e) {
                    System.debug(e.getMessage());
                    System.debug(e.getStackTraceString());
                }
    }
}