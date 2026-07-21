/**
 * @description Service class for invoking TValue calculations.
 *              Enqueues NT_TValueQueueable to run callout in a separate transaction.
 *              Supports multiple payment frequencies and terms - creates all combinations.
 * @author Northteq
 */
public without sharing class NT_TValueService {

    // SAL-6442 — hard ceiling on how many Quote/Offer/TValue combinations a single
    // submission can generate. Multiple quotes (one per selected term) is intended, but
    // the business caps the total at 12 (per grooming). MVP field restrictions already
    // keep the count at 6 (6 terms × Monthly); this guards future term/frequency growth.
    // If admin tuning is ever needed, source this from custom metadata instead.
    @TestVisible
    private static final Integer MAX_QUOTE_COMBINATIONS = 12;

    // SAL-7404 — captures the queueable each invokeTValue overload enqueues so tests can
    // assert the wiring (e.g. that setEndOfTermBuyOut was actually called on it).
    @TestVisible
    private static NT_TValueQueueable lastQueueable;
    
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

            // SAL-7244 — net financed amount = financed − down − buydown − subsidy
            Decimal netFinancedAmount = computeNetFinancedAmount(ctx);
            Decimal tvalueQuoteAmount = computeTValueQuoteAmount(ctx);
            Decimal pointsAmount = computePointsAmount(tvalueQuoteAmount, ctx.points);
            
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
                ctx.points,
                tvalueQuoteAmount,
                pointsAmount,
                ctx.monthlyPayment
            );
            // SAL-7404 — equipment-cost-based buyout (null unless Opportunity-originated
            // with an applied residual modifier)
            queueable.setEndOfTermBuyOut(computeModifierBuyOutAmount(ctx));
            lastQueueable = queueable;

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

            // SAL-7244 — net financed amount = financed − down − buydown − subsidy
            Decimal netFinancedAmount = computeNetFinancedAmount(ctx);
            Decimal tvalueQuoteAmount = computeTValueQuoteAmount(ctx);
            Decimal pointsAmount = computePointsAmount(tvalueQuoteAmount, ctx.points);
            
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
                ctx.points,
                tvalueQuoteAmount,
                pointsAmount,
                ctx.monthlyPayment
            );
            // SAL-7404 — equipment-cost-based buyout for the applied residual modifier
            queueable.setEndOfTermBuyOut(computeModifierBuyOutAmount(ctx));
            lastQueueable = queueable;

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
     * @description  SAL-7244 — computes the financed amount sent to TValue after
     *               the buy-down levers. Down payment, buy-down, and subsidy each
     *               reduce the financed amount the customer carries (equipment
     *               cost stays gross and is never sent to TValue). Per business:
     *               "subsidy/discount/buydown/rebate should be deducted from the
     *               financed amount." Shared by both invokeTValue overloads so the
     *               Quote (New Quote tab) and Opportunity (Calculate Pricing) paths
     *               stay consistent. Floored at 0 to avoid a negative financed amount.
     * @param        ctx  The pricing context.
     * @return       The net financed amount (gross financed − down − buydown − subsidy, min 0),
     *               or null when no financed amount was provided (Payment Amount-only path) —
     *               callers must not coerce that to 0, since 0 would incorrectly suppress the
     *               "solve for financed amount" branch in NT_TValueQueueable.buildTValueQuote.
     */
    @TestVisible
    private Decimal computeNetFinancedAmount(NT_PricingContext ctx) {
        if (ctx.financedAmount == null) {
            return null;
        }
        Decimal net = ctx.financedAmount;
        if (ctx.downPayment != null && ctx.downPayment > 0) {
            net -= ctx.downPayment;
        }
        if (ctx.buyDown != null && ctx.buyDown > 0) {
            net -= ctx.buyDown;
        }
        if (ctx.subsidy != null && ctx.subsidy > 0) {
            net -= ctx.subsidy;
        }
        if(ctx.points != null && ctx.points > 0){// SAL-7381 
            net += (ctx.financedAmount * (ctx.points / 100));
        }
        return net < 0 ? 0 : net;
    }
    
    /**
     * @description  SAL-7404 — computes the end-of-term buyout dollar amount stamped on
     *               tval__End_of_Term_Buy_Out__c: total Equipment Cost × the applied residual
     *               modifier percentage (summed across residual modifiers). Uses the same
     *               equipment-cost basis as the modifier-level
     *               Pricing_Result__c.Modified_Residual_Amount__c records, so the buyout
     *               equals the SUM of those audit rows — identical to the single row's value
     *               in the typical one-residual-modifier case. Returns null for
     *               Quote-originated runs (explicitly out of scope) and when no residual
     *               modifier applied, leaving the TValue Quote's buyout/balloon behavior
     *               unchanged from today.
     * @param        ctx  The pricing context.
     * @return       The buyout dollar amount, or null when not applicable.
     */
    @TestVisible
    private Decimal computeModifierBuyOutAmount(NT_PricingContext ctx) {
        if (!ctx.isOpportunity() || ctx.equipmentCost == null) {
            return null;
        }
        Decimal totalResidualPct = 0;
        for (Decimal adj : ctx.modifierResidualAdjustments.values()) {
            if (adj != null) {
                totalResidualPct += adj;
            }
        }
        if (totalResidualPct == 0) {
            return null;
        }
        return ctx.equipmentCost * totalResidualPct / 100;
    }

    /**
     * @description  SAL-7244 — the amount the TValue engine actually amortizes is
     *               tval__Quote_Amount__c (this value), NOT tval__Amount_Financed__c.
     *               So Buydown/Subsidy must be subtracted here, or the solved payment
     *               ignores them (the reported defect: adding/removing Buydown on the
     *               Opportunity path left the payment unchanged). Equipment Cost stays
     *               gross on the Opportunity for display — only the amount fed to the
     *               engine is reduced, matching the design note "Buydown reduces the
     *               financed amount, not the equipment cost." Down Payment is
     *               deliberately NOT subtracted here (post-MVP, SAL-7417); it must not
     *               change the payment yet, so it stays out of the amortized amount.
     * @param        ctx  The pricing context.
     * @return       The amount fed to the engine as tval__Quote_Amount__c: on the
     *               Opportunity path, Equipment Cost less Buydown and Subsidy (min 0);
     *               otherwise the context financed amount unchanged.
     */
    @TestVisible
    private Decimal computeTValueQuoteAmount(NT_PricingContext ctx) {
        if (ctx.isOpportunity() && ctx.opportunity != null && ctx.opportunity.Equipment_Cost__c != null) {
            Decimal amt = ctx.opportunity.Equipment_Cost__c;
            if (ctx.buyDown != null && ctx.buyDown > 0) {
                amt -= ctx.buyDown;
            }
            if (ctx.subsidy != null && ctx.subsidy > 0) {
                amt -= ctx.subsidy;
            }
            return amt < 0 ? 0 : amt;
        }
        return ctx.financedAmount;
    }
    @TestVisible
    private Decimal computePointsAmount(Decimal quoteAmount, Decimal points) {
        if (quoteAmount != null && points != null && points > 0) {
            return quoteAmount * (points / 100);
        }
        return 0;
    }

    /**
     * @description Builds all frequency × term combinations for TValue processing
     * @param ctx The pricing context
     * @return List<NT_TValueQueueable.TValueCombination> List of all combinations to process
     */
    @TestVisible
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
                        // SAL-6441 — carry the per-term amount solved from the Requested Payment
                        // Amount so each combination feeds TValue its own Amount Financed.
                        combo.financedAmount = tpr.financedAmount;
                    }
                }
                combinations.add(combo);
            }
        }

        // SAL-6442 — enforce the max-combinations ceiling. Keep the first N in the
        // existing deterministic order (frequency-outer, term-inner); never drop silently.
        if (combinations.size() > MAX_QUOTE_COMBINATIONS) {
            System.debug(LoggingLevel.WARN, 'NT_TValueService: capping pricing combinations from '
                + combinations.size() + ' to ' + MAX_QUOTE_COMBINATIONS);
            List<NT_TValueQueueable.TValueCombination> capped = new List<NT_TValueQueueable.TValueCombination>();
            for (Integer i = 0; i < MAX_QUOTE_COMBINATIONS; i++) {
                capped.add(combinations[i]);
            }
            combinations = capped;
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