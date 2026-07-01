@IsTest
    public class PEAC_ILIntegrationLogsTriggerHandlerTest {
    private static String buildRequestJson(Integer assetCount, String buyoutType, String extKey, String extValue) {
            List<Object> assets = new List<Object>();
            for (Integer i = 0; i < assetCount; i++) assets.add('A' + i);
    
            Map<String, Object> req = new Map<String, Object>{
                'BuyoutType' => buyoutType,
                'Assets'     => assets
            };
            if (extKey != null && extValue != null) req.put(extKey, extValue);
    
            return JSON.serialize(new Map<String, Object>{
                'inputs' => new Map<String, Object>{ 'Request' => req }
            });
 }
    
        private static String pickVal(Schema.SObjectField f, String preferredContains) {
            for (Schema.PicklistEntry pe : f.getDescribe().getPicklistValues()) {
                if (preferredContains != null && pe.getValue() != null &&
                    pe.getValue().toLowerCase().contains(preferredContains.toLowerCase())) {
                    return pe.getValue();
                }
            }
            List<Schema.PicklistEntry> all = f.getDescribe().getPicklistValues();
            return all.isEmpty() ? null : all[0].getValue();
 }
    
        @IsTest
        static void testCompletedForLessThanEqual200_NoExtId_SuccessType() {
            IL_Integration_Logs__c logRec = new IL_Integration_Logs__c();
            logRec.Integration_Name__c = 'InfoLease Generate Buyout Quote'; 
            logRec.Type__c = 'Success';
            logRec.Request_Text__c = buildRequestJson(20, '83', null, null);
    
            insert logRec;
    
            IL_Integration_Logs__c stamped = [
                SELECT Status__c, Buyout_External_Id__c
                FROM IL_Integration_Logs__c
                WHERE Id = :logRec.Id
            ];
            System.assertEquals(null, stamped.Status__c, 'No status should be stamped for <200 assets'); 
            System.assertEquals(null, stamped.Buyout_External_Id__c);
        }
    
        @IsTest
        static void testInProgressForGreaterThan200_WithExtId_SuccessType() {
            String extId = 'CN-83-20260327063000000';
    
            IL_Integration_Logs__c logRec = new IL_Integration_Logs__c();
            logRec.Integration_Name__c = 'InfoLease Generate Buyout Quote';
            logRec.Type__c = 'Success';
            logRec.Request_Text__c = buildRequestJson(220, '83', 'BuyoutexternalId', extId);
    
            insert logRec;
    
            IL_Integration_Logs__c stamped = [
                SELECT Status__c, Buyout_External_Id__c
                FROM IL_Integration_Logs__c
                WHERE Id = :logRec.Id
            ];
            System.assertEquals('In Progress', stamped.Status__c); 
            System.assertEquals(extId, stamped.Buyout_External_Id__c);
        }
    
        @IsTest
        static void testFailedForErrorType() {
            IL_Integration_Logs__c logRec = new IL_Integration_Logs__c();
            logRec.Integration_Name__c = 'InfoLease Generate Buyout Quote';
            logRec.Type__c = 'Error';
            logRec.Request_Text__c = buildRequestJson(10, '86', null, null);
    
            insert logRec;
    
            IL_Integration_Logs__c stamped = [
                SELECT Status__c
                FROM IL_Integration_Logs__c
                WHERE Id = :logRec.Id
            ];
            System.assertEquals('Failed', stamped.Status__c); 
        }
    
        @IsTest
        static void testIgnoresOtherIntegrationNames_UsingValidPicklistValue() {
            // pick a valid integration name that is NOT 'InfoLease Generate Buyout Quote'
            String validOtherIntegration = null;
            for (Schema.PicklistEntry pe : IL_Integration_Logs__c.Integration_Name__c.getDescribe().getPicklistValues()) {
                if (pe.getValue() != 'InfoLease Generate Buyout Quote') {
                    validOtherIntegration = pe.getValue();
                    break;
                }
            }
            System.assertNotEquals(null, validOtherIntegration,
                'Need at least one Integration_Name__c picklist value other than InfoLease Generate Buyout Quote');
    
            IL_Integration_Logs__c logRec = new IL_Integration_Logs__c();
            logRec.Integration_Name__c = validOtherIntegration; // valid picklist
            logRec.Type__c = 'Success';
            logRec.Request_Text__c = buildRequestJson(220, '83', 'BuyoutExternalId', 'CN-83-20260327063000000');
    
            insert logRec;
    
            // Handler should skip, so Status__c should remain null unless defaulted elsewhere
            IL_Integration_Logs__c rec = [
                SELECT Status__c, Buyout_External_Id__c
                FROM IL_Integration_Logs__c
                WHERE Id = :logRec.Id
            ];
            System.assertEquals(null, rec.Status__c, 'Handler must skip non-buyout integration'); 
        }
    
    
    @IsTest
    static void test_TestVisibleHelperCoverageBoost_PEAC_IL_Integration_LogsTriggerHandler() {
        // normalizeStatus branches
        System.assertEquals('In Progress', PEAC_IL_Integration_LogsTriggerHandler.tv_normalizeStatus('inprogress'));
        System.assertEquals('In Progress', PEAC_IL_Integration_LogsTriggerHandler.tv_normalizeStatus('In Progress'));
        System.assertEquals('Completed',  PEAC_IL_Integration_LogsTriggerHandler.tv_normalizeStatus('Completed'));
        System.assertEquals('Failed',     PEAC_IL_Integration_LogsTriggerHandler.tv_normalizeStatus('Error'));
        System.assertEquals(null,         PEAC_IL_Integration_LogsTriggerHandler.tv_normalizeStatus(null));
    
        // parseMetaFromRequest branches (new + backward compat + invalid)
        Map<String,String> m1 =
            PEAC_IL_Integration_LogsTriggerHandler.tv_parseMetaFromRequest('{"BuyoutExternalId":"X1","Status":"Success"}');
        System.assertEquals('X1', m1.get('buyoutExternalId'));
        Map<String,String> m2 =
            PEAC_IL_Integration_LogsTriggerHandler.tv_parseMetaFromRequest('{"LogExternalId":"X2","LogStatus":"InProgress"}');
        System.assertEquals('X2', m2.get('buyoutExternalId'));
        System.assertEquals('In Progress', m2.get('status')); 
    
        Map<String,String> m3 =
            PEAC_IL_Integration_LogsTriggerHandler.tv_parseMetaFromRequest('<html>bad</html>');
        System.assertEquals(null, m3.get('buyoutExternalId'));
        System.assertEquals(null, m3.get('status'));
    
        Map<String,String> m4 =
            PEAC_IL_Integration_LogsTriggerHandler.tv_parseMetaFromRequest(''); // blank
        System.assertEquals(null, m4.get('buyoutExternalId'));
    }
        
}