@isTest
public with sharing class SL_DPSharingRecalcTest {
    @TestSetup
    static void makeData(){
        SL_SCTestData.createExternalHierarchy();
    }

    @isTest
    public static void sendContractBatch() {
        List<User> portalUsers = [SELECT Id, Contact.AccountId, userName, isPortalEnabled, IsActive, IsPrmSuperUser FROM User WHERE UserName LIKE 'Portal.SL.test.user%@silverlinecrm.com'];
        List<Contract__c> contracts = [SELECT Id, Dealer_Name__c FROM Contract__c];
        List<Opportunity> opps = [SELECT Id, Dealer_Account__c FROM Opportunity];
        List<Account> theAccounts = [SELECT Id, Name FROM Account];
        Account portalAccount = theAccounts[1];
        Test.startTest();
        contracts[0].Dealer_Name__c = portalAccount.Id;
        contracts[0].Dealer_User__c = portalUsers[0].Id;
        update contracts[0];
        Dealer__c testDealer = new Dealer__c(Opportunity__c = opps[0].Id, Dealer__c = portalAccount.Id,
            Funded__c = false, Primary_Dealer__c = true);
        insert testDealer;
        opps[0].Dealer_User__c = portalUsers[0].Id;
        update opps[0];
        List<String> dealerAccountIds = new List<String>();
        dealerAccountIds.add(theAccounts[1].Id);
        Database.executeBatch(new SL_DPSharingRecalcBatch('AccountShare', dealerAccountIds));
        Database.executeBatch(new SL_DPSharingRecalcBatch('Contract__Share', dealerAccountIds));
        Database.executeBatch(new SL_DPSharingRecalcBatch('OpportunityShare', dealerAccountIds));
        Database.executeBatch(new SL_DPSharingRecalcBatch('UserShare', true));
        Database.executeBatch(new SL_DPSharingRecalcBatch('UserShare', dealerAccountIds));
        SL_DPSharingRecalcBatch extraInstance = new SL_DPSharingRecalcBatch('Contract__Share', dealerAccountIds);
        List<Contract__Share> sharesToDelete = new List<Contract__Share>{
            new Contract__Share(AccessLevel = 'Read',
                    RowCause = 'Manual', ParentId = contracts[0].Id, UserOrGroupId = portalUsers[0].Id)};
        insert sharesToDelete;
        extraInstance.recalculateDeleteShares((List<SObject>)sharesToDelete);
        List<UserShare> userSharesToDelete = new List<UserShare>{
            new UserShare(UserAccessLevel = 'Read', RowCause = 'Manual', UserId = portalUsers[0].Id, UserOrGroupId = portalUsers[1].Id)
        };
        insert userSharesToDelete;
        extraInstance = new SL_DPSharingRecalcBatch('UserShare', dealerAccountIds);
        extraInstance.recalculateDeleteShares((List<SObject>)userSharesToDelete);
        extraInstance = new SL_DPSharingRecalcBatch('User', dealerAccountIds);
        extraInstance.recalculateInsertShares((List<SObject>)portalUsers);
        Database.executeBatch(new SL_DPSharingRecalcBatch((List<SObject>)sharesToDelete, 'Contract__c'));// insert remaining
        List<SObject> allTheRecords = new List<SObject>();
        for(Integer i = 0; i < 20001; i++){
            allTheRecords.add(new Contract__Share(AccessLevel = 'Read',
                RowCause = 'Manual', ParentId = contracts[0].Id, UserOrGroupId = portalUsers[0].Id));
        }
        List<List<SObject>> partitionedList = SL_DPSharingRecalcBatch.splitDMLList(allTheRecords);
        Test.stopTest();
        System.Assert.areEqual(10000, partitionedList[0].size(), 'first element must have 10000 records');
        System.Assert.areEqual(1, partitionedList[2].size(), 'third element must have 1 record');
    }
}