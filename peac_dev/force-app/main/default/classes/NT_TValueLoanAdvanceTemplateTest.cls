/**
 * @description  Unit tests for NT_TValueLoanAdvanceTemplate (SAL-7384 + commission defect).
 *               Covers:
 *                 - delegation of getTemplateJson/getParameters to the standard Loan impl
 *                 - getTVDoc passthrough when the quote has no advance payments
 *                 - advance split: N-x-unknown event on the quote date plus the remaining
 *                   term - N series one period later (monthly and quarterly)
 *                 - passthrough guard when advance payments >= total term
 *                 - commission: a Commission line on the quote date when Commission Amount
 *                   is non-zero, alone and combined with the advance split; passthrough
 *                   when zero
 * @author       Luke Vang
 * @date         2026-07-10
 */
@isTest
private class NT_TValueLoanAdvanceTemplateTest {

    private static final Decimal UNKNOWN_MARKER = Decimal.valueOf('1E100');
    private static final Decimal UNKNOWN_MULTIPLE_BASE = Decimal.valueOf('1E110');

    // Builds an in-memory loan quote; translateQuote/getTVDoc never touch the database
    private static tval__TValue_Quote__c buildQuote(Decimal advancePayments, String period, Decimal term) {
        return buildQuote(advancePayments, period, term, null);
    }

    // Same, with a Commission Amount on the quote
    private static tval__TValue_Quote__c buildQuote(Decimal advancePayments, String period, Decimal term, Decimal commission) {
        return new tval__TValue_Quote__c(
            tval__Quote_Name__c = 'NT_TValueLoanAdvanceTemplateTest',
            tval__Quote_Date__c = Date.newInstance(2026, 7, 10),
            tval__Quote_Amount__c = 35000,
            tval__Amount_Financed__c = 35000,
            tval__Term__c = term,
            tval__Rate__c = 9.55,
            tval__Period__c = period,
            tval__Advance_Arrears__c = (advancePayments != null && advancePayments > 0) ? 'Advance' : 'Arrears',
            tval__Number_of_Advanced_Payments__c = advancePayments,
            tval__Payment_In_Advance__c = advancePayments != null && advancePayments > 0,
            tval__Purchase_Option__c = 'Customer Owned',
            tval__Commission_Amount__c = commission
        );
    }

    // Runs the full template pipeline and returns the built engine document
    private static tval.TVWS.TValueDocument runPipeline(tval__TValue_Quote__c q, NT_TValueLoanAdvanceTemplate t) {
        Object params = t.getParameters();
        Object translated = t.translateQuote(q, params);
        return (tval.TVWS.TValueDocument) t.getTVDoc(translated);
    }

    @isTest
    static void testSchemaAndParametersDelegate() {
        NT_TValueLoanAdvanceTemplate t = new NT_TValueLoanAdvanceTemplate();
        System.assertEquals(
            new tval.TemplateStandardLoanImpl().getTemplateJson(),
            t.getTemplateJson(),
            'Schema should be the standard Loan schema'
        );
        System.assertNotEquals(null, t.getParameters(), 'Parameters should delegate to the standard Loan impl');
    }

    @isTest
    static void testNoAdvancePaymentsPassesThrough() {
        NT_TValueLoanAdvanceTemplate t = new NT_TValueLoanAdvanceTemplate();
        tval.TVWS.TValueDocument doc = runPipeline(buildQuote(null, 'Monthly', 60), t);

        List<tval.TVWS.CashFlowLine> lines = doc.CashFlowMatrix.CashFlowLines.CashFlowLine;
        System.assertEquals(2, lines.size(), 'Doc without advance payments should keep the standard 2 lines');
        System.assertEquals(60, lines[1].EventNumber, 'Payment series should keep the full term');
    }

    @isTest
    static void testAdvanceSplitMonthly() {
        NT_TValueLoanAdvanceTemplate t = new NT_TValueLoanAdvanceTemplate();
        tval.TVWS.TValueDocument doc = runPipeline(buildQuote(2, 'Monthly', 60), t);

        List<tval.TVWS.CashFlowLine> lines = doc.CashFlowMatrix.CashFlowLines.CashFlowLine;
        System.assertEquals(3, lines.size(), 'Advance payments should add a split line');

        tval.TVWS.CashFlowLine advance = lines[1];
        System.assertEquals(1, advance.EventNumber, 'Advance event is a single line');
        System.assertEquals(2 * UNKNOWN_MULTIPLE_BASE, advance.EventAmount, 'Advance amount encodes 2 x unknown');
        System.assertEquals('07/10/2026', advance.EventDate, 'Advance payments land on the quote date');

        tval.TVWS.CashFlowLine remaining = lines[2];
        System.assertEquals(58, remaining.EventNumber, 'Remaining series is term - advance count');
        System.assertEquals(UNKNOWN_MARKER, remaining.EventAmount, 'Remaining series stays solve-for');
        System.assertEquals('08/10/2026', remaining.EventDate, 'Remaining series starts one period later');
    }

