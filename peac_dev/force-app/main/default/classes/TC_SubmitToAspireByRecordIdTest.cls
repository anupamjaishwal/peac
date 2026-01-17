@isTest
public with sharing class TC_SubmitToAspireByRecordIdTest {
    @TestSetup
    static void dataSetup(){
        Account acc = new Account (
        Name = 'test', 
        RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId()
        );
        insert acc;

        Opportunity opp = new Opportunity(
            AccountId = acc.Id,
            StageName = 'Proposal',
            CloseDate = date.today () + 10,
            Name = 'test'
        );
        insert opp;
    }
    
    @IsTest
   public static void submitToAspireByRecordIdTest(){

       Opportunity opp = [SELECT Id FROM Opportunity];
       TC_SubmitToAspireByRecordId.submitToAspireByRecordId(opp.Id);
   }
       
}