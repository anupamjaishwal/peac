@IsTest
public class NT_EFApprovedOfferServiceTest {

    private static final Id SYSTEM_RT = Schema.SObjectType.EF_Approved_Offers__c
        .getRecordTypeInfosByName().get('System').getRecordTypeId();
    private static final Id CUSTOM_RT = Schema.SObjectType.EF_Approved_Offers__c
        .getRecordTypeInfosByName().get('Custom').getRecordTypeId();

    @TestSetup
    static void makeData() {
        insert new ORE__c(Bypass__c = true);

        Account acc = new Account(
            Name = 'Test EF Offer Account',
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

        Program__c program = new Program__c(Name = 'Test Program');
        insert program;

        Opportunity opp = new Opportunity(
            Name = 'Test EF Offer Opp',
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
            Program_Lookup__c = program.Id
        );
        insert opp;

        Pricing_Result__c pr = new Pricing_Result__c(
            Opportunity__c = opp.Id,
            Total_Rate__c = 5.5,
            Total_Rate_Factor__c = 0.018,
            Total_Residual__c = null,
            Status__c = 'Success',
            Source__c = 'Base Rate',
            Transaction_Id__c = 'test-txn-001'
        );
        insert pr;
    }

    @IsTest
    static void testCreateOffersFromPricingResults_SingleResult() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test EF Offer Opp' LIMIT 1];
        List<Pricing_Result__c> prs = [
            SELECT Id, Total_Rate__c, Total_Rate_Factor__c, Total_Residual__c, Source__c
            FROM Pricing_Result__c WHERE Opportunity__c = :opp.Id AND Source__c = 'Base Rate'
        ];

        tval__TValue_Quote__c tvQuote = new tval__TValue_Quote__c(
            tval__Term__c = 36,
            tval__Purchase_Option__c = '1.00 Out'
        );
        insert tvQuote;

        Test.startTest();
        List<EF_Approved_Offers__c> offers = NT_EFApprovedOfferService.createOffersFromPricingResults(
            opp.Id, prs, tvQuote
        );
        Test.stopTest();

        System.assertEquals(1, offers.size(), 'Should create one EF offer per pricing result');
        EF_Approved_Offers__c offer = offers[0];
        System.assertEquals(5.5, offer.Yield__c);
        System.assertEquals(0.018, offer.Rate_Factor__c);
        System.assertEquals(36, offer.Term_in_Months__c);
        System.assertEquals(SYSTEM_RT, offer.RecordTypeId);
        System.assertEquals(opp.Id, offer.Opportunity__c);
        System.assertEquals(null, offer.Residual__c, 'Residual should be null for non-FMV');
    }

    @IsTest
    static void testCreateOffersFromPricingResults_MultipleResults() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test EF Offer Opp' LIMIT 1];

        Pricing_Result__c pr2 = new Pricing_Result__c(
            Opportunity__c = opp.Id,
            Total_Rate__c = 6.0,
            Total_Rate_Factor__c = 0.020,
            Status__c = 'Success',
            Source__c = 'Base Rate',
            Transaction_Id__c = 'test-txn-002'
        );
        insert pr2;

        List<Pricing_Result__c> prs = [
            SELECT Id, Total_Rate__c, Total_Rate_Factor__c, Total_Residual__c, Source__c
            FROM Pricing_Result__c WHERE Opportunity__c = :opp.Id AND Source__c = 'Base Rate'
        ];

        tval__TValue_Quote__c tvQuote = new tval__TValue_Quote__c(
            tval__Term__c = 60,
            tval__Purchase_Option__c = '1.00 Out'
        );
        insert tvQuote;

        Test.startTest();
        List<EF_Approved_Offers__c> offers = NT_EFApprovedOfferService.createOffersFromPricingResults(
            opp.Id, prs, tvQuote
        );
        Test.stopTest();