    @isTest
    static void testAdvanceSplitQuarterlyShiftsThreeMonths() {
        NT_TValueLoanAdvanceTemplate t = new NT_TValueLoanAdvanceTemplate();
        tval.TVWS.TValueDocument doc = runPipeline(buildQuote(1, 'Quarterly', 12), t);

        List<tval.TVWS.CashFlowLine> lines = doc.CashFlowMatrix.CashFlowLines.CashFlowLine;
        System.assertEquals(3, lines.size(), 'Advance payment should add a split line');
        System.assertEquals('10/10/2026', lines[2].EventDate, 'Quarterly series shifts three months');
    }

    @isTest
    static void testAdvanceSplitRemainingPeriods() {
        // period => term in months (enough for >1 payment), expected shifted start date
        Map<String, List<String>> periodToTermAndDate = new Map<String, List<String>>{
            'Semiannual' => new List<String>{ '24', '01/10/2027' },
            'Annual'     => new List<String>{ '36', '07/10/2027' },
            'Biweekly'   => new List<String>{ '12', '07/24/2026' },
            'Weekly'     => new List<String>{ '12', '07/17/2026' },
            'Daily'      => new List<String>{ '12', '07/11/2026' }
        };
        for (String period : periodToTermAndDate.keySet()) {
            NT_TValueLoanAdvanceTemplate t = new NT_TValueLoanAdvanceTemplate();
            Decimal term = Decimal.valueOf(periodToTermAndDate.get(period)[0]);
            tval.TVWS.TValueDocument doc = runPipeline(buildQuote(1, period, term), t);
            List<tval.TVWS.CashFlowLine> lines = doc.CashFlowMatrix.CashFlowLines.CashFlowLine;
            System.assertEquals(3, lines.size(), period + ': advance payment should add a split line');
            System.assertEquals(
                periodToTermAndDate.get(period)[1],
                lines[2].EventDate,
                period + ': remaining series should shift one period'
            );
        }
    }

    @isTest
    static void testCommissionAddsLineAfterLoanLine() {
        NT_TValueLoanAdvanceTemplate t = new NT_TValueLoanAdvanceTemplate();
        tval.TVWS.TValueDocument doc = runPipeline(buildQuote(null, 'Monthly', 60, 700), t);

        List<tval.TVWS.CashFlowLine> lines = doc.CashFlowMatrix.CashFlowLines.CashFlowLine;
        System.assertEquals(3, lines.size(), 'Commission should add one line to the standard 2');

        tval.TVWS.CashFlowLine commission = lines[1];
        System.assertEquals('Commission', commission.CustomEvent.Name, 'Commission line sits right after the loan line');
        System.assertEquals(tval.TVWS.LOAN_BASE_TYPE, commission.CustomEvent.BaseType, 'Commission is Loan-based, like the lease-group event');
        System.assertEquals(700, commission.EventAmount, 'Commission line carries the quote Commission Amount');
        System.assertEquals(1, commission.EventNumber, 'Commission is a single event');
        System.assertEquals('07/10/2026', commission.EventDate, 'Commission lands on the quote date');

        System.assertEquals(60, lines[2].EventNumber, 'Payment series should keep the full term');
        System.assertEquals(UNKNOWN_MARKER, lines[2].EventAmount, 'Payment series stays solve-for');
    }

    @isTest
    static void testCommissionWithAdvanceSplit() {
        NT_TValueLoanAdvanceTemplate t = new NT_TValueLoanAdvanceTemplate();
        tval.TVWS.TValueDocument doc = runPipeline(buildQuote(2, 'Monthly', 60, 700), t);

        List<tval.TVWS.CashFlowLine> lines = doc.CashFlowMatrix.CashFlowLines.CashFlowLine;
        System.assertEquals(4, lines.size(), 'Commission and the advance split should both add a line');

        System.assertEquals('Commission', lines[1].CustomEvent.Name, 'Commission line still sits right after the loan line');
        System.assertEquals(700, lines[1].EventAmount, 'Commission amount is unchanged by the split');

        System.assertEquals(2 * UNKNOWN_MULTIPLE_BASE, lines[2].EventAmount, 'Advance line still encodes 2 x unknown');
        System.assertEquals('07/10/2026', lines[2].EventDate, 'Advance payments still land on the quote date');
        System.assertEquals(58, lines[3].EventNumber, 'Remaining series is still term - advance count');
        System.assertEquals('08/10/2026', lines[3].EventDate, 'Remaining series still starts one period later');
    }

    @isTest
    static void testZeroCommissionPassesThrough() {
        NT_TValueLoanAdvanceTemplate t = new NT_TValueLoanAdvanceTemplate();
        tval.TVWS.TValueDocument doc = runPipeline(buildQuote(null, 'Monthly', 60, 0), t);

        List<tval.TVWS.CashFlowLine> lines = doc.CashFlowMatrix.CashFlowLines.CashFlowLine;
        System.assertEquals(2, lines.size(), 'Zero commission should leave the doc untouched');
    }

    @isTest
    static void testAdvanceCountAtTermPassesThrough() {
        NT_TValueLoanAdvanceTemplate t = new NT_TValueLoanAdvanceTemplate();
        tval.TVWS.TValueDocument doc = runPipeline(buildQuote(60, 'Monthly', 60), t);

        List<tval.TVWS.CashFlowLine> lines = doc.CashFlowMatrix.CashFlowLines.CashFlowLine;
        System.assertEquals(2, lines.size(), 'Advance count >= term should leave the doc untouched');
    }
}