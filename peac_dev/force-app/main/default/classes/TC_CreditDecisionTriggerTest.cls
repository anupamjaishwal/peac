/** @author : Tamarack Consulting, Inc.
 * @date : 1/30/20
 * @description: 
 *
 */
@IsTest
public with sharing class TC_CreditDecisionTriggerTest {

    @TestSetup
    static void setup() {

        List<Account> accountList = new List<Account>();

        Account franchiseeAccount = new Account(
                Name = 'TC_CreditDecisionTriggerTest Franchisee Account'
                , RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Franchisee Account').getRecordTypeId()
                , Business_Address__c = 'Test Address', Business_City__c = 'Test City', Business_State__c = 'MN', Business_Zip__c = '11111'
                , Account_EU_FS_SIC_Description__c = '8661'
                , Account_Months_In_Business__c = 13
        );
        accountList.add(franchiseeAccount);

        Account dealerAccount = new Account (
                Name = 'TC_CreditDecisionTriggerTest Dealer Account'
                , RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId()
                , Business_Address__c = 'Test Address', Business_City__c = 'Test City', Business_State__c = 'MN', Business_Zip__c = '11111'
                , Account_EU_FS_SIC_Description__c = '8661'
                , Preferred_Dealer_Level__c = '3'
                , Dealer_Number__c = '855331.7237'
                ,Equipment_Type__c = 'A/V (General)'
        );
        accountList.add(dealerAccount);

        insert accountList;

        Opportunity opp = new Opportunity(
                Name = 'TC_CreditDecisionTriggerTest'
                , StageName = 'Quote'
                , CloseDate = Date.today()
                , Last_Date_Scorex_Retrieved__c = Date.today()
                , RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Express Application').getRecordTypeId()
                , AccountId = franchiseeAccount.Id
                , Application__c = 'TestApplicationNumber'
                , Loan_Ready_To_Doc__c = 'Yes'
                , Lessor__c = 201
                , Months_Verified__c = 12
        );
		Test.startTest();
        insert opp;
        

        Dealer__c dealer = new Dealer__c(
                Opportunity__c = opp.Id
                , Primary_Dealer__c = TRUE
                , Dealer__c = dealerAccount.Id
        );
        
        insert dealer;
        Test.stopTest();

    }

    @IsTest
    static void testCreditRules1() {

        Opportunity opp = [SELECT Id, Region__c FROM Opportunity WHERE Name = 'TC_CreditDecisionTriggerTest'];
        opp.Region__c = '001';
        Test.startTest();
        update opp;
        
        opp.StageName = 'Decision';
        opp.Decision_Status__c = 'A';
        opp.Reason_for_Approval__c = 'Approved with Supplemental Information';
        opp.Region__c = '000';
        opp.Lessor__c = 150;
        update opp;
        Test.stopTest();

    }

    @IsTest
    static void testCreditRules2() {

        Opportunity opp = [SELECT Id, Lessor__c FROM Opportunity WHERE Name = 'TC_CreditDecisionTriggerTest'];

        opp.Region__c = '001';
        //opp.Branch__c = 'Commercial Vehicle Group';
        opp.Program_Type__c = null;
        opp.Credit_Amount__c = 30000;
        Test.startTest();
        update opp;
        TC_RecursiveTriggerHelper.cdrRules = false;

        opp.StageName = 'Decision';
        opp.Decision_Status__c = 'A';
        opp.Reason_for_Approval__c = 'Approved with Supplemental Information';
        opp.Months_Verified__c = 24;
        opp.Required_Adv_Payments__c = null;
        opp.Terms__c = 35;
        opp.Program_Type__c = '1100';
        opp.Credit_Amount__c = 20000;
        update opp;

        Test.stopTest();
    }

    @IsTest
    static void testCDR001_StipNew() {

        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'TC_CreditDecisionTriggerTest'];
        System.debug('TEST CLASS LESSOR HERE: '+[SELECT Id, Lessor__c FROM Opportunity WHERE Name = 'TC_CreditDecisionTriggerTest'].Lessor__c);

        opp.Region__c = '001';
        //opp.Branch__c = 'Commercial Vehicle Group';
        opp.Program_Type__c = null;
        opp.Credit_Amount__c = 30000;
        Test.startTest();
        update opp;
        System.debug('TEST CLASS LESSOR HERE: '+[SELECT Id, Lessor__c FROM Opportunity WHERE Name = 'TC_CreditDecisionTriggerTest'].Lessor__c);

        // Reset the recurisve trigger check (since tests are in the same execution)
        TC_RecursiveTriggerHelper.cdrRules = false;

        
        opp.StageName = 'Decision';
        opp.Decision_Status__c = 'A';
        opp.Stipulations__c = 'Corporate Officer to Sign';

        opp.Reason_for_Approval__c = 'Approved with Supplemental Information';
        opp.Months_Verified__c = 24;
        opp.Required_Adv_Payments__c = null;
        opp.Terms__c = 35;
        opp.Program_Type__c = '1100';
        opp.Credit_Amount__c = 20000;
        update opp;
        opp = [SELECT Id, Stipulations__c, Lessor__c FROM Opportunity WHERE Name = 'TC_CreditDecisionTriggerTest'];
        System.debug('TEST CLASS LESSOR HERE: '+ opp.Lessor__c);
        System.debug('TEST CLASS Stipulations HERE: '+ opp.Stipulations__c);
        System.assert(opp.Stipulations__c.contains('Auto ACH Required'));
        // System.assert(opp.Stipulations__c.contains('ACH Guarantee Form'));

        Test.stopTest();
    }


    @IsTest
    static void testCDR004_StipulationsWithExistingStips() {

        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'TC_CreditDecisionTriggerTest'];
        // System.debug('TEST CLASS LESSOR HERE: '+[SELECT Id, Lessor__c FROM Opportunity WHERE Name = 'TC_CreditDecisionTriggerTest'].Lessor__c);

        opp.Region__c = '001';
        //opp.Branch__c = 'Commercial Vehicle Group';
        opp.Program_Type__c = null;
        opp.Credit_Amount__c = 30000;
        Test.startTest();
        update opp;
        // System.debug('TEST CLASS LESSOR HERE: '+[SELECT Id, Lessor__c FROM Opportunity WHERE Name = 'TC_CreditDecisionTriggerTest'].Lessor__c);

        // Reset the recurisve trigger check (since tests are in the same execution)
        TC_RecursiveTriggerHelper.cdrRules = false;

        
        // opp.StageName = 'Decision';
        opp.Decision_Status__c = 'A';
        // opp.Stipulations__c = 'Corporate Officer to Sign';

        // opp.Reason_for_Approval__c = 'Approved with Supplemental Information';
        // opp.Months_Verified__c = 24;
        // opp.Required_Adv_Payments__c = null;
        // opp.Terms__c = 35;
        opp.Program_Type__c = '1100';
        // opp.Credit_Amount__c = 20000;
        update opp;
        opp = [SELECT Id, Stipulations__c, Lessor__c FROM Opportunity WHERE Name = 'TC_CreditDecisionTriggerTest'];
        // System.debug('TEST CLASS LESSOR HERE: '+ opp.Lessor__c);
        // System.debug('TEST CLASS Stipulations HERE: '+ opp.Stipulations__c);
        System.assert(opp.Stipulations__c.contains('ACH Guarantee Form'));

        Test.stopTest();
    }

    @isTest 
    static void testCDR004_StipulationsNew() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'TC_CreditDecisionTriggerTest'];
        opp.Region__c = '001';
        //opp.Branch__c = 'Commercial Vehicle Group';
        opp.Program_Type__c = null;
        opp.Credit_Amount__c = 30000;
        Test.startTest();
        update opp;

        // Reset the recurisve trigger check (since tests are in the same execution)
        TC_RecursiveTriggerHelper.cdrRules = false;

        opp.StageName = 'Decision';
        opp.Decision_Status__c = 'A';
        opp.Reason_for_Approval__c = 'Approved with Supplemental Information';
        opp.Months_Verified__c = 24;
        opp.Required_Adv_Payments__c = null;
        opp.Terms__c = 35;
        opp.Program_Type__c = '1100';
        opp.Credit_Amount__c = 20000;
        update opp;
        opp = [SELECT Id, Stipulations__c, Lessor__c FROM Opportunity WHERE Name = 'TC_CreditDecisionTriggerTest'];
        System.assert(opp.Stipulations__c.contains('ACH Guarantee Form'));

        Test.stopTest();
    }
}