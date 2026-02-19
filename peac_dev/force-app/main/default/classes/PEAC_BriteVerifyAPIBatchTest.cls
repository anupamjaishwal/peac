@IsTest
private class PEAC_BriteVerifyAPIBatchTest {

    private class DummyHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"Accept_All"}');
            return res;
        }
    }

    private static List<Contact> lastN(Integer n) {
        List<Contact> outList = new List<Contact>();
        Integer startIdx = SL_SCTestData.testContacts.size() - n;
        for (Integer i = startIdx; i < SL_SCTestData.testContacts.size(); i++) {
            outList.add(SL_SCTestData.testContacts[i]);
        }
        return outList;
    }

    @IsTest
    static void testBatchCoversDmlAndFinishChunking() {

        Test.setMock(HttpCalloutMock.class, new DummyHttpMock());

        PEAC_BriteVerifyAPIBatch.useMockBriteVerifyInTests = true;
        PEAC_BriteVerifyAPIBatch.mockBriteVerifyStatus = 'Accept_All';

        // SL test data only
        SL_SCTestData.createAccountAndContracts(55, 0);
        System.assert(SL_SCTestData.testContacts.size() >= 55, 'SL_SCTestData did not create enough Contacts');

        List<Contact> contacts55 = lastN(55);

        List<Contact> reset = new List<Contact>();
        Set<Id> ids = new Set<Id>();
        for (Contact c : contacts55) {
            ids.add(c.Id);
            reset.add(new Contact(
                Id = c.Id,
                Email = c.Email,
                Validity_Verify__Checked__c = false,
                Validity_Verify__Status__c = null,
                Validity_Verify__Timestamp__c = null
            ));
        }
        update reset;

        List<Contact> scope = [
            SELECT Id, Email
            FROM Contact
            WHERE Id IN :ids
        ];

        Test.startTest();

        PEAC_BriteVerifyAPIBatch b = new PEAC_BriteVerifyAPIBatch(55);
        b.execute(null, scope);
        b.finish(null);

        Test.stopTest();
        System.assertEquals(1, b.totalScopes, 'execute() should run once');
        System.assertEquals(55, b.totalContactsSeen, 'Should see 55 contacts');
        System.assertEquals(55, b.executedContactIds.size(), 'Should store 55 executed IDs');

        System.assertEquals(55, b.totalContactsUpdated, 'Expected all 55 updated');
        System.assertEquals(55, b.updatedContactIds.size(), 'Expected updated IDs stored');

        Integer updated = [
            SELECT COUNT()
            FROM Contact
            WHERE Id IN :ids
            AND Validity_Verify__Checked__c = true
            AND Validity_Verify__Status__c = 'Accept_All'
            AND Validity_Verify__Timestamp__c != null
        ];
        System.assertEquals(55, updated, 'Expected 55 Contacts updated in the database');
    }
}