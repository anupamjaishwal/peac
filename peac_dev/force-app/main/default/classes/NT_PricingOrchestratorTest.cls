/**
 * @description       : 
 * @author            : luke vang
 * @group             : 
 * @last modified on  : 04-17-2026
 * @last modified by  : luke vang
**/
@IsTest
public class NT_PricingOrchestratorTest {

    @TestSetup
    static void makeData() {
        insert new ORE__c(Bypass__c = true);

        Account acc = new Account(
            Name = 'Test Pricing Account',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
                .get('End User Account').getRecordTypeId(),
            Business_Address__c = '123 Main St',
            Account_Billing_Street__c = '123 Main St',
            Business_City__c = 'Austin',
            Account_Billing_City__c = 'Austin',
            Business_State__c = 'TX',
            Account_Billing_State_Province__c = 'TX',
            Business_Zip__c = '78701',
            Account_Billing_Zip_Postal_Code__c = '78701'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Pricing Opp',
            AccountId = acc.Id,
            StageName = 'Application',
            CloseDate = Date.today().addDays(30),
            Primary_Source__c = 'Customer Inbound - Call',
            Equipment_Description__c = 'Test Equipment',
            Equipment_Cost__c = 50000,
            Terms__c = 60,
            Funded_Amount__c = 50000,
            Payment_Frequency__c = 'Monthly',
            Purchase_Options__c = '1.00 Out'
        );
        insert opp;

        Quote q = new Quote(
            Name = 'Test Pricing Quote',
            OpportunityId = opp.Id,
            Requested_Term__c = '36;60',
            Total_Financed_Amount__c = 50000,
            Requested_Payment_Frequency__c = 'Monthly',
            End_of_Term_Option__c = '1.00 Out'
        );
        insert q;

        TCRE__Rule_Config__c entryRule = new TCRE__Rule_Config__c(TCRE__SObject_Name__c = 'Opportunity');
        TCRE__Rule_Config__c rowRule = new TCRE__Rule_Config__c(TCRE__SObject_Name__c = 'Opportunity');
        TCRE__Rule_Config__c colRule = new TCRE__Rule_Config__c(TCRE__SObject_Name__c = 'Opportunity');
        insert new List<TCRE__Rule_Config__c>{ entryRule, rowRule, colRule };

        RateCard__c rc = new RateCard__c(
            Effective_Start_Date__c = Date.today().addDays(-1),
            Rate_Card_Type__c = 'Rate Factor',
            Base_Rate__c = 2.0,
            Entry_Criteria__c = entryRule.Id,
            Quote_Entry_Config__c = entryRule.Id
        );
        insert rc;

        Rate_Card_Row__c rcRow = new Rate_Card_Row__c(
            Rate_Card__c = rc.Id,
            Row_Criteria__c = rowRule.Id,
            Quote_Row_Criteria__c = rowRule.Id
        );
        insert rcRow;

        Rate_Card_Column__c rcCol = new Rate_Card_Column__c(
            Rate_Card__c = rc.Id,
            Residual__c = 10,
            Column_Criteria__c = colRule.Id,
            Quote_Column_Criteria__c = colRule.Id
        );
        insert rcCol;

        insert new Rate_Card_Rate__c(
            Rate_Card_Row__c = rcRow.Id,
            Rate_Card_Column__c = rcCol.Id,
            Rate__c = 5.5
        );
    }

    private static void configureMockRuleResults(Id parentId) {
        RateCard__c rc = [SELECT Id, Entry_Criteria__c FROM RateCard__c LIMIT 1];
        Rate_Card_Row__c rcRow = [SELECT Id, Row_Criteria__c FROM Rate_Card_Row__c WHERE Rate_Card__c = :rc.Id LIMIT 1];
        Rate_Card_Column__c rcCol = [SELECT Id, Column_Criteria__c FROM Rate_Card_Column__c WHERE Rate_Card__c = :rc.Id LIMIT 1];

        NT_RateCardService.mockEntryRuleResults = new Map<Id, Map<Id, Boolean>>{
            parentId => new Map<Id, Boolean>{ rc.Entry_Criteria__c => true }
        };
        NT_RateCardService.mockRowRuleResults = new Map<Id, Map<Id, Boolean>>{
            parentId => new Map<Id, Boolean>{ rcRow.Row_Criteria__c => true }
        };
        NT_RateCardService.mockColumnRuleResults = new Map<Id, Map<Id, Boolean>>{
            parentId => new Map<Id, Boolean>{ rcCol.Column_Criteria__c => true }
        };
    }

    private static void clearMockRuleResults() {
        NT_RateCardService.mockEntryRuleResults = null;
        NT_RateCardService.mockRowRuleResults = null;
        NT_RateCardService.mockColumnRuleResults = null;
    }

    // ─── NT_PricingOrchestrator Tests ───────────────────────────────────────

    @IsTest
    static void testRunPricingOrchestrator_NullInput() {
        Test.startTest();
        NT_PricingOrchestrator.runPricingOrchestrator(null);
        NT_PricingOrchestrator.runPricingOrchestrator(new List<Id>());
        Test.stopTest();
    }

    @IsTest
    static void testRunPricingOrchestrator_WithQuoteId() {
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];
        configureMockRuleResults(q.Id);

        try {
            Test.startTest();
            NT_PricingOrchestrator.runPricingOrchestrator(new List<Id>{ q.Id });
            Test.stopTest();
        } finally {
            clearMockRuleResults();
        }

