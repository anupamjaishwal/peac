/**
 * @description Service class for creating EF_Approved_Offers__c records from
 *              Pricing Orchestrator results (Pricing_Result__c).
 *              Bridges the orchestrator output with the EF offer system so that
 *              yield, rate factor, and residual flow through automatically.
 * @author Northteq
 */
public without sharing class NT_EFApprovedOfferService {

    private static final Id SYSTEM_RT = Schema.SObjectType.EF_Approved_Offers__c
        .getRecordTypeInfosByName().get('System').getRecordTypeId();

    private static final String FMV_VALUE = 'FMV';

    /**
     * @description Creates EF_Approved_Offers__c records from Pricing_Result__c records.
     *              Deletes existing System-type EF offers for the Opportunity first,
     *              then creates one EF offer per pricing result.
     * @param opportunityId The Opportunity to create offers for
     * @param pricingResults The pricing results from the orchestrator
     * @param tvQuote The TValue Quote with term and purchase option
     * @return List<EF_Approved_Offers__c> The created EF offers
     */
    /*
        Scenario 3: Pricing Orchestrator results create EF_Approved_Offers__c records
        Given the Pricing Orchestrator has completed successfully for a Quote (Pricing_Result__c and tval__TValue_Quote__c records exist)
        And the user selects a TValue Quote and an Opportunity is created
        When EF_Approved_Offers__c records are created for the Opportunity
        Then each EF offer is populated with:
        Yield__c = PEAC yield from the pricing run (Pricing_Result__c.Total_Rate__c)
        Term_in_Months__c = term from the TValue Quote
        Rate_Factor__c = rate factor from the pricing run
        RecordType = 'System'
        Residual__c = residual from Pricing_Result__c (if FMV)
        And one EF_Approved_Offers__c record is created per pricing combination
    */
    public static List<EF_Approved_Offers__c> createOffersFromPricingResults(
        Id opportunityId,
        List<Pricing_Result__c> pricingResults,
        tval__TValue_Quote__c tvQuote
    ) {
        if (opportunityId == null || pricingResults == null || pricingResults.isEmpty() || tvQuote == null) {
            return new List<EF_Approved_Offers__c>();
        }

        List<EF_Approved_Offers__c> offers = buildOffersFromPricingResults(
            opportunityId, pricingResults, tvQuote
        );
        replaceSystemOffers(new Set<Id>{ opportunityId }, offers);
        return offers;
    }

    /**
     * @description Builds EF_Approved_Offers__c records in memory without DML.
     *              Use with replaceSystemOffers for bulk-safe trigger contexts.
     */
    public static List<EF_Approved_Offers__c> buildOffersFromPricingResults(
        Id opportunityId,
        List<Pricing_Result__c> pricingResults,
        tval__TValue_Quote__c tvQuote
    ) {
        List<EF_Approved_Offers__c> offers = new List<EF_Approved_Offers__c>();
        if (opportunityId == null || pricingResults == null || pricingResults.isEmpty() || tvQuote == null) {
            return offers;
        }

        String purchaseOption = tvQuote.tval__Purchase_Option__c;
        Boolean isFmv = purchaseOption != null && purchaseOption.containsIgnoreCase(FMV_VALUE);

        for (Pricing_Result__c pr : pricingResults) {
            EF_Approved_Offers__c offer = new EF_Approved_Offers__c();
            offer.Opportunity__c = opportunityId;
            offer.RecordTypeId = SYSTEM_RT;
            offer.Yield__c = pr.Total_Rate__c;
            offer.Rate_Factor__c = pr.Total_Rate_Factor__c;
            offer.Term_in_Months__c = tvQuote.tval__Term__c;
            offer.Residual__c = isFmv ? pr.Total_Residual__c : null;
            offers.add(offer);
        }
        return offers;
    }

    /**
     * @description Bulk-safe: deletes existing System-type EF offers for the given
     *              Opportunity IDs, then inserts the new offers in a single DML call.
     */
    public static void replaceSystemOffers(Set<Id> opportunityIds, List<EF_Approved_Offers__c> newOffers) {
        try {
            delete [
                SELECT Id FROM EF_Approved_Offers__c
                WHERE Opportunity__c IN :opportunityIds
                  AND RecordTypeId = :SYSTEM_RT
            ];
        } catch (DmlException e) {
            System.debug('Failed to delete existing System EF offers: ' + e.getMessage());
        }

        if (newOffers != null && !newOffers.isEmpty()) {
            insert newOffers;
        }
    }
}