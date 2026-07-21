/**
 * @description Data wrapper class for pricing state.
 *              Holds all context needed throughout the pricing orchestration process.
 * @author Northteq
 */
public without sharing class NT_PricingContext {
    
    // Parent record information
    public Id parentId { get; set; }
    public String parentType { get; set; } // 'Opportunity' or 'Quote'
    public Opportunity opportunity { get; set; }
    public Quote quote { get; set; }
    
    // Program configuration
    public Id programId { get; set; }
    public Program__c program { get; set; }
    public Boolean hasProgram { get; set; }
    
    // Rate Card configuration
    public List<RateCard__c> eligibleRateCards { get; set; }
    public RateCard__c selectedRateCard { get; set; }
    public Rate_Card_Rate__c selectedRate { get; set; }
    public Decimal baseRate { get; set; }
    public Decimal baseRateFactor { get; set; }
    
    // Residual configuration
    public List<Program_Residual__c> programResiduals { get; set; }
    public Decimal baseResidual { get; set; }
    
    // Modifier configuration
    public List<Modifier__c> eligibleModifiers { get; set; }
    public List<Modifier__c> appliedModifiers { get; set; }
    public Map<Id, Decimal> modifierRateAdjustments { get; set; }    // modifier Id → rate adjustment
    public Map<Id, Decimal> modifierResidualAdjustments { get; set; } // modifier Id → residual adjustment
    public Map<Id, String> modifierErrors { get; set; }               // modifier Id → error message
    public Decimal totalModifierRateAdjustment { get; set; }
    public Decimal totalModifierResidualAdjustment { get; set; }
    
    // Final calculated values
    public Decimal finalRate { get; set; }
    public Decimal finalRateFactor { get; set; }
    public Decimal finalResidual { get; set; }
    public Decimal monthlyPayment { get; set; }
    
    // Pricing inputs
    public List<Decimal> requestedTerms { get; set; }    // Multiple terms from Requested_Term__c
    public Decimal financedAmount { get; set; }
    public Decimal equipmentCost { get; set; }
    public Decimal points { get; set; }
    public Decimal downPayment { get; set; }
    public Decimal buyDown { get; set; }
    public Decimal subsidy { get; set; }
    public Decimal advancePayments { get; set; }
    public List<String> paymentFrequencies { get; set; }
    public String endOfTermOption { get; set; }
    public String equipmentType { get; set; }
    
    // Transaction tracking
    public String transactionId { get; set; }

    // TValue configuration
    public Id templateId { get; set; }
    
    // Audit and status
    public Pricing_Result__c pricingResult { get; set; }
    public List<Pricing_Result__c> modifierResults { get; set; }
    public String status { get; set; } // 'Success', 'Error', 'Pricing Error'
    public String errorMessage { get; set; }
    
    // Per-term pricing results (Quote context only)
    public Map<Decimal, TermPricingResult> termPricingResults { get; set; }
    
    // Constants
    public static final String PARENT_TYPE_OPPORTUNITY = 'Opportunity';
    public static final String PARENT_TYPE_QUOTE = 'Quote';
    public static final String STATUS_SUCCESS = 'Success';
    public static final String STATUS_ERROR = 'Error';
    public static final String STATUS_PRICING_ERROR = 'Pricing Error';
    
    /**
     * @description Default constructor
     */
    public NT_PricingContext() {
        this.eligibleRateCards = new List<RateCard__c>();
        this.programResiduals = new List<Program_Residual__c>();
        this.eligibleModifiers = new List<Modifier__c>();
        this.appliedModifiers = new List<Modifier__c>();
        this.modifierRateAdjustments = new Map<Id, Decimal>();
        this.modifierResidualAdjustments = new Map<Id, Decimal>();
        this.modifierErrors = new Map<Id, String>();
        this.modifierResults = new List<Pricing_Result__c>();
        this.requestedTerms = new List<Decimal>();
        this.paymentFrequencies = new List<String>();
        this.termPricingResults = new Map<Decimal, TermPricingResult>();
        this.transactionId = UUID.randomUUID().toString();
        this.hasProgram = false;
        this.status = STATUS_SUCCESS;
    }
    
    /**
     * @description Constructor with parent Id
     * @param parentId The Opportunity or Quote Id
     */
    public NT_PricingContext(Id parentId) {
        this();
        this.parentId = parentId;
        this.parentType = determineParentType(parentId);
    }
    
    /**
     * @description Determines the parent type based on the record Id
     * @param recordId The record Id to check
     * @return String 'Opportunity' or 'Quote'
     */
    private String determineParentType(Id recordId) {
        if (recordId == null) {
            return null;
        }
        String sObjType = recordId.getSObjectType().getDescribe().getName();
   
        if (sObjType == 'Opportunity') {
            return PARENT_TYPE_OPPORTUNITY;
        } else if (sObjType == 'Quote') {
            return PARENT_TYPE_QUOTE;
        }
        return null;
    }
    
    /**
     * @description Checks if parent is an Opportunity
     * @return Boolean true if parent is Opportunity
     */
    public Boolean isOpportunity() {
        return PARENT_TYPE_OPPORTUNITY.equals(this.parentType);
    }
    
    /**
     * @description Checks if parent is a Quote
     * @return Boolean true if parent is Quote
     */
    public Boolean isQuote() {
        return PARENT_TYPE_QUOTE.equals(this.parentType);
    }
    
    /**
     * @description Marks the context as having an error
     * @param message The error message
     */
    public void setError(String message) {
        this.status = STATUS_ERROR;
        this.errorMessage = message;
    }
    
    /**
     * @description Marks the context as having a pricing error
     * @param message The error message
     */
    public void setPricingError(String message) {
        this.status = STATUS_PRICING_ERROR;
        this.errorMessage = message;
    }
    
    /**
     * @description Checks if the context has any error
     * @return Boolean true if has error
     */
    public Boolean hasError() {
        return STATUS_ERROR.equals(this.status) || STATUS_PRICING_ERROR.equals(this.status);
    }
    
    /**
     * @description Checks if rate card was found and selected
     * @return Boolean true if rate card is selected
     */
    public Boolean hasSelectedRateCard() {
        return this.selectedRateCard != null;
    }
    
    /**
     * @description Checks if per-term pricing results are available (Quote context)
     * @return Boolean true if per-term results exist
     */
    public Boolean hasTermPricingResults() {
        return this.termPricingResults != null && !this.termPricingResults.isEmpty();
    }
    
    /**
     * @description Holds rate/residual data for a single term within a multi-term Quote pricing run
     */
    public class TermPricingResult {
        public Decimal term;
        public Decimal baseRate;
        public Decimal finalRate;
        public Decimal baseRateFactor;
        public Decimal finalRateFactor;
        public Decimal baseResidual;
        public Decimal finalResidual;
        public Rate_Card_Rate__c selectedRate;
        // SAL-6441 — financed amount solved from the Requested Payment Amount for this term
        // (payment-solve path only; null on the normal calculate-payment path).
        public Decimal financedAmount;
    }
}