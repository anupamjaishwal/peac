/** @author : Northteq Consulting, Inc.
 * @date : 11/11/20
 * @description: Do Not Sync to Marketo Batch Test Class
 *
 */
@IsTest
public with sharing class TC_DNSMarketoBatchableTest {

  //  SELECT Id, AccountId, Application_Status__c, Decision_Date__c FROM Opportunity WHERE Application_Status__c = 'Rejected' AND Decision_Date__c >= :Date.today().addDays(-numDays) AND Decision_Date__c < :Date.today().addDays(-numDays+1)
    @testSetup
    static void setup() {

        Marlin_Configuration__c setting = new Marlin_Configuration__c();
        setting.Name = 'DNS_Marketo_Timer__c';
        setting.DNS_Marketo_Timer__c = 30;
        insert setting;

        Integer numDays = Integer.valueOf(Marlin_Configuration__c.getOrgDefaults().DNS_Marketo_Timer__c);

        Account testAccount = new Account();
        testAccount.Name='Test Account' ;
        insert testAccount;

        Contact cont = new Contact();
        cont.Phone = '123-123-1234';
        cont.FirstName='Testfn';
        cont.LastName='Testln';
        cont.Do_Not_Sync_to_Marketo__c = true;

        cont.Accountid= testAccount.id;
        insert cont;

        Contact cont2 = new Contact();
        cont2.Phone = '123-123-1234';
        cont2.FirstName='Test2fn';
        cont2.LastName='Test2ln';
        cont2.Do_Not_Sync_to_Marketo__c = false;
        cont2.Accountid= testAccount.id;
        insert cont2;

        Account acc = new Account();
        acc.Name = 'test';
       // acc.RecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Lessor').getRecordTypeId();
        insert acc;
        Account broker = new Account();
        broker.Name = 'source';
       // broker.RecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Source').getRecordTypeId();

        Test.startTest();
        insert broker;




        Opportunity opp1 = new Opportunity ();
        opp1.Decision_Date__c = System.today()-30;
        opp1.Application_Status__c = 'Rejected';
        opp1.Name = 'Test Opp';
        opp1.StageName = 'Pipeline';
        opp1.CloseDate = System.today() - 1;
        opp1.AccountId = acc.Id;

        insert opp1;

    }

    static testMethod void testMethod1()
    {
        Test.StartTest();
        TC_DNSMarketoBatchable   dle = new TC_DNSMarketoBatchable();
        Id batchId = Database.executeBatch(dle);

        Test.StopTest();
    }

    static testMethod void testMethod2()
    {
        Test.StartTest();
        TC_DNSMarketoBatchable dle = new TC_DNSMarketoBatchable();
        Id batchId = Database.executeBatch(dle);

        Test.StopTest();
   }

    static testMethod void testMethod3()
    {
        Test.StartTest();
        TC_DNSMarketoBatchable dle = new TC_DNSMarketoBatchable();
        Id batchId = Database.executeBatch(dle);
        Test.StopTest();
     }
}