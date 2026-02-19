/**
 * @description Service class for Quote-related operations.
 *              Note: Quote updates happen when user selects a TValue quote, not during pricing.
 *              Status is tracked via Quote.Pricing_Result__c lookup.
 * @author Northteq
 */
public class NT_QuoteService {
    
    /**
     * @description Gets the Quote from context (no updates during pricing)
     * @param ctx The pricing context
     * @return Quote The Quote record
     */
    public Quote getQuote(NT_PricingContext ctx) {
        return ctx.quote;
    }
}