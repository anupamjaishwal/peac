/**
 * @description Queueable class for TValue API callout.
 *              Processes ONE frequency+term combination per execution and chains to next.
 *              This ensures each TValue call runs in a clean transaction.
 * @author Northteq
 */
public class NT_TValueQueueable implements Queueable, Database.AllowsCallouts {
    
    /**
     * @description Inner class to hold a payment frequency + term combination
     */
    public class TValueCombination {
        public String paymentFrequency;
        public Decimal term;
        
        public TValueCombination(String paymentFrequency, Decimal term) {
            this.paymentFrequency = paymentFrequency;
            this.term = term;
        }
    }
    
    private Id quoteId;
    private Id opportunityId;
    private Id templateId;
    private Id pricingResultId;
    private Decimal finalRate;
    private Decimal financedAmount;
    private List<TValueCombination> combinations;
    private Decimal advancePayments;
    private Decimal finalResidual;
    private String endOfTermOption;
    private String quoteName;
    private List<String> tvalueQuoteIds;
    
    /**
     * @description Constructor with all pricing parameters
     * @param quoteId The parent Quote Id
     * @param opportunityId The Opportunity Id
     * @param templateId The TValue Template Id
     * @param pricingResultId The Pricing_Result__c Id for error tracking
     * @param finalRate The final calculated rate
     * @param financedAmount The amount being financed
     * @param combinations List of frequency+term combinations to process
     * @param advancePayments Number of advance payments
     * @param finalResidual The final residual/balloon amount
     * @param endOfTermOption The end of term/purchase option
     * @param quoteName The base quote name for naming TValue quotes
     * @param tvalueQuoteIds Accumulated list of created TValue Quote Ids
     */
    public NT_TValueQueueable(
        Id quoteId,
        Id opportunityId,
        Id templateId,
        Id pricingResultId,
        Decimal finalRate,
        Decimal financedAmount,
        List<TValueCombination> combinations,
        Decimal advancePayments,
        Decimal finalResidual,
        String endOfTermOption,
        String quoteName,
        List<String> tvalueQuoteIds
    ) {
        this.tvalueQuoteIds = new List<String>();
        if (tvalueQuoteIds != null) {
            this.tvalueQuoteIds.addAll(tvalueQuoteIds);
        }
        this.quoteId = quoteId;
        this.opportunityId = opportunityId;
        this.templateId = templateId;
        this.pricingResultId = pricingResultId;
        this.finalRate = finalRate;
        this.financedAmount = financedAmount;
        this.combinations = combinations != null ? combinations : new List<TValueCombination>();
        this.advancePayments = advancePayments;
        this.finalResidual = finalResidual;
        this.endOfTermOption = endOfTermOption;
        this.quoteName = quoteName;
    }
    
    /**
     * @description Executes TValue calculation for ONE frequency+term combination, then chains to next
     */
    public void execute(QueueableContext context) {
        if (combinations.isEmpty()) {
            System.debug('No combinations to process');
            return;
        }
        
        // Process ONLY the first combination
        TValueCombination currentCombination = combinations.remove(0);
        
        try {
            System.debug('Processing TValue for: ' + currentCombination.paymentFrequency + ' - ' + 
                        currentCombination.term + ' mo (' + combinations.size() + ' remaining)');
            
            tval__TValue_Quote__c tvq = buildTValueQuote(currentCombination);
            List<tval.TValueServiceInv.Params> params = new List<tval.TValueServiceInv.Params>();
            params.add(new tval.TValueServiceInv.Params(tvq, 'a7FVA000000LRGX', true));
            
            // Each call to this function performs a DML operation 
            // meaning we have to make the call for each TValue quote in a separate transaction (queueable chain)
            List<tval__TValue_Quote__c> quotes = tval.TValueServiceInv.calculateQuote(params);
            if (quotes != null && !quotes.isEmpty()) {
                tvalueQuoteIds.add(quotes[0].Id);
            }   

            // Publish platform event when last combination is processed
            if (combinations.isEmpty() && quotes != null && !quotes.isEmpty()) {
                String recordId = String.isNotBlank(quoteId) ? quoteId : opportunityId;
                publishPlatformEvent(tvalueQuoteIds, recordId, 'Success');
                update new Quote(Id = quoteId, Pricing_Status__c = 'Success');
            }
            
        } catch (Exception e) {
            String recordId = String.isNotBlank(quoteId) ? quoteId : opportunityId;
            System.debug('TValue API Error for ' + currentCombination.paymentFrequency + ' - ' + 
                        currentCombination.term + ' mo: ' + e.getMessage());
            logError(e);
            publishPlatformEvent(tvalueQuoteIds, recordId, 'Error');
            return;  // Stop processing - do not chain to next combination
        }
        
        // Chain to next combination if any remain
        if (!combinations.isEmpty() && !Test.isRunningTest() && Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
            System.enqueueJob(new NT_TValueQueueable(
                quoteId,
                opportunityId,
                templateId,
                pricingResultId,
                finalRate,
                financedAmount,
                combinations,
                advancePayments,
                finalResidual,
                endOfTermOption,
                quoteName,
                tvalueQuoteIds
            ));
        }
    }

