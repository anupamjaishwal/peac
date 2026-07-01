@isTest
public class SL_DPImperativeXBSEmailTest {
    @TestSetup
    static void setup(){        
        // SL_SCTestData.prepareFundingOpportunity();
        // User serviceAdmin = SL_SCTestData.testUser;
        
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
            insert oppAtt;
            SL_DPImperative.SendOnBaseEmailXBS(opp.Id);
        }
        Test.stopTest();
        
    }

}