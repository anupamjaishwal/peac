/**
 * @description  SAL-6441 — Integration tests for the "solve for financed amount" path in
 *               NT_RateCardService (solveRatePerTermFromPayment). Builds a two-tier Interest-Rate
 *               rate card (5k–25k @ 13%, 25k–500k @ 9.75%) with real TCRE amount-band conditions and
 *               verifies the payment inverts to the amount in the self-consistent tier — and that a
 *               payment too small for any tier yields a pricing error rather than a mis-priced quote.
 * @author       Northteq
 * @date         2026-07-06
 */
@IsTest
private class NT_RateCardServiceSolveTest {

    // Ids captured at setup for building the pricing context and mock rule results.
    private static Id quoteId;
    private static Id rateCardId;
    private static Id rowCfgAId; // 5k–25k
    private static Id rowCfgBId; // 25k–500k
    private static Id colCfgId;
    private static Id entryCfgId;

    @TestSetup
    static void makeData() {
        insert new ORE__c(Bypass__c = true);

        Account acc = new Account(
            Name = 'Northteq Test Dealer',
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
            Name = 'Northteq Test Opp',
            AccountId = acc.Id,
            StageName = 'Application',
            CloseDate = Date.today().addDays(30),
            Primary_Source__c = 'Customer Inbound - Call',
            Equipment_Description__c = 'Test Equipment',
            Equipment_Cost__c = 50000,
            Terms__c = 24,
            Funded_Amount__c = 50000,
            Payment_Frequency__c = 'Monthly',
            Purchase_Options__c = '1.00 Out'
        );
        insert opp;

        // Payment path: Requested Payment Amount set, Total_Financed_Amount__c intentionally null.
        Quote q = new Quote(
            Name = 'Northteq Test Quote',
            OpportunityId = opp.Id,
            Requested_Term__c = '24',
            Requested_Payment_Frequency__c = 'Monthly',
            End_of_Term_Option__c = '1.00 Out'
        );
        insert q;

        TCRE__Rule_Config__c entryCfg = new TCRE__Rule_Config__c(TCRE__SObject_Name__c = 'Quote');
        TCRE__Rule_Config__c rowCfgA = new TCRE__Rule_Config__c(TCRE__SObject_Name__c = 'Quote');
        TCRE__Rule_Config__c rowCfgB = new TCRE__Rule_Config__c(TCRE__SObject_Name__c = 'Quote');
        TCRE__Rule_Config__c colCfg = new TCRE__Rule_Config__c(TCRE__SObject_Name__c = 'Quote');
        insert new List<TCRE__Rule_Config__c>{ entryCfg, rowCfgA, rowCfgB, colCfg };

        // Real amount-band conditions so getRowAmountBounds reads the tier bounds.
        insert new List<TCRE__Rule_Condition__c>{
            new TCRE__Rule_Condition__c(TCRE__Rule_Config__c = rowCfgA.Id,
                TCRE__Field_Name__c = 'Total_Financed_Amount__c', TCRE__Operator__c = '>=', TCRE__Value__c = '5000'),
            new TCRE__Rule_Condition__c(TCRE__Rule_Config__c = rowCfgA.Id,
                TCRE__Field_Name__c = 'Total_Financed_Amount__c', TCRE__Operator__c = '<', TCRE__Value__c = '25000'),
            new TCRE__Rule_Condition__c(TCRE__Rule_Config__c = rowCfgB.Id,
                TCRE__Field_Name__c = 'Total_Financed_Amount__c', TCRE__Operator__c = '>=', TCRE__Value__c = '25000'),
            new TCRE__Rule_Condition__c(TCRE__Rule_Config__c = rowCfgB.Id,
                TCRE__Field_Name__c = 'Total_Financed_Amount__c', TCRE__Operator__c = '<=', TCRE__Value__c = '500000')
        };

        RateCard__c rc = new RateCard__c(
            Effective_Start_Date__c = Date.today().addDays(-1),
            Rate_Card_Type__c = 'Interest Rate',
            Base_Rate__c = 0,
            Entry_Criteria__c = entryCfg.Id,
            Quote_Entry_Config__c = entryCfg.Id
        );
        insert rc;

        Rate_Card_Row__c rowA = new Rate_Card_Row__c(
            Rate_Card__c = rc.Id, Row_Criteria__c = rowCfgA.Id, Quote_Row_Criteria__c = rowCfgA.Id);
        Rate_Card_Row__c rowB = new Rate_Card_Row__c(
            Rate_Card__c = rc.Id, Row_Criteria__c = rowCfgB.Id, Quote_Row_Criteria__c = rowCfgB.Id);
        insert new List<Rate_Card_Row__c>{ rowA, rowB };

        Rate_Card_Column__c col = new Rate_Card_Column__c(
            Rate_Card__c = rc.Id, Column_Criteria__c = colCfg.Id, Quote_Column_Criteria__c = colCfg.Id);
        insert col;

        insert new List<Rate_Card_Rate__c>{
            new Rate_Card_Rate__c(Rate_Card_Row__c = rowA.Id, Rate_Card_Column__c = col.Id, Rate__c = 13),
            new Rate_Card_Rate__c(Rate_Card_Row__c = rowB.Id, Rate_Card_Column__c = col.Id, Rate__c = 9.75)
        };
    }

