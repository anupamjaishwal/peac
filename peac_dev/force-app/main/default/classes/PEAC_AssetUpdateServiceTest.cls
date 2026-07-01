/**************************************************************************************************************
@Author: Chalapati Murru (LTIMindtree)
@Description: This is test class for PEAC_AssetUpdateService(PEAC_ClearDepreciationSection)
@User Story: SAL-7139 Unable to move app from Funding to booking receiving Too many SOQL queries: 101
@Created Date: 23-Apr-2026
**************************************************************************************************************/
@isTest
public class PEAC_AssetUpdateServiceTest {
    
	@testSetup 
    public static void setupBeneficialOwners () {
        Account acc = new Account (Name = 'testbeni', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId(), Business_Phone__c = '1234567890');
        insert acc;
        Contact c = new Contact (AccountId = acc.Id, FirstName = 'test', LastName = 'testbeni', OtherStreet = 'test', OtherCity = 'test', OtherStateCode = 'MN', OtherPostalCode = '11111', Title = 'title', SSN__c = '111111111', BirthDate = Date.today (), Email = 'test@test.com');
        insert c;
        insert new Beneficial_Owner__c (Account__c = acc.Id, Contact__c = c.Id, Ownership_Percent__c = 50);

        Test.startTest();
        Id loanOppId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Lease Opportunity').getRecordTypeId();
        Opportunity opp = new Opportunity (AccountId = acc.Id, StageName = 'Quote', CloseDate = date.today () + 10,
                                           Name = 'test', RecordTypeId = loanOppId,Purchase_Options__c = 'FMV');
        insert opp;
        insert new Asset__c (End_User_Billing_Address__c = true, Quantity__c = 1, Equipment_Code__c = 'ATM',
               Usage_User_Table__c = '1',State_Tax_Code__c = '050',Equipment_Sub_Category__c = 'ATM', Opportunity__c = opp.Id, Cost__c = 0);
        insert new Blended_Income_Item__c (Opportunity__c = opp.id);  
        Test.stopTest();
    }
    
    @isTest public static void expressOrtValidationTest() {
        Opportunity opp = [SELECT Id, Contract_Type__c FROM Opportunity LIMIT 1];
        
        Test.startTest();
        opp.Contract_Type__c = 'CS';
        opp.Tax_Exempt__c = 'Yes';
        update opp;
        Test.stopTest();
    }
    
    @isTest public static void customerOwnedTest() {
        Opportunity opp = [SELECT Id, Contract_Type__c FROM Opportunity LIMIT 1];
        
        Test.startTest();
        opp.Contract_Type__c = 'RL';
        opp.Purchase_Options__c = 'Customer Owned';
        update opp;
        Test.stopTest();
    }
    
    @isTest public static void taxExemptTest() {
        Opportunity opp = [SELECT Id, Contract_Type__c FROM Opportunity LIMIT 1];
        
        Test.startTest();
        opp.Contract_Type__c = 'RL';
        opp.Tax_Exempt__c = null;
        update opp;
        Test.stopTest();
    }
    @isTest public static void bookdateTest() {
        Opportunity opp = [SELECT Id, Opportunity_Booked_Date__c FROM Opportunity LIMIT 1];
        
        Test.startTest();
        opp.Opportunity_Booked_Date__c = System.Now();
        update opp;
        Test.stopTest();
    }
    @isTest public static void commencementdateTest() {
        Opportunity opp = [SELECT Id, Commencement_Date__c FROM Opportunity LIMIT 1];
        
        Test.startTest();
        opp.Commencement_Date__c = System.Now().date();
        update opp;
        Test.stopTest();
    }

}