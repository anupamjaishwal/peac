/**
 * @description  SAL-7384 — EFA/IPA (Loan) TValue template that applies # of Advanced Payments.
 *
 *               Required because the managed tval.TemplateStandardLoanImpl has no
 *               numAdvancedPayments field in its schema, so it drops the count before the
 *               engine runs and the quote prices as if there were no advance payments. No
 *               config can fix that the field doesn't exist to map. So we supply our own
 *               template: delegate to the standard Loan impl, then split the payment series
 *               like the Lease impl does N payments on the quote date, the rest one period
 *               later. Wired to EFA/IPA via tval__TValue_Template_Class__mdt.
 *
 *               The stock Loan impl drops the count (confirmed against the tval package
 *               source, TemplateStandardLoanImpl / TemplateStandardLeaseImpl):
 *               1. TemplateStandardLoanImpl's Parameters class has no numAdvancedPayments
 *                  field; the Lease impl's does. Nowhere to put the count.
 *               2. Its translateQuote only does "Advance_Arrears == Advance ->
 *                  paymentsInAdvance = true"; it never reads Number_of_Advanced_Payments.
 *               3. Its getTVDoc uses paymentsInAdvance only to set the payment start date
 *                  (quote date vs one period later), then builds ONE unknown payment line
 *                  for the full term. No advance event, no split.
 *               The Lease impl (getTVDoc) instead builds an "Advanced Payment" line of
 *                  numAdvancedPayments * WEIGHTED_UNKNOWN plus a (term - N) line. This
 *                  class does the same thing for Loan. (An older tval build's
 *                  TVDocForStandardLoan did this too, so Loan support existed once and was
 *                  lost in the template rewrite.)
 *
 *               How this class uses the advance count (call it N, from
 *               tval__Number_of_Advanced_Payments__c):
 *               - translateQuote reads N off the quote and holds it on the class. The
 *                 managed Parameters object has no field for it, so this is the only way to
 *                 carry it forward to getTVDoc.
 *               - getTVDoc lets the Loan impl build its document, then rewrites the one
 *                 solve-for-payment series (the full-term Payment line, amount = unknown):
 *                   * add an advance line: 1 event on the quote date for N payments, so the
 *                     borrower pays N up front.
 *                   * shrink the original series to (term - N) and push its start out one
 *                     period, so the remaining payments follow.
 *                 Both lines share the same unknown payment value, so the engine solves one
 *                 payment that covers N up front plus (term - N) after. That is what
 *                 "advance" means, and it matches how the Lease impl already does it.
 *               - N of 0/null does nothing: the document passes through and the quote prices
 *                 in arrears, same as before.
 *
 *               Also applies Commission Amount (added 2026-07-14, defect — no story yet).
 *               The stock Loan impl drops tval__Commission_Amount__c the same way it drops
 *               the advance count: no Parameters field, never read in translateQuote, no
 *               Commission cash-flow line built. The Lease impl handles it (reads the field,
 *               adds a Commission event line on the quote date), which is why lease quotes
 *               show the line and price it while EFA/IPA quotes silently drop the money.
 *               We do the Lease behavior for Loan: when Commission Amount is non-zero, add a
 *               Commission line on the quote date so the edit screen shows it and the engine
 *               recovers it through the payment. One deliberate difference: the Lease impl
 *               grabs its event via TVWS.GetCustomEvent on the lease group, but that helper
 *               returns null when the requested group differs from line[0]'s group on a
 *               multi-line document — and the Loan impl builds all its lines in its own
 *               'Loan 2' group. So we add a Commission event to 'Loan 2' with
 *               TVWS.AddCustomEvent (the same helper the Loan impl uses for its own events),
 *               with the same Loan base type the lease-group Commission event has.
 *               Commission of 0/null does nothing: the document passes through unchanged.
 * @author       Luke Vang
 * @date         2026-07-10
 */
