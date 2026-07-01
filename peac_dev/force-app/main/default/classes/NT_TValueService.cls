/**
 * @description Service class for invoking TValue calculations.
 *              Enqueues NT_TValueQueueable to run callout in a separate transaction.
 *              Supports multiple payment frequencies and terms - creates all combinations.
 * @author Northteq
 */
public without sharing class NT_TValueService {
    
    /**
     * @description Enqueues TValue calculation asynchronously.
     *              Creates all frequency × term combinations and processes via queueable chain.
     * @param ctx The pricing context
     * @param parentQuote The Quote to parent TValue Quotes to
     */
    public void invokeTValue(NT_PricingContext ctx, Quote parentQuote) {
        // Validate context
        if (ctx.hasError()) {
            return;
        }
        
        if (parentQuote == null) {
            ctx.setError('No Quote available for TValue invocation');
            return;
        }
        
        try {
            // Get Opportunity Id
            Id opportunityId = parentQuote.OpportunityId;
            if (opportunityId == null && ctx.isOpportunity()) {
                opportunityId = ctx.parentId;
            }
            
            // Build all frequency × term combinations
            List<NT_TValueQueueable.TValueCombination> combinations = buildCombinations(ctx);

            if (combinations.isEmpty()) {
                System.debug('No frequency/term combinations to process for TValue');
                return;
            }

            System.debug('Enqueueing TValue for ' + combinations.size() + ' combinations');
            for (NT_TValueQueueable.TValueCombination combo : combinations) {
                System.debug('  - ' + combo.paymentFrequency + ' / ' + combo.term + ' mo');
            }

            // Net financed amount: subtract down payment and buy-down before sending to TValue
            Decimal netFinancedAmount = ctx.financedAmount != null ? ctx.financedAmount : 0;
            if (ctx.downPayment != null && ctx.downPayment > 0) {
                netFinancedAmount -= ctx.downPayment;
            }
            if (ctx.buyDown != null && ctx.buyDown > 0) {
                netFinancedAmount -= ctx.buyDown;
            }

            // AC Scenario 3: ctx.transactionId is passed to the queueable so EF offer creation is scoped to this pricing run
            NT_TValueQueueable queueable = new NT_TValueQueueable(
                parentQuote.Id,
                opportunityId,
                ctx.templateId,
                ctx.pricingResult?.Id,
                ctx.finalRate,
                netFinancedAmount,
                combinations,
                ctx.advancePayments,
                ctx.finalResidual,
                ctx.endOfTermOption,
                parentQuote.Name,
                new List<String>(),
                ctx.transactionId,
                ctx.points
            );
            
            if (!Test.isRunningTest() && Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
                System.enqueueJob(queueable);
            } else if (Test.isRunningTest()) {
                // For tests, execute synchronously
                queueable.execute(null);
            }
            
        } catch (Exception e) {
            ctx.setError('Failed to enqueue TValue: ' + e.getMessage());
        }
    }
    
    /**
     * @description Enqueues TValue calculation for Opportunity-only context (no parent Quote).
     *              Uses Opportunity fields directly.
     * @param ctx The pricing context (must be Opportunity-based)
     */
    public void invokeTValue(NT_PricingContext ctx) {
        if (ctx.hasError()) {
            return;
        }
        
        if (!ctx.isOpportunity() || ctx.opportunity == null) {
            ctx.setError('Opportunity context required for Quote-less TValue invocation');
            return;
        }
        
        try {
            Id opportunityId = ctx.parentId;
            List<NT_TValueQueueable.TValueCombination> combinations = buildCombinations(ctx);

            if (combinations.isEmpty()) {
                System.debug('No frequency/term combinations to process for TValue');
                return;
            }

            System.debug('Enqueueing TValue (Opportunity context) for ' + combinations.size() + ' combinations');

            // Net financed amount: subtract down payment and buy-down before sending to TValue
            Decimal netFinancedAmount = ctx.financedAmount != null ? ctx.financedAmount : 0;
            if (ctx.downPayment != null && ctx.downPayment > 0) {
                netFinancedAmount -= ctx.downPayment;
            }
            if (ctx.buyDown != null && ctx.buyDown > 0) {
                netFinancedAmount -= ctx.buyDown;
            }

            // AC Scenario 3: ctx.transactionId is passed to the queueable so EF offer creation is scoped to this pricing run
            NT_TValueQueueable queueable = new NT_TValueQueueable(
                null,
                opportunityId,
                ctx.templateId,
                ctx.pricingResult?.Id,
                ctx.finalRate,
                netFinancedAmount,
                combinations,
                ctx.advancePayments,
                ctx.finalResidual,
                ctx.endOfTermOption,
                ctx.opportunity.Name,
                new List<String>(),
                ctx.transactionId,
                ctx.points
            );
            
            if (!Test.isRunningTest() && Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
                System.enqueueJob(queueable);
            } else if (Test.isRunningTest()) {
                queueable.execute(null);
            }
            
        } catch (Exception e) {
            ctx.setError('Failed to enqueue TValue: ' + e.getMessage());
        }
    }
    
    /**
     * @description Builds all frequency × term combinations for TValue processing
     * @param ctx The pricing context
     * @return List<NT_TValueQueueable.TValueCombination> List of all combinations to process
     */
    private List<NT_TValueQueueable.TValueCombination> buildCombinations(NT_PricingContext ctx) {
        List<NT_TValueQueueable.TValueCombination> combinations = new List<NT_TValueQueueable.TValueCombination>();
        
        // Get payment frequencies (with fallback to 'Monthly')
        List<String> frequencies = getPaymentFrequencies(ctx);
        
        // Get terms to process
        List<Decimal> terms = getTermsToProcess(ctx);
        
        if (frequencies.isEmpty() || terms.isEmpty()) {
            return combinations;
        }
        
        // Build the Cartesian product: frequencies × terms
        for (String frequency : frequencies) {
            for (Decimal term : terms) {
                NT_TValueQueueable.TValueCombination combo = new NT_TValueQueueable.TValueCombination(frequency, term);
                // Attach per-term rate/residual when available (Quote context)
                if (ctx.hasTermPricingResults()) {
                    NT_PricingContext.TermPricingResult tpr = ctx.termPricingResults.get(term);
                    if (tpr != null) {
                        combo.rate = tpr.finalRate;
                        combo.residual = tpr.finalResidual;
                    }
                }
                combinations.add(combo);
            }
        }
        
        return combinations;
    }
    
    /**
     * @description Gets the list of payment frequencies to process
     * @param ctx The pricing context
     * @return List<String> List of payment frequencies
     */
    private List<String> getPaymentFrequencies(NT_PricingContext ctx) {
        // If paymentFrequencies has values, use those
        if (ctx.paymentFrequencies != null && !ctx.paymentFrequencies.isEmpty()) {
            // Filter out any null or blank values
            List<String> validFrequencies = new List<String>();
            for (String freq : ctx.paymentFrequencies) {
                if (String.isNotBlank(freq)) {
                    validFrequencies.add(freq);
                }
            }
            if (!validFrequencies.isEmpty()) {
                return validFrequencies;
            }
        }
        
        // Default to Monthly if no frequencies specified
        return new List<String>{ 'Monthly' };
    }
    
    /**
     * @description Gets the list of terms to process for TValue
     * @param ctx The pricing context
     * @return List<Decimal> List of terms to process
     */
    private List<Decimal> getTermsToProcess(NT_PricingContext ctx) {
        // Return requestedTerms if available
        if (ctx.requestedTerms != null && !ctx.requestedTerms.isEmpty()) {
            return ctx.requestedTerms;
        }
        
        return new List<Decimal>();
    }
    
    
    /**
     * @description Validates that TValue can be invoked
     * @param ctx The pricing context
     * @return Boolean true if TValue can be invoked
     */
    public Boolean canInvokeTValue(NT_PricingContext ctx) {
        // Check for errors
        if (ctx.hasError()) {
            return false;
        }
        
        // Check for required data
        if (ctx.finalRate == null && ctx.finalRateFactor == null) {
            return false;
        }
        
        if (ctx.financedAmount == null || ctx.financedAmount <= 0) {
            return false;
        }
        
        return true;
    }
}