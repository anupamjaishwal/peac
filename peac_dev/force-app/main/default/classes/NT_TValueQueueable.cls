/**
 * @description Queueable class for TValue API callout.
 *              Processes ONE frequency+term combination per execution and chains to next.
 *              This ensures each TValue call runs in a clean transaction.
 * @author Northteq
 */
public without sharing class NT_TValueQueueable implements Queueable, Database.AllowsCallouts {

    @TestVisible private static List<tval__TValue_Quote__c> mockCalculateQuoteResult = null;
    @TestVisible private static Boolean throwCalloutException = false;
    
    /**
     * @description Inner class to hold a payment frequency + term combination
     */
    public class TValueCombination {
        public String paymentFrequency;
        public Decimal term;
        public Decimal rate;
        public Decimal residual;
        
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
    // AC Scenario 3: transactionId scopes which Pricing_Result__c records are used to create EF offers
    private String transactionId;
    private Decimal points;
    private Decimal monthlyPayment;

    /**
     * @description Constructor with all pricing parameters (Payment Amount-only callers should
     *              use the overload below that also accepts monthlyPayment). Retained for
     *              backward compatibility with existing call sites/tests.
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
     * @param transactionId The pricing transaction Id to scope Pricing_Result__c queries
     */
    // AC Scenario 3: Constructor accepts transactionId so each queueable instance carries the originating pricing transaction
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
        List<String> tvalueQuoteIds,
        String transactionId,
        Decimal points
    ) {
        this(
            quoteId, opportunityId, templateId, pricingResultId, finalRate, financedAmount,
            combinations, advancePayments, finalResidual, endOfTermOption, quoteName,
            tvalueQuoteIds, transactionId, points, null
        );
    }

    /**
     * @description Constructor with all pricing parameters, including monthlyPayment for the
     *              "solve for financed amount" path (user supplied Requested Payment Amount
     *              instead of Financed Amount).
     * @param monthlyPayment The requested payment amount, used to solve for financed amount
     *                        when financedAmount is unavailable
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
        List<String> tvalueQuoteIds,
        String transactionId,
        Decimal points,
        Decimal monthlyPayment
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
        this.transactionId = transactionId;
        this.points = points;
        this.monthlyPayment = monthlyPayment;
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

                        System.debug('tvalue templateId: ' + templateId);
            
            if (throwCalloutException) {
                throw new CalloutException('Mock callout exception');
            }
            tval__TValue_Quote__c tvq = buildTValueQuote(currentCombination);
            List<tval.TValueServiceInv.Params> params = new List<tval.TValueServiceInv.Params>();
            params.add(new tval.TValueServiceInv.Params(tvq, templateId, true));
            System.debug(params);
            List<tval__TValue_Quote__c> quotes = mockCalculateQuoteResult != null ? mockCalculateQuoteResult : tval.TValueServiceInv.calculateQuote(params);
            if (quotes != null && !quotes.isEmpty()) {
                tvalueQuoteIds.add(quotes[0].Id);
            }   

            // Publish platform event when last combination is processed
            if (combinations.isEmpty() && quotes != null && !quotes.isEmpty()) {
                String recordId = String.isNotBlank(quoteId) ? quoteId : opportunityId;
                publishPlatformEvent(tvalueQuoteIds, recordId, 'Success');
                if (quoteId != null) {
                    update new Quote(Id = quoteId, Pricing_Status__c = 'Success');
                }
                if (opportunityId != null) {
                    updateOpportunityFromTValue(quotes[0]);
                    sendPricingNotification('Pricing Complete', 'Yield, IRR, and Payment have been updated.', opportunityId);
                }
            }
            
        } catch (Exception e) {
            String recordId = String.isNotBlank(quoteId) ? quoteId : opportunityId;
            System.debug('TValue API Error for ' + currentCombination.paymentFrequency + ' - ' + 
                        currentCombination.term + ' mo: ' + e.getMessage());
            logError(e);
            publishPlatformEvent(tvalueQuoteIds, recordId, 'Error');
            if (opportunityId != null) {
                sendPricingNotification('Pricing Error', 'Please review the Pricing Results.', opportunityId);
            }
            return;
        }
        
        // AC Scenario 3: transactionId is forwarded to the next chained queueable so every instance shares the same pricing run scope
        if (!combinations.isEmpty() && !Test.isRunningTest() && Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
            System.enqueueJob(new NT_TValueQueueable(
                quoteId, opportunityId, templateId,
                pricingResultId, finalRate, financedAmount,
                combinations, advancePayments, finalResidual,
                endOfTermOption, quoteName, tvalueQuoteIds,
                transactionId, points, monthlyPayment
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
    @TestVisible
    private tval__TValue_Quote__c buildTValueQuote(TValueCombination combination) {
        tval__TValue_Quote__c tvq = new tval__TValue_Quote__c();
        
        // Set parent references
        tvq.Quote__c = quoteId;
        tvq.tval__Opportunity__c = opportunityId;
        
        // Set quote name with frequency and term suffix: "Quote Name - M onthly - 24 mo"
        String mappedFrequency = mapPaymentFrequency(combination.paymentFrequency);
        tvq.tval__Quote_Name__c = quoteName + ' - ' + mappedFrequency + ' - ' + combination.term.intValue() + ' mo';
        tvq.tval__Quote_Date__c = Date.today();
        
        // Set financial amounts. When Financed Amount is known, feed it to TValue and let it
        // solve for the payment. Otherwise (user entered Requested Payment Amount instead),
        // feed the payment and let TValue solve for the financed amount — previously this
        // branch was missing entirely, so a payment-only quote always sent Amount Financed
        // of 0/null and dropped the payment amount, which pricing could never resolve.
        if (financedAmount != null && financedAmount > 0) {
            tvq.tval__Quote_Amount__c = financedAmount;
            tvq.tval__Amount_Financed__c = financedAmount;
        } else if (monthlyPayment != null && monthlyPayment > 0) {
            tvq.tval__Payment_Amount__c = monthlyPayment;
        }
        
        // Set term
        tvq.tval__Term__c = combination.term;
        
        // Set rate: prefer per-term rate from combination, fall back to flat finalRate.
        // Add dealer points (percentage point markup) on top of the base rate.
        Decimal effectiveRate = combination.rate != null ? combination.rate : finalRate;
        if (points != null && points != 0) {
            effectiveRate = (effectiveRate != null ? effectiveRate : 0) + points;
        }
        if (effectiveRate != null) {
            tvq.tval__Rate__c = effectiveRate;
        }
        
        // Set advance payments
        if (advancePayments != null) {
            tvq.tval__Number_of_Advanced_Payments__c = advancePayments;
            tvq.tval__Payment_In_Advance__c = advancePayments > 0;
        }
        
        // Set residual/balloon: prefer per-term residual, fall back to flat finalResidual
        Decimal effectiveResidual = combination.residual != null ? combination.residual : finalResidual;
        if (effectiveResidual != null) {
            tvq.tval__Balloon_Payment_Amount__c = effectiveResidual;
        }
        
        // Set payment period based on frequency from the combination
        tvq.tval__Period__c = mappedFrequency;
        
        // Set end of term option (translate user-facing value to the one
        // TValue's calculation engine expects — see mapToTValuePurchaseOption).
        if (String.isNotBlank(endOfTermOption)) {
            tvq.tval__Purchase_Option__c = mapToTValuePurchaseOption(endOfTermOption);
        }

        return tvq;
    }

    /**
     * @description  SAL-7243 — translate the user-facing Purchase Option value
     *               (from Quote.End_of_Term_Option__c or
     *               Opportunity.Purchase_Options__c) to the value TValue's
     *               calculation engine expects on tval__Purchase_Option__c.
     *               TValue's restricted picklist accepts both "1.00 Out" and
     *               "$1.00 Buyout", but per SAL-6389/SAL-7243 the engine must
     *               receive "$1.00 Buyout" for the $1 buyout case. All other
     *               values pass through unchanged.
     * @param        userValue  The user-facing purchase option.
     * @return       The TValue-engine value to stamp on tval__Purchase_Option__c.
     */
    @TestVisible
    private static String mapToTValuePurchaseOption(String userValue) {
        if (String.isBlank(userValue)) return userValue;
        if ('1.00 Out'.equalsIgnoreCase(userValue)) return '$1.00 Buyout';
        return userValue;
    }
    
    /**
     * @description Maps payment frequency to TValue period
     * @param frequency The payment frequency string
     * @return String The mapped TValue period
     */
    @TestVisible private String mapPaymentFrequency(String frequency) {
        if (String.isBlank(frequency)) {
            return 'Monthly';
        }
        
        String lowerFreq = frequency.toLowerCase();
        
        if (lowerFreq.contains('month')) {
            return 'Monthly';
        } else if (lowerFreq.contains('quarter')) {
            return 'Quarterly';
        } else if (lowerFreq.contains('semi') || lowerFreq.contains('half')) {
            return 'Semiannual';
        } else if (lowerFreq.contains('annual') || lowerFreq.contains('year')) {
            return 'Annual';
        } else if (lowerFreq.contains('biweek') || lowerFreq.contains('bi-week')) {
            // Check biweekly before the generic 'week' branch so 'Bi-Weekly'
            // isn't silently downgraded to 'Weekly'. tval__Period__c has a
            // distinct restricted value of 'Biweekly'.
            return 'Biweekly';
        } else if (lowerFreq.contains('week')) {
            return 'Weekly';
        } else if (lowerFreq.contains('daily') || lowerFreq.contains('day')) {
            return 'Daily';
        }
        
        return 'Monthly';
    }
    
    /**
     * @description Updates Opportunity fields from the TValue Quote result.
     *              Maps Yield, Estimated IRR, Payment Amount, and sets Pricing_Status__c to Success.
     * @param tvQuote The TValue Quote returned from calculation
     */
    private void updateOpportunityFromTValue(tval__TValue_Quote__c tvQuote) {
        if (opportunityId == null || tvQuote == null) {
            return;
        }
        try {
            tval__TValue_Quote__c fullQuote = [
                SELECT Id, tval__Nominal_Annual_Rate__c, tval__Annual_Percentage_Rate__c,
                       tval__Payment_Amount__c, tval__Term__c, tval__Purchase_Option__c
                FROM tval__TValue_Quote__c
                WHERE Id = :tvQuote.Id
                LIMIT 1
            ];
            
            Opportunity opp = new Opportunity(Id = opportunityId);
            opp.Yield__c = fullQuote.tval__Nominal_Annual_Rate__c;
            opp.Estimated_IRR__c = fullQuote.tval__Nominal_Annual_Rate__c;
            opp.Payment_Amount__c = fullQuote.tval__Payment_Amount__c;
            opp.Pricing_Status__c = 'Success';
            update opp;
        } catch (Exception ex) {
            System.debug('Failed to update Opportunity from TValue: ' + ex.getMessage());
            setOpportunityPricingStatus('Error');
        }
    }
    
    /**
     * @description Sets the Pricing_Status__c field on the Opportunity.
     * @param status The status value to set (e.g. 'Error', 'Success')
     */
    private void setOpportunityPricingStatus(String status) {
        if (opportunityId == null) {
            return;
        }
        try {
            update new Opportunity(Id = opportunityId, Pricing_Status__c = status);
        } catch (DmlException ex) {
            System.debug('Failed to set Pricing_Status__c to ' + status + ': ' + ex.getMessage());
        }
    }
    
    /**
     * @description Sends a Salesforce custom bell notification to the current user.
     * @param title The notification title
     * @param body The notification body
     * @param opportunityId The Opportunity Id
     */
    public static void sendPricingNotification(String title, String body, String x_opportunityId) {
        if (x_opportunityId == null) {
            return;
        }
        try {
            CustomNotificationType notifType = [
                SELECT Id FROM CustomNotificationType
                WHERE DeveloperName = 'Pricing_Complete' LIMIT 1
            ];
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle(title);
            notification.setBody(body);
            notification.setNotificationTypeId(notifType.Id);
            notification.setTargetId(x_opportunityId);
            notification.send(new Set<String>{ UserInfo.getUserId() });
        } catch (Exception ex) {
            System.debug('Failed to send pricing notification: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Updates Pricing_Result__c with TValue error and links to Quote
     * @param e The exception to log
     */
    private static String truncate(String msg) {
        if (msg == null) return null;
        return msg.length() > 255 ? msg.left(255) : msg;
    }

    private void logError(Exception e) {
        System.debug('Logging TValue error to Pricing Result: ');
        System.debug(e.getMessage());
        System.debug(e.getStackTraceString());

        // Log to API_Log__c for integration-level traceability
        try {
            Id logRecordId = String.isNotBlank(quoteId) ? quoteId : opportunityId;
            MARLIN_IntegrationLog.addLog(
                'TValue Pricing',
                logRecordId,
                'Error',
                '',
                '',
                'TVALUE_ERROR',
                e.getMessage() + '\n' + e.getStackTraceString()
            );
            MARLIN_IntegrationLog.insertLogs();
        } catch (Exception logEx) {
            System.debug('Failed to log TValue error to API_Log__c: ' + logEx.getMessage());
        }

        if (pricingResultId == null) {
            System.debug('No Pricing Result Id available to log error');
            setOpportunityPricingStatus('Error');
            return;
        }

        try {
            Pricing_Result__c result = new Pricing_Result__c(
                Id = pricingResultId,
                Status__c = 'Error',
                Error_Message__c = truncate('TValue Error: ' + e.getMessage())
            );
            update result;

            if (quoteId != null) {
                Quote q = new Quote(
                    Id = quoteId,
                    Pricing_Status__c = 'Error'
                );
                update q;
            }

            setOpportunityPricingStatus('Error');
        } catch (DmlException dmlEx) {
            System.debug('Failed to update Pricing Result/Quote with error: ' + dmlEx.getMessage());
        }
    }
}