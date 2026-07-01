/**
 * @description Trigger handler for Quote. When OpportunityId is set or changed,
 *              the back-stamp work (tval__Opportunity__c on related TValue Quotes,
 *              Opportunity__c on related Pricing_Result__c rows, and
 *              EF_Approved_Offers__c creation) is decoupled from the originating
 *              transaction by publishing an NT_Quote_Backstamp__e platform event
 *              per Quote. The event subscriber (NT_QuoteBackstampEventTrigger)
 *              runs as the Automated Process user, which has access to the
 *              Opportunity even when the Quote was updated by a portal/community
 *              user. This avoids INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY,
 *              which the synchronous path hit when the tval managed-package
 *              trigger cascaded a Quote update referencing an Opportunity the
 *              portal user could not access (SAL-7168).
 * @author Northteq
 */
public without sharing class NT_QuoteTriggerHandler {

    public void afterInsert(Map<Id, SObject> newMap) {
        Map<Id, Id> quoteToOppId = new Map<Id, Id>();
        for (Id quoteId : newMap.keySet()) {
            Quote q = (Quote) newMap.get(quoteId);
            if (q.OpportunityId != null) {
                quoteToOppId.put(quoteId, q.OpportunityId);
            }
        }
        publishBackstampEvents(quoteToOppId);
    }

    public void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
        Map<Id, Id> quoteToOppId = new Map<Id, Id>();
        for (Id quoteId : newMap.keySet()) {
            Quote newQ = (Quote) newMap.get(quoteId);
            Quote oldQ = (Quote) oldMap.get(quoteId);
            if (newQ.OpportunityId != null && newQ.OpportunityId != oldQ.OpportunityId) {
                quoteToOppId.put(quoteId, newQ.OpportunityId);
            }
        }
        publishBackstampEvents(quoteToOppId);
    }

    /**
     * @description Publishes one NT_Quote_Backstamp__e per Quote->Opportunity pair
     *              so the back-stamp + EF offer work runs asynchronously as the
     *              Automated Process user. PublishAfterCommit on the event ensures
     *              the source Quote.OpportunityId change is committed before the
     *              subscriber runs, so its queries see the linked Opportunity.
     * @param quoteToOppId Map of Quote Id to its OpportunityId.
     */
    private void publishBackstampEvents(Map<Id, Id> quoteToOppId) {
        if (quoteToOppId == null || quoteToOppId.isEmpty()) {
            return;
        }
        List<NT_Quote_Backstamp__e> events = new List<NT_Quote_Backstamp__e>();
        for (Id quoteId : quoteToOppId.keySet()) {
            events.add(new NT_Quote_Backstamp__e(
                Quote_Id__c = quoteId,
                Opportunity_Id__c = quoteToOppId.get(quoteId)
            ));
        }
        List<Database.SaveResult> results = EventBus.publish(events);
        for (Database.SaveResult sr : results) {
            if (!sr.isSuccess()) {
                for (Database.Error e : sr.getErrors()) {
                    System.debug('SAL-7168 NT_Quote_Backstamp__e publish failed: '
                        + e.getStatusCode() + ' | ' + e.getMessage());
                }
            }
        }
    }

    /**
     * @description Subscriber entry point for NT_Quote_Backstamp__e. Rebuilds the
     *              Quote->Opportunity map from the events and runs the back-stamp
     *              + EF offer creation. Runs in the Automated Process context, so
     *              it has the Opportunity access the portal user lacked.
     * @param events The NT_Quote_Backstamp__e records from Trigger.new.
     */
    public static void handleBackstampEvents(List<NT_Quote_Backstamp__e> events) {
        if (events == null || events.isEmpty()) {
            return;
        }
        Map<Id, Id> quoteToOppId = new Map<Id, Id>();
        for (NT_Quote_Backstamp__e evt : events) {
            if (String.isBlank(evt.Quote_Id__c) || String.isBlank(evt.Opportunity_Id__c)) {
                continue;
            }
            quoteToOppId.put((Id) evt.Quote_Id__c, (Id) evt.Opportunity_Id__c);
        }
        if (!quoteToOppId.isEmpty()) {
            new NT_QuoteTriggerHandler().createEFOffers(quoteToOppId);
        }
    }

    /**
     * @description Queries pricing data linked to each Quote, back-stamps the
     *              Opportunity onto the related TValue Quotes and Pricing
     *              Result rows, and creates EF_Approved_Offers__c via
     *              NT_EFApprovedOfferService.
     * @param quoteToOppId Map of Quote Id to its OpportunityId
     */
    private void createEFOffers(Map<Id, Id> quoteToOppId) {
        Set<Id> quoteIds = quoteToOppId.keySet();

        // Scope pricing results to the latest orchestrator run per quote.
        // Results are ordered newest-first, so the first row per Quote__c
        // reveals that quote's latest Transaction_Id__c; subsequent rows
        // with a different transaction are from older runs and are skipped.
        Map<Id, String> latestTxnByQuote = new Map<Id, String>();
        Map<Id, List<Pricing_Result__c>> resultsByQuote = new Map<Id, List<Pricing_Result__c>>();

        for (Pricing_Result__c pr : [
            SELECT Id, Quote__c, Transaction_Id__c,
                   Total_Rate__c, Total_Rate_Factor__c, Total_Residual__c, Source__c
            FROM Pricing_Result__c
            WHERE Quote__c IN :quoteIds
              AND Source__c = 'Base Rate'
              AND Status__c = 'Success'
            ORDER BY CreatedDate DESC
        ]) {
            if (!latestTxnByQuote.containsKey(pr.Quote__c)) {
                latestTxnByQuote.put(pr.Quote__c, pr.Transaction_Id__c);
            }
            if (pr.Transaction_Id__c != latestTxnByQuote.get(pr.Quote__c)) {
                continue;
            }
            if (!resultsByQuote.containsKey(pr.Quote__c)) {
                resultsByQuote.put(pr.Quote__c, new List<Pricing_Result__c>());
            }
            resultsByQuote.get(pr.Quote__c).add(pr);
        }

        Map<Id, tval__TValue_Quote__c> tvQuoteByQuote = new Map<Id, tval__TValue_Quote__c>();
        // Standalone quotes (New Quote tab) create their TValue Quotes before an
        // Opportunity exists, so tval__Opportunity__c is null. Collect every such
        // TValue Quote here and stamp it with the converted Opportunity so it
        // appears in the Opportunity's TValue Quote related list.
        List<tval__TValue_Quote__c> tvQuotesToStamp = new List<tval__TValue_Quote__c>();
        for (tval__TValue_Quote__c tvq : [
            SELECT Id, Quote__c, tval__Term__c, tval__Purchase_Option__c, tval__Opportunity__c
            FROM tval__TValue_Quote__c
            WHERE Quote__c IN :quoteIds
            ORDER BY CreatedDate DESC
        ]) {
            if (!tvQuoteByQuote.containsKey(tvq.Quote__c)) {
                tvQuoteByQuote.put(tvq.Quote__c, tvq);
            }
            Id targetOppId = quoteToOppId.get(tvq.Quote__c);
            if (targetOppId != null && tvq.tval__Opportunity__c != targetOppId) {
                tvQuotesToStamp.add(new tval__TValue_Quote__c(
                    Id = tvq.Id,
                    tval__Opportunity__c = targetOppId
                ));
            }
        }

        // SAL-7168 — best-effort. The tval managed-package trigger has been
        // observed to throw on tval__TValue_Quote__c updates in some sandboxes
        // (qa). A failure here must not roll back the source Quote update or
        // saveCompany's Opportunity insert. Use Database.update partial-success
        // so individual row failures are captured without throwing.
        if (!tvQuotesToStamp.isEmpty()) {
            try {
                Database.update(tvQuotesToStamp, false);
            } catch (Exception ex) {
                System.debug('SAL-7168 TValue back-stamp skipped: ' + ex.getMessage());
            }
        }

        // Mirror of the TValue Quote back-stamp for Pricing_Result__c. A
        // standalone Quote's pricing run produces audit rows with Quote__c set
        // and Opportunity__c null; stamp them on conversion so the full
        // pricing audit trail appears in the Opportunity related list. Separate
        // query so the EF-offer query above (which filters by Source/Status)
        // is untouched.
        List<Pricing_Result__c> prsToStamp = new List<Pricing_Result__c>();
        for (Pricing_Result__c pr : [
            SELECT Id, Quote__c, Opportunity__c
            FROM Pricing_Result__c
            WHERE Quote__c IN :quoteIds
        ]) {
            Id targetOppId = quoteToOppId.get(pr.Quote__c);
            if (targetOppId != null && pr.Opportunity__c != targetOppId) {
                prsToStamp.add(new Pricing_Result__c(
                    Id = pr.Id,
                    Opportunity__c = targetOppId
                ));
            }
        }

        // SAL-7168 — same best-effort pattern as the TValue Quote stamp above.
        if (!prsToStamp.isEmpty()) {
            try {
                Database.update(prsToStamp, false);
            } catch (Exception ex) {
                System.debug('SAL-7168 Pricing Result back-stamp skipped: ' + ex.getMessage());
            }
        }

        Set<Id> opportunityIds = new Set<Id>();
        List<EF_Approved_Offers__c> allOffers = new List<EF_Approved_Offers__c>();

        for (Id quoteId : quoteIds) {
            List<Pricing_Result__c> pricingResults = resultsByQuote.get(quoteId);
            tval__TValue_Quote__c tvQuote = tvQuoteByQuote.get(quoteId);
            Id opportunityId = quoteToOppId.get(quoteId);

            if (pricingResults != null && !pricingResults.isEmpty() && tvQuote != null) {
                opportunityIds.add(opportunityId);
                allOffers.addAll(
                    NT_EFApprovedOfferService.buildOffersFromPricingResults(
                        opportunityId, pricingResults, tvQuote
                    )
                );
            }
        }

        // SAL-7168 — best-effort. The EF Approved Offers insert can hit
        // org validation rules (e.g. "Move app to Proposal Stage before
        // modifying the Offer" in marlin_qa, which fires while the Opportunity
        // is still at the just-created "Quote" stage). A failure here must not
        // roll back the back-stamps above or the source Quote.OpportunityId
        // update that fired this trigger; the EF offers can be re-created
        // later from the same TValue Quote + Pricing Result rows.
        if (!opportunityIds.isEmpty()) {
            try {
                NT_EFApprovedOfferService.replaceSystemOffers(opportunityIds, allOffers);
            } catch (Exception ex) {
                System.debug('SAL-7168 EF offers replace skipped: ' + ex.getMessage());
            }
        }
    }
}