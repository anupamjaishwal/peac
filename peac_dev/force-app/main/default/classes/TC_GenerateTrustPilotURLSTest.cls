@isTest
public with sharing class TC_GenerateTrustPilotURLSTest {
    @testSetup 
    public static void setupData () {

        Account account = new Account(
            Name = 'TC_GenerateTrustPilotURLSTest',
            Business_City__c = 'Minneapolis',
            Business_State__c = 'MN',
            Business_Address__c = '701 N 3rd St',
            Business_Zip__c = '55401',
            Business_Type__c = 'Proprietorship'
        );
        insert account;
        System.assertNotEquals(null, account.Id);
        Id rTypeId = Schema.SObjectType.opportunity.getRecordTypeInfosByDeveloperName().get('Loan_Funding').getRecordTypeId();
        Opportunity opportunity = new Opportunity(
            recordTypeId = rTypeId,
            Name = 'TC_GenerateTrustPilotURLSTest',
            StageName = 'Booking',
            CloseDate = Date.today(),
            Tax_ID__c = '123456789',
            Business_Phone__c = '8908908900',
            Probability = 76,
            Credit_Stips_Completed_Date__c = Date.today(),
            Assign_To_CMS_User__c = UserInfo.getUserId(),
            AccountId = account.Id,
            Account_Business_Street__c = '123 Avenue Dr',
            Account_Billing_Street__c = '123 Avenue Dr',
            Account_Business_City__c = 'Minneapolis',
            Account_Billing_City__c = 'Minneapolis',
            Account_Business_State_Province__c = 'MN',
            Account_Billing_State_Province__c = 'MN',
            Account_Business_Zip_Postal_Code__c = '55401',
            Account_Billing_Zip_Postal_Code__c  = '55401',
            Loan_Purpose__c = 'Expansion/Hiring',
            Funding_Booking_Loan_Completed_Date__c =Date.today (),
            Terms__c = 12,
            Commencement_Date__c = Date.today (),
            Invoicing_Due_Day__c = 5,
            Equipment_Cost__c = 30000,
            Gross_Contract__c = 20000,
            Gross_Finance__c = 10000,
            Invoice_Description__c = 'test',
            Payment_Frequency__c = 'Annually',
            Billing_Cycle__c = 'January',
            Funding_Booking_Lease_Completed_Date__c = Date.today (),
            Purchase_Options__c = 'FMV',
            of_Payments__c = 12,
            Payment_Amount__c = 5000,
            Contract_Type__c = 'Conditional Sales',
            Primary_Source__c = 'Customer Outbound',
            CaseCenter__c = 'ADCDGTPURL'
        );
        Test.startTest();
        insert opportunity;
        System.assertNotEquals(null, opportunity.Id);
        Test.stopTest();

        insert new Trust_Pilot_App__c(API_Key__c = 'test', Secret__c = 'test', Business_Id__c = 'test', Invitation_URL__c = 'TrustPilot2Resp', Password__c = 'tes', Token_URL__c = 'TrustPilot1Resp', Username__c = 'test');
         
        Approved_Offer__c offer = new Approved_Offer__c ();
        offer.Opportunity__c = opportunity.Id;
        insert offer;
    }

    @isTest
    static void generateTrustPilotURLSTest(){
        Approved_Offer__c offer = [SELECT Id FROM Approved_Offer__c LIMIT 1];
        Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Name = 'TC_GenerateTrustPilotURLSTest'];
        opp.StageName = 'Funded/Booked';
        opp.Selected_Approved_Offer__c = offer.Id;
        Test.startTest();
            update opp;
        Test.stopTest();
    }
}