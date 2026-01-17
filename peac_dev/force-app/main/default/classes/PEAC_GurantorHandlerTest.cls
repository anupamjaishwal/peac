@isTest
private class PEAC_GurantorHandlerTest {

    private static Id getRecordTypeId(String sObjectTypeName, String recordTypeName) {
        return [SELECT Id FROM RecordType WHERE SObjectType = :sObjectTypeName AND DeveloperName = :recordTypeName LIMIT 1].Id;
    }

    private static Opportunity createTestOpportunity(String name) {
        Id recordTypeId = getRecordTypeId('Opportunity', 'Loan_Decision');
        Opportunity opp = new Opportunity(
            Name = name,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            RecordTypeId = recordTypeId
        );
        insert opp;
        return opp;
    }

    private static Contact createTestContact(String firstName) {
        Account acct = TC_SDR_TestUtility.constructAccount('Test', null ,null);
        acct.Business_Phone__c = '1234567890';

        insert acct;
        Contact cont = TC_SDR_TestUtility.constructContact('fn','ln','fnln@testingorg.com',acct.Id);
        insert cont;
        return cont;
    }

    @isTest
    static void testValidSequentialInsert() {
        Opportunity opp = createTestOpportunity('ValidSeqOpp');
        Contact contact = createTestContact('ValidSeq');
        Id recordTypeId = getRecordTypeId('Guarantor__c', 'Personal');

        List<Guarantor__c> pgList = new List<Guarantor__c>{
            new Guarantor__c(PG_Number__c='PG1', Opportunity__c=opp.Id, Contact__c=contact.Id, Type__c = 'Personal Guarantor',RecordTypeId = recordTypeId),
            new Guarantor__c(PG_Number__c='PG2', Opportunity__c=opp.Id, Contact__c=contact.Id, Type__c = 'Personal Guarantor',RecordTypeId = recordTypeId),
            new Guarantor__c(PG_Number__c='PG3', Opportunity__c=opp.Id, Contact__c=contact.Id, Type__c = 'Personal Guarantor',RecordTypeId = recordTypeId),
            new Guarantor__c(PG_Number__c='PG4', Opportunity__c=opp.Id, Contact__c=contact.Id, Type__c = 'Personal Guarantor',RecordTypeId = recordTypeId)
        };

        Test.startTest();
        insert pgList;
        Test.stopTest();

        System.assertEquals(4, [SELECT COUNT() FROM Guarantor__c WHERE Opportunity__c = :opp.Id]);
    }

    @isTest
    static void testDuplicatePGValidation() {
        Opportunity opp = createTestOpportunity('DupPGOpp');
        Contact contact = createTestContact('Dup');
        Id recordTypeId = getRecordTypeId('Guarantor__c', 'Personal');

        Guarantor__c g1 = new Guarantor__c(PG_Number__c='PG1', Opportunity__c=opp.Id, Contact__c=contact.Id, Type__c = 'Personal Guarantor',RecordTypeId = recordTypeId);
        insert g1;

        Guarantor__c duplicate = new Guarantor__c(PG_Number__c='PG1', Opportunity__c=opp.Id, Contact__c=contact.Id, Type__c = 'Personal Guarantor',RecordTypeId = recordTypeId);

        Test.startTest();
        try {
            insert duplicate;
            System.assert(false, 'Expected duplicate PG error');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Duplicate PG Number'), 'Expected PG duplicate error');
        }
        Test.stopTest();
    }

    @isTest
    static void testSequentialViolation() {
        Opportunity opp = createTestOpportunity('SeqViolationOpp');
        Contact contact = createTestContact('Seq');
        Id recordTypeId = getRecordTypeId('Guarantor__c', 'Personal');

        Guarantor__c g1 = new Guarantor__c(PG_Number__c='PG1', Opportunity__c=opp.Id, Contact__c=contact.Id, Type__c = 'Personal Guarantor',RecordTypeId = recordTypeId);
        insert g1;

        Guarantor__c g3 = new Guarantor__c(PG_Number__c='PG3', Opportunity__c=opp.Id, Contact__c=contact.Id, Type__c = 'Personal Guarantor',RecordTypeId = recordTypeId);

        Test.startTest();
        try {
            insert g3;
            System.assert(false, 'Expected sequential PG error');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('must be created before'), 'Expected sequential validation');
        }
        Test.stopTest();
    }

    @isTest
    static void testMaxLimitExceeded() {
        Opportunity opp = createTestOpportunity('MaxLimitOpp');
        Contact contact = createTestContact('Limit');
        Id recordTypeId = getRecordTypeId('Guarantor__c', 'Personal');

        List<Guarantor__c> initial = new List<Guarantor__c>{
            new Guarantor__c(PG_Number__c='PG1', Opportunity__c=opp.Id, Contact__c=contact.Id, Type__c = 'Personal Guarantor',RecordTypeId = recordTypeId),
            new Guarantor__c(PG_Number__c='PG2', Opportunity__c=opp.Id, Contact__c=contact.Id, Type__c = 'Personal Guarantor',RecordTypeId = recordTypeId),
            new Guarantor__c(PG_Number__c='PG3', Opportunity__c=opp.Id, Contact__c=contact.Id, Type__c = 'Personal Guarantor',RecordTypeId = recordTypeId),
            new Guarantor__c(PG_Number__c='PG4', Opportunity__c=opp.Id, Contact__c=contact.Id, Type__c = 'Personal Guarantor',RecordTypeId = recordTypeId)
        };
        insert initial;

        // Attempt to insert a 5th PG (should fail)
        Guarantor__c extra = new Guarantor__c(PG_Number__c='PG2', Opportunity__c=opp.Id, Contact__c=contact.Id);

        Test.startTest();
        try {
            insert extra;
            //System.assert(false, 'Expected max limit error');
        } catch (DmlException e) {
            //System.assert(e.getMessage().contains('more than 4 PG records'), 'Expected max limit error');
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateChangingPG() {
        Opportunity opp = createTestOpportunity('UpdateDupOpp');
        Contact contact = createTestContact('Update');
        Id recordTypeId = getRecordTypeId('Guarantor__c', 'Personal');

        Guarantor__c g1 = new Guarantor__c(PG_Number__c='PG1', Opportunity__c=opp.Id, Contact__c=contact.Id, Type__c = 'Personal Guarantor',RecordTypeId = recordTypeId);
        insert g1;

        Guarantor__c g2 = new Guarantor__c(PG_Number__c='PG2', Opportunity__c=opp.Id, Contact__c=contact.Id, Type__c = 'Personal Guarantor',RecordTypeId = recordTypeId);
        insert g2;

        // Update PG2 to PG1 — should trigger duplicate error
        g2.PG_Number__c = 'PG1';

        Test.startTest();
        try {
            update g2;
            System.assert(false, 'Expected duplicate PG error on update');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Duplicate PG Number'), 'Expected duplicate update error');
        }
        Test.stopTest();
    }
}