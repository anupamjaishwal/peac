/**
 * Created by trohweder on 3/15/21.
 */
@IsTest
public with sharing class TC_DealerSuvAutoDeactivateBatchTest {

    @TestSetup
    public static void createTestData(){
        List<Account> dealerList = new List<Account>();

        Account acc = new Account();
        acc.Name = 'Test';
        acc.RecordTypeId = [SELECT Id FROM RecordType WHERE Name='Dealer Account' LIMIT 1].Id;
        acc.Account_Dealer_Status__c = 'Active';

        dealerList.add(acc);

        Account acc2 = new Account();
        acc2.Name = 'Test2';
        acc2.RecordTypeId = [SELECT Id FROM RecordType WHERE Name='Dealer Account' LIMIT 1].Id;
        acc2.Account_Dealer_Status__c = 'Watch List';

        dealerList.add(acc2);

        Account acc3 = new Account();
        acc3.Name = 'Test3';
        acc3.RecordTypeId = [SELECT Id FROM RecordType WHERE Name='Dealer Account' LIMIT 1].Id;
        acc3.Account_Dealer_Status__c = 'Active';

        dealerList.add(acc3);

        Account acc5 = new Account();
        acc5.Name = 'Test5';
        acc5.RecordTypeId = [SELECT Id FROM RecordType WHERE Name='Dealer Account' LIMIT 1].Id;
        acc5.Account_Dealer_Status__c = 'Watch List';

        dealerList.add(acc5);

        Test.startTest();

        insert dealerList;

        Test.stopTest();

        List<Account> childAccounts = new List<Account>();

        Account acc4 = new Account();
        acc4.Name = 'Test4';
        acc4.RecordTypeId = [SELECT Id FROM RecordType WHERE Name='Dealer Account' LIMIT 1].Id;
        acc4.Account_Dealer_Status__c = 'Active';
        acc4.ParentId = dealerList[2].Id;

        childAccounts.add(acc4);

        Account acc6 = new Account();
        acc6.Name = 'Test6';
        acc6.RecordTypeId = [SELECT Id FROM RecordType WHERE Name='Dealer Account' LIMIT 1].Id;
        acc6.Account_Dealer_Status__c = 'Watch List';
        acc6.ParentId = dealerList[3].Id;

        childAccounts.add(acc6);

        insert childAccounts;

        for(Account a : childAccounts){
            dealerList.add(a);
        }

        for(Account a : dealerList){
            a.Date_Dealer_Approved_Most_Recent__c = Date.today ().addYears(-1).addDays(-1);
        }

        update dealerList;
    }

    @IsTest
    public static void dotest(){
        Database.executeBatch(new TC_DealerSuvAutoDeactivateBatch(), 6);
    }
}