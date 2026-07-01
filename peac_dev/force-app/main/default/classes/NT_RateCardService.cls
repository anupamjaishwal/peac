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
}