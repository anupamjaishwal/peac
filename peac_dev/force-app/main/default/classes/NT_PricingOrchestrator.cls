/**
 * @description Main orchestrator class for pricing execution.
 *              Coordinates program validation, rate card evaluation, modifier application,
 *              audit logging, and TValue API invocation.
 * @author Northteq
 */
public class NT_PricingOrchestrator {
    
    // Service instances
    private NT_PricingConfigService configService;
    private NT_PricingValidationService validationService;
    private NT_RateCardService rateCardService;
    private NT_ModifierService modifierService;
    private NT_QuoteService quoteService;
    private NT_PricingResultService resultService;
    private NT_TValueService tvalueService;
    
    /**
     * @description Default constructor - initializes all services
     */
    public NT_PricingOrchestrator() {
        this.configService = new NT_PricingConfigService();
        this.validationService = new NT_PricingValidationService();
        this.rateCardService = new NT_RateCardService();
        this.modifierService = new NT_ModifierService();
        this.quoteService = new NT_QuoteService();
        this.resultService = new NT_PricingResultService();
        this.tvalueService = new NT_TValueService();
    }
    
    /**
     * @description Invocable method for Flow/Process Builder invocation
     * @param recordIds List of Opportunity or Quote Ids to process
     */
    @InvocableMethod(label='Run Pricing Orchestrator' description='Runs the pricing orchestrator for Opportunities or Quotes')
    public static void runPricingOrchestrator(List<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) {
            return;
        }
        
        // Determine parent type from first record
        Id firstId = recordIds[0];
        String parentType = determineParentType(firstId);
        
        // Enqueue for async processing
        Set<Id> recordIdSet = new Set<Id>(recordIds);
        
