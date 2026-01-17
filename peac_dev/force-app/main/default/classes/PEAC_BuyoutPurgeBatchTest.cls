@isTest
private class PEAC_BuyoutPurgeBatchTest {

    @testSetup
    static void setupData() {
        List<Buyout__c> records = new List<Buyout__c>();

        // Records with today's PurgeDate__c (should be deleted)
        for (Integer i = 0; i < 5; i++) {
            records.add(new Buyout__c(Name = 'ToBeDeleted_' + i, PurgeDate__c = Date.today()));
        }

        // Records with a future date (should NOT be deleted)
        for (Integer i = 0; i < 3; i++) {
            records.add(new Buyout__c(Name = 'ToBeIgnored_' + i, PurgeDate__c = Date.today().addDays(2)));
        }

        insert records;
    }

    @isTest
    static void testBatchExecution() {
        Test.startTest();
        PEAC_BuyoutPurgeBatch batch = new PEAC_BuyoutPurgeBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // Verify that only records with today's date are deleted
        List<Buyout__c> remaining = [
            SELECT Id, Name, PurgeDate__c 
            FROM Buyout__c
        ];

        System.assertEquals(3, remaining.size(), 'Only future-dated records should remain');
        for (Buyout__c record : remaining) {
            System.assert(record.PurgeDate__c > Date.today(), 'No record with today\'s PurgeDate__c should remain');
        }
    }

    @isTest
    static void testScheduledExecution() {
        Test.startTest();
        String cronExp = '0 0 2 * * ?';
        System.schedule('TestBuyoutPurgeSchedule', cronExp, new PEAC_BuyoutPurgeBatch());
        Test.stopTest();

    }
}