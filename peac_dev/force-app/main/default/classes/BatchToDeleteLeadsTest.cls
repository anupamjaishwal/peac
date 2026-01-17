@isTest 
public class BatchToDeleteLeadsTest {
    @testSetup static void setupData () {
        TC_LeadTestHelper.insertLead2 ();
        
    }
    static testmethod void executeBatch () {
        Id batchJobId = Database.executeBatch(new batchToDeleteLeads(false), 500);
    } 
}