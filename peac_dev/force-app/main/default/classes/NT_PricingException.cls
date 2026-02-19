/**
 * @description Custom exception classes for the Pricing Orchestrator.
 *              Provides specific exception types for different failure scenarios.
 * @author Northteq
 */
public class NT_PricingException extends Exception {
    
    /**
     * @description Exception for validation failures (missing config, invalid data)
     */
    public class PricingValidationException extends Exception {}
    
    /**
     * @description Exception for configuration loading failures
     */
    public class PricingConfigException extends Exception {}
    
    /**
     * @description Exception for TValue integration failures
     */
    public class TValueException extends Exception {}
    
    /**
     * @description Exception for modifier evaluation failures
     */
    public class ModifierException extends Exception {}
    
    /**
     * @description Exception for rate card evaluation failures
     */
    public class RateCardException extends Exception {}
    
    /**
     * @description Exception for performance timeout
     */
    public class PerformanceTimeoutException extends Exception {}
}