    // Loads setup Ids and builds a payment-path pricing context with mock rule results.
    private static NT_PricingContext buildContext(Decimal payment) {
        RateCard__c rc = [SELECT Id, Name, Base_Rate__c, Rate_Card_Type__c, Quote_Entry_Config__c FROM RateCard__c LIMIT 1];
        Quote q = [SELECT Id, Pricing_Term__c, Total_Financed_Amount__c FROM Quote LIMIT 1];
        Map<String, Id> cfgByField = new Map<String, Id>();
        rateCardId = rc.Id;
        quoteId = q.Id;
        entryCfgId = rc.Quote_Entry_Config__c;
        for (Rate_Card_Row__c row : [SELECT Quote_Row_Criteria__c FROM Rate_Card_Row__c WHERE Rate_Card__c = :rc.Id ORDER BY CreatedDate]) {
            if (rowCfgAId == null) { rowCfgAId = row.Quote_Row_Criteria__c; }
            else { rowCfgBId = row.Quote_Row_Criteria__c; }
        }
        colCfgId = [SELECT Quote_Column_Criteria__c FROM Rate_Card_Column__c WHERE Rate_Card__c = :rc.Id LIMIT 1].Quote_Column_Criteria__c;

        NT_PricingContext ctx = new NT_PricingContext(q.Id);
        ctx.quote = q;
        ctx.eligibleRateCards = new List<RateCard__c>{ rc };
        ctx.monthlyPayment = payment;      // Requested Payment Amount
        ctx.financedAmount = null;          // solve-for-financed path
        ctx.requestedTerms = new List<Decimal>{ 24 };
        ctx.paymentFrequencies = new List<String>{ 'Monthly' };

        // Mock TCRE so entry passes, both rows are credit-tier-applicable, and the column matches.
        NT_RateCardService.mockEntryRuleResults = new Map<Id, Map<Id, Boolean>>{
            q.Id => new Map<Id, Boolean>{ entryCfgId => true }
        };
        NT_RateCardService.mockRowRuleResults = new Map<Id, Map<Id, Boolean>>{
            q.Id => new Map<Id, Boolean>{ rowCfgAId => true, rowCfgBId => true }
        };
        NT_RateCardService.mockColumnRuleResults = new Map<Id, Map<Id, Boolean>>{
            q.Id => new Map<Id, Boolean>{ colCfgId => true }
        };
        return ctx;
    }

    @IsTest
    static void solvesIntoLowerTier() {
        NT_PricingContext ctx = buildContext(500); // ~$10.5k at 13% → 5k–25k tier
        Test.startTest();
        new NT_RateCardService().evaluateRateCards(ctx);
        Test.stopTest();

        System.assert(ctx.hasTermPricingResults(), 'Expected a solved term result. err=' + ctx.errorMessage);
        NT_PricingContext.TermPricingResult tpr = ctx.termPricingResults.get(24);
        System.assertNotEquals(null, tpr, 'Term 24 should be solved');
        System.assertEquals(13, tpr.finalRate, 'Lower tier rate (13%) expected');
        System.assert(tpr.financedAmount > 5000 && tpr.financedAmount < 25000,
            'Solved amount should land in the 5k–25k tier, was ' + tpr.financedAmount);
    }

    @IsTest
    static void solvesIntoHigherTier() {
        NT_PricingContext ctx = buildContext(1500); // ~$32.6k at 9.75% → 25k–500k tier
        Test.startTest();
        new NT_RateCardService().evaluateRateCards(ctx);
        Test.stopTest();

        NT_PricingContext.TermPricingResult tpr = ctx.termPricingResults.get(24);
        System.assertNotEquals(null, tpr, 'Term 24 should be solved. err=' + ctx.errorMessage);
        System.assertEquals(9.75, tpr.finalRate, 'Higher tier rate (9.75%) expected');
        System.assert(tpr.financedAmount >= 25000 && tpr.financedAmount <= 500000,
            'Solved amount should land in the 25k–500k tier, was ' + tpr.financedAmount);
    }

    @IsTest
    static void paymentTooSmallProducesPricingError() {
        NT_PricingContext ctx = buildContext(100); // implies ~$2.1k — below the lowest tier
        Test.startTest();
        new NT_RateCardService().evaluateRateCards(ctx);
        Test.stopTest();

        System.assert(!ctx.hasTermPricingResults(), 'No tier should be self-consistent for a tiny payment');
        System.assert(ctx.hasError(), 'A no-solution payment must raise a pricing error');
    }
}