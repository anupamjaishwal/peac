/********************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This class is responsilbe for sharing the related list of Contract records with the 
associated super dealer user.
@User Story:DP-1585
@Created Date:February-24-2025 	    
*********************************************************************************************************************/

@isTest
public with sharing class PEAC_ContractShareBatchTest {
    
    private static final String OEG_DEALER_PROFILE = 'OEG Dealer';
    private static final String USERNAME = 'Portal.R.test.user@Mindtree.com';
    private static final String USERNAME1 = 'Portal.J.test.user@Mindtree.com';
    private static final String USERNAME2 = 'Portal.M.test.user@Mindtree.com';
    private static final Id DEALER_ACC = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer_Vendor').getRecordTypeId();
    
    /**************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This is a testsetup method to prepare the data to execute PEAC_ContractShareBatch logic
@User Story:DP-1585
@Created Date:February-24-2025    
@Param:None
@Return:None
**************************************************************************************************************/
    
    @TestSetup
    static void makeDataTest(){
        SL_SCTestData.createAccountAndContracts(3,3);
        Account portalAccount = SL_SCTestData.testAccounts[0];
        portalAccount.RecordTypeId = DEALER_ACC;
        UPDATE portalAccount;
        
        Contact portalContact = new contact(LastName = 'portalContact', FirstName = 'Test', AccountId = portalAccount.Id);
        INSERT portalContact;
        
        Account portalAccount1 = SL_SCTestData.testAccounts[1];
        portalAccount1.RecordTypeId = DEALER_ACC;
        UPDATE portalAccount1;
        
        Contact portalContact1 = new contact(LastName = 'portalContact1', FirstName = 'Test1', AccountId = portalAccount1.Id);
        INSERT portalContact1;
        
        Account portalAccount2 = SL_SCTestData.testAccounts[2];
        portalAccount2.RecordTypeId = DEALER_ACC;
        UPDATE portalAccount2;
        
        Contact portalContact2 = new contact(LastName = 'portalContact2', FirstName = 'Test2', AccountId = portalAccount2.Id);
        INSERT portalContact2;
        
        Test.startTest();
        User pUser1 ;
        User pUser;
        User pUser2;
        system.runAS(new user(ID = UserInfo.getUserID()))
        {
            
            pUser = new User(Alias = 'testuser', Email = 'marlinbusiness@peacsolutions.com', EmailEncodingKey='UTF-8',
                             LastName = 'testing', FirstName = 'user', LanguageLocaleKey = 'en_US',
                             LocaleSidKey = 'en_US', ProfileId = [SELECT Id, Name FROM Profile WHERE Name = :OEG_DEALER_PROFILE].Id, TimeZoneSidKey = 'America/Los_Angeles',
                             Username = USERNAME, Doc_Fee_Exception_Approver__c = true, PortalRole = 'Manager', ContactId = portalContact.Id,
                             IsPrmSuperUser = true, SuperUser__c = true);
            INSERT pUser;
            pUser1 = new User(Alias = 'testuser', Email = 'marlinbusiness@peacsolutions.com', EmailEncodingKey='UTF-8',
                              LastName = 'testing', FirstName = 'user', LanguageLocaleKey = 'en_US',
                              LocaleSidKey = 'en_US', ProfileId = [SELECT Id, Name FROM Profile WHERE Name = :OEG_DEALER_PROFILE].Id, TimeZoneSidKey = 'America/Los_Angeles',
                              Username = USERNAME1, Doc_Fee_Exception_Approver__c = true, PortalRole = 'Manager', ContactId = portalContact1.Id,
                              IsPrmSuperUser = true, SuperUser__c = true);
            INSERT pUser1;   
            pUser2 = new User(Alias = 'testuser', Email = 'marlinbusiness@peacsolutions.com', EmailEncodingKey='UTF-8',
                              LastName = 'testing', FirstName = 'user', LanguageLocaleKey = 'en_US',
                              LocaleSidKey = 'en_US', ProfileId = [SELECT Id, Name FROM Profile WHERE Name = :OEG_DEALER_PROFILE].Id, TimeZoneSidKey = 'America/Los_Angeles',
                              Username = USERNAME2, Doc_Fee_Exception_Approver__c = true, PortalRole = 'Manager', ContactId = portalContact2.Id,
                              IsPrmSuperUser = true, SuperUser__c = true);
            INSERT pUser2;
            
            PermissionSet thePermission = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Dealer_Delegated_Admin'];
            PermissionSetAssignment thePSA = new PermissionSetAssignment(AssigneeId = pUser.Id, PermissionSetId = thePermission.Id);
            insert thePSA;
            SL_SCTestData.createPortalContracts(1,portalAccount, pUser);
            
            update pUser;
        }
        
        Test.stopTest();
        ExternalAccountHierarchy externalAccount = createExternalAccount(portalAccount,false,null);
        
        //SL_SCTestData.createPortalContracts(1,portalAccount1, pUser1);
        Contract__c contract = new Contract__c (Customer__c = portalAccount1.Id, Status__c = 'Active',
                                                Name = '401-234433-210', application_number__c = '1234567890',dealer_user__c = pUser1.id,
                                                Delinquency_Status_Code__c = '00', Infolease_Environment__c = '10', dealer_Name__c = portalAccount1.Id);
        Insert contract;
        
        //SL_SCTestData.createPortalContracts(1,portalAccount1, pUser1);
        Contract__c contract1 = new Contract__c (Customer__c = portalAccount2.Id, Status__c = 'Active',
                                                 Name = '401-234883-210', application_number__c = '1234567890',dealer_user__c = pUser1.id,
                                                 Delinquency_Status_Code__c = '00', Infolease_Environment__c = '10', dealer_Name__c = portalAccount2.Id);
        Insert contract1;
        ExternalAccountHierarchy externalAccount1 = createExternalAccount(portalAccount1,true,externalAccount);
        createExternalAccount(portalAccount2,true,externalAccount1);
        
    }
    /**************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This test method will schedule PEAC_ContractShareBatch and share contract records
with dealer user and super partner users associated with the same account id of
the contract record
@User Story:DP-1585
@Created Date:February-24-2025    
@Param:None
@Return:None
**************************************************************************************************************/
    
    @isTest
    public static void contractSharingTest() {
        Map<Id, User> userMap = new Map<Id, User>();
        Map<Id,Id> sDPUserAccountIDMap = New Map<Id,Id>();
        Id pUserId ;
        userMap = new Map<Id, User>([SELECT Id, Contact.AccountId FROM User WHERE IsActive = true AND IsPrmSuperUser = true ]);
        for(user superDuser: userMap.values()){
            sDPUserAccountIDMap.Put(superDuser.Id,superDuser.Contact.AccountId);
            pUserId = superDuser.Id;
            
        }
        Test.startTest();
        Map<Id,Contract__c> contractMap = new Map<id,Contract__c>([SELECT Id, Dealer_User__c FROM Contract__c LIMIT 1]);
        contractMap.values()[0].Dealer_User__c = pUserId;
        Update contractMap.values();
        
        datetime dynamicDate = system.today().addDays(-30);
        // Schedule the Apex job with a dummy cron expression
        String CRON_EXP = '0 0 0 3 9 ? 2042';
        //id jobId = System.schedule('PEAC_ContractShareBatchTest', CRON_EXP, new PEAC_ContractShareBatch(True)); 
        //Database.executeBatch(new PEAC_ContractShareBatch(sDPUserAccountIDMap), 20);
        //Database.executeBatch(new PEAC_ContractShareBatch());
        //Database.executeBatch(new PEAC_ContractShareBatch('Today',false), 20);
        //Database.executeBatch(new PEAC_ContractShareBatch(sDPUserAccountIDMap.values()), 20);
        
        
        Test.stopTest();
        List<Contract__Share> contractShareList = New List<Contract__Share>();
        contractShareList = [SELECT ID FROM Contract__Share ];
        assert.areEqual(contractShareList.isEmpty(),false,'Contract sharing is missing');// positive test
        
    }
    @isTest
    public static void contractSharing1Test() {
        Map<Id, User> userMap = new Map<Id, User>();
        Map<Id,Id> sDPUserAccountIDMap = New Map<Id,Id>();
        Id pUserId ;
        userMap = new Map<Id, User>([SELECT Id, Contact.AccountId FROM User WHERE IsActive = true AND IsPrmSuperUser = true LIMIT 1]);
        for(user superDuser: userMap.values()){
            sDPUserAccountIDMap.Put(superDuser.Id,superDuser.Contact.AccountId);
            pUserId = superDuser.Id;
            
        }
        Test.startTest();
        
        datetime dynamicDate = system.today().addDays(-30);
        // Schedule the Apex job with a dummy cron expression
        //String CRON_EXP = '0 0 0 3 9 ? 2042';
        //id jobId = System.schedule('PEAC_ContractShareBatchTest', CRON_EXP, new PEAC_ContractShareBatch(false)); 
        //Database.executeBatch(new PEAC_ContractShareBatch(sDPUserAccountIDMap), 20);
        // Database.executeBatch(new PEAC_ContractShareBatch());
        //Database.executeBatch(new PEAC_ContractShareBatch('Today',false), 20);
        //Database.executeBatch(new PEAC_ContractShareBatch(sDPUserAccountIDMap.values()), 20);
        Test.stopTest();
        List<Contract__Share> contractShareList = New List<Contract__Share>();
        contractShareList = [SELECT ID FROM Contract__Share ];
        assert.areEqual(contractShareList.isEmpty(),false,'Contract sharing is missing');// positive test
        
    }
    @isTest
    public static void contractSharing2Test() {
        Map<Id, User> userMap = new Map<Id, User>();
        Map<Id,Id> sDPUserAccountIDMap = New Map<Id,Id>();
        Id pUserId ;
        userMap = new Map<Id, User>([SELECT Id, Contact.AccountId FROM User WHERE IsActive = true AND IsPrmSuperUser = true LIMIT 1]);
        for(user superDuser: userMap.values()){
            sDPUserAccountIDMap.Put(superDuser.Id,superDuser.Contact.AccountId);
            pUserId = superDuser.Id;
            
        }
        Test.startTest();
        // Schedule the Apex job with a dummy cron expression
        Database.executeBatch(new PEAC_ContractShareBatch(sDPUserAccountIDMap), 20);
        //Database.executeBatch(new PEAC_ContractShareBatch());
        //Database.executeBatch(new PEAC_ContractShareBatch('Today',false), 20);
        //Database.executeBatch(new PEAC_ContractShareBatch(sDPUserAccountIDMap.values()), 20);
        Test.stopTest();
        List<Contract__Share> contractShareList = New List<Contract__Share>();
        contractShareList = [SELECT ID FROM Contract__Share ];
        assert.areEqual(contractShareList.isEmpty(),false,'Contract sharing is missing');// positive test
        
    }
    @isTest
    public static void updateContractSharingTest() {
        Test.startTest();
        List<Contract__c> contractList = [SELECT ID,Dealer_Name__c,Dealer_User__c FROM Contract__c WHERE Dealer_Name__c !=NULL ];
        contractList[0].dealer_Name__c = contractList[1].Dealer_Name__c;
        contractList[0].dealer_User__c = contractList[1].dealer_User__c;
        
        update contractList;
        
        
        
        Test.stopTest();
        List<Contract__Share> contractShareList = New List<Contract__Share>();
        contractShareList = [SELECT ID FROM Contract__Share ];
        assert.areEqual(contractShareList.isEmpty(),false,'Contract sharing is missing');// positive test
        
    }
    
    @isTest
    public static void updateContactSharingTest() {
        Test.startTest();
        List<Contract__c> contractList = [SELECT ID,Dealer_Name__c,Dealer_User__c FROM Contract__c WHERE Dealer_Name__c !=NULL ];
        contractList[0].dealer_Name__c = contractList[1].Dealer_Name__c;
        contractList[0].dealer_User__c = contractList[1].dealer_User__c;
        
        update contractList;
        list<user> dUserList = [SELECT ID, IsPrmSuperUser,ContactId,Contact.AccountId,IsActive FROM USER WHERE IsPrmSuperUser = true AND IsActive = True AND Contact.AccountId != null];
        system.debug(LoggingLevel.ERROR, 'dUserList...'+dUserList);
        
        list<Contact> contactList = [  SELECT ID,ACCOUNTID FROM Contact WHERE Id =: dUserList[0].ContactId];
        contactList[0].AccountId = dUserList[1].Contact.AccountId;
        update contactList;
        
        Test.stopTest();
        List<Contract__Share> contractShareList = New List<Contract__Share>();
        contractShareList = [SELECT ID FROM Contract__Share ];
        assert.areEqual(contractShareList.isEmpty(),false,'Contract sharing is missing');// positive test
        
    }
    
    @isTest
    public static void updateExternalAccountTest() {
        Test.startTest();
        List<ExternalAccountHierarchy> externalAccountList = [SELECT Id,accountid,parentId,name
                                                              FROM ExternalAccountHierarchy WHERE  IsActive = True AND  Parent.ParentId != null AND accountid!=null Limit 1];
        Map<Id,Id> oldExternalIdWithAccountMap = new Map<Id,Id>();
        for(ExternalAccountHierarchy externaAcc: externalAccountList)
        {
            if(externaAcc.accountid!=null)
            {
                oldExternalIdWithAccountMap.put(externaAcc.accountid, externaAcc.Id);
            }
            
        }
        PEAC_ContractShareHelperBatch.getExternalAccounts(oldExternalIdWithAccountMap);
        list<user> dUserList = [SELECT ID, IsPrmSuperUser,ContactId,Contact.AccountId,IsActive FROM USER WHERE IsPrmSuperUser = true AND IsActive = True AND Contact.AccountId != null];
        system.debug(LoggingLevel.ERROR, 'dUserList...'+dUserList);
        
        list<Contact> contactList = [ SELECT ID,ACCOUNTID FROM Contact WHERE Id =: dUserList[0].ContactId];
        contactList[0].AccountId = dUserList[1].Contact.AccountId;
        update contactList;
        List<PEAC_ExternalAccountHieraTriggerHandler.ExternalAccountDetails> externalAccList = new List<PEAC_ExternalAccountHieraTriggerHandler.ExternalAccountDetails>();
        PEAC_ExternalAccountHieraTriggerHandler.ExternalAccountDetails pscr = new PEAC_ExternalAccountHieraTriggerHandler.ExternalAccountDetails();
        pscr.newDealerAccounts = externalAccountList[0];
        pscr.oldDealerAccounts = null;
        pscr.actionType = 'Insert';
        externalAccList.add(pscr);
        PEAC_ExternalAccountHieraTriggerHandler.shareContracts(externalAccList); 
        
        Test.stopTest();
        List<Contract__Share> contractShareList = New List<Contract__Share>();
        contractShareList = [SELECT ID FROM Contract__Share ];
        assert.areEqual(contractShareList.isEmpty(),false,'Contract sharing is missing');// positive test
        
    }
    
    static ExternalAccountHierarchy createExternalAccount(Account acc, Boolean ischild,ExternalAccountHierarchy parentAcc){
        List<ExternalAccountHierarchy> externalAccountList = New List<ExternalAccountHierarchy>();
        
        ExternalAccountHierarchy externalAccount = new ExternalAccountHierarchy();
        externalAccount.Name = acc.name;
        externalAccount.AccountId = acc.Id;
        if(isChild)
        {
            externalAccount.ParentId = parentAcc.id;
        }
        externalAccount.IsActive = true;
        
        externalAccountList.add(externalAccount);
        insert externalAccount;
        return externalAccount;
        
        
    }
    
}