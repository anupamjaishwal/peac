@isTest
public with sharing class SL_RuleEngineTest {
    @isTest
    public static void scenario1() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[0].Id, 1, 1);
        List<TCRE__Rule_Config__c> configs = new List<TCRE__Rule_Config__c>();
        configs.add(new TCRE__Rule_Config__c(TCRE__Priority__c = 1, TCRE__SObject_Name__c = 'Opportunity'));
        configs.add(new TCRE__Rule_Config__c(TCRE__Priority__c = 1, TCRE__SObject_Name__c = 'Opportunity', TCRE__Evaluation_Logic_Picklist__c = 'Any (OR)'));
        configs.add(new TCRE__Rule_Config__c(TCRE__Priority__c = 1, TCRE__SObject_Name__c = 'Opportunity', TCRE__Evaluation_Logic_Picklist__c = 'Custom',
            TCRE__Custom_Rule_Evaluation_Logic__c = '1 AND (2 OR 3 OR 4 OR 5 OR 6 OR 7 OR 8 OR 9) '));
        insert configs;
        List<RateCard__c> rcs = new List<RateCard__c>();
        rcs.add(new RateCard__c(Name = 'Mtest0', Entry_Criteria__c = configs[0].Id));
        rcs.add(new RateCard__c(Name = 'Mtest1', Entry_Criteria__c = configs[1].Id));
        rcs.add(new RateCard__c(Name = 'Mtest2', Entry_Criteria__c = configs[2].Id));
        insert rcs;
            
        Rate_Card_Column__c col = new Rate_Card_Column__c();
        col.Rate_Card__c = rcs[0].Id;
        col.Column_Criteria__c = configs[0].Id;
        insert col;
        
        Rate_Card_Row__c row = new Rate_Card_Row__c(); 
        row.Rate_Card__C = rcs[0].Id;
        row.Row_Criteria__c = configs[0].Id;
        insert row;

        List<TCRE__Rule_Condition__c> conds = new List<TCRE__Rule_Condition__c>();
        conds.add(new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'CreatedDate', TCRE__Operator__c = '>', TCRE__Value__c = '12/12/2010', TCRE__Rule_Config__c = configs[0].Id));
        conds.add(new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Name', TCRE__Operator__c = '=', TCRE__Value__c = 'false', TCRE__Rule_Config__c = configs[0].Id));
        conds.add(new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Name', TCRE__Operator__c = 'Contains', TCRE__Value__c = 'test', TCRE__Rule_Config__c = configs[0].Id));
        conds.add(new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'StageName', TCRE__Operator__c = '!=', TCRE__Value__c = 'test', TCRE__Rule_Config__c = configs[0].Id));
        conds.add(new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Approved_Amount__c', TCRE__Operator__c = '>', TCRE__Value__c = '23400', TCRE__Rule_Config__c = configs[0].Id));
        conds.add(new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Amount', TCRE__Operator__c = '<', TCRE__Value__c = '-234.56', TCRE__Rule_Config__c = configs[0].Id));
        
        conds.add(new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Account.CCAN__c', TCRE__Operator__c = '=', TCRE__Value__c = '12260216', TCRE__Rule_Config__c = configs[1].Id));
        conds.add(new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'StageName', TCRE__Operator__c = '=', TCRE__Value__c = 'Proposal', TCRE__Rule_Config__c = configs[1].Id));
        conds.add(new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Appealed__c', TCRE__Operator__c = '=', TCRE__Value__c = 'true', TCRE__Rule_Config__c = configs[1].Id));
        conds.add(new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Appealed__c', TCRE__Operator__c = '!=', TCRE__Value__c = 'false', TCRE__Rule_Config__c = configs[1].Id));
        conds.add(new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Approved_Amount__c', TCRE__Operator__c = '!=', TCRE__Value__c = '1000', TCRE__Rule_Config__c = configs[1].Id));
        conds.add(new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Funded_Amount__c', TCRE__Operator__c = '=', TCRE__Value__c = '14', TCRE__Rule_Config__c = configs[1].Id));

        conds.add(new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Approved_Amount__c', TCRE__Operator__c = '>=', TCRE__Value__c = '12.26', TCRE__Rule_Config__c = configs[2].Id));
        conds.add(new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Dealer_Account__r.Dealer_Tier__c', TCRE__Operator__c = '=', TCRE__Value__c = 'Standard', TCRE__Rule_Config__c = configs[2].Id));
        conds.add(new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Opportunity_Installed_Date__c', TCRE__Operator__c = '=', TCRE__Value__c = '12/12/2010', TCRE__Rule_Config__c = configs[2].Id));
        conds.add(new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Additional_Docs__c', TCRE__Operator__c = 'Includes', TCRE__Value__c = 'Proposal;notIn', TCRE__Rule_Config__c = configs[2].Id));
        conds.add(new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Opportunity_Installed_Date__c', TCRE__Operator__c = '<', TCRE__Value__c = '12/12/2010', TCRE__Rule_Config__c = configs[2].Id));
        conds.add(new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Opportunity_Installed_Date__c', TCRE__Operator__c = '<=', TCRE__Value__c = '12/12/2010', TCRE__Rule_Config__c = configs[2].Id));
        conds.add(new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Opportunity_Installed_Date__c', TCRE__Operator__c = '!=', TCRE__Value__c = '12/12/2010', TCRE__Rule_Config__c = configs[2].Id));
        conds.add(new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Opportunity_Installed_Date__c', TCRE__Operator__c = '>=', TCRE__Value__c = '12/12/2010', TCRE__Rule_Config__c = configs[2].Id));
        conds.add(new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Amount', TCRE__Operator__c = '<=', TCRE__Value__c = '1201.00', TCRE__Rule_Config__c = configs[2].Id));
        insert conds;

        Test.startTest();
        SL_RuleEngine rateCardRE = new SL_RuleEngine();
        Set<Id> objIds = new Set<Id>();
        Id oppId = SL_SCTestData.testOpportunities[0].Id;
        objIds.add(oppId);
        rateCardRE.logicObjectIds = objIds;
        rateCardRE.ruleObjectType = 'RateCard__c';
        rateCardRE.testRuleConditions();
        SL_RuleEngine rateRowRE = new SL_RuleEngine();
        rateRowRE.logicObjects = new List<SObject>{SL_SCTestData.testOpportunities[0]};
        rateRowRE.logicObjectUId = 'Id';
        rateRowRE.ruleConfigIds = new Set<Id>{configs[0].Id};
        rateRowRE.ruleObjectType = 'Rate_Card_Row__c';
        rateRowRE.testRuleConditions();
        Test.stopTest();
        System.Assert.isFalse(rateCardRE.ruleResults.get(oppId).get(configs[0].Id));
        System.Assert.isTrue(rateCardRE.ruleResults.get(oppId).get(configs[1].Id));
        System.Assert.isTrue(rateCardRE.ruleResults.get(oppId).get(configs[2].Id));
    }

    @isTest
    public static void noLookupException() {
        Test.startTest();
        SL_RuleEngine rateCardRE = new SL_RuleEngine();
        rateCardRE.ruleObjectType = 'Lead';
        try{rateCardRE.testRuleConditions();}catch(Exception e){
            System.Assert.areEqual('Rule Object Lookup Field Not Found on sObject Type [Lead]', e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    public static void apexOverrideException() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[0].Id, 1, 1);
        TCRE__Rule_Config__c config = new TCRE__Rule_Config__c(TCRE__Priority__c = 1, TCRE__SObject_Name__c = 'Opportunity');
        insert config;
        insert new RateCard__c(Name = 'Mtest3', Entry_Criteria__c = config.Id);
        insert new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'StageName', TCRE__Operator__c = '!=', TCRE__Value__c = 'test', 
            TCRE__sObject_Override_Apex__c = 'testapex', TCRE__Rule_Config__c = config.Id);
        Test.startTest();
        SL_RuleEngine rateCardRE = new SL_RuleEngine();
        Set<Id> objIds = new Set<Id>();
        objIds.add(SL_SCTestData.testOpportunities[0].Id);
        rateCardRE.logicObjectIds = objIds;
        rateCardRE.ruleObjectType = 'RateCard__c';
        try{rateCardRE.testRuleConditions();}catch(Exception e){}
        Test.stopTest();
    }
}