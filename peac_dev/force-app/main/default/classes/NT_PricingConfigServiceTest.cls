/**
 * @description  Unit tests for NT_PricingConfigService parent-record mapping.
 *               SAL-7244 regression guard: the Opportunity (Calculate Pricing)
 *               path must map Down Payment, Buydown, and Subsidy into the pricing
 *               context so they reduce the financed amount sent to TValue, while
 *               equipment cost stays gross.
 * @author       Northteq
 * @date         2026-06-24
 */
@IsTest
private class NT_PricingConfigServiceTest {

    @TestSetup
    static void makeData() {
        insert new ORE__c(Bypass__c = true);

        Account acc = new Account(
            Name = 'Northteq Config Account',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId(),
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
            Name = 'Northteq Config Opp',
            AccountId = acc.Id,
            StageName = 'Application',
            CloseDate = Date.today().addDays(30),
            Primary_Source__c = 'Customer Inbound - Call',
            Equipment_Description__c = 'Test Equipment',
            Equipment_Cost__c = 50000,
            Terms__c = 36,
            Funded_Amount__c = 50000,
            Payment_Frequency__c = 'Monthly',
            Purchase_Options__c = '1.00 Out',
            Points__c = 2,
            Down_Payment__c = 1000,
            Buydown__c = 500,
            Subsidy__c = 250,
            Required_Adv_Payments__c = 2
        );
        insert opp;
    }

    /**
     * @description  SAL-7244 — Down Payment, Buydown, and Subsidy from the
     *               Opportunity are mapped into the context (they were previously
     *               dropped, so the Calculate Pricing button ignored them), while
     *               equipment cost stays gross and independent of the deductions.
     */
    @IsTest
    static void populateFromOpportunity_mapsDownBuydownSubsidy() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Northteq Config Opp' LIMIT 1];

        Test.startTest();
        NT_PricingContext ctx = new NT_PricingContext(opp.Id);
        new NT_PricingConfigService().loadConfiguration(ctx);
        Test.stopTest();

