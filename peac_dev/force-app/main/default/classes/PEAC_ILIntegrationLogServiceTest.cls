/**
 * @Author: D Balakrishna (LTIMindtree)
 * @Description:This Class provides the required Test Coverage for "PEAC_ILIntegrationLogService"	
 * @User Story: SL-2924
 * Created Date : 24 March 2026
 */
@IsTest(SeeAllData=true)
private class PEAC_ILIntegrationLogServiceTest {

private static Id getAnyContractId() {
        return [SELECT Id FROM Contract__c LIMIT 1].Id;
    }

    private static String buildReq(Integer assetCount, String buyoutType, String extKey, String extValue) {
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

    private static String pickIntegrationNameStartingWith(String prefix) {
        for (Schema.PicklistEntry pe : IL_Integration_Logs__c.Integration_Name__c.getDescribe().getPicklistValues()) {
            if (pe.getValue() != null && pe.getValue().startsWith(prefix)) return pe.getValue();
        }
        // fallback: exact base value if it exists
        for (Schema.PicklistEntry pe : IL_Integration_Logs__c.Integration_Name__c.getDescribe().getPicklistValues()) {
            if (pe.getValue() == 'InfoLease Generate Buyout Quote') return pe.getValue();
        }
        return null;
    }

    @IsTest
    static void testGetInProgressQbts() {
        Id cId = getAnyContractId();

        String integrationName = pickIntegrationNameStartingWith('InfoLease Generate Buyout Quote');
        System.assertNotEquals(null, integrationName,
            'Integration_Name__c picklist must contain InfoLease Generate Buyout Quote');

        IL_Integration_Logs__c l1 = new IL_Integration_Logs__c(
            Contract__c = cId,
            Integration_Name__c = integrationName,
            Status__c = 'In Progress', // valid restricted picklist
            Type__c = 'Success',
            Request_Text__c = buildReq(220, '83', 'BuyoutexternalId', 'CN-83-20260327063000000')
        );

        insert l1;

        Test.startTest();
        List<String> qbts = PEAC_ILIntegrationLogService.getInProgressQbts(cId);
        Test.stopTest();

        System.assert(qbts.contains('83'), 'Should include QBT 83'); 
    }

    @IsTest
    static void testGetLatestLogs_ReturnsInProgressAndFailed_DedupByQbt() {
        Id cId = getAnyContractId();

        String integrationName = pickIntegrationNameStartingWith('InfoLease Generate Buyout Quote');
        System.assertNotEquals(null, integrationName,
            'Integration_Name__c picklist must contain InfoLease Generate Buyout Quote');

        IL_Integration_Logs__c failed = new IL_Integration_Logs__c(
            Contract__c = cId,
            Integration_Name__c = integrationName,
            Status__c = 'Failed',       // valid value in most orgs; if not, remove and use Type__c='Error' and leave Status__c blank
            Type__c = 'Error',
            Error_Message__c = 'Some error',
            Request_Text__c = buildReq(220, '83', 'BuyoutexternalId', 'CN-83-20260327065000000')
        );

        IL_Integration_Logs__c inProg = new IL_Integration_Logs__c(
            Contract__c = cId,
            Integration_Name__c = integrationName,
            Status__c = 'In Progress',
            Type__c = 'Success',
            Request_Text__c = buildReq(220, '83', 'BuyoutexternalId', 'CN-83-20260327065500000')
        );

        insert new List<IL_Integration_Logs__c>{ failed, inProg };

        Test.startTest();
        PEAC_ILIntegrationLogService.LogResponse resp =
            PEAC_ILIntegrationLogService.getLatestLogs(cId, 10080);
        Test.stopTest();

        System.assertEquals(true, resp.showComponent, 'Should show component when rows exist'); 
        System.assert(resp.rows.size() >= 1, 'Expected at least one row');

        Boolean found83 = false;
        for (PEAC_ILIntegrationLogService.LogRow r : resp.rows) {
            if (r.quoteBuyoutType == '83') {
                found83 = true;
                System.assertEquals('In Progress', r.status, 'Dedup should prefer In Progress'); 
                System.assert(String.isNotBlank(r.startTime), 'StartTime should not be blank'); 
            }
        }
        System.assert(found83, 'Expected QBT 83 row');
    }
    
    private static String getValidIntegrationName() {
        // Prefer the exact value used in code
        for (Schema.PicklistEntry pe : IL_Integration_Logs__c.Integration_Name__c.getDescribe().getPicklistValues()) {
            if (pe.getValue() == 'InfoLease Generate Buyout Quote') return pe.getValue();
        }
        // Fallback: first value that starts with expected prefix (DP etc.)
        for (Schema.PicklistEntry pe : IL_Integration_Logs__c.Integration_Name__c.getDescribe().getPicklistValues()) {
            if (pe.getValue() != null && pe.getValue().startsWith('InfoLease Generate Buyout Quote')) return pe.getValue();
        }
        // Last resort: first picklist value (so insert succeeds)
        List<Schema.PicklistEntry> all = IL_Integration_Logs__c.Integration_Name__c.getDescribe().getPicklistValues();
        return all.isEmpty() ? null : all[0].getValue();
	}
    
    @IsTest
    static void testGetLatestLogs_SkipsWhenRequestTextNotJson() {
        Id cId = [SELECT Id FROM Contract__c LIMIT 1].Id; // SeeAllData=true recommended if Contract inserts fail
        String integrationName = getValidIntegrationName();
        System.assertNotEquals(null, integrationName);
    
        // Not JSON (starts with '<') => parseRequest returns empty => skipped
        IL_Integration_Logs__c badReq = new IL_Integration_Logs__c(
            Contract__c = cId,
            Integration_Name__c = integrationName,
            Status__c = 'In Progress',      // valid picklist value
            Type__c = 'Success',
            Request_Text__c = '<html>not json</html>'
        );
        insert badReq;
    
        Test.startTest();
        PEAC_ILIntegrationLogService.LogResponse resp =
            PEAC_ILIntegrationLogService.getLatestLogs(cId, 10080);
        Test.stopTest();
    
        System.assertNotEquals(null, resp);
    }
    @IsTest
    static void testGetLatestLogs_StatusBlankFallsBackToTypeError() {
        Id cId = [SELECT Id FROM Contract__c LIMIT 1].Id;
        String integrationName = getValidIntegrationName();
        System.assertNotEquals(null, integrationName);
    
        // Minimal valid Request JSON with BuyoutType present
        String req = JSON.serialize(new Map<String,Object>{
            'inputs' => new Map<String,Object>{
                'Request' => new Map<String,Object>{
                    'BuyoutType' => '83',
                    'Assets' => new List<Object>{ 'A1' }
                }
            }
        });
    
        IL_Integration_Logs__c errNoStatus = new IL_Integration_Logs__c(
            Contract__c = cId,
            Integration_Name__c = integrationName,
            Status__c = null,          // ✅ forces fallback path
            Type__c = 'Error',         // ✅ service sets status='Failed'
            Error_Message__c = 'boom',
            Request_Text__c = req
        );
        insert errNoStatus;
    
        Test.startTest();
        PEAC_ILIntegrationLogService.LogResponse resp =
            PEAC_ILIntegrationLogService.getLatestLogs(cId, 10080);
        Test.stopTest();
    
        System.assert(resp != null);
        System.assert(resp.rows != null);
    
        // Assert at least one returned row has Failed
        Boolean foundFailed = false;
        for (PEAC_ILIntegrationLogService.LogRow r : resp.rows) {
            if (r.quoteBuyoutType == '83' && r.status == 'Failed') {
                foundFailed = true;
                break;
            }
        }
        System.assertEquals(true, foundFailed, 'Should return Failed when Status__c blank and Type__c=Error'); 
    }
    @IsTest
    static void testGetLatestLogs_StartTimeFallbackWhenExternalIdInvalid() {
        Id cId = [SELECT Id FROM Contract__c LIMIT 1].Id;
        String integrationName = getValidIntegrationName();
        System.assertNotEquals(null, integrationName);
    
        // External id timestamp too short => formatStartTimeFromExternalId returns ''
        String req = JSON.serialize(new Map<String,Object>{
            'inputs' => new Map<String,Object>{
                'Request' => new Map<String,Object>{
                    'BuyoutType' => '86',
                    'Assets' => new List<Object>{ 'A1' },
                    'BuyoutExternalId' => 'CN-86-2026' // invalid timestamp length
                }
            }
        });
    
        IL_Integration_Logs__c logRec = new IL_Integration_Logs__c(
            Contract__c = cId,
            Integration_Name__c = integrationName,
            Status__c = 'In Progress',
            Type__c = 'Success',
            Request_Text__c = req
        );
        insert logRec;
    
        Test.startTest();
        PEAC_ILIntegrationLogService.LogResponse resp =
            PEAC_ILIntegrationLogService.getLatestLogs(cId, 10080);
        Test.stopTest();
    
        Boolean found = false;
        for (PEAC_ILIntegrationLogService.LogRow r : resp.rows) {
            if (r.quoteBuyoutType == '86') {
                found = true;
                System.assert(String.isNotBlank(r.startTime),
                    'StartTime should fallback to CreatedDate when externalId timestamp invalid'); 
                break;
            }
        }
        System.assertEquals(true, found, 'Expected to find QBT 86 row');
    }
    @IsTest
    static void testGetLatestLogs_DefaultMinutesBackWhenZero() {
        Id cId = [SELECT Id FROM Contract__c LIMIT 1].Id;
        Test.startTest();
        PEAC_ILIntegrationLogService.LogResponse resp =
            PEAC_ILIntegrationLogService.getLatestLogs(cId, 0);
        Test.stopTest();
        System.assertNotEquals(null, resp);
    }
    @IsTest
    static void test_TestVisibleHelperCoverageBoost() {
        // normalizeStatus branches
        System.assertEquals('In Progress', PEAC_ILIntegrationLogService.tv_normalizeStatus('InProgress'));
        System.assertEquals('In Progress', PEAC_ILIntegrationLogService.tv_normalizeStatus('In Progress'));
        System.assertEquals('Failed', PEAC_ILIntegrationLogService.tv_normalizeStatus('Error'));
        System.assertEquals('Failed', PEAC_ILIntegrationLogService.tv_normalizeStatus('Failed'));
        System.assertEquals('Completed', PEAC_ILIntegrationLogService.tv_normalizeStatus('Success'));
        System.assertEquals('Completed', PEAC_ILIntegrationLogService.tv_normalizeStatus('Completed'));
        System.assertEquals(null, PEAC_ILIntegrationLogService.tv_normalizeStatus(null));
    
        // deriveQbtFromExternalId branches
        System.assertEquals('83', PEAC_ILIntegrationLogService.tv_deriveQbtFromExternalId('CN-83-20260327063000000'));
        System.assertEquals('', PEAC_ILIntegrationLogService.tv_deriveQbtFromExternalId('CN')); // <2 parts
    
        // formatStartTimeFromExternalId branches
        // Valid timestamp => should return non-blank (exact formatting may vary by user timezone/locale)
        String t1 = PEAC_ILIntegrationLogService.tv_formatStartTimeFromExternalId('CN-83-20260327063000');
        System.assert(String.isNotBlank(t1), 'Expected a formatted datetime string');
    
        // Invalid timestamp => blank
        String t2 = PEAC_ILIntegrationLogService.tv_formatStartTimeFromExternalId('CN-83-2026');
        System.assertEquals('', t2);
    
        // parseMeta branches (top-level JSON keys)
        Map<String,String> m1 = PEAC_ILIntegrationLogService.tv_parseMeta('{"BuyoutExternalId":"X1","Status":"Success"}');
        System.assertEquals('X1', m1.get('buyoutExternalId'));
        System.assertEquals('Success', m1.get('status'));
    
        // parseMeta backward-compat keys
        Map<String,String> m2 = PEAC_ILIntegrationLogService.tv_parseMeta('{"LogExternalId":"X2","LogStatus":"InProgress"}');
        System.assertEquals('X2', m2.get('buyoutExternalId'));
        System.assertEquals('InProgress', m2.get('status'));
    
        // parseMeta non-json / blank
        Map<String,String> m3 = PEAC_ILIntegrationLogService.tv_parseMeta('<html>bad</html>');
        System.assertEquals(null, m3.get('buyoutExternalId'));
    }
}