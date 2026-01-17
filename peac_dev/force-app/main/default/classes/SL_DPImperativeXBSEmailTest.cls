@isTest
public class SL_DPImperativeXBSEmailTest {
    @TestSetup
    static void setup(){        
        SL_SCTestData.prepareFundingOpportunity();
        User serviceAdmin = SL_SCTestData.testUser;
        
    }
    
    @isTest
    static void testXBSEmail(){
        User theAdmin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND FirstName = 'Test Owner' LIMIT 1];
        Opportunity opp = [Select Id, StageName From Opportunity][2];       
        
        opp.Program__c = 'XBS';
        opp.StageName = 'Docs In';
        opp.Opportunity_Status__c = 'Docs in - Pending review';
        Opportunity_Attachment__c oppAtt = new Opportunity_Attachment__c();
        oppAtt.Opportunity__c = opp.Id;
        oppAtt.Type__c = 'LC - Assignment of Proceeds';
        oppAtt.Name = 'Test.txt';
        Test.startTest();
        System.runAs(theAdmin){
            update opp;
        }
        insert oppAtt;
        SL_DPImperative.SendOnBaseEmailXBS(opp.Id);
        Test.stopTest();
    }

}