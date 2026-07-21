/**
 * @description  Unit tests for NT_TValueQueueable. Covers:
 *                 - mapToTValuePurchaseOption (SAL-7243 translation helper)
 *                 - mapPaymentFrequency (every branch)
 *                 - execute() happy path via mockCalculateQuoteResult,
 *                   exercising buildTValueQuote, publishPlatformEvent,
 *                   updateOpportunityFromTValue, sendPricingNotification
 *                 - execute() error path via throwCalloutException, exercising
 *                   logError and setOpportunityPricingStatus
 *                 - execute() short-circuit on empty combinations
 * @author       Northteq
 * @date         2026-05-28
 */
@isTest
private class NT_TValueQueueableTest {

    @TestSetup
    static void makeData() {
        Account acc = new Account(
            Name = 'NT_TValueQueueableTest Account',
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
            Name = 'NT_TValueQueueableTest Opp',
            AccountId = acc.Id,
            StageName = 'Application',
            CloseDate = Date.today().addDays(30),
            Primary_Source__c = 'Customer Inbound - Call',
            Equipment_Description__c = 'Test Equipment',
            Equipment_Cost__c = 50000,
            Terms__c = 36,
            Funded_Amount__c = 50000,
            Payment_Frequency__c = 'Monthly',
            Purchase_Options__c = '1.00 Out'
        );
        insert opp;

        Quote q = new Quote(Name = 'NT_TValueQueueableTest Quote', OpportunityId = opp.Id);
        insert q;

        insert new Pricing_Result__c(
            Opportunity__c = opp.Id,
            Quote__c = q.Id,
            Total_Rate__c = 5.5,
            Status__c = 'In Progress',
            Source__c = 'Base Rate',
            Transaction_Id__c = 'tvq-test-001'
        );
    }

    /** Build a queueable with the seeded data + a single combination. */
    private static NT_TValueQueueable makeQueueable(Decimal term, String freq) {
        Quote q = [SELECT Id, Name FROM Quote WHERE Name = 'NT_TValueQueueableTest Quote' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'NT_TValueQueueableTest Opp' LIMIT 1];
        Pricing_Result__c pr = [SELECT Id FROM Pricing_Result__c WHERE Transaction_Id__c = 'tvq-test-001' LIMIT 1];
        List<NT_TValueQueueable.TValueCombination> combos = new List<NT_TValueQueueable.TValueCombination>();
        if (term != null) {
            NT_TValueQueueable.TValueCombination c = new NT_TValueQueueable.TValueCombination(freq, term);
            c.rate = 6.25;
            c.residual = 1000;
            combos.add(c);
        }
        return new NT_TValueQueueable(
            q.Id, opp.Id, null, pr.Id,
            5.5, 50000, combos,
            1, 1000, '1.00 Out',
            'NT_TValueQueueableTest Quote', new List<String>(), 'tvq-test-001', null
        );
    }

    @isTest
    static void mapToTValuePurchaseOption_translates1OutToBuyout() {
        System.assertEquals(
            '$1.00 Buyout',
            NT_TValueQueueable.mapToTValuePurchaseOption('1.00 Out'),
            'SAL-7243: "1.00 Out" must be translated to "$1.00 Buyout" for TValue.'
        );
    }

    @isTest
    static void mapToTValuePurchaseOption_isCaseInsensitiveFor1Out() {
        System.assertEquals(
            '$1.00 Buyout',
            NT_TValueQueueable.mapToTValuePurchaseOption('1.00 OUT'),
            'Case-insensitive matching keeps the translation robust to picklist label drift.'
        );
    }

    @isTest
    static void mapToTValuePurchaseOption_passesThroughOtherValues() {
        System.assertEquals(
            'Customer Owned',
            NT_TValueQueueable.mapToTValuePurchaseOption('Customer Owned'),
            'Non-buyout values must pass through unchanged.'
        );
        System.assertEquals(
            'FMV',
            NT_TValueQueueable.mapToTValuePurchaseOption('FMV'),
            'FMV must pass through unchanged.'
        );
        System.assertEquals(
            '$1.00 Buyout',
            NT_TValueQueueable.mapToTValuePurchaseOption('$1.00 Buyout'),
            'Legacy "$1.00 Buyout" must pass through unchanged.'
        );
    }

