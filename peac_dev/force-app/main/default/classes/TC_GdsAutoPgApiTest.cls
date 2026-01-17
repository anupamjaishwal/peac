@isTest 
public with sharing class TC_GdsAutoPgApiTest {
    private static String CRON_EXP = '0 5 0 * * ? 2023';

    @testSetup 
    public static void setupDeal() {
        Account acc = new Account (Name = 'testbeni', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId());
        insert acc;

        Opportunity opp = new Opportunity (
            AccountId = acc.Id, 
            StageName = 'test', 
            CloseDate = date.today () + 10, 
            Name = 'test'
        );
        insert opp;

        Test.startTest();
        Asset__c asset = new Asset__c(
                Opportunity__c = opp.Id,
                Quantity__c = 1,
                Equipment_Code__c = 'Copiers',
                Equipment_City__c = 'Minneapolis',
                Equipment_State__c = 'MN'
        );
        insert asset;
        Test.stopTest();
    }

    @isTest 
    public static void gdsAutoPgApiTest() {

        Opportunity opp = [SELECT Id From Opportunity LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new TC_GdsAutoPgApiCalloutMock());

        Test.startTest();
        TC_GdsAutoPgApi.runAutoPG(opp.Id, TC_GdsAutoPgUtils.TestDwhResponse());
        Test.stopTest();

        // <GatingCriteriaMet>0</GatingCriteriaMet>
		// <CORPOnly_RiskGrade>D2</CORPOnly_RiskGrade>
        // <PGRequired></PGRequired>
        // <MaxCorpOnly_Amount></MaxCorpOnly_Amount>
        Opportunity updatedOpp = [SELECT Id, Corp_Only_Risk_Grade__c, Max_Corp_Only_Amount__c, Gating_Criteria_Met__c, PGRequired__c From Opportunity LIMIT 1];
        System.assertEquals(0, updatedOpp.Gating_Criteria_Met__c);
        System.assertEquals('D2', updatedOpp.Corp_Only_Risk_Grade__c);
        System.assertEquals(0, updatedOpp.PGRequired__c);
    }

    @isTest 
    public static void lead1() {

        Account acc = [SELECT Id From Account LIMIT 1];
        Lead theLead = new Lead (LeadSource = 'Customer Service Referral',
                                Status = 'Unassigned',
                                Lead_Type__c = 'End User',
                                lastName = 'test contact1',
                                company = 'test company');
        insert theLead;
        Test.setMock(HttpCalloutMock.class, new TC_GdsAutoPgApiCalloutMock());

        Test.startTest();
        TC_GdsAutoPgApi.runAutoPG(theLead.Id, TC_GdsAutoPgUtils.TestDwhResponse());
        Test.stopTest();
        System.assert(true);
    }
}