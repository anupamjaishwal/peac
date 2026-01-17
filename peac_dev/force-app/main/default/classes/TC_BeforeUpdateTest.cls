@isTest
public class TC_BeforeUpdateTest {
    
    @testSetup 
    public static void TC_BeforeUpdate () {
        Id devRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan Booking').getRecordTypeId();
        Account acc = new Account (Name = 'testbeni', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId(), Business_Phone__c = '1234567890');
        insert acc;
        
        Contact c = new Contact (AccountId = acc.Id, FirstName = 'test', LastName = 'testbeni', OtherStreet = 'test', OtherCity = 'test', OtherStateCode = 'MN', OtherPostalCode = '11111', Title = 'title', SSN__c = '111111111', BirthDate = Date.today (), Email = 'test@test.com');
        insert c;
        
        insert new Beneficial_Owner__c (Account__c = acc.Id, Contact__c = c.Id, Ownership_Percent__c = 50);

        Test.startTest();
        Opportunity opp = new Opportunity (AccountId = acc.Id
                                           , StageName = 'Docs Out'
                                           , CloseDate = date.today () + 10
                                           , Name = 'test'
                                           , Tax_ID__c = '111000001', Gross_Contract__c = 11,
                                          Equipment_Cost__c = 22);

        
        insert opp;
        opp.Equipment_Cost__c = 2.3;
        opp.Gross_Contract__c = 1.2;
        opp.Variable_Payment__c = false;
        update opp;
        Test.stopTest();

    }
    
    @isTest public static void expressOrtValidationTest() {
        Id devRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan Booking').getRecordTypeId();
        Opportunity op = new Opportunity (Name = 'test'
                                         ,AccountId = [SELECT Id FROM Account WHERE Name = 'testbeni'][0].Id
                                         ,StageName='Quote'
                                         ,CloseDate = date.today()+15
                                         ,Primary_Source__c='LendingTree', 
                                         RecordTypeId = devRecordTypeId);
        Test.startTest();
        insert op;
        op.Terms__c = 10;
        op.Max_Term_Approved__c =5;
        op.Equipment_Cost__c = 23;op.Gross_Contract__c = 12;
        op.RecordTypeId = devRecordTypeId;
        update op;
        TC_BeforeUpdate.beforeUpdate(new Map<Id, Opportunity>{op.Id => op}, new Map<Id, Opportunity>{op.Id => op});
        //update op;
        
        
        Test.stopTest();
    }
}