@isTest public class TC_PayoffTriggerHelperTest {

    @isTest 
    public static void payoffInsertTest () {
        Account acc = new Account (Name = 'test', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Franchisee Account').getRecordTypeId(), Business_Address__c = 'test', Business_Phone__c = '1234567890');
        insert acc;
        
        Contact primary = new Contact (FirstName = 'test', LastName = 'test2', Email = 'test@test.com', AccountId = acc.Id);
        insert primary;
        
        
        Contact billing = new Contact (FirstName = 'test', LastName = 'test2', AccountId = acc.Id);
        insert billing;
        
        Account dealer = new Account (Name = 'dealer', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId(), Equipment_Type__c = 'A/V (General)');
        Test.startTest();
        insert dealer;
        
        Profile p = [SELECT Id FROM Profile WHERE Name='DataAdmin'][0];
        
        String uniqueUserName = 'dataadmin' + DateTime.now().getTime() + '@testorg.com';
        User u = new User(Alias = 'dadmin', Email='dataadmin@testorg.com',EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',LocaleSidKey='en_US', ProfileId = p.Id,TimeZoneSidKey='America/Los_Angeles',UserName=uniqueUserName);
        System.runAs(u) {
            
            Opportunity opp = new Opportunity (Name = 'checklistTest', StageName = 'Decision', CloseDate = Date.today () + 10, AccountId = acc.Id, RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan Opportunity').getRecordTypeId(), Application__c = 'test', Equipment_Cost__c = 5000, Equipment_Description__c = 'test', Payment_Amount__c = 5000, of_Payments__c = 12,Primary_Source__c = 'DLG Outbound', Application_Status__c = 'In Process', Required_Adv_Payments__c = 1, of_beginning_payments__c = 1, Documentation_Fee__c = 200, of_ending_payments__c = 1, Document_Delivery_Method__c = 'DocuSign', Estimated_Funding_Month__c = 'January', Sec_Dep_Pymts__c = 200, CaseCenter__c = 'test321', Loan_Purpose__c  = 'test');
            insert opp;
			Test.stopTest();
            
            Payoff__c payoff = new Payoff__c (Payoff_Amount__c = 5000, Opportunity__c = opp.Id);
            insert payoff;
            
            
        }
    }
}