/**
 * @description Utility class for the Pricing Orchestrator.
 *              Contains helper methods used across pricing services.
 * @author Northteq
 */
public with sharing class NT_PricingOrchestratorUtil {
    
    /**
     * @description Checks if a record Id is an Opportunity
     * @param recordId The record Id
     * @return Boolean true if Opportunity
     */
    public static Boolean isOpportunity(Id recordId) {
        return recordId != null && recordId.getSObjectType() == Opportunity.SObjectType;
    }
    
    /**
     * @description Checks if a record Id is a Quote
     * @param recordId The record Id
     * @return Boolean true if Quote
     */
    public static Boolean isQuote(Id recordId) {
        return recordId != null && recordId.getSObjectType() == Quote.SObjectType;
    }
    
    /**
     * @description Gets the parent type string for a record Id
     * @param recordId The record Id
     * @return String 'Opportunity' or 'Quote'
     */
    public static String getParentType(Id recordId) {
        if (isOpportunity(recordId)) {
            return NT_PricingContext.PARENT_TYPE_OPPORTUNITY;
        } else if (isQuote(recordId)) {
            return NT_PricingContext.PARENT_TYPE_QUOTE;
        }
        return null;
    }
    
    /**
     * @description Safely converts a Decimal to Double
     * @param value The Decimal value
     * @return Double The converted value
     */
    public static Double toDouble(Decimal value) {
        return value != null ? value.doubleValue() : null;
    }
    
    /**
     * @description Safely converts a Double to Decimal
     * @param value The Double value
     * @return Decimal The converted value
     */
    public static Decimal toDecimal(Double value) {
        return value != null ? Decimal.valueOf(value) : null;
    }
    
    /**
     * @description Calculates rate factor from yield
     * @param yield The annual yield percentage
     * @param term The term in months
     * @param deferralMonths Number of deferral months
     * @return Decimal The rate factor
     */
    public static Decimal calculateRateFactor(Decimal yield, Decimal term, Decimal deferralMonths) {
        if (yield == null || term == null || term <= 0) {
            return null;
        }
        
        Decimal deferral = deferralMonths != null ? deferralMonths : 0;
        Double monthlyRate = yield.doubleValue() / 100 / 12;
        
        if (monthlyRate == 0) {
            return 1 / term;
        }
        
        Double deferralFactor = Math.pow(1 + monthlyRate, deferral.doubleValue());
        Double termFactor = Math.pow(1 + monthlyRate, -term.doubleValue());
        
        Decimal rateFactor = Decimal.valueOf(deferralFactor * monthlyRate / (1 - termFactor));
        return rateFactor.setScale(8, RoundingMode.HALF_UP);
    }
    
    /**
     * @description Calculates monthly payment
     * @param principal The principal amount
     * @param rateFactor The rate factor
     * @param points Points percentage
     * @return Decimal The monthly payment
     */
    public static Decimal calculateMonthlyPayment(Decimal principal, Decimal rateFactor, Decimal points) {
        if (principal == null || rateFactor == null) {
            return null;
        }
        
        Decimal pointsMultiplier = 1;
        if (points != null) {
            pointsMultiplier = 1 + (points / 100);
        }
        
        Decimal payment = principal * pointsMultiplier * rateFactor;
        return payment.setScale(2, RoundingMode.HALF_UP);
    }
    
    /**
     * @description Checks if the current transaction is approaching governor limits
     * @return Boolean true if approaching limits
     */
    public static Boolean isApproachingLimits() {
        // Check CPU time (warn at 80%)
        if (Limits.getCpuTime() > Limits.getLimitCpuTime() * 0.8) {
            return true;
        }
        
        // Check SOQL queries (warn at 80%)
        if (Limits.getQueries() > Limits.getLimitQueries() * 0.8) {
            return true;
        }
        
        // Check DML statements (warn at 80%)
        if (Limits.getDmlStatements() > Limits.getLimitDmlStatements() * 0.8) {
            return true;
        }
        
        return false;
    }
}