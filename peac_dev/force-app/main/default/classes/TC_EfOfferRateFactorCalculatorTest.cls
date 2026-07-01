@IsTest
public class TC_EfOfferRateFactorCalculatorTest {

    @TestSetup
    static void makeData() {
        insert new ORE__c(Bypass__c = true);

        Account acc = new Account(
            Name = 'Test Rate Factor Account',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
                .get('End User Account').getRecordTypeId(),
            Business_Address__c = '100 Main St',
            Account_Billing_Street__c = '100 Main St',
            Business_City__c = 'Dallas',
            Account_Billing_City__c = 'Dallas',
            Business_State__c = 'TX',
            Account_Billing_State_Province__c = 'TX',
            Business_Zip__c = '75001',
            Account_Billing_Zip_Postal_Code__c = '75001'
        );
        insert acc;

        insert new Opportunity(
            Name = 'Test Rate Factor Opp',
            AccountId = acc.Id,
            StageName = 'Application',
            CloseDate = Date.today().addDays(30),
            Primary_Source__c = 'Customer Inbound - Call',
            Equipment_Description__c = 'Test Equipment',
            Equipment_Cost__c = 25000,
            Terms__c = 36,
            Funded_Amount__c = 25000,
            Payment_Frequency__c = 'Monthly',
            Purchase_Options__c = '1.00 Out'
        );
    }

    // Returns a base opp with fields used by calculate/calculateFMV
    private static Opportunity getBaseOpp() {
        return [
            SELECT Id, Purchase_Options__c, Portal_User_ID__c,
                   Deferral_Payments__c, Required_Adv_Payments__c
            FROM Opportunity LIMIT 1
        ];
    }

    private static EF_Approved_Offers__c makeOffer(Id oppId, Decimal yld, Decimal term, String advRental) {
        return new EF_Approved_Offers__c(
            Opportunity__c = oppId,
            Yield__c = yld,
            Term_in_Months__c = term,
            Advanced_Rental__c = advRental
        );
    }

    // ─── calculate() tests ───────────────────────────────────────────────────

    @IsTest
    static void testCalculate_StandardRateFactor() {
        Opportunity opp = getBaseOpp();
        EF_Approved_Offers__c ef = makeOffer(opp.Id, 10.0, 36, null);
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>{ opp.Id => opp };

        Test.startTest();
        List<EF_Approved_Offers__c> results = TC_EfOfferRateFactorCalculator.calculate(
            new List<EF_Approved_Offers__c>{ ef }, oppMap);
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertNotEquals(0, results[0].Rate_Factor__c, 'Rate factor should be calculated');
    }

    @IsTest
    static void testCalculate_NullYieldSetsZero() {
        Opportunity opp = getBaseOpp();
        EF_Approved_Offers__c ef = makeOffer(opp.Id, null, 36, null);
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>{ opp.Id => opp };

        Test.startTest();
        List<EF_Approved_Offers__c> results = TC_EfOfferRateFactorCalculator.calculate(
            new List<EF_Approved_Offers__c>{ ef }, oppMap);
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(0, results[0].Rate_Factor__c, 'Null yield should result in rate factor 0');
    }

    @IsTest
    static void testCalculate_NullOppSkipped() {
        Opportunity opp = getBaseOpp();
        EF_Approved_Offers__c ef = makeOffer(opp.Id, 10.0, 36, null);
        // Empty map — opp not found, offer should be skipped
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();

        Test.startTest();
        List<EF_Approved_Offers__c> results = TC_EfOfferRateFactorCalculator.calculate(
            new List<EF_Approved_Offers__c>{ ef }, oppMap);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Offers with missing opp should be skipped');
    }

    @IsTest
    static void testCalculate_PortalFMVSkipped() {
        // Portal + FMV opp should be skipped in calculate() (line 18)
        Opportunity opp = getBaseOpp();
        opp.Purchase_Options__c = 'FMV';
        opp.Portal_User_ID__c = 'DP-123';
        EF_Approved_Offers__c ef = makeOffer(opp.Id, 10.0, 36, null);
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>{ opp.Id => opp };

        Test.startTest();
        List<EF_Approved_Offers__c> results = TC_EfOfferRateFactorCalculator.calculate(
            new List<EF_Approved_Offers__c>{ ef }, oppMap);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Portal FMV offers should be skipped in calculate()');
    }

