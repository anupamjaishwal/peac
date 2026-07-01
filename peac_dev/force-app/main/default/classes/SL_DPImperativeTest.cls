@isTest
public with sharing class SL_DPImperativeTest {
    @isTest
    public static void general() {
        SL_SCTestData.createAccountAndContracts(2,2);
        Account portalAccount = SL_SCTestData.testAccounts[0];
        User u = null;
        System.runAs(SL_SCTestData.testUser){
            u = SL_SCTestData.createDPDataForUser(portalAccount);
            List<Contract__c> contracts = SL_SCTestData.testContracts;
            contracts[2].Dealer_Name__c = SL_SCTestData.dealerAccountId;
            contracts[3].Dealer_Name__c = SL_SCTestData.dealerAccountId;
            update contracts;
        }
        List<Contract__c> activeContracts = [SELECT Total_Amount_Due__c, Is_Active__c, Status__c, Dealer_Name__c, Customer__c
        FROM Contract__c  
        WHERE Dealer_Name__c = :portalAccount.Id AND Is_Active__c = true AND Customer__c = :SL_SCTestData.testAccounts[1].Id];
        String result;
        Test.startTest();
        System.runAs(u){
            result = SL_DPImperative.hubExecute('getCustomerSummary', new List<String>{String.valueOf(SL_SCTestData.testAccounts[1].Id)});
            portalAccount.Pre_Delivery_20k_Trial__c = false;
            List<Account> accLst = new List<Account>{portalAccount};
            SL_DPImperative.updateDealerAccounts(accLst);
        }
        Test.stopTest();
        System.debug('result: ' + result);
        List<Account> accountsAfter = [SELECT Id, Pre_Delivery_20k_Trial__c FROM Account WHERE Id = :portalAccount.Id];
        System.Assert.areEqual(false, accountsAfter[0].Pre_Delivery_20k_Trial__c);
    }

    @isTest
    static void testXBSEmail(){
        SL_SCTestData.createAccountAndContracts(1, 1);
        SL_SCTestData.createOpportunities(SL_SCTestData.testAccounts[0].Id, 1);
        Id adminId=[SELECT id, name FROM profile WHERE name='System Administrator'].id;
        User theAdmin = SL_SCTestData.createExtraUser(adminId);
        Opportunity opp = SL_SCTestData.testOpportunities[0];
        list<Profile> cmsProfiles = [SELECT Id FROM Profile WHERE Name ='CMS'];
        User u = SL_SCTestData.createExtraUser(cmsProfiles[0].Id);
        opp.Program__c = 'XBS';
        // opp.StageName = 'Docs In';
        // opp.Opportunity_Status__c = 'Docs in - Pending review';
        opp.Assign_To_CMS_User__c = u.Id;
        Opportunity_Attachment__c oppAtt = new Opportunity_Attachment__c();
        oppAtt.Opportunity__c = opp.Id;
        oppAtt.Type__c = 'LC - Assignment of Proceeds';
        oppAtt.Name = 'Test.txt';
        Test.startTest();
        System.runAs(theAdmin){
            update opp;
            SL_DPImperative.adminInsert(new List<SObject> {oppAtt});
            SL_DPImperative.SendOnBaseEmailXBS(opp.Id);
        }
        Test.stopTest();
        
    }
}