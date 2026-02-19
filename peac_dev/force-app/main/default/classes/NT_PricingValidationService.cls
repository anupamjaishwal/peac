/**
 * @description Service class for pricing validation.
 *              Validates Program constraints and TValue readiness.
 * @author Northteq
 */
public class NT_PricingValidationService {
    
    // Lease Purchase Options (require Residual)
    private static final Set<String> LEASE_PURCHASE_OPTIONS = new Set<String>{
        'FMV',
        'Put',
        'Assigned Residual',
        'Guaranteed Residual',
        'Assign Resid No Renewal',
        '26-Rental-No'
    };
    
    // Loan Purchase Options (no Residual required)
    private static final Set<String> LOAN_PURCHASE_OPTIONS = new Set<String>{
        '1.00 Out',
        'Customer Owned'
    };
    
    /**
     * @description Validates record values against Program constraints
     * @param ctx The pricing context to validate
     * @return NT_PricingContext The validated context (may contain errors)
     */
    public NT_PricingContext validateProgramConstraints(NT_PricingContext ctx) {
        if (!ctx.hasProgram || ctx.program == null) {
            return ctx; // No program validation needed
        }
        
        Program__c prog = ctx.program;
        List<String> errors = new List<String>();
        
        // Term validation - validate each requested term
        for (Decimal term : ctx.requestedTerms) {
            if (prog.Minimum_Term__c != null && term < prog.Minimum_Term__c) {
                errors.add('Term ' + term.intValue() + ' is below minimum ' + prog.Minimum_Term__c.intValue());
            }
            if (prog.Maximum_Term__c != null && term > prog.Maximum_Term__c) {
                errors.add('Term ' + term.intValue() + ' exceeds maximum ' + prog.Maximum_Term__c.intValue());
            }
        }
        
        // Amount validation
        Decimal amount = ctx.financedAmount;
        if (amount != null) {
            if (prog.Minimum_Financed_Amount__c != null && amount < prog.Minimum_Financed_Amount__c) {
                errors.add('Amount $' + amount.setScale(2) + ' is below minimum $' + prog.Minimum_Financed_Amount__c.setScale(2));
            }
            if (prog.Maximum_Financed_Amount__c != null && amount > prog.Maximum_Financed_Amount__c) {
                errors.add('Amount $' + amount.setScale(2) + ' exceeds maximum $' + prog.Maximum_Financed_Amount__c.setScale(2));
            }
        }
        
        if (!errors.isEmpty()) {
            ctx.setPricingError('Program validation failed: ' + String.join(errors, '; '));
        }
        
        return ctx;
    }
    
    /**
     * @description Checks if TValue has all required inputs
     * @param ctx The pricing context to check
     * @param missingFields List to populate with missing field names
     * @return Boolean true if TValue can be invoked
     */
    public Boolean isTValueReady(NT_PricingContext ctx, List<String> missingFields) {
        // Must have Financed Amount OR Payment Amount
        Boolean hasAmount = (ctx.financedAmount != null && ctx.financedAmount > 0);
        Boolean hasPayment = (ctx.monthlyPayment != null && ctx.monthlyPayment > 0);
        if (!hasAmount && !hasPayment) {
            missingFields.add('Financed Amount or Payment Amount');
        }
        
        // Must have Term
        if (ctx.requestedTerms == null || ctx.requestedTerms.isEmpty()) {
            missingFields.add('Term');
        }
        
        // Must have Rate (from Rate Card evaluation)
        if (ctx.finalRate == null && ctx.finalRateFactor == null) {
            missingFields.add('Rate (no matching rate card found)');
        }
        
        // Must have Payment Frequency
        if (ctx.paymentFrequencies.isEmpty()) {
            missingFields.add('Payment Frequency');
        }
        
        // Residual required for Lease products (based on Purchase Option)
        if (isLeaseProduct(ctx) && ctx.finalResidual == null) {
            missingFields.add('Residual (required for Lease)');
        }
        
        return missingFields.isEmpty();
    }
    
    /**
     * @description Checks if TValue is ready without returning missing fields
     * @param ctx The pricing context to check
     * @return Boolean true if TValue can be invoked
     */
    public Boolean isTValueReady(NT_PricingContext ctx) {
        List<String> missingFields = new List<String>();
        return isTValueReady(ctx, missingFields);
    }
    
    /**
     * @description Determines if the product is a Lease based on Purchase Option
     * @param ctx The pricing context
     * @return Boolean true if Lease product
     */
    public Boolean isLeaseProduct(NT_PricingContext ctx) {
        String purchaseOption = ctx.endOfTermOption;
        if (String.isBlank(purchaseOption)) {
            return false; // Unknown, assume not lease
        }
        return LEASE_PURCHASE_OPTIONS.contains(purchaseOption);
    }
    
    /**
     * @description Determines if the product is a Loan based on Purchase Option
     * @param ctx The pricing context
     * @return Boolean true if Loan product
     */
    public Boolean isLoanProduct(NT_PricingContext ctx) {
        String purchaseOption = ctx.endOfTermOption;
        if (String.isBlank(purchaseOption)) {
            return false;
        }
        return LOAN_PURCHASE_OPTIONS.contains(purchaseOption);
    }
    
    /**
     * @description Gets the list of missing fields for TValue
     * @param ctx The pricing context
     * @return List<String> List of missing field names
     */
    public List<String> getMissingTValueFields(NT_PricingContext ctx) {
        List<String> missingFields = new List<String>();
        isTValueReady(ctx, missingFields);
        return missingFields;
    }
    
    /**
     * @description Validates all eligibility criteria for pricing
     * @param ctx The pricing context
     * @return Boolean true if eligible for pricing
     */
    public Boolean isEligibleForPricing(NT_PricingContext ctx) {
        // Check for required parent record
        if (ctx.parentId == null) {
            return false;
        }
        
        // If Program is selected, validate constraints
        if (ctx.hasProgram && ctx.program != null) {
            NT_PricingContext validated = validateProgramConstraints(ctx);
            if (validated.hasError()) {
                return false;
            }
        }
        
        return true;
    }
}