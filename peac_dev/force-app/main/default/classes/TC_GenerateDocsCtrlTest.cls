@IsTest
public with sharing class TC_GenerateDocsCtrlTest {
   @TestSetup
    static void makeData(){
        Account a = TC_SDR_TestUtility.constructAccount('Test Generate Docs Ctrl', null, null);
        insert a;
        Opportunity o = TC_SDR_TestUtility.constructOpportunity('Test GenDocs Opportunity', a.Id);
        insert o;
        Contact c1 = TC_SDR_TestUtility.constructContact('TestPerson', 'DOCGEN', 'test@test.com', a.Id);
        c1.Phone = '6121231234';
        Contact c2 = TC_SDR_TestUtility.constructContact('TestPerson2', '2DOC2GEN', 'person@testEmail.com', a.Id);
        c2.Phone = '1231231234';
        insert new List<Contact>{c1, c2};
    }

    @IsTest
    static void testWithGuarantors() {
        Test.startTest();
        Opportunity o = [SELECT Id FROM Opportunity][0];
        List<Contact> cons = new List<Contact>([SELECT Id FROM Contact]);
        Guarantor__c g = new Guarantor__c(
            Opportunity__c = o.Id,
            Contact__c = cons[0].Id,
            Type__c = 'Personal Guarantor',
            RecordTypeId = Schema.SObjectType.Guarantor__c.getRecordTypeInfosByName().get('Personal').getRecordTypeId()
        );
        Guarantor__c g2 = new Guarantor__c(
            Opportunity__c = o.Id,
            Contact__c = cons[1].Id,
            Type__c = 'Personal Guarantor',
            RecordTypeId = Schema.SObjectType.Guarantor__c.getRecordTypeInfosByName().get('Personal').getRecordTypeId()
        );
        insert new List<Guarantor__c>{g, g2};

        TC_GenerateDocsCtrl.generateDocuments(o.Id);
        Test.stopTest();
    }

    @IsTest
    static void testWithPrimaryContact() {
        Test.startTest();
        Opportunity o = [SELECT Id FROM Opportunity][0];
        Contact c = [SELECT Id FROM Contact][0];
        o.Primary_Contact__c = c.Id;
        update o;
        TC_GenerateDocsCtrl.generateDocuments(o.Id);
        Test.stopTest();
    }
}