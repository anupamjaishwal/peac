/** @author : Northteq Consulting, Inc.
 * @date : 11/23/20
 * @description: Test Class for TC_StageToClearValidation
 *
 */
@IsTest
public with sharing class TC_StageToClearValidationTest {

    @TestSetup
    static void setup() {
Test.startTest();
        SL_SCTestData.createAccountAndContracts(1, 1);
        Account acc = SL_SCTestData.testAccounts[0];
Test.stopTest();
        SL_SCTestData.createOpportunitiesAndAssets(acc.Id, 1, 1);
        Opportunity opp = SL_SCTestData.testOpportunities[0];
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Express Quote').getRecordTypeId();
        opp.Name = 'Test Opportunity';
        opp.AccountId = acc.Id;
        opp.StageName = 'Quote';
        opp.Primary_Source__c = 'Customer Inbound - Call';
        opp.CloseDate = System.today();
        opp.Account_Business_City__c = 'Test';
        opp.Account_Business_Country__c = 'Test2';
        opp.Account_Business_State_Province__c = 'PA';
        opp.Account_Business_Street__c ='Test4';
        opp.Account_Business_Street2__c = 'Test5';
        opp.Account_Business_Zip_Postal_Code__c = 'Test6';

        update opp;
    }

    @IsTest
    static void testAdvanceStageWithoutClearing() {

        Opportunity opp = [SELECT Id, Name, StageName FROM Opportunity WHERE Name = 'Test Opportunity'];

        TC_Origination__Checklist_Template__c template = new TC_Origination__Checklist_Template__c();
        template.Name = 'test template';
        insert template;

        TC_Origination__Checklist__c checklist = new TC_Origination__Checklist__c();
        checklist.Name = 'test checklist';
        checklist.TC_Origination__Opportunity__c = opp.Id;
        checklist.TC_Origination__Checklist_Template__c = template.Id;
        Test.startTest();
        insert checklist;

        TC_Origination__Checklist_Item_with_Attachments__c item = new TC_Origination__Checklist_Item_with_Attachments__c();
        item.Name = 'test item';
        item.TC_Origination__Stage_to_Clear__c = 'Quote';
        item.TC_Origination__Checklist__c = checklist.Id;
        item.TC_Origination__Included__c = true;
        item.TC_Origination__Checklist_s_Opportunity__c = opp.Id;
        insert item;

        opp.StageName = 'Application';
        try {
            opp.Equipment_Cost__c = 10000;
            opp.Equipment_Description__c = 'test';
            opp.Terms__c = 60;
            update opp;
        } catch (Exception e) {
            System.debug('Exception caught! ' + e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void testAdvanceStageWithClearing() {

        Opportunity opp = [SELECT Id, Name, StageName FROM Opportunity WHERE Name = 'Test Opportunity'];
        // opp.Equipment_Cost__c = 10000;
        opp.Equipment_Description__c = 'test';
        opp.Terms__c = 60;

        TC_Origination__Checklist_Template__c template = new TC_Origination__Checklist_Template__c();
        template.Name = 'test template';
        insert template;

        TC_Origination__Checklist__c checklist = new TC_Origination__Checklist__c();
        checklist.Name = 'test checklist';
        checklist.TC_Origination__Opportunity__c = opp.Id;
        checklist.TC_Origination__Checklist_Template__c = template.Id;
        Test.startTest();
        insert checklist;

        TC_Origination__Checklist_Item_with_Attachments__c item = new TC_Origination__Checklist_Item_with_Attachments__c();
        item.Name = 'test item';
        item.TC_Origination__Stage_to_Clear__c = 'Quote';
        item.TC_Origination__Checklist__c = checklist.Id;
        item.TC_Origination__Included__c = true;
        item.TC_Origination__Checklist_s_Opportunity__c = opp.Id;
        item.TC_Origination__Primary_Reviewer__c = true;
        insert item;

        opp.StageName = 'Application';

        update opp;
        Test.stopTest();
    }
}