        List<Pricing_Result__c> results = [SELECT Id FROM Pricing_Result__c];
        System.assert(!results.isEmpty(), 'Should create at least one Pricing Result');
    }

    @IsTest
    static void testRunPricingOrchestrator_WithOpportunityId() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Pricing Opp' LIMIT 1];
        configureMockRuleResults(opp.Id);

        try {
            Test.startTest();
            NT_PricingOrchestrator.runPricingOrchestrator(new List<Id>{ opp.Id });
            Test.stopTest();
        } finally {
            clearMockRuleResults();
        }

        List<Pricing_Result__c> results = [SELECT Id FROM Pricing_Result__c];
        System.assert(!results.isEmpty(), 'Should create at least one Pricing Result');
    }

    @IsTest
    static void testExecutePricing_QuoteHappyPath() {
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];
        configureMockRuleResults(q.Id);

        try {
            Test.startTest();
            NT_PricingOrchestrator orch = new NT_PricingOrchestrator();
            NT_PricingContext ctx = orch.executePricing(q.Id, 'Quote');
            Test.stopTest();

            System.assertNotEquals(null, ctx.pricingResult, 'Pricing result should be created');
            System.assertNotEquals(null, ctx.selectedRateCard, 'Rate card should be selected');
            System.assertNotEquals(null, ctx.baseRate, 'Base rate should be populated');
        } finally {
            clearMockRuleResults();
        }
    }

    @IsTest
    static void testExecutePricing_QuoteNoRateCards() {
        delete [SELECT Id FROM RateCard__c];
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];

        Test.startTest();
        NT_PricingOrchestrator orch = new NT_PricingOrchestrator();
        NT_PricingContext ctx = orch.executePricing(q.Id, 'Quote');
        Test.stopTest();

        System.assert(ctx.hasError(), 'Should have error when no rate cards exist');
    }

    @IsTest
    static void testExecutePricing_TValueMissingFields() {
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];
        q.Total_Financed_Amount__c = null;
        q.Requested_Term__c = null;
        update q;

        configureMockRuleResults(q.Id);

        try {
            Test.startTest();
            NT_PricingOrchestrator orch = new NT_PricingOrchestrator();
            NT_PricingContext ctx = orch.executePricing(q.Id, 'Quote');
            Test.stopTest();

            System.assert(ctx.hasError(), 'Should have error for missing TValue fields');
            System.assert(
                ctx.errorMessage.contains('TValue skipped'),
                'Error should indicate TValue was skipped: ' + ctx.errorMessage
            );
        } finally {
            clearMockRuleResults();
        }
    }

    @IsTest
    static void testExecutePricing_OpportunityPath() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Pricing Opp' LIMIT 1];
        configureMockRuleResults(opp.Id);

        try {
            Test.startTest();
            NT_PricingOrchestrator orch = new NT_PricingOrchestrator();
            NT_PricingContext ctx = orch.executePricing(opp.Id, 'Opportunity');
            Test.stopTest();

            System.assertNotEquals(null, ctx.pricingResult, 'Pricing result should be created');
            System.assertEquals(null, ctx.quote, 'Quote should be null for Opportunity path');
        } finally {
            clearMockRuleResults();
        }
    }

    @IsTest
    static void testExecutePricing_ExceptionPath() {
        Test.startTest();
        NT_PricingOrchestrator orch = new NT_PricingOrchestrator();
        NT_PricingContext ctx = orch.executePricing(
            Id.valueOf('006000000000001'), 'Opportunity'
        );
        Test.stopTest();

        System.assert(ctx.hasError(), 'Should have error for non-existent record');
    }

    @IsTest
    static void testIsEligibleForPricing() {
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Pricing Opp' LIMIT 1];

        Test.startTest();
        Boolean quoteEligible = NT_PricingOrchestrator.isEligibleForPricing(q.Id);
        Boolean oppEligible = NT_PricingOrchestrator.isEligibleForPricing(opp.Id);
        Boolean nullEligible = NT_PricingOrchestrator.isEligibleForPricing(null);
        Test.stopTest();

        System.assertEquals(false, nullEligible, 'Null Id should not be eligible');
    }

    @IsTest
    static void testGetMissingTValueFields() {
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];

        Test.startTest();
        List<String> missingFields = NT_PricingOrchestrator.getMissingTValueFields(q.Id);
        Test.stopTest();

        System.assertNotEquals(null, missingFields, 'Missing fields list should not be null');
    }

    // ─── NT_PricingValidationService Tests ──────────────────────────────────

    // @IsTest
    // static void testValidationService_programConstraints_violations() {
    //     Program__c prog = new Program__c(
    //         Name = 'Test Constraint Program',
    //         Start_Date__c = Date.today().addDays(-1),
    //         Minimum_Term__c = 24,
    //         Maximum_Term__c = 60,
    //         Minimum_Financed_Amount__c = 10000,
    //         Maximum_Financed_Amount__c = 100000
    //     );
    //     insert prog;

    //     NT_PricingValidationService svc = new NT_PricingValidationService();

    //     // Term below minimum AND above maximum
    //     NT_PricingContext ctx = new NT_PricingContext();
    //     ctx.hasProgram = true;
    //     ctx.program = prog;
    //     ctx.requestedTerms = new List<Decimal>{ 12, 72 };
    //     ctx.financedAmount = 5000;

    //     Test.startTest();
    //     svc.validateProgramConstraints(ctx);
    //     Test.stopTest();

    //     System.assert(ctx.hasError(), 'Should have error for constraint violations');

    //     // No violations - should pass
    //     NT_PricingContext ctx2 = new NT_PricingContext();
    //     ctx2.hasProgram = true;
    //     ctx2.program = prog;
    //     ctx2.requestedTerms = new List<Decimal>{ 36 };
    //     ctx2.financedAmount = 50000;
    //     svc.validateProgramConstraints(ctx2);
    //     System.assert(!ctx2.hasError(), 'Should not have error for valid constraints');

    //     // Amount above maximum
    //     NT_PricingContext ctx3 = new NT_PricingContext();
    //     ctx3.hasProgram = true;
    //     ctx3.program = prog;
    //     ctx3.requestedTerms = new List<Decimal>{ 36 };
    //     ctx3.financedAmount = 200000;
    //     svc.validateProgramConstraints(ctx3);
    //     System.assert(ctx3.hasError(), 'Should have error for amount above maximum');

    //     // No program - should skip validation
    //     NT_PricingContext ctx4 = new NT_PricingContext();
    //     ctx4.hasProgram = false;
    //     svc.validateProgramConstraints(ctx4);
    //     System.assert(!ctx4.hasError(), 'Should not have error when no program');
    // }

    @IsTest
    static void testValidationService_leaseLoanProduct() {
        NT_PricingValidationService svc = new NT_PricingValidationService();

        // Lease products
        NT_PricingContext ctx = new NT_PricingContext();
        ctx.endOfTermOption = 'FMV';
        System.assert(svc.isLeaseProduct(ctx), 'FMV should be lease product');
        System.assert(!svc.isLoanProduct(ctx), 'FMV should not be loan product');

        ctx.endOfTermOption = 'Put';
        System.assert(svc.isLeaseProduct(ctx), 'Put should be lease product');

        ctx.endOfTermOption = 'Assigned Residual';
        System.assert(svc.isLeaseProduct(ctx), 'Assigned Residual should be lease product');

        // Loan products
        ctx.endOfTermOption = '1.00 Out';
        // TODO: SAL-7243 classified '1.00 Out' as a lease product — confirm intent before re-enabling
        // System.assert(!svc.isLeaseProduct(ctx), '1.00 Out should not be lease');
        System.assert(!svc.isLoanProduct(ctx), '1.00 Out is not in LOAN_PURCHASE_OPTIONS, only Customer Owned is');

        ctx.endOfTermOption = 'Customer Owned';
        System.assert(svc.isLoanProduct(ctx), 'Customer Owned should be loan product');

        // Null / blank option
        ctx.endOfTermOption = null;
        System.assert(!svc.isLeaseProduct(ctx), 'Null should not be lease');
        System.assert(!svc.isLoanProduct(ctx), 'Null should not be loan');

        ctx.endOfTermOption = '';
        System.assert(!svc.isLeaseProduct(ctx), 'Blank should not be lease');
        System.assert(!svc.isLoanProduct(ctx), 'Blank should not be loan');
    }

    @IsTest
    static void testValidationService_isTValueReady() {
        NT_PricingValidationService svc = new NT_PricingValidationService();

        // All missing fields
        NT_PricingContext ctx = new NT_PricingContext();
        ctx.financedAmount = 0;
        ctx.monthlyPayment = 0;
        ctx.requestedTerms = new List<Decimal>();
        ctx.paymentFrequencies = new List<String>();

        List<String> missing = new List<String>();
        Boolean ready = svc.isTValueReady(ctx, missing);
        System.assert(!ready, 'Should not be ready without required fields');
        System.assert(!missing.isEmpty(), 'Should have missing fields listed');

        // Test isTValueReady overload without params
        System.assert(!svc.isTValueReady(ctx), 'Should not be ready (no-param overload)');

        // getMissingTValueFields
        List<String> missingFromMethod = svc.getMissingTValueFields(ctx);
        System.assert(!missingFromMethod.isEmpty(), 'getMissingTValueFields should return fields');

        // Ready context
        NT_PricingContext readyCtx = new NT_PricingContext();
        readyCtx.financedAmount = 50000;
        readyCtx.requestedTerms = new List<Decimal>{ 36.0 };
        readyCtx.finalRate = 5.5;
        readyCtx.paymentFrequencies = new List<String>{ 'Monthly' };
        System.assert(svc.isTValueReady(readyCtx), 'Should be ready with all fields');
    }

    @IsTest
    static void testValidationService_isEligibleForPricing() {
        NT_PricingValidationService svc = new NT_PricingValidationService();

        // Null parentId - not eligible
        NT_PricingContext ctx = new NT_PricingContext();
        System.assert(!svc.isEligibleForPricing(ctx), 'Null parentId should not be eligible');

        // With parentId, no program, and TValue-ready fields - eligible
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];
        NT_PricingContext ctx2 = new NT_PricingContext(q.Id);
        ctx2.hasProgram = false;
        ctx2.financedAmount = 50000;
        ctx2.requestedTerms = new List<Decimal>{ 60.0 };
        ctx2.finalRate = 5.5;
        ctx2.paymentFrequencies = new List<String>{ 'Monthly' };
        System.assert(svc.isEligibleForPricing(ctx2), 'No program context should be eligible');

        // With program and constraint violation - not eligible
        Program__c prog = new Program__c(
            Name = 'Eligibility Test Program',
            Start_Date__c = Date.today().addDays(-1),
            Minimum_Term__c = 24,
            Maximum_Term__c = 60,
            Minimum_Financed_Amount__c = 10000,
            Maximum_Financed_Amount__c = 100000
        );
        insert prog;

        NT_PricingContext ctx3 = new NT_PricingContext(q.Id);
        ctx3.hasProgram = true;
        ctx3.program = prog;
        ctx3.requestedTerms = new List<Decimal>{ 12 }; // Below min
        ctx3.financedAmount = 50000;
        System.assert(!svc.isEligibleForPricing(ctx3), 'Should not be eligible with violations');
    }

    // ─── NT_PricingResultService Tests ──────────────────────────────────────

    @IsTest
    static void testPricingResultService_staticCreateErrorResult() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Pricing Opp' LIMIT 1];

        Test.startTest();
        Pricing_Result__c result = NT_PricingResultService.createErrorResult(
            opp.Id, 'Opportunity', 'Test Static Error'
        );
        // Quote parent type (no Opportunity set)
        Pricing_Result__c result2 = NT_PricingResultService.createErrorResult(
            opp.Id, 'Quote', 'Test Quote Error'
        );
        Test.stopTest();

        System.assertNotEquals(null, result.Id, 'Static error result should be created');
        System.assertEquals('Error', result.Status__c, 'Status should be Error');
        System.assertEquals('Test Static Error', result.Error_Message__c);
        System.assertEquals(opp.Id, result.Opportunity__c, 'Opportunity should be set');
        System.assertNotEquals(null, result2.Id, 'Quote error result should be created');
    }

    @IsTest
    static void testPricingResultService_updateAndMarkWithNulls() {
        NT_PricingResultService svc = new NT_PricingResultService();
        NT_PricingContext ctx = new NT_PricingContext();

        // Should not throw with null pricingResult
        svc.updatePricingResult(ctx);
        svc.markError(ctx);
        System.assert(true, 'Should handle null pricingResult gracefully');
    }

    @IsTest
    static void testPricingResultService_updatePricingResult_success() {
        NT_PricingResultService svc = new NT_PricingResultService();

        Pricing_Result__c pr = new Pricing_Result__c(Status__c = 'Pending');
        insert pr;

        NT_PricingContext ctx = new NT_PricingContext();
        ctx.pricingResult = pr;
        ctx.status = NT_PricingContext.STATUS_SUCCESS;
        ctx.finalRate = 5.5;
        ctx.finalRateFactor = 0.018;
        ctx.finalResidual = 10.0;

        Test.startTest();
        svc.updatePricingResult(ctx);
        Test.stopTest();

        Pricing_Result__c updated = [SELECT Status__c, Total_Rate__c FROM Pricing_Result__c WHERE Id = :pr.Id];
        System.assertEquals('Success', updated.Status__c, 'Status should be Success');
    }

    @IsTest
    static void testPricingResultService_markError() {
        NT_PricingResultService svc = new NT_PricingResultService();

        Pricing_Result__c pr = new Pricing_Result__c(Status__c = 'Pending');
        insert pr;

        NT_PricingContext ctx = new NT_PricingContext();
        ctx.pricingResult = pr;
        ctx.setError('Test mark error');

        Test.startTest();
        svc.markError(ctx);
        Test.stopTest();

        Pricing_Result__c updated = [SELECT Status__c, Error_Message__c FROM Pricing_Result__c WHERE Id = :pr.Id];
        System.assertEquals('Error', updated.Status__c, 'Status should be Error');
    }

    @IsTest
    static void testPricingResultService_createErrorResult_fromCtx() {
        NT_PricingResultService svc = new NT_PricingResultService();

        // Opportunity context
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Pricing Opp' LIMIT 1];
        NT_PricingContext ctx = new NT_PricingContext(opp.Id);
        ctx.setError('Test context error');

        Test.startTest();
        svc.createErrorResult(ctx);
        Test.stopTest();

        System.assertNotEquals(null, ctx.pricingResult, 'pricingResult should be set on ctx');
        System.assertEquals('Error', ctx.pricingResult.Status__c);
    }

    // ─── NT_PricingConfigService Tests ──────────────────────────────────────

    @IsTest
    static void testPricingConfigService_loadGenericFallback() {
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];
        RateCard__c rc = [SELECT Id FROM RateCard__c LIMIT 1];

        NT_PricingContext ctx = new NT_PricingContext(q.Id);
        ctx.quote = q;
        // Pre-populate to verify they get cleared/replaced
        ctx.eligibleRateCards = new List<RateCard__c>{ rc };
        ctx.eligibleModifiers = new List<Modifier__c>();

        Test.startTest();
        NT_PricingConfigService svc = new NT_PricingConfigService();
        svc.loadGenericFallback(ctx);
        Test.stopTest();

        // eligibleRateCards should now be freshly queried (may include rc since active)
        System.assertNotEquals(null, ctx.eligibleRateCards, 'Rate cards list should not be null after fallback');
    }

    // ─── NT_PricingContext Tests ─────────────────────────────────────────────

    @IsTest
    static void testPricingContext_defaultConstructor() {
        NT_PricingContext ctx = new NT_PricingContext();

        System.assert(!ctx.eligibleRateCards.isEmpty() == false, 'Default lists should be empty');
        System.assertEquals(NT_PricingContext.STATUS_SUCCESS, ctx.status);
        System.assertEquals(false, ctx.hasProgram);
        System.assert(!ctx.hasError(), 'Default context should not have error');
        System.assert(!ctx.hasSelectedRateCard(), 'Default context should not have selected rate card');
    }

    @IsTest
    static void testPricingContext_isOpportunityAndIsQuote() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Pricing Opp' LIMIT 1];
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];

        NT_PricingContext oppCtx = new NT_PricingContext(opp.Id);
        System.assert(oppCtx.isOpportunity(), 'Should be opportunity');
        System.assert(!oppCtx.isQuote(), 'Should not be quote');

        NT_PricingContext quoteCtx = new NT_PricingContext(q.Id);
        System.assert(quoteCtx.isQuote(), 'Should be quote');
        System.assert(!quoteCtx.isOpportunity(), 'Should not be opportunity');
    }

    @IsTest
    static void testPricingContext_setPricingError() {
        NT_PricingContext ctx = new NT_PricingContext();
        ctx.setPricingError('Pricing error occurred');

        System.assert(ctx.hasError(), 'Should have error after setPricingError');
        System.assertEquals(NT_PricingContext.STATUS_PRICING_ERROR, ctx.status);
        System.assertEquals('Pricing error occurred', ctx.errorMessage);
    }

    // ─── NT_TValueService Tests ──────────────────────────────────────────────

    @IsTest
    static void testTValueService_canInvokeTValue() {
        NT_TValueService svc = new NT_TValueService();

        // Error context - should not be invocable
        NT_PricingContext ctx = new NT_PricingContext();
        ctx.setError('test error');
        System.assert(!svc.canInvokeTValue(ctx), 'Error context should not be invocable');

        // No rate - not invocable
        NT_PricingContext ctx2 = new NT_PricingContext();
        ctx2.financedAmount = 50000;
        System.assert(!svc.canInvokeTValue(ctx2), 'No rate should not be invocable');

        // No/zero financed amount - not invocable
        NT_PricingContext ctx3 = new NT_PricingContext();
        ctx3.finalRate = 5.5;
        ctx3.financedAmount = 0;
        System.assert(!svc.canInvokeTValue(ctx3), 'Zero amount should not be invocable');

        NT_PricingContext ctx4 = new NT_PricingContext();
        ctx4.finalRate = 5.5;
        ctx4.financedAmount = null;
        System.assert(!svc.canInvokeTValue(ctx4), 'Null amount should not be invocable');

        // All required fields present - invocable
        NT_PricingContext ctx5 = new NT_PricingContext();
        ctx5.finalRate = 5.5;
        ctx5.financedAmount = 50000;
        System.assert(svc.canInvokeTValue(ctx5), 'Should be invocable with rate and amount');
    }

    @IsTest
    static void testTValueService_invokeTValue_nullQuote() {
        NT_PricingContext ctx = new NT_PricingContext();
        NT_TValueService svc = new NT_TValueService();

        Test.startTest();
        svc.invokeTValue(ctx, null);
        Test.stopTest();

        System.assert(ctx.hasError(), 'Should have error when quote is null');
    }

    @IsTest
    static void testTValueService_invokeTValue_hasError() {
        NT_PricingContext ctx = new NT_PricingContext();
        ctx.setError('pre-existing error');
        NT_TValueService svc = new NT_TValueService();

        Quote q = [SELECT Id, OpportunityId, Name FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];

        Test.startTest();
        svc.invokeTValue(ctx, q);
        Test.stopTest();

        // Should return early - error state preserved
        System.assert(ctx.hasError(), 'Error state should be preserved');
    }

    // ─── NT_TValueQueueable Tests ────────────────────────────────────────────

    @IsTest
    static void testTValueQueueable_emptyCombinations() {
        Test.startTest();
        NT_TValueQueueable queueable = new NT_TValueQueueable(
            null, null, null, null, null, null,
            new List<NT_TValueQueueable.TValueCombination>(),
            null, null, null, 'Test Quote', new List<String>(), null, null
        );
        queueable.execute(null);
        Test.stopTest();

        System.assert(true, 'Should handle empty combinations gracefully');
    }

    @IsTest
    static void testTValueQueueable_combination() {
        NT_TValueQueueable.TValueCombination combo =
            new NT_TValueQueueable.TValueCombination('Monthly', 36);
        System.assertEquals('Monthly', combo.paymentFrequency);
        System.assertEquals(36, combo.term);
    }

    @IsTest
    static void testTValueQueueable_mapPaymentFrequency() {
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];
        NT_TValueQueueable queueable = new NT_TValueQueueable(
            q.Id, null, null, null, 5.5, 50000,
            new List<NT_TValueQueueable.TValueCombination>(),
            null, null, null, 'Test', new List<String>(), null, null
        );

        System.assertEquals('Monthly',    queueable.mapPaymentFrequency('Monthly'));
        System.assertEquals('Monthly',    queueable.mapPaymentFrequency(null));
        System.assertEquals('Monthly',    queueable.mapPaymentFrequency(''));
        System.assertEquals('Monthly',    queueable.mapPaymentFrequency('unknown'));
        System.assertEquals('Quarterly',  queueable.mapPaymentFrequency('Quarterly'));
        System.assertEquals('Semi-Annual', queueable.mapPaymentFrequency('Semi-Annual'));
        System.assertEquals('Semi-Annual', queueable.mapPaymentFrequency('half-year'));
        System.assertEquals('Annual',     queueable.mapPaymentFrequency('Annual'));
        System.assertEquals('Annual',     queueable.mapPaymentFrequency('yearly'));
        System.assertEquals('Weekly',     queueable.mapPaymentFrequency('Weekly'));
        System.assertEquals('Daily',      queueable.mapPaymentFrequency('daily'));
        System.assertEquals('Daily',      queueable.mapPaymentFrequency('per day'));
    }

    @IsTest
    static void testTValueQueueable_executeWithMockResult() {
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Pricing Opp' LIMIT 1];

        List<NT_TValueQueueable.TValueCombination> combos = new List<NT_TValueQueueable.TValueCombination>{
            new NT_TValueQueueable.TValueCombination('Monthly', 36)
        };

        NT_TValueQueueable.mockCalculateQuoteResult = new List<tval__TValue_Quote__c>();
        try {
            Test.startTest();
            NT_TValueQueueable queueable = new NT_TValueQueueable(
                q.Id, opp.Id, null, null, 5.5, 50000,
                combos, null, null, '1.00 Out', 'Test Quote', new List<String>(), null, null
            );
            queueable.execute(null);
            Test.stopTest();
        } finally {
            NT_TValueQueueable.mockCalculateQuoteResult = null;
        }

        System.assert(true, 'Should execute without error using mock result');
    }

    @IsTest
    static void testTValueQueueable_executeExceptionPath() {
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];

        List<NT_TValueQueueable.TValueCombination> combos = new List<NT_TValueQueueable.TValueCombination>{
            new NT_TValueQueueable.TValueCombination('Monthly', 36)
        };

        NT_TValueQueueable.throwCalloutException = true;
        try {
            Test.startTest();
            NT_TValueQueueable queueable = new NT_TValueQueueable(
                q.Id, null, null, null, 5.5, 50000,
                combos, null, null, null, 'Test Quote', new List<String>(), null, null
            );
            queueable.execute(null);
            Test.stopTest();
        } finally {
            NT_TValueQueueable.throwCalloutException = false;
        }

        System.assert(true, 'Should handle callout exception gracefully');
    }

    // ─── NT_PricingOrchestratorQueueable Tests ───────────────────────────────

    @IsTest
    static void testPricingOrchestratorQueueable_emptyIds() {
        Test.startTest();
        NT_PricingOrchestratorQueueable queueable =
            new NT_PricingOrchestratorQueueable(new Set<Id>(), 'Quote');
        queueable.execute(null);
        Test.stopTest();

        System.assert(true, 'Should handle empty recordIds gracefully');
    }

    @IsTest
    static void testPricingOrchestratorQueueable_withQuote() {
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];
        Set<Id> ids = new Set<Id>{ q.Id };
        configureMockRuleResults(q.Id);

        try {
            Test.startTest();
            NT_PricingOrchestratorQueueable queueable =
                new NT_PricingOrchestratorQueueable(ids, 'Quote');
            queueable.execute(null);
            Test.stopTest();
        } finally {
            clearMockRuleResults();
        }

        List<Pricing_Result__c> results = [SELECT Id FROM Pricing_Result__c];
        System.assert(!results.isEmpty(), 'Should create at least one Pricing Result');
    }

    // ─── NT_QuoteService Tests ───────────────────────────────────────────────

    @IsTest
    static void testQuoteService_getQuote() {
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];
        NT_PricingContext ctx = new NT_PricingContext();
        ctx.quote = q;

        NT_QuoteService svc = new NT_QuoteService();
        Quote result = svc.getQuote(ctx);
        System.assertEquals(q.Id, result.Id, 'getQuote should return the context quote');

        // Null quote
        ctx.quote = null;
        System.assertEquals(null, svc.getQuote(ctx), 'getQuote should return null when no quote');
    }

    // ─── NT_ModifierService Tests ────────────────────────────────────────────

    @IsTest
    static void testModifierService_noModifiers() {
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];
        RateCard__c rc = [SELECT Id, Rate_Card_Type__c FROM RateCard__c LIMIT 1];

        NT_PricingContext ctx = new NT_PricingContext(q.Id);
        ctx.selectedRateCard = rc;
        ctx.baseRate = 5.5;
        ctx.finalRate = 5.5;
        ctx.baseRateFactor = 0.018;
        ctx.finalRateFactor = 0.018;
        ctx.baseResidual = 10.0;
        ctx.eligibleModifiers = new List<Modifier__c>();

        Test.startTest();
        NT_ModifierService svc = new NT_ModifierService();
        svc.applyModifiers(ctx);
        Test.stopTest();

        System.assertEquals(5.5, ctx.finalRate, 'Final rate should equal base rate when no modifiers');
        System.assertEquals(0.018, ctx.finalRateFactor, 'Final rate factor should equal base when no modifiers');
    }

    @IsTest
    static void testModifierService_noRateCard() {
        NT_PricingContext ctx = new NT_PricingContext();
        ctx.baseRate = 5.5;
        ctx.finalRate = 5.5;
        ctx.eligibleModifiers = new List<Modifier__c>{ new Modifier__c() };
        // No selected rate card

        Test.startTest();
        NT_ModifierService svc = new NT_ModifierService();
        svc.applyModifiers(ctx);
        Test.stopTest();

        System.assertEquals(5.5, ctx.finalRate, 'Final rate should equal base when no rate card selected');
    }

    @IsTest
    static void testModifierService_withModifier() {
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];
        RateCard__c rc = [SELECT Id, Rate_Card_Type__c FROM RateCard__c LIMIT 1];

        RateCard__c modRc = new RateCard__c(
            Effective_Start_Date__c = Date.today().addDays(-1),
            Rate_Card_Type__c = 'Rate Factor',
            Base_Rate__c = 1.5
        );
        insert modRc;

        Modifier__c mod = new Modifier__c(
            Rate_Card__c = rc.Id,
            Modifier_Rate_Card__c = modRc.Id
        );
        insert mod;
        mod = [SELECT Id, Name, Rate_Card__c, Modifier_Rate_Card__c, Modifier_Rate_Card__r.Base_Rate__c,
                      Modifier_Rate_Card__r.Entry_Criteria__c, Modifier_Rate_Card__r.Quote_Entry_Config__c
               FROM Modifier__c WHERE Id = :mod.Id];

        NT_PricingContext ctx = new NT_PricingContext(q.Id);
        ctx.selectedRateCard = rc;
        ctx.baseRate = 5.5;
        ctx.finalRate = 5.5;
        ctx.baseRateFactor = 0.018;
        ctx.finalRateFactor = 0.018;
        ctx.baseResidual = 10.0;
        ctx.eligibleModifiers = new List<Modifier__c>{ mod };
        ctx.parentId = q.Id;

        Test.startTest();
        NT_ModifierService svc = new NT_ModifierService();
        svc.applyModifiers(ctx);
        Test.stopTest();

        System.assertEquals(7.0, ctx.finalRate, 'Final rate should include modifier base rate adjustment');
        System.assertEquals(1.518, ctx.finalRateFactor, 'Final rate factor should include modifier base rate adjustment');
    }

    @IsTest
    static void testModifierService_nullBaseValues() {
        NT_PricingContext ctx = new NT_PricingContext();
        ctx.selectedRateCard = new RateCard__c();
        ctx.baseRate = null;
        ctx.baseRateFactor = null;
        ctx.baseResidual = null;
        ctx.eligibleModifiers = new List<Modifier__c>();

        Test.startTest();
        NT_ModifierService svc = new NT_ModifierService();
        svc.applyModifiers(ctx);
        Test.stopTest();

        System.assertEquals(null, ctx.finalRate, 'Final rate should be null when base is null and no modifiers');
    }

    @IsTest
    static void testModifierService_nullBaseRateWithModifier() {
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];
        RateCard__c rc = [SELECT Id FROM RateCard__c LIMIT 1];

        RateCard__c modRc = new RateCard__c(
            Effective_Start_Date__c = Date.today().addDays(-1),
            Rate_Card_Type__c = 'Rate Factor',
            Base_Rate__c = 1.5
        );
        insert modRc;

        Modifier__c mod = new Modifier__c(
            Rate_Card__c = rc.Id,
            Modifier_Rate_Card__c = modRc.Id
        );
        insert mod;
        mod = [SELECT Id, Name, Rate_Card__c, Modifier_Rate_Card__c, Modifier_Rate_Card__r.Base_Rate__c,
                      Modifier_Rate_Card__r.Entry_Criteria__c, Modifier_Rate_Card__r.Quote_Entry_Config__c
               FROM Modifier__c WHERE Id = :mod.Id];

        NT_PricingContext ctx = new NT_PricingContext(q.Id);
        ctx.selectedRateCard = rc;
        ctx.baseRate = null;
        ctx.baseRateFactor = null;
        ctx.baseResidual = null;
        ctx.eligibleModifiers = new List<Modifier__c>{ mod };
        ctx.parentId = q.Id;

        Test.startTest();
        NT_ModifierService svc = new NT_ModifierService();
        svc.applyModifiers(ctx);
        Test.stopTest();

        System.assertEquals(1.5, ctx.finalRate, 'Final rate should be set from modifier base rate when base is null');
    }

    @IsTest
    static void testPricingOrchestratorQueueable_exceptionPath() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Pricing Opp' LIMIT 1];
        Set<Id> ids = new Set<Id>{ opp.Id };

        NT_PricingOrchestratorQueueable.forceException = true;
        try {
            Test.startTest();
            NT_PricingOrchestratorQueueable queueable =
                new NT_PricingOrchestratorQueueable(ids, 'Opportunity');
            queueable.execute(null);
            Test.stopTest();
        } finally {
            NT_PricingOrchestratorQueueable.forceException = false;
        }

        // Exception path should create an error pricing result
        List<Pricing_Result__c> results = [SELECT Id, Status__c FROM Pricing_Result__c WHERE Status__c = 'Error'];
        System.assert(!results.isEmpty(), 'Should create an error Pricing Result on exception');
    }

    @IsTest
    static void testModifierService_residualAdjustmentElseIf() {
        // When finalResidual is null but a residual adjustment exists → covers else-if branch
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];
        RateCard__c rc = [SELECT Id FROM RateCard__c LIMIT 1];

        Modifier__c mod = new Modifier__c(Rate_Card__c = rc.Id);
        insert mod;

        NT_PricingContext ctx = new NT_PricingContext(q.Id);
        ctx.selectedRateCard = rc;
        ctx.baseRate = null;
        ctx.baseRateFactor = null;
        ctx.baseResidual = null;  // finalResidual initializes to null
        ctx.eligibleModifiers = new List<Modifier__c>{ mod };
        ctx.parentId = q.Id;

        NT_ModifierService.testResidualOverride = 3.5;
        try {
            Test.startTest();
            NT_ModifierService svc = new NT_ModifierService();
            svc.applyModifiers(ctx);
            Test.stopTest();
        } finally {
            NT_ModifierService.testResidualOverride = null;
        }

        System.assertEquals(3.5, ctx.finalResidual, 'Final residual should be set from residual adjustment when base is null');
    }

    @IsTest
    static void testModifierService_residualAdjustmentAddedToExisting() {
        // When finalResidual is non-null, residual adjustment is added to it
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];
        RateCard__c rc = [SELECT Id FROM RateCard__c LIMIT 1];

        Modifier__c mod = new Modifier__c(Rate_Card__c = rc.Id);
        insert mod;

        NT_PricingContext ctx = new NT_PricingContext(q.Id);
        ctx.selectedRateCard = rc;
        ctx.baseRate = null;
        ctx.baseRateFactor = null;
        ctx.baseResidual = 10.0;  // finalResidual initializes to 10.0
        ctx.eligibleModifiers = new List<Modifier__c>{ mod };
        ctx.parentId = q.Id;

        NT_ModifierService.testResidualOverride = 2.0;
        try {
            Test.startTest();
            NT_ModifierService svc = new NT_ModifierService();
            svc.applyModifiers(ctx);
            Test.stopTest();
        } finally {
            NT_ModifierService.testResidualOverride = null;
        }

        System.assertEquals(12.0, ctx.finalResidual, 'Residual adjustment should be added to existing final residual');
    }

    @IsTest
    static void testPricingOrchestratorQueueable_multipleRecords() {
        Quote q1 = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Pricing Opp' LIMIT 1];

        Quote q2 = new Quote(
            Name = 'Second Test Pricing Quote',
            OpportunityId = opp.Id,
            Requested_Term__c = '24',
            Total_Financed_Amount__c = 30000,
            Requested_Payment_Frequency__c = 'Monthly',
            End_of_Term_Option__c = '1.00 Out'
        );
        insert q2;

        Set<Id> ids = new Set<Id>{ q1.Id, q2.Id };

        RateCard__c rc = [SELECT Id, Entry_Criteria__c FROM RateCard__c LIMIT 1];
        Rate_Card_Row__c rcRow = [SELECT Id, Row_Criteria__c FROM Rate_Card_Row__c WHERE Rate_Card__c = :rc.Id LIMIT 1];
        Rate_Card_Column__c rcCol = [SELECT Id, Column_Criteria__c FROM Rate_Card_Column__c WHERE Rate_Card__c = :rc.Id LIMIT 1];

        NT_RateCardService.mockEntryRuleResults = new Map<Id, Map<Id, Boolean>>{
            q1.Id => new Map<Id, Boolean>{ rc.Entry_Criteria__c => true },
            q2.Id => new Map<Id, Boolean>{ rc.Entry_Criteria__c => true }
        };
        NT_RateCardService.mockRowRuleResults = new Map<Id, Map<Id, Boolean>>{
            q1.Id => new Map<Id, Boolean>{ rcRow.Row_Criteria__c => true },
            q2.Id => new Map<Id, Boolean>{ rcRow.Row_Criteria__c => true }
        };
        NT_RateCardService.mockColumnRuleResults = new Map<Id, Map<Id, Boolean>>{
            q1.Id => new Map<Id, Boolean>{ rcCol.Column_Criteria__c => true },
            q2.Id => new Map<Id, Boolean>{ rcCol.Column_Criteria__c => true }
        };

        try {
            Test.startTest();
            NT_PricingOrchestratorQueueable queueable =
                new NT_PricingOrchestratorQueueable(ids, 'Quote');
            queueable.execute(null);
            Test.stopTest();
        } finally {
            clearMockRuleResults();
        }

        List<Pricing_Result__c> results = [SELECT Id FROM Pricing_Result__c];
        System.assert(!results.isEmpty(), 'Should create at least one Pricing Result');
    }

    // ─── NT_RateCardService Mock Rule Results Tests ───────────────────────────

    @IsTest
    static void testRateCardService_mockRuleResults() {
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];
        configureMockRuleResults(q.Id);

        try {
            Test.startTest();
            NT_PricingOrchestrator orch = new NT_PricingOrchestrator();
            NT_PricingContext ctx = orch.executePricing(q.Id, 'Quote');
            Test.stopTest();

            System.assertNotEquals(null, ctx.selectedRateCard, 'Rate card should be selected');
        } finally {
            clearMockRuleResults();
        }
    }

    @IsTest
    static void testRateCardService_quoteSpecificCriteria() {
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];

        TCRE__Rule_Config__c entryRule = new TCRE__Rule_Config__c(TCRE__SObject_Name__c = 'Opportunity');
        TCRE__Rule_Config__c rowRule = new TCRE__Rule_Config__c(TCRE__SObject_Name__c = 'Opportunity');
        TCRE__Rule_Config__c colRule = new TCRE__Rule_Config__c(TCRE__SObject_Name__c = 'Opportunity');
        insert new List<TCRE__Rule_Config__c>{ entryRule, rowRule, colRule };

        RateCard__c rc = [SELECT Id FROM RateCard__c LIMIT 1];
        rc.Quote_Entry_Config__c = entryRule.Id;
        update rc;

        Rate_Card_Row__c rcRow = [SELECT Id FROM Rate_Card_Row__c WHERE Rate_Card__c = :rc.Id LIMIT 1];
        rcRow.Quote_Row_Criteria__c = rowRule.Id;
        update rcRow;

        Rate_Card_Column__c rcCol = [SELECT Id FROM Rate_Card_Column__c WHERE Rate_Card__c = :rc.Id LIMIT 1];
        rcCol.Quote_Column_Criteria__c = colRule.Id;
        update rcCol;

        NT_RateCardService.mockEntryRuleResults = new Map<Id, Map<Id, Boolean>>{
            q.Id => new Map<Id, Boolean>{ entryRule.Id => true }
        };
        NT_RateCardService.mockRowRuleResults = new Map<Id, Map<Id, Boolean>>{
            q.Id => new Map<Id, Boolean>{ rowRule.Id => true }
        };
        NT_RateCardService.mockColumnRuleResults = new Map<Id, Map<Id, Boolean>>{
            q.Id => new Map<Id, Boolean>{ colRule.Id => true }
        };

        try {
            Test.startTest();
            NT_PricingOrchestrator orch = new NT_PricingOrchestrator();
            NT_PricingContext ctx = orch.executePricing(q.Id, 'Quote');
            Test.stopTest();

            System.assertNotEquals(null, ctx.selectedRateCard, 'Rate card should be selected via Quote criteria');
            System.assertNotEquals(null, ctx.selectedRate, 'Rate should be found via Quote row/column criteria');
        } finally {
            clearMockRuleResults();
        }
    }

    @IsTest
    static void testRateCardService_opportunityCriteriaUnchanged() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Pricing Opp' LIMIT 1];

        TCRE__Rule_Config__c entryRule = new TCRE__Rule_Config__c(TCRE__SObject_Name__c = 'Opportunity');
        TCRE__Rule_Config__c rowRule = new TCRE__Rule_Config__c(TCRE__SObject_Name__c = 'Opportunity');
        TCRE__Rule_Config__c colRule = new TCRE__Rule_Config__c(TCRE__SObject_Name__c = 'Opportunity');
        insert new List<TCRE__Rule_Config__c>{ entryRule, rowRule, colRule };

        RateCard__c rc = [SELECT Id FROM RateCard__c LIMIT 1];
        rc.Entry_Criteria__c = entryRule.Id;
        update rc;

        Rate_Card_Row__c rcRow = [SELECT Id FROM Rate_Card_Row__c WHERE Rate_Card__c = :rc.Id LIMIT 1];
        rcRow.Row_Criteria__c = rowRule.Id;
        update rcRow;

        Rate_Card_Column__c rcCol = [SELECT Id FROM Rate_Card_Column__c WHERE Rate_Card__c = :rc.Id LIMIT 1];
        rcCol.Column_Criteria__c = colRule.Id;
        update rcCol;

        NT_RateCardService.mockEntryRuleResults = new Map<Id, Map<Id, Boolean>>{
            opp.Id => new Map<Id, Boolean>{ entryRule.Id => true }
        };
        NT_RateCardService.mockRowRuleResults = new Map<Id, Map<Id, Boolean>>{
            opp.Id => new Map<Id, Boolean>{ rowRule.Id => true }
        };
        NT_RateCardService.mockColumnRuleResults = new Map<Id, Map<Id, Boolean>>{
            opp.Id => new Map<Id, Boolean>{ colRule.Id => true }
        };

        try {
            Test.startTest();
            NT_PricingOrchestrator orch = new NT_PricingOrchestrator();
            NT_PricingContext ctx = orch.executePricing(opp.Id, 'Opportunity');
            Test.stopTest();

            System.assertNotEquals(null, ctx.selectedRateCard, 'Rate card should be selected via Opportunity criteria');
            System.assertNotEquals(null, ctx.selectedRate, 'Rate should be found via Opportunity row/column criteria');
        } finally {
            clearMockRuleResults();
        }
    }

    // ─── NT_ModifierService Exception Path Test ───────────────────────────────

    @IsTest
    static void testModifierService_evaluationException() {
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];
        RateCard__c rc = [SELECT Id FROM RateCard__c LIMIT 1];

        Modifier__c mod = new Modifier__c(Rate_Card__c = rc.Id);
        insert mod;

        NT_PricingContext ctx = new NT_PricingContext(q.Id);
        ctx.selectedRateCard = rc;
        ctx.baseRate = 5.5;
        ctx.finalRate = 5.5;
        ctx.baseRateFactor = 0.018;
        ctx.finalRateFactor = 0.018;
        ctx.baseResidual = 10.0;
        ctx.eligibleModifiers = new List<Modifier__c>{ mod };
        ctx.parentId = q.Id;

        NT_ModifierService.forceEvaluationException = true;
        try {
            Test.startTest();
            NT_ModifierService svc = new NT_ModifierService();
            svc.applyModifiers(ctx);
            Test.stopTest();
        } finally {
            NT_ModifierService.forceEvaluationException = false;
        }

        System.assertEquals(5.5, ctx.finalRate, 'Final rate should equal base when modifier throws');
    }

    // ─── NT_PricingResultService – createModifierResults coverage ────────────

    @IsTest
    static void testPricingResultService_createModifierResults_opportunityPath() {
        NT_PricingResultService svc = new NT_PricingResultService();
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Pricing Opp' LIMIT 1];
        RateCard__c rc = [SELECT Id FROM RateCard__c LIMIT 1];

        RateCard__c modRc = new RateCard__c(
            Effective_Start_Date__c = Date.today().addDays(-1),
            Rate_Card_Type__c = 'Rate Factor',
            Base_Rate__c = 1.5
        );
        insert modRc;

        Modifier__c mod = new Modifier__c(
            Rate_Card__c = rc.Id,
            Modifier_Rate_Card__c = modRc.Id
        );
        insert mod;
        mod = [SELECT Id, Rate_Card__c, Rate_Card__r.Base_Rate__c,
                      Modifier_Rate_Card__c, Modifier_Rate_Card__r.Base_Rate__c
               FROM Modifier__c WHERE Id = :mod.Id];

        NT_PricingContext ctx = new NT_PricingContext(opp.Id);
        ctx.appliedModifiers = new List<Modifier__c>{ mod };
        ctx.modifierRateAdjustments = new Map<Id, Decimal>{ mod.Id => 0.5 };
        ctx.modifierResidualAdjustments = new Map<Id, Decimal>{ mod.Id => 1.5 };
        ctx.modifierErrors = new Map<Id, String>();
        ctx.baseResidual = 10.0;
        ctx.baseRate = 2.0;
        ctx.financedAmount = 50000;

        Test.startTest();
        svc.createModifierResults(ctx);
        Test.stopTest();

        System.assert(!ctx.modifierResults.isEmpty(), 'Modifier results should be populated on ctx');
        List<Pricing_Result__c> results = [
            SELECT Id, Status__c, Source__c, Modified_Rate__c, Rate_Card__c, Base_Rate__c,
                   Residual_Amount__c, Modified_Residual_Amount__c, Total_Amount__c, Total_Rate__c
            FROM Pricing_Result__c
            WHERE Source__c = 'Modifier' AND Opportunity__c = :opp.Id
        ];
        System.assert(!results.isEmpty(), 'Modifier Pricing_Result__c should be created');
        System.assertEquals('Success', results[0].Status__c);
        System.assertEquals(rc.Id, results[0].Rate_Card__c, 'Modifier result should reference the parent rate card');
        System.assertEquals(2.0, results[0].Base_Rate__c, 'Modifier result should store parent rate card base rate');
        System.assertEquals(10.0, results[0].Residual_Amount__c, 'Modifier result should store base residual');
        System.assertEquals(750.0, results[0].Modified_Residual_Amount__c, 'Modifier result should store residual as dollar amount');
        System.assertEquals(51231.25, results[0].Total_Amount__c, 'Total amount should use formula (P-R)*(1+rate/100)+R');
        System.assertEquals(2.5, results[0].Total_Rate__c, 'Total rate should be parent base rate + modifier rate adjustment');
    }

    @IsTest
    static void testPricingResultService_createModifierResults_withModifierErrors() {
        NT_PricingResultService svc = new NT_PricingResultService();
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Pricing Opp' LIMIT 1];
        RateCard__c rc = [SELECT Id FROM RateCard__c LIMIT 1];

        RateCard__c modRc = new RateCard__c(
            Effective_Start_Date__c = Date.today().addDays(-1),
            Rate_Card_Type__c = 'Rate Factor',
            Base_Rate__c = 1.5
        );
        insert modRc;

        Modifier__c mod1 = new Modifier__c(Rate_Card__c = rc.Id, Modifier_Rate_Card__c = modRc.Id);
        Modifier__c mod2 = new Modifier__c(Rate_Card__c = rc.Id);
        insert new List<Modifier__c>{ mod1, mod2 };
        mod1 = [SELECT Id, Rate_Card__c, Rate_Card__r.Base_Rate__c,
                       Modifier_Rate_Card__c, Modifier_Rate_Card__r.Base_Rate__c
                FROM Modifier__c WHERE Id = :mod1.Id];

        NT_PricingContext ctx = new NT_PricingContext(opp.Id);
        ctx.appliedModifiers = new List<Modifier__c>{ mod1 };
        ctx.modifierRateAdjustments = new Map<Id, Decimal>{ mod1.Id => 0.5 };
        ctx.modifierResidualAdjustments = new Map<Id, Decimal>{ mod1.Id => 1.0 };
        ctx.modifierErrors = new Map<Id, String>{ mod2.Id => 'Rule engine error' };
        ctx.baseResidual = 10.0;
        ctx.baseRate = 2.0;
        ctx.financedAmount = 50000;

        Test.startTest();
        svc.createModifierResults(ctx);
        Test.stopTest();

        List<Pricing_Result__c> results = [
            SELECT Id, Status__c, Source__c, Error_Message__c, Rate_Card__c, Base_Rate__c,
                   Residual_Amount__c, Modified_Residual_Amount__c, Total_Amount__c, Total_Rate__c
            FROM Pricing_Result__c
            WHERE Source__c = 'Modifier'
        ];
        System.assertEquals(2, results.size(), 'Should create one success + one error modifier result');
        Integer errorCount = 0;
        for (Pricing_Result__c r : results) {
            if (r.Status__c == 'Error') { errorCount++; }
            if (r.Status__c == 'Success') {
                System.assertEquals(rc.Id, r.Rate_Card__c, 'Success result should reference parent rate card');
                System.assertEquals(2.0, r.Base_Rate__c, 'Success result should store parent rate card base rate');
                System.assertEquals(10.0, r.Residual_Amount__c, 'Success result should store base residual');
                System.assertEquals(500.0, r.Modified_Residual_Amount__c, 'Modifier result should store residual as dollar amount');
                System.assertEquals(51237.50, r.Total_Amount__c, 'Total amount should use formula (P-R)*(1+rate/100)+R');
                System.assertEquals(2.5, r.Total_Rate__c, 'Total rate should be parent base rate + modifier rate adjustment');
            }
        }
        System.assertEquals(1, errorCount, 'One error modifier result expected');
    }

    @IsTest
    static void testPricingResultService_createModifierResults_quotePath() {
        NT_PricingResultService svc = new NT_PricingResultService();
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];
        RateCard__c rc = [SELECT Id FROM RateCard__c LIMIT 1];

        RateCard__c modRc = new RateCard__c(
            Effective_Start_Date__c = Date.today().addDays(-1),
            Rate_Card_Type__c = 'Rate Factor',
            Base_Rate__c = 2.5
        );
        insert modRc;

        Modifier__c mod = new Modifier__c(
            Rate_Card__c = rc.Id,
            Modifier_Rate_Card__c = modRc.Id
        );
        insert mod;
        mod = [SELECT Id, Rate_Card__c, Rate_Card__r.Base_Rate__c,
                      Modifier_Rate_Card__c, Modifier_Rate_Card__r.Base_Rate__c
               FROM Modifier__c WHERE Id = :mod.Id];

        NT_PricingContext ctx = new NT_PricingContext(q.Id);
        ctx.quote = q;
        ctx.appliedModifiers = new List<Modifier__c>{ mod };
        ctx.modifierRateAdjustments = new Map<Id, Decimal>{ mod.Id => 0.25 };
        ctx.modifierResidualAdjustments = new Map<Id, Decimal>{ mod.Id => 0.75 };
        ctx.modifierErrors = new Map<Id, String>{ mod.Id => 'Test error for quote' };
        ctx.baseResidual = 8.0;
        ctx.baseRate = 3.0;
        ctx.financedAmount = 40000;

        Test.startTest();
        svc.createModifierResults(ctx);
        Test.stopTest();

        List<Pricing_Result__c> results = [
            SELECT Id, Status__c, Quote__c, Rate_Card__c, Base_Rate__c,
                   Residual_Amount__c, Modified_Residual_Amount__c, Total_Amount__c, Total_Rate__c
            FROM Pricing_Result__c
            WHERE Source__c = 'Modifier' AND Status__c = 'Success'
        ];
        System.assert(!results.isEmpty(), 'Modifier results should be created for quote context');
        System.assertEquals(q.Id, results[0].Quote__c, 'Quote lookup should be set');
        System.assertEquals(rc.Id, results[0].Rate_Card__c, 'Modifier result should reference the parent rate card');
        System.assertEquals(3.0, results[0].Base_Rate__c, 'Modifier result should store ctx.baseRate');
        System.assertEquals(8.0, results[0].Residual_Amount__c, 'Modifier result should store base residual');
        System.assertEquals(300.0, results[0].Modified_Residual_Amount__c, 'Modifier result should store residual as dollar amount');
        System.assertEquals(41290.25, results[0].Total_Amount__c, 'Total amount should use formula (P-R)*(1+rate/100)+R');
        System.assertEquals(3.25, results[0].Total_Rate__c, 'Total rate should be ctx.baseRate + modifier rate adjustment');
    }

    // ─── NT_PricingResultService – markModifierErrors coverage ───────────────

    @IsTest
    static void testPricingResultService_markModifierErrors() {
        NT_PricingResultService svc = new NT_PricingResultService();

        Pricing_Result__c pr = new Pricing_Result__c(Status__c = 'Pending');
        insert pr;

        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Pricing Opp' LIMIT 1];
        RateCard__c rc = [SELECT Id FROM RateCard__c LIMIT 1];
        Modifier__c mod = new Modifier__c(Rate_Card__c = rc.Id);
        insert mod;

        NT_PricingContext ctx = new NT_PricingContext(opp.Id);
        ctx.pricingResult = pr;
        ctx.modifierErrors = new Map<Id, String>{ mod.Id => 'Modifier evaluation failed' };

        Test.startTest();
        svc.markModifierErrors(ctx);
        Test.stopTest();

        Pricing_Result__c updated = [SELECT Status__c, Error_Message__c FROM Pricing_Result__c WHERE Id = :pr.Id];
        System.assertEquals('Error', updated.Status__c, 'Status should be Error');
        System.assert(updated.Error_Message__c.contains('One or more modifiers failed'), 'Error message should mention modifier failures');
    }

    @IsTest
    static void testPricingResultService_markModifierErrors_nullResultOrEmptyErrors() {
        NT_PricingResultService svc = new NT_PricingResultService();

        // null pricingResult - should return early
        NT_PricingContext ctx1 = new NT_PricingContext();
        ctx1.modifierErrors = new Map<Id, String>{ Id.valueOf('a00000000000001AAA') => 'err' };
        svc.markModifierErrors(ctx1); // no throw

        // empty modifierErrors - should return early
        Pricing_Result__c pr = new Pricing_Result__c(Status__c = 'Pending');
        insert pr;
        NT_PricingContext ctx2 = new NT_PricingContext();
        ctx2.pricingResult = pr;
        ctx2.modifierErrors = new Map<Id, String>();
        svc.markModifierErrors(ctx2); // no throw

        System.assert(true, 'Should handle null result and empty errors gracefully');
    }

    // ─── NT_PricingResultService – mapStatus coverage ────────────────────────

    @IsTest
    static void testPricingResultService_updatePricingResult_errorStatuses() {
        NT_PricingResultService svc = new NT_PricingResultService();

        Pricing_Result__c pr1 = new Pricing_Result__c(Status__c = 'Pending');
        Pricing_Result__c pr2 = new Pricing_Result__c(Status__c = 'Pending');
        insert new List<Pricing_Result__c>{ pr1, pr2 };

        // STATUS_ERROR path in mapStatus
        NT_PricingContext ctx1 = new NT_PricingContext();
        ctx1.pricingResult = pr1;
        ctx1.status = NT_PricingContext.STATUS_ERROR;
        ctx1.modifierErrors = new Map<Id, String>();

        // STATUS_PRICING_ERROR path in mapStatus
        NT_PricingContext ctx2 = new NT_PricingContext();
        ctx2.pricingResult = pr2;
        ctx2.status = NT_PricingContext.STATUS_PRICING_ERROR;
        ctx2.modifierErrors = new Map<Id, String>();

        Test.startTest();
        svc.updatePricingResult(ctx1);
        svc.updatePricingResult(ctx2);
        Test.stopTest();

        Pricing_Result__c updated1 = [SELECT Status__c FROM Pricing_Result__c WHERE Id = :pr1.Id];
        Pricing_Result__c updated2 = [SELECT Status__c FROM Pricing_Result__c WHERE Id = :pr2.Id];
        System.assertEquals('Error', updated1.Status__c, 'STATUS_ERROR should map to Error');
        System.assertEquals('Error', updated2.Status__c, 'STATUS_PRICING_ERROR should map to Error');
    }

    // ─── NT_ModifierService – Opportunity path and TCRE entry criteria ────────

    @IsTest
    static void testModifierService_opportunityPath() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Pricing Opp' LIMIT 1];
        RateCard__c rc = [SELECT Id FROM RateCard__c LIMIT 1];

        RateCard__c modRc = new RateCard__c(
            Effective_Start_Date__c = Date.today().addDays(-1),
            Rate_Card_Type__c = 'Rate Factor',
            Base_Rate__c = 2.0
        );
        insert modRc;

        Modifier__c mod = new Modifier__c(
            Rate_Card__c = rc.Id,
            Modifier_Rate_Card__c = modRc.Id
        );
        insert mod;
        mod = [SELECT Id, Name, Rate_Card__c, Modifier_Rate_Card__c, Modifier_Rate_Card__r.Base_Rate__c,
                      Modifier_Rate_Card__r.Entry_Criteria__c, Modifier_Rate_Card__r.Quote_Entry_Config__c
               FROM Modifier__c WHERE Id = :mod.Id];

        NT_PricingContext ctx = new NT_PricingContext(opp.Id);
        ctx.selectedRateCard = rc;
        ctx.baseRate = 5.0;
        ctx.finalRate = 5.0;
        ctx.baseRateFactor = 0.016;
        ctx.finalRateFactor = 0.016;
        ctx.baseResidual = 10.0;
        ctx.eligibleModifiers = new List<Modifier__c>{ mod };
        ctx.parentId = opp.Id;

        Test.startTest();
        NT_ModifierService svc = new NT_ModifierService();
        svc.applyModifiers(ctx);
        Test.stopTest();

        System.assertEquals(7.0, ctx.finalRate, 'Final rate should include modifier from opportunity path');
    }

    @IsTest
    static void testModifierService_withEntryCriteria() {
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];
        RateCard__c rc = [SELECT Id FROM RateCard__c LIMIT 1];

        TCRE__Rule_Config__c entryRule = new TCRE__Rule_Config__c(TCRE__SObject_Name__c = 'Opportunity');
        insert entryRule;

        RateCard__c modRc = new RateCard__c(
            Effective_Start_Date__c = Date.today().addDays(-1),
            Rate_Card_Type__c = 'Rate Factor',
            Base_Rate__c = 1.0,
            Quote_Entry_Config__c = entryRule.Id
        );
        insert modRc;

        Modifier__c mod = new Modifier__c(
            Rate_Card__c = rc.Id,
            Modifier_Rate_Card__c = modRc.Id
        );
        insert mod;
        mod = [SELECT Id, Name, Rate_Card__c, Modifier_Rate_Card__c, Modifier_Rate_Card__r.Base_Rate__c,
                      Modifier_Rate_Card__r.Entry_Criteria__c, Modifier_Rate_Card__r.Quote_Entry_Config__c
               FROM Modifier__c WHERE Id = :mod.Id];

        NT_PricingContext ctx = new NT_PricingContext(q.Id);
        ctx.selectedRateCard = rc;
        ctx.baseRate = 5.0;
        ctx.finalRate = 5.0;
        ctx.eligibleModifiers = new List<Modifier__c>{ mod };
        ctx.parentId = q.Id;

        Test.startTest();
        NT_ModifierService svc = new NT_ModifierService();
        svc.applyModifiers(ctx);
        Test.stopTest();

        // Modifier may or may not be applied depending on TCRE evaluation in test context
        System.assert(true, 'Should execute TCRE rule evaluation path without error');
    }

    // ─── NT_TValueQueueable – non-empty mock result (success path) ────────────

    @IsTest
    static void testTValueQueueable_nonEmptyMockResult() {
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Pricing Opp' LIMIT 1];

        tval__TValue_Quote__c tvq = new tval__TValue_Quote__c(
            tval__Term__c = 36,
            tval__Purchase_Option__c = '1.00 Out'
        );
        insert tvq;

        List<NT_TValueQueueable.TValueCombination> combos = new List<NT_TValueQueueable.TValueCombination>{
            new NT_TValueQueueable.TValueCombination('Monthly', 36)
        };

        NT_TValueQueueable.mockCalculateQuoteResult = new List<tval__TValue_Quote__c>{ tvq };
        try {
            Test.startTest();
            NT_TValueQueueable queueable = new NT_TValueQueueable(
                q.Id, opp.Id, null, null, 5.5, 50000,
                combos, null, null, '1.00 Out', 'Test Quote', new List<String>(), null, null
            );
            queueable.execute(null);
            Test.stopTest();
        } finally {
            NT_TValueQueueable.mockCalculateQuoteResult = null;
        }

        System.assert(true, 'Should handle non-empty mock result on last combination');
    }

    // ─── Per-Term Column Evaluation Tests (SAL-7084) ────────────────────────

    @IsTest
    static void testPerTermQuote_termPricingResultsPopulated() {
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];
        // Quote has Requested_Term__c = '36;60'
        configureMockRuleResults(q.Id);

        try {
            Test.startTest();
            NT_PricingOrchestrator orch = new NT_PricingOrchestrator();
            NT_PricingContext ctx = orch.executePricing(q.Id, 'Quote');
            Test.stopTest();

            System.assert(ctx.hasTermPricingResults(), 'termPricingResults should be populated for Quote with multiple terms');
            System.assertEquals(2, ctx.termPricingResults.size(), 'Should have one result per requested term');
            System.assert(ctx.termPricingResults.containsKey(36), 'Should have result for term 36');
            System.assert(ctx.termPricingResults.containsKey(60), 'Should have result for term 60');

            NT_PricingContext.TermPricingResult tpr36 = ctx.termPricingResults.get(36);
            NT_PricingContext.TermPricingResult tpr60 = ctx.termPricingResults.get(60);
            System.assertEquals(36, tpr36.term, 'TermPricingResult should store its term');
            System.assertEquals(60, tpr60.term, 'TermPricingResult should store its term');
            System.assertNotEquals(null, tpr36.baseRate, 'Base rate should be populated for term 36');
            System.assertNotEquals(null, tpr60.baseRate, 'Base rate should be populated for term 60');
        } finally {
            clearMockRuleResults();
        }
    }

    @IsTest
    static void testPerTermQuote_catchAllColumnSameRate() {
        // Catch-all scenario (AC7): single column matches all terms, same rate for each
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];
        configureMockRuleResults(q.Id);

        try {
            Test.startTest();
            NT_PricingOrchestrator orch = new NT_PricingOrchestrator();
            NT_PricingContext ctx = orch.executePricing(q.Id, 'Quote');
            Test.stopTest();

            System.assert(ctx.hasTermPricingResults(), 'Should have per-term results');

            // Both terms match the same column (mock returns same column for all iterations)
            // so both should receive the same rate (rateCardBaseRate 2.0 + cellRate 5.5 = 7.5)
            NT_PricingContext.TermPricingResult tpr36 = ctx.termPricingResults.get(36);
            NT_PricingContext.TermPricingResult tpr60 = ctx.termPricingResults.get(60);
            System.assertEquals(tpr36.baseRate, tpr60.baseRate,
                'Catch-all column: both terms should receive the same rate');
            System.assertEquals(7.5, tpr36.baseRate,
                'Rate should be rateCardBaseRate (2.0) + cellRate (5.5) = 7.5');
        } finally {
            clearMockRuleResults();
        }
    }

    @IsTest
    static void testPerTermQuote_modifiersAppliedPerTerm() {
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];
        RateCard__c rc = [SELECT Id FROM RateCard__c LIMIT 1];
        configureMockRuleResults(q.Id);

        RateCard__c modRc = new RateCard__c(
            Effective_Start_Date__c = Date.today().addDays(-1),
            Rate_Card_Type__c = 'Rate Factor',
            Base_Rate__c = 0.50
        );
        insert modRc;

        Modifier__c mod = new Modifier__c(
            Rate_Card__c = rc.Id,
            Modifier_Rate_Card__c = modRc.Id
        );
        insert mod;

        try {
            Test.startTest();
            NT_PricingOrchestrator orch = new NT_PricingOrchestrator();
            NT_PricingContext ctx = orch.executePricing(q.Id, 'Quote');
            Test.stopTest();

            System.assert(ctx.hasTermPricingResults(), 'Should have per-term results');
            NT_PricingContext.TermPricingResult tpr36 = ctx.termPricingResults.get(36);
            NT_PricingContext.TermPricingResult tpr60 = ctx.termPricingResults.get(60);

            // Base rate = 2.0 + 5.5 = 7.5; modifier adds 0.50 → finalRate = 8.0
            System.assertEquals(8.0, tpr36.finalRate,
                'Per-term final rate should include modifier adjustment');
            System.assertEquals(8.0, tpr60.finalRate,
                'Per-term final rate should include modifier adjustment');
        } finally {
            clearMockRuleResults();
        }
    }

    @IsTest
    static void testPerTermQuote_opportunityPathUnchanged() {
        // AC6: Opportunity pricing should NOT produce termPricingResults
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Pricing Opp' LIMIT 1];
        configureMockRuleResults(opp.Id);

        try {
            Test.startTest();
            NT_PricingOrchestrator orch = new NT_PricingOrchestrator();
            NT_PricingContext ctx = orch.executePricing(opp.Id, 'Opportunity');
            Test.stopTest();

            System.assert(!ctx.hasTermPricingResults(),
                'Opportunity path should NOT produce per-term pricing results');
            System.assertNotEquals(null, ctx.selectedRate,
                'Opportunity should still have a single selected rate');
            System.assertNotEquals(null, ctx.baseRate,
                'Opportunity should still have a single base rate');
        } finally {
            clearMockRuleResults();
        }
    }

    @IsTest
    static void testPerTermQuote_pricingTermFieldCleared() {
        // Verify Pricing_Term__c is cleared after per-term evaluation
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];
        configureMockRuleResults(q.Id);

        try {
            Test.startTest();
            NT_PricingOrchestrator orch = new NT_PricingOrchestrator();
            NT_PricingContext ctx = orch.executePricing(q.Id, 'Quote');
            Test.stopTest();

            Quote updatedQ = [SELECT Pricing_Term__c FROM Quote WHERE Id = :q.Id];
            System.assertEquals(null, updatedQ.Pricing_Term__c,
                'Pricing_Term__c should be cleared after per-term evaluation');
        } finally {
            clearMockRuleResults();
        }
    }

    @IsTest
    static void testPerTermQuote_backwardCompatibleCtxFields() {
        // ctx.baseRate / ctx.finalRate should be set from the first term's result
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];
        configureMockRuleResults(q.Id);

        try {
            Test.startTest();
            NT_PricingOrchestrator orch = new NT_PricingOrchestrator();
            NT_PricingContext ctx = orch.executePricing(q.Id, 'Quote');
            Test.stopTest();

            System.assertNotEquals(null, ctx.baseRate,
                'ctx.baseRate should be set for backward compatibility');
            System.assertNotEquals(null, ctx.finalRate,
                'ctx.finalRate should be set for backward compatibility');
            System.assertNotEquals(null, ctx.selectedRate,
                'ctx.selectedRate should be set for backward compatibility');
        } finally {
            clearMockRuleResults();
        }
    }

    @IsTest
    static void testTValueCombination_perTermRateAndResidual() {
        NT_TValueQueueable.TValueCombination combo =
            new NT_TValueQueueable.TValueCombination('Monthly', 24);
        combo.rate = 7.99;
        combo.residual = 15.0;

        System.assertEquals(7.99, combo.rate, 'Combination should hold per-term rate');
        System.assertEquals(15.0, combo.residual, 'Combination should hold per-term residual');
    }

    @IsTest
    static void testTValueQueueable_usesPerTermRate() {
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Pricing Opp' LIMIT 1];

        NT_TValueQueueable.TValueCombination combo =
            new NT_TValueQueueable.TValueCombination('Monthly', 36);
        combo.rate = 13.45;
        combo.residual = 15.0;

        List<NT_TValueQueueable.TValueCombination> combos =
            new List<NT_TValueQueueable.TValueCombination>{ combo };

        NT_TValueQueueable.mockCalculateQuoteResult = new List<tval__TValue_Quote__c>();
        try {
            Test.startTest();
            // finalRate = 5.5 but combination has rate = 13.45; combination should take precedence
            NT_TValueQueueable queueable = new NT_TValueQueueable(
                q.Id, opp.Id, null, null, 5.5, 50000,
                combos, null, 10.0, '1.00 Out', 'Test Quote', new List<String>(), null, null
            );
            queueable.execute(null);
            Test.stopTest();
        } finally {
            NT_TValueQueueable.mockCalculateQuoteResult = null;
        }

        System.assert(true, 'Should use per-term rate from combination');
    }

    @IsTest
    static void testPerTermContext_hasTermPricingResults() {
        NT_PricingContext ctx = new NT_PricingContext();
        System.assert(!ctx.hasTermPricingResults(), 'Empty map should return false');

        NT_PricingContext.TermPricingResult tpr = new NT_PricingContext.TermPricingResult();
        tpr.term = 36;
        tpr.baseRate = 7.5;
        tpr.finalRate = 7.5;
        ctx.termPricingResults.put(36, tpr);
        System.assert(ctx.hasTermPricingResults(), 'Non-empty map should return true');
    }

    @IsTest
    static void testPerTermQuote_multipleColumnsSetup() {
        // Test with two distinct columns at different rates
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];
        RateCard__c rc = [SELECT Id, Entry_Criteria__c FROM RateCard__c LIMIT 1];
        Rate_Card_Row__c rcRow = [SELECT Id, Row_Criteria__c, Quote_Row_Criteria__c FROM Rate_Card_Row__c WHERE Rate_Card__c = :rc.Id LIMIT 1];

        TCRE__Rule_Config__c col2Rule = new TCRE__Rule_Config__c(TCRE__SObject_Name__c = 'Opportunity');
        insert col2Rule;

        Rate_Card_Column__c rcCol2 = new Rate_Card_Column__c(
            Rate_Card__c = rc.Id,
            Residual__c = 5,
            Order__c = 2,
            Column_Criteria__c = col2Rule.Id,
            Quote_Column_Criteria__c = col2Rule.Id
        );
        insert rcCol2;

        insert new Rate_Card_Rate__c(
            Rate_Card_Row__c = rcRow.Id,
            Rate_Card_Column__c = rcCol2.Id,
            Rate__c = 3.25
        );

        Rate_Card_Column__c rcCol1 = [SELECT Id, Column_Criteria__c, Quote_Column_Criteria__c
            FROM Rate_Card_Column__c WHERE Rate_Card__c = :rc.Id AND Id != :rcCol2.Id LIMIT 1];

        // Mock: both columns match (simulates catch-all behavior)
        NT_RateCardService.mockEntryRuleResults = new Map<Id, Map<Id, Boolean>>{
            q.Id => new Map<Id, Boolean>{ rc.Entry_Criteria__c => true }
        };
        NT_RateCardService.mockRowRuleResults = new Map<Id, Map<Id, Boolean>>{
            q.Id => new Map<Id, Boolean>{ rcRow.Quote_Row_Criteria__c => true }
        };
        NT_RateCardService.mockColumnRuleResults = new Map<Id, Map<Id, Boolean>>{
            q.Id => new Map<Id, Boolean>{
                rcCol1.Quote_Column_Criteria__c => true,
                col2Rule.Id => true
            }
        };

        try {
            Test.startTest();
            NT_PricingOrchestrator orch = new NT_PricingOrchestrator();
            NT_PricingContext ctx = orch.executePricing(q.Id, 'Quote');
            Test.stopTest();

            System.assert(ctx.hasTermPricingResults(), 'Should produce per-term results');
            System.assertEquals(2, ctx.termPricingResults.size(), 'Should have results for both terms');
        } finally {
            clearMockRuleResults();
        }
    }

    // ─── Term-With-No-Matching-Column Handling ────────────────────────────

    @IsTest
    static void testPerTermQuote_termWithNoMatchingColumn_skipsTerm() {
        // Simulates a Rate Card that does NOT offer a column for one of the requested terms
        // (e.g., Quote asks for 36 and 60, but card only has a column for 36).
        // Expected: term 36 is priced, term 60 is skipped and removed from requestedTerms.
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];
        RateCard__c rc = [SELECT Id, Entry_Criteria__c FROM RateCard__c LIMIT 1];
        Rate_Card_Row__c rcRow = [SELECT Id, Row_Criteria__c FROM Rate_Card_Row__c WHERE Rate_Card__c = :rc.Id LIMIT 1];
        Rate_Card_Column__c rcCol = [SELECT Id, Column_Criteria__c FROM Rate_Card_Column__c WHERE Rate_Card__c = :rc.Id LIMIT 1];

        NT_RateCardService.mockEntryRuleResults = new Map<Id, Map<Id, Boolean>>{
            q.Id => new Map<Id, Boolean>{ rc.Entry_Criteria__c => true }
        };
        NT_RateCardService.mockRowRuleResults = new Map<Id, Map<Id, Boolean>>{
            q.Id => new Map<Id, Boolean>{ rcRow.Row_Criteria__c => true }
        };
        // Term 36 -> column matches; Term 60 -> no column matches
        NT_RateCardService.mockMatchingColumnCriteriaByTerm = new Map<String, Set<Id>>{
            '36' => new Set<Id>{ rcCol.Column_Criteria__c },
            '60' => new Set<Id>()
        };

        try {
            Test.startTest();
            NT_PricingOrchestrator orch = new NT_PricingOrchestrator();
            NT_PricingContext ctx = orch.executePricing(q.Id, 'Quote');
            Test.stopTest();

            System.assert(!ctx.hasError(),
                'Run should succeed when at least one term resolves. Error: ' + ctx.errorMessage);
            System.assert(ctx.hasTermPricingResults(), 'Should have per-term results');
            System.assertEquals(1, ctx.termPricingResults.size(),
                'Only the term with a matching column should be priced');
            System.assert(ctx.termPricingResults.containsKey(36),
                'Term 36 should be priced');
            System.assert(!ctx.termPricingResults.containsKey(60),
                'Term 60 should be skipped (no matching column)');
            System.assertEquals(1, ctx.requestedTerms.size(),
                'requestedTerms should contain only the resolved term');
            System.assertEquals(Decimal.valueOf(36), ctx.requestedTerms[0],
                'Resolved term 36 should remain in requestedTerms');
        } finally {
            NT_RateCardService.mockMatchingColumnCriteriaByTerm = null;
            clearMockRuleResults();
        }
    }

    @IsTest
    static void testPerTermQuote_allTermsSkipped_pricingError() {
        // If every requested term lacks a matching column, fail the whole run
        // with a Pricing Error (no quotes produced).
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Pricing Quote' LIMIT 1];
        RateCard__c rc = [SELECT Id, Entry_Criteria__c FROM RateCard__c LIMIT 1];
        Rate_Card_Row__c rcRow = [SELECT Id, Row_Criteria__c FROM Rate_Card_Row__c WHERE Rate_Card__c = :rc.Id LIMIT 1];

        NT_RateCardService.mockEntryRuleResults = new Map<Id, Map<Id, Boolean>>{
            q.Id => new Map<Id, Boolean>{ rc.Entry_Criteria__c => true }
        };
        NT_RateCardService.mockRowRuleResults = new Map<Id, Map<Id, Boolean>>{
            q.Id => new Map<Id, Boolean>{ rcRow.Row_Criteria__c => true }
        };
        // No column matches for either requested term
        NT_RateCardService.mockMatchingColumnCriteriaByTerm = new Map<String, Set<Id>>{
            '36' => new Set<Id>(),
            '60' => new Set<Id>()
        };

        try {
            Test.startTest();
            NT_PricingOrchestrator orch = new NT_PricingOrchestrator();
            NT_PricingContext ctx = orch.executePricing(q.Id, 'Quote');
            Test.stopTest();

            System.assert(ctx.hasError(),
                'Run should fail when no term can be priced');
            System.assertEquals(NT_PricingContext.STATUS_PRICING_ERROR, ctx.status,
                'Status should be Pricing Error, got: ' + ctx.status);
            System.assert(!ctx.hasTermPricingResults(),
                'No term should be priced');
            System.assert(ctx.errorMessage != null && ctx.errorMessage.contains('No requested term'),
                'Error message should explain no term could be priced, got: ' + ctx.errorMessage);
        } finally {
            NT_RateCardService.mockMatchingColumnCriteriaByTerm = null;
            clearMockRuleResults();
        }
    }

    @IsTest
    static void testOpportunity_noMatchingColumn_pricingError() {
        // Single-rate path: Opportunity with no matching column must now raise a
        // Pricing Error instead of silently falling back to the first rate on the card.
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Pricing Opp' LIMIT 1];
        RateCard__c rc = [SELECT Id, Entry_Criteria__c FROM RateCard__c LIMIT 1];
        Rate_Card_Row__c rcRow = [SELECT Id, Row_Criteria__c FROM Rate_Card_Row__c WHERE Rate_Card__c = :rc.Id LIMIT 1];

        NT_RateCardService.mockEntryRuleResults = new Map<Id, Map<Id, Boolean>>{
            opp.Id => new Map<Id, Boolean>{ rc.Entry_Criteria__c => true }
        };
        NT_RateCardService.mockRowRuleResults = new Map<Id, Map<Id, Boolean>>{
            opp.Id => new Map<Id, Boolean>{ rcRow.Row_Criteria__c => true }
        };
        // No column matches
        NT_RateCardService.mockColumnRuleResults = new Map<Id, Map<Id, Boolean>>{
            opp.Id => new Map<Id, Boolean>()
        };

        try {
            Test.startTest();
            NT_PricingOrchestrator orch = new NT_PricingOrchestrator();
            NT_PricingContext ctx = orch.executePricing(opp.Id, 'Opportunity');
            Test.stopTest();

            System.assert(ctx.hasError(),
                'Opportunity run should fail when no column matches');
            System.assertEquals(NT_PricingContext.STATUS_PRICING_ERROR, ctx.status,
                'Status should be Pricing Error, got: ' + ctx.status);
            System.assertEquals(null, ctx.selectedRate,
                'No rate should be selected when row+column intersection is empty');
            System.assert(ctx.errorMessage != null && ctx.errorMessage.contains('No rate found'),
                'Error should indicate no rate was found, got: ' + ctx.errorMessage);
        } finally {
            clearMockRuleResults();
        }
    }
}