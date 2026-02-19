/**
 * @description Service class for creating and managing Pricing_Result__c audit records.
 *              Creates run-level and modifier-level result records.
 * @author Northteq
 */
public class NT_PricingResultService {
    
    /**
     * @description Creates the run-level Pricing_Result__c record
     * @param ctx The pricing context
     * @return Pricing_Result__c The created pricing result
     */
    public Pricing_Result__c createPricingResult(NT_PricingContext ctx) {
        Pricing_Result__c result = new Pricing_Result__c();
        
        // Set parent references
        if (ctx.isOpportunity()) {
            result.Opportunity__c = ctx.parentId;
        }
        if (ctx.quote != null) {
            result.Quote__c = ctx.quote.Id;
        }
        
        // Set base pricing values
        result.Base_Rate__c = ctx.baseRate;
        result.Rate_Factor__c = ctx.baseRateFactor;
        result.Residual_Amount__c = ctx.baseResidual;
        
        // Set final/modified pricing values
        result.Total_Rate__c = ctx.finalRate;
        result.Total_Rate_Factor__c = ctx.finalRateFactor;
        result.Modified_Rate__c = ctx.finalRate;
        result.Modified_Rate_Factor__c = ctx.finalRateFactor;
        result.Modified_Residual_Amount__c = ctx.finalResidual;
        result.Total_Amount__c = ctx.financedAmount;
        
        // Set rate card reference
        if (ctx.selectedRateCard != null) {
            result.Rate_Card_Rate__c = ctx.selectedRate?.Id;
        }

        try {
            insert result;
            ctx.pricingResult = result;
        } catch (DmlException e) {
            ctx.setError('Failed to create Pricing Result: ' + e.getMessage());
            throw e;
        }
        
        return result;
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
        result.Error_Message__c = ctx.errorMessage;
        
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
        result.Error_Message__c = errorMessage;
        
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
        
        ctx.pricingResult.Status__c = mapStatus(ctx.status);
        ctx.pricingResult.Error_Message__c = ctx.errorMessage;
        
        // Update final values
        ctx.pricingResult.Total_Rate__c = ctx.finalRate;
        ctx.pricingResult.Total_Rate_Factor__c = ctx.finalRateFactor;
        ctx.pricingResult.Modified_Rate__c = ctx.finalRate;
        ctx.pricingResult.Modified_Rate_Factor__c = ctx.finalRateFactor;
        ctx.pricingResult.Modified_Residual_Amount__c = ctx.finalResidual;
        
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
        ctx.pricingResult.Error_Message__c = ctx.errorMessage;

        try {
            update ctx.pricingResult;
        } catch (DmlException e) {
            System.debug('Failed to mark Pricing Result as error: ' + e.getMessage());
        }
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