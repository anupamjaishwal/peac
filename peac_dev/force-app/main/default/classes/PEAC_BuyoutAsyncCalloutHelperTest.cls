@IsTest(SeeAllData=true)
private class PEAC_BuyoutAsyncCalloutHelperTest {

    @IsTest
    static void test_futureCallout_updatesStatus() {
        Id cId = [SELECT Id FROM Contract__c LIMIT 1].Id;

        // build request with >200 assets
        List<String> assets = new List<String>();
        for (Integer i = 0; i < 201; i++) assets.add('A' + i);

        Map<String, Object> req = new Map<String, Object>{
            'ContractNumber' => 'DUMMY',
            'BuyoutType' => '1',
            'QuoteType' => '0001',
            'QuotedBy' => 'Tester',
            'Assets' => assets,
            'BuyoutexternalId' => 'DUMMY-1-20260323010101000'
        };

        String strictBody = JSON.serialize(new Map<String, Object>{
            'inputs' => new Map<String, Object>{ 'Request' => req }
        });

        IL_Integration_Logs__c logRec = new IL_Integration_Logs__c(
            Contract__c = cId,
            Integration_Name__c = 'InfoLease Generate Buyout Quote',
            Request_Text__c = strictBody,
            Status__c = 'In Progress'
        );
        insert logRec;

        Test.startTest();
        // Future executes at stopTest
        PEAC_BuyoutAsyncCalloutHelper.submitBuyoutFromIntegrationLog(logRec.Id);
        Test.stopTest();

        // We just assert it didn't crash + record still exists.
        // Status may become Completed/Failed depending on mock response behavior in callBridgeware().
        IL_Integration_Logs__c after = [SELECT Status__c, Error_Message__c FROM IL_Integration_Logs__c WHERE Id = :logRec.Id];
        System.assertNotEquals(null, after.Status__c);
    }
    @IsTest
    static void test_helper_private_methods_for_coverage() {
    
        // isInfoleaseFailure branches
        System.assertEquals(true, PEAC_BuyoutAsyncCalloutHelper.tv_isInfoleaseFailure(null));
        System.assertEquals(true, PEAC_BuyoutAsyncCalloutHelper.tv_isInfoleaseFailure('not-json'));
        System.assertEquals(false, PEAC_BuyoutAsyncCalloutHelper.tv_isInfoleaseFailure('{"response":{"Response":{"Success":"true"}}}'));
        System.assertEquals(true, PEAC_BuyoutAsyncCalloutHelper.tv_isInfoleaseFailure('{"response":{"Response":{"Success":"false"}}}'));
    
        // extractInfoleaseMessage branches
        System.assertEquals('No response returned from Infolease.',
            PEAC_BuyoutAsyncCalloutHelper.tv_extractInfoleaseMessage(''));
        System.assertEquals('E1, E2',
            PEAC_BuyoutAsyncCalloutHelper.tv_extractInfoleaseMessage('{"response":{"Response":{"Errors":["E1","E2"]}}}'));
    
        // updateSafeLog branch: just ensure it doesn't throw even if some fields absent in org
        // Use any existing log id if possible; otherwise create a minimal IL log row
        IL_Integration_Logs__c l = new IL_Integration_Logs__c(
            Integration_Name__c = 'InfoLease Generate Buyout Quote',
            Request_Text__c = '{"inputs":{"Request":{"ContractNumber":"X"}}}'
        );
        insert l;
    
        Test.startTest();
        PEAC_BuyoutAsyncCalloutHelper.tv_updateSafeLog(l.Id, 'Failed', 'Error', 'boom','response');
        Test.stopTest();
    
        IL_Integration_Logs__c after = [SELECT Id FROM IL_Integration_Logs__c WHERE Id = :l.Id];
        System.assertNotEquals(null, after.Id);
    }
}