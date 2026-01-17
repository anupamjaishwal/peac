@isTest public class TC_DocFeeRuleHelperTest {

    @testsetup public static void setupDocRuleTest () {
        Account dealer = new Account (Name = 'dealer', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId() ,Equipment_Type__c = 'A/V (General)');
        insert dealer;
        
        Account borrower = new Account (Name = 'test', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Franchisee Account').getRecordTypeId(), Business_Address__c = 'test', Business_City__c = 'test', Business_State__c = 'MN', Business_Zip__c = '11111');
        insert borrower;
        
        Opportunity opp = new Opportunity (Name = 'docfeetest', StageName = 'Quote', CloseDate = Date.today () + 10, AccountId = borrower.Id, Primary_Source__c = 'Direct Mail', RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Express Application').getRecordTypeId(), Application_Status__c = 'Manually Approved', Application__c = 'test', Equipment_Cost__c = 5000, Equipment_Description__c = 'test', Payment_Amount__c = 0, of_Payments__c = 12, Required_Adv_Payments__c = 0, of_beginning_payments__c = 1, Documentation_Fee__c = 200, of_ending_payments__c = 1, Document_Delivery_Method__c = 'DocuSign', Estimated_Funding_Month__c = 'January', Sec_Dep_Pymts__c = 200, Account_Billing_Street__c = 'test');
        Test.startTest();
        insert opp;
        Test.stopTest();
        
        
        
        
        TCRE__Rule_Config__c config = new TCRE__Rule_Config__c  (TCRE__SObject_Name__c = 'Opportunity', TCRE__Evaluation_Logic_Picklist__c  = 'All (AND)', TCRE__Rule_Name__c = 'test');
        insert config;
        
        TCRE__Rule_Condition__c cond = new TCRE__Rule_Condition__c  (TCRE__Rule_Config__c = config.Id, TCRE__Operator__c = '=', TCRE__Value__c = 'test', TCRE__Field_Name__c = 'Name');
        insert cond;
        
        insert new Doc_Fee_Rule__c (Apex_Class_Define_Entry_Criteria_Value__c = 'TC_RitchieBrothersDocFeeImpl', Order__c = 1, Doc_Fee_Amount__c = 25);
        insert new Doc_Fee_Rule__c (Apex_Class_Define_Entry_Criteria_Value__c = 'TC_SentrySurveillanceDocFeeImpl', Order__c = 2, Doc_Fee_Amount__c = 25);
        insert new Doc_Fee_Rule__c (Rule_Config__c = config.Id, Order__c = 3, Doc_Fee_Amount__c = 25);
    }
    
    @isTest public static void testDocFees () {
        Test.startTest();
        insert new Dealer__c (Dealer__c = [SELECT ID FROM ACCOUNT WHERE NAME = 'dealer'][0].ID, Opportunity__c = [SELECT ID FROM OPPORTUNITY WHERE NAME= 'docfeetest'][0].ID, Primary_Dealer__c = true);
        TC_DocFeeRuleHelper.setDocFees (new Set <Id> {[SELECT Id FROM Opportunity WHERE Name = 'docfeetest'][0].Id});
        Test.stopTest();
    } 

}