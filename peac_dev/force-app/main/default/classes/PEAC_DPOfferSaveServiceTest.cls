@IsTest
public class PEAC_DPOfferSaveServiceTest {

    @testSetup
    static void setupData() {
        User adminUser = SL_SCTestData.createTestUser();

        System.runAs(adminUser) {
            PEAC_GenerateTaxMatrixBatch.isRunning = true;
            SL_SCTestData.createBridgeWareSetting();
            deactivateAssetTrigger();

            SL_SCTestData.createAccountAndContracts(1, 1);

            Account testAccount = [SELECT Id FROM Account LIMIT 1];

            Opportunity opp = new Opportunity(
                AccountId = testAccount.Id,
                Name = 'DP Offer Save Service Test Opp',
                StageName = 'Proposal',
                CloseDate = Date.today().addDays(30),
                Purchase_Options__c = 'FMV',
                Required_Adv_Payments__c = 1,
                Terms__c = 24,
                Max_Term_Approved__c = 36,
                Equipment_Cost__c = 12000,
                Approved_Amount__c = 15000,
                Payment_Amount__c = 450
            );
            insert opp;

            Asset__c assetRec = buildTestAsset(opp.Id, 12000, 'Model A', 'SN-001');
            insert assetRec;

            insert new Pricing_Result__c(
                Opportunity__c = opp.Id,
                Status__c = 'Success',
                Error_Message__c = null
            );
        }
    }

    @IsTest
    static void testGetOfferDataReturnsOpportunityData() {
        Opportunity opp = [
            SELECT Id, Payment_Amount__c
            FROM Opportunity
            LIMIT 1
        ];

        Test.startTest();
        PEAC_DPOfferSaveService.PEAC_OfferDataResponse response =
            PEAC_DPOfferSaveService.getOfferData(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, response, 'Response should not be null.');
        System.assertEquals(opp.Id, response.opportunityId, 'Opportunity Id should match.');
        System.assertEquals(opp.Payment_Amount__c, response.monthlyPayment, 'Monthly payment should come from Opportunity.');
        System.assertNotEquals(null, response.assets, 'Assets list should be initialized.');
        System.assertNotEquals(null, response.equipmentCodeOptions, 'Equipment code options should be initialized.');
    }

