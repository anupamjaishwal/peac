@isTest
public class PEAC_sendCreateAppEmailTest {
    
        static testMethod void PEAC_sendCreateAppEmail(){
            Account acct = new Account(Name='Test', CCAN__c='111111', Tax_ID__c='111111111');
            insert acct;
            Opportunity opp = new Opportunity (Name = 'oppp',  Fraud_PG_Required__c =1, Annual_Revenue__c = 1000000, 
                Requested_Amount__c = 250000, Oppt_FS_Use_Of_Funds__c = 'test', StageName = 'Decision', Points__c = 1, CloseDate = Date.today () + 10, 
                AccountId = acct.Id, Primary_Source__c = 'Direct Mail', RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan Opportunity').getRecordTypeId(), 
                Application_Status__c = 'Manually Approved', Advance_Rental_Amount__c = null,  Application__c = 'test', Equipment_Cost__c = 5000, 
                Equipment_Description__c = 'test', Payment_Amount__c = 0, of_Payments__c = 12, Required_Adv_Payments__c = 0, of_beginning_payments__c = 1, 
                Documentation_Fee__c = 200, of_ending_payments__c = 1, Document_Delivery_Method__c = 'DocuSign', Estimated_Funding_Month__c = 'January',
                Sec_Dep_Pymts__c = 200,  Account_Billing_Street__c = 'test', Loan_Purpose__c = 'testing');
                opp.Payment_Frequency__c = 'Weekly';
            insert opp;
            sendCreateAppEmail.sendEmail(new list<Id>{opp.ID});
        }
}