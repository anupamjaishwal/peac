/**
 * @description Service class for creating and managing Pricing_Result__c audit records.
 *              Creates run-level and modifier-level result records.
 * @author Northteq
 */
public without sharing class NT_PricingResultService {
    
    /**
     * @description Creates the run-level Pricing_Result__c record
     * @param ctx The pricing context
     * @return Pricing_Result__c The created pricing result
     */
    public Pricing_Result__c createPricingResult(NT_PricingContext ctx) {
        System.debug('createPricingResult ctx: ' + ctx);
        Pricing_Result__c result = new Pricing_Result__c();
        
        // Set parent references
        if (ctx.isOpportunity()) {
            result.Opportunity__c = ctx.parentId;
        }
        if (ctx.quote != null) {
            result.Quote__c = ctx.quote.Id;
        }
        
        result.Base_Rate__c = ctx.baseRate;
        result.Rate_Factor__c = ctx.baseRateFactor;
        result.Residual_Amount__c = ctx.baseResidual;
        
        result.Total_Rate__c = ctx.finalRate;
        result.Total_Rate_Factor__c = ctx.finalRateFactor;
        result.Total_Residual__c = ctx.finalResidual;

        result.Base_Residual__c = ctx.baseResidual;
        result.Final_Rate__c = ctx.finalRate;
        result.Final_Rate_Factor__c = ctx.finalRateFactor;
        result.Final_Residual__c = ctx.finalResidual;

        Decimal principal = ctx.financedAmount != null ? ctx.financedAmount : 0;
        Decimal totalRatePct = ctx.finalRate != null ? ctx.finalRate : 0;
        result.Total_Amount__c = principal * (1 + totalRatePct / 100);
        
        if (ctx.selectedRateCard != null) {
            result.Rate_Card__c = ctx.selectedRateCard.Id;
        }
        if (ctx.selectedRate != null) {
            result.Rate_Card_Rate__c = ctx.selectedRate.Id;
        }

        result.Transaction_Id__c = ctx.transactionId;
        result.Status__c = 'Pending';
        result.Source__c = 'Base Rate';

        try {
            insert result;
            ctx.pricingResult = result;
        } catch (DmlException e) {
            System.debug('Failed to create Pricing Result: ' + e.getMessage());
            ctx.setError('Failed to create Pricing Result: ' + e.getMessage());
            throw e;
        }
        System.debug('createPricingResult result: ' + result.Id);
        return result;
    }
    
    
    /**
     * @description Creates one Pricing_Result__c per applied modifier
     * @param ctx The pricing context
     */
    public void createModifierResults(NT_PricingContext ctx) {
        System.debug('createModifierResults ctx: ' + ctx);
        if (ctx.appliedModifiers == null || ctx.appliedModifiers.isEmpty()) {
            return;
        }

        List<Pricing_Result__c> records = new List<Pricing_Result__c>();
        for (Modifier__c modifier : ctx.appliedModifiers) {
            Pricing_Result__c result = new Pricing_Result__c();

            if (ctx.isOpportunity()) {
                result.Opportunity__c = ctx.parentId;
            }
            if (ctx.quote != null) {
                result.Quote__c = ctx.quote.Id;
            }

            Decimal rateAdj = ctx.modifierRateAdjustments.get(modifier.Id);
            Decimal residualAdj = ctx.modifierResidualAdjustments.get(modifier.Id);
            result.Modifier__c = modifier.Id;
            result.Rate_Card__c = modifier.Rate_Card__c;
            result.Base_Rate__c = ctx.baseRate;
            result.Residual_Amount__c = ctx.baseResidual;

            Decimal baseRate = ctx.baseRate != null ? ctx.baseRate : 0;
            Decimal modRate = rateAdj != null ? rateAdj : 0;
            Decimal totalRateValue = baseRate + modRate;

            if (ctx.finalRateFactor != null) {
                result.Modified_Rate_Factor__c = rateAdj;
            } else {
                result.Modified_Rate__c = rateAdj;
            }
            result.Total_Rate__c = totalRateValue;

            Decimal principal = ctx.financedAmount != null ? ctx.financedAmount : 0;
            Decimal residualPct = residualAdj != null ? residualAdj : 0;
            Decimal residualAmt = principal * residualPct / 100;
            result.Modified_Residual_Amount__c = residualAmt;
            result.Total_Amount__c = (principal - residualAmt) * (1 + totalRateValue / 100) + residualAmt;
            result.Parent_Pricing_Result__c = ctx.pricingResult != null ? ctx.pricingResult.Id : null;
            result.Transaction_Id__c = ctx.transactionId;
            result.Status__c = 'Success';
            result.Source__c = 'Modifier';

            records.add(result);
        }

        // Create Error records for failed modifiers
        for (Id modifierId : ctx.modifierErrors.keySet()) {
            Pricing_Result__c errResult = new Pricing_Result__c();
            if (ctx.isOpportunity()) {
                errResult.Opportunity__c = ctx.parentId;
            }
            if (ctx.quote != null) {
                errResult.Quote__c = ctx.quote.Id;
            }
            errResult.Modifier__c = modifierId;
            errResult.Parent_Pricing_Result__c = ctx.pricingResult != null ? ctx.pricingResult.Id : null;
            errResult.Transaction_Id__c = ctx.transactionId;
            errResult.Status__c = 'Error';
            errResult.Source__c = 'Modifier';
            errResult.Error_Message__c = truncate(ctx.modifierErrors.get(modifierId));
            records.add(errResult);
        }

        System.debug('createModifierResults records: ' + records);
        try {
            insert records;
            ctx.modifierResults.addAll(records);
        } catch (DmlException e) {
            
            System.debug('Failed to create modifier Pricing Results: ' + e.getMessage());
        }
    }

    /**
     * @description Marks the run-level Pricing_Result__c as Error when one or more modifiers failed
     * @param ctx The pricing context
     */
    public void markModifierErrors(NT_PricingContext ctx) {
        if (ctx.pricingResult == null || ctx.modifierErrors.isEmpty()) {
            return;
        }
        ctx.pricingResult.Status__c = 'Error';
        ctx.pricingResult.Error_Message__c = truncate('One or more modifiers failed: ' + String.join(ctx.modifierErrors.values(), '; '));
        try {
            update ctx.pricingResult;
        } catch (DmlException e) {
            System.debug('Failed to mark modifier errors on Pricing Result: ' + e.getMessage());
        }
    }

    /**
     * @description Creates an error Pricing_Result__c record
     * @param ctx The pricing context
     * @return Pricing_Result__c The error result
     */
    public Pricing_Result__c createErrorResult(NT_PricingContext ctx) {
        Pricing_Result__c result = new Pricing_Result__c();
        
        // Set parent references
        if (ctx.isOpportunity()) {
            result.Opportunity__c = ctx.parentId;
        }
        if (ctx.quote != null) {
            result.Quote__c = ctx.quote.Id;
        }
        
        // Set error status and message
        result.Status__c = 'Error';
        result.Error_Message__c = truncate(ctx.errorMessage);
        
        try {
            insert result;
            ctx.pricingResult = result;
        } catch (DmlException e) {
            // Log but don't throw - this is already error handling
            System.debug('Failed to create error Pricing Result: ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * @description Creates an error result for a specific record
     * @param recordId The parent record Id
     * @param parentType The parent type ('Opportunity' or 'Quote')
     * @param errorMessage The error message
     * @return Pricing_Result__c The error result
     */
    public static Pricing_Result__c createErrorResult(Id recordId, String parentType, String errorMessage) {
        Pricing_Result__c result = new Pricing_Result__c();
        
        if (parentType == NT_PricingContext.PARENT_TYPE_OPPORTUNITY) {
            result.Opportunity__c = recordId;
        }
        
        // Set error status and message
        result.Status__c = 'Error';
        result.Error_Message__c = truncate(errorMessage);
        
        try {
            insert result;
        } catch (DmlException e) {
            System.debug('Failed to create error Pricing Result: ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * @description Updates the pricing result with final status
     * @param ctx The pricing context
     */
    public void updatePricingResult(NT_PricingContext ctx) {
        if (ctx.pricingResult == null) {
            return;
        }
        
        ctx.pricingResult.Status__c = !ctx.modifierErrors.isEmpty() ? 'Error' : mapStatus(ctx.status);
        ctx.pricingResult.Error_Message__c = truncate(ctx.errorMessage);
        
        if (ctx.selectedRateCard != null) {
            ctx.pricingResult.Rate_Card__c = ctx.selectedRateCard.Id;
        }
        if (ctx.selectedRate != null) {
            ctx.pricingResult.Rate_Card_Rate__c = ctx.selectedRate.Id;
        }
        
        try {
            update ctx.pricingResult;
        } catch (DmlException e) {
            System.debug('Failed to update Pricing Result: ' + e.getMessage());
        }
    }
    
    /**
     * @description Marks the pricing result as an error
     * @param ctx The pricing context
     */
    public void markError(NT_PricingContext ctx) {
        if (ctx.pricingResult == null) {
            return;
        }
        
        ctx.pricingResult.Status__c = 'Error';
        ctx.pricingResult.Error_Message__c = truncate(ctx.errorMessage);

        try {
            update ctx.pricingResult;
        } catch (DmlException e) {
            System.debug('Failed to mark Pricing Result as error: ' + e.getMessage());
        }
    }
    
    private static String truncate(String msg) {
        if (msg == null) return null;
        return msg.length() > 255 ? msg.left(255) : msg;
    }

    /**
     * @description Maps context status to Pricing_Result__c Status picklist
     * @param status The context status
     * @return String The mapped status value
     */
    private String mapStatus(String status) {
        if (status == NT_PricingContext.STATUS_SUCCESS) {
            return 'Success';
        } else if (status == NT_PricingContext.STATUS_ERROR) {
            return 'Error';
        } else if (status == NT_PricingContext.STATUS_PRICING_ERROR) {
            return 'Error';
        }
        return 'Pending';
    }
}