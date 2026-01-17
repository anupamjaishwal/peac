@isTest
public class AccountDetails_Test {

   public static testmethod void getAccountPriority_Test(){
   
       RecordType rt = [select id,Name from RecordType where SobjectType='Account' and Name='Dealer Account' Limit 1];
       Account acct1 = new Account(Name='Test Account1' , recordTypeId=rt.id, Equipment_Type__c = 'A/V (General)');
       insert acct1;
       Account acc = new Account();
       acc = AccountDetails.getAccountPriority(acct1.id);
       System.AssertEquals(acc.id,acct1.id);
       
       AccountDetails.ErrorWrapperClass wrap = new AccountDetails.ErrorWrapperClass();
       wrap = AccountDetails.getAccount('Qualification',acct1.id);

   }

 
 
}