@isTest
public class SL_DocGenControllerTest {

    @testSetup 
    static void setup() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(FirstName='Test',LastName = 'Test Contact', AccountId = acc.Id, Phone ='7848484810');
        insert con;

        Opportunity opp = new Opportunity(Name = 'Test Opportunity', AccountId = acc.Id, Account_Billing_State_Province__c='CA', ContactId = con.Id, StageName = 'Prospecting', CloseDate = Date.today().addDays(30),Branch__c='CT&I Field');
        insert opp;
        Loop__DDP__c ninPack=new Loop__DDP__c(Name='CTI DocGen Package');
        insert ninPack;
        Loop__DDP_Integration_Option__c delivery= new Loop__DDP_Integration_Option__c(Name='Docusign',Loop__DDP__c=ninPack.Id);
        insert delivery;
    }

    @isTest 
    static void testGetContacts() {

        // When
        Test.startTest();
        List<Contact> contacts = SL_DocGenController.getContacts([SELECT Id FROM Account LIMIT 1].Id);
        SL_DocGenController.getUserContact();
        SL_DocGenController.getDisclaimers();
        Test.stopTest();

        // Then
        System.assertEquals(1, contacts.size());
    }

    @isTest 
    static void testGetOppInfo() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        // When
        Test.startTest();
        Opportunity oppInfo = SL_DocGenController.getOppInfo(opp.Id);
        SL_DocGenController.hasPendingItems(opp.Id);
        Test.stopTest();

    }

    @isTest 
    static void testGetInstance() {

        Organization o=[SELECT InstanceName FROM Organization  WHERE Id = :UserInfo.getOrganizationId()];
        // When
        Test.startTest();
        String instanceId = SL_DocGenController.getInstance();
        Test.stopTest();
        System.Assert.areEqual(o.InstanceName, instanceId, 'Instance value is different');
    }


    @isTest
    static void testIsOppValid() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        Boolean result = SL_DocGenController.isOppValid(opp.Id);
        Test.stopTest();

        System.assertEquals(true, result, 'The Opportunity should be valid');
    }
     @isTest
    static void testIsStateValid() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        Boolean result = SL_DocGenController.isStateValid(opp.Id);
        Test.stopTest();

        System.assertEquals(true, result, 'The Opportunity should be valid');
    }

    
    @isTest static void test_sendDocuments() {
        // Create a test request
        String contactId = [SELECT Id FROM Contact LIMIT 1].Id;
        String opportunityId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        String docName = 'Docusign';


        // Test the method
        Test.startTest();
        SL_DocGenController.sendDocuments(opportunityId, contactId, docName);
        SL_DocGenController.sendDocuments(opportunityId, contactId, 'Email');
        Test.stopTest();
    }

    @isTest
    static void test_primaryContact(){
      Contact contact = [SELECT Id FROM Contact WHERE LastName = 'Test Contact' LIMIT 1 ];
      Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];

      Test.startTest();
      SL_DocGenController.handlePrimaryContact(contact.Id, opp.Id);
      Test.stopTest();

      String primaryRole = 'Primary Contact';

      OpportunityContactRole ocr = [SELECT Role FROM OpportunityContactRole WHERE OpportunityId = :opp.Id 
                                    AND ContactId = :contact.Id AND Role = :primaryRole LIMIT 1];
      Assert.areEqual(primaryRole, ocr.Role ,'Expecting the selected contact to has the Primary Contact role');
      Assert.areEqual(Contact.Id, [SELECT Primary_Contact__c FROM Opportunity WHERE Id = :opp.Id].Primary_Contact__c,
                      'Expecting the selected contact to be the Primary Contact');
    }
}