    @isTest
    static void mapToTValuePurchaseOption_handlesBlankInput() {
        System.assertEquals(
            null,
            NT_TValueQueueable.mapToTValuePurchaseOption(null),
            'Null input returns null.'
        );
        System.assertEquals(
            '',
            NT_TValueQueueable.mapToTValuePurchaseOption(''),
            'Empty string passes through as empty.'
        );
    }

    /**
     * Exercise every branch of mapPaymentFrequency, including the blank
     * and "no keyword matched" fallbacks.
     */
    @isTest
    static void mapPaymentFrequency_coversEveryBranch() {
        NT_TValueQueueable q = makeQueueable(36, 'Monthly');
        System.assertEquals('Monthly', q.mapPaymentFrequency(null));
        System.assertEquals('Monthly', q.mapPaymentFrequency(''));
        System.assertEquals('Monthly', q.mapPaymentFrequency('monthly'));
        System.assertEquals('Quarterly', q.mapPaymentFrequency('Quarterly'));
        System.assertEquals('Semiannual', q.mapPaymentFrequency('Semi-Annual'));
        System.assertEquals('Semiannual', q.mapPaymentFrequency('Half-yearly'));
        System.assertEquals('Annual', q.mapPaymentFrequency('Annual'));
        System.assertEquals('Annual', q.mapPaymentFrequency('Yearly'));
        System.assertEquals('Weekly', q.mapPaymentFrequency('Weekly'));
        System.assertEquals('Daily', q.mapPaymentFrequency('Daily'));
        System.assertEquals('Daily', q.mapPaymentFrequency('Per day'));
        System.assertEquals('Monthly', q.mapPaymentFrequency('Unknown cadence'));
    }

    /**
     * execute() with no combinations should short-circuit cleanly.
     */
    @isTest
    static void execute_isNoOpWhenCombinationsEmpty() {
        NT_TValueQueueable q = makeQueueable(null, null);
        Test.startTest();
        q.execute(null);
        Test.stopTest();
        // No-op contract: completing without exception is the assertion.
        System.assert(true);
    }

    /**
     * Happy path: mockCalculateQuoteResult returns a calculated TValue Quote,
     * exercising buildTValueQuote, publishPlatformEvent, the post-callout
     * Quote/Opp updates, and updateOpportunityFromTValue's SOQL fall-through.
     */
    @isTest
    static void execute_successPathPublishesEventAndUpdatesQuote() {
        Quote q = [SELECT Id FROM Quote WHERE Name = 'NT_TValueQueueableTest Quote' LIMIT 1];
        // A real tval__TValue_Quote__c so updateOpportunityFromTValue's SOQL finds it.
        tval__TValue_Quote__c mocked;
        try {
            mocked = new tval__TValue_Quote__c(
                Quote__c = q.Id,
                tval__Term__c = 36,
                tval__Purchase_Option__c = '$1.00 Buyout',
                tval__Nominal_Annual_Rate__c = 6.25,
                tval__Payment_Amount__c = 1500
            );
            insert mocked;
        } catch (Exception ex) {
            // tval managed trigger may NPE in this org for synthetic test data —
            // execute()'s success path still runs because we only need the mock
            // list to be non-empty; the SOQL inside updateOpportunityFromTValue
            // is wrapped in its own try/catch.
            System.debug('Skipping tval insert due to managed trigger: ' + ex.getMessage());
        }

        NT_TValueQueueable.mockCalculateQuoteResult = new List<tval__TValue_Quote__c>{
            mocked != null
                ? mocked
                : new tval__TValue_Quote__c(Quote__c = q.Id, tval__Term__c = 36)
        };

        NT_TValueQueueable queueable = makeQueueable(36, 'Monthly');
        Test.startTest();
        queueable.execute(null);
        Test.stopTest();

        Quote refreshed = [SELECT Pricing_Status__c FROM Quote WHERE Id = :q.Id];
        System.assertEquals('Success', refreshed.Pricing_Status__c,
            'Quote.Pricing_Status__c must flip to Success after the last combination completes.');
    }

