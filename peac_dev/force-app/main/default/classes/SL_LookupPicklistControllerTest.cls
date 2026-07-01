/**
 * SL_LookupPicklistControllerTest
 * Test class for SL_LookupPicklistController.
 * Covers all three filtering modes, getProgramRules logic,
 * getRecordById, and error/edge cases.
 */
@isTest
private class SL_LookupPicklistControllerTest {

    // ─── Test Data Setup ──────────────────────────────────────────────────

    @TestSetup
    static void setupTestData() {
        
        RecordType rt = [select id,Name from RecordType where SobjectType='Account' and Name='Dealer Account' Limit 1];
        // Create Accounts
        Account acc1 = new Account(Name = 'Test Account One',  recordTypeId=rt.id);
        Account acc2 = new Account(Name = 'Test Account Two',  recordTypeId=rt.id);
        Account acc3 = new Account(Name = 'Test Account No Programs',  recordTypeId=rt.id);
        insert new List<Account>{ acc1, acc2, acc3 };

        // Create Programs
        Program__c prog1 = new Program__c(Name = 'Alpha Program');
        Program__c prog2 = new Program__c(Name = 'Beta Program');
        Program__c prog3 = new Program__c(Name = 'Gamma Program');
        insert new List<Program__c>{ prog1, prog2, prog3 };

        // acc1 → 1 program (single = auto-select + read-only)
        insert new Account_Program__c(Account__c = acc1.Id, Program__c = prog1.Id);

        // acc2 → 2 programs (multiple = required)
        insert new List<Account_Program__c>{
            new Account_Program__c(Account__c = acc2.Id, Program__c = prog2.Id),
            new Account_Program__c(Account__c = acc2.Id, Program__c = prog3.Id)
        };

        // acc3 → 0 programs (optional)
    }

    // ─── getProgramRules ──────────────────────────────────────────────────

    @isTest
    static void testGetProgramRules_SingleProgram() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account One' LIMIT 1];

        Test.startTest();
        SL_LookupPicklistController.ProgramRules rules =
            SL_LookupPicklistController.getProgramRules(acc.Id);
        Test.stopTest();

