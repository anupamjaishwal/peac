@isTest
public with sharing class SL_SharingCustomRecord_Test {
  private static final Integer COUNT_CONTRACTS = 5;
  private static final String OEG_DEALER_PROFILE = 'OEG Dealer';
  private static final String USERNAME = 'Portal.SL.test.user@silverlinecrm.com';
  private static final String USERNAME2 = 'Portal.SL.test.user2@silverlinecrm.com';
  private static final Set<String> userNames = new Set<String>{USERNAME, USERNAME2, 'service.admin.test.user@silverlinecrm.com'};

  @TestSetup
  static void makeData(){
    SL_SCTestData.createAccountAndContracts(1,COUNT_CONTRACTS);
    Account portalAccount = new Account(name = 'portalAccount', Business_Phone__c = '1234567890');//create a portal account first
    INSERT portalAccount;
    
    Contact portalContact = new contact(LastName = 'portalContact', FirstName = 'Test', AccountId = portalAccount.Id); //create a portal contact
    INSERT portalContact;
    Contact portalContact2 = new contact(LastName = 'portalContact', FirstName = 'Test', AccountId = portalAccount.Id); //create a portal contact
    INSERT portalContact2;
    

    User u = new User(Alias = 'testuser', Email = 'marlinbusiness@peacsolutions.com', EmailEncodingKey='UTF-8',
            LastName = 'testing', FirstName = 'user', LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US', ProfileId = [SELECT Id, Name FROM Profile WHERE Name = :OEG_DEALER_PROFILE].Id, TimeZoneSidKey = 'America/Los_Angeles',
            Username = USERNAME, Doc_Fee_Exception_Approver__c = true, PortalRole = 'Manager', ContactId = portalContact.Id);
    insert u;
    User u2 = u.clone();
    u2.Id = null;
    u2.Username = USERNAME2;
    u2.ContactId = portalContact2.Id;
    u2.Email = 'fake2.Portal.SL.test.user@silverlinecrm.com';
    insert u2;

    List<Contract__c> lstContracts = [SELECT Id FROM Contract__c];
    for(Contract__c contract :lstContracts){
      contract.Dealer_User__c = u.Id;
    }

    UPDATE lstContracts;
  }

  @isTest
  static void scenario1(){
    List<Contract__c> lstContracts = [SELECT Id, Dealer_Name__c, OwnerId FROM Contract__c];
    Account portalAccount = [SELECT Id, Name, OwnerId FROM Account WHERE Name = 'portalAccount' LIMIT 1];
    Map<Id, Set<Id>> mapRecordsToShare = new Map<Id, Set<Id>>();
    List<User> users = [SELECT Id, UserName FROM User WHERE UserName IN :userNames];
    Id userId = users[0].Id;
    Id userId3 = users[1].Id;
    Id adminUserId = users[2].Id;
    
    mapRecordsToShare.put(lstContracts[0].Id, new Set<Id>{userId});
    Contract__c secondContract = lstContracts[1];
    Contract__c newContract = lstContracts[2];
    secondContract.Dealer_User__c = adminUserId;
    newContract.Dealer_User__c = userId3;
    newContract.Id = null;
    newContract.Status__c = 'Active';
    SL_SharingCustomRecord shareContract = new SL_SharingCustomRecord();
    Test.startTest();
    insert newContract;
    System.runAs(users[2]){
      shareContract.checkRecordToShareOrRemove_Contract(lstContracts[0], null, true, userId, mapRecordsToShare, new Map<Id, Id>());
      shareContract.checkRecordToShareOrRemove_Contract(lstContracts[0], secondContract, false, userId3, mapRecordsToShare, new Map<Id, Id>());
      shareContract.addRecordToList('Contract__share', secondContract.Id, userId3, 'Read', false, false);
      shareContract.commitRecords('Contract__share', false);
      shareContract.addRecordToList('Contract__share', secondContract.Id, userId3, 'Read', true, false);
      shareContract.commitRecords('Contract__share', false);
      system.debug('secondContract.OwnerId before: ' + secondContract.OwnerId);
      secondContract.OwnerId = userId;
      system.debug('secondContract.OwnerId after: ' + secondContract.OwnerId);
      system.debug('userId: ' + userId);
      system.debug('userId3: ' + userId3);
      secondContract.Dealer_User__c = userId3;
      shareContract.checkRecordToShareOrRemove_Contract(secondContract, null, true, userId3, mapRecordsToShare, new Map<Id, Id>());
      shareContract.addRecordToList('AccountShare', secondContract.Id, userId3, 'Read', true, true);
      shareContract.commitRecords('AccountShare', true);
    }
    AccountShare existingShare = new AccountShare(AccountAccessLevel = 'Edit', OpportunityAccessLevel = 'Edit', CaseAccessLevel = 'Read',
                    RowCause = 'Manual', AccountId = portalAccount.Id, UserOrGroupId = adminUserId);
                    List<AccountShare> sharesToInsert = new List<AccountShare>{existingShare.clone()};
                    List<AccountShare> sharestoDelete = new List<AccountShare>{existingShare.clone()};
                    List<AccountShare> sharestoDeleteForReal = new List<AccountShare>();
    SL_SharingCustomRecord.checkAddOrRemove(existingShare, sharesToInsert, sharestoDelete, sharestoDeleteForReal, 'AccountId', 'Manual', 'AccountAccessLevel', 'Edit');
    Test.stopTest();
  }
    @isTest
  static void testDealerUserReAssignment(){
    user dealer = [SELECT Id FROM User WHERE IsActive = true AND ProfileId IN (SELECT Id FROM Profile WHERE Name = :OEG_DEALER_PROFILE) AND userName = :USERNAME LIMIT 1];
      
    assert.areEqual(COUNT_CONTRACTS, [SELECT Id FROM Contract__Share WHERE UserOrGroupId = :dealer.Id].size());

    test.startTest();
      List<Contract__c> lstContracts = [SELECT Id FROM Contract__c];
      for(Contract__c contract :lstContracts){
        contract.Dealer_User__c = null;
        
      }

      UPDATE lstContracts;
    test.stopTest();
    delete lstContracts;
    system.runAs(dealer){
      assert.areEqual(0, [SELECT Id FROM Contract__c].size());
    }
    //contractShareonDealerName();
  }
  
  @istest
  static void createcontract(){
      Account acc = [SELECT Id FROM Account WHERE name = 'portalAccount'];
      String recTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId();

        Account dealerAccount = new Account(name = 'dealer Account', Business_Phone__c = '1234567890', recordTypeId=recTypeId);
        INSERT dealerAccount;
      Contract__c contract = new Contract__c (
          Customer__c = acc.Id,
            Status__c = 'Active',
            Name = '401-1111111-210', application_number__c = '1234567890',
            Delinquency_Status_Code__c = '00',
            Dealer_Name__c = dealerAccount.Id
        );
        insert contract;
  }

  // @isTest
  // static void testDealerUserReAssignment(){
  //   user dealer = [SELECT Id FROM User WHERE IsActive = true AND ProfileId IN (SELECT Id FROM Profile WHERE Name = :OEG_DEALER_PROFILE) AND userName = :USERNAME LIMIT 1];
      
  //   assert.areEqual(COUNT_CONTRACTS, [SELECT Id FROM Contract__Share WHERE UserOrGroupId = :dealer.Id].size());

  //   test.startTest();
  //     List<Contract__c> lstContracts = [SELECT Id FROM Contract__c];
  //     for(Contract__c contract :lstContracts){
  //       contract.Dealer_User__c = null;
  //     }

  //     UPDATE lstContracts;
  //   test.stopTest();

  //   system.runAs(dealer){
  //     assert.areEqual(0, [SELECT Id FROM Contract__c].size());
  //   }
  // }
}