        if (!Test.isRunningTest() && Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
            System.enqueueJob(new NT_PricingOrchestratorQueueable(recordIdSet, parentType));
        } else {
            // Synchronous execution for tests or when queueable limit reached
            NT_PricingOrchestrator orchestrator = new NT_PricingOrchestrator();
            for (Id recordId : recordIds) {
                try {
                    orchestrator.executePricing(recordId, parentType);
                } catch (Exception e) {
                    NT_PricingResultService.createErrorResult(recordId, parentType, e.getMessage());
                }
            }
        }
    }
    
    /**
     * @description Executes pricing for a single record
     * @param recordId The Opportunity or Quote Id
     * @param parentType The parent type ('Opportunity' or 'Quote')
     * @return NT_PricingContext The completed pricing context
     */
    public NT_PricingContext executePricing(Id recordId, String parentType) {
        // Initialize context
        NT_PricingContext ctx = new NT_PricingContext(recordId);
        
        try {
            // Step 1: Load configuration
            ctx = configService.loadConfiguration(ctx);

            System.debug('ctx: ' + ctx);
            System.debug('ctx.hasError(): ' + ctx.hasError());

            if (ctx.hasError()) {
                handleError(ctx);
                return ctx;
            }
            
            // Step 2: Validate Program constraints
            ctx = validationService.validateProgramConstraints(ctx);
            System.debug('ctx.hasError() after validateProgramConstraints: ' + ctx.hasError());
            if (ctx.hasError()) {
                handleError(ctx);
                return ctx;
            }
            
            // Step 3: Evaluate Rate Cards
            ctx = rateCardService.evaluateRateCards(ctx);
            System.debug('ctx.hasError() after rateCardService: ' + ctx.hasError());
            if (ctx.hasError() || !ctx.hasSelectedRateCard()) {
                handleError(ctx);
                return ctx;
            }
            
            // Step 4: Apply Modifiers
            ctx = modifierService.applyModifiers(ctx);
            System.debug('ctx.hasError() after modifierService: ' + ctx.hasError());
            if (ctx.hasError()) {
                handleError(ctx);
                return ctx;
            }
            
            // Step 5: Create Pricing Result
            resultService.createPricingResult(ctx);
            
            // Step 6: Get Quote for TValue invocation (no updates - user selects TValue quote later)
            Quote parentQuote = ctx.quote;
            
            // Link Pricing Result to Quote if available
            if (ctx.pricingResult != null && parentQuote != null) {
                ctx.pricingResult.Quote__c = parentQuote.Id;
                update ctx.pricingResult;
            }
            
            // Step 7: Invoke TValue asynchronously to generate quote options
            if (parentQuote != null) {
                List<String> missingFields = new List<String>();
                if (validationService.isTValueReady(ctx, missingFields)) {
                    tvalueService.invokeTValue(ctx, parentQuote);
                } else {    
                    ctx.setError('TValue skipped - missing fields: ' + String.join(missingFields, ', '));
                    handleError(ctx);
                    return ctx;
                }
            }
            
            // Final status update
            if (ctx.hasError()) {
                resultService.markError(ctx);
            } else {
                resultService.updatePricingResult(ctx);
            }
            
            // Update Quote with Pricing_Status__c lookup for status tracking
            updateQuotePricingStatus(ctx);
            
        } catch (Exception e) {
            ctx.setError('Unexpected error: ' + e.getMessage());
            handleException(ctx, e);
        }
        
        return ctx;
    }
    
    /**
     * @description Handles errors during pricing execution
     * @param ctx The pricing context
     */
    private void handleError(NT_PricingContext ctx) {
        // Create error pricing result if not already created
        if (ctx.pricingResult == null) {
            resultService.createErrorResult(ctx);
        } else {
            resultService.markError(ctx);
        }
        
        // Update Quote with Pricing_Status__c lookup
        updateQuotePricingStatus(ctx);
    }
    
    /**
     * @description Handles exceptions during pricing execution
     * @param ctx The pricing context
     * @param e The exception
     */
    private void handleException(NT_PricingContext ctx, Exception e) {
        // Create error result
        if (ctx.pricingResult == null) {
            resultService.createErrorResult(ctx);
        } else {
            resultService.markError(ctx);
        }
        
        // Update Quote with Pricing_Status__c lookup
        updateQuotePricingStatus(ctx);
    }
    
    /**
     * @description Updates Quote with Pricing_Result__c lookup and Pricing_Status__c text
     * @param ctx The pricing context
     */
    private void updateQuotePricingStatus(NT_PricingContext ctx) {
        if (ctx.quote != null && ctx.pricingResult != null) {
            try {
                ctx.quote.Pricing_Status__c = ctx.hasError() ? 'Error' : 'Success';
                update ctx.quote;
            } catch (DmlException e) {
                System.debug('Failed to update Quote with Pricing Result: ' + e.getMessage());
            }
        }
    }
    
    /**
     * @description Determines parent type from record Id
     * @param recordId The record Id
     * @return String 'Opportunity' or 'Quote'
     */
    private static String determineParentType(Id recordId) {
        if (recordId == null) {
            return null;
        }
        Schema.SObjectType sObjType = recordId.getSObjectType();
        if (sObjType == Opportunity.SObjectType) {
            return NT_PricingContext.PARENT_TYPE_OPPORTUNITY;
        } else if (sObjType == Quote.SObjectType) {
            return NT_PricingContext.PARENT_TYPE_QUOTE;
        }
        return null;
    }
    
    /**
     * @description Checks if a record is eligible for pricing
     * @param recordId The record Id to check
     * @return Boolean true if eligible
     */
    public static Boolean isEligibleForPricing(Id recordId) {
        String parentType = determineParentType(recordId);
        
        if (parentType == null) {
            return false;
        }
        
        // Initialize context and load config for validation
        NT_PricingContext ctx = new NT_PricingContext(recordId);
        NT_PricingConfigService configService = new NT_PricingConfigService();
        NT_PricingValidationService validationService = new NT_PricingValidationService();
        
        try {
            ctx = configService.loadConfiguration(ctx);
            return validationService.isEligibleForPricing(ctx);
        } catch (Exception e) {
            System.debug('Error checking pricing eligibility: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Gets missing fields required for TValue invocation
     * @param recordId The record Id to check
     * @return List<String> List of missing field names, empty if ready
     */
    public static List<String> getMissingTValueFields(Id recordId) {
        NT_PricingContext ctx = new NT_PricingContext(recordId);
        NT_PricingConfigService configService = new NT_PricingConfigService();
        NT_PricingValidationService validationService = new NT_PricingValidationService();
        
        try {
            ctx = configService.loadConfiguration(ctx);
            return validationService.getMissingTValueFields(ctx);
        } catch (Exception e) {
            return new List<String>{ 'Error loading record: ' + e.getMessage() };
        }
    }
}