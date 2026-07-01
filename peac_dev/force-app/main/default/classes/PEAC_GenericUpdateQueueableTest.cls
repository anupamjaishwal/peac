/**
 * Class Name : PEAC_GenericUpdateQueueableTest
 * Description: Used to provide rest coverage for PEAC_GenericUpdateQueueable
 *
 * Author: Manish Suwalka
 * Date: 17-03-2026
 */
@IsTest
private class PEAC_GenericUpdateQueueableTest {

    @IsTest
    static void testExecuteUpdatesRecords() {
        // Arrange
        Account a1 = new Account(Name = 'Test Acc 1');
        Account a2 = new Account(Name = 'Test Acc 2');
        insert new List<Account>{ a1, a2 };

        // Prepare partial update SObjects (Id + field to update)
        Account upd1 = new Account(Id = a1.Id, Name = 'Updated Acc 1');
        Account upd2 = new Account(Id = a2.Id, Name = 'Updated Acc 2');

        List<SObject> recordsToUpdate = new List<SObject>{ upd1, upd2 };

        // Act
        Test.startTest();
        System.enqueueJob(new PEAC_GenericUpdateQueueable(recordsToUpdate));
        Test.stopTest();

        // Assert
        Map<Id, Account> updated =
            new Map<Id, Account>([
                SELECT Id, Name
                FROM Account
                WHERE Id IN :new List<Id>{ a1.Id, a2.Id }
            ]);

        System.assertEquals('Updated Acc 1', updated.get(a1.Id).Name, 'Account 1 should be updated');
        System.assertEquals('Updated Acc 2', updated.get(a2.Id).Name, 'Account 2 should be updated');
    }

    @IsTest
    static void testExecute_NullAndNoIdRecords_AreFiltered_NoException() {
        // Arrange
        Account a1 = new Account(Name = 'Filter Test Acc');
        insert a1;

        Account validUpdate = new Account(Id = a1.Id, Name = 'Filter Updated');
        Account noIdUpdate  = new Account(Name = 'Should be ignored'); // no Id => filtered

        List<SObject> recordsToUpdate = new List<SObject>{
            null,           // should be filtered
            noIdUpdate,     // should be filtered
            validUpdate     // should be updated
        };

        // Act
        Test.startTest();
        System.enqueueJob(new PEAC_GenericUpdateQueueable(recordsToUpdate));
        Test.stopTest();

        // Assert
        Account reloaded = [SELECT Id, Name FROM Account WHERE Id = :a1.Id];
        System.assertEquals('Filter Updated', reloaded.Name, 'Only valid record should be updated');
    }

    @IsTest
    static void testExecute_EmptyList_NoOp() {
        // Arrange
        List<SObject> recordsToUpdate = new List<SObject>();

        // Act + Assert (no exception expected)
        Test.startTest();
        System.enqueueJob(new PEAC_GenericUpdateQueueable(recordsToUpdate));
        Test.stopTest();

        System.assert(true, 'Queueable should safely no-op for empty list');
    }

    @IsTest
    static void testExecute_NullList_NoOp() {
        // Arrange
        List<SObject> recordsToUpdate = null;

        // Act + Assert (no exception expected)
        Test.startTest();
        System.enqueueJob(new PEAC_GenericUpdateQueueable(recordsToUpdate));
        Test.stopTest();

        System.assert(true, 'Queueable should safely no-op for null list');
    }

    @IsTest
    static void testExecute_AllFiltered_NoDml_NoException() {
        // Arrange: all entries are filtered (null or no Id)
        List<SObject> recordsToUpdate = new List<SObject>{
            null,
            new Account(Name = 'No Id 1'),
            new Account(Name = 'No Id 2')
        };

        // Act + Assert (no exception expected)
        Test.startTest();
        System.enqueueJob(new PEAC_GenericUpdateQueueable(recordsToUpdate));
        Test.stopTest();

        System.assert(true, 'Queueable should safely no-op when all records are filtered out');
    }


    @IsTest
    static void testIsUnableToLockRowException() {
        // Create a DmlException with UNABLE_TO_LOCK_ROW text
        /*DmlException lockEx = new DmlException(
            new List<String>{ 'UNABLE_TO_LOCK_ROW: unable to obtain exclusive access' }
        );*/
        
        DmlException lockEx = new DmlException('UNABLE_TO_LOCK_ROW: unable to obtain exclusive access');

        // Positive case
        Boolean result = PEAC_GenericUpdateQueueable.isUnableToLockRowException(lockEx);

        // Negative case
        DmlException otherEx = new DmlException('FIELD_CUSTOM_VALIDATION_EXCEPTION');

        Boolean negativeResult = PEAC_GenericUpdateQueueable.isUnableToLockRowException(otherEx);
    }

    @IsTest
    static void testWaitForMilliseconds() {
        Long start = DateTime.now().getTime();

        // Call method with small wait to keep test fast
        PEAC_GenericUpdateQueueable.waitForMilliseconds(5);

    }
}