    @IsTest
    static void testGetOfferDataRequiresOpportunityId() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            PEAC_DPOfferSaveService.getOfferData(null);
        } catch (AuraHandledException ex) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'Expected AuraHandledException when Opportunity Id is null.');
    }

    @IsTest
    static void testGetLeasePricingTrackedFields() {
        Test.startTest();
        List<PEAC_DPOfferSaveService.PEAC_TrackedFieldDTO> trackedFields =
            PEAC_DPOfferSaveService.getLeasePricingTrackedFields();
        Test.stopTest();

        System.assertNotEquals(null, trackedFields, 'Tracked fields response should not be null.');
    }

    @IsTest
    static void testGetLatestPricingResultStatusReturnsLatestResult() {
        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            LIMIT 1
        ];

        Test.startTest();
        PEAC_DPOfferSaveService.PEAC_PricingResultStatusDTO response =
            PEAC_DPOfferSaveService.getLatestPricingResultStatus(opp.Id, null);
        Test.stopTest();

        System.assertNotEquals(null, response, 'Response should not be null.');
        System.assertEquals(true, response.hasPricingResult, 'Pricing result should exist.');
        System.assertEquals('Success', response.pricingResultStatus, 'Latest pricing result status should be returned.');
    }

    @IsTest
    static void testGetLatestPricingResultStatusWithNullId() {
        Test.startTest();
        PEAC_DPOfferSaveService.PEAC_PricingResultStatusDTO response =
            PEAC_DPOfferSaveService.getLatestPricingResultStatus(null, null);
        Test.stopTest();

        System.assertNotEquals(null, response, 'Response should not be null.');
        System.assertEquals(false, response.hasPricingResult, 'Null Opportunity Id should return no pricing result.');
    }

    @IsTest
    static void testSaveOfferChangesWithNullOpportunityId() {
        Test.startTest();
        PEAC_DPOfferSaveService.PEAC_SaveOfferResponse response =
            PEAC_DPOfferSaveService.saveOfferChanges(null, null, null, false);
        Test.stopTest();

        System.assertEquals(false, response.success, 'Save should fail when Opportunity Id is null.');
        System.assertEquals('Opportunity Id is required.', response.message);
    }

    @IsTest
    static void testSaveOfferChangesWithNoChanges() {
        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            LIMIT 1
        ];

        Test.startTest();
        PEAC_DPOfferSaveService.PEAC_SaveOfferResponse response =
            PEAC_DPOfferSaveService.saveOfferChanges(opp.Id, null, null, false);
        Test.stopTest();

        System.assertEquals(true, response.success, 'No changes response should be successful.');
        System.assertEquals(false, response.didSaveChanges, 'No changes should be saved.');
        System.assertEquals('No changes to save.', response.message);
    }

    @IsTest
    static void testSaveOfferChangesIgnoresInvalidOpportunityFields() {
        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            LIMIT 1
        ];

        Map<String, Object> opportunityChanges = new Map<String, Object>{
            'Not_A_Real_Field__c' => 'Invalid'
        };

        Test.startTest();
        PEAC_DPOfferSaveService.PEAC_SaveOfferResponse response =
            PEAC_DPOfferSaveService.saveOfferChanges(
                opp.Id,
                opportunityChanges,
                null,
                false
            );
        Test.stopTest();

        System.assertEquals(true, response.success, 'Response should still be successful.');
        System.assertEquals(false, response.didSaveChanges, 'No valid changes should be saved.');
        System.assertEquals('No valid changes to save.', response.message);
    }

    @IsTest
    static void testSaveOfferChangesUpdatesOpportunity() {
        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            LIMIT 1
        ];

        Map<String, Object> opportunityChanges = new Map<String, Object>{
            'Terms__c' => 36,
            'Payment_Amount__c' => 525
        };

        Test.startTest();
        PEAC_DPOfferSaveService.PEAC_SaveOfferResponse response =
            PEAC_DPOfferSaveService.saveOfferChanges(
                opp.Id,
                opportunityChanges,
                null,
                false
            );
        Test.stopTest();

        System.assertEquals(true, response.success, 'Save should be successful.');
        System.assertEquals(true, response.didSaveChanges, 'Opportunity changes should be saved.');

        Opportunity refreshedOpp = [
            SELECT Id, Terms__c, Payment_Amount__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        System.assertEquals(36, refreshedOpp.Terms__c, 'Terms should be updated.');
        System.assertEquals(null, refreshedOpp.Payment_Amount__c, 'Payment amount should be cleared after tracked pricing field update.');
    }

    @IsTest
    static void testSaveOfferChangesInsertsAsset() {
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        deactivateAssetTrigger();
        Test.setMock(HttpCalloutMock.class, new TC_BridgewareSelectZipGeoCalloutMockImpl());

        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            LIMIT 1
        ];

        Integer beforeCount = [
            SELECT COUNT()
            FROM Asset__c
            WHERE Opportunity__c = :opp.Id
        ];

        PEAC_DPOfferSaveService.PEAC_AssetChangeDTO assetChange =
            new PEAC_DPOfferSaveService.PEAC_AssetChangeDTO();

        assetChange.action = 'INSERT';
        assetChange.fields = buildAssetFieldMap(5000, 'Inserted Model', 'SN-INSERT');

        Test.startTest();
        PEAC_DPOfferSaveService.PEAC_SaveOfferResponse response =
            PEAC_DPOfferSaveService.saveOfferChanges(
                opp.Id,
                null,
                new List<PEAC_DPOfferSaveService.PEAC_AssetChangeDTO>{ assetChange },
                false
            );
        Test.stopTest();

        System.assertEquals(true, response.success, 'Asset insert save should be successful.');
        System.assertEquals(true, response.didSaveChanges, 'Asset insert should count as saved changes.');

        Integer afterCount = [
            SELECT COUNT()
            FROM Asset__c
            WHERE Opportunity__c = :opp.Id
        ];

        System.assertEquals(beforeCount + 1, afterCount, 'One asset should be inserted.');
    }

    @IsTest
    static void testSaveOfferChangesUpdatesAsset() {
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        deactivateAssetTrigger();

        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            LIMIT 1
        ];

        Asset__c existingAsset = [
            SELECT Id, Cost__c, Model__c
            FROM Asset__c
            WHERE Opportunity__c = :opp.Id
            LIMIT 1
        ];

        PEAC_DPOfferSaveService.PEAC_AssetChangeDTO assetChange =
            new PEAC_DPOfferSaveService.PEAC_AssetChangeDTO();

        assetChange.action = 'UPDATE';
        assetChange.recordId = existingAsset.Id;
        assetChange.fields = new Map<String, Object>{
            'Cost__c' => 8000,
            'Model__c' => 'Updated Model'
        };

        Test.startTest();
        PEAC_DPOfferSaveService.PEAC_SaveOfferResponse response =
            PEAC_DPOfferSaveService.saveOfferChanges(
                opp.Id,
                null,
                new List<PEAC_DPOfferSaveService.PEAC_AssetChangeDTO>{ assetChange },
                false
            );
        Test.stopTest();

        System.assertEquals(true, response.success, 'Asset update save should be successful.');
        System.assertEquals(true, response.didSaveChanges, 'Asset update should count as saved changes.');

        Asset__c refreshedAsset = [
            SELECT Id, Cost__c, Model__c
            FROM Asset__c
            WHERE Id = :existingAsset.Id
        ];

        System.assertEquals(8000, refreshedAsset.Cost__c, 'Asset cost should be updated.');
        System.assertEquals('Updated Model', refreshedAsset.Model__c, 'Asset model should be updated.');
    }

    @IsTest
    static void testSaveOfferChangesDeletesAsset() {
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        deactivateAssetTrigger();

        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            LIMIT 1
        ];

        Asset__c existingAsset = [
            SELECT Id
            FROM Asset__c
            WHERE Opportunity__c = :opp.Id
            LIMIT 1
        ];

        PEAC_DPOfferSaveService.PEAC_AssetChangeDTO assetChange =
            new PEAC_DPOfferSaveService.PEAC_AssetChangeDTO();

        assetChange.action = 'DELETE';
        assetChange.recordId = existingAsset.Id;

        Test.startTest();
        PEAC_DPOfferSaveService.PEAC_SaveOfferResponse response =
            PEAC_DPOfferSaveService.saveOfferChanges(
                opp.Id,
                null,
                new List<PEAC_DPOfferSaveService.PEAC_AssetChangeDTO>{ assetChange },
                false
            );
        Test.stopTest();

        System.assertEquals(true, response.success, 'Asset delete save should be successful.');
        System.assertEquals(true, response.didSaveChanges, 'Asset delete should count as saved changes.');

        Integer assetCount = [
            SELECT COUNT()
            FROM Asset__c
            WHERE Id = :existingAsset.Id
        ];

        System.assertEquals(0, assetCount, 'Asset should be deleted.');
    }

    @IsTest
    static void testSaveOfferChangesUnsupportedAssetActionReturnsError() {
        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            LIMIT 1
        ];

        PEAC_DPOfferSaveService.PEAC_AssetChangeDTO assetChange =
            new PEAC_DPOfferSaveService.PEAC_AssetChangeDTO();

        assetChange.action = 'UPSERT';
        assetChange.fields = new Map<String, Object>{
            'Cost__c' => 100
        };

        Test.startTest();
        PEAC_DPOfferSaveService.PEAC_SaveOfferResponse response =
            PEAC_DPOfferSaveService.saveOfferChanges(
                opp.Id,
                null,
                new List<PEAC_DPOfferSaveService.PEAC_AssetChangeDTO>{ assetChange },
                false
            );
        Test.stopTest();

        System.assertEquals(false, response.success, 'Unsupported action should fail.');
        System.assert(
            String.isNotBlank(response.message),
            'Expected an error message for unsupported asset action.'
        );
    }

    private static Asset__c buildTestAsset(Id oppId, Decimal cost, String model, String serialNumber) {
        return new Asset__c(
            Opportunity__c = oppId,
            Equipment_Code__c = getAssetEquipmentCodeValue(),
            Cost__c = cost,
            Model__c = model,
            Serial_Number__c = serialNumber,
            Equipment_Location_City__c = 'City',
            Equipment_Location_State__c = 'CA',
            End_User_Billing_Address__c = true
        );
    }

    private static Map<String, Object> buildAssetFieldMap(Decimal cost, String model, String serialNumber) {
        return new Map<String, Object>{
            'Equipment_Code__c' => getAssetEquipmentCodeValue(),
            'Cost__c' => cost,
            'Model__c' => model,
            'Serial_Number__c' => serialNumber,
            'Equipment_Location_City__c' => 'City',
            'Equipment_Location_State__c' => 'CA',
            'End_User_Billing_Address__c' => true
        };
    }

    private static String getAssetEquipmentCodeValue() {
        List<Schema.PicklistEntry> entries =
            Asset__c.Equipment_Code__c.getDescribe().getPicklistValues();

        for (Schema.PicklistEntry pe : entries) {
            if (pe.isActive()) {
                return pe.getValue();
            }
        }

        return null;
    }

    private static void deactivateAssetTrigger() {
        DeactivateTriggers__c existingSetting =
            DeactivateTriggers__c.getInstance('PEAC_AssetTrigger');

        if (existingSetting != null && existingSetting.Id != null) {
            existingSetting.IsDeactived__c = true;
            update existingSetting;
        } else {
            insert new DeactivateTriggers__c(
                Name = 'PEAC_AssetTrigger',
                IsDeactived__c = true
            );
        }
    }
}