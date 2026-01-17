/**
 * SAL-2778 Test class for TC_FraudRenderDecisionCtrl
 * Tests the Approved, Rejected, and More Info scenarios
 */
@IsTest
public with sharing class TC_FraudRenderDecisionCtrlTest {
    
    @TestSetup
    static void makeData(){
        String username = 'standardusertest123@northteq.com';

        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User u = new User(Alias = 'testuser', Email = 'sfdc@northteq.com', EmailEncodingKey='UTF-8',
                LastName = 'testing', FirstName = 'user', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles',
                Username = username, Doc_Fee_Exception_Approver__c = true);
        insert u;

        Account acc = new Account();
        acc.Name = 'testacc';
        acc.Business_Phone__c = '1111111111';
        insert acc;

        Opportunity opp = new Opportunity();
        opp.Name = 'testopp';
        opp.StageName = 'Decision';
        opp.CloseDate = Date.today()+5;
        opp.AccountId = acc.Id;
        opp.RecordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('CVG Decision').getRecordTypeId();
        opp.Assigned_Credit_User__c = u.Id;
        insert opp;
    }

    @IsTest
    static void testApproved() {

        User u = [SELECT Id FROM User WHERE Username = 'standardusertest123@northteq.com'];

        System.runAs(u) {
            Test.startTest();
            Id oppId = [SELECT Id FROM Opportunity][0].Id;
            TC_FraudRenderDecisionCtrl.renderDecision(oppId, 'Approved');
            Test.stopTest();
        }
    }

    @IsTest
    static void testMoreInfo() {

        User u = [SELECT Id FROM User WHERE Username = 'standardusertest123@northteq.com'];

        System.runAs(u) {
            Test.startTest();
            Id oppId = [SELECT Id FROM Opportunity][0].Id;
            TC_FraudRenderDecisionCtrl.renderDecision(oppId, 'More Info');
            Test.stopTest();
        }
    }

    @IsTest
    static void testRejected() {
        
        User u = [SELECT Id FROM User WHERE Username = 'standardusertest123@northteq.com'];
        
        System.runAs(u) {
            Test.startTest();
            Id oppId = [SELECT Id FROM Opportunity][0].Id;
            TC_FraudRenderDecisionCtrl.renderDecision(oppId, 'Rejected');
            Test.stopTest();
        }
    }

    @IsTest
    static void testNull() {

        User u = [SELECT Id FROM User WHERE Username = 'standardusertest123@northteq.com'];

        System.runAs(u) {
            Test.startTest();
            Id oppId = [SELECT Id FROM Opportunity][0].Id;
            TC_FraudRenderDecisionCtrl.renderDecision(oppId, null);
            Test.stopTest();
        }
    }

    @IsTest
    static void testBlank() {

        User u = [SELECT Id FROM User WHERE Username = 'standardusertest123@northteq.com'];

        System.runAs(u) {
            Test.startTest();
            Id oppId = [SELECT Id FROM Opportunity][0].Id;
            TC_FraudRenderDecisionCtrl.renderDecision(oppId, '');
            Test.stopTest();
        }
    }

    @IsTest
    static void testNonValue() {

        User u = [SELECT Id FROM User WHERE Username = 'standardusertest123@northteq.com'];

        System.runAs(u) {
            Test.startTest();
            Id oppId = [SELECT Id FROM Opportunity][0].Id;
            TC_FraudRenderDecisionCtrl.renderDecision(oppId, 'xyz');
            Test.stopTest();
        }
    }
}