@isTest
private class RemarketerMatrixSyncServiceTest {

    @isTest static void testUpsertRemarketers() {
        List<RemarketerMatrixSyncService.RemarketerMatrixWrapper> wrappers = new List<RemarketerMatrixSyncService.RemarketerMatrixWrapper>();
        List<String> stateList = new List<String>{'AK','CA','OH'};
        for (Integer i = 0; i < 3; i++) {
            RemarketerMatrixSyncService.RemarketerMatrixWrapper w = new RemarketerMatrixSyncService.RemarketerMatrixWrapper();
            w.EquipmentType = 'Office Equipment(General)';
            w.EquipmentSubType = 'Copiers';
            w.State = stateList[i];
            w.WarehouseCode = 'ALS';
            wrappers.add(w);
        }

        String jsonBody = JSON.serialize(wrappers);

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonBody);
        req.httpMethod = 'POST';
        RestContext.request = req;

        Test.startTest();
            String response = RemarketerMatrixSyncService.upsertRemarketers();
        Test.stopTest();

        System.assert(response.startsWith('Success:'), 'Response must be successfull');

        List<Remarketer_Matrix_Obj__c> inserted = [SELECT Equipment_Type__c, Equipment_Subtype__c, State__c, Return_Warehouse_Code__c FROM Remarketer_Matrix_Obj__c];
        System.assertEquals(3, inserted.size(), 'Should be 3 existing records.');
    }
}