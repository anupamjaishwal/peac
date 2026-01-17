@isTest
public with sharing class SL_UserTriggerHandlerTest {
  private static final String OEG_DEALER_PROFILE = 'OEG Dealer';
  private static final String USERNAME = 'Portal.SL.test.user@silverlinecrm.com';
  private static final Id DEALER_ACC = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer_Vendor').getRecordTypeId();
    
    @isTest()
    public static void scenario1() {
        User u = new User();
        Id expectedId = null;
        Test.startTest();
        SL_SCTestData.createAccountAndContracts(1, 1);
        List<User> externalUsers = [SELECT Id, name, ContactId, Contact.AccountId, Dealer__c FROM User WHERE ContactId != null];
        system.debug('externalUsers.size() ' + externalUsers.size() );
        if(externalUsers.size() > 0){
            u = externalUsers[0];
            expectedId = u.Contact.AccountId;
        }else{
            Account acc = SL_SCTestData.testAccounts[0];
            u = SL_SCTestData.testUser;
            Site.createExternalUser(u, acc.Id);
        }
        u.Dealer__c = 'nothing';
        // this will need review in fullCopy, also tests actually adding the role to the Partner executive
        System.runAs(SL_SCTestData.testUser){
        	update u;    
        }
        Test.stopTest();
        List<User> usersAfter = [SELECT Id, name, ContactId, Contact.AccountId, Dealer__c FROM User WHERE Id = :u.Id];
        // if(externalUsers.size() > 0 && usersAfter.size() > 0){
        //     System.assertEquals(expectedId, usersAfter[0].Dealer__c);
        // }
    }

    @isTest
    static void addingPermissionSetsSharingAndGroup(){
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User systemAdmin = SL_SCTestData.createTestUser(p.Id);
        SL_SCTestData.createAccountAndContracts(1,1);
        Account portalAccount = SL_SCTestData.testAccounts[0];
        portalAccount.Account_Dealer_Program__c = 'XBS;';
        
        Test.startTest();
        System.runAs(systemAdmin){
           User u = SL_SCTestData.createDPDataForUser(portalAccount);
            PermissionSet thePermission = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Dealer_Delegated_Admin'];
            PermissionSetAssignment thePSA = new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = thePermission.Id);
            insert thePSA;
            SL_SCTestData.createPortalContracts(1,portalAccount, u);
            update u;
        }
        Test.stopTest();
    }

    @isTest
    static void removingSharingAndUngroup(){
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User systemAdmin = SL_SCTestData.createTestUser(p.Id);
        SL_SCTestData.createAccountAndContracts(1,1);
        Account portalAccount = SL_SCTestData.testAccounts[0];
        portalAccount.Account_Dealer_Program__c = 'XBS;';
        
        Test.startTest();
        System.runAs(systemAdmin){
           User u = SL_SCTestData.createDPDataForUser(portalAccount);
            PermissionSet thePermission = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Dealer_Delegated_Admin'];
            PermissionSetAssignment thePSA = new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = thePermission.Id);
            insert thePSA;
            SL_SCTestData.createPortalContracts(1,portalAccount, u);
            u.IsActive = false;
            update u;
        }
        Test.stopTest();
    }
}