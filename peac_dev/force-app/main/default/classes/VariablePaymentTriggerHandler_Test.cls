@isTest
public class VariablePaymentTriggerHandler_Test {
    
    @TestSetup
    static void setup(){
        
        //create dealer type account
        //Account record of type End USer
        RecordType rt = [select id,Name from RecordType where SobjectType='Account' and Name='End User Account' Limit 1];
        Account acct1 = new Account(Name='Test Account1' , recordTypeId=rt.id);        
        insert acct1;
        
        Account acct2 = new Account(Name='Test Account2' , recordTypeId=rt.id, Business_Phone__c = '0987654321');
        insert acct2;
        
        //create opportuntiy and associate it with the account.
        RecordType rt2 = [select id,Name from RecordType where SobjectType='Opportunity' and Name LIKE '%Express%' Limit 1];
        Opportunity op = new Opportunity();
        op.Name = 'Test Opp';
        op.Accountid = acct1.Id;
        op.Amount = 100;
        op.StageName = 'Quote';
        op.CloseDate = System.today() + 30;
        op.Primary_Source__c = 'Email';
        
        Test.startTest();
        insert op;
        Test.stopTest();
        
    }
    
    public static testmethod void testInsertVp() {
        Opportunity op = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp'];
        
        Test.startTest();
        Variable_Payment__c vp = new Variable_Payment__c();
        vp.of_payments__c = 67;
        vp.Payment_Amount__c = 56;
        vp.Opportunity__c = op.id;
        insert vp;
        Test.stopTest();
    }
}