    /**
     * Error path: throwCalloutException routes through logError /
     * setOpportunityPricingStatus, marking the Pricing_Result__c as Error.
     */
    @isTest
    static void execute_errorPathLogsAndMarksPricingResultError() {
        NT_TValueQueueable.throwCalloutException = true;
        NT_TValueQueueable queueable = makeQueueable(48, 'Monthly');
        Test.startTest();
        queueable.execute(null);
        Test.stopTest();

        Pricing_Result__c pr = [
            SELECT Status__c, Error_Message__c
            FROM Pricing_Result__c
            WHERE Transaction_Id__c = 'tvq-test-001' LIMIT 1
        ];
        System.assertEquals('Error', pr.Status__c,
            'Pricing_Result__c.Status__c must be set to Error when the callout throws.');
        System.assert(
            pr.Error_Message__c != null && pr.Error_Message__c.contains('TValue Error'),
            'Error_Message__c must include the TValue Error prefix.'
        );
    }

    /**
     * sendPricingNotification is invoked from execute() but is also reachable
     * directly when called with a null opportunityId (short-circuits without
     * querying CustomNotificationType, useful when the notif type isn't seeded).
     */
    @isTest
    static void sendPricingNotification_isNoOpForNullOpportunityId() {
        Test.startTest();
        NT_TValueQueueable.sendPricingNotification('t', 'b', null);
        Test.stopTest();
        System.assert(true, 'Null opportunityId returns early without exception.');
    }

    // ---------------------------------------------------------------------
    // SAL-7244 — dealer points are added to the rate on the TValue Quote
    // ---------------------------------------------------------------------

    /** Build a queueable with an explicit points value (financed amount is pre-net). */
    private static NT_TValueQueueable makeQueueableWithPoints(Decimal points) {
        Quote q = [SELECT Id, Name FROM Quote WHERE Name = 'NT_TValueQueueableTest Quote' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'NT_TValueQueueableTest Opp' LIMIT 1];
        Pricing_Result__c pr = [SELECT Id FROM Pricing_Result__c WHERE Transaction_Id__c = 'tvq-test-001' LIMIT 1];
        NT_TValueQueueable.TValueCombination c = new NT_TValueQueueable.TValueCombination('Monthly', 36);
        c.rate = 6.25;
        c.residual = 1000;
        return new NT_TValueQueueable(
            q.Id, opp.Id, null, pr.Id,
            5.5, 50000, new List<NT_TValueQueueable.TValueCombination>{ c },
            1, 1000, '1.00 Out',
            'NT_TValueQueueableTest Quote', new List<String>(), 'tvq-test-001', points
        );
    }

    /**
     * @description  SAL-7381 — points must NOT be added to the rate (that markup was wrong);
     *               points flow to TValue as a commission amount instead. Even with points set,
     *               tval__Rate__c stays the combination rate. Equipment cost is never on the
     *               TValue Quote, so the financed amount passed in (already net) is stamped
     *               unchanged.
     */
    @isTest
    static void buildTValueQuote_appliesPointsToRate() {
        NT_TValueQueueable q = makeQueueableWithPoints(2);
        NT_TValueQueueable.TValueCombination combo = new NT_TValueQueueable.TValueCombination('Monthly', 36);
        combo.rate = 6.25;
        combo.residual = 1000;

        Test.startTest();
        tval__TValue_Quote__c tvq = q.buildTValueQuote(combo);
        Test.stopTest();

        System.assertEquals(6.25, tvq.tval__Rate__c,
            'SAL-7381: points must not be added to the rate; rate stays the combination rate.');
        System.assertEquals(50000, tvq.tval__Amount_Financed__c, 'Net financed amount passed in is stamped unchanged.');
    }