    @IsTest
    static void testCalculate_AdvancedRentalFirstPayment() {
        // line 28: term-- when Advanced_Rental__c == 'First Payment'
        Opportunity opp = getBaseOpp();
        EF_Approved_Offers__c efAdv = makeOffer(opp.Id, 10.0, 36, 'First Payment');
        EF_Approved_Offers__c efBase = makeOffer(opp.Id, 10.0, 36, null);
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>{ opp.Id => opp };

        Test.startTest();
        List<EF_Approved_Offers__c> advResults = TC_EfOfferRateFactorCalculator.calculate(
            new List<EF_Approved_Offers__c>{ efAdv }, oppMap);
        List<EF_Approved_Offers__c> baseResults = TC_EfOfferRateFactorCalculator.calculate(
            new List<EF_Approved_Offers__c>{ efBase }, oppMap);
        Test.stopTest();

        System.assertEquals(1, advResults.size());
        System.assertNotEquals(baseResults[0].Rate_Factor__c, advResults[0].Rate_Factor__c,
            'First Payment reduces term by 1 so rate factor should differ');
    }

    @IsTest
    static void testCalculate_AdvancedRentalFirstAndLast() {
        // line 30: term -= 2 when Advanced_Rental__c == 'First & Last Payment'
        Opportunity opp = getBaseOpp();
        EF_Approved_Offers__c ef = makeOffer(opp.Id, 10.0, 36, 'First & Last Payment');
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>{ opp.Id => opp };

        Test.startTest();
        List<EF_Approved_Offers__c> results = TC_EfOfferRateFactorCalculator.calculate(
            new List<EF_Approved_Offers__c>{ ef }, oppMap);
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertNotEquals(0, results[0].Rate_Factor__c);
    }

    @IsTest
    static void testCalculate_PortalAdvancePayment() {
        // lines 38-41: portal + Required_Adv_Payments__c == 1 uses alternate formula
        Opportunity opp = getBaseOpp();
        opp.Portal_User_ID__c = 'DP-123';
        opp.Required_Adv_Payments__c = 1;
        opp.Purchase_Options__c = '1.00 Out'; // non-FMV so not skipped

        EF_Approved_Offers__c ef = makeOffer(opp.Id, 10.0, 36, null);
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>{ opp.Id => opp };

        Test.startTest();
        List<EF_Approved_Offers__c> results = TC_EfOfferRateFactorCalculator.calculate(
            new List<EF_Approved_Offers__c>{ ef }, oppMap);
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertNotEquals(0, results[0].Rate_Factor__c,
            'Portal advance payment rate factor should be calculated');
    }

    @IsTest
    static void testCalculate_Deferral30Days() {
        Opportunity opp = getBaseOpp();
        opp.Deferral_Payments__c = '30 days';
        EF_Approved_Offers__c ef = makeOffer(opp.Id, 10.0, 36, null);
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>{ opp.Id => opp };

        Test.startTest();
        List<EF_Approved_Offers__c> results = TC_EfOfferRateFactorCalculator.calculate(
            new List<EF_Approved_Offers__c>{ ef }, oppMap);
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertNotEquals(0, results[0].Rate_Factor__c);
    }

    // ─── calculateFMV() tests ────────────────────────────────────────────────

    @IsTest
    static void testCalculateFMV_NonPortalSkipped() {
        Opportunity opp = getBaseOpp(); // no Portal_User_ID__c
        EF_Approved_Offers__c ef = makeOffer(opp.Id, 10.0, 36, null);
        ef.Residual__c = 20;
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>{ opp.Id => opp };

        Test.startTest();
        List<EF_Approved_Offers__c> results = TC_EfOfferRateFactorCalculator.calculateFMV(
            new List<EF_Approved_Offers__c>{ ef }, oppMap);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Non-portal offers should be skipped in calculateFMV()');
    }

    @IsTest
    static void testCalculateFMV_PortalFMVCalculates() {
        Opportunity opp = getBaseOpp();
        opp.Portal_User_ID__c = 'DP-123';
        opp.Purchase_Options__c = 'FMV';
        EF_Approved_Offers__c ef = makeOffer(opp.Id, 10.0, 36, null);
        ef.Residual__c = 20;
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>{ opp.Id => opp };

        Test.startTest();
        List<EF_Approved_Offers__c> results = TC_EfOfferRateFactorCalculator.calculateFMV(
            new List<EF_Approved_Offers__c>{ ef }, oppMap);
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertNotEquals(0, results[0].Rate_Factor__c);
    }