        System.assertEquals(1000, ctx.downPayment, 'Down Payment must be mapped from the Opportunity.');
        System.assertEquals(500, ctx.buyDown, 'Buydown (Opp field Buydown__c) must be mapped.');
        System.assertEquals(250, ctx.subsidy, 'Subsidy must be mapped from the Opportunity.');
        System.assertEquals(2, ctx.points, 'Points must be mapped from the Opportunity.');
        System.assertEquals(50000, ctx.equipmentCost, 'Equipment cost stays gross, independent of the deductions.');
        System.assertEquals(50000, ctx.financedAmount, 'Financed amount starts gross; deductions are applied in NT_TValueService.');
    }

    /**
     * @description  SAL-7384 — # Required Adv. Payments from the Opportunity is
     *               mapped into the context (it was previously dropped, so the
     *               Calculate Pricing path could never calculate in Advance or
     *               apply the annuity-due rate inversion).
     */
    @IsTest
    static void populateFromOpportunity_mapsRequiredAdvPayments() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Northteq Config Opp' LIMIT 1];

        Test.startTest();
        NT_PricingContext ctx = new NT_PricingContext(opp.Id);
        new NT_PricingConfigService().loadConfiguration(ctx);
        Test.stopTest();

        System.assertEquals(2, ctx.advancePayments,
            'SAL-7384: # Required Adv. Payments must be mapped from the Opportunity.');
    }

    // Creates an active rate card of the given type (Active__c is a formula off the effective dates)
    private static RateCard__c createActiveRateCard(String rateCardType) {
        RateCard__c rc = new RateCard__c(
            Effective_Start_Date__c = Date.today().addDays(-1),
            Rate_Card_Type__c = rateCardType,
            Base_Rate__c = 2.0
        );
        insert rc;
        return rc;
    }

    /**
     * @description  Quote path — loadConfiguration maps every pricing input from
     *               the Quote (financed amount, payment, points, down payment,
     *               buydown, advance payments, frequencies, terms, EOT option,
     *               residual) and loads generic rate cards plus their modifiers.
     */
    @IsTest
    static void populateFromQuote_mapsQuoteFieldsAndLoadsGenericCards() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Northteq Config Opp' LIMIT 1];
        RateCard__c rc = createActiveRateCard('Rate Factor');
        insert new Modifier__c(Rate_Card__c = rc.Id);

        Quote q = new Quote(
            Name = 'Northteq Config Quote',
            OpportunityId = opp.Id,
            Total_Financed_Amount__c = 60000,
            Payment__c = 1250,
            Points__c = 1.5,
            Down_Payment__c = 2000,
            Buy_Down__c = 300,
            Advance_Payments__c = 1,
            Requested_Payment_Frequency__c = 'Monthly',
            Requested_Term__c = '36;60',
            End_of_Term_Option__c = 'Customer Owned',
            Residual__c = 500
        );
        insert q;

        Test.startTest();
        NT_PricingContext ctx = new NT_PricingContext(q.Id);
        new NT_PricingConfigService().loadConfiguration(ctx);
        Test.stopTest();

        System.assertEquals(60000, ctx.financedAmount, 'Financed amount must map from Total_Financed_Amount__c.');
        System.assertEquals(1250, ctx.monthlyPayment, 'Payment must map from Payment__c.');
        System.assertEquals(1.5, ctx.points, 'Points must map from the Quote.');
        System.assertEquals(2000, ctx.downPayment, 'Down Payment must map from the Quote.');
        System.assertEquals(300, ctx.buyDown, 'Buy Down (Quote field Buy_Down__c) must map.');
        System.assertEquals(1, ctx.advancePayments, 'Advance Payments must map from the Quote.');
        System.assertEquals(new List<String>{ 'Monthly' }, ctx.paymentFrequencies,
            'Requested Payment Frequency multi-select must split into the frequency list.');
        System.assertEquals(new List<Decimal>{ 36, 60 }, ctx.requestedTerms,
            'Requested Term multi-select must parse into decimal terms.');
        System.assertEquals('Customer Owned', ctx.endOfTermOption, 'End of Term Option must map from the Quote.');
        System.assertEquals(500, ctx.baseResidual, 'Base residual must map from Quote Residual__c.');
        System.assertEquals(false, ctx.hasProgram, 'No program on the Quote → generic path.');
        System.assertEquals(1, ctx.eligibleRateCards.size(), 'Active generic rate card must be loaded.');
        System.assertEquals(1, ctx.eligibleModifiers.size(), 'Modifiers on eligible rate cards must be loaded.');
    }

    /**
     * @description  Quote path — a blank Requested Payment Frequency is a hard
     *               error (setError) because TValue cannot price without it.
     */
    @IsTest
    static void populateFromQuote_blankFrequency_setsError() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Northteq Config Opp' LIMIT 1];
        Quote q = new Quote(
            Name = 'Northteq Config Quote No Freq',
            OpportunityId = opp.Id,
            Total_Financed_Amount__c = 60000
        );
        insert q;

        Test.startTest();
        NT_PricingContext ctx = new NT_PricingContext(q.Id);
        new NT_PricingConfigService().loadConfiguration(ctx);
        Test.stopTest();

        System.assert(ctx.hasError(), 'Blank Requested Payment Frequency must set an error.');
        System.assert(ctx.errorMessage.contains('Requested Payment Frequency'),
            'Error must name the missing field: ' + ctx.errorMessage);
    }

    /**
     * @description  Opportunity path — when the Opportunity has no Program lookup
     *               but a child Quote carries one, the program is taken from the
     *               Quote, and the program-specific rate cards (via the
     *               Program_Rate_Card__c junction) and program residuals load.
     */
    @IsTest
    static void loadConfiguration_programFromChildQuote_loadsProgramConfig() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Northteq Config Opp' LIMIT 1];

        Program__c prog = new Program__c(
            Name = 'Northteq Config Program',
            Start_Date__c = Date.today().addDays(-1)
        );
        insert prog;

        insert new Quote(
            Name = 'Northteq Config Program Quote',
            OpportunityId = opp.Id,
            Program__c = prog.Id
        );

        RateCard__c rc = createActiveRateCard('Rate Factor');
        insert new Program_Rate_Card__c(Program__c = prog.Id, Rate_Card__c = rc.Id);

        RateCard__c residualTable = createActiveRateCard('Residual');
        insert new Program_Residual__c(Program__c = prog.Id, Residual_Balloon_Table__c = residualTable.Id);

        Test.startTest();
        NT_PricingContext ctx = new NT_PricingContext(opp.Id);
        new NT_PricingConfigService().loadConfiguration(ctx);
        Test.stopTest();

        System.assertEquals(prog.Id, ctx.programId, 'Program must be taken from the child Quote when the Opp has none.');
        System.assertEquals(true, ctx.hasProgram, 'Active program must be loaded.');
        System.assertEquals(1, ctx.eligibleRateCards.size(), 'Program rate card must load via the junction.');
        System.assertEquals(rc.Id, ctx.eligibleRateCards[0].Id, 'The junction-linked rate card must be the eligible one.');
        System.assertEquals(1, ctx.programResiduals.size(), 'Program residual must be loaded.');
    }

    /**
     * @description  loadGenericFallback clears program-derived rate cards and
     *               modifiers and reloads generic ones (used when program rate
     *               cards fail to price).
     */
    @IsTest
    static void loadGenericFallback_reloadsGenericCardsAndModifiers() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Northteq Config Opp' LIMIT 1];
        RateCard__c rc = createActiveRateCard('Rate Factor');
        insert new Modifier__c(Rate_Card__c = rc.Id);

        NT_PricingContext ctx = new NT_PricingContext(opp.Id);
        // Stale program-derived state that the fallback must replace
        ctx.eligibleRateCards = new List<RateCard__c>{ new RateCard__c() };
        ctx.eligibleModifiers = new List<Modifier__c>{ new Modifier__c() };

        Test.startTest();
        new NT_PricingConfigService().loadGenericFallback(ctx);
        Test.stopTest();

        System.assertEquals(1, ctx.eligibleRateCards.size(), 'Fallback must reload the active generic rate card.');
        System.assertEquals(rc.Id, ctx.eligibleRateCards[0].Id, 'Fallback rate card must come from a fresh query.');
        System.assertEquals(1, ctx.eligibleModifiers.size(), 'Fallback must reload modifiers for the generic cards.');
    }
}