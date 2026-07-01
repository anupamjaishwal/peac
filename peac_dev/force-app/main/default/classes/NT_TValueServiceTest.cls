/**
 * @description  Unit tests for NT_TValueService: the SAL-6442 max-combinations cap (12),
 *               both invokeTValue overloads (Quote-parented and Opportunity-only),
 *               their guard/early-return branches, and canInvokeTValue validation.
 *               TValue callouts are bypassed via NT_TValueQueueable.mockCalculateQuoteResult
 *               so execute() runs synchronously without a live callout.
 * @author       Northteq
 * @date         2026-06-24
 */
@IsTest
private class NT_TValueServiceTest {

    /**
     * @description  Seeds an Account, Opportunity and Quote shared by the invoke tests.
     */
    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Northteq Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Northteq Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;

        Quote q = new Quote(Name = 'Northteq Test Quote', OpportunityId = opp.Id);
        insert q;
    }

    /**
     * @description  Builds a fully-populated, error-free context valid for TValue invocation.
     * @return       NT_PricingContext ready to drive invokeTValue.
     */
    private static NT_PricingContext buildValidContext() {
        NT_PricingContext ctx = new NT_PricingContext();
        ctx.paymentFrequencies = new List<String>{ 'Monthly' };
        ctx.requestedTerms = new List<Decimal>{ 24, 36 };
        ctx.financedAmount = 10000;
        ctx.downPayment = 100;
        ctx.buyDown = 50;
        ctx.subsidy = 25;
        ctx.finalRate = 9.75;
        ctx.finalResidual = 0;
        ctx.advancePayments = 1;
        ctx.endOfTermOption = '1.00 Out';
        ctx.points = 0;
        ctx.transactionId = 'northteq-tx-001';
        return ctx;
    }

    // ---------------------------------------------------------------------
    // buildCombinations — cap behavior
    // ---------------------------------------------------------------------

    /**
     * @description  When frequencies × terms exceeds the cap, only MAX_QUOTE_COMBINATIONS
     *               are built (deterministic first-N), never the full fan-out.
     */
    @IsTest
    static void buildCombinations_capsAtMax() {
        NT_PricingContext ctx = new NT_PricingContext();
        // 3 frequencies × 6 terms = 18 raw combinations -> must cap to 12.
        ctx.paymentFrequencies = new List<String>{ 'Monthly', 'Quarterly', 'Annually' };
        ctx.requestedTerms = new List<Decimal>{ 12, 18, 24, 36, 48, 60 };

        Test.startTest();
        List<NT_TValueQueueable.TValueCombination> combos = new NT_TValueService().buildCombinations(ctx);
        Test.stopTest();

        System.assertEquals(
            NT_TValueService.MAX_QUOTE_COMBINATIONS,
            combos.size(),
            'Combinations should be capped at MAX_QUOTE_COMBINATIONS when the raw fan-out exceeds it'
        );
    }

    /**
     * @description  Below the cap, every requested combination is built unchanged
     *               (multi-term fan-out is intended behavior).
     */
    @IsTest
    static void buildCombinations_belowCapReturnsAll() {
        NT_PricingContext ctx = new NT_PricingContext();
        // MVP shape: 1 frequency × 6 terms = 6 combinations, under the cap.
        ctx.paymentFrequencies = new List<String>{ 'Monthly' };
        ctx.requestedTerms = new List<Decimal>{ 12, 18, 24, 36, 48, 60 };

        Test.startTest();
        List<NT_TValueQueueable.TValueCombination> combos = new NT_TValueService().buildCombinations(ctx);
        Test.stopTest();

        System.assertEquals(6, combos.size(), 'All 6 MVP combinations should be returned when under the cap');
    }

    /**
     * @description  With no terms supplied, no combinations are produced.
     */
    @IsTest
    static void buildCombinations_noTermsReturnsEmpty() {
        NT_PricingContext ctx = new NT_PricingContext();
        ctx.paymentFrequencies = new List<String>{ 'Monthly' };
        ctx.requestedTerms = new List<Decimal>();

        Test.startTest();
        List<NT_TValueQueueable.TValueCombination> combos = new NT_TValueService().buildCombinations(ctx);
        Test.stopTest();

        System.assertEquals(0, combos.size(), 'No terms should yield no combinations');
    }

    // ---------------------------------------------------------------------
    // invokeTValue(ctx, parentQuote) — Quote-parented
    // ---------------------------------------------------------------------

    /**
     * @description  Happy path: a valid context + parent Quote enqueues/executes the
     *               queueable without setting an error.
     */
    @IsTest
    static void invokeTValue_quote_happyPath() {
        Quote q = [SELECT Id, Name, OpportunityId FROM Quote WHERE Name = 'Northteq Test Quote' LIMIT 1];
        NT_PricingContext ctx = buildValidContext();
        NT_TValueQueueable.mockCalculateQuoteResult = new List<tval__TValue_Quote__c>();

        Test.startTest();
        new NT_TValueService().invokeTValue(ctx, q);
        Test.stopTest();

        System.assertEquals(false, ctx.hasError(), 'A valid Quote invocation should not flag an error');
    }

    /**
     * @description  An already-errored context short-circuits and is left untouched.
     */
    @IsTest
    static void invokeTValue_quote_returnsWhenContextHasError() {
        Quote q = [SELECT Id, Name FROM Quote WHERE Name = 'Northteq Test Quote' LIMIT 1];
        NT_PricingContext ctx = buildValidContext();
        ctx.setError('pre-existing error');

        Test.startTest();
        new NT_TValueService().invokeTValue(ctx, q);
        Test.stopTest();

        System.assertEquals('pre-existing error', ctx.errorMessage,
            'Existing error message must be preserved when invocation short-circuits');
    }

    /**
     * @description  A null parent Quote sets a descriptive error.
     */
    @IsTest
    static void invokeTValue_quote_nullQuoteSetsError() {
        NT_PricingContext ctx = buildValidContext();

        Test.startTest();
        new NT_TValueService().invokeTValue(ctx, (Quote) null);
        Test.stopTest();

        System.assertEquals(true, ctx.hasError(), 'A null parent Quote must flag an error');
    }

    /**
     * @description  No combinations (no terms) returns early without enqueuing or erroring.
     */
    @IsTest
    static void invokeTValue_quote_noCombinationsReturnsEarly() {
        Quote q = [SELECT Id, Name, OpportunityId FROM Quote WHERE Name = 'Northteq Test Quote' LIMIT 1];
        NT_PricingContext ctx = buildValidContext();
        ctx.requestedTerms = new List<Decimal>();

        Test.startTest();
        new NT_TValueService().invokeTValue(ctx, q);
        Test.stopTest();

        System.assertEquals(false, ctx.hasError(), 'Empty combinations should return quietly, not error');
    }

    // ---------------------------------------------------------------------
    // invokeTValue(ctx) — Opportunity-only
    // ---------------------------------------------------------------------

    /**
     * @description  Happy path: Opportunity context enqueues/executes the queueable.
     */
    @IsTest
    static void invokeTValue_opportunity_happyPath() {
        Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Name = 'Northteq Test Opp' LIMIT 1];
        NT_PricingContext ctx = buildValidContext();
        ctx.parentId = opp.Id;
        ctx.parentType = NT_PricingContext.PARENT_TYPE_OPPORTUNITY;
        ctx.opportunity = opp;
        NT_TValueQueueable.mockCalculateQuoteResult = new List<tval__TValue_Quote__c>();

        Test.startTest();
        new NT_TValueService().invokeTValue(ctx);
        Test.stopTest();

        System.assertEquals(false, ctx.hasError(), 'A valid Opportunity invocation should not flag an error');
    }

    /**
     * @description  An already-errored context short-circuits the Opportunity overload.
     */
    @IsTest
    static void invokeTValue_opportunity_returnsWhenContextHasError() {
        NT_PricingContext ctx = buildValidContext();
        ctx.setError('pre-existing error');

        Test.startTest();
        new NT_TValueService().invokeTValue(ctx);
        Test.stopTest();

        System.assertEquals('pre-existing error', ctx.errorMessage,
            'Existing error must be preserved when the Opportunity overload short-circuits');
    }

    /**
     * @description  Non-Opportunity context (or missing Opportunity) sets a descriptive error.
     */
    @IsTest
    static void invokeTValue_opportunity_requiresOpportunityContext() {
        NT_PricingContext ctx = buildValidContext(); // no parentType / opportunity set

        Test.startTest();
        new NT_TValueService().invokeTValue(ctx);
        Test.stopTest();

        System.assertEquals(true, ctx.hasError(),
            'A non-Opportunity context must flag an error in the Quote-less overload');
    }

    // ---------------------------------------------------------------------
    // canInvokeTValue
    // ---------------------------------------------------------------------

    /**
     * @description  A complete, error-free context can invoke TValue.
     */
    @IsTest
    static void canInvokeTValue_trueForValidContext() {
        NT_PricingContext ctx = buildValidContext();
        System.assertEquals(true, new NT_TValueService().canInvokeTValue(ctx),
            'A valid context should be invokable');
    }

    /**
     * @description  An errored context cannot invoke TValue.
     */
    @IsTest
    static void canInvokeTValue_falseWhenError() {
        NT_PricingContext ctx = buildValidContext();
        ctx.setError('boom');
        System.assertEquals(false, new NT_TValueService().canInvokeTValue(ctx),
            'An errored context is not invokable');
    }

    /**
     * @description  No rate (neither finalRate nor finalRateFactor) blocks invocation.
     */
    @IsTest
    static void canInvokeTValue_falseWhenNoRate() {
        NT_PricingContext ctx = buildValidContext();
        ctx.finalRate = null;
        ctx.finalRateFactor = null;
        System.assertEquals(false, new NT_TValueService().canInvokeTValue(ctx),
            'Missing rate must block invocation');
    }

    /**
     * @description  A non-positive financed amount blocks invocation.
     */
    @IsTest
    static void canInvokeTValue_falseWhenNoFinancedAmount() {
        NT_PricingContext ctx = buildValidContext();
        ctx.financedAmount = 0;
        System.assertEquals(false, new NT_TValueService().canInvokeTValue(ctx),
            'A zero financed amount must block invocation');
    }

    // ---------------------------------------------------------------------
    // SAL-7244 — computeNetFinancedAmount (down payment + buydown + subsidy)
    // ---------------------------------------------------------------------

    /**
     * @description  Down payment, buy-down, and subsidy are each subtracted from
     *               the gross financed amount before it is sent to TValue.
     */
    @IsTest
    static void computeNetFinancedAmount_subtractsDownBuydownSubsidy() {
        NT_PricingContext ctx = buildValidContext(); // 10000 − 100 − 50 − 25
        System.assertEquals(
            9825,
            new NT_TValueService().computeNetFinancedAmount(ctx),
            'Net financed = financed − downPayment − buyDown − subsidy'
        );
    }

    /**
     * @description  Null levers are treated as zero; the financed amount is unchanged.
     */
    @IsTest
    static void computeNetFinancedAmount_nullLeversTreatedAsZero() {
        NT_PricingContext ctx = buildValidContext();
        ctx.downPayment = null;
        ctx.buyDown = null;
        ctx.subsidy = null;
        System.assertEquals(
            10000,
            new NT_TValueService().computeNetFinancedAmount(ctx),
            'With no levers the net financed amount equals the gross financed amount'
        );
    }

    /**
     * @description  Levers exceeding the financed amount floor the net at 0
     *               (never a negative financed amount sent to TValue).
     */
    @IsTest
    static void computeNetFinancedAmount_flooredAtZero() {
        NT_PricingContext ctx = buildValidContext();
        ctx.financedAmount = 100;
        ctx.downPayment = 80;
        ctx.buyDown = 80;
        ctx.subsidy = 0;
        System.assertEquals(
            0,
            new NT_TValueService().computeNetFinancedAmount(ctx),
            'Net financed amount is floored at 0 when levers exceed the financed amount'
        );
    }
}