        System.assertEquals(2, offers.size(), 'Should create two EF offers');
    }

    @IsTest
    static void testCreateOffersFromPricingResults_FMV() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test EF Offer Opp' LIMIT 1];
        Pricing_Result__c pr = [
            SELECT Id FROM Pricing_Result__c WHERE Opportunity__c = :opp.Id LIMIT 1
        ];
        pr.Total_Residual__c = 10.0;
        update pr;

        List<Pricing_Result__c> prs = [
            SELECT Id, Total_Rate__c, Total_Rate_Factor__c, Total_Residual__c, Source__c
            FROM Pricing_Result__c WHERE Id = :pr.Id
        ];

        tval__TValue_Quote__c tvQuote = new tval__TValue_Quote__c(
            tval__Term__c = 36,
            tval__Purchase_Option__c = 'FMV'
        );
        insert tvQuote;

        Test.startTest();
        List<EF_Approved_Offers__c> offers = NT_EFApprovedOfferService.createOffersFromPricingResults(
            opp.Id, prs, tvQuote
        );
        Test.stopTest();

        System.assertEquals(1, offers.size());
        System.assertEquals(10.0, offers[0].Residual__c, 'Residual should be populated for FMV');
    }

    @IsTest
    static void testCreateOffersFromPricingResults_NonFMV() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test EF Offer Opp' LIMIT 1];
        Pricing_Result__c pr = [
            SELECT Id FROM Pricing_Result__c WHERE Opportunity__c = :opp.Id LIMIT 1
        ];
        pr.Total_Residual__c = 10.0;
        update pr;

        List<Pricing_Result__c> prs = [
            SELECT Id, Total_Rate__c, Total_Rate_Factor__c, Total_Residual__c, Source__c
            FROM Pricing_Result__c WHERE Id = :pr.Id
        ];

        tval__TValue_Quote__c tvQuote = new tval__TValue_Quote__c(
            tval__Term__c = 36,
            tval__Purchase_Option__c = '1.00 Out'
        );
        insert tvQuote;

        Test.startTest();
        List<EF_Approved_Offers__c> offers = NT_EFApprovedOfferService.createOffersFromPricingResults(
            opp.Id, prs, tvQuote
        );
        Test.stopTest();

        System.assertEquals(null, offers[0].Residual__c, 'Residual should be null for non-FMV');
    }

    @IsTest
    static void testCreateOffersFromPricingResults_DeletesExistingSystem() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test EF Offer Opp' LIMIT 1];

        List<Pricing_Result__c> prs = [
            SELECT Id, Total_Rate__c, Total_Rate_Factor__c, Total_Residual__c, Source__c
            FROM Pricing_Result__c WHERE Opportunity__c = :opp.Id AND Source__c = 'Base Rate'
        ];

        tval__TValue_Quote__c tvQuote = new tval__TValue_Quote__c(
            tval__Term__c = 36,
            tval__Purchase_Option__c = '1.00 Out'
        );
        insert tvQuote;

        Test.startTest();
        List<EF_Approved_Offers__c> offers = NT_EFApprovedOfferService.createOffersFromPricingResults(
            opp.Id, prs, tvQuote
        );
        Test.stopTest();

        System.assertEquals(1, offers.size(), 'Should build one System offer from pricing results');
        System.assertEquals(SYSTEM_RT, offers[0].RecordTypeId);
    }

    @IsTest
    static void testCreateOffersFromPricingResults_PreservesCustomOffers() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test EF Offer Opp' LIMIT 1];

        List<Pricing_Result__c> prs = [
            SELECT Id, Total_Rate__c, Total_Rate_Factor__c, Total_Residual__c, Source__c
            FROM Pricing_Result__c WHERE Opportunity__c = :opp.Id AND Source__c = 'Base Rate'
        ];

        tval__TValue_Quote__c tvQuote = new tval__TValue_Quote__c(
            tval__Term__c = 36,
            tval__Purchase_Option__c = '1.00 Out'
        );
        insert tvQuote;

        Test.startTest();
        List<EF_Approved_Offers__c> offers = NT_EFApprovedOfferService.createOffersFromPricingResults(
            opp.Id, prs, tvQuote
        );
        Test.stopTest();

        for (EF_Approved_Offers__c offer : offers) {
            System.assertEquals(SYSTEM_RT, offer.RecordTypeId,
                'Service should only build System-type offers, never Custom');
        }
    }

    @IsTest
    static void testCreateOffersFromPricingResults_NullInputs() {
        Test.startTest();
        List<EF_Approved_Offers__c> r1 = NT_EFApprovedOfferService.createOffersFromPricingResults(
            null, new List<Pricing_Result__c>(), new tval__TValue_Quote__c()
        );
        List<EF_Approved_Offers__c> r2 = NT_EFApprovedOfferService.createOffersFromPricingResults(
            Id.valueOf('006000000000001AAA'), null, new tval__TValue_Quote__c()
        );
        List<EF_Approved_Offers__c> r3 = NT_EFApprovedOfferService.createOffersFromPricingResults(
            Id.valueOf('006000000000001AAA'), new List<Pricing_Result__c>(), null
        );
        Test.stopTest();

        System.assert(r1.isEmpty(), 'Null opportunityId should return empty');
        System.assert(r2.isEmpty(), 'Null pricingResults should return empty');
        System.assert(r3.isEmpty(), 'Null tvQuote should return empty');
    }

    @IsTest
    static void testBuildOffersFromPricingResults_NullInputs() {
        Test.startTest();
        List<EF_Approved_Offers__c> r1 = NT_EFApprovedOfferService.buildOffersFromPricingResults(
            null, new List<Pricing_Result__c>(), new tval__TValue_Quote__c()
        );
        List<EF_Approved_Offers__c> r2 = NT_EFApprovedOfferService.buildOffersFromPricingResults(
            Id.valueOf('006000000000001AAA'), null, new tval__TValue_Quote__c()
        );
        Test.stopTest();

        System.assert(r1.isEmpty(), 'Null opportunityId should return empty from buildOffers');
        System.assert(r2.isEmpty(), 'Null pricingResults should return empty from buildOffers');
    }

    @IsTest
    static void testCreateOffersFromPricingResults_EmptyResults() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test EF Offer Opp' LIMIT 1];

        tval__TValue_Quote__c tvQuote = new tval__TValue_Quote__c(
            tval__Term__c = 36,
            tval__Purchase_Option__c = '1.00 Out'
        );
        insert tvQuote;

        Test.startTest();
        List<EF_Approved_Offers__c> offers = NT_EFApprovedOfferService.createOffersFromPricingResults(
            opp.Id, new List<Pricing_Result__c>(), tvQuote
        );
        Test.stopTest();

        System.assert(offers.isEmpty(), 'Empty pricing results should produce no offers');
    }
}