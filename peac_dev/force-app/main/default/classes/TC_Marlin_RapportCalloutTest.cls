@isTest public class TC_Marlin_RapportCalloutTest {
    
    @isTest public static void testRapportCallout () {
        //MARLIN_RapportCallout.updateApplicationInRapportAsync(lNewOppty.Id,'',lUpdatedFieldList.toLowerCase(),'Opportunity');
        Account acc = new Account (Name = 'test', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Franchisee Account').getRecordTypeId(), Business_Address__c = 'test', Business_City__c = 'test', Business_State__c = 'MN', Business_Zip__c = '11111');
        insert acc;
        
        
        
        Marlin_Configuration__c config = Marlin_Configuration__c.getOrgDefaults ();
        config.Static_Standard_Asset_Account_Id__c = acc.Id;
        insert config;
        
        Account dealer = new Account (Name = 'dealer', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId(),Equipment_Type__c = 'A/V (General)');
        insert dealer;
        
        Opportunity opp = new Opportunity (Name = 'checklistTest', StageName = 'Decision', CloseDate = Date.today () + 10, AccountId = acc.Id, Primary_Source__c = 'Direct Mail', RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Express Application').getRecordTypeId(), Application_Status__c = 'Manually Approved', Application__c = 'test', Equipment_Cost__c = 5000, Equipment_Description__c = 'test', Payment_Amount__c = 0, of_Payments__c = 12, Required_Adv_Payments__c = 0, of_beginning_payments__c = 1, Documentation_Fee__c = 200, of_ending_payments__c = 1, Document_Delivery_Method__c = 'DocuSign', Estimated_Funding_Month__c = 'January', Sec_Dep_Pymts__c = 200, Account_Billing_Street__c = 'test');
        opp.Payment_Frequency__c = 'Monthly';
        Test.startTest();
        insert opp;
        Test.stopTest();
        
        Set<String> lRapportAPIField = new Set<String> {'Equipment_Description__c','Sales_Comments__c','Payment_Amount__c','Equipment_Cost__c','Terms__c','Sec_Dep_Pymts__c','of_Payments__c','Payment_Frequency__c','purchase_options__c'};
        String lUpdatedFieldList = '';
        
        for(String lFieldName : lRapportAPIField){
            lUpdatedFieldList = lUpdatedFieldList + lFieldName + ',';
                            
        }
        
        MARLIN_RapportCallout.updateApplicationInRapportAsync(opp.Id,'', lUpdatedFieldList.toLowerCase (),'Opportunity');
        
    }

}