@isTest
public with sharing class SL_DealerPortalLogActivityTest {
    @isTest
    public static void scenario1() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        Account acc = SL_SCTestData.testAccounts[0];
        SL_SCTestData.createOpportunities(acc.Id, 1);
        Test.startTest();
        System.runAs(SL_SCTestData.testUser){
            SL_DealerPortalLogActivity.runFromLWC('Create Application', SL_SCTestData.testOpportunities[0].Id);
            SL_DealerPortalLogActivity.runFromLWC('Create Buyouts', SL_SCTestData.testContracts[0].Id);
            SL_DealerPortalLogActivity.FlowInput input = new SL_DealerPortalLogActivity.FlowInput();
            input.actionType = 'Export Report';
            input.recordId = null;
            input.actualU  = SL_SCTestData.testUser.Id;
            input.details  = 'CPC Reports has ben executed.';
            input.loginHistoryId = null;
            input.sessionKey = 'audP4x18k+ueq89Q';
            SL_DealerPortalLogActivity.saveActivityLogDP(new List<SL_DealerPortalLogActivity.FlowInput>{ input });
            SL_DealerPortalLogActivity.runFromLWC('Generate Documents', SL_SCTestData.testOpportunities[0].Id);
            SL_DealerPortalLogActivity.runFromLWC('Upload Meter Reads', '666666.4444');
        }
        Test.stopTest();
        // List<Dealer_Portal_Activity__c> dpActivityAfter = [SELECT Id, Delegated_User__c, Delegated_User__r.Name, User__c, user__r.name, CreatedDate, Details__c, Session_Key__c, Type__c, Contract__c,Dealer_Account__c, Opportunity__c
        //     FROM Dealer_Portal_Activity__c];
        // System.Assert.areEqual(5, dpActivityAfter.size(), 'created one activity per type.');
    }
}