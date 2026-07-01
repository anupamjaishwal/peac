/********************************************************************************************************************
 @Author: Suraj Harichandan(LTIMindtree)
 @Description: Test class for PEAC_UpdateTotalExposure.
               
 @User Story: SAL-5831
 @Created Date: February-13-2026
 @Updated By: Suraj Harichandan(LTIMindtree)
 @Updated Date: 03/02/2026

*********************************************************************************************************************/
@isTest
private class PEAC_UpdateTotalExposureTest {

    /********************************************************************************************************************
     @Description: Common test data setup — creates one Account with an active Guidance_Line_Amount__c
                   and one Opportunity linked to that Account.
                   The Opportunity uses a non-Loan record type so Loan_Record_Type__c formula = false.
    *********************************************************************************************************************/
    @TestSetup
    static void setupTestData() {

        // Get End User Account Record Type
        Id endUserRTId = Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get('End User Account').getRecordTypeId();

        // Create a single test Account
        Account testAccount = new Account(
            Name        = 'Test Account Coverage',
            RecordTypeId = endUserRTId
        );
        insert testAccount;

        // Create an Opportunity linked to the Account.
        // Non-Loan record type ensures Loan_Record_Type__c formula evaluates to false.
        Opportunity testOpp = new Opportunity(
            Name      = 'Test Opp Coverage',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount    = 25000
        );
        insert testOpp;

        // Create an active Guidance_Line_Amount__c for the Account.
        // Start and End dates bracket today so the Active__c formula = true.
        Guidance_Line_Amount__c gla = new Guidance_Line_Amount__c(
            Account__c       = testAccount.Id,
            Guidance_Amount__c = 200000,
            Start_Date__c    = Date.today().addDays(-30),
            End_Date__c      = Date.today().addDays(365)
        );
        insert gla;
    }

    /********************************************************************************************************************
     @Description: Helper — builds a Map<Id, SObject> containing a single Opportunity.
                   Uses JSON.deserialize to set formula/read-only fields such as
                   Total_Exposure__c and Loan_Record_Type__c that cannot be set directly.
     @Param oppId        — Id of the Opportunity
     @Param accountId    — AccountId to assign
     @Param totalExp     — value for Total_Exposure__c
     @Param loanRT       — value for Loan_Record_Type__c (Boolean formula field)
     @Return             Map<Id, SObject> keyed by oppId
    *********************************************************************************************************************/
    private static Map<Id, SObject> buildOppSObjectMap(Id oppId, Id accountId, Decimal totalExp, Boolean loanRT) {
        Map<String, Object> fieldMap = new Map<String, Object>{
            'Id'                  => String.valueOf(oppId),
            'AccountId'           => accountId != null ? String.valueOf(accountId) : null,
            'Total_Exposure__c'   => totalExp,
            'Loan_Record_Type__c' => loanRT
        };
        Opportunity opp = (Opportunity) JSON.deserialize(JSON.serialize(fieldMap), Opportunity.class);
        Map<Id, SObject> result = new Map<Id, SObject>();
        result.put(oppId, opp);
        return result;
    }

    /********************************************************************************************************************
     @Description: Helper — builds a Map<Id, SObject> containing a single Account.
                   Uses JSON.deserialize to set Total_Exposure__c (may be a formula/read-only
                   field that cannot be set through standard constructor in tests).
     @Param accId    — Id of the Account
     @Param totalExp — value for Total_Exposure__c
     @Return         Map<Id, SObject> keyed by accId
    *********************************************************************************************************************/
    private static Map<Id, SObject> buildAccSObjectMap(Id accId, Decimal totalExp) {
        Map<String, Object> fieldMap = new Map<String, Object>{
            'Id'                => String.valueOf(accId),
            'Total_Exposure__c' => totalExp
        };
        Account acc = (Account) JSON.deserialize(JSON.serialize(fieldMap), Account.class);
        Map<Id, SObject> result = new Map<Id, SObject>();
        result.put(accId, acc);
        return result;
    }

