@isTest
public with sharing class TC_ContractMappingTest {
    @TestSetup
    static void dataSetup(){
 
        Account acc = new Account (
            Name = 'test', 
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId()
        );
        insert acc;

        Opportunity opp = new Opportunity(
            AccountId = acc.Id,
            Resubmitted_to_Credit__c = true,
            Credit_Decision__c = false,
            CloseDate = date.today()+100,
            Probability = 80,
            Deferral_Payments__c = '30 days',
            StageName = 'test',
            Ready_to_Doc__c = 'No',
            Loan_Points_Amount__c = 15,
            RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Express Decision'][0].Id,
            Name = 'test'
        );
        insert opp;
        
		String accid = acc.Id;
        TC_ASPIRE__Account__c aspireAcc = new TC_ASPIRE__Account__c(TC_ASPIRE__LastName__c = 'AAA',TC_ASPIRE__AccountId__c = accid.substring(0, 15), TC_ASPIRE__RecordId__c = acc.Id, TC_ASPIRE__AccountType__c='Individual');
        insert aspireAcc;
    }
    @IsTest
    public static void ContractMappingTest(){
        try{
        Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];
        TC_ContractMapping contractMapping = new TC_ContractMapping(o.Id);
        contractMapping.createASPIRERecord();
        //contractMapping.addMappingFields();
        contractMapping.deleteRecords();
        }
        catch(Exception e){

        }
    }

}