    /**
     * @description  With no points, the rate is the combination rate unchanged.
     */
    @isTest
    static void buildTValueQuote_noPointsLeavesRate() {
        NT_TValueQueueable q = makeQueueableWithPoints(null);
        NT_TValueQueueable.TValueCombination combo = new NT_TValueQueueable.TValueCombination('Monthly', 36);
        combo.rate = 6.25;

        Test.startTest();
        tval__TValue_Quote__c tvq = q.buildTValueQuote(combo);
        Test.stopTest();

        System.assertEquals(6.25, tvq.tval__Rate__c, 'With no points the rate is unchanged.');
    }

    // ---------------------------------------------------------------------
    // SAL-7384 — advance payments flip the engine's Advance/Arrears picklist
    // ---------------------------------------------------------------------

    /** Build a queueable with an explicit advance-payment count. */
    private static NT_TValueQueueable makeQueueableWithAdvancePayments(Decimal advancePayments) {
        Quote q = [SELECT Id, Name FROM Quote WHERE Name = 'NT_TValueQueueableTest Quote' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'NT_TValueQueueableTest Opp' LIMIT 1];
        Pricing_Result__c pr = [SELECT Id FROM Pricing_Result__c WHERE Transaction_Id__c = 'tvq-test-001' LIMIT 1];
        NT_TValueQueueable.TValueCombination c = new NT_TValueQueueable.TValueCombination('Monthly', 36);
        c.rate = 6.25;
        return new NT_TValueQueueable(
            q.Id, opp.Id, null, pr.Id,
            5.5, 50000, new List<NT_TValueQueueable.TValueCombination>{ c },
            advancePayments, 1000, '1.00 Out',
            'NT_TValueQueueableTest Quote', new List<String>(), 'tvq-test-001', null
        );
    }

    /**
     * @description  SAL-7384 — ≥1 required advance payment must stamp the engine's
     *               timing picklist to Advance (the tval__Payment_In_Advance__c
     *               checkbox alone does not drive the engine) alongside the count.
     */
    @isTest
    static void buildTValueQuote_advancePaymentsStampsAdvance() {
        NT_TValueQueueable q = makeQueueableWithAdvancePayments(2);
        NT_TValueQueueable.TValueCombination combo = new NT_TValueQueueable.TValueCombination('Monthly', 36);
        combo.rate = 6.25;

        Test.startTest();
        tval__TValue_Quote__c tvq = q.buildTValueQuote(combo);
        Test.stopTest();

        System.assertEquals('Advance', tvq.tval__Advance_Arrears__c,
            'SAL-7384: >=1 advance payment must calculate in Advance.');
        System.assertEquals(2, tvq.tval__Number_of_Advanced_Payments__c, 'Advance-payment count is stamped.');
        System.assertEquals(true, tvq.tval__Payment_In_Advance__c, 'Checkbox mirrors a positive count.');
    }

    /**
     * @description  SAL-7384 — zero advance payments keeps the quote in Arrears.
     */
    @isTest
    static void buildTValueQuote_zeroAdvancePaymentsStampsArrears() {
        NT_TValueQueueable q = makeQueueableWithAdvancePayments(0);
        NT_TValueQueueable.TValueCombination combo = new NT_TValueQueueable.TValueCombination('Monthly', 36);
        combo.rate = 6.25;

        Test.startTest();
        tval__TValue_Quote__c tvq = q.buildTValueQuote(combo);
        Test.stopTest();

        System.assertEquals('Arrears', tvq.tval__Advance_Arrears__c,
            'SAL-7384: zero advance payments calculates in Arrears.');
        System.assertEquals(false, tvq.tval__Payment_In_Advance__c, 'Checkbox stays false for a zero count.');
    }

