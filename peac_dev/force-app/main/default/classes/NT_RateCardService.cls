/**
 * @description Service class for evaluating Rate Card entry criteria.
 *              Uses the existing SL_RuleEngine pattern.
 * @author Northteq
 */
public class NT_RateCardService {
    
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
     * @description Evaluates entry criteria using SL_RuleEngine
     * @param ctx The pricing context
     * @return Set<Id> IDs of Rate Cards that matched
     */
    private Set<Id> evaluateEntryCriteria(NT_PricingContext ctx) {
        Set<Id> matchingRateCardIds = new Set<Id>();
        
        // Prepare the logic object ID for rule evaluation
        Set<Id> logicObjectIds = new Set<Id>();
        logicObjectIds.add(ctx.parentId);
        
        // Use SL_RuleEngine to evaluate Rate Card entry criteria
        SL_RuleEngine rateCardRE = new SL_RuleEngine();
        rateCardRE.logicObjectIds = logicObjectIds;
        rateCardRE.ruleObjectType = 'RateCard__c';
        
        try {
            rateCardRE.testRuleConditions();
            
            // Extract matching Rate Card IDs from results
            for (Map<Id, Boolean> ruleResult : rateCardRE.ruleResults.values()) {
                for (Id ruleConfigId : ruleResult.keySet()) {
                    if (ruleResult.get(ruleConfigId) == true) {
                        // Find the Rate Card with this Entry_Criteria__c
                        for (RateCard__c rc : ctx.eligibleRateCards) {
                            if (rc.Entry_Criteria__c == ruleConfigId) {
                                matchingRateCardIds.add(rc.Id);
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            ctx.setError('Error evaluating Rate Card criteria: ' + e.getMessage());
        }
        
        // If no rule engine results, include all rate cards without entry criteria
        if (matchingRateCardIds.isEmpty()) {
            for (RateCard__c rc : ctx.eligibleRateCards) {
                if (rc.Entry_Criteria__c == null) {
                    matchingRateCardIds.add(rc.Id);
                }
            }
        }
        
        return matchingRateCardIds;
    }
    
    /**
     * @description Selects the appropriate rate from the Rate Card based on row/column criteria
     * @param ctx The pricing context
     */
    private void selectRate(NT_PricingContext ctx) {
        // Get row criteria matches
        Set<Id> matchingRowIds = evaluateRowCriteria(ctx);
        
        // Get column criteria matches  
        Set<Id> matchingColumnIds = evaluateColumnCriteria(ctx);
        
        // Query the rate at the intersection
        List<Rate_Card_Rate__c> rates = [
            SELECT Id, Rate__c, Rate_Card_Column__c, Rate_Card_Row__c,
                   Rate_Card_Column__r.Name, Rate_Card_Column__r.Residual__c
            FROM Rate_Card_Rate__c
            WHERE Rate_Card_Row__r.Rate_Card__c = :ctx.selectedRateCard.Id
            AND Rate_Card_Row__r.Row_Criteria__c IN :matchingRowIds
            AND Rate_Card_Column__r.Column_Criteria__c IN :matchingColumnIds
            ORDER BY Rate_Card_Column__r.Order__c
            LIMIT 1
        ];
        
        if (!rates.isEmpty()) {
            ctx.selectedRate = rates[0];
            ctx.baseRate = rates[0].Rate__c;
            ctx.finalRate = rates[0].Rate__c; // Initialize final rate
            
            // Calculate base rate factor if applicable
            if (ctx.selectedRateCard.Rate_Card_Type__c == 'Rate Factor') {
                ctx.baseRateFactor = rates[0].Rate__c;
                ctx.finalRateFactor = rates[0].Rate__c;
            }
            
            // Get residual from column if available
            if (rates[0].Rate_Card_Column__r.Residual__c != null) {
                ctx.baseResidual = rates[0].Rate_Card_Column__r.Residual__c;
                ctx.finalResidual = rates[0].Rate_Card_Column__r.Residual__c;
            }
        } else {
            // Try to get any rate from the rate card if specific matching failed
            List<Rate_Card_Rate__c> fallbackRates = [
                SELECT Id, Rate__c, Rate_Card_Column__c, Rate_Card_Row__c,
                       Rate_Card_Column__r.Name, Rate_Card_Column__r.Residual__c
                FROM Rate_Card_Rate__c
                WHERE Rate_Card_Row__r.Rate_Card__c = :ctx.selectedRateCard.Id
                ORDER BY Rate_Card_Column__r.Order__c, Rate_Card_Row__r.Order__c
                LIMIT 1
            ];
            
            if (!fallbackRates.isEmpty()) {
                ctx.selectedRate = fallbackRates[0];
                ctx.baseRate = fallbackRates[0].Rate__c;
                ctx.finalRate = fallbackRates[0].Rate__c;
            } else {
                ctx.setPricingError('No rate found for selected Rate Card');
            }
        }
    }
    
    /**
     * @description Evaluates Row criteria using SL_RuleEngine
     * @param ctx The pricing context
     * @return Set<Id> IDs of matching row criteria (Rule Config IDs)
     */
    private Set<Id> evaluateRowCriteria(NT_PricingContext ctx) {
        Set<Id> matchingRowCriteriaIds = new Set<Id>();
        
        // Get all row criteria IDs for this rate card
        Set<Id> rowCriteriaIds = new Set<Id>();
        for (Rate_Card_Row__c row : [
            SELECT Id, Row_Criteria__c 
            FROM Rate_Card_Row__c 
            WHERE Rate_Card__c = :ctx.selectedRateCard.Id
            AND Row_Criteria__c != null
        ]) {
            rowCriteriaIds.add(row.Row_Criteria__c);
        }
        
        if (rowCriteriaIds.isEmpty()) {
            // No criteria, return all row criteria as matching
            for (Rate_Card_Row__c row : [
                SELECT Id, Row_Criteria__c 
                FROM Rate_Card_Row__c 
                WHERE Rate_Card__c = :ctx.selectedRateCard.Id
            ]) {
                if (row.Row_Criteria__c != null) {
                    matchingRowCriteriaIds.add(row.Row_Criteria__c);
                }
            }
            return matchingRowCriteriaIds;
        }
        
        // Use SL_RuleEngine to evaluate row criteria
        Set<Id> logicObjectIds = new Set<Id>();
        logicObjectIds.add(ctx.parentId);
        
        SL_RuleEngine rowRE = new SL_RuleEngine();
        rowRE.logicObjectIds = logicObjectIds;
        rowRE.ruleConfigIds = rowCriteriaIds;
        rowRE.ruleObjectType = 'Rate_Card_Row__c';
        
        try {
            rowRE.testRuleConditions();
            
            for (Map<Id, Boolean> ruleResult : rowRE.ruleResults.values()) {
                for (Id ruleConfigId : ruleResult.keySet()) {
                    if (ruleResult.get(ruleConfigId) == true) {
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
     * @description Evaluates Column criteria using SL_RuleEngine
     * @param ctx The pricing context
     * @return Set<Id> IDs of matching column criteria (Rule Config IDs)
     */
    private Set<Id> evaluateColumnCriteria(NT_PricingContext ctx) {
        Set<Id> matchingColumnCriteriaIds = new Set<Id>();
        
        // Get all column criteria IDs for this rate card
        Set<Id> columnCriteriaIds = new Set<Id>();
        for (Rate_Card_Column__c col : [
            SELECT Id, Column_Criteria__c 
            FROM Rate_Card_Column__c 
            WHERE Rate_Card__c = :ctx.selectedRateCard.Id
            AND Column_Criteria__c != null
        ]) {
            columnCriteriaIds.add(col.Column_Criteria__c);
        }
        
        if (columnCriteriaIds.isEmpty()) {
            // No criteria, return all column criteria as matching
            for (Rate_Card_Column__c col : [
                SELECT Id, Column_Criteria__c 
                FROM Rate_Card_Column__c 
                WHERE Rate_Card__c = :ctx.selectedRateCard.Id
            ]) {
                if (col.Column_Criteria__c != null) {
                    matchingColumnCriteriaIds.add(col.Column_Criteria__c);
                }
            }
            return matchingColumnCriteriaIds;
        }
        
        // Use SL_RuleEngine to evaluate column criteria
        Set<Id> logicObjectIds = new Set<Id>();
        logicObjectIds.add(ctx.parentId);
        
        SL_RuleEngine colRE = new SL_RuleEngine();
        colRE.logicObjectIds = logicObjectIds;
        colRE.ruleConfigIds = columnCriteriaIds;
        colRE.ruleObjectType = 'Rate_Card_Column__c';
        
        try {
            colRE.testRuleConditions();
            
            for (Map<Id, Boolean> ruleResult : colRE.ruleResults.values()) {
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