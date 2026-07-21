/**
 * @description  Unit tests for NT_PaymentSolveService — the pure lease/loan present-value
 *               inversion used by the SAL-6441 "solve for financed amount" path. Verifies the
 *               computed financed amount round-trips back to the requested payment.
 * @author       Northteq
 * @date         2026-07-06
 */
@IsTest
private class NT_PaymentSolveServiceTest {

    // Asserts two decimals are within `tol` of each other.
    private static void assertClose(Decimal expected, Decimal actual, Decimal tol, String msg) {
        System.assertNotEquals(null, actual, msg + ' (was null)');
        System.assert(Math.abs(expected - actual) <= tol,
            msg + ' expected≈' + expected + ' actual=' + actual);
    }

    @IsTest
    static void invertInterestRate_monthlyNoResidual() {
        // 12% APR, 24 months, $100/mo → ~$2124.34 financed.
        Decimal financed = NT_PaymentSolveService.invertInterestRate(100, 12, 24, 'Monthly', 0, 0);
        assertClose(2124.34, financed, 0.05, 'Monthly 12% 24mo $100 inversion');

        // Round-trips back to ~$100.
        Decimal pmt = NT_PaymentSolveService.paymentForFinanced(financed, 12, 24, 'Monthly', 0, 0);
        assertClose(100, pmt, 0.02, 'Round-trip payment');
    }

    @IsTest
    static void invertInterestRate_zeroRate() {
        // 0% APR: financed = payment × number of periods.
        Decimal financed = NT_PaymentSolveService.invertInterestRate(100, 0, 24, 'Monthly', 0, 0);
        assertClose(2400, financed, 0.01, '0% 24mo $100 => 2400');
    }

    @IsTest
    static void invertInterestRate_withResidual() {
        // Adds the present value of the end-of-term residual.
        Decimal financed = NT_PaymentSolveService.invertInterestRate(100, 12, 24, 'Monthly', 500, 0);
        assertClose(2518.12, financed, 0.10, 'With $500 residual');

        Decimal pmt = NT_PaymentSolveService.paymentForFinanced(financed, 12, 24, 'Monthly', 500, 0);
        assertClose(100, pmt, 0.02, 'Round-trip payment with residual');
    }

    @IsTest
    static void invertInterestRate_quarterly() {
        // 12% APR, 24 months, $300/qtr → ~$2105.91 (8 quarterly periods at 3%).
        Decimal financed = NT_PaymentSolveService.invertInterestRate(300, 12, 24, 'Quarterly', 0, 0);
        assertClose(2105.91, financed, 0.10, 'Quarterly inversion');
        Decimal pmt = NT_PaymentSolveService.paymentForFinanced(financed, 12, 24, 'Quarterly', 0, 0);
        assertClose(300, pmt, 0.05, 'Round-trip quarterly payment');
    }

    @IsTest
    static void invertInterestRate_rawFrequencyTolerant() {
        // Raw picklist values (with hyphens/casing) resolve the same as mapped period values.
        Decimal a = NT_PaymentSolveService.invertInterestRate(100, 12, 24, 'Semi-Annual', 0, 0);
        Decimal b = NT_PaymentSolveService.invertInterestRate(100, 12, 24, 'Semiannual', 0, 0);
        assertClose(a, b, 0.01, 'Raw vs mapped Semiannual match');
        System.assertNotEquals(null,
            NT_PaymentSolveService.invertInterestRate(100, 12, 24, 'Bi-Weekly', 0, 0),
            'Bi-Weekly should resolve');
    }

    @IsTest
    static void invertInterestRate_advancePaymentsShiftsFactor() {
        Decimal arrears = NT_PaymentSolveService.invertInterestRate(100, 12, 24, 'Monthly', 0, 0);
        Decimal advance = NT_PaymentSolveService.invertInterestRate(100, 12, 24, 'Monthly', 0, 1);
        // Payments in advance are worth more, so the same payment finances a larger amount.
        System.assert(advance > arrears, 'Advance payments should finance more: '
            + advance + ' vs ' + arrears);
    }

    @IsTest
    static void invertRateFactor_basic() {
        // payment = amount × factor → amount = payment / factor.
        Decimal financed = NT_PaymentSolveService.invertRateFactor(100, 0.05);
        assertClose(2000, financed, 0.01, 'Rate factor inversion');
        System.assertEquals(null, NT_PaymentSolveService.invertRateFactor(100, 0),
            'Zero factor => null');
    }

    @IsTest
    static void invalidInputs_returnNull() {
        System.assertEquals(null, NT_PaymentSolveService.invertInterestRate(null, 12, 24, 'Monthly', 0, 0), 'null payment');
        System.assertEquals(null, NT_PaymentSolveService.invertInterestRate(0, 12, 24, 'Monthly', 0, 0), 'zero payment');
        System.assertEquals(null, NT_PaymentSolveService.invertInterestRate(100, 12, null, 'Monthly', 0, 0), 'null term');
        System.assertEquals(null, NT_PaymentSolveService.invertInterestRate(100, 12, 24, '', 0, 0), 'blank frequency');
        System.assertEquals(null, NT_PaymentSolveService.paymentForFinanced(null, 12, 24, 'Monthly', 0, 0), 'null financed');
    }
}