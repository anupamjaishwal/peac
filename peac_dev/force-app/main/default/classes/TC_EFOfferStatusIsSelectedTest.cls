@IsTest
public class TC_EFOfferStatusIsSelectedTest {

    private static final Id SYSTEM_RT = Schema.SObjectType.EF_Approved_Offers__c
        .getRecordTypeInfosByName().get('System').getRecordTypeId();
    private static final Id CUSTOM_RT = Schema.SObjectType.EF_Approved_Offers__c
        .getRecordTypeInfosByName().get('Custom').getRecordTypeId();

    @TestSetup
    static void makeData() {
        insert new ORE__c(Bypass__c = true);

        Account acc = new Account(
            Name = 'Test Offer Select Account',
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

        Opportunity opp = new Opportunity(
            Name = 'Test Offer Select Opp',
            AccountId = acc.Id,
            StageName = 'Proposal',
            CloseDate = Date.today().addDays(30),
            Primary_Source__c = 'Customer Inbound - Call',
            Equipment_Description__c = 'Test Equipment',
            Equipment_Cost__c = 25000,
            Terms__c = 36,
            Funded_Amount__c = 25000,
            Payment_Frequency__c = 'Monthly',
            Purchase_Options__c = '1.00 Out',
            Offer_Made_By__c = 'Dealer'
        );
        insert opp;

        EF_Approved_Offers__c systemOffer = new EF_Approved_Offers__c(
            Opportunity__c = opp.Id,
            RecordTypeId = SYSTEM_RT,
            Yield__c = 7.5,
            Term_in_Months__c = 36,
            Rate_Factor__c = 0.030
        );
        insert systemOffer;

        EF_Approved_Offers__c customOffer = new EF_Approved_Offers__c(
            Opportunity__c = opp.Id,
            RecordTypeId = CUSTOM_RT,
            Yield__c = 8.0,
            Term_in_Months__c = 48,
            Rate_Factor__c = 0.032
        );
        insert customOffer;
    }

    @IsTest
    static void testOfferSelectedCopiesEstimatedIRR() {
        EF_Approved_Offers__c offer = [
            SELECT Id, Opportunity__c, Yield__c, Monthly_Payment__c, Term_in_Months__c,
                   Rate_Factor__c, Offer_Selected__c, RecordTypeId, Advanced_Rental__c
            FROM EF_Approved_Offers__c WHERE RecordTypeId = :SYSTEM_RT LIMIT 1
        ];

        EF_Approved_Offers__c oldOffer = offer.clone(true, true, true, true);
        oldOffer.Offer_Selected__c = null;

        offer.Offer_Selected__c = 'Selected';

        Map<Id, EF_Approved_Offers__c> oldMap = new Map<Id, EF_Approved_Offers__c>{ offer.Id => oldOffer };
        Map<Id, EF_Approved_Offers__c> newMap = new Map<Id, EF_Approved_Offers__c>{ offer.Id => offer };

        TC_TriggerContext tc = new TC_TriggerContext(oldMap, newMap, newMap.values(),
            System.TriggerOperation.AFTER_UPDATE, 'EF_Approved_Offers__c');

        Test.startTest();
        new TC_EFOfferStatusIsSelected().doAction(tc);
        Test.stopTest();

        Opportunity opp = [
            SELECT Yield__c, Estimated_IRR__c FROM Opportunity
            WHERE Id = :offer.Opportunity__c
        ];
        System.assertEquals(7.5, opp.Yield__c, 'Yield__c should be copied from offer');
        System.assertEquals(7.5, opp.Estimated_IRR__c, 'Estimated_IRR__c should be copied from offer Yield');
    }

    @IsTest
    static void testOfferExceptionApprovedCopiesEstimatedIRR() {
        EF_Approved_Offers__c offer = [
            SELECT Id, Opportunity__c, Yield__c, Monthly_Payment__c, Term_in_Months__c,
                   Rate_Factor__c, Offer_Selected__c, RecordTypeId, Advanced_Rental__c
            FROM EF_Approved_Offers__c WHERE RecordTypeId = :SYSTEM_RT LIMIT 1
        ];

        EF_Approved_Offers__c oldOffer = offer.clone(true, true, true, true);
        oldOffer.Offer_Selected__c = null;

        offer.Offer_Selected__c = 'Exception Approved';

        Map<Id, EF_Approved_Offers__c> oldMap = new Map<Id, EF_Approved_Offers__c>{ offer.Id => oldOffer };
        Map<Id, EF_Approved_Offers__c> newMap = new Map<Id, EF_Approved_Offers__c>{ offer.Id => offer };

        TC_TriggerContext tc = new TC_TriggerContext(oldMap, newMap, newMap.values(),
            System.TriggerOperation.AFTER_UPDATE, 'EF_Approved_Offers__c');

        Test.startTest();
        new TC_EFOfferStatusIsSelected().doAction(tc);
        Test.stopTest();

        Opportunity opp = [
            SELECT Yield__c, Estimated_IRR__c FROM Opportunity
            WHERE Id = :offer.Opportunity__c
        ];
        System.assertEquals(7.5, opp.Estimated_IRR__c,
            'Estimated_IRR__c should be set on Exception Approved');
    }

    @IsTest
    static void testOfferNotSelectedDoesNotCopy() {
        EF_Approved_Offers__c offer = [
            SELECT Id, Opportunity__c, Yield__c, Monthly_Payment__c, Term_in_Months__c,
                   Rate_Factor__c, Offer_Selected__c, RecordTypeId, Advanced_Rental__c
            FROM EF_Approved_Offers__c WHERE RecordTypeId = :SYSTEM_RT LIMIT 1
        ];

        EF_Approved_Offers__c oldOffer = offer.clone(true, true, true, true);
        oldOffer.Offer_Selected__c = null;

        offer.Offer_Selected__c = 'Not Selected';

        Map<Id, EF_Approved_Offers__c> oldMap = new Map<Id, EF_Approved_Offers__c>{ offer.Id => oldOffer };
        Map<Id, EF_Approved_Offers__c> newMap = new Map<Id, EF_Approved_Offers__c>{ offer.Id => offer };

        TC_TriggerContext tc = new TC_TriggerContext(oldMap, newMap, newMap.values(),
            System.TriggerOperation.AFTER_UPDATE, 'EF_Approved_Offers__c');

        Test.startTest();
        new TC_EFOfferStatusIsSelected().doAction(tc);
        Test.stopTest();

        Opportunity opp = [
            SELECT Estimated_IRR__c FROM Opportunity WHERE Id = :offer.Opportunity__c
        ];
        System.assertEquals(null, opp.Estimated_IRR__c,
            'Estimated_IRR__c should remain unchanged for Not Selected');
    }

    @IsTest
    static void testOfferSelectedCopiesAllFields() {
        EF_Approved_Offers__c offer = [
            SELECT Id, Opportunity__c, Yield__c, Monthly_Payment__c, Term_in_Months__c,
                   Rate_Factor__c, Offer_Selected__c, RecordTypeId, Advanced_Rental__c
            FROM EF_Approved_Offers__c WHERE RecordTypeId = :SYSTEM_RT LIMIT 1
        ];

        EF_Approved_Offers__c oldOffer = offer.clone(true, true, true, true);
        oldOffer.Offer_Selected__c = null;

        offer.Offer_Selected__c = 'Selected';

        Map<Id, EF_Approved_Offers__c> oldMap = new Map<Id, EF_Approved_Offers__c>{ offer.Id => oldOffer };
        Map<Id, EF_Approved_Offers__c> newMap = new Map<Id, EF_Approved_Offers__c>{ offer.Id => offer };

        TC_TriggerContext tc = new TC_TriggerContext(oldMap, newMap, newMap.values(),
            System.TriggerOperation.AFTER_UPDATE, 'EF_Approved_Offers__c');

        Test.startTest();
        new TC_EFOfferStatusIsSelected().doAction(tc);
        Test.stopTest();

        Opportunity opp = [
            SELECT Payment_Amount__c, Terms__c, X_Rate_Factor__c, Yield__c,
                   Estimated_IRR__c, of_Payments__c, EF_Approved_Offers__c
            FROM Opportunity WHERE Id = :offer.Opportunity__c
        ];
        System.assertEquals(offer.Monthly_Payment__c, opp.Payment_Amount__c);
        System.assertEquals(36, opp.Terms__c);
        System.assertEquals(7.5, opp.Yield__c);
        System.assertEquals(7.5, opp.Estimated_IRR__c);
        System.assertEquals(36, opp.of_Payments__c);
        System.assertEquals(offer.Id, opp.EF_Approved_Offers__c);
    }

    @IsTest
    static void testCustomOfferSelectedCopiesPoints() {
        // Points__c on EF_Approved_Offers__c is a formula (Opportunity__r.Points__c),
        // so set it on the Opportunity first so the offer reflects 2.0
        Opportunity oppForPoints = [SELECT Id FROM Opportunity LIMIT 1];
        oppForPoints.Points__c = 2.0;
        update oppForPoints;

        EF_Approved_Offers__c offer = [
            SELECT Id, Opportunity__c, Yield__c, Monthly_Payment__c, Term_in_Months__c,
                   Rate_Factor__c, Offer_Selected__c, RecordTypeId, Points__c, Advanced_Rental__c
            FROM EF_Approved_Offers__c WHERE RecordTypeId = :CUSTOM_RT LIMIT 1
        ];

        EF_Approved_Offers__c oldOffer = offer.clone(true, true, true, true);
        oldOffer.Offer_Selected__c = null;

        offer.Offer_Selected__c = 'Selected';

        Map<Id, EF_Approved_Offers__c> oldMap = new Map<Id, EF_Approved_Offers__c>{ offer.Id => oldOffer };
        Map<Id, EF_Approved_Offers__c> newMap = new Map<Id, EF_Approved_Offers__c>{ offer.Id => offer };

        TC_TriggerContext tc = new TC_TriggerContext(oldMap, newMap, newMap.values(),
            System.TriggerOperation.AFTER_UPDATE, 'EF_Approved_Offers__c');

        Test.startTest();
        new TC_EFOfferStatusIsSelected().doAction(tc);
        Test.stopTest();

        Opportunity opp = [
            SELECT Points__c, Estimated_IRR__c FROM Opportunity
            WHERE Id = :offer.Opportunity__c
        ];
        System.assertEquals(2.0, opp.Points__c, 'Points should be copied from Custom offer');
        System.assertEquals(8.0, opp.Estimated_IRR__c,
            'Estimated_IRR__c should be set from Custom offer Yield');
    }

    @IsTest
    static void testAdvancedRentalFirstPaymentSetsRequiredAdv1() {
        EF_Approved_Offers__c offer = [
            SELECT Id, Opportunity__c, Yield__c, Monthly_Payment__c, Term_in_Months__c,
                   Rate_Factor__c, Offer_Selected__c, RecordTypeId, Advanced_Rental__c
            FROM EF_Approved_Offers__c WHERE RecordTypeId = :SYSTEM_RT LIMIT 1
        ];

        EF_Approved_Offers__c oldOffer = offer.clone(true, true, true, true);
        oldOffer.Offer_Selected__c = null;

        offer.Offer_Selected__c = 'Selected';
        offer.Advanced_Rental__c = 'First Payment';

        Map<Id, EF_Approved_Offers__c> oldMap = new Map<Id, EF_Approved_Offers__c>{ offer.Id => oldOffer };
        Map<Id, EF_Approved_Offers__c> newMap = new Map<Id, EF_Approved_Offers__c>{ offer.Id => offer };

        TC_TriggerContext tc = new TC_TriggerContext(oldMap, newMap, newMap.values(),
            System.TriggerOperation.AFTER_UPDATE, 'EF_Approved_Offers__c');

        Test.startTest();
        new TC_EFOfferStatusIsSelected().doAction(tc);
        Test.stopTest();

        Opportunity opp = [SELECT Required_Adv_Payments__c FROM Opportunity WHERE Id = :offer.Opportunity__c];
        System.assertEquals(1, opp.Required_Adv_Payments__c,
            'First Payment should set Required_Adv_Payments__c = 1');
    }

    @IsTest
    static void testAdvancedRentalFirstAndLastPaymentSetsRequiredAdv2() {
        EF_Approved_Offers__c offer = [
            SELECT Id, Opportunity__c, Yield__c, Monthly_Payment__c, Term_in_Months__c,
                   Rate_Factor__c, Offer_Selected__c, RecordTypeId, Advanced_Rental__c
            FROM EF_Approved_Offers__c WHERE RecordTypeId = :SYSTEM_RT LIMIT 1
        ];

        EF_Approved_Offers__c oldOffer = offer.clone(true, true, true, true);
        oldOffer.Offer_Selected__c = null;

        offer.Offer_Selected__c = 'Selected';
        offer.Advanced_Rental__c = 'First & Last Payment';

        Map<Id, EF_Approved_Offers__c> oldMap = new Map<Id, EF_Approved_Offers__c>{ offer.Id => oldOffer };
        Map<Id, EF_Approved_Offers__c> newMap = new Map<Id, EF_Approved_Offers__c>{ offer.Id => offer };

        TC_TriggerContext tc = new TC_TriggerContext(oldMap, newMap, newMap.values(),
            System.TriggerOperation.AFTER_UPDATE, 'EF_Approved_Offers__c');

        Test.startTest();
        new TC_EFOfferStatusIsSelected().doAction(tc);
        Test.stopTest();

        Opportunity opp = [SELECT Required_Adv_Payments__c FROM Opportunity WHERE Id = :offer.Opportunity__c];
        System.assertEquals(2, opp.Required_Adv_Payments__c,
            'First & Last Payment should set Required_Adv_Payments__c = 2');
    }

    @IsTest
    static void testDeselectsPreviouslySelectedOffers() {
        List<EF_Approved_Offers__c> offers = [
            SELECT Id, Opportunity__c, Yield__c, Monthly_Payment__c, Term_in_Months__c,
                   Rate_Factor__c, Offer_Selected__c, RecordTypeId, Advanced_Rental__c
            FROM EF_Approved_Offers__c ORDER BY RecordTypeId
        ];
        EF_Approved_Offers__c offerA = offers[0];
        EF_Approved_Offers__c offerB = offers[1];

        offerA.Offer_Selected__c = 'Selected';
        update offerA;

        EF_Approved_Offers__c oldOfferB = offerB.clone(true, true, true, true);
        oldOfferB.Offer_Selected__c = null;
        offerB.Offer_Selected__c = 'Selected';

        Map<Id, EF_Approved_Offers__c> oldMap = new Map<Id, EF_Approved_Offers__c>{ offerB.Id => oldOfferB };
        Map<Id, EF_Approved_Offers__c> newMap = new Map<Id, EF_Approved_Offers__c>{ offerB.Id => offerB };

        TC_TriggerContext tc = new TC_TriggerContext(oldMap, newMap, newMap.values(),
            System.TriggerOperation.AFTER_UPDATE, 'EF_Approved_Offers__c');

        Test.startTest();
        new TC_EFOfferStatusIsSelected().doAction(tc);
        Test.stopTest();

        EF_Approved_Offers__c updatedA = [
            SELECT Offer_Selected__c FROM EF_Approved_Offers__c WHERE Id = :offerA.Id
        ];
        System.assertEquals('Not Selected', updatedA.Offer_Selected__c,
            'Previously selected offer should be deselected');
    }
}