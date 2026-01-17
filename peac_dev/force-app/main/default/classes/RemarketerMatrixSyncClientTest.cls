@isTest
private class RemarketerMatrixSyncClientTest {

    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"message":"Success"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest static void testSyncRemarketersToSandbox() {
        List<Remarketer_Matrix_Obj__c> testRecords = new List<Remarketer_Matrix_Obj__c>();
        List<String> stateList = new List<String>{'AK','CA','OH'};
        for(Integer i=0; i<3; i++) {
            testRecords.add(new Remarketer_Matrix_Obj__c(
                Equipment_Type__c = 'Office Equipment(General)',
                Equipment_Subtype__c = 'Copiers', 
                State__c = stateList[i],
                Return_Warehouse_Code__c = 'ALS',
                Synced__c = false
            ));
        }
        insert testRecords;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
            RemarketerMatrixSyncClient.syncRemarketersToSandbox();
        Test.stopTest();

        List<Remarketer_Matrix_Obj__c> updatedRecords = [SELECT Synced__c FROM Remarketer_Matrix_Obj__c WHERE Id IN :testRecords];
        for (Remarketer_Matrix_Obj__c r : updatedRecords) {
            System.assertEquals(true, r.Synced__c, 'Synced__c must be true');
        }
    }
}