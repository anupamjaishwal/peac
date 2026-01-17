@isTest
public class RemarketerMatrixSchedulerTest {

    // Mock callout to simulate a successful response
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"Success"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testSchedulerExecution() {
        // Register the mock
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Create test data
        Remarketer_Matrix_Obj__c testObj = new Remarketer_Matrix_Obj__c(
            Equipment_Type__c = 'Office Equipment(General)',
            Equipment_Subtype__c = 'Copiers',
            State__c = 'CA',
            Return_Warehouse_Code__c = 'ALS',
            Synced__c = false
        );
        insert testObj;

        // Run the scheduler
        Test.startTest();
        RemarketerMatrixScheduler scheduler = new RemarketerMatrixScheduler();
        scheduler.execute(null); // Manually call execute since we're testing it directly
        Test.stopTest();

        // Verify that the record was marked as synced
        Remarketer_Matrix_Obj__c updatedObj = [SELECT Synced__c FROM Remarketer_Matrix_Obj__c WHERE Id = :testObj.Id];
        System.assertEquals(true, updatedObj.Synced__c, 'Record should be marked as synced.');
    }
}