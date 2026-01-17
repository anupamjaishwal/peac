@IsTest
private class TC_ContactRelatedObjUpdateTests {
    
    @IsTest
    static void testBehavior() {
        Test.setMock(HttpCalloutMock.class, new BriteVerifyHttpMock());
        Test.startTest();
        Account acct = TC_SDR_TestUtility.constructAccount('Test', null ,null);
        acct.Business_Phone__c = '1234567890';
        insert acct;
        
        Contact cont = TC_SDR_TestUtility.constructContact('fn','ln','fnln@testingorg.com',acct.Id);
        insert cont;
        
        cont.mkto71_Lead_Score__c = 30;
        cont.Receive_All_Notifications__c = true;
        update cont;
        
        acct = [SELECT Id, Account_Engagement_Score__c FROM Account WHERE Id = :acct.Id];
        System.assertEquals(cont.mkto71_Lead_Score__c, acct.Account_Engagement_Score__c);
        
        AccountContactRelation acr = [SELECT Id FROM AccountContactRelation WHERE ContactId = :cont.Id LIMIT 1];
        acr = new AccountContactRelation(ID = acr.ID, AccountId = acct.ID, ContactId = cont.Id, Roles = 'Primary contact');
        update acr;
        Test.stopTest();
    }
    
    @IsTest
    static void test_checkChangedDealerAccount() {
        Test.setMock(HttpCalloutMock.class, new BriteVerifyHttpMock());

        User testAdmin = new User(
            Alias = 'testur0', Email = 'marlinbusiness@peacsolutions.com', EmailEncodingKey='UTF-8',
            LastName = 'testing', FirstName = 'user', LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US', ProfileId = [SELECT Id FROM Profile WHERE Name = 'Services Admin'].Id,
            TimeZoneSidKey = 'America/Los_Angeles', Username = 'Testadmin.test.user@silverlinecrm.com',
            Doc_Fee_Exception_Approver__c = true, Personnel_Number__c = '0321'
        );
        insert testAdmin;
        
        User u = null;
        User parentU;
        Contact portalContact;
        
        System.runAs(testAdmin){
            SL_SCTestData.createAccountAndContracts(2, 1);
            
            Id dealerAccRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('Dealer_Vendor').getRecordTypeId();
            SL_SCTestData.testAccounts[1].ParentId   = SL_SCTestData.testAccounts[0].Id;
            SL_SCTestData.testAccounts[0].RecordTypeId = dealerAccRTId;
            update SL_SCTestData.testAccounts;
            
            List<Contact> lstContact = new List<Contact>();
            portalContact = new Contact(LastName = 'portalContact', FirstName = 'Test',
                                        AccountId = SL_SCTestData.testAccounts[1].Id);
            lstContact.add(portalContact);
            
            Contact portalContactParent = new Contact(LastName = 'portalContact', FirstName = 'Parent',
                                                      AccountId = SL_SCTestData.testAccounts[0].Id);
            lstContact.add(portalContactParent);
            insert lstContact;
            
            List<User> lstUser = new List<User>();
            u = new User(
                Alias='testur2', Email='marlinbusiness@peacsolutions.com', EmailEncodingKey='UTF-8',
                LastName='testing', FirstName='user', LanguageLocaleKey='en_US', LocaleSidKey='en_US',
                ProfileId=[SELECT Id FROM Profile WHERE Name='OEG Dealer'].Id,
                TimeZoneSidKey='America/Los_Angeles', Username='Portal.SL.test.user@silverlinecrm.com',
                Doc_Fee_Exception_Approver__c=true, PortalRole='Manager', ContactId=portalContact.Id,
                IsPrmSuperUser=true, Receive_Notifications__c=true
            );
            lstUser.add(u);
            
            parentU = new User(
                Alias='Parent', Email='marlinbusiness@peacsolutions.com.Parent', EmailEncodingKey='UTF-8',
                LastName='testing', FirstName='user', LanguageLocaleKey='en_US', LocaleSidKey='en_US',
                ProfileId=[SELECT Id FROM Profile WHERE Name='OEG Dealer'].Id,
                TimeZoneSidKey='America/Los_Angeles', Username='Parent.SL.test.user@silverlinecrm.com',
                Doc_Fee_Exception_Approver__c=true, PortalRole='Manager', ContactId=portalContactParent.Id,
                IsPrmSuperUser=false
            );
            lstUser.add(parentU);
            insert lstUser;
            
            Test.startTest();
            System.runAs(u){
                SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[1].Id, 1, 1);
                SL_SCTestData.testOpportunities[0].Dealer_User__c    = u.Id;
                SL_SCTestData.testOpportunities[0].Dealer_Account__c = SL_SCTestData.testAccounts[1].Id;
                update SL_SCTestData.testOpportunities[0];
            }
            
            portalContact.AccountId = SL_SCTestData.testAccounts[0].Id;
            update portalContact;
            Test.stopTest();
            
            parentU.IsPrmSuperUser = true;
            update parentU;
        }
    }
    
    // ------------------------------------
    // Callout mocking for BriteVerify path
    // ------------------------------------
    
    private class BriteVerifyHttpMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(
                '{"address":"cover@test.org","account":"cover","domain":"test.org","status":"valid","disposable":"false","role_address":"false","duration":"0.10"}'
            );
            return res;
        }
    }
    
    // ----------------------------------------------------
    // tests to cover email verification paths
    // ----------------------------------------------------
    
    @IsTest
    static void test_emailVerify_futurePath_is_covered() {
        Test.setMock(HttpCalloutMock.class, new BriteVerifyHttpMock());
        
        SL_SCTestData.createAccountAndContracts(1, 0);
        Account a = SL_SCTestData.testAccounts[0];
        
        Contact c = new Contact(
            FirstName='Fn',
            LastName='Ln',
            Email='cover@test.org',
            AccountId=a.Id
        );
        insert c;
        
        Test.startTest();
        TC_ContactRelatedObjUpdate.verifyEmail(c.Id, c.Email);
        Test.stopTest();
        
        Contact c2 = [
            SELECT Validity_Verify__Checked__c, Validity_Verify__Status__c
            FROM Contact WHERE Id = :c.Id
        ];
        System.assertEquals(true, c2.Validity_Verify__Checked__c, 'future should flag as checked');
    }
    
    @IsTest
    static void test_emailVerify_triggerPath_with_group_membership() {
        Test.setMock(HttpCalloutMock.class, new BriteVerifyHttpMock());
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Group g;
            List<Group> gs = [SELECT Id FROM Group WHERE DeveloperName = 'ValidityVerifyUsers' LIMIT 1];
            if (gs.isEmpty()) {
                g = new Group(Name='Validity Verify Users', DeveloperName='ValidityVerifyUsers', Type='Regular');
                insert g;
            } else {
                g = gs[0];
            }
            List<GroupMember> gms = [
                SELECT Id FROM GroupMember
                WHERE GroupId = :g.Id AND UserOrGroupId = :UserInfo.getUserId()
                LIMIT 1
            ];
            if (gms.isEmpty()) {
                insert new GroupMember(GroupId=g.Id, UserOrGroupId=UserInfo.getUserId());
            }
        }
        
        SL_SCTestData.createAccountAndContracts(1, 0);
        Account a = SL_SCTestData.testAccounts[0];
        
        Test.startTest();
        Contact c = new Contact(FirstName='Trig', LastName='Path', Email='trigger@test.org', AccountId=a.Id);
        insert c; 
        Test.stopTest(); 
        
        Contact got = [
            SELECT Validity_Verify__Checked__c, Validity_Verify__Status__c
            FROM Contact WHERE Id = :c.Id
        ];
        System.assertEquals(true, got.Validity_Verify__Checked__c, 'trigger path should set checked');
    }
    
    @IsTest
    static void test_runBriteVerifyCheck_direct() {
        Test.setMock(HttpCalloutMock.class, new BriteVerifyHttpMock());
        List<BriteVerifyResponse> res =
            TC_ContactRelatedObjUpdate.runBriteVerifyCheck(new Set<String>{ 'cover@test.org' });
        System.assertEquals(1, res.size(), 'one response expected from mock');
    }
}