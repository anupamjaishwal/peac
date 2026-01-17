@isTest
private class PEAC_PGBackfillBatchTest {

   @testSetup
    static void setupTestData() {
        // 1. Find any Opportunity RecordType whose DeveloperName contains 'loan'
        Id loanOppRecordTypeId = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Opportunity' 
            AND DeveloperName LIKE '%loan%' 
            LIMIT 1
        ].Id;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting', // not excluded
            CloseDate = Date.today().addDays(10),
            RecordTypeId = loanOppRecordTypeId
        );
        insert opp;
        
        // 2. Create Contacts
        Contact c1 = new Contact(FirstName = 'John', LastName = 'Doe', Phone = '5102021011');
        Contact c2 = new Contact(FirstName = 'Jane', LastName = 'Smith', Phone = '5103021011');
        insert new List<Contact>{ c1, c2 };
        
        // 3. Create Guarantors pointing to Contacts
        // Replace Contact__c with the actual lookup field API name on Guarantor__c
        Guarantor__c g1 = new Guarantor__c(
            Opportunity__c = opp.Id,
            Contact__c = c1.Id,
            PG_Number__c = 'PG1'
        );
        Guarantor__c g2 = new Guarantor__c(
            Opportunity__c = opp.Id,
            Contact__c = c2.Id,
            PG_Number__c = 'PG2'
        );
        insert new List<Guarantor__c>{ g1, g2 };
        
        // 4. Create Integration Log with XML
        String xmlMsg = 
            '<ROOT>' +
                '<PG1><FIRSTNAME>John</FIRSTNAME><LASTNAME>Doe</LASTNAME></PG1>' +
                '<PG2><FIRSTNAME>Jane</FIRSTNAME><LASTNAME>Smith</LASTNAME></PG2>' +
            '</ROOT>';
        
        Integration_Log__c log = new Integration_Log__c(
            Opportunity__c = opp.Id,
            Request_Message__c = xmlMsg
        );
        insert log;
    }
    
    @isTest
    static void testBatchUpdatesGuarantors() {
        Test.startTest();
        Database.executeBatch(new PEACP_PGBackfillBatch(), 50);
        Test.stopTest();
        
        // Reload guarantors with their Contact
        List<Guarantor__c> updatedGs = [
            SELECT Id, PG_Number__c, Contact__r.FirstName, Contact__r.LastName
            FROM Guarantor__c
        ];
        
        Map<String, String> nameToPG = new Map<String, String>();
        for (Guarantor__c g : updatedGs) {
            String name = g.Contact__r.FirstName + ' ' + g.Contact__r.LastName;
            nameToPG.put(name, g.PG_Number__c);
        }
        
        System.assertEquals('PG1', nameToPG.get('John Doe'), 'John Doe should be tagged as PG1');
        System.assertEquals('PG2', nameToPG.get('Jane Smith'), 'Jane Smith should be tagged as PG2');
    }
}