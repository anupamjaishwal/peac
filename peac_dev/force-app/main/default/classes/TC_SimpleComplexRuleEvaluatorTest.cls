/** @author : Tamarack Consulting, Inc.
 * @date : 11/30/20
 * @description: 
 *
 */
@IsTest
public with sharing class TC_SimpleComplexRuleEvaluatorTest {
    
      //// Start: Test class to cover codcoverage for decommision(SAL-4149) class-By Raja Sirivella
   static testmethod void test2(){
        Test.startTest();

       TC_SimpleComplexRuleEvaluator cs = new TC_SimpleComplexRuleEvaluator();
       cs.TC_SimpleComplexRuleEvaluator('test');

        Test.stopTest();
    }

  /*  @TestSetup
    static void setup() {
        Test.startTest();
        Account acc = new Account();
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
        acc.Name = 'Test account';
        acc.Business_Address__c = '123 Street St.';
        acc.Business_City__c = 'Minneapolis';
        acc.Business_State__c = 'MN';
        acc.Business_Zip__c = '55401';
        insert acc;

        Opportunity opp = new Opportunity();
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Express Quote').getRecordTypeId();
        opp.Name = 'Test opportunity';
        opp.AccountId = acc.Id;
        opp.StageName = 'Application';
        opp.Primary_Source__c = 'Customer Inbound - Call';
        opp.CloseDate = System.today();
        opp.Equipment_Cost__c = 10000;
        opp.Equipment_Description__c = 'test';
        opp.Terms__c = 60;
        insert opp;
        Test.stopTest();
    }

    @IsTest
    static void test() {

        Opportunity opp = [SELECT Id, Name, Lessor__c, Workflow_Type__c FROM Opportunity WHERE Name = 'Test opportunity'];
        opp.Lessor__c = 401;
        Test.startTest();
        update opp;
        Test.stopTest();

        System.debug('workflow type test: ' + opp.Workflow_Type__c);
    }  */
}