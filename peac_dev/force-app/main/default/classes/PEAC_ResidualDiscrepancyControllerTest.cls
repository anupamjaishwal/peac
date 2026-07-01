/********************************************************************************************************************
 * @author            : Suraj Harichandan(LTM)
 * @created date      : 2026-04-03
 * @description       : Test class for PEAC_ResidualDiscrepancyController (SAL-5654).
 *                     
 *
 *
 * Test Scenarios:
 *   1. testDispatcher_processingStatus    — Opp with discrepancy → status = 'processing', @future enqueued instantly
 *   2. testDispatcher_noDiscrepancy       — Opp where values already match → status = 'no_discrepancy', early return
 *   3. testAsync_updatesOpportunityFields — @future executes via Test.stopTest(); verifies Residual__c,
 *                                           Equipment_Cost__c, Number_of_Units__c, Gross_Finance__c updated
 *   4. testAsync_bypassSettingsRestored   — After @future, verifies ORE__c.Bypass__c and both
 *                                           DeactivateTriggers__c.IsDeactived__c values are restored
 *                                           to their originals (validates the finally blocks)
 *   5. testDispatcher_invalidId           — Null Id passed → catch block fires → status = 'error'
 ********************************************************************************************************************/
@isTest
public with sharing class PEAC_ResidualDiscrepancyControllerTest {

    @TestSetup
    static void testSetup() {
        // ORE__c is a Hierarchy custom setting — insert an org-level record with Bypass__c = true
        // to suppress validation rules during test data creation.
        insert new ORE__c(Bypass__c = true);

        // DeactivateTriggers__c is a List custom setting — NOT visible in tests by default.
        // Insert both records to simulate the real sandbox state and suppress trigger cascades
        // while creating test data (IsDeactived__c = true — consistent with other test classes in this org).
        insert new DeactivateTriggers__c(Name = 'TC_OpportunityTrigger', IsDeactived__c = true, ObjectName__c = 'Opportunity');
        insert new DeactivateTriggers__c(Name = 'PEAC_AssetTrigger',     IsDeactived__c = true);

        // Create a test Account using End User Account RecordType (verified in org)
        Account acc = new Account(
            Name         = 'PEAC Residual Test Account',
            RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'End User Account' AND SObjectType = 'Account' LIMIT 1].Id
        );
        insert acc;

        // Create a test Opportunity using Express Decision RecordType.
        // Required fields pattern sourced from TC_CalculateAssetCostTest (existing org pattern).
        Opportunity opp = new Opportunity(
            Name                     = 'PEAC Residual Discrepancy Test Opp',
            AccountId                = acc.Id,
            StageName                = 'Decision',
            CloseDate                = Date.today().addDays(30),
            Primary_Source__c        = 'Customer Inbound - Call',
            RecordTypeId             = [SELECT Id FROM RecordType WHERE Name = 'Express Decision' AND SObjectType = 'Opportunity' LIMIT 1].Id,
            of_Payments__c           = 24,
            Terms__c                 = 60,
            Payment_Frequency__c     = 'Monthly',
            Equipment_Description__c = 'Test Equipment',
            FraudReviewFlag__c       = 1,
            Gross_Contract__c        = 20000  // Used to compute Gross_Finance__c in @future
        );
        insert opp;

        // Create 2 child Assets — @future will sum these:
        //   sumResidual = 1500, sumCost = 8000, sumQuantity = 3
        List<Asset__c> assets = new List<Asset__c>{
            new Asset__c(Opportunity__c = opp.Id, Cost__c = 5000, Residual_Amount__c = 1000, Quantity__c = 1),
            new Asset__c(Opportunity__c = opp.Id, Cost__c = 3000, Residual_Amount__c = 500,  Quantity__c = 2)
        };
        insert assets;

        // Force a residual discrepancy: corrupt Residual__c to a stale/incorrect value.
        // This simulates the broken Opportunity state that makes the banner visible.
        // ORE__c.Bypass__c = true (inserted above) prevents validation rules from blocking this.
        Opportunity insertedOpp = [SELECT Id FROM Opportunity WHERE Id = :opp.Id];
        insertedOpp.Residual__c = 9999;
        update insertedOpp;
    }

    /**
     * Scenario 1: testDispatcher_processingStatus
     * Verifies that when a genuine residual discrepancy exists, the dispatcher immediately
     * returns status = 'processing' and enqueues the @future without blocking the transaction.
     */
    @isTest
    static void testDispatcher_processingStatus() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'PEAC Residual Discrepancy Test Opp' LIMIT 1];

        Test.startTest();
        Map<String, Object> result = PEAC_ResidualDiscrepancyController.resolveResidualDiscrepancy(opp.Id);
        Test.stopTest();

        System.assertEquals('processing', result.get('status'), 'Expected status = processing when discrepancy exists');
        System.assertNotEquals(null, result.get('message'), 'Expected a non-null message');
        System.assertEquals('Recalculation in progress.', result.get('message'), 'Expected processing message');
    }

    /**
     * Scenario 2: testDispatcher_noDiscrepancy
     * Verifies the early-exit path when Residual__c already matches Total_Asset_Residual__c.
     * Uses a fresh Opp with no child Assets so both values compute to 0 — no discrepancy.
     */
    @isTest
    static void testDispatcher_noDiscrepancy() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'PEAC Residual Test Account' LIMIT 1];

        // Opp with no Assets: Total_Asset_Residual__c = 0 (rollup), Residual__c = null (→ 0 after ?? 0)
        // Both sides compute to 0.00 → rollup == current → early exit
        Opportunity matchedOpp = new Opportunity(
            Name                     = 'PEAC Matched Residual Opp',
            AccountId                = acc.Id,
            StageName                = 'Decision',
            CloseDate                = Date.today().addDays(30),
            Primary_Source__c        = 'Customer Inbound - Call',
            RecordTypeId             = [SELECT Id FROM RecordType WHERE Name = 'Express Decision' AND SObjectType = 'Opportunity' LIMIT 1].Id,
            of_Payments__c           = 24,
            Terms__c                 = 60,
            Payment_Frequency__c     = 'Monthly',
            Equipment_Description__c = 'Test Equipment',
            FraudReviewFlag__c       = 1
        );
        insert matchedOpp;

        Test.startTest();
        Map<String, Object> result = PEAC_ResidualDiscrepancyController.resolveResidualDiscrepancy(matchedOpp.Id);
        Test.stopTest();

        System.assertEquals('no_discrepancy', result.get('status'), 'Expected status = no_discrepancy when values already match');
        System.assert(String.valueOf(result.get('message')).contains('already matches'), 'Expected "already matches" in message');
    }

    /**
     * Scenario 3: testAsync_updatesOpportunityFields
     * Verifies that the @future worker (flushed synchronously by Test.stopTest()) correctly
     * sums child Asset fields and writes them to the Opportunity:
     *   Residual__c      = 1500 (1000 + 500)
     *   Equipment_Cost__c = 8000 (5000 + 3000)
     *   Number_of_Units__c = 3   (1 + 2)
     *   Gross_Finance__c = 12000 (Gross_Contract__c 20000 - sumCost 8000)
     */
    @isTest
    static void testAsync_updatesOpportunityFields() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'PEAC Residual Discrepancy Test Opp' LIMIT 1];

        Test.startTest();
        PEAC_ResidualDiscrepancyController.resolveResidualDiscrepancy(opp.Id);
        Test.stopTest(); // resolveResidualAsync() executes synchronously here

        Opportunity updated = [
            SELECT Residual__c, Equipment_Cost__c, Number_of_Units__c, Gross_Finance__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        System.assertEquals(1500, updated.Residual__c,         'Residual__c should equal sum of Asset Residual_Amount__c (1000 + 500)');
        System.assertEquals(8000, updated.Equipment_Cost__c,   'Equipment_Cost__c should equal sum of Asset Cost__c (5000 + 3000)');
        System.assertEquals(3,    updated.Number_of_Units__c,  'Number_of_Units__c should equal sum of Asset Quantity__c (1 + 2)');
        System.assertEquals(12000, updated.Gross_Finance__c,   'Gross_Finance__c should equal Gross_Contract__c (20000) - sumCost (8000)');
    }

    /**
     * Scenario 4: testAsync_bypassSettingsRestored
     * Verifies that after the @future completes, the finally blocks correctly restore
     * all bypass settings:
     *   - ORE__c.Bypass__c                              → restored to original (true, as set in testSetup)
     *   - DeactivateTriggers__c 'TC_OpportunityTrigger' → IsDeactived__c restored to original (true)
     *   - DeactivateTriggers__c 'PEAC_AssetTrigger'     → IsDeactived__c restored to original (true)
     */
    @isTest
    static void testAsync_bypassSettingsRestored() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'PEAC Residual Discrepancy Test Opp' LIMIT 1];

        Test.startTest();
        PEAC_ResidualDiscrepancyController.resolveResidualDiscrepancy(opp.Id);
        Test.stopTest();

        // ORE__c.Bypass__c should be restored to its original value (true — set in testSetup)
        ORE__c ore = ORE__c.getInstance();
        System.assertNotEquals(null, ore, 'ORE__c record should exist');
        System.assertEquals(true, ore.Bypass__c, 'ORE__c.Bypass__c should be restored to original value (true) after @future');

        // DeactivateTriggers__c should be restored to their original values (IsDeactived__c = true)
        DeactivateTriggers__c dtOpp = DeactivateTriggers__c.getInstance('TC_OpportunityTrigger');
        System.assertNotEquals(null, dtOpp, 'TC_OpportunityTrigger DeactivateTriggers__c record should exist');
        System.assertEquals(true, dtOpp.IsDeactived__c, 'TC_OpportunityTrigger should be restored to IsDeactived__c = true (original)');

        DeactivateTriggers__c dtAsset = DeactivateTriggers__c.getInstance('PEAC_AssetTrigger');
        System.assertNotEquals(null, dtAsset, 'PEAC_AssetTrigger DeactivateTriggers__c record should exist');
        System.assertEquals(true, dtAsset.IsDeactived__c, 'PEAC_AssetTrigger should be restored to IsDeactived__c = true (original)');
    }

    /**
     * Scenario 5: testDispatcher_invalidId
     * Verifies the exception-handling path in the dispatcher: passing a null Id causes
     * the Opportunity SOQL to throw a NullPointerException, which the catch block handles
     * gracefully by returning status = 'error' without propagating the exception.
     */
    @isTest
    static void testDispatcher_invalidId() {
        Test.startTest();
        Map<String, Object> result = PEAC_ResidualDiscrepancyController.resolveResidualDiscrepancy(null);
        Test.stopTest();

        System.assertEquals('error', result.get('status'), 'Expected status = error for null opportunityId');
        System.assertNotEquals(null, result.get('message'), 'Expected an error message to be populated');
        System.assert(String.valueOf(result.get('message')).startsWith('Error: '), 'Message should begin with "Error: "');
    }
}