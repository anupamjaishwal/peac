/**
 * Created by trohweder on 10/7/20.
 */
@IsTest
public with sharing class TC_LeadOutcomeChangeTest {
//test
    @IsTest
    public static void testConvertedNoOppId(){
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

        Lead test = [SELECT Id, Status, Lead_Outcome__c FROM Lead WHERE Id = :l.Id LIMIT 1];

        test.Status = 'Closed - Converted';


        update test;

        test = [SELECT Id, Status, Lead_Outcome__c FROM Lead WHERE Id = :l.Id LIMIT 1];

        System.assertEquals('Warm Transfer Converted', test.Lead_Outcome__c);

    }
    @IsTest
    public static void testConvertedWithOppId() {
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

        l.Status = 'Closed - Converted';

        l.Opportunity_Record_ID__c = '1';

        update l;

        Lead test = [SELECT Id, Lead_Outcome__c FROM Lead WHERE Id=:l.Id];

        System.assertEquals('Digital Auto Converted', test.Lead_Outcome__c);

    }

}