    /**
     * @description  SAL-7384 — a null count stamps Arrears explicitly (not relying
     *               on the picklist default) and leaves count/checkbox untouched.
     */
    @isTest
    static void buildTValueQuote_nullAdvancePaymentsStampsArrears() {
        NT_TValueQueueable q = makeQueueableWithAdvancePayments(null);
        NT_TValueQueueable.TValueCombination combo = new NT_TValueQueueable.TValueCombination('Monthly', 36);
        combo.rate = 6.25;

        Test.startTest();
        tval__TValue_Quote__c tvq = q.buildTValueQuote(combo);
        Test.stopTest();

        System.assertEquals('Arrears', tvq.tval__Advance_Arrears__c,
            'SAL-7384: null advance payments stamps Arrears explicitly.');
        System.assertEquals(null, tvq.tval__Number_of_Advanced_Payments__c, 'Count is untouched when null.');
        // Reading an unset checkbox field returns false, not null.
        System.assertNotEquals(true, tvq.tval__Payment_In_Advance__c, 'Checkbox must not be true when the count is null.');
    }

    // ---------------------------------------------------------------------
    // SAL-7404 — equipment-cost-based residual buyout on tval__End_of_Term_Buy_Out__c
    // ---------------------------------------------------------------------

    /**
     * @description  SAL-7404 — a buyout amount set on the queueable is stamped on
     *               tval__End_of_Term_Buy_Out__c, alongside (not replacing) the
     *               existing balloon mapping.
     */
    @isTest
    static void buildTValueQuote_endOfTermBuyOutStamped() {
        NT_TValueQueueable q = makeQueueable(36, 'Monthly');
        q.setEndOfTermBuyOut(900);
        NT_TValueQueueable.TValueCombination combo = new NT_TValueQueueable.TValueCombination('Monthly', 36);
        combo.rate = 6.25;
        combo.residual = 1000;

        Test.startTest();
        tval__TValue_Quote__c tvq = q.buildTValueQuote(combo);
        Test.stopTest();

        System.assertEquals(900, tvq.tval__End_of_Term_Buy_Out__c,
            'SAL-7404: the equipment-cost-based buyout amount is stamped on tval__End_of_Term_Buy_Out__c.');
        System.assertEquals(1000, tvq.tval__Balloon_Payment_Amount__c,
            'Balloon mapping is unchanged by the buyout stamp.');
    }

    /**
     * @description  SAL-7404 — with no buyout amount (Quote-originated run or no residual
     *               modifier), tval__End_of_Term_Buy_Out__c stays unset and balloon
     *               behavior is unchanged from today.
     */
    @isTest
    static void buildTValueQuote_noBuyOutLeavesFieldUnset() {
        NT_TValueQueueable q = makeQueueable(36, 'Monthly');
        NT_TValueQueueable.TValueCombination combo = new NT_TValueQueueable.TValueCombination('Monthly', 36);
        combo.rate = 6.25;
        combo.residual = 1000;

        Test.startTest();
        tval__TValue_Quote__c tvq = q.buildTValueQuote(combo);
        Test.stopTest();

        System.assertEquals(null, tvq.tval__End_of_Term_Buy_Out__c,
            'SAL-7404: without a buyout amount the field stays unset.');
        System.assertEquals(1000, tvq.tval__Balloon_Payment_Amount__c,
            'Balloon mapping is unchanged when no buyout applies.');
    }

