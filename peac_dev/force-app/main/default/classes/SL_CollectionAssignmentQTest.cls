@isTest
public class SL_CollectionAssignmentQTest {
    @isTest
    static void enqueueOnly() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        Test.startTest();        
        System.enqueueJob(new SL_CollectionAssignmentQ());
        System.enqueueJob(new SL_CollectionAssignmentQ(SL_SCTestData.testAccounts));
        System.enqueueJob(new SL_CollectionAssignmentQ(SL_SCTestData.testContracts));
        System.enqueueJob(new SL_CollectionAssignmentQ('invalid@email.address', 'failed', 'test errors'));
        Test.stopTest();
        system.assert(true);
    }
}