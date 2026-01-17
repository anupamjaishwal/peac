@isTest
public with sharing class TC_CalculateGrossContractTest {
    @TestSetup
    static void dataSetup(){

        Account acc = new Account (
            Name = 'test', 
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId()
        );
        insert acc;

        Opportunity opp = new Opportunity(
            AccountId = acc.Id,
            of_Payments__c = 5,
            Payment_Amount__c = 1200,
            First_Payment_Amount__c = 100,
            Ending_Pymts_in_Advance__c = 100,
            of_ending_payments__c = 4,
            Equipment_Cost__c = 50,
            Gross_Contract__c = 10,
            CloseDate = date.today()+5,
            StageName = 'test',
            Name = 'test'
        );
        insert opp;
    }
    @IsTest
    public static void CalculateGrossContractTest(){
        Opportunity opp = [SELECT Id, Gross_Contract__c, Equipment_Cost__c, of_Payments__c, of_ending_payments__c, Payment_Amount__c, First_Payment_Amount__c, Ending_Pymts_in_Advance__c FROM Opportunity];
            try{
                TC_CalculateGrossContract.calculateGrossContract(opp);
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