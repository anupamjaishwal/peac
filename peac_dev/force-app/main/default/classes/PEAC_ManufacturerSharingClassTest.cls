/********************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This test class is reasponsilbe for sharing the list of Manufacture Account related records with the 
associated dealer user code coverage.
@User Story:DP-1241
@Created Date:October-14-2024 	    
*********************************************************************************************************************/
@isTest
public class PEAC_ManufacturerSharingClassTest {
    private static final String OEG_DEALER_PROFILE = 'OEG Dealer';
    private static final String USERNAME = 'Portal.SL.test1.user@silverlinecrm.com';
    private static final Id DEALER_ACC = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer_Vendor').getRecordTypeId();
    
    @TestSetup
    static void createTestData(){
        //create Manufacturer Accounts
        SL_SCTestData.createManufacturer(1, True);
    }
    @isTest
    static void portalUserCreationTest(){
        SL_SCTestData.createAccountAndContracts(1,1);
        Account portalAccount = SL_SCTestData.testAccounts[0];
        portalAccount.RecordTypeId = DEALER_ACC;
        UPDATE portalAccount;
        
        Contact portalContact = new contact(LastName = 'portalContact', FirstName = 'Test', AccountId = portalAccount.Id);
        INSERT portalContact;
        
        User pUser = new User(Alias = 'testuser', Email = 'marlinbusiness@peacsolutions.com', EmailEncodingKey='UTF-8',
                              LastName = 'testing', FirstName = 'user', LanguageLocaleKey = 'en_US',
                              LocaleSidKey = 'en_US', ProfileId = [SELECT Id, Name FROM Profile WHERE Name = :OEG_DEALER_PROFILE].Id, TimeZoneSidKey = 'America/Los_Angeles',
                              Username = USERNAME, Doc_Fee_Exception_Approver__c = true, PortalRole = 'Manager', ContactId = portalContact.Id,
                              IsPrmSuperUser = true, SuperUser__c = true);
        INSERT pUser;
        Test.startTest();
        system.runAs(new user(ID = UserInfo.getUserID())){
            PermissionSet thePermission = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Dealer_Delegated_Admin'];
            PermissionSetAssignment thePSA = new PermissionSetAssignment(AssigneeId = pUser.Id, PermissionSetId = thePermission.Id);
            insert thePSA;
            SL_SCTestData.createPortalContracts(1,portalAccount, pUser);
            update pUser;
        }
        // Schedule the Apex job with a dummy cron expression
		String CRON_EXP = '0 0 0 3 9 ? 2042';
        id jobId = System.schedule('PEAC_ManufacturerShareBatchTest', CRON_EXP, new PEAC_ManufacturerShareBatch()); 
        Test.stopTest();
        List<AccountShare> accountShareList = New List<AccountShare>();
        accountShareList = [SELECT ID FROM AccountShare ];
        assert.areEqual(accountShareList.isEmpty(),false,'Account sharing is missing');
        PEAC_ManufacturerShareQueueable.emptyMethod();
        PEAC_ManufacturerSharingClass.emptyMethod();
    }
}