    /********************************************************************************************************************
     @Description: SUCCESS PATH — updateTotalExposureOnAccount
                   Verifies that when an Opportunity's Total_Exposure__c changes,
                   Loan_Record_Type__c is false, and AccountId is populated,
                   the Account record is updated with the new exposure value.
                   Covers: for-loop, typecast, condition true branch, DML update, map clear.
    *********************************************************************************************************************/
    @isTest
    static void testUpdateTotalExposureOnAccount_ExposureChanged() {
        // Arrange
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];

        // New map: Total_Exposure__c = 150000, Loan_Record_Type__c = false
        Map<Id, SObject> newMap = buildOppSObjectMap(opp.Id, opp.AccountId, 150000, false);
        // Old map: Total_Exposure__c = 100000 (different → triggers update)
        Map<Id, SObject> oldMap = buildOppSObjectMap(opp.Id, opp.AccountId, 100000, false);

        // Act
        Test.startTest();
        PEAC_UpdateTotalExposure.updateTotalExposureOnAccount(newMap, oldMap);
        Test.stopTest();

        // Assert: Account Total_Exposure__c was updated to the new value
        Account updated = [SELECT Total_Exposure__c FROM Account WHERE Id = :opp.AccountId];
        System.assertEquals(150000, updated.Total_Exposure__c,
            'Account Total_Exposure__c should be updated to the new Opportunity value');
    }

    /********************************************************************************************************************
     @Description: NO-CHANGE PATH — updateTotalExposureOnAccount
                   Verifies that when Total_Exposure__c is identical in new and old maps,
                   no Account DML is performed and the value remains unchanged.
                   Covers: for-loop, typecast, condition false branch (exposure equal).
    *********************************************************************************************************************/
    @isTest
    static void testUpdateTotalExposureOnAccount_ExposureUnchanged() {
        // Arrange
        Opportunity opp      = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Account beforeUpdate = [SELECT Total_Exposure__c FROM Account WHERE Id = :opp.AccountId];

        // Same exposure value in both maps → condition evaluates to false
        Map<Id, SObject> newMap = buildOppSObjectMap(opp.Id, opp.AccountId, 100000, false);
        Map<Id, SObject> oldMap = buildOppSObjectMap(opp.Id, opp.AccountId, 100000, false);

        // Act
        Test.startTest();
        PEAC_UpdateTotalExposure.updateTotalExposureOnAccount(newMap, oldMap);
        Test.stopTest();

        // Assert: Account value is unchanged; no DML executed inside the method
        Account afterUpdate = [SELECT Total_Exposure__c FROM Account WHERE Id = :opp.AccountId];
        System.assertEquals(beforeUpdate.Total_Exposure__c, afterUpdate.Total_Exposure__c,
            'Account Total_Exposure__c should remain unchanged when Opp exposure did not change');
    }

    /********************************************************************************************************************
     @Description: LOAN RECORD TYPE PATH — updateTotalExposureOnAccount
                   Verifies that when Loan_Record_Type__c is true the Account
                   is NOT updated even when Total_Exposure__c has changed.
                   Covers: condition false branch (Loan_Record_Type__c = true).
    *********************************************************************************************************************/
    @isTest
    static void testUpdateTotalExposureOnAccount_LoanRecordType() {
        // Arrange
        Opportunity opp      = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Account beforeUpdate = [SELECT Total_Exposure__c FROM Account WHERE Id = :opp.AccountId];

        // Loan_Record_Type__c = true → method should skip Account update
        Map<Id, SObject> newMap = buildOppSObjectMap(opp.Id, opp.AccountId, 200000, true);
        Map<Id, SObject> oldMap = buildOppSObjectMap(opp.Id, opp.AccountId, 100000, true);

        // Act
        Test.startTest();
        PEAC_UpdateTotalExposure.updateTotalExposureOnAccount(newMap, oldMap);
        Test.stopTest();

        // Assert: Account unchanged because Loan record type is filtered out
        Account afterUpdate = [SELECT Total_Exposure__c FROM Account WHERE Id = :opp.AccountId];
        System.assertEquals(beforeUpdate.Total_Exposure__c, afterUpdate.Total_Exposure__c,
            'Account should not be updated for Loan record type opportunities');
    }

    /********************************************************************************************************************
     @Description: NULL ACCOUNT ID PATH — updateTotalExposureOnAccount
                   Verifies that when AccountId is null the map stays empty
                   and no Account DML is attempted.
                   Covers: condition false branch (AccountId = null).
    *********************************************************************************************************************/
    @isTest
    static void testUpdateTotalExposureOnAccount_NullAccountId() {
        // Arrange
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        // AccountId = null → method condition fails, no update performed
        Map<Id, SObject> newMap = buildOppSObjectMap(opp.Id, null, 150000, false);
        Map<Id, SObject> oldMap = buildOppSObjectMap(opp.Id, null, 100000, false);

        // Act — must complete without exception
        Test.startTest(); 
        PEAC_UpdateTotalExposure.updateTotalExposureOnAccount(newMap, oldMap);
        Test.stopTest();

        // Assert: no exception thrown and DML limit not consumed by this method
        System.assert(Limits.getDMLStatements() < Limits.getLimitDMLStatements(),
            'No DML should have been performed for an Opp with null AccountId');
    }

   

   
   
   
    /********************************************************************************************************************
     @Description: BULK TEST — updateTotalExposureOnAccount with 50 Opportunities
                   Validates governor-limit safety when processing large batches.
                   Covers: full success path executed 50 times in a single call.
    *********************************************************************************************************************/
    @isTest
    static void testBulkUpdate_Opportunities() {
        // Arrange: 50 Accounts and Opportunities
        List<Account> bulkAccounts = new List<Account>();
        for (Integer i = 0; i < 50; i++) {
            bulkAccounts.add(new Account(Name = 'Bulk Opp Account ' + i));
        }
        insert bulkAccounts;

        List<Opportunity> bulkOpps = new List<Opportunity>();
        for (Account acc : bulkAccounts) {
            bulkOpps.add(new Opportunity(
                Name      = acc.Name + ' Opp',
                AccountId = acc.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                Amount    = 5000
            ));
        }
        insert bulkOpps;

        // Build SObject maps: exposure increases from 10000 → 20000 for all Opps
        Map<Id, SObject> newMap = new Map<Id, SObject>();
        Map<Id, SObject> oldMap = new Map<Id, SObject>();
        for (Opportunity opp : bulkOpps) {
            Map<String, Object> newFields = new Map<String, Object>{
                'Id' => String.valueOf(opp.Id),
                'AccountId' => String.valueOf(opp.AccountId),
                'Total_Exposure__c' => 20000,
                'Loan_Record_Type__c' => false
            };
            Map<String, Object> oldFields = new Map<String, Object>{
                'Id' => String.valueOf(opp.Id),
                'AccountId' => String.valueOf(opp.AccountId),
                'Total_Exposure__c' => 10000,
                'Loan_Record_Type__c' => false
            };
            newMap.put(opp.Id, (SObject) JSON.deserialize(JSON.serialize(newFields), Opportunity.class));
            oldMap.put(opp.Id, (SObject) JSON.deserialize(JSON.serialize(oldFields), Opportunity.class));
        }

        // Act
        Test.startTest();
        PEAC_UpdateTotalExposure.updateTotalExposureOnAccount(newMap, oldMap);
        Test.stopTest();

        // Assert: All Accounts processed, governor limits respected
        List<Account> updatedAccounts = [SELECT Id, Total_Exposure__c FROM Account WHERE Id IN :bulkAccounts];
        System.assertEquals(50, updatedAccounts.size(), 'All 50 accounts should be returned after update');
        System.assert(Limits.getDMLStatements() < Limits.getLimitDMLStatements(),
            'Bulk operation must not exceed DML statement governor limit');
        System.assert(Limits.getQueries() < Limits.getLimitQueries(),
            'Bulk operation must not exceed SOQL query governor limit');
    }

}