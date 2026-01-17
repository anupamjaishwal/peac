/**************************************************************************************************************
@Author:D Balakrishna(LTIMindtree)
@Description:This test class validate the business logic of OptyApprovalController Class
@User Story:SAL-5999
@Created Date:November-25-2025
**************************************************************************************************************/
@isTest
private class PEAC_OptyApprovalFSControllerTest {
    private static Opportunity createOpportunity(String name) {
        Opportunity opp = new Opportunity(
            Name = name,
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(30)
        );
        insert opp;
        return opp;
    }

    private static Approved_Offer__c makeApprovedOffer(
        Id opportunityId,
        Decimal amount,
        Boolean selectForApproval,
        Decimal term,
        String frequency
    ) {
        Approved_Offer__c ao = new Approved_Offer__c(
            Opportunity__c         = opportunityId,
            Offer_Amount__c        = amount,
            Select_for_approval__c = selectForApproval,
            Term__c                = term,
            Approved_Frequency__c  = frequency
        );
        insert ao;
        return ao;
    }

    @IsTest
    static void returnsNullWhenIdIsNull() {
        Test.startTest();
        Approved_Offer__c result = PEAC_OptyApprovalFSController.getTopApprovedOffer(null);
        Test.stopTest();
        System.assertEquals(null, result, 'Should return null when Opportunity Id is null');
    }

    @IsTest
    static void returnsHighestApprovedOfferByAmount() {
        Opportunity opp = createOpportunity('Opp A');

        Approved_Offer__c offer1 = makeApprovedOffer(opp.Id, 10000.0, true, 12.0, 'Daily');
        Approved_Offer__c offer2 = makeApprovedOffer(opp.Id, 25000.0, true, 24.0, 'Daily'); // highest
        Approved_Offer__c offer3 = makeApprovedOffer(opp.Id, 15000.0, true, 18.0, 'Daily');

        Test.startTest();
        Approved_Offer__c result = PEAC_OptyApprovalFSController.getTopApprovedOffer(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Top offer should not be null');
        System.assertEquals(offer2.Id, result.Id, 'Highest approved offer should be returned');
        System.assertEquals(25000.0, result.Offer_Amount__c, 'Offer amount should be 25,000');
        System.assertEquals(true, result.Select_for_approval__c);
        System.assertEquals(24.0, result.Term__c);
        System.assertEquals('Daily', result.Approved_Frequency__c);
    }
    

    @IsTest
    static void ignoresOffersFromOtherOpportunity() {
        Opportunity opp1 = createOpportunity('Opp C1');
        Opportunity opp2 = createOpportunity('Opp C2');

        // An offer on a different opportunity that would otherwise be highest
        makeApprovedOffer(opp2.Id, 99999.0, true, 36.0, 'Daily');

        // A valid offer on the target opportunity
        Approved_Offer__c expected = makeApprovedOffer(opp1.Id, 12345.0, true, 12.0, 'Daily');

        Test.startTest();
        Approved_Offer__c result = PEAC_OptyApprovalFSController.getTopApprovedOffer(opp1.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should find an approved offer on the given opportunity');
        System.assertEquals(expected.Id, result.Id, 'Offers from other opportunities must be ignored');
        System.assertEquals(12345.0, result.Offer_Amount__c);
    }

    @IsTest
    static void returnsNullWhenOnlyZeroAmountSelected() {
        Opportunity opp = createOpportunity('Opp D');

        // Selected but amount is 0 -> filter excludes
        makeApprovedOffer(opp.Id, 0.0, true, 10.0, 'Daily');

        Test.startTest();
        Approved_Offer__c result = PEAC_OptyApprovalFSController.getTopApprovedOffer(opp.Id);
        Test.stopTest();

        System.assertEquals(null, result, 'Selected with zero amount should not be considered');
    }

    @IsTest
    static void constructorCoverage() {
        // Call the public constructor to cover it (even though it’s empty)
        PEAC_OptyApprovalFSController controller = new PEAC_OptyApprovalFSController();
        System.assertNotEquals(null, controller, 'Controller instance should be created');
    }

    @IsTest
    static void returnsTopWhenMultipleValid() {
        Opportunity opp = createOpportunity('Opp E');

        // All pass filters; verify ordering by amount DESC LIMIT 1
        makeApprovedOffer(opp.Id, 1.0, true, 1.0, 'Daily');
        makeApprovedOffer(opp.Id, 500.0, true, 6.0, 'Daily');
        Approved_Offer__c top = makeApprovedOffer(opp.Id, 1000.0, true, 12.0, 'Daily');

        Test.startTest();
        Approved_Offer__c result = PEAC_OptyApprovalFSController.getTopApprovedOffer(opp.Id);
        Test.stopTest();

        System.assertEquals(top.Id, result.Id, 'Should return the row with highest Offer_Amount__c');
        System.assertEquals(1000.0, result.Offer_Amount__c);
    }
}