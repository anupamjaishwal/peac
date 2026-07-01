@isTest
public with sharing class SL_DealerPortalCAAllowSaveTest {
    @TestSetup
    static void makeData(){
        SL_SCTestData.createAccountAndContracts(3,1);
        List<Contact> testCon = new List<Contact>();
        List<Contact> result;
        testCon.add(SL_SCTestData.testContacts[1]);
        Test.startTest();
        User dpUser = null;
        User dpUser2 = null;
        User sysAdmin = SL_SCTestData.createExtraUser([SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id);
        Account portalAccount = SL_SCTestData.testAccounts[0];
        Account portalAccount2 = SL_SCTestData.testAccounts[2];
        Id runningUser = System.UserInfo.getUserId();
        System.runAs(SL_SCTestData.testUser){
            SL_SCTestData.createEmailTemplates(runningUser);
            dpUser = SL_SCTestData.createDPDataForUser(portalAccount);
            dpUser2 = SL_SCTestData.createDPDataForUser(portalAccount2);
        }
        List<Opportunity> updatedOpp = null;
        System.runAs(dpUser){
            SL_DealerPortalCreateApp.shareAccountWithUser(SL_SCTestData.testAccounts[1].Id);
        }
        Test.stopTest();
        System.runAs(dpUser){
            SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[1].Id, 1, 1);
        }
    }

    @isTest
    public static void changeDealerUser(){
        List<User> portalUsers = [SELECT Id, Contact.AccountId, userName, isPortalEnabled, IsActive, IsPrmSuperUser FROM User WHERE UserName LIKE 'Portal.SL.test.user%@silverlinecrm.com'];
        List<Contact> contracts = [SELECT Id, AccountId FROM Contact];
        List<Opportunity> opps = [SELECT Id, Dealer_Account__c FROM Opportunity];
        Test.startTest();
        User dpUser = portalUsers[0];
        User dpUser2 = portalUsers[1];
        
        List<Opportunity> updatedOpp = null;
        SL_DealerPortalCAOppInfo.shareOppWithUser(opps);
        System.runAs(dpUser){
            SL_DealerPortalCAOppInfo.shareOppWithUser(opps);
            Opportunity opp = opps[0];
            List<SL_DealerPortalCAAllowSave.AllowSaveParams> allowSaveParams = new List<SL_DealerPortalCAAllowSave.AllowSaveParams>();
            SL_DealerPortalCAAllowSave.AllowSaveParams parameter = new SL_DealerPortalCAAllowSave.AllowSaveParams();
            parameter.opportunity = opp;
            allowSaveParams.add(parameter);
            parameter.opportunity.Dealer_Account__c = null;
            parameter.opportunity.Dealer_User__c = null;
            parameter.isToUpdateOpp = false;
            updatedOpp = SL_DealerPortalCAAllowSave.updateOpp(allowSaveParams);
            parameter.opportunity = opp.clone(false,false,false);
            parameter.isToUpdateOpp = true;
            allowSaveParams.add(parameter);
            List<Opportunity> createdOpp = SL_DealerPortalCAAllowSave.updateOpp(allowSaveParams);
            // parameter.opportunity.Id = opp.Id; // error with dealer somehow, when having time fix it
            // SL_DealerPortalCAAllowSave.updateOpp(allowSaveParams);
        }
        Test.stopTest();
        System.Assert.areEqual(updatedOpp[0].Dealer_User__c, dpUser.Id, 'dealer User must have been replaced by running user');
        System.Assert.areEqual(updatedOpp[0].Dealer_Account__c, dpUser.Contact.AccountId, 'dealer Account must also have been replaced');
    }

}