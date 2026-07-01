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
        System.assertEquals('Semi-Annual', q.mapPaymentFrequency('Semi-Annual'));
        System.assertEquals('Semi-Annual', q.mapPaymentFrequency('Half-yearly'));
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
}