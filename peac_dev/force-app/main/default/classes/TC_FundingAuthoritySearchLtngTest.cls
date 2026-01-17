@isTest public class TC_FundingAuthoritySearchLtngTest {
    @isTest public static void getFundingUser () {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'][0];
        User u = new User (LastName = 'test', Email = 'test@test.com', Alias = 'ttest', UserName = 'andrew234432234@test.com', LocaleSidKey = 'en_US', TimeZoneSidKey = 'GMT', ProfileID = p.Id, EmailEncodingKey = 'UTF-8', LanguageLocaleKey  = 'en_US');
        insert u;
        
        Account acc = new Account (Name = 'test', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Franchisee Account').getRecordTypeId(), Business_Address__c = 'test', Business_City__c = 'test', Business_State__c = 'MN', Business_Zip__c = '11111');
        insert acc;
        Opportunity opp = new Opportunity (Name = 'checklistTest'
                                           , StageName = 'Decision', CloseDate = Date.today () + 10, AccountId = acc.Id, Primary_Source__c = 'Direct Mail', RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Express Application').getRecordTypeId(), 
                                           //Application_Status__c = 'Manually Approved', Application__c = 'test', Equipment_Cost__c = 5000, Equipment_Description__c = 'test', Payment_Amount__c = 0, of_Payments__c = 12, Required_Adv_Payments__c = 1, of_beginning_payments__c = 1, Documentation_Fee__c = 200, of_ending_payments__c = 1, Document_Delivery_Method__c = 'DocuSign', Estimated_Funding_Month__c = 'January', Sec_Dep_Pymts__c = 200
                                           Application_Status__c = 'Manually Approved', Advance_Rental_Amount__c = null,  Application__c = 'test', Equipment_Cost__c = 5000, Equipment_Description__c = 'test', Payment_Amount__c = 0, of_Payments__c = 12, Required_Adv_Payments__c = 0, of_beginning_payments__c = 1, Documentation_Fee__c = 200, of_ending_payments__c = 1, Document_Delivery_Method__c = 'DocuSign', Estimated_Funding_Month__c = 'January', Sec_Dep_Pymts__c = 200,  Account_Billing_Street__c = 'test', Purchase_Options__c = 'Customer Owned');
        opp.Payment_Frequency__c = 'Monthly';
        insert opp;
        
        TC_FundingAuthoritySearchLtng.getFundingAuthUsers ('test', opp.Id);
        
    }
}