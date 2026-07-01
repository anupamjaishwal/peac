/**
 * @description Controller for the Calculate Pricing LWC Quick Action.
 *              Validates required fields, prevents duplicate runs, and triggers
 *              the pricing orchestrator for an Opportunity.
 * @author Northteq
 */
public without sharing class NT_CalculatePricingController {

    public class PricingValidationResult {
        @AuraEnabled public Boolean isValid;
        @AuraEnabled public Boolean isInProgress;
        @AuraEnabled public List<String> missingFields;
        @AuraEnabled public String message;

        public PricingValidationResult() {
            this.isValid = false;
            this.isInProgress = false;
            this.missingFields = new List<String>();
        }
    }

    @AuraEnabled
    public static PricingValidationResult getValidationStatus(Id opportunityId) {
        PricingValidationResult result = new PricingValidationResult();

        try {
            Opportunity opp = [
                SELECT Id, Terms__c, Payment_Frequency__c,
                Equipment_Cost__c, Pricing_Status__c
                FROM Opportunity
                WHERE Id = :opportunityId
                LIMIT 1
            ];

            if (opp.Pricing_Status__c == 'In Progress') {
                result.isInProgress = true;
                result.message = 'Pricing is already in progress for this opportunity.';
                return result;
            }

            if (opp.Terms__c == null) {
                result.missingFields.add('Term');
            }
            if (String.isBlank(opp.Payment_Frequency__c)) {
                result.missingFields.add('Payment Frequency');
            }
            if (opp.Equipment_Cost__c == null || opp.Equipment_Cost__c <= 0) {
                result.missingFields.add('Equipment Cost');
            }

            if (result.missingFields.isEmpty()) {
                result.isValid = true;
                result.message = 'Ready to calculate pricing.';
            } else {
                result.message = 'Required fields are missing: ' + String.join(result.missingFields, ', ');
            }

        } catch (Exception e) {
            result.message = 'Error validating opportunity: ' + e.getMessage();
        }

        return result;
    }

    @AuraEnabled
    public static PricingValidationResult validateAndRunPricing(Id opportunityId) {
        PricingValidationResult result = getValidationStatus(opportunityId);

        if (!result.isValid) {
            return result;
        }

        try {
            NT_PricingOrchestrator.runPricingOrchestrator(new List<Id>{ opportunityId });
            result.message = 'Pricing calculation has been started. You will be notified when it completes.';
        } catch (Exception e) {
            result.isValid = false;
            result.message = 'Failed to start pricing: ' + e.getMessage();
        }

        return result;
    }
}