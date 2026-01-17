@isTest public class TC_BrokerTest {
    @isTest public static void insertBroker (){
        
        Account acc = new Account (Name = 'test', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Franchisee Account').getRecordTypeId(), Business_Address__c = 'test', Business_City__c = 'test', Business_State__c = 'MN', Business_Zip__c = '11111');
        insert acc;
        
        Account broker = new Account (Name = 'broker', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker Account').getRecordTypeId());
        insert broker;
       
        Opportunity opp = new Opportunity (Name = 'oppp', StageName = 'Decision', CloseDate = Date.today () + 10, AccountId = acc.Id, Primary_Source__c = 'Direct Mail', RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Express Application').getRecordTypeId(), Application_Status__c = 'Manually Approved', Advance_Rental_Amount__c = null,  Application__c = 'test', Equipment_Cost__c = 5000, Equipment_Description__c = 'test', Payment_Amount__c = 0, of_Payments__c = 12, Required_Adv_Payments__c = 0, of_beginning_payments__c = 1, Documentation_Fee__c = 200, of_ending_payments__c = 1, Document_Delivery_Method__c = 'DocuSign', Estimated_Funding_Month__c = 'January', Sec_Dep_Pymts__c = 200,  Account_Billing_Street__c = 'test', Purchase_Options__c = 'Customer Owned');
        opp.Payment_Frequency__c = 'Monthly';
        Test.startTest();
        insert opp;
        Test.stopTest();
        
        insert new Broker__C (Account__C = broker.Id, Opportunity__c = opp.Id);
        
        
    }
}