global class NT_TValueLoanAdvanceTemplate implements tval.TValueTemplate {

    // The standard Loan template. It's our base — it does all the normal work, and we
    // just add the advance-payments feature on top of it.
    private tval.TemplateStandardLoanImpl standardLoan = new tval.TemplateStandardLoanImpl();

    // Remember how many advance payments this quote has. We save it here because the base
    // template gives us no field to pass it through, and we need it later in getTVDoc.
    private Decimal advancePayments;

    // Remember the quote's Commission Amount, carried the same way (the base Parameters
    // object has no slot for it). Double to match the engine's EventAmount type.
    private Double commissionAmount;

    // The cash-flow group the standard Loan impl builds all of its lines in. Our commission
    // event has to live in the same group — TVWS.GetCustomEvent refuses cross-group events
    // once the document has more than one line.
    private static final String LOAN_GROUP_NAME = 'Loan 2';

    // The tval engine marks a cash-flow amount with two special values, which the package
    // exposes as global constants on tval.TVWS (both Double, same type as EventAmount):
    //   TVWS.UNKNOWN_AMOUNT   (1E100)  = "solve for this amount"
    //   TVWS.WEIGHTED_UNKNOWN (1E110)  = one unit of an unknown; N of them is
    //                                    N * WEIGHTED_UNKNOWN, shown as "N.000x" in TValue
    //                                    Direct. (TVWS: "for weighted unknown of 2.5X use
    //                                    2.5 * WEIGHTED_UNKNOWN".)
    // We use the package's own constants directly so this can't drift from the engine.

    /**
     * @description  Same as the standard Loan template. We don't change the input schema.
     * @return       The template input schema JSON the tval engine reads.
     */
    global String getTemplateJson() {
        // Nothing to change here — let the base template answer.
        return standardLoan.getTemplateJson();
    }

    /**
     * @description  Same as the standard Loan template. We don't change the parameters.
     * @return       The template parameters object the base template uses.
     */
    global Object getParameters() {
        // Nothing to change here — let the base template answer.
        return standardLoan.getParameters();
    }

    /**
     * @description  Remembers the quote's # of Advanced Payments and Commission Amount
     *               (getTVDoc needs both later), then runs the standard Loan translation.
     * @param        quote   The TValue Quote being calculated.
     * @param        params  The template parameters object.
     * @return       The translated parameters object.
     */
    global Object translateQuote(tval__TValue_Quote__c quote, Object params) {
        // Grab the advance-payment count and commission off the quote and save them for
        // getTVDoc. This is the only place we can see the quote, so remember them now.
        // Then let the base template do its normal translation.
        advancePayments = quote.tval__Number_of_Advanced_Payments__c;
        commissionAmount = quote.tval__Commission_Amount__c;
        return standardLoan.translateQuote(quote, params);
    }

    /**
     * @description  This is where both features actually happen. The base template builds
     *               its document; we then (1) split the payments into "N paid up front on
     *               the quote date" plus "the rest, starting one period later" — the same
     *               shape the Lease template makes — and (2) add a Commission line on the
     *               quote date, like the Lease template does. Each step skips itself when
     *               its quote field is 0/null, so a plain quote passes through unchanged.
     * @param        params  The template parameters object.
     * @return       The TValue document sent to the engine.
     */
    global Object getTVDoc(Object params) {
        // Start from the document the base template builds.
        Object docObj = standardLoan.getTVDoc(params);

        // Make sure the document actually has cash-flow lines before we touch anything.
        tval.TVWS.TValueDocument doc = (tval.TVWS.TValueDocument) docObj;
        if (doc == null || doc.CashFlowMatrix == null || doc.CashFlowMatrix.CashFlowLines == null) {
            return docObj;
        }
        List<tval.TVWS.CashFlowLine> lines = doc.CashFlowMatrix.CashFlowLines.CashFlowLine;
        if (lines == null) {
            return docObj;
        }

        // Each step guards itself, so they apply independently in any combination.
        applyAdvanceSplit(lines);
        addCommissionLine(doc, lines);
        return doc;
    }

    // The SAL-7384 advance-payments split: pull N payments out of the solve-for-payment
    // series onto the quote date, and push the leftover series out one period. Does nothing
    // when the quote has no advance payments or no series to split.
    private void applyAdvanceSplit(List<tval.TVWS.CashFlowLine> lines) {
        // No advance payments? Leave the document exactly as-is (prices in arrears).
        if (advancePayments == null || advancePayments <= 0) {
            return;
        }

        // Find the payment line to split: the run of payments the engine solves for, long
        // enough to pull the advance payments out of (more payments than the advance count).
        Integer seriesIdx = null;
        for (Integer i = 0; i < lines.size(); i++) {
            tval.TVWS.CashFlowLine l = lines[i];
            if (l.CustomEvent != null && l.CustomEvent.BaseType == 'Payment'
                && l.EventAmount == tval.TVWS.UNKNOWN_AMOUNT
                && l.EventNumber != null && l.EventNumber > advancePayments) {
                seriesIdx = i;
                break;
            }
        }
        // Didn't find one (e.g. a payment-known quote)? Leave it alone.
        if (seriesIdx == null) {
            return;
        }

        tval.TVWS.CashFlowLine paymentSeries = lines[seriesIdx];

        // First new line: the advance payments, paid up front on the quote date. We copy the
        // payment line and say "collect N of the unknown payment" (N * WEIGHTED_UNKNOWN) —
        // the same expression the Lease impl uses.
        tval.TVWS.CashFlowLine advanceLine = paymentSeries.clone();
        advanceLine.EventNumber = 1;
        advanceLine.EventAmount = advancePayments.intValue() * tval.TVWS.WEIGHTED_UNKNOWN;

        // Then shorten the original line to the leftover payments (term minus the advance
        // count) and move its start out one period, so they come after the advance ones.
        paymentSeries.EventNumber = paymentSeries.EventNumber - advancePayments.intValue();
        paymentSeries.EventDate = shiftOnePeriod(paymentSeries.EventDate, paymentSeries.EventPeriod);

        // Drop the advance line in ahead of the leftovers. Both are the same unknown payment,
        // so the engine solves a single payment that works for the whole schedule.
        lines.add(seriesIdx, advanceLine);
    }

    // The commission feature: add a Commission line on the quote date, the way the Lease
    // impl does, so the edit screen shows it and the engine recovers it through the payment.
    // Does nothing when Commission Amount is 0/null.
    private void addCommissionLine(tval.TVWS.TValueDocument doc, List<tval.TVWS.CashFlowLine> lines) {
        if (commissionAmount == null || commissionAmount == 0) {
            return;
        }

        // Anchor on the loan-advance line the base template built: its date IS the validated
        // quote date and its period the quote period, so we copy both instead of re-deriving
        // them (and re-validating nulls) ourselves.
        Integer loanIdx = null;
        for (Integer i = 0; i < lines.size(); i++) {
            tval.TVWS.CashFlowLine l = lines[i];
            if (l.CustomEvent != null && l.CustomEvent.BaseType == tval.TVWS.LOAN_BASE_TYPE) {
                loanIdx = i;
                break;
            }
        }
        // No loan line (not a shape this template should ever build)? Leave the doc alone.
        if (loanIdx == null) {
            return;
        }
        tval.TVWS.CashFlowLine loanLine = lines[loanIdx];

        // Register a Commission event in the base template's own line group. We can't reuse
        // the lease group's Commission event here: GetCustomEvent returns null for a group
        // that doesn't match the document's existing lines. Loan base type matches the
        // lease-group Commission event, so the engine treats it the same way — money out
        // that the payments must recover.
        tval.TVWS.CashFlowLine commissionLine = new tval.TVWS.CashFlowLine();
        commissionLine.CustomEvent = tval.TVWS.AddCustomEvent(
            doc, LOAN_GROUP_NAME, 'Commission', tval.TVWS.LOAN_BASE_TYPE
        );
        commissionLine.EventDate = loanLine.EventDate;
        commissionLine.EventAmount = commissionAmount;
        commissionLine.EventNumber = 1;
        commissionLine.EventPeriod = loanLine.EventPeriod;

        // Right after the loan amount, before the payments — the same layout lease quotes
        // already show.
        lines.add(loanIdx + 1, commissionLine);
    }

    // Move a tval date (MM/DD/YYYY text) forward by one payment period, so the leftover
    // payments start one period after the advance ones.
    private static String shiftOnePeriod(String engineDate, String period) {
        if (String.isBlank(engineDate)) {
            return engineDate;
        }
        List<String> parts = engineDate.split('/');
        Date d = Date.newInstance(Integer.valueOf(parts[2]), Integer.valueOf(parts[0]), Integer.valueOf(parts[1]));
        String p = period == null ? 'Monthly' : period;
        if (p == 'Monthly') {
            d = d.addMonths(1);
        } else if (p == 'Quarterly') {
            d = d.addMonths(3);
        } else if (p == 'Semiannual') {
            d = d.addMonths(6);
        } else if (p == 'Annual') {
            d = d.addMonths(12);
        } else if (p == 'Biweekly') {
            d = d.addDays(14);
        } else if (p == 'Weekly') {
            d = d.addDays(7);
        } else if (p == 'Daily') {
            d = d.addDays(1);
        } else {
            d = d.addMonths(1);
        }
        String mm = String.valueOf(d.month()).leftPad(2, '0');
        String dd = String.valueOf(d.day()).leftPad(2, '0');
        return mm + '/' + dd + '/' + String.valueOf(d.year());
    }
}