    @IsTest
    static void testCalculateFMV_AdvancedRentalFirstPayment() {
        Opportunity opp = getBaseOpp();
        opp.Portal_User_ID__c = 'DP-123';
        opp.Purchase_Options__c = 'FMV';

        EF_Approved_Offers__c efAdv = makeOffer(opp.Id, 10.0, 36, 'First Payment');
        efAdv.Residual__c = 20;
        EF_Approved_Offers__c efBase = makeOffer(opp.Id, 10.0, 36, null);
        efBase.Residual__c = 20;
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>{ opp.Id => opp };

        Test.startTest();
        List<EF_Approved_Offers__c> advResults = TC_EfOfferRateFactorCalculator.calculateFMV(
            new List<EF_Approved_Offers__c>{ efAdv }, oppMap);
        List<EF_Approved_Offers__c> baseResults = TC_EfOfferRateFactorCalculator.calculateFMV(
            new List<EF_Approved_Offers__c>{ efBase }, oppMap);
        Test.stopTest();

        System.assertEquals(1, advResults.size());
        System.assertNotEquals(baseResults[0].Rate_Factor__c, advResults[0].Rate_Factor__c,
            'First Payment should produce different FMV rate factor');
    }

    @IsTest
    static void testCalculateFMV_AdvancedRentalFirstAndLast() {
        Opportunity opp = getBaseOpp();
        opp.Portal_User_ID__c = 'DP-123';
        opp.Purchase_Options__c = 'FMV';
        EF_Approved_Offers__c ef = makeOffer(opp.Id, 10.0, 36, 'First & Last Payment');
        ef.Residual__c = 20;
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>{ opp.Id => opp };

        Test.startTest();
        List<EF_Approved_Offers__c> results = TC_EfOfferRateFactorCalculator.calculateFMV(
            new List<EF_Approved_Offers__c>{ ef }, oppMap);
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertNotEquals(0, results[0].Rate_Factor__c);
    }

    @IsTest
    static void testCalculateFMV_AdvancePayment() {
        Opportunity opp = getBaseOpp();
        opp.Portal_User_ID__c = 'DP-123';
        opp.Purchase_Options__c = 'FMV';
        opp.Required_Adv_Payments__c = 1;
        EF_Approved_Offers__c ef = makeOffer(opp.Id, 10.0, 36, null);
        ef.Residual__c = 20;
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>{ opp.Id => opp };

        Test.startTest();
        List<EF_Approved_Offers__c> results = TC_EfOfferRateFactorCalculator.calculateFMV(
            new List<EF_Approved_Offers__c>{ ef }, oppMap);
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertNotEquals(0, results[0].Rate_Factor__c);
    }

    @IsTest
    static void testCalculateFMV_NullYieldSetsZero() {
        Opportunity opp = getBaseOpp();
        opp.Portal_User_ID__c = 'DP-123';
        opp.Purchase_Options__c = 'FMV';
        EF_Approved_Offers__c ef = makeOffer(opp.Id, null, 36, null);
        ef.Residual__c = 20;
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>{ opp.Id => opp };

        Test.startTest();
        List<EF_Approved_Offers__c> results = TC_EfOfferRateFactorCalculator.calculateFMV(
            new List<EF_Approved_Offers__c>{ ef }, oppMap);
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(0, results[0].Rate_Factor__c, 'Null yield should result in rate factor 0');
    }

    @IsTest
    static void testCalculateFMV_NullOppSkipped() {
        Opportunity opp = getBaseOpp();
        opp.Portal_User_ID__c = 'DP-123';
        opp.Purchase_Options__c = 'FMV';
        EF_Approved_Offers__c ef = makeOffer(opp.Id, 10.0, 36, null);
        ef.Residual__c = 20;
        // Empty map — opp not found
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();

        Test.startTest();
        List<EF_Approved_Offers__c> results = TC_EfOfferRateFactorCalculator.calculateFMV(
            new List<EF_Approved_Offers__c>{ ef }, oppMap);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Offers with missing opp should be skipped');
    }
}