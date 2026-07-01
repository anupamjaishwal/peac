/**
 * @description Service class for evaluating and applying modifiers.
 *              Modifiers are additive/subtractive point adjustments - order does not affect results.
 * @author Northteq
 */
public without sharing class NT_ModifierService {

    @TestVisible private static Decimal testResidualOverride = null;
    @TestVisible private static Boolean forceEvaluationException = false;
    @TestVisible private static Map<Id, Map<Id, Boolean>> mockModifierRowRuleResults = null;
    @TestVisible private static Map<Id, Map<Id, Boolean>> mockModifierColumnRuleResults = null;
    
    /**
     * @description Evaluates and applies all applicable modifiers
     * @param ctx The pricing context
     * @return NT_PricingContext The updated context with applied modifiers
     */
    public NT_PricingContext applyModifiers(NT_PricingContext ctx) {
        ctx.finalResidual = ctx.baseResidual;
        
        if (ctx.eligibleModifiers.isEmpty()) {
            return ctx;
        }
        
        if (!ctx.hasSelectedRateCard()) {
            return ctx;
        }
        
        // Filter modifiers for the selected rate card
        List<Modifier__c> relevantModifiers = filterModifiersForRateCard(ctx);
        
        
        // Track cumulative adjustments
        Decimal rateAdjustment = 0;
        Decimal residualAdjustment = 0;
        
        // Evaluate and apply each modifier (additive)
        for (Modifier__c modifier : relevantModifiers) {
            try {
                if (forceEvaluationException) { throw new IllegalArgumentException('Forced test exception'); }
                if (isModifierApplicable(modifier, ctx)) {
                    // Get rate adjustment
                    Decimal modRate = getModifierRate(modifier, ctx);
                    if (modRate != null) {
                        rateAdjustment += modRate;
                    }

                    // Get residual adjustment
                    Decimal modResidual = getResidualAdjustment(modifier, ctx);
                    if (modResidual != null) {
                        residualAdjustment += modResidual;
                    }

                    ctx.appliedModifiers.add(modifier);
                    ctx.modifierRateAdjustments.put(modifier.Id, modRate != null ? modRate : 0);
                    ctx.modifierResidualAdjustments.put(modifier.Id, modResidual != null ? modResidual : 0);
                }
            } catch (Exception e) {
                // Track error and continue processing other modifiers
                System.debug('Warning: Error evaluating modifier ' + modifier.Name + ': ' + e.getMessage());
                ctx.modifierErrors.put(modifier.Id, modifier.Name + ': ' + e.getMessage());
            }
        }
        
        ctx.totalModifierRateAdjustment = rateAdjustment;
        ctx.totalModifierResidualAdjustment = residualAdjustment;

        if (ctx.finalRate != null) {
            ctx.finalRate = ctx.finalRate + rateAdjustment;
        } else if (rateAdjustment != 0) {
            ctx.finalRate = rateAdjustment;
        }
        
        if (ctx.finalRateFactor != null) {
            ctx.finalRateFactor = ctx.finalRateFactor + rateAdjustment;
        }
        
        if (ctx.finalResidual != null) {
            ctx.finalResidual = ctx.finalResidual + residualAdjustment;
        } else if (residualAdjustment != 0) {
            ctx.finalResidual = residualAdjustment;
        }
        
        // Apply the same modifier adjustments to each per-term result (Quote context)
        if (ctx.hasTermPricingResults()) {
            for (NT_PricingContext.TermPricingResult tpr : ctx.termPricingResults.values()) {
                if (tpr.finalRate != null) {
                    tpr.finalRate = tpr.finalRate + rateAdjustment;
                } else if (rateAdjustment != 0) {
                    tpr.finalRate = rateAdjustment;
                }
                
                if (tpr.finalRateFactor != null) {
                    tpr.finalRateFactor = tpr.finalRateFactor + rateAdjustment;
                }
                
                if (tpr.finalResidual != null) {
                    tpr.finalResidual = tpr.finalResidual + residualAdjustment;
                } else if (tpr.baseResidual != null) {
                    tpr.finalResidual = tpr.baseResidual + residualAdjustment;
                } else if (residualAdjustment != 0) {
                    tpr.finalResidual = residualAdjustment;
                }
            }
        }
        
        return ctx;
    }
    
    /**
     * @description Filters modifiers to only those related to the selected rate card
     * @param ctx The pricing context
     * @return List<Modifier__c> Filtered list of modifiers
     */
    private List<Modifier__c> filterModifiersForRateCard(NT_PricingContext ctx) {
        List<Modifier__c> filteredModifiers = new List<Modifier__c>();
        
        for (Modifier__c mod : ctx.eligibleModifiers) {
            if (mod.Rate_Card__c == ctx.selectedRateCard.Id) {
                filteredModifiers.add(mod);
            }
        }
        
        return filteredModifiers;
    }
    
    
    /**
     * @description Checks if a modifier is applicable based on its entry criteria
     * @param modifier The modifier to check
     * @param ctx The pricing context
     * @return Boolean true if modifier should be applied
     */
    private Boolean isModifierApplicable(Modifier__c modifier, NT_PricingContext ctx) {
        if (modifier.Modifier_Rate_Card__c == null) {
            return true;
        }

        Id entryCriteria = ctx.isQuote()
            ? modifier.Modifier_Rate_Card__r.Quote_Entry_Config__c
            : modifier.Modifier_Rate_Card__r.Entry_Criteria__c;

        if (entryCriteria == null) {
            return true;
        }

        TCRE.RuleEngine modRE = new TCRE.RuleEngine();
        modRE.logicObjectIds = new Set<Id>{ ctx.parentId };
        modRE.ruleConfigIds = new Set<Id>{ entryCriteria };
        modRE.ruleObjectType = 'RateCard__c';
        try {
            modRE.testRuleConditions();
            for (Map<Id, Boolean> ruleResult : modRE.ruleResults.values()) {
                for (Id ruleConfigId : ruleResult.keySet()) {
                    if (ruleResult.get(ruleConfigId) == true) { return true; }
                }
            }
        } catch (Exception e) {
            System.debug('Error evaluating modifier criteria: ' + e.getMessage());
            return false;
        }
        return false;
    }
    
    
    /**
     * @description Gets the rate adjustment from the modifier's rate card.
     *              Returns Base_Rate__c plus the grid rate matched by row/column criteria
     *              (e.g. credit risk score row × term column intersection).
     * @param modifier The modifier
     * @param ctx The pricing context
     * @return Decimal The rate adjustment value
     */
    private Decimal getModifierRate(Modifier__c modifier, NT_PricingContext ctx) {
        if (modifier.Modifier_Rate_Card__c == null) {
            return null;
        }
        Decimal baseRate = modifier.Modifier_Rate_Card__r.Base_Rate__c != null
            ? modifier.Modifier_Rate_Card__r.Base_Rate__c
            : 0;
        Decimal gridRate = getModifierGridRate(modifier.Modifier_Rate_Card__c, ctx);
        return baseRate + (gridRate != null ? gridRate : 0);
    }

    /**
     * @description Evaluates the modifier rate card's row/column grid to find the
     *              contextual rate adjustment (e.g. credit risk score lookup).
     * @param modRateCardId The modifier rate card Id
     * @param ctx The pricing context
     * @return Decimal The grid rate, or null if no matching row/column found
     */
    private Decimal getModifierGridRate(Id modRateCardId, NT_PricingContext ctx) {
        Boolean useQuoteField = ctx.isQuote();

        // Collect row criteria IDs for this modifier rate card
        Set<Id> rowCriteriaIds = new Set<Id>();
        for (Rate_Card_Row__c row : [
            SELECT Id, Row_Criteria__c, Quote_Row_Criteria__c
            FROM Rate_Card_Row__c
            WHERE Rate_Card__c = :modRateCardId
        ]) {
            Id criteriaId = useQuoteField ? row.Quote_Row_Criteria__c : row.Row_Criteria__c;
            if (criteriaId != null) {
                rowCriteriaIds.add(criteriaId);
            }
        }

        if (rowCriteriaIds.isEmpty()) {
            return null;
        }

        // Evaluate row criteria via TCRE
        Set<Id> matchingRowCriteriaIds = new Set<Id>();
        TCRE.RuleEngine rowRE = new TCRE.RuleEngine();
        rowRE.logicObjectIds = new Set<Id>{ ctx.parentId };
        rowRE.ruleConfigIds = rowCriteriaIds;
        rowRE.ruleObjectType = 'Rate_Card_Row__c';
        try {
            Map<Id, Map<Id, Boolean>> rowResults;
            if (mockModifierRowRuleResults != null) {
                rowResults = mockModifierRowRuleResults;
            } else {
                rowRE.testRuleConditions();
                rowResults = rowRE.ruleResults;
            }
            for (Map<Id, Boolean> ruleResult : rowResults.values()) {
                for (Id ruleConfigId : ruleResult.keySet()) {
                    if (ruleResult.get(ruleConfigId) == true) {
                        matchingRowCriteriaIds.add(ruleConfigId);
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error evaluating modifier row criteria: ' + e.getMessage());
            return null;
        }

        if (matchingRowCriteriaIds.isEmpty()) {
            return null;
        }

        // Collect column criteria IDs for this modifier rate card
        Set<Id> columnCriteriaIds = new Set<Id>();
        for (Rate_Card_Column__c col : [
            SELECT Id, Column_Criteria__c, Quote_Column_Criteria__c
            FROM Rate_Card_Column__c
            WHERE Rate_Card__c = :modRateCardId
        ]) {
            Id criteriaId = useQuoteField ? col.Quote_Column_Criteria__c : col.Column_Criteria__c;
            if (criteriaId != null) {
                columnCriteriaIds.add(criteriaId);
            }
        }

        // A modifier rate card may have a single catch-all column (e.g. "All term lengths")
        // with no criteria configured. In that case we match on row only. When column
        // criteria DO exist, we require a column match (strict, mirrors NT_RateCardService).
        Boolean hadColumnCriteria = !columnCriteriaIds.isEmpty();

        // Evaluate column criteria if any exist
        Set<Id> matchingColumnCriteriaIds = new Set<Id>();
        if (hadColumnCriteria) {
            TCRE.RuleEngine colRE = new TCRE.RuleEngine();
            colRE.logicObjectIds = new Set<Id>{ ctx.parentId };
            colRE.ruleConfigIds = columnCriteriaIds;
            colRE.ruleObjectType = 'Rate_Card_Column__c';
            try {
                Map<Id, Map<Id, Boolean>> colResults;
                if (mockModifierColumnRuleResults != null) {
                    colResults = mockModifierColumnRuleResults;
                } else {
                    colRE.testRuleConditions();
                    colResults = colRE.ruleResults;
                }
                for (Map<Id, Boolean> ruleResult : colResults.values()) {
                    for (Id ruleConfigId : ruleResult.keySet()) {
                        if (ruleResult.get(ruleConfigId) == true) {
                            matchingColumnCriteriaIds.add(ruleConfigId);
                        }
                    }
                }
            } catch (Exception e) {
                System.debug('Error evaluating modifier column criteria: ' + e.getMessage());
            }
        }

        // Column criteria existed but none matched — no valid intersection, skip this modifier's grid
        if (hadColumnCriteria && matchingColumnCriteriaIds.isEmpty()) {
            return null;
        }

        // Query Rate_Card_Rate__c at the row/column intersection
        List<Rate_Card_Rate__c> rates;
        if (matchingColumnCriteriaIds.isEmpty()) {
            // No column criteria configured — match on row only (catch-all column)
            if (useQuoteField) {
                rates = [
                    SELECT Id, Rate__c
                    FROM Rate_Card_Rate__c
                    WHERE Rate_Card_Row__r.Rate_Card__c = :modRateCardId
                    AND Rate_Card_Row__r.Quote_Row_Criteria__c IN :matchingRowCriteriaIds
                    ORDER BY Rate_Card_Column__r.Order__c
                    LIMIT 1
                ];
            } else {
                rates = [
                    SELECT Id, Rate__c
                    FROM Rate_Card_Rate__c
                    WHERE Rate_Card_Row__r.Rate_Card__c = :modRateCardId
                    AND Rate_Card_Row__r.Row_Criteria__c IN :matchingRowCriteriaIds
                    ORDER BY Rate_Card_Column__r.Order__c
                    LIMIT 1
                ];
            }
        } else {
            if (useQuoteField) {
                rates = [
                    SELECT Id, Rate__c
                    FROM Rate_Card_Rate__c
                    WHERE Rate_Card_Row__r.Rate_Card__c = :modRateCardId
                    AND Rate_Card_Row__r.Quote_Row_Criteria__c IN :matchingRowCriteriaIds
                    AND Rate_Card_Column__r.Quote_Column_Criteria__c IN :matchingColumnCriteriaIds
                    ORDER BY Rate_Card_Column__r.Order__c
                    LIMIT 1
                ];
            } else {
                rates = [
                    SELECT Id, Rate__c
                    FROM Rate_Card_Rate__c
                    WHERE Rate_Card_Row__r.Rate_Card__c = :modRateCardId
                    AND Rate_Card_Row__r.Row_Criteria__c IN :matchingRowCriteriaIds
                    AND Rate_Card_Column__r.Column_Criteria__c IN :matchingColumnCriteriaIds
                    ORDER BY Rate_Card_Column__r.Order__c
                    LIMIT 1
                ];
            }
        }

        return rates.isEmpty() ? null : rates[0].Rate__c;
    }
    
    /**
     * @description Gets the residual adjustment from the modifier
     * @param modifier The modifier
     * @param ctx The pricing context
     * @return Decimal The residual adjustment value
     */
    private Decimal getResidualAdjustment(Modifier__c modifier, NT_PricingContext ctx) {
        if (testResidualOverride != null) {
            return testResidualOverride;
        }
        // Get residual from linked Program_Residual
        if (modifier.Residual_Balloon_Table__c == null) { return null; }
        List<Program_Residual__c> residuals = [SELECT Id, Residual_Balloon_Table__r.Base_Rate__c FROM Program_Residual__c WHERE Id = :modifier.Residual_Balloon_Table__c LIMIT 1];
        if (!residuals.isEmpty() && residuals[0].Residual_Balloon_Table__r != null) {
            return residuals[0].Residual_Balloon_Table__r.Base_Rate__c;
        }
        return null;
    }
    
}