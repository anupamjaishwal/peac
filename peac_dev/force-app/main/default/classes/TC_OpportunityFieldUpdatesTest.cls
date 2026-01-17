@isTest
private class TC_OpportunityFieldUpdatesTest {
    private static final String accountName = 'TEST ACCOUNT NAME';
    private static final String contactFirstName = 'FIRST';
    private static final String contactLastName = 'LAST';
    private static final String contactFullName = contactFirstName+' '+contactLastName;

    @testSetup 
    public static void setupData() {
        Account acc = new Account (
            Name = accountName, 
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId()
        );
        insert acc;
        
        Contact c = new Contact (
            AccountId = acc.Id, 
            FirstName = contactFirstName, 
            LastName = contactLastName, 
            MailingStreet = 'test', 
            MailingCity = 'test', 
            MailingStateCode = 'MN', 
            MailingPostalCode = '11111', 
            MailingCountry='United States', 
            Phone='5555555555',
            Title = 'title', 
            SSN__c = '111111111', 
            BirthDate = Date.today (), 
            Email = 'test123@test.com'
        );
        insert c;
        
    }

    @isTest
    private static void testGuarantorTextFieldUpdates() {
        Account acc = [SELECT Id FROM Account WHERE Name =:accountName LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE LastName =:contactLastName LIMIT 1];

        Test.startTest();

        Opportunity opp = new Opportunity(
            AccountId = acc.Id,
            StageName = 'test',
            CloseDate = date.today () + 10,
            Name = 'test'
        );
        insert opp;

        TC_OpportunityFieldUpdates.currentRecursionCount = 0;
        List<Guarantor__c> guarantors = new List<Guarantor__c>();
        Guarantor__c pg = new Guarantor__c(
            RecordTypeId = Schema.SObjectType.Guarantor__c.getRecordTypeInfosByName().get('Personal').getRecordTypeId(),
            Type__c='Personal Guarantor',
            Opportunity__c=opp.Id,
            Contact__c=con.Id
        );
        guarantors.add(pg);

        TC_OpportunityFieldUpdates.currentRecursionCount = 0;
        Guarantor__c cg = new Guarantor__c(
            RecordTypeId = Schema.SObjectType.Guarantor__c.getRecordTypeInfosByName().get('Corporate').getRecordTypeId(),
            Type__c='Corporate Guarantor',
            Opportunity__c=opp.Id,
            Account__c=acc.Id
        );
        guarantors.add(cg);
        insert guarantors;

        //update opp;
        Opportunity oppUpdated = [
            SELECT Id, Personal_Guarantor_Names__c, Corporate_Guarantor_Names__c 
            FROM Opportunity 
            WHERE Id=:opp.Id
        ];

        // Assert the text fields with Guarantor names are populated
        System.assertEquals(contactFullName, oppUpdated.Personal_Guarantor_Names__c);
        System.assertEquals(accountName, oppUpdated.Corporate_Guarantor_Names__c);
        delete guarantors;
        Test.stopTest();
    }
}