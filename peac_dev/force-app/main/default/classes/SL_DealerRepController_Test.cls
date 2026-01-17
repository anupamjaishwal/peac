@isTest
public with sharing class SL_DealerRepController_Test {
  private static Integer numberOfAccounts = 50;
  private static Id DEALER_ACC_RT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer_Vendor').getRecordTypeId();

  @TestSetup
  static void setup(){
    List<Account> lstAccount = new List<Account>();
    for(Integer i = 0; i <= numberOfAccounts; i++){
      Account acc = new Account();
      acc.Name              = 'Test Acc ' + i;
      acc.Business_Phone__c = String.valueOf(i + 1234567890).left(10);
      acc.RecordTypeId      = DEALER_ACC_RT;

      lstAccount.add(acc);
    }
   
    INSERT lstAccount;
  }

  @isTest()
  static void test_getDealerRep(){

    List<Account> lstAccounts = [SELECT Id, Name, OwnerId FROM Account LIMIT :numberOfAccounts];
    List<Account> accountResponse = SL_DealerRepController.getDealerRep(lstAccounts[0].Id, 'Id, Name, OwnerId');
    Assert.areEqual(lstAccounts[0].OwnerId, accountResponse[0].OwnerId);
    Assert.areEqual(lstAccounts[0].Name, accountResponse[0].Name);
    Assert.areEqual(lstAccounts[0].Id, accountResponse[0].Id);
  }

  @isTest()
  static void test_getDealerRepWithout(){

    List<Account> lstAccounts = [SELECT Id FROM Account LIMIT :numberOfAccounts];
    Assert.areEqual(null, SL_DealerRepController.getDealerRep(lstAccounts[0].Id, ''), 'Expecting null value from the controller since we did not provide any field');
  }
}