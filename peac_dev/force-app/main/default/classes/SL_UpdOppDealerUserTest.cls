@isTest
public with sharing class SL_UpdOppDealerUserTest {
    @TestSetup
    static void makeData(){
        SL_SCTestData.createAccountAndContracts(1, 1);
        Account customer = SL_SCTestData.testAccounts[0];
        User dpUser = null;
        User dpUser2 = null;
        System.runAs(SL_SCTestData.testUser){
            List<User> dpUsers = SL_SCTestData.createDPUsers(2, 1);
            dpUser = dpUsers[0];
            dpUser2 = dpUsers[1];
        
            List<Opportunity> opps = SL_SCTestData.createOpportunities(customer.Id, 2);
            Test.startTest();
            opps[0].Portal_User_ID__c = 'PUDA-';
            update opps[0];
            insert new List<OpportunityContactRole>{new OpportunityContactRole(Role = 'Dealer Sales Contact', OpportunityId = opps[0].Id, ContactId = dpUser.ContactId ),
                new OpportunityContactRole(Role = 'Dealer Primary Contact', OpportunityId = opps[1].Id, ContactId = dpUser2.ContactId)};
            Test.stopTest();
        }
    }

    @isTest()
    public static void justRun() {
        List<User> portalUsers = [SELECT Id, Contact.AccountId, Contact.Account.Name, userName, IsActive 
            FROM User WHERE UserName LIKE 'Portal.SL.test.user%@silverlinecrm.com'];
        User dpUser = portalUsers[0];
        User dpUser2 = portalUsers[1];
        Account portalAccount = dpUser.Contact.Account;
        Account portalAccount2 = dpUser2.Contact.Account;
        List<Id> activated = new List<Id>();
        activated.add(dpUser.ContactId);
        activated.add(dpUser2.ContactId);
        Test.startTest();
        User u = [SELECT Id, userName FROM User WHERE UserName ='service.admin.test.user@silverlinecrm.com'];
        List<Opportunity> opps = [SELECT Id, Dealer_Account__c, Dealer_User__c FROM Opportunity];
        insert new List<Dealer__c>{ new Dealer__c(Opportunity__c = opps[0].Id, Primary_Dealer__c = true, Dealer__c = portalAccount.Id),
            new Dealer__c(Opportunity__c = opps[1].Id, Primary_Dealer__c = true, Dealer__c = portalAccount2.Id)
        };
        System.runAs(u){
            Database.executeBatch(new SL_UpdOppDealerUserBatch(activated));
            SL_UpdOppDealerUserBatch batchInstance = new SL_UpdOppDealerUserBatch(activated);
            batchInstance.allErrors.add('test only');
            Database.executeBatch(batchInstance);
        }
        Test.stopTest();
        //system.debug('queries 4: ' + Limits.getQueries());
        //List<Opportunity> oppsAfter = [SELECT Id, Dealer_Account__c, Dealer_User__c FROM Opportunity];
        //System.Assert.areEqual(dpUser.Id, oppsAfter[0].Dealer_User__c, 'When activating user if opp.Portal_User_ID__c is PUDA- and user is Dealer Sales Contact then stamp as Dealer_User__c');
        //System.Assert.areEqual(dpUser2.Id, oppsAfter[1].Dealer_User__c, 'When activating user if opp.Portal_User_ID__c is SF- and user is Dealer Primary Contact then stamp as Dealer_User__c');
    }
}