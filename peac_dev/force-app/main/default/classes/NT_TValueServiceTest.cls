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
        // Query Equipment_Cost__c so computeTValueQuoteAmount can read it, mirroring how
        // NT_PricingConfigService loads the Opportunity in the real flow.
        Opportunity opp = [SELECT Id, Name, Equipment_Cost__c FROM Opportunity WHERE Name = 'Northteq Test Opp' LIMIT 1];
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

    // ---------------------------------------------------------------------
    // SAL-7244 — computeTValueQuoteAmount (amount the engine amortizes)
    // ---------------------------------------------------------------------

    /**
     * @description  Opportunity path: the amount fed to the engine as
     *               tval__Quote_Amount__c (which the engine actually amortizes) has
     *               Buydown and Subsidy removed, so the solved payment reflects them.
     *               Equipment Cost stays gross on the Opportunity itself.
     */
    @IsTest
    static void computeTValueQuoteAmount_opportunitySubtractsBuydownSubsidy() {
        NT_PricingContext ctx = buildValidContext(); // buyDown = 50, subsidy = 25
        ctx.parentType = NT_PricingContext.PARENT_TYPE_OPPORTUNITY;
        ctx.opportunity = new Opportunity(Equipment_Cost__c = 60000);
        System.assertEquals(
            59925,
            new NT_TValueService().computeTValueQuoteAmount(ctx),
            'Quote Amount (Opp path) = Equipment Cost − buyDown − subsidy = 60000 − 50 − 25'
        );
    }

    /**
     * @description  Down Payment must NOT reduce the amount fed to the engine on the
     *               Opportunity path — it is post-MVP (SAL-7417) and must not change the
     *               payment yet. Only Buydown/Subsidy reduce the amortized amount.
     */
    @IsTest
    static void computeTValueQuoteAmount_opportunityIgnoresDownPayment() {
        NT_PricingContext ctx = buildValidContext();
        ctx.parentType = NT_PricingContext.PARENT_TYPE_OPPORTUNITY;
        ctx.buyDown = null;
        ctx.subsidy = null;
        ctx.downPayment = 5000;
        ctx.opportunity = new Opportunity(Equipment_Cost__c = 60000);
        System.assertEquals(
            60000,
            new NT_TValueService().computeTValueQuoteAmount(ctx),
            'Down Payment does not reduce Quote Amount on the Opportunity path (SAL-7417 post-MVP)'
        );
    }

    // ---------------------------------------------------------------------
    // SAL-7404 — computeModifierBuyOutAmount (equipment-cost-based buyout)
    // ---------------------------------------------------------------------

    /**
     * @description  Opportunity-originated run with an applied residual modifier: buyout =
     *               Equipment Cost × modifier residual % (matches the modifier-level
     *               Pricing_Result__c.Modified_Residual_Amount__c basis).
     */
    @IsTest
    static void computeModifierBuyOutAmount_opportunityUsesEquipmentCost() {
        NT_PricingContext ctx = buildValidContext();
        ctx.parentType = NT_PricingContext.PARENT_TYPE_OPPORTUNITY;
        ctx.equipmentCost = 60000;
        ctx.modifierResidualAdjustments = new Map<Id, Decimal>{
            fakeModifierId(1) => 1.5
        };
        System.assertEquals(
            900,
            new NT_TValueService().computeModifierBuyOutAmount(ctx),
            'Buyout = equipment cost × residual modifier pct: 60000 × 1.5% = 900'
        );
    }

    /**
     * @description  Multiple residual modifiers sum: the buyout equals equipment cost × the
     *               summed percentage, i.e. the sum of the per-modifier dollar amounts.
     */
    @IsTest
    static void computeModifierBuyOutAmount_sumsResidualModifiers() {
        NT_PricingContext ctx = buildValidContext();
        ctx.parentType = NT_PricingContext.PARENT_TYPE_OPPORTUNITY;
        ctx.equipmentCost = 60000;
        ctx.modifierResidualAdjustments = new Map<Id, Decimal>{
            fakeModifierId(1) => 1.5,
            fakeModifierId(2) => 0.5,
            fakeModifierId(3) => null
        };
        System.assertEquals(
            1200,
            new NT_TValueService().computeModifierBuyOutAmount(ctx),
            'Buyout sums residual modifier pcts (null-safe): 60000 × 2.0% = 1200'
        );
    }

    /**
     * @description  Quote-originated runs are out of scope: null even with equipment cost
     *               and residual modifiers present.
     */
    @IsTest
    static void computeModifierBuyOutAmount_nullForQuoteOrigin() {
        NT_PricingContext ctx = buildValidContext();
        ctx.parentType = NT_PricingContext.PARENT_TYPE_QUOTE;
        ctx.equipmentCost = 60000;
        ctx.modifierResidualAdjustments = new Map<Id, Decimal>{
            fakeModifierId(1) => 1.5
        };
        System.assertEquals(
            null,
            new NT_TValueService().computeModifierBuyOutAmount(ctx),
            'Quote-originated runs must not produce a buyout amount (SAL-7404 scope)'
        );
    }

    /**
     * @description  No applied residual modifier (empty map or zero adjustments) or missing
     *               equipment cost: null, so the TValue buyout/balloon behavior is unchanged.
     */
    @IsTest
    static void computeModifierBuyOutAmount_nullWhenNoResidualModifierOrEquipmentCost() {
        NT_TValueService svc = new NT_TValueService();

        NT_PricingContext noModifiers = buildValidContext();
        noModifiers.parentType = NT_PricingContext.PARENT_TYPE_OPPORTUNITY;
        noModifiers.equipmentCost = 60000;
        System.assertEquals(null, svc.computeModifierBuyOutAmount(noModifiers),
            'No residual modifier applied → no buyout amount');

        NT_PricingContext zeroAdjustment = buildValidContext();
        zeroAdjustment.parentType = NT_PricingContext.PARENT_TYPE_OPPORTUNITY;
        zeroAdjustment.equipmentCost = 60000;
        zeroAdjustment.modifierResidualAdjustments = new Map<Id, Decimal>{ fakeModifierId(1) => 0 };
        System.assertEquals(null, svc.computeModifierBuyOutAmount(zeroAdjustment),
            'Zero residual adjustment → no buyout amount');

        NT_PricingContext noEquipmentCost = buildValidContext();
        noEquipmentCost.parentType = NT_PricingContext.PARENT_TYPE_OPPORTUNITY;
        noEquipmentCost.modifierResidualAdjustments = new Map<Id, Decimal>{ fakeModifierId(1) => 1.5 };
        System.assertEquals(null, svc.computeModifierBuyOutAmount(noEquipmentCost),
            'Null equipment cost → no buyout amount');
    }

    // ---------------------------------------------------------------------
    // SAL-7404 — invokeTValue wiring: the computed buyout must reach the queueable
    // ---------------------------------------------------------------------

    /**
     * @description  Opportunity-only overload: invokeTValue must push the computed
     *               equipment-cost buyout onto the queueable it enqueues (the seam between
     *               computeModifierBuyOutAmount and buildTValueQuote's stamp).
     */
    @IsTest
    static void invokeTValue_opportunity_wiresBuyOutOntoQueueable() {
        Opportunity opp = [SELECT Id, Name, Equipment_Cost__c FROM Opportunity WHERE Name = 'Northteq Test Opp' LIMIT 1];
        NT_PricingContext ctx = buildValidContext();
        ctx.parentId = opp.Id;
        ctx.parentType = NT_PricingContext.PARENT_TYPE_OPPORTUNITY;
        ctx.opportunity = opp;
        ctx.equipmentCost = 60000;
        ctx.modifierResidualAdjustments = new Map<Id, Decimal>{ fakeModifierId(1) => 1.5 };
        NT_TValueQueueable.mockCalculateQuoteResult = new List<tval__TValue_Quote__c>();

        Test.startTest();
        new NT_TValueService().invokeTValue(ctx);
        Test.stopTest();

        System.assertNotEquals(null, NT_TValueService.lastQueueable, 'A queueable must be built');
        System.assertEquals(900, NT_TValueService.lastQueueable.endOfTermBuyOut,
            'invokeTValue must set the equipment-cost buyout on the queueable: 60000 × 1.5% = 900');
    }

    /**
     * @description  Quote-parented overload with an Opportunity-originated context (real
     *               Calculate Pricing runs that carry a parent Quote) must also wire the buyout.
     */
    @IsTest
    static void invokeTValue_quoteParented_opportunityCtxWiresBuyOut() {
        Quote q = [SELECT Id, Name, OpportunityId FROM Quote WHERE Name = 'Northteq Test Quote' LIMIT 1];
        NT_PricingContext ctx = buildValidContext();
        ctx.parentId = q.OpportunityId;
        ctx.parentType = NT_PricingContext.PARENT_TYPE_OPPORTUNITY;
        ctx.equipmentCost = 60000;
        ctx.modifierResidualAdjustments = new Map<Id, Decimal>{ fakeModifierId(1) => 1.5 };
        NT_TValueQueueable.mockCalculateQuoteResult = new List<tval__TValue_Quote__c>();

        Test.startTest();
        new NT_TValueService().invokeTValue(ctx, q);
        Test.stopTest();

        System.assertNotEquals(null, NT_TValueService.lastQueueable, 'A queueable must be built');
        System.assertEquals(900, NT_TValueService.lastQueueable.endOfTermBuyOut,
            'Opportunity-originated runs through the Quote-parented overload must carry the buyout');
    }

    /**
     * @description  Quote-originated context through the Quote-parented overload leaves the
     *               buyout null on the queueable (SAL-7404 scope guard at the wiring level).
     */
    @IsTest
    static void invokeTValue_quote_ctxLeavesBuyOutNull() {
        Quote q = [SELECT Id, Name, OpportunityId FROM Quote WHERE Name = 'Northteq Test Quote' LIMIT 1];
        NT_PricingContext ctx = buildValidContext();
        ctx.parentId = q.Id;
        ctx.parentType = NT_PricingContext.PARENT_TYPE_QUOTE;
        ctx.equipmentCost = 60000;
        ctx.modifierResidualAdjustments = new Map<Id, Decimal>{ fakeModifierId(1) => 1.5 };
        NT_TValueQueueable.mockCalculateQuoteResult = new List<tval__TValue_Quote__c>();

        Test.startTest();
        new NT_TValueService().invokeTValue(ctx, q);
        Test.stopTest();

        System.assertNotEquals(null, NT_TValueService.lastQueueable, 'A queueable must be built');
        System.assertEquals(null, NT_TValueService.lastQueueable.endOfTermBuyOut,
            'Quote-originated runs must not carry a buyout even with equipment cost + residual modifiers present');
    }

    // SAL-7404 — deterministic fake Modifier__c Ids for the adjustment maps (no DML needed)
    private static Id fakeModifierId(Integer seq) {
        return Id.valueOf(Modifier__c.SObjectType.getDescribe().getKeyPrefix()
            + String.valueOf(seq).leftPad(12, '0'));
    }
}