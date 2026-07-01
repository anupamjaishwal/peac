/********************************************************************************************************************
@Author:Suraj Harichandan(LTIMindtree)
@Description: Test Class for PEAC_DisplayGuidanceLineAmtMessageClass
@User Story:SAL-6483
@Created Date:February/11/2026 	    
*********************************************************************************************************************/
@isTest
private class PEAC_DisplayGuidanceLineAmtMsgTest {

    @TestSetup
    static void makeDataTest() {
        // Create End User Account record type
        Id endUserRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
        
        // Create Infolease Group Code record
        Infolease_Group_Code__c groupCode = new Infolease_Group_Code__c(
            Name = 'Test Group Code',
            IL_Group_Code_ID__c = 'TESTGRP001'
        );
        insert groupCode;
        
        // Account WITH Infolease Group Code (group code path)
        Account accWithGroup = new Account(
            Name = 'Test End User Group',
            RecordTypeId = endUserRTId,
            Infolease_Group_Code__c = groupCode.Id
        );
        
        // Account WITHOUT Infolease Group Code (direct end-user path)
        Account accNoGroup = new Account(
            Name = 'Test End User Direct',
            RecordTypeId = endUserRTId
        );
        
        insert new List<Account>{accWithGroup, accNoGroup};
        
        // Create Opportunities (Equipment_Cost_w_o_Tax__c is a rollup summary of Asset__c.List_Price__c)
        Opportunity oppGroup = new Opportunity(
            Name = 'Test Opp Group',
            AccountId = accWithGroup.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        
        Opportunity oppDirect = new Opportunity(
            Name = 'Test Opp Direct',
            AccountId = accNoGroup.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        
        insert new List<Opportunity>{oppGroup, oppDirect};
        
        // Create active Guidance Line Amounts
        // GLA for group account
        Guidance_Line_Amount__c glaForGroup = new Guidance_Line_Amount__c(
            Account__c = accWithGroup.Id,
            Guidance_Amount__c = 15000.00,
            Start_Date__c = Date.today().addDays(-30),
            End_Date__c = Date.today().addDays(365)
        );
        
        // GLA for direct account
        Guidance_Line_Amount__c glaForDirect = new Guidance_Line_Amount__c(
            Account__c = accNoGroup.Id,
            Guidance_Amount__c = 50000.00,
            Start_Date__c = Date.today().addDays(-30),
            End_Date__c = Date.today().addDays(365)
        );
        
        insert new List<Guidance_Line_Amount__c>{glaForGroup, glaForDirect};
    }

    // ─── Helper Methods ───────────────────────────────────────────────────────

    private static Account getAccountByName(String name) {
        return [SELECT Id, Infolease_Group_Code__c, Total_Equipment_Cost_w_o_Tax__c 
                FROM Account WHERE Name = :name LIMIT 1];
    }

    private static Opportunity getOppByName(String name) {
        return [SELECT Id, AccountId, Account.Infolease_Group_Code__c 
                FROM Opportunity WHERE Name = :name LIMIT 1];
    }

    // ─── Test: getGuidanceAmessage — Opp with group code path (lines 19-44) ──

    @isTest
    static void testGetGuidanceMsg_Opp_GroupCode() {
        Opportunity opp = getOppByName('Test Opp Group');
        
        Test.startTest();
        // Exercises: objectName == 'Opportunity' path (line 23-25),
        // getAccountId (lines 73-78), getGuidanceAmounts call (line 34),
        // and the if-check with Infolease_Group_Code__c (lines 36-37)
        Boolean result = PEAC_DisplayGuidanceLineAmtMessageClass.getGuidanceAmessage(opp.Id, 'Opportunity');
        Test.stopTest();
        
        // Without Asset__c records, Equipment_Cost_w_o_Tax__c = 0 which is < Guidance_Amount__c,
        // so getGuidanceAmounts returns empty set and result should be false
        System.assertEquals(false, result, 'Should return false when no equipment cost data');
    }

    // ─── Test: getGuidanceAmessage — Opp without group code path ─────────────

    @isTest
    static void testGetGuidanceMsg_Opp_NoGroupCode() {
        Opportunity opp = getOppByName('Test Opp Direct');
        
        Test.startTest();
        // Exercises direct end-user path (no Infolease_Group_Code__c)
        Boolean result = PEAC_DisplayGuidanceLineAmtMessageClass.getGuidanceAmessage(opp.Id, 'Opportunity');
        Test.stopTest();
        
        System.assertEquals(false, result, 'Should return false when equipment cost is under guidance amount');
    }

    // ─── Test: getGuidanceAmessage — Asset path triggers catch block ──────────

    @isTest
    static void testGetGuidanceMsg_Asset_CatchBlock() {
        // Use a fabricated Asset Id — getOppId returns '', getAccountId('') returns empty list,
        // causing IndexOutOfBoundsException caught in the catch block
        String fakeAssetId = Asset__c.SObjectType.getDescribe().getKeyPrefix() + '000000000000';
        
        Test.startTest();
        try {
            PEAC_DisplayGuidanceLineAmtMessageClass.getGuidanceAmessage(fakeAssetId, 'Asset');
            System.assert(false, 'Expected AuraHandledException was not thrown');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e.getMessage(), 'Exception message should not be null');
        }
        Test.stopTest();
    }

    // ─── Test: getGuidanceAmessage — Invalid Opp Id triggers catch block ─────

    @isTest
    static void testGetGuidanceMsg_InvalidId() {
        String fakeOppId = '006000000000000AAA';
        
        Test.startTest();
        try {
            PEAC_DisplayGuidanceLineAmtMessageClass.getGuidanceAmessage(fakeOppId, 'Opportunity');
            System.assert(false, 'Expected AuraHandledException was not thrown');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e.getMessage(), 'Exception message should not be null');
        }
        Test.stopTest();
    }

