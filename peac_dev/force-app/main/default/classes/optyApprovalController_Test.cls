@IsTest
private class optyApprovalController_Test {

    private static Opportunity createOpportunity() {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
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
            Opportunity__c = opportunityId,
            Offer_Amount__c = amount,
            Select_for_approval__c = selectForApproval,
            Term__c = term,
            Approved_Frequency__c = frequency
        );
        insert ao;
        return ao;
    }

    @IsTest
    static void returnsNullWhenIdIsNull() {
        Test.startTest();
        Approved_Offer__c result = optyApprovalController.getTopApprovedOffer(null);
        Test.stopTest();
        System.assertEquals(null, result);
    }

    @IsTest
    static void returnsHighestApprovedOfferByAmount() {
        Opportunity opp = createOpportunity();

        Approved_Offer__c offer1 = makeApprovedOffer(opp.Id, 10000.0, true, 12.0, 'Daily');
        Approved_Offer__c offer2 = makeApprovedOffer(opp.Id, 25000.0, true, 24.0, 'Daily'); // highest
        Approved_Offer__c offer3 = makeApprovedOffer(opp.Id, 15000.0, true, 18.0, 'Daily');

        Test.startTest();
        Approved_Offer__c result = optyApprovalController.getTopApprovedOffer(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(offer2.Id, result.Id);
        System.assertEquals(25000, result.Offer_Amount__c);
        System.assertEquals(true, result.Select_for_approval__c);
        System.assertEquals(24.0, result.Term__c);
        System.assertEquals('Daily', result.Approved_Frequency__c);
    }

}