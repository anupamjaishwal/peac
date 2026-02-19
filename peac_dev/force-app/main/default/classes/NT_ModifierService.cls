/**
 * @description Service class for evaluating and applying modifiers.
 *              Modifiers are additive/subtractive point adjustments - order does not affect results.
 * @author Northteq
 */
public class NT_ModifierService {
    
    /**
     * @description Evaluates and applies all applicable modifiers
     * @param ctx The pricing context
     * @return NT_PricingContext The updated context with applied modifiers
     */
    public NT_PricingContext applyModifiers(NT_PricingContext ctx) {
        // Initialize final values from base values
        ctx.finalRate = ctx.baseRate;
        ctx.finalRateFactor = ctx.baseRateFactor;
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
                }
            } catch (Exception e) {
                // Log warning but continue processing other modifiers
                System.debug('Warning: Error evaluating modifier ' + modifier.Name + ': ' + e.getMessage());
            }
        }
        
        // Apply cumulative adjustments
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
        // If modifier has no entry criteria on its rate card, it's always applicable
        if (modifier.Rate_Card__r == null || modifier.Rate_Card__r.Entry_Criteria__c == null) {
            return true;
        }
        
        // Evaluate the modifier's rate card entry criteria
        Set<Id> logicObjectIds = new Set<Id>();
        logicObjectIds.add(ctx.parentId);
        
        Set<Id> ruleConfigIds = new Set<Id>();
        ruleConfigIds.add(modifier.Rate_Card__r.Entry_Criteria__c);
        
        TCRE.RuleEngine modRE = new TCRE.RuleEngine();
        modRE.logicObjectIds = logicObjectIds;
        modRE.ruleConfigIds = ruleConfigIds;
        modRE.ruleObjectType = 'Modifier__c';
        
        try {
            modRE.testRuleConditions();
            
            for (Map<Id, Boolean> ruleResult : modRE.ruleResults.values()) {
                for (Id ruleConfigId : ruleResult.keySet()) {
                    if (ruleResult.get(ruleConfigId) == true) {
                        return true;
                    }
                }
            }
        } catch (Exception e) {
            // Log error but assume applicable
            System.debug('Error evaluating modifier criteria: ' + e.getMessage());
            return true;
        }
        
        return false;
    }
    
    
    /**
     * @description Gets the rate adjustment from the modifier's rate card
     * @param modifier The modifier
     * @param ctx The pricing context
     * @return Decimal The rate adjustment value
     */
    private Decimal getModifierRate(Modifier__c modifier, NT_PricingContext ctx) {
        // Query rates from the modifier's rate card
        // Use same row/column matching logic as base rate card
        List<Rate_Card_Rate__c> rates = [
            SELECT Id, Rate__c
            FROM Rate_Card_Rate__c
            WHERE Rate_Card_Row__r.Rate_Card__c = :modifier.Rate_Card__c
            ORDER BY Rate_Card_Column__r.Order__c, Rate_Card_Row__r.Order__c
            LIMIT 1
        ];
        
        if (!rates.isEmpty()) {
            return rates[0].Rate__c;
        }
        
        return null;
    }
    
    /**
     * @description Gets the residual adjustment from the modifier
     * @param modifier The modifier
     * @param ctx The pricing context
     * @return Decimal The residual adjustment value
     */
    private Decimal getResidualAdjustment(Modifier__c modifier, NT_PricingContext ctx) {
        // Get residual from linked Program_Residual
        if (modifier.Residual_Balloon_Table__c != null) {
            List<Program_Residual__c> residuals = [
                SELECT Id, Residual_Balloon_Table__r.Base_Rate__c
                FROM Program_Residual__c
                WHERE Id = :modifier.Residual_Balloon_Table__c
                LIMIT 1
            ];
            
            if (!residuals.isEmpty() && residuals[0].Residual_Balloon_Table__r != null) {
                return residuals[0].Residual_Balloon_Table__r.Base_Rate__c;
            }
        }
        
        return null;
    }
    
}