    /**
     * @description Publishes a platform event when the last combination is processed
     * @param tvalueQuoteIds List of TValue Quote Ids
     * @param recordId The record Id to publish the event for
     */
    private void publishPlatformEvent(List<String> tvalueQuoteIds, Id recordId, String status) {
        List<NT_TValue_Event__e> events = new List<NT_TValue_Event__e>();
        NT_TValue_Event__e event = new NT_TValue_Event__e(); 
        event.RecordId__c = recordId; 
        event.TvalueQuoteIds__c = String.join(tvalueQuoteIds, ';');
        event.UserId__c = UserInfo.getUserId();
        event.Status__c = status;
        events.add(event);
        List<Database.SaveResult> results = EventBus.publish(events);
        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                System.debug('Failed to publish platform event: ' + result.getErrors()[0].getMessage());
            }else{
                System.debug('Successfully published platform event');
            }
        }
    }
    
    /**
     * @description Builds a TValue Quote record for a specific frequency+term combination
     * @param combination The frequency+term combination to build for
     * @return tval__TValue_Quote__c The built TValue Quote record
     */
    private tval__TValue_Quote__c buildTValueQuote(TValueCombination combination) {
        tval__TValue_Quote__c tvq = new tval__TValue_Quote__c();
        
        // Set parent references
        tvq.Quote__c = quoteId;
        tvq.tval__Opportunity__c = opportunityId;
        
        // Set quote name with frequency and term suffix: "Quote Name - M onthly - 24 mo"
        String mappedFrequency = mapPaymentFrequency(combination.paymentFrequency);
        tvq.tval__Quote_Name__c = quoteName + ' - ' + mappedFrequency + ' - ' + combination.term.intValue() + ' mo';
        tvq.tval__Quote_Date__c = Date.today();
        
        // Set financial amounts
        tvq.tval__Quote_Amount__c = financedAmount;
        tvq.tval__Amount_Financed__c = financedAmount;
        
        // Set term
        tvq.tval__Term__c = combination.term;
        
        // Set rate
        if (finalRate != null) {
            tvq.tval__Rate__c = finalRate;
        }
        
        // Set advance payments
        if (advancePayments != null) {
            tvq.tval__Number_of_Advanced_Payments__c = advancePayments;
            tvq.tval__Payment_In_Advance__c = advancePayments > 0;
        }
        
        // Set residual/balloon
        if (finalResidual != null) {
            tvq.tval__Balloon_Payment_Amount__c = finalResidual;
        }
        
        // Set payment period based on frequency from the combination
        tvq.tval__Period__c = mappedFrequency;
        
        // Set end of term option
        if (String.isNotBlank(endOfTermOption)) {
            tvq.tval__Purchase_Option__c = endOfTermOption;
        }
        
        return tvq;
    }
    
    /**
     * @description Maps payment frequency to TValue period
     * @param frequency The payment frequency string
     * @return String The mapped TValue period
     */
    private String mapPaymentFrequency(String frequency) {
        if (String.isBlank(frequency)) {
            return 'Monthly';
        }
        
        String lowerFreq = frequency.toLowerCase();
        
        if (lowerFreq.contains('month')) {
            return 'Monthly';
        } else if (lowerFreq.contains('quarter')) {
            return 'Quarterly';
        } else if (lowerFreq.contains('semi') || lowerFreq.contains('half')) {
            return 'Semi-Annual';
        } else if (lowerFreq.contains('annual') || lowerFreq.contains('year')) {
            return 'Annual';
        } else if (lowerFreq.contains('week')) {
            return 'Weekly';
        } else if (lowerFreq.contains('daily') || lowerFreq.contains('day')) {
            return 'Daily';
        }
        
        return 'Monthly';
    }
    
    /**
     * @description Updates Pricing_Result__c with TValue error and links to Quote
     * @param e The exception to log
     */
    private void logError(Exception e) {
        System.debug('Logging TValue error to Pricing Result: ');
        System.debug(e.getMessage());
        System.debug(e.getStackTraceString());
        if (pricingResultId == null) {
            System.debug('No Pricing Result Id available to log error');
            return;
        }
        
        try {
            // Update Pricing Result with error
            Pricing_Result__c result = new Pricing_Result__c(
                Id = pricingResultId,
                Status__c = 'Error',
                Error_Message__c = 'TValue Error: ' + e.getMessage()
            );
            update result;
            
            // Update Quote Pricing_Status__c text
            if (quoteId != null) {
                Quote q = new Quote(
                    Id = quoteId,
                    Pricing_Status__c = 'Error'
                );
                update q;
            }
        } catch (DmlException dmlEx) {
            System.debug('Failed to update Pricing Result/Quote with error: ' + dmlEx.getMessage());
        }
    }
}