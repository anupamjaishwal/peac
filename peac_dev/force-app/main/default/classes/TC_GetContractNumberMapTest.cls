@isTest
public with sharing class TC_GetContractNumberMapTest {
    @TestSetup
    static void dataSetup(){

        Account acc = new Account (
            Name = 'test', 
            CCID__c = '9000000',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId()
        );
        insert acc;

        Opportunity opp = new Opportunity(
            AccountId = acc.Id,
            CloseDate = date.today()+5,
            StageName = 'test',
            Name = 'test'
        );
        insert opp;

        Loan_Contract__c lc = new Loan_Contract__c(Opportunity__c = opp.Id, Contract_Status__c = 'Active', Name = 'TestRecordR222');
        insert lc;
    }

    @IsTest
    public static void GetContractNumberMapTest(){

            Opportunity opp = [SELECT Id, StageName,CCID__c FROM Opportunity];
            try{
                TC_GetContractNumberMap.getContractNumberMap(new set<Id>{opp.Id});
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