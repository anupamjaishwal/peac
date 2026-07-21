/**
 * @description  SAL-6441 — Solves for the financed amount when a user supplies a Requested
 *               Payment Amount instead of a Financed Amount ("solve for financed amount" path).
 *
 *               Background: the rate on our Rate Cards is chosen by a financed-amount tier
 *               (Rate_Card_Row__c criteria on Quote.Total_Financed_Amount__c). On the payment
 *               path the financed amount is unknown, so we cannot pick a rate row directly —
 *               and TValue's templates only solve for Payment, never Amount. This class inverts
 *               the standard lease/loan present-value relationship in Apex so we can compute the
 *               financed amount ourselves, hand it to TValue as a normal amount, and let TValue
 *               re-solve the payment. NT_RateCardService drives the amount↔tier iteration; this
 *               class holds only the pure math (no SOQL/DML) so it is unit-testable in isolation.
 * @author       Northteq
 * @date         2026-07-06
 */
public without sharing class NT_PaymentSolveService {

    /**
     * @description Present-value inversion for an Interest-Rate ("Interest Rate") rate card:
     *              given a periodic payment, returns the financed amount that amortizes to that
     *              payment at the supplied APR over the term, including any end-of-term
     *              residual/balloon. Mirrors the inputs fed to TValue in
     *              NT_TValueQueueable.buildTValueQuote (rate, term, frequency, residual,
     *              advance payments) so the computed amount round-trips back to the same payment.
     * @param  payment          The requested periodic payment (per the given frequency).
     * @param  aprPercent       Annual percentage rate as a whole number (e.g. 13 = 13%).
     * @param  termMonths       The term in months (as stored on the combination/Quote.Term__c).
     * @param  mappedFrequency  TValue period value: Monthly/Quarterly/Semiannual/Annual/
     *                          Biweekly/Weekly/Daily (from NT_TValueQueueable.mapPaymentFrequency).
     * @param  residual         End-of-term residual/balloon paid at maturity (null/0 for $1-out).
     * @param  advancePayments  Count of payments made in advance (annuity-due); 0/null = arrears.
     * @return The financed amount that produces the payment, rounded to cents; null if inputs
     *         are insufficient (missing payment/term/frequency).
     */
    public static Decimal invertInterestRate(
        Decimal payment,
        Decimal aprPercent,
        Decimal termMonths,
        String mappedFrequency,
        Decimal residual,
        Decimal advancePayments
    ) {
        if (payment == null || payment <= 0 || termMonths == null || termMonths <= 0
                || String.isBlank(mappedFrequency)) {
            return null;
        }

        Integer perYear = periodsPerYear(mappedFrequency);
        // Number of payment periods over the term (term is in months).
        Double n = (termMonths.doubleValue() / 12.0) * perYear;
        if (n <= 0) {
            return null;
        }

        Double i = (aprPercent == null ? 0.0 : aprPercent.doubleValue() / 100.0) / perYear;
        Double res = (residual == null ? 0.0 : residual.doubleValue());
        Double pmt = payment.doubleValue();

        Double base = 1 + i; // kept Double so Math.pow resolves (Double, Double)
        Double annuityFactor;
        Double balloonPv;
        if (i == 0.0) {
            annuityFactor = n;
            balloonPv = res;
        } else {
            Double discount = Math.pow(base, -n);
            annuityFactor = (1 - discount) / i;
            balloonPv = res * discount;
        }

        // Payments made in advance: annuity-due shift (× (1+i)). Exact only for K=1 advance
        // payment; for K>=2 TValue's "N advance payments at signing" semantics diverge from this
        // approximation. The end-to-end guard is TValue itself — it receives the solved amount and
        // recomputes the payment, so any drift shows up as payment != requested in the results.
        if (advancePayments != null && advancePayments > 0 && i != 0.0) {
            annuityFactor = annuityFactor * base;
        }

        Double financed = pmt * annuityFactor + balloonPv;
        if (financed <= 0) {
            return null;
        }
        return Decimal.valueOf(financed).setScale(2, System.RoundingMode.HALF_UP);
    }

    /**
     * @description Inversion for a "Rate Factor" rate card, where the payment is the financed
     *              amount multiplied by a payment factor. Inverts trivially.
     * @param  payment     The requested periodic payment.
     * @param  rateFactor  The payment factor (payment per unit financed).
     * @return payment / rateFactor rounded to cents; null when the factor is missing/zero.
     */
    public static Decimal invertRateFactor(Decimal payment, Decimal rateFactor) {
        if (payment == null || payment <= 0 || rateFactor == null || rateFactor == 0) {
            return null;
        }
        return (payment / rateFactor).setScale(2, System.RoundingMode.HALF_UP);
    }

    /**
     * @description Recomputes the periodic payment for a given financed amount — the inverse of
     *              invertInterestRate — so callers can round-trip a solved amount and confirm it
     *              reproduces the requested payment within tolerance before offering it.
     * @param  financedAmount  The amount to amortize.
     * @param  aprPercent      APR as a whole number.
     * @param  termMonths      Term in months.
     * @param  mappedFrequency TValue period value.
     * @param  residual        End-of-term residual/balloon.
     * @param  advancePayments Count of advance payments.
     * @return The periodic payment, rounded to cents; null if inputs are insufficient.
     */
    public static Decimal paymentForFinanced(
        Decimal financedAmount,
        Decimal aprPercent,
        Decimal termMonths,
        String mappedFrequency,
        Decimal residual,
        Decimal advancePayments
    ) {
        if (financedAmount == null || financedAmount <= 0 || termMonths == null || termMonths <= 0
                || String.isBlank(mappedFrequency)) {
            return null;
        }

        Integer perYear = periodsPerYear(mappedFrequency);
        Double n = (termMonths.doubleValue() / 12.0) * perYear;
        if (n <= 0) {
            return null;
        }

        Double i = (aprPercent == null ? 0.0 : aprPercent.doubleValue() / 100.0) / perYear;
        Double res = (residual == null ? 0.0 : residual.doubleValue());

        Double base = 1 + i; // kept Double so Math.pow resolves (Double, Double)
        Double annuityFactor;
        Double balloonPv;
        if (i == 0.0) {
            annuityFactor = n;
            balloonPv = res;
        } else {
            Double discount = Math.pow(base, -n);
            annuityFactor = (1 - discount) / i;
            balloonPv = res * discount;
        }
        if (advancePayments != null && advancePayments > 0 && i != 0.0) {
            annuityFactor = annuityFactor * base;
        }
        if (annuityFactor == 0.0) {
            return null;
        }

        Double pmt = (financedAmount.doubleValue() - balloonPv) / annuityFactor;
        if (pmt <= 0) {
            return null;
        }
        return Decimal.valueOf(pmt).setScale(2, System.RoundingMode.HALF_UP);
    }

    /**
     * @description Number of payment periods per year for a payment frequency. Tolerant of both
     *              raw picklist values ("Semi-Annual", "Bi-Weekly") and TValue period values
     *              ("Semiannual", "Biweekly"); mirrors NT_TValueQueueable.mapPaymentFrequency.
     * @param  frequency Raw or mapped payment frequency.
     * @return Periods per year (defaults to 12/Monthly for unrecognized/blank values).
     */
    @TestVisible
    private static Integer periodsPerYear(String frequency) {
        if (String.isBlank(frequency)) {
            return 12;
        }
        String f = frequency.toLowerCase();
        // Order matters: check biweekly before weekly, semi/annual before generic.
        if (f.contains('biweek') || f.contains('bi-week')) { return 26; }
        if (f.contains('semi') || f.contains('half')) { return 2; }
        if (f.contains('quarter')) { return 4; }
        if (f.contains('month')) { return 12; }
        if (f.contains('annual') || f.contains('year')) { return 1; }
        if (f.contains('week')) { return 52; }
        if (f.contains('daily') || f.contains('day')) { return 365; }
        return 12;
    }
}