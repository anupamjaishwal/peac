@isTest
public with sharing class SL_DPPermissionsTest {
    private static final String OEG_DEALER_PROFILE = 'OEG Dealer';
    private static final String USERNAME = 'Portal.SL.test.user@silverlinecrm.com';
    private static final Id DEALER_ACC = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer_Vendor').getRecordTypeId();
    
    @isTest
    public static void general() {
        SL_SCTestData.createAccountAndContracts(2,1);
        SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[1].Id, 2, 1);
        Test.startTest();
        system.runAs(new user(ID = UserInfo.getUserID())){
            Account portalAccount = SL_SCTestData.testAccounts[0];
            User u = SL_SCTestData.createDPDataForUser(portalAccount);
            PermissionSet thePermission = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Dealer_Delegated_Admin'];
            PermissionSetAssignment thePSA = new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = thePermission.Id);
            insert thePSA;
            List<Opportunity> opps = SL_SCTestData.testOpportunities;
            for(Opportunity oneOpp:opps){
                oneOpp.Dealer_Account__c = portalAccount.Id;
            }
            update opps;
            SL_SCTestData.testContracts[1].Dealer_Name__c = portalAccount.Id;
            update SL_SCTestData.testContracts[1];
        }
        List<String> resultDealerIds = SL_DPPermissions.findMissingSharesByCount('Account');
        resultDealerIds = SL_DPPermissions.findMissingSharesByCount('Contract__c');
        resultDealerIds = SL_DPPermissions.findMissingSharesByCount('Opportunity');
        System.schedule('DP Permissions just test', '0 0 8 * * ?' , new SL_DPPermissionsSchedule());
        Test.stopTest();
    }
}