    // ─── Test: getOppId — Non-existent Asset returns empty string ────────────

    @isTest
    static void testGetOppId_NoAsset() {
        String fakeAssetId = Asset__c.SObjectType.getDescribe().getKeyPrefix() + '000000000000';
        
        Test.startTest();
        String result = PEAC_DisplayGuidanceLineAmtMessageClass.getOppId(fakeAssetId);
        Test.stopTest();
        
        System.assertEquals('', result, 'getOppId should return empty string for non-existent Asset');
    }

    // ─── Test: getAccountId — Valid Opportunity ──────────────────────────────

    @isTest
    static void testGetAccountId_Valid() {
        Opportunity opp = getOppByName('Test Opp Group');
        
        Test.startTest();
        List<Opportunity> result = PEAC_DisplayGuidanceLineAmtMessageClass.getAccountId(opp.Id);
        Test.stopTest();
        
        System.assertEquals(1, result.size(), 'Should return exactly one Opportunity');
        System.assertEquals(opp.Id, result[0].Id, 'Returned Opportunity should match queried Id');
        System.assertNotEquals(null, result[0].AccountId, 'AccountId should be populated');
    }

    // ─── Test: getGuidanceLineWarning — Valid inputs ─────────────────────────

    @isTest
    static void testGetGuidanceLineWarning_ValidInput() {
        Opportunity opp = getOppByName('Test Opp Group');
        
        Test.startTest();
        // Exercises lines 90-110: result map creation, blank-check (lines 96-97),
        // getGuidanceAmessage call (line 100), and the if-block (lines 102-108)
        Map<String, Object> result = PEAC_DisplayGuidanceLineAmtMessageClass.getGuidanceLineWarning(opp.Id, 'Opportunity');
        Test.stopTest();
        
        // Without Asset records, showWarning = false, but the full path is exercised
        System.assertNotEquals(null, result, 'Result map should not be null');
        System.assert(result.containsKey('showWarning'), 'Result should contain showWarning key');
        System.assert(result.containsKey('message'), 'Result should contain message key');
    }

    // ─── Test: getGuidanceLineWarning — Blank Inputs (early return) ─────────

    @isTest
    static void testGetGuidanceLineWarning_Blank() {
        Test.startTest();
        Map<String, Object> result = PEAC_DisplayGuidanceLineAmtMessageClass.getGuidanceLineWarning('', '');
        Test.stopTest();
        
        System.assertEquals(false, result.get('showWarning'), 
            'showWarning should be false for blank inputs');
        System.assertEquals(null, result.get('message'), 
            'message should be null for blank inputs');
    }
}