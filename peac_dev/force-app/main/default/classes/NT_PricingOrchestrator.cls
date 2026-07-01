/**
 * @description Main orchestrator class for pricing execution.
 *              Coordinates program validation, rate card evaluation, modifier application,
 *              audit logging, and TValue API invocation.
 * @author Northteq
 */
public without sharing class NT_PricingOrchestrator {
    
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
        System.debug('runPricingOrchestrator recordIds: ' + recordIds);
        if (recordIds == null || recordIds.isEmpty()) {
            return;
        }
        
        // Determine parent type from first record
        Id firstId = recordIds[0];
        String parentType = determineParentType(firstId);
        
        // Enqueue for async processing
        Set<Id> recordIdSet = new Set<Id>(recordIds);

        // Mark all records as In Progress before enqueuing so status updates immediately
        NT_PricingOrchestrator orchestrator = new NT_PricingOrchestrator();
        for (Id recordId : recordIdSet) {
            orchestrator.markInProgress(recordId, parentType);
        }

        if (!Test.isRunningTest() && Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {

            System.enqueueJob(new NT_PricingOrchestratorQueueable(recordIdSet, parentType));
        } else {
            // Synchronous execution for tests or when queueable limit reached
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

        publishEvent(recordId, 'Starting');

        try {
            // Step 1: Load configuration
            ctx = configService.loadConfiguration(ctx);

            System.debug('ctx: ' + ctx);
            System.debug('ctx.hasError(): ' + ctx.hasError());

            if (ctx.hasError()) {
                handleError(ctx);
                return ctx;
            }

            // Lease products normally require a Program_Residual__c record, but AC
            // does not call this out as a hard gate. Uncomment if AC is updated to require it.
            //
            // ctx = validationService.validateResidualConfiguration(ctx);
            // if (ctx.hasError()) {
            //     handleError(ctx);
            //     return ctx;
            // }

            // Step 2: Evaluate Rate Cards
            ctx = rateCardService.evaluateRateCards(ctx);
            System.debug('ctx.hasError() after rateCardService: ' + ctx.hasError());
            
            // Fallback: if program rate cards yielded no match, retry with generic rate cards
            if ((ctx.hasError() || !ctx.hasSelectedRateCard()) && ctx.hasProgram) {
                System.debug('Program rate cards failed, falling back to generic rate cards');
                ctx.status = NT_PricingContext.STATUS_SUCCESS;
                ctx.errorMessage = null;
                ctx.selectedRateCard = null;
                ctx.selectedRate = null;
                ctx = configService.loadGenericFallback(ctx);
                ctx = rateCardService.evaluateRateCards(ctx);
            }
            
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

            if(ctx.hasError()) {
                handleError(ctx);
                return ctx;
            }
            
            // Step 5a: Create per-modifier Pricing Result records
            resultService.createModifierResults(ctx);
            if(ctx.hasError()) {
                handleError(ctx);
                return ctx;
            }
            // Step 5b: Mark run-level result as Error if any modifier failed
            if (!ctx.modifierErrors.isEmpty()) {
                resultService.markModifierErrors(ctx);
            }

            // Step 6: Invoke TValue asynchronously
            // Quote__c is already linked inside createPricingResult; no extra update needed.
            List<String> missingFields = new List<String>();
            if (validationService.isTValueReady(ctx, missingFields)) {
                System.debug('TValue is ready');
                Quote parentQuote = ctx.quote;
                if (parentQuote != null) {
                    tvalueService.invokeTValue(ctx, parentQuote);
                } else if (ctx.isOpportunity()) {
                    tvalueService.invokeTValue(ctx);
                }
            } else {    
                System.debug('TValue is not ready');
                ctx.setError('TValue skipped - missing fields: ' + String.join(missingFields, ', '));
                handleError(ctx);
                return ctx;
            }
            
            // Final status update
            if (ctx.hasError()) {
                resultService.markError(ctx);
            } else {
                resultService.updatePricingResult(ctx);
            }
            
            // Update Quote with Pricing_Status__c lookup for status tracking
            updatePricingStatus(ctx);
            
        } catch (Exception e) {
            System.debug('Unexpected error: ' + e.getMessage());
            ctx.setError('Unexpected error: ' + e.getMessage());
            handleException(ctx, e);
        }
        
        return ctx;
    }
    
    /**
     * @description Sets Pricing_Status__c = 'In Progress' on the Opportunity or Quote
     * @param recordId The record Id
     * @param parentType 'Opportunity' or 'Quote'
     */
    private void markInProgress(Id recordId, String parentType) {
        try {
            if (NT_PricingContext.PARENT_TYPE_OPPORTUNITY.equals(parentType)) {
                update new Opportunity(Id = recordId, Pricing_Status__c = 'In Progress');
            } else if (NT_PricingContext.PARENT_TYPE_QUOTE.equals(parentType)) {
                update new Quote(Id = recordId, Pricing_Status__c = 'In Progress');
            }
        } catch (DmlException e) {
            System.debug('Failed to set Pricing_Status__c to In Progress: ' + e.getMessage());
        }
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
        updatePricingStatus(ctx);

        publishEvent(ctx.quote != null ? ctx.quote.Id : ctx.parentId, 'Error');
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
        updatePricingStatus(ctx);

        publishEvent(ctx.quote != null ? ctx.quote.Id : ctx.parentId, 'Error');
    }

    private static void publishEvent(Id recordId, String status) {
        try {
            NT_TValue_Event__e event = new NT_TValue_Event__e();
            event.RecordId__c = recordId;
            event.Status__c = status;
            event.UserId__c = UserInfo.getUserId();
            List<Database.SaveResult> results = EventBus.publish(new List<NT_TValue_Event__e>{ event });
            for (Database.SaveResult result : results) {
                if (!result.isSuccess()) {
                    System.debug('Failed to publish pricing event (' + status + '): ' + result.getErrors()[0].getMessage());
                }
            }
        } catch (Exception e) {
            System.debug('Error publishing pricing event (' + status + '): ' + e.getMessage());
        }
    }
    
    /**
     * @description Updates Quote or Opportunity with Pricing_Status__c text
     * @param ctx The pricing context
     */
    private void updatePricingStatus(NT_PricingContext ctx) {
        if (ctx.pricingResult == null) {
            return;
        }
        
        String status;
        if (!ctx.hasError()) {
            status = 'Success';
        } else if (NT_PricingContext.STATUS_PRICING_ERROR.equals(ctx.status)) {
            status = 'Pricing Error';
        } else {
            status = 'Error';
        }
        
        try {
            if (ctx.quote != null) {
                ctx.quote.Pricing_Status__c = status;
                update ctx.quote;
                
            } else if (ctx.isOpportunity() && ctx.opportunity != null) {
                ctx.opportunity.Pricing_Status__c = status;
                update ctx.opportunity;
                
                if (status == 'Success') {
                    PEAC_LeaseFieldsTrackingHandler.clearLeasePricingTracking(
                        new Set<Id>{ ctx.opportunity.Id }
                    );
                } else {
                    NT_TValueQueueable.sendPricingNotification(status, 'Please review the Pricing Results.', ctx.opportunity.Id);
                }
            }
        } catch (Exception e) {
            System.debug('Failed to update Pricing Status: ' + e.getMessage());
            if(ctx.isOpportunity() && ctx.opportunity != null) {
                NT_TValueQueueable.sendPricingNotification('Error', e.getMessage(), ctx.opportunity.Id);
            } else if(ctx.quote != null) {
                NT_TValueQueueable.sendPricingNotification('Error', e.getMessage(), ctx.quote.Id);
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