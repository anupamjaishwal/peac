/**
 * @description  Unit tests for NT_PricingValidationService. Covers
 *               isTValueReady (both overloads), isLeaseProduct, isLoanProduct,
 *               getMissingTValueFields, and isEligibleForPricing. Includes the
 *               SAL-7243 addition of "1.00 Out" to LEASE_PURCHASE_OPTIONS.
 * @author       Northteq
 * @date         2026-05-28
 */
@isTest
private class NT_PricingValidationServiceTest {

    /** Build a "ready" pricing context with every TValue input populated. */
    private static NT_PricingContext readyContext() {
        NT_PricingContext ctx = new NT_PricingContext();
        ctx.parentId = UserInfo.getOrganizationId(); // any non-null Id; isEligibleForPricing only nullity-checks
        ctx.financedAmount = 50000;
        ctx.requestedTerms = new List<Decimal>{ 36 };
        ctx.finalRate = 6.25;
        ctx.paymentFrequencies = new List<String>{ 'Monthly' };
        ctx.endOfTermOption = '1.00 Out';
        return ctx;
    }

    @isTest
    static void isTValueReady_trueWhenAllRequiredInputsPresent() {
        NT_PricingValidationService svc = new NT_PricingValidationService();
        NT_PricingContext ctx = readyContext();
        List<String> missing = new List<String>();

        System.assertEquals(true, svc.isTValueReady(ctx, missing),
            'A fully populated context must satisfy isTValueReady.');
        System.assert(missing.isEmpty(),
            'Missing-fields list must be empty when all inputs are present.');
        // Single-arg overload mirrors the result.
        System.assertEquals(true, svc.isTValueReady(ctx));
    }

    @isTest
    static void isTValueReady_collectsEveryMissingField() {
        NT_PricingValidationService svc = new NT_PricingValidationService();
        NT_PricingContext ctx = new NT_PricingContext(); // empty: nothing populated
        List<String> missing = new List<String>();

        System.assertEquals(false, svc.isTValueReady(ctx, missing));
        System.assertEquals(false, svc.isTValueReady(ctx));
        // All four gates should report.
        System.assert(missing.contains('Financed Amount or Payment Amount'));
        System.assert(missing.contains('Term'));
        System.assert(missing.contains('Rate (no matching rate card found)'));
        System.assert(missing.contains('Payment Frequency'));
    }

    @isTest
    static void isTValueReady_acceptsPaymentInPlaceOfFinancedAmount() {
        NT_PricingValidationService svc = new NT_PricingValidationService();
        NT_PricingContext ctx = readyContext();
        ctx.financedAmount = null;
        ctx.monthlyPayment = 1500;

        List<String> missing = new List<String>();
        System.assertEquals(true, svc.isTValueReady(ctx, missing),
            'Monthly Payment substitutes for Financed Amount per AC.');
    }

    @isTest
    static void isTValueReady_acceptsRateFactorInPlaceOfFinalRate() {
        NT_PricingValidationService svc = new NT_PricingValidationService();
        NT_PricingContext ctx = readyContext();
        ctx.finalRate = null;
        ctx.finalRateFactor = 0.018;

        System.assertEquals(true, svc.isTValueReady(ctx));
    }

    @isTest
    static void getMissingTValueFields_returnsSameAsByRefVariant() {
        NT_PricingValidationService svc = new NT_PricingValidationService();
        NT_PricingContext ctx = new NT_PricingContext();
        List<String> direct = svc.getMissingTValueFields(ctx);
        System.assertEquals(4, direct.size(),
            'Empty context exposes all four gating-field misses.');
    }

    /**
     * SAL-7243 — "1.00 Out" must be recognized as a lease option alongside the
     * legacy "$1.00 Buyout" value.
     */
    @isTest
    static void isLeaseProduct_recognizes1OutAndLegacyBuyout() {
        NT_PricingValidationService svc = new NT_PricingValidationService();
        NT_PricingContext ctx = new NT_PricingContext();

        ctx.endOfTermOption = '1.00 Out';
        System.assertEquals(true, svc.isLeaseProduct(ctx),
            'SAL-7243: "1.00 Out" must be classified as Lease.');

        ctx.endOfTermOption = '$1.00 Buyout';
        System.assertEquals(true, svc.isLeaseProduct(ctx),
            'Legacy "$1.00 Buyout" must still be classified as Lease.');

        ctx.endOfTermOption = 'FMV';
        System.assertEquals(true, svc.isLeaseProduct(ctx));
    }

    @isTest
    static void isLeaseProduct_falseForBlankOrNonLeaseOption() {
        NT_PricingValidationService svc = new NT_PricingValidationService();
        NT_PricingContext ctx = new NT_PricingContext();

        ctx.endOfTermOption = null;
        System.assertEquals(false, svc.isLeaseProduct(ctx));
        ctx.endOfTermOption = '';
        System.assertEquals(false, svc.isLeaseProduct(ctx));
        ctx.endOfTermOption = 'Customer Owned';
        System.assertEquals(false, svc.isLeaseProduct(ctx),
            '"Customer Owned" is a Loan option, not Lease.');
    }

    @isTest
    static void isLoanProduct_recognizesCustomerOwnedOnly() {
        NT_PricingValidationService svc = new NT_PricingValidationService();
        NT_PricingContext ctx = new NT_PricingContext();

        ctx.endOfTermOption = 'Customer Owned';
        System.assertEquals(true, svc.isLoanProduct(ctx));

        ctx.endOfTermOption = '1.00 Out';
        System.assertEquals(false, svc.isLoanProduct(ctx),
            '"1.00 Out" is a Lease option, not Loan.');

        ctx.endOfTermOption = null;
        System.assertEquals(false, svc.isLoanProduct(ctx));
        ctx.endOfTermOption = '';
        System.assertEquals(false, svc.isLoanProduct(ctx));
    }

    @isTest
    static void isEligibleForPricing_trueWhenContextIsReady() {
        NT_PricingValidationService svc = new NT_PricingValidationService();
        NT_PricingContext ctx = readyContext();
        System.assertEquals(true, svc.isEligibleForPricing(ctx));
    }

    @isTest
    static void isEligibleForPricing_falseWhenParentIdNull() {
        NT_PricingValidationService svc = new NT_PricingValidationService();
        NT_PricingContext ctx = readyContext();
        ctx.parentId = null;
        System.assertEquals(false, svc.isEligibleForPricing(ctx));
    }

    @isTest
    static void isEligibleForPricing_falseWhenTValueInputsIncomplete() {
        NT_PricingValidationService svc = new NT_PricingValidationService();
        NT_PricingContext ctx = readyContext();
        ctx.requestedTerms = new List<Decimal>(); // strip Term
        System.assertEquals(false, svc.isEligibleForPricing(ctx));
    }
}