        System.assertEquals(1,     rules.count,      'Count should be 1');
        System.assertEquals(true,  rules.isReadOnly,  'Should be read-only for single program');
        System.assertEquals(false, rules.isRequired,  'Should not be required for single program');
        System.assertNotEquals(null, rules.autoSelected, 'autoSelected should be populated');
        System.assertEquals('Alpha Program', rules.autoSelected.label, 'Label should match program name');
    }

    @isTest
    static void testGetProgramRules_MultiplePrograms() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account Two' LIMIT 1];

        Test.startTest();
        SL_LookupPicklistController.ProgramRules rules =
            SL_LookupPicklistController.getProgramRules(acc.Id);
        Test.stopTest();

        System.assertEquals(2,     rules.count,      'Count should be 2');
        System.assertEquals(false, rules.isReadOnly,  'Should not be read-only for multiple programs');
        System.assertEquals(true,  rules.isRequired,  'Should be required for multiple programs');
        System.assertEquals(null,  rules.autoSelected,'autoSelected should be null for multiple programs');
    }

    @isTest
    static void testGetProgramRules_NoPrograms() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account No Programs' LIMIT 1];

        Test.startTest();
        SL_LookupPicklistController.ProgramRules rules =
            SL_LookupPicklistController.getProgramRules(acc.Id);
        Test.stopTest();

        System.assertEquals(0,     rules.count,      'Count should be 0');
        System.assertEquals(false, rules.isReadOnly,  'Should not be read-only for no programs');
        System.assertEquals(false, rules.isRequired,  'Should not be required for no programs');
        System.assertEquals(null,  rules.autoSelected,'autoSelected should be null for no programs');
    }

    @isTest
    static void testGetProgramRules_BlankAccountId() {
        Test.startTest();
        SL_LookupPicklistController.ProgramRules rules =
            SL_LookupPicklistController.getProgramRules('');
        Test.stopTest();

        System.assertEquals(0,     rules.count,      'Count should be 0 for blank accountId');
        System.assertEquals(false, rules.isRequired,  'isRequired should be false for blank accountId');
        System.assertEquals(false, rules.isReadOnly,  'isReadOnly should be false for blank accountId');
    }

    @isTest
    static void testGetProgramRules_NullAccountId() {
        Test.startTest();
        SL_LookupPicklistController.ProgramRules rules =
            SL_LookupPicklistController.getProgramRules(null);
        Test.stopTest();

        System.assertEquals(0, rules.count, 'Count should be 0 for null accountId');
    }

    // ─── searchRecords — Mode 1: No filter ────────────────────────────────

    @isTest
    static void testSearchRecords_NoFilter_ReturnsAll() {
        Test.startTest();
        List<SL_LookupPicklistController.LookupResult> results =
            SL_LookupPicklistController.searchRecords(
                'Program__c', 'Name', '', '', '', '', 10, '', '', ''
            );
        Test.stopTest();

        System.assert(!results.isEmpty(), 'Should return programs with no filter');
    }

    @isTest
    static void testSearchRecords_NoFilter_SearchTerm() {
        Test.startTest();
        List<SL_LookupPicklistController.LookupResult> results =
            SL_LookupPicklistController.searchRecords(
                'Program__c', 'Name', 'Alpha', '', '', '', 10, '', '', ''
            );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return only matching program');
        System.assertEquals('Alpha Program', results[0].label, 'Label should match search term');
    }

    // ─── searchRecords — Mode 2: Direct filter ────────────────────────────

    @isTest
    static void testSearchRecords_DirectFilter() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account One' LIMIT 1];

        Test.startTest();
        List<SL_LookupPicklistController.LookupResult> results =
            SL_LookupPicklistController.searchRecords(
                'Account_Program__c', 'Account__c',
                '', 'Account__c', acc.Id,
                '', 10, '', '', ''
            );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return 1 junction record for acc1');
    }

    // ─── searchRecords — Mode 3: Junction filter ──────────────────────────

    @isTest
    static void testSearchRecords_JunctionFilter_SingleProgram() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account One' LIMIT 1];

        Test.startTest();
        List<SL_LookupPicklistController.LookupResult> results =
            SL_LookupPicklistController.searchRecords(
                'Program__c', 'Name', '',
                '', acc.Id, '',
                10,
                'Account_Program__c', 'Account__c', 'Program__c'
            );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return 1 program for acc1');
        System.assertEquals('Alpha Program', results[0].label, 'Should return Alpha Program');
    }

    @isTest
    static void testSearchRecords_JunctionFilter_MultiplePrograms() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account Two' LIMIT 1];

        Test.startTest();
        List<SL_LookupPicklistController.LookupResult> results =
            SL_LookupPicklistController.searchRecords(
                'Program__c', 'Name', '',
                '', acc.Id, '',
                10,
                'Account_Program__c', 'Account__c', 'Program__c'
            );
        Test.stopTest();

        System.assertEquals(2, results.size(), 'Should return 2 programs for acc2');
    }

    @isTest
    static void testSearchRecords_JunctionFilter_NoPrograms() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account No Programs' LIMIT 1];

        Test.startTest();
        List<SL_LookupPicklistController.LookupResult> results =
            SL_LookupPicklistController.searchRecords(
                'Program__c', 'Name', '',
                '', acc.Id, '',
                10,
                'Account_Program__c', 'Account__c', 'Program__c'
            );
        Test.stopTest();

        System.assert(results.isEmpty(), 'Should return empty list for account with no programs');
    }

    @isTest
    static void testSearchRecords_JunctionFilter_WithSearchTerm() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account Two' LIMIT 1];

        Test.startTest();
        List<SL_LookupPicklistController.LookupResult> results =
            SL_LookupPicklistController.searchRecords(
                'Program__c', 'Name', 'Beta',
                '', acc.Id, '',
                10,
                'Account_Program__c', 'Account__c', 'Program__c'
            );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Search term should filter within junction results');
        System.assertEquals('Beta Program', results[0].label, 'Should return Beta Program');
    }

    @isTest
    static void testSearchRecords_MaxResults() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account Two' LIMIT 1];

        Test.startTest();
        List<SL_LookupPicklistController.LookupResult> results =
            SL_LookupPicklistController.searchRecords(
                'Program__c', 'Name', '',
                '', acc.Id, '',
                1, // maxResults = 1
                'Account_Program__c', 'Account__c', 'Program__c'
            );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should respect maxResults limit');
    }

    @isTest
    static void testSearchRecords_ExtraFields() {
        Test.startTest();
        List<SL_LookupPicklistController.LookupResult> results =
            SL_LookupPicklistController.searchRecords(
                'Program__c', 'Name', 'Alpha',
                '', '', 'Name',
                10, '', '', ''
            );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return 1 result');
        System.assert(results[0].extraData.containsKey('Name'), 'extraData should contain Name field');
    }


    // ─── getRecordById ────────────────────────────────────────────────────

    @isTest
    static void testGetRecordById_ValidId() {
        Program__c prog = [SELECT Id, Name FROM Program__c WHERE Name = 'Alpha Program' LIMIT 1];

        Test.startTest();
        SL_LookupPicklistController.LookupResult result =
            SL_LookupPicklistController.getRecordById('Program__c', 'Name', prog.Id);
        Test.stopTest();

        System.assertNotEquals(null, result,             'Result should not be null');
        System.assertEquals(prog.Id,   result.id,        'Id should match');
        System.assertEquals('Alpha Program', result.label, 'Label should match');
    }

    @isTest
    static void testGetRecordById_InvalidId_ReturnsNull() {
        Test.startTest();
        SL_LookupPicklistController.LookupResult result =
            SL_LookupPicklistController.getRecordById('Program__c', 'Name', 'invalidId000000000');
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null for non-existent Id');
    }

    @isTest
    static void testGetRecordById_BlankParams_ReturnsNull() {
        Test.startTest();
        SL_LookupPicklistController.LookupResult result =
            SL_LookupPicklistController.getRecordById('', '', '');
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null for blank params');
    }

    @isTest
    static void testGetRecordById_NullParams_ReturnsNull() {
        Test.startTest();
        SL_LookupPicklistController.LookupResult result =
            SL_LookupPicklistController.getRecordById(null, null, null);
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null for null params');
    }
}