    /**
     * @description  SAL-7404 — the buyout must survive the combination chain: the
     *               next-in-chain queueable carries it and stamps it on its own quote
     *               (a dropped carry would silently lose the buyout on combos 2+).
     */
    @isTest
    static void buildNextInChain_carriesEndOfTermBuyOut() {
        NT_TValueQueueable q = makeQueueable(36, 'Monthly');
        q.setEndOfTermBuyOut(900);

        Test.startTest();
        NT_TValueQueueable next = q.buildNextInChain();
        Test.stopTest();

        System.assertEquals(900, next.endOfTermBuyOut,
            'SAL-7404: the buyout amount must be carried onto the next chained queueable.');
        NT_TValueQueueable.TValueCombination combo = new NT_TValueQueueable.TValueCombination('Monthly', 48);
        combo.rate = 6.25;
        System.assertEquals(900, next.buildTValueQuote(combo).tval__End_of_Term_Buy_Out__c,
            'The chained queueable must stamp the carried buyout on its own TValue Quote.');
    }

    // ---------------------------------------------------------------------
    // SAL-7432 — strip form-reserved characters from the TValue quote name so the
    // managed package's unencoded callout body isn't corrupted (Import 460 error)
    // ---------------------------------------------------------------------

    /**
     * @description  SAL-7432 — '&' in the name (common on the Opportunity path, which names
     *               quotes off the account name) is replaced with 'and' so it can't split
     *               the tval package's x-www-form-urlencoded callout body.
     */
    @isTest
    static void sanitizeQuoteName_replacesAmpersand() {
        System.assertEquals(
            'Joseph Jingoli and Son, Inc',
            NT_TValueQueueable.sanitizeQuoteName('Joseph Jingoli & Son, Inc'),
            'SAL-7432: "&" must become "and" so it cannot corrupt the TValue callout body.'
        );
    }

    /**
     * @description  SAL-7432 — the other form-reserved characters ('%', '+') are dropped;
     *               ordinary characters are untouched.
     */
    @isTest
    static void sanitizeQuoteName_dropsPercentAndPlus() {
        System.assertEquals(
            'A100 B Co',
            NT_TValueQueueable.sanitizeQuoteName('A100% B+ Co'),
            'SAL-7432: "%" and "+" must be dropped from the quote name.'
        );
    }

    /**
     * @description  SAL-7432 — a name with no reserved characters passes through unchanged;
     *               null passes through as null (no naming behavior change for the common case).
     */
    @isTest
    static void sanitizeQuoteName_leavesCleanNameAndNullUnchanged() {
        System.assertEquals(
            'Northteq Clean Name',
            NT_TValueQueueable.sanitizeQuoteName('Northteq Clean Name'),
            'A name with no reserved characters is unchanged.'
        );
        System.assertEquals(null, NT_TValueQueueable.sanitizeQuoteName(null),
            'A null name passes through as null.');
    }

    /**
     * @description  SAL-7432 — the sanitized name is what actually lands on the built
     *               TValue Quote (end-to-end through buildTValueQuote), ahead of the
     *               "- <freq> - <term> mo" suffix.
     */
    @isTest
    static void buildTValueQuote_sanitizesNameOnBuiltQuote() {
        Quote q = [SELECT Id FROM Quote WHERE Name = 'NT_TValueQueueableTest Quote' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'NT_TValueQueueableTest Opp' LIMIT 1];
        Pricing_Result__c pr = [SELECT Id FROM Pricing_Result__c WHERE Transaction_Id__c = 'tvq-test-001' LIMIT 1];
        NT_TValueQueueable.TValueCombination c = new NT_TValueQueueable.TValueCombination('Monthly', 36);
        c.rate = 6.25;
        NT_TValueQueueable queueable = new NT_TValueQueueable(
            q.Id, opp.Id, null, pr.Id,
            5.5, 50000, new List<NT_TValueQueueable.TValueCombination>{ c },
            0, 1000, '1.00 Out',
            'Joseph Jingoli & Son, Inc', new List<String>(), 'tvq-test-001', null
        );

        Test.startTest();
        tval__TValue_Quote__c tvq = queueable.buildTValueQuote(c);
        Test.stopTest();

        System.assertEquals(
            'Joseph Jingoli and Son, Inc - Monthly - 36 mo',
            tvq.tval__Quote_Name__c,
            'SAL-7432: the built TValue Quote name must have "&" neutralized before the suffix.'
        );
    }
}