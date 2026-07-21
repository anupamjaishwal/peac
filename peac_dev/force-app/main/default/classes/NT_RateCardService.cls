/**
 * @description Service class for evaluating Rate Card entry criteria.
 *              Uses the existing TCRE.RuleEngine pattern.
 * @author Northteq
 */
public without sharing class NT_RateCardService {

    @TestVisible private static Map<Id, Map<Id, Boolean>> mockEntryRuleResults = null;
    @TestVisible private static Map<Id, Map<Id, Boolean>> mockRowRuleResults = null;
    @TestVisible private static Map<Id, Map<Id, Boolean>> mockColumnRuleResults = null;
    // Test-only: per-term override for matching column criteria IDs, keyed by
    // the String form of Pricing_Term__c. When set, evaluateColumnCriteria
    // returns the configured set for the quote's current Pricing_Term__c,
    // emulating TCRE's per-term differentiation under unit tests.
    @TestVisible private static Map<String, Set<Id>> mockMatchingColumnCriteriaByTerm = null;
    
    /**
     * @description Evaluates Rate Card entry criteria and selects the best match
     * @param ctx The pricing context
     * @return NT_PricingContext The updated context with selected rate card
     */
    public NT_PricingContext evaluateRateCards(NT_PricingContext ctx) {
        if (ctx.eligibleRateCards.isEmpty()) {
            System.debug('No eligible Rate Cards found');
            ctx.setPricingError('No eligible Rate Cards found');
            return ctx;
        }
        
        // Evaluate entry criteria for rate cards
        Set<Id> matchingRateCardIds = evaluateEntryCriteria(ctx);
        
        if (matchingRateCardIds.isEmpty()) {
            System.debug('No Rate Cards matched entry criteria');
            ctx.setPricingError('No Rate Cards matched entry criteria');
            return ctx;
        }
        
        // Select the first matching rate card (could be enhanced with priority logic)
        for (RateCard__c rc : ctx.eligibleRateCards) {
            if (matchingRateCardIds.contains(rc.Id)) {
                ctx.selectedRateCard = rc;
                break;
            }
        }
        
        // Get the rate from the selected rate card
        if (ctx.selectedRateCard != null) {
            selectRate(ctx);
        }
        
        return ctx;
    }
    
    /**
     * @description Evaluates entry criteria using TCRE.RuleEngine
     * @param ctx The pricing context
     * @return Set<Id> IDs of Rate Cards that matched
     */
    private Set<Id> evaluateEntryCriteria(NT_PricingContext ctx) {
        System.debug('evaluateEntryCriteria');
        Set<Id> matchingRateCardIds = new Set<Id>();

        // Prepare the logic object ID for rule evaluation
        Set<Id> logicObjectIds = new Set<Id>();
        logicObjectIds.add(ctx.parentId);
        System.debug(ctx.parentId);
        System.debug(logicObjectIds);
        
        // Use TCRE.RuleEngine to evaluate Rate Card entry criteria
        TCRE.RuleEngine rateCardRE = new TCRE.RuleEngine();
        rateCardRE.logicObjectIds = logicObjectIds;
        rateCardRE.ruleObjectType = 'RateCard__c';
        rateCardRE.logicObjectType = 'Quote';
        
        try {
            Map<Id, Map<Id, Boolean>> ruleResults;
            if (mockEntryRuleResults != null) {
                ruleResults = mockEntryRuleResults;
            } else {
                rateCardRE.testRuleConditions();
                ruleResults = rateCardRE.ruleResults;
            }
            
            System.debug(ruleResults);
            
            for (Map<Id, Boolean> ruleResult : ruleResults.values()) {
                for (Id ruleConfigId : ruleResult.keySet()) {
                    if (ruleResult.get(ruleConfigId) == true) {
                        for (RateCard__c rc : ctx.eligibleRateCards) {
                            Id criteriaId = ctx.isQuote() ? rc.Quote_Entry_Config__c : rc.Entry_Criteria__c;
                            if (criteriaId == ruleConfigId) {
                                matchingRateCardIds.add(rc.Id);
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            ctx.setError('Error evaluating Rate Card criteria: ' + e.getMessage());
        }
        
        return matchingRateCardIds;
    }
    
    /**
     * @description Selects the appropriate rate from the Rate Card based on row/column criteria.
     *              For Quotes with multiple terms, iterates per-term using the Pricing_Term__c
     *              proxy field so TCRE can evaluate each term individually.
     *              For Opportunities, evaluates once (unchanged behavior).
     * @param ctx The pricing context
     */
    private void selectRate(NT_PricingContext ctx) {
        Set<Id> matchingRowIds = evaluateRowCriteria(ctx);
        
        if (ctx.isQuote() && ctx.requestedTerms != null && !ctx.requestedTerms.isEmpty()) {
            selectRatePerTerm(ctx, matchingRowIds);
        } else {
            selectRateSingle(ctx, matchingRowIds);
        }
    }
    
    /**
     * @description Per-term rate selection for Quotes. Sets Pricing_Term__c to each term,
     *              runs TCRE column evaluation, and stores a TermPricingResult per term.
     * @param ctx The pricing context (must be Quote)
     * @param matchingRowIds Row criteria IDs that matched
     */
    private void selectRatePerTerm(NT_PricingContext ctx, Set<Id> matchingRowIds) {
        System.debug('selectRatePerTerm');

        // SAL-6441 — "solve for financed amount" path: the user supplied a Requested Payment Amount
        // instead of a Financed Amount, so Total_Financed_Amount__c is null and no amount-tiered row
        // can match. Resolve the amount (and its tier/rate) from the payment instead.
        if (ctx.financedAmount == null && ctx.monthlyPayment != null && ctx.monthlyPayment > 0) {
            solveRatePerTermFromPayment(ctx);
            return;
        }

        Decimal rateCardBaseRate = ctx.selectedRateCard.Base_Rate__c != null ? ctx.selectedRateCard.Base_Rate__c : 0;
        Boolean isFirst = true;
        List<Decimal> skippedTerms = new List<Decimal>();
        // Iterate a snapshot so we can safely prune ctx.requestedTerms afterward
        List<Decimal> termsToEvaluate = new List<Decimal>(ctx.requestedTerms);
        
        try {
            for (Decimal term : termsToEvaluate) {
                System.debug('term: ' + term);
                // Set the proxy field so TCRE evaluates this single term
                ctx.quote.Pricing_Term__c = String.valueOf(term.intValue());
                update ctx.quote;
                
                Set<Id> matchingColumnIds = evaluateColumnCriteria(ctx);
                System.debug('matchingColumnIds: ' + matchingColumnIds);

                if (matchingColumnIds.isEmpty()) {
                    System.debug('Skipping term ' + term + ': no matching column on Rate Card ' + ctx.selectedRateCard.Name);
                    skippedTerms.add(term);
                    continue;
                }

                List<Rate_Card_Rate__c> rates = [
                    SELECT Id, Rate__c, Rate_Card_Column__c, Rate_Card_Row__c,
                           Rate_Card_Column__r.Name, Rate_Card_Column__r.Residual__c
                    FROM Rate_Card_Rate__c
                    WHERE Rate_Card_Row__r.Rate_Card__c = :ctx.selectedRateCard.Id
                    AND Rate_Card_Row__r.Quote_Row_Criteria__c IN :matchingRowIds
                    AND Rate_Card_Column__r.Quote_Column_Criteria__c IN :matchingColumnIds
                    ORDER BY Rate_Card_Column__r.Order__c
                    LIMIT 1
                ];
                System.debug('rates: ' + rates);

                if (rates.isEmpty()) {
                    System.debug('Skipping term ' + term + ': no rate at row+column intersection on Rate Card ' + ctx.selectedRateCard.Name);
                    skippedTerms.add(term);
                    continue;
                }

                NT_PricingContext.TermPricingResult tpr = buildTermResult(
                    term, rates, rateCardBaseRate, ctx
                );
                ctx.termPricingResults.put(term, tpr);
                
                // Populate top-level ctx fields from the first resolved term for backward compatibility
                if (isFirst) {
                    ctx.selectedRate = tpr.selectedRate;
                    ctx.baseRate = tpr.baseRate;
                    ctx.finalRate = tpr.finalRate;
                    if (tpr.baseRateFactor != null) {
                        ctx.baseRateFactor = tpr.baseRateFactor;
                        ctx.finalRateFactor = tpr.finalRateFactor;
                    }
                    if (tpr.baseResidual != null) {
                        ctx.baseResidual = tpr.baseResidual;
                        ctx.finalResidual = tpr.finalResidual;
                    }
                    isFirst = false;
                }
            }
        } finally {
            // Always clear the proxy field
            ctx.quote.Pricing_Term__c = null;
            update ctx.quote;
        }

        // Prune skipped terms so downstream TValue combinations aren't built for them
        if (!skippedTerms.isEmpty() && ctx.requestedTerms != null) {
            Set<Decimal> skipSet = new Set<Decimal>(skippedTerms);
            List<Decimal> keptTerms = new List<Decimal>();
            for (Decimal t : ctx.requestedTerms) {
                if (!skipSet.contains(t)) {
                    keptTerms.add(t);
                }
            }
            ctx.requestedTerms = keptTerms;
            System.debug('Skipped terms (not offered by Rate Card ' + ctx.selectedRateCard.Name + '): ' + skippedTerms);
        }
        
        if (ctx.termPricingResults.isEmpty()) {
            ctx.setPricingError('No requested term could be priced on selected Rate Card: ' + ctx.selectedRateCard.Name);
        }
        
        if (ctx.finalResidual == null && ctx.baseResidual != null) {
            ctx.finalResidual = ctx.baseResidual;
        }
    }
    
    /**
     * @description Builds a TermPricingResult from a non-empty rate query result.
     *              Callers must guard against empty `rates` and skip/error on their own.
     * @param term The term being evaluated
     * @param rates The rates found at the row/column intersection (must be non-empty)
     * @param rateCardBaseRate The rate card's base rate
     * @param ctx The pricing context
     * @return NT_PricingContext.TermPricingResult The result for this term
     */
    private NT_PricingContext.TermPricingResult buildTermResult(
        Decimal term,
        List<Rate_Card_Rate__c> rates,
        Decimal rateCardBaseRate,
        NT_PricingContext ctx
    ) {
        NT_PricingContext.TermPricingResult tpr = new NT_PricingContext.TermPricingResult();
        tpr.term = term;

        tpr.selectedRate = rates[0];
        tpr.baseRate = rateCardBaseRate + rates[0].Rate__c;
        tpr.finalRate = rateCardBaseRate + rates[0].Rate__c;

        if (ctx.selectedRateCard.Rate_Card_Type__c == 'Rate Factor') {
            tpr.baseRateFactor = rateCardBaseRate;
            tpr.finalRateFactor = rateCardBaseRate;
        }

        if (rates[0].Rate_Card_Column__r.Residual__c != null) {
            tpr.baseResidual = rates[0].Rate_Card_Column__r.Residual__c;
            tpr.finalResidual = rates[0].Rate_Card_Column__r.Residual__c;
        }

        return tpr;
    }
    
    /**
     * @description Original single-pass rate selection. Used for Opportunities and
     *              Quotes with no requestedTerms (backward-compatible path).
     * @param ctx The pricing context
     * @param matchingRowIds Row criteria IDs that matched
     */
    private void selectRateSingle(NT_PricingContext ctx, Set<Id> matchingRowIds) {
        Set<Id> matchingColumnIds = evaluateColumnCriteria(ctx);
        
        List<Rate_Card_Rate__c> rates;
        if (ctx.isQuote()) {
            rates = [
                SELECT Id, Rate__c, Rate_Card_Column__c, Rate_Card_Row__c,
                       Rate_Card_Column__r.Name, Rate_Card_Column__r.Residual__c
                FROM Rate_Card_Rate__c
                WHERE Rate_Card_Row__r.Rate_Card__c = :ctx.selectedRateCard.Id
                AND Rate_Card_Row__r.Quote_Row_Criteria__c IN :matchingRowIds
                AND Rate_Card_Column__r.Quote_Column_Criteria__c IN :matchingColumnIds
                ORDER BY Rate_Card_Column__r.Order__c
                LIMIT 1
            ];
        } else {
            rates = [
                SELECT Id, Rate__c, Rate_Card_Column__c, Rate_Card_Row__c,
                       Rate_Card_Column__r.Name, Rate_Card_Column__r.Residual__c
                FROM Rate_Card_Rate__c
                WHERE Rate_Card_Row__r.Rate_Card__c = :ctx.selectedRateCard.Id
                AND Rate_Card_Row__r.Row_Criteria__c IN :matchingRowIds
                AND Rate_Card_Column__r.Column_Criteria__c IN :matchingColumnIds
                ORDER BY Rate_Card_Column__r.Order__c
                LIMIT 1
            ];
        }
        
        Decimal rateCardBaseRate = ctx.selectedRateCard.Base_Rate__c != null ? ctx.selectedRateCard.Base_Rate__c : 0;

        System.debug('rates: ' + rates);

        if (!rates.isEmpty()) {
            ctx.selectedRate = rates[0];
            ctx.baseRate = rateCardBaseRate + rates[0].Rate__c;
            ctx.finalRate = rateCardBaseRate + rates[0].Rate__c;
            
            if (ctx.selectedRateCard.Rate_Card_Type__c == 'Rate Factor') {
                ctx.baseRateFactor = rateCardBaseRate;
                ctx.finalRateFactor = rateCardBaseRate;
            }
            
            if (rates[0].Rate_Card_Column__r.Residual__c != null) {
                ctx.baseResidual = rates[0].Rate_Card_Column__r.Residual__c;
                ctx.finalResidual = rates[0].Rate_Card_Column__r.Residual__c;
            }
        } else {
            System.debug('no rates found');
            ctx.setPricingError(
                'No rate found for selected Rate Card: ' + ctx.selectedRateCard.Name +
                ' (no row+column match for the current criteria)'
            );
        }

        if (ctx.finalResidual == null && ctx.baseResidual != null) {
            ctx.finalResidual = ctx.baseResidual;
        }
    }
    
    /**
     * @description Evaluates Row criteria using TCRE.RuleEngine
     * @param ctx The pricing context
     * @return Set<Id> IDs of matching row criteria (Rule Config IDs)
     */
    private Set<Id> evaluateRowCriteria(NT_PricingContext ctx) {
        Set<Id> matchingRowCriteriaIds = new Set<Id>();
        Boolean useQuoteField = ctx.isQuote();
        
        // Get all row criteria IDs for this rate card
        Set<Id> rowCriteriaIds = new Set<Id>();
        for (Rate_Card_Row__c row : [
            SELECT Id, Row_Criteria__c, Quote_Row_Criteria__c
            FROM Rate_Card_Row__c 
            WHERE Rate_Card__c = :ctx.selectedRateCard.Id
        ]) {
            Id criteriaId = useQuoteField ? row.Quote_Row_Criteria__c : row.Row_Criteria__c;
            if (criteriaId != null) {
                rowCriteriaIds.add(criteriaId);
            }
        }
        
        // Use TCRE.RuleEngine to evaluate row criteria
        Set<Id> logicObjectIds = new Set<Id>();
        logicObjectIds.add(ctx.parentId);
        
        TCRE.RuleEngine rowRE = new TCRE.RuleEngine();
        rowRE.logicObjectIds = logicObjectIds;
        rowRE.ruleConfigIds = rowCriteriaIds;
        rowRE.ruleObjectType = 'Rate_Card_Row__c';
        
        try {
            Map<Id, Map<Id, Boolean>> ruleResults;
            if (mockRowRuleResults != null) {
                ruleResults = mockRowRuleResults;
            } else {
                rowRE.testRuleConditions();
                ruleResults = rowRE.ruleResults;
            }

            for (Map<Id, Boolean> ruleResult : ruleResults.values()) {
                for (Id ruleConfigId : ruleResult.keySet()) {
                    if (ruleResult.get(ruleConfigId) == true) {
                        System.debug('Matching row criteria: ' + ruleConfigId);
                        matchingRowCriteriaIds.add(ruleConfigId);
                    }
                }
            }
        } catch (Exception e) {
            // Log error but continue
            System.debug('Error evaluating row criteria: ' + e.getMessage());
        }
        
        return matchingRowCriteriaIds;
    }
    
    /**
     * @description Evaluates Column criteria using TCRE.RuleEngine
     * @param ctx The pricing context
     * @return Set<Id> IDs of matching column criteria (Rule Config IDs)
     */
    private Set<Id> evaluateColumnCriteria(NT_PricingContext ctx) {
        Set<Id> matchingColumnCriteriaIds = new Set<Id>();
        Boolean useQuoteField = ctx.isQuote();

        // Test hook: return a configured matching-set based on current Pricing_Term__c
        if (mockMatchingColumnCriteriaByTerm != null && ctx.quote != null) {
            String currentTerm = ctx.quote.Pricing_Term__c;
            Set<Id> perTerm = mockMatchingColumnCriteriaByTerm.get(currentTerm);
            return perTerm != null ? perTerm : new Set<Id>();
        }

        // Get all column criteria IDs for this rate card
        Set<Id> columnCriteriaIds = new Set<Id>();
        for (Rate_Card_Column__c col : [
            SELECT Id, Column_Criteria__c, Quote_Column_Criteria__c
            FROM Rate_Card_Column__c 
            WHERE Rate_Card__c = :ctx.selectedRateCard.Id
        ]) {
            Id criteriaId = useQuoteField ? col.Quote_Column_Criteria__c : col.Column_Criteria__c;
            if (criteriaId != null) {
                columnCriteriaIds.add(criteriaId);
            }
        }
        
        // Use TCRE.RuleEngine to evaluate column criteria
        Set<Id> logicObjectIds = new Set<Id>();
        logicObjectIds.add(ctx.parentId);
        
        TCRE.RuleEngine colRE = new TCRE.RuleEngine();
        colRE.logicObjectIds = logicObjectIds;
        colRE.ruleConfigIds = columnCriteriaIds;
        colRE.ruleObjectType = 'Rate_Card_Column__c';
        
        try {
            Map<Id, Map<Id, Boolean>> ruleResults;
            if (mockColumnRuleResults != null) {
                ruleResults = mockColumnRuleResults;
            } else {
                colRE.testRuleConditions();
                ruleResults = colRE.ruleResults;
            }

            for (Map<Id, Boolean> ruleResult : ruleResults.values()) {
                for (Id ruleConfigId : ruleResult.keySet()) {
                    if (ruleResult.get(ruleConfigId) == true) {
                        matchingColumnCriteriaIds.add(ruleConfigId);
                    }
                }
            }
        } catch (Exception e) {
            // Log error but continue
            System.debug('Error evaluating column criteria: ' + e.getMessage());
        }

        return matchingColumnCriteriaIds;
    }

    /**
     * @description SAL-6441 — Per-term rate selection for the "solve for financed amount" path.
     *              The rate is chosen by a financed-amount tier (Rate_Card_Row__c criteria on
     *              Quote.Total_Financed_Amount__c), which is null when the user enters a Requested
     *              Payment Amount. For each term we iterate the card's applicable tiers, invert the
     *              payment to a financed amount at that tier's rate (NT_PaymentSolveService), and
     *              keep the tier whose resulting amount actually falls inside that tier's band (the
     *              self-consistent fixed point). The solved amount is stored per-term so each
     *              TValue combination is fed a known Amount Financed and TValue solves the payment.
     * @param       ctx  The pricing context (Quote, payment path).
     */
    private void solveRatePerTermFromPayment(NT_PricingContext ctx) {
        System.debug('solveRatePerTermFromPayment');
        Decimal payment = ctx.monthlyPayment;
        Decimal rateCardBaseRate = ctx.selectedRateCard.Base_Rate__c != null ? ctx.selectedRateCard.Base_Rate__c : 0;
        Boolean isRateFactor = ctx.selectedRateCard.Rate_Card_Type__c == 'Rate Factor';
        String primaryFreq = getPrimaryFrequency(ctx);
        Decimal advancePayments = ctx.advancePayments;

        // Row bounds are on the gross Total_Financed_Amount__c; the amount we solve is what TValue
        // amortizes (net of down/buydown/subsidy). Convert net→gross for the tier membership check.
        Decimal deductions = 0;
        if (ctx.downPayment != null && ctx.downPayment > 0) { deductions += ctx.downPayment; }
        if (ctx.buyDown != null && ctx.buyDown > 0) { deductions += ctx.buyDown; }
        if (ctx.subsidy != null && ctx.subsidy > 0) { deductions += ctx.subsidy; }

        List<RowTier> tiers = resolveApplicableTiers(ctx);
        if (tiers.isEmpty()) {
            ctx.setPricingError('No applicable rate tier found for selected Rate Card: ' + ctx.selectedRateCard.Name);
            return;
        }

        Boolean isFirst = true;
        List<Decimal> skippedTerms = new List<Decimal>();
        List<Decimal> termsToEvaluate = new List<Decimal>(ctx.requestedTerms);

        try {
            for (Decimal term : termsToEvaluate) {
                // Set the proxy term so TCRE column evaluation (term-based) resolves the column.
                ctx.quote.Pricing_Term__c = String.valueOf(term.intValue());
                update ctx.quote;

                Set<Id> matchingColumnIds = evaluateColumnCriteria(ctx);
                if (matchingColumnIds.isEmpty()) {
                    System.debug('Skipping term ' + term + ': no matching column');
                    skippedTerms.add(term);
                    continue;
                }

                Boolean solved = false;
                for (RowTier tier : tiers) {
                    List<Rate_Card_Rate__c> rates = [
                        SELECT Id, Rate__c, Rate_Card_Column__c, Rate_Card_Row__c,
                               Rate_Card_Column__r.Name, Rate_Card_Column__r.Residual__c
                        FROM Rate_Card_Rate__c
                        WHERE Rate_Card_Row__r.Rate_Card__c = :ctx.selectedRateCard.Id
                        AND Rate_Card_Row__r.Quote_Row_Criteria__c = :tier.criteriaId
                        AND Rate_Card_Column__r.Quote_Column_Criteria__c IN :matchingColumnIds
                        ORDER BY Rate_Card_Column__r.Order__c
                        LIMIT 1
                    ];
                    if (rates.isEmpty()) {
                        continue;
                    }

                    Decimal rowRate = rateCardBaseRate + rates[0].Rate__c;
                    Decimal residual = rates[0].Rate_Card_Column__r.Residual__c;

                    Decimal netAmount = isRateFactor
                        ? NT_PaymentSolveService.invertRateFactor(payment, rates[0].Rate__c)
                        : NT_PaymentSolveService.invertInterestRate(payment, rowRate, term, primaryFreq, residual, advancePayments);
                    if (netAmount == null || netAmount <= 0) {
                        continue;
                    }

                    // Tier bounds are on gross financed amount; add back deductions to compare.
                    Decimal grossForTier = netAmount + deductions;
                    if (!tier.contains(grossForTier)) {
                        continue; // amount produced by this tier's rate doesn't belong to this tier
                    }

                    NT_PricingContext.TermPricingResult tpr = new NT_PricingContext.TermPricingResult();
                    tpr.term = term;
                    tpr.selectedRate = rates[0];
                    tpr.baseRate = rowRate;
                    tpr.finalRate = rowRate;
                    if (isRateFactor) {
                        tpr.baseRateFactor = rateCardBaseRate;
                        tpr.finalRateFactor = rateCardBaseRate;
                    }
                    if (residual != null) {
                        tpr.baseResidual = residual;
                        tpr.finalResidual = residual;
                    }
                    tpr.financedAmount = netAmount;
                    ctx.termPricingResults.put(term, tpr);

                    // Populate top-level ctx fields from the first solved term (isTValueReady needs a
                    // finalRate). Deliberately leave ctx.financedAmount null so the per-combination
                    // solved amount is used and computeNetFinancedAmount doesn't double-deduct.
                    if (isFirst) {
                        ctx.selectedRate = rates[0];
                        ctx.baseRate = rowRate;
                        ctx.finalRate = rowRate;
                        if (isRateFactor) {
                            ctx.baseRateFactor = rateCardBaseRate;
                            ctx.finalRateFactor = rateCardBaseRate;
                        }
                        if (residual != null) {
                            ctx.baseResidual = residual;
                            ctx.finalResidual = residual;
                        }
                        isFirst = false;
                    }
                    solved = true;
                    break;
                }

                if (!solved) {
                    System.debug('Skipping term ' + term + ': no self-consistent amount tier for payment ' + payment);
                    skippedTerms.add(term);
                }
            }
        } finally {
            // Never persist the proxy term or a trial financed amount on the real Quote.
            ctx.quote.Pricing_Term__c = null;
            ctx.quote.Total_Financed_Amount__c = null;
            update ctx.quote;
        }

        // Prune terms we couldn't solve so downstream TValue combinations aren't built for them.
        if (!skippedTerms.isEmpty() && ctx.requestedTerms != null) {
            Set<Decimal> skipSet = new Set<Decimal>(skippedTerms);
            List<Decimal> keptTerms = new List<Decimal>();
            for (Decimal t : ctx.requestedTerms) {
                if (!skipSet.contains(t)) {
                    keptTerms.add(t);
                }
            }
            ctx.requestedTerms = keptTerms;
        }

        if (ctx.termPricingResults.isEmpty()) {
            ctx.setPricingError(
                'Unable to solve a financed amount for the requested payment on Rate Card: ' +
                ctx.selectedRateCard.Name + '. Please enter a Financed Amount instead.'
            );
        }

        if (ctx.finalResidual == null && ctx.baseResidual != null) {
            ctx.finalResidual = ctx.baseResidual;
        }
    }

    /**
     * @description SAL-6441 — Determines which of the selected Rate Card's rows apply to this
     *              Quote, independent of the (unknown) financed amount. Each row's criteria may mix
     *              non-amount conditions (e.g. credit tier) with a Total_Financed_Amount__c band;
     *              we read the band bounds from the row's TCRE conditions and probe a representative
     *              in-band amount so TCRE confirms the non-amount conditions also match. The Quote's
     *              Total_Financed_Amount__c is restored to null afterward.
     * @param       ctx  The pricing context.
     * @return      The applicable tiers, ordered by ascending lower bound.
     */
    private List<RowTier> resolveApplicableTiers(NT_PricingContext ctx) {
        List<Rate_Card_Row__c> rows = [
            SELECT Id, Quote_Row_Criteria__c
            FROM Rate_Card_Row__c
            WHERE Rate_Card__c = :ctx.selectedRateCard.Id
            AND Quote_Row_Criteria__c != null
        ];

        Set<Id> criteriaIds = new Set<Id>();
        for (Rate_Card_Row__c r : rows) {
            criteriaIds.add(r.Quote_Row_Criteria__c);
        }
        Map<Id, RowTier> boundsByCriteria = getRowAmountBounds(criteriaIds);

        List<RowTier> applicable = new List<RowTier>();
        try {
            for (Rate_Card_Row__c r : rows) {
                RowTier tier = boundsByCriteria.get(r.Quote_Row_Criteria__c);
                if (tier == null) {
                    tier = new RowTier();
                    tier.criteriaId = r.Quote_Row_Criteria__c;
                }
                ctx.quote.Total_Financed_Amount__c = tier.representativeValue();
                update ctx.quote;
                Set<Id> matched = evaluateRowCriteria(ctx);
                if (matched.contains(r.Quote_Row_Criteria__c)) {
                    applicable.add(tier);
                }
            }
        } finally {
            ctx.quote.Total_Financed_Amount__c = null;
            update ctx.quote;
        }

        applicable.sort();
        return applicable;
    }

    /**
     * @description SAL-6441 — Reads Total_Financed_Amount__c lower/upper bounds from each row
     *              criteria's TCRE rule conditions.
     * @param       criteriaIds  Rule Config Ids of the rows' Quote_Row_Criteria__c.
     * @return      Map of criteria Id → RowTier with parsed bounds.
     */
    private Map<Id, RowTier> getRowAmountBounds(Set<Id> criteriaIds) {
        Map<Id, RowTier> result = new Map<Id, RowTier>();
        if (criteriaIds == null || criteriaIds.isEmpty()) {
            return result;
        }
        for (TCRE__Rule_Condition__c cond : [
            SELECT TCRE__Rule_Config__c, TCRE__Operator__c, TCRE__Value__c
            FROM TCRE__Rule_Condition__c
            WHERE TCRE__Rule_Config__c IN :criteriaIds
            AND TCRE__Field_Name__c = 'Total_Financed_Amount__c'
        ]) {
            if (String.isBlank(cond.TCRE__Value__c)) {
                continue;
            }
            Decimal val;
            try {
                val = Decimal.valueOf(cond.TCRE__Value__c.trim());
            } catch (Exception e) {
                continue;
            }
            RowTier tier = result.get(cond.TCRE__Rule_Config__c);
            if (tier == null) {
                tier = new RowTier();
                tier.criteriaId = cond.TCRE__Rule_Config__c;
                result.put(cond.TCRE__Rule_Config__c, tier);
            }
            switch on cond.TCRE__Operator__c {
                when '>=' { tier.lo = val; tier.loInclusive = true; }
                when '>'  { tier.lo = val; tier.loInclusive = false; }
                when '<=' { tier.hi = val; tier.hiInclusive = true; }
                when '<'  { tier.hi = val; tier.hiInclusive = false; }
                when else { /* '=' or others: not a range bound, ignore */ }
            }
        }
        return result;
    }

    /**
     * @description Returns the primary payment frequency to use when inverting the payment.
     * @param       ctx  The pricing context.
     * @return      The first non-blank requested frequency, or 'Monthly'.
     */
    private String getPrimaryFrequency(NT_PricingContext ctx) {
        if (ctx.paymentFrequencies != null) {
            for (String f : ctx.paymentFrequencies) {
                if (String.isNotBlank(f)) {
                    return f;
                }
            }
        }
        return 'Monthly';
    }

    /**
     * @description SAL-6441 — A financed-amount tier for a Rate Card row: the row's criteria Id and
     *              its Total_Financed_Amount__c bounds. Sorts by ascending lower bound.
     */
    private class RowTier implements Comparable {
        public Id criteriaId;
        public Decimal lo;
        public Boolean loInclusive = true;
        public Decimal hi;
        public Boolean hiInclusive = false;

        // True when a (gross) financed amount falls within this tier's bounds.
        public Boolean contains(Decimal v) {
            if (v == null) {
                return false;
            }
            if (lo != null && (loInclusive ? v < lo : v <= lo)) {
                return false;
            }
            if (hi != null && (hiInclusive ? v > hi : v >= hi)) {
                return false;
            }
            return true;
        }

        // A representative in-band amount used to probe non-amount row criteria via TCRE.
        public Decimal representativeValue() {
            if (lo != null && hi != null) {
                return (lo + hi) / 2;
            }
            if (lo != null) {
                return lo + 1000;
            }
            if (hi != null) {
                return hi > 1000 ? hi - 1000 : hi / 2;
            }
            return 10000; // unbounded row (no amount condition): any positive amount works
        }

        public Integer compareTo(Object o) {
            RowTier other = (RowTier) o;
            Decimal a = (lo != null) ? lo : -1;
            Decimal b = (other.lo != null) ? other.lo : -1;
            if (a < b) { return -1; }
            if (a > b) { return 1; }
            return 0;
        }
    }
}