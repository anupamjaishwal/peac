@isTest
public class TC_LeadTestHelper {

    public static testmethod void insertLead () {
        Lead l = new Lead (
            // required fields for standard objects
            LastName = 'ContactBatchTest',
            Company = 'CompanyBatchTest',
            FirstName = 'ContactBatchTest',
            
            // required criteria to be auto-converted
            RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('End User Lead').getRecordTypeId(),
            Auto_Convert__c = true,
            
            // required fields for additional objects
            Guarantor_Last_Name__c = 'GuarLastBatchTest1',
            Guarantor2_Last_Name__c = 'GuarLastBatchTest2',
            Dealer_name__c = 'DealerBatchTest',
            
            Equipment_Description__c = 'testEquipDescriptBatch',
            Equipment_Type__c = 'ATM',
            Equipment_Address_Line_1__c = 'equipLine1',
            Equipment_Address_Line_2__c = 'equipLine2',
            Equipment_City__c = 'equipCity',
            Equipment_State__c = 'AL',
            Equipment_Zipcode__c = '33333',
            
            // miscellaneous required fields
            LeadSource = 'Loan Portal Application',
            Status = 'Prospecting',
            Lead_Type__c = 'End User',
            Email = 'sfdc@northteq.com',
            Street = 'test street',
            City = 'test city',
            State = 'Minnesota',
            Country = 'United States',
            PostalCode = '55414',
            Last_Completed_Step__c = 'Bank Statements',
            Loan_Started__c = Date.today(),
             CCAN__c = 'n98y7nc',
            Phone = '8794447777'
        );
        
        insert l;
        
    }
    
    public static testmethod void insertLead2 () {
        
        Lead l2 = new Lead (
            // required fields for standard objects
            LastName = 'CompanyTest',
            Company = 'CompanyTest',
            FirstName = 'CompanyTest',
            
            // required criteria to be auto-converted
            RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('End User Lead').getRecordTypeId(),
            Auto_Convert__c = FALSE,
            
            // required fields for additional objects
            Guarantor_Last_Name__c = 'GuarLastBatchTest1',
            Guarantor2_Last_Name__c = 'GuarLastBatchTest2',
            Dealer_name__c = 'DealerBatchTest',
            
            Equipment_Description__c = 'testEquipDescriptBatch',
            Equipment_Type__c = 'ATM',
            Equipment_Address_Line_1__c = 'equipLine1',
            Equipment_Address_Line_2__c = 'equipLine2',
            Equipment_City__c = 'equipCity',
            Equipment_State__c = 'AL',
            Equipment_Zipcode__c = '33333',
            
            // miscellaneous required fields
            LeadSource = 'Loan Portal Application',
            Status = 'Prospecting',
            Lead_Type__c = 'End User',
            Email = 'sfdc@northteq.com',
            Street = 'test street',
            City = 'test city',
            State = 'Minnesota',
            Country = 'United States',
            PostalCode = '55414',
            Last_Completed_Step__c = 'Bank Statements',
            Loan_Started__c = Date.today(),
             CCAN__c = 'n98y7nc',
            Phone = '8794447777'
        );
        
        insert l2;
    }

    public static testMethod  void insertDupeAccountContact () {
		insert new Account (Name = 'Dupe Acc', CCAN__c = 'n98y7nc');
        insert new Contact ( LastName = 'ContactBatchTest', FirstName = 'ContactBatchTest2', Email = 'sfdc@northteq.com', Phone = '8794447777');
    }

    public static testMethod void testBoost() {
        TC_LeadConversion.boost();
    }
}