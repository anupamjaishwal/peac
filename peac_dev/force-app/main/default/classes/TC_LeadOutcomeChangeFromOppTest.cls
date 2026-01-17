/**
 * Created by trohweder on 10/7/20.
 */
@IsTest
public with sharing class TC_LeadOutcomeChangeFromOppTest {
    
    @TestSetup
    static void setup() {
        
        Account acc = new Account (Name = 'test',
                Business_Address__c = '701 n 3rd st',
                Business_City__c = 'minneapolis',
                Business_State__c = 'MN',
                Business_Zip__c = '55401',
                Business_Type__c = 'Corporation',
                Business_Country__c= 'US',
                Account_Status__c = 'Prospect',
                WCL_Status__c = 'No Contact');
        insert acc;
        
        Opportunity opp = new Opportunity (Name = 'checklistTest',
                StageName = 'Proposal',
                Primary_Source__c = 'Customer Inbound - Call',
                CloseDate = Date.today() + 1,
                Application__c = 'salkdjflksjdf',
                Equipment_Cost__c = 100,
                Equipment_Description__c = 'test',
                Terms__c = 60,
                AccountId=acc.Id,
                Business_Phone__c = '1234567891',
                Tax_ID__c = '123124321'
        );
        Test.startTest();
        insert opp;
        
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
                Phone = '8794447777',
                Business_Phone__c = '1234567891'
        );

        l.Opportunity_Record_ID__c = opp.Id;
        insert l;
        Test.stopTest();
    }
    
    @IsTest
    public static void testLeadOutcomeChangeStartedOnOpp(){

        Lead l = [SELECT Id, Status FROM Lead WHERE LeadSource = 'Loan Portal Application'];
        
        l.Status = 'Closed - Converted';
        update l;

        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, Application_Status__c, CreatedDate, record_type_name__c, RecordTypeId, StageName, Loan_Record_Type__c FROM Opportunity]);
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>([SELECT Id, Application_Status__c, CreatedDate, record_type_name__c, RecordTypeId, Loan_Record_Type__c, StageName FROM Opportunity]);

        TC_LeadOutcomeChangeFromOpp.updateLeadOutcome(oldMap,newMap);

    }

    @IsTest
    public static void testLeadOutcomeChangeStartedOnOpp2(){

        Lead l = [SELECT Id, Status FROM Lead WHERE LeadSource = 'Loan Portal Application'];
        
        l.Status = 'Closed - Converted';
        update l;

        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, Application_Status__c, CreatedDate, record_type_name__c, RecordTypeId, StageName, Loan_Record_Type__c FROM Opportunity]);
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>([SELECT Id, Application_Status__c, CreatedDate, record_type_name__c, RecordTypeId, Loan_Record_Type__c, StageName FROM Opportunity]);
        for(Id key : newMap.keyset()){
            newMap.get(key).StageName = 'Funded/Booked';
        }
        TC_LeadOutcomeChangeFromOpp.updateLeadOutcome(oldMap,newMap);

    }
}