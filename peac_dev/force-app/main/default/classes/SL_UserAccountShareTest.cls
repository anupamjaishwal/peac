@isTest
public with sharing class SL_UserAccountShareTest {
    @TestSetup
    static void makeData(){
        SL_SCTestData.createAccountAndContracts(2, 1);
        List<Account> theAccounts = SL_SCTestData.testAccounts;
        Account portalAccount = theAccounts[1];
        SL_SCTestData.createOpportunitiesAndAssets(theAccounts[0].Id, 1, 1);
        Test.startTest();
        portalAccount.recordTypeId = SL_SCTestData.DEALER_ACC;
        portalAccount.Waiting_To_Be_Sent_To_Bridgeware__c = true;
        update portalAccount;
        System.runAs(SL_SCTestData.testUser){
            SL_SCTestData.createDPDataForUser(portalAccount);
            SL_SCTestData.createDPDataForUser(portalAccount);
        }
        Test.stopTest();
    }

    @isTest
    public static void sendIt() {
        List<Account> theAccounts = [SELECT Id FROM Account LIMIT 2];
        User testAdminUser = [SELECT Id, userName FROM User WHERE UserName = 'service.admin.test.user@silverlinecrm.com' LIMIT 1];
        List<User> portalUsers = [SELECT Id, userName FROM User WHERE UserName LIKE 'Portal.SL.test.user%@silverlinecrm.com'];
        Test.startTest();
        System.runAs(testAdminUser){
            List<AccountShare> sharesToDelete = new List<AccountShare>{
                new AccountShare(AccountAccessLevel = 'Edit', OpportunityAccessLevel = 'Edit', CaseAccessLevel = 'Read',
                        RowCause = 'Manual', AccountId = theAccounts[0].Id, UserOrGroupId = portalUsers[0].Id)};
            // insert sharesToDelete;
            List<AccountShare> sharesToAdd = new List<AccountShare>{
                new AccountShare(AccountAccessLevel = 'Edit', OpportunityAccessLevel = 'Edit', CaseAccessLevel = 'Read',
                        RowCause = 'Manual', AccountId = theAccounts[1].Id, UserOrGroupId = portalUsers[0].Id)};
            List<UserShare> userSharesToInsert = new List<UserShare>{
                new UserShare(UserAccessLevel = 'Read', RowCause = 'Manual', UserId = portalUsers[0].Id, UserOrGroupId = portalUsers[1].Id)
            };
            List<UserShare> userSharesToDelete = new List<UserShare>{
                new UserShare(UserAccessLevel = 'Read', RowCause = 'Manual', UserId = portalUsers[0].Id, UserOrGroupId = portalUsers[1].Id)
            };
            insert sharesToDelete;
            insert userSharesToDelete;
            System.enqueueJob(new SL_UserAccountShareQ(sharesToAdd, sharesToDelete, userSharesToInsert, userSharesToDelete));
        }
        // DP-1616 Misael Romero
        // List<TC_Origination__Checklist__Share> checklistSharesToInsert = new List<TC_Origination__Checklist__Share>{
        //     new TC_Origination__Checklist__Share(AccessLevel = 'Edit', RowCause = 'Manual', ParentId = testChecklist.Id, UserOrGroupId = u.Id)
        // };
        // List<TC_Origination__Checklist__Share> checklistSharesToDelete = new List<TC_Origination__Checklist__Share>{
        //     new TC_Origination__Checklist__Share(AccessLevel = 'Edit', RowCause = 'Manual', ParentId = testChecklist.Id, UserOrGroupId = u.Id)
        // };
        // System.enqueueJob(new SL_UserAccountShareQ(checklistSharesToInsert, checklistSharesToDelete));
        List<String> dealerAccountIds = new List<String>();
        dealerAccountIds.add(theAccounts[1].Id);
        System.enqueueJob(new SL_UserAccountShareQ('Contract__Share', dealerAccountIds));
        System.enqueueJob(new SL_UserAccountShareQ('OpportunityShare', dealerAccountIds));
        System.enqueueJob(new SL_UserAccountShareQ('AccountShare'));
        System.enqueueJob(new SL_UserAccountShareQ('dealerAccountShare', new List<Id>{theAccounts[1].Id}));
        User testUser = [SELECT Id FROM User WHERE Username = 'service.admin.test.user@silverlinecrm.com' LIMIT 1];
        SL_SCTestData.testUser = testUser;
        // User dpUser = SL_SCTestData.createDPUser(theAccounts[0].Id);
        // SL_SCTestData.createDPDataForUser(portalAccount);
        Map<String, List<Id>> userIdsByGroup = new Map<String, List<Id>>{'Dealer_Admins' => new List<Id>{testUser.Id}, 'Non_XBS_OEG_Dealer_Manager' => new List<Id>{testUser.Id}};
        List<Id> userIdsToUngroup = new List<Id>();
        System.enqueueJob(new SL_UserAccountShareQ(userIdsByGroup, userIdsToUngroup));
        userIdsToUngroup.add(testUser.Id);
        System.enqueueJob(new SL_UserAccountShareQ(userIdsByGroup, userIdsToUngroup));
        Test.stopTest();
    }
}