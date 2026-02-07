public with sharing class tvalueQuotePickerController {

    /**
     * Wrapper class to hold flattened data for the LWC.
     */
    public class QuoteWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String quoteOptionName;
        @AuraEnabled public String description;
        @AuraEnabled public Decimal financedAmount;
        @AuraEnabled public Decimal term;
        @AuraEnabled public Decimal payment;
        @AuraEnabled public Decimal advancePayments;
        @AuraEnabled public Decimal yield;
        @AuraEnabled public Decimal deferral;
        @AuraEnabled public String endOption;
        @AuraEnabled public String notes;
        @AuraEnabled public DateTime createdDate;

        public QuoteWrapper(tval__TValue_Quote__c tq) {
            this.id = tq.Id;
            // Parent Quote fields
            this.quoteOptionName = tq.Name;
            this.description = (tq.Quote__c != null) ? tq.Quote__r.Description : '';
            this.notes = (tq.Quote__c != null) ? tq.Quote__r.Notes__c : '';
            
            // tval__TValue_Quote__c fields
            this.financedAmount = tq.tval__Amount_Financed__c;
            this.term = tq.tval__Term__c;
            this.payment = tq.tval__Payment_Amount__c;
            this.advancePayments = tq.tval__Number_of_Advanced_Payments__c;
            this.yield = tq.tval__Nominal_Annual_Rate__c;
            this.deferral = tq.tval__Deferred_Payments__c;
            this.endOption = tq.tval__Purchase_Option__c;
            this.createdDate = tq.CreatedDate;
        }
    }

    /**
     * Wrapper class to hold both the list of quotes and the yield column visibility flag.
     */
    public class QuoteDataWrapper {
        @AuraEnabled public List<QuoteWrapper> quotes { get; set; }
        @AuraEnabled public Boolean showYield { get; set; }

        public QuoteDataWrapper(List<QuoteWrapper> quotes, Boolean showYield) {
            this.quotes = quotes;
            this.showYield = showYield;
        }
    }

    /**
     * Main method called by the LWC. Determines yield visibility and fetches quote data by recordId.
     */
    @AuraEnabled(cacheable=true)
    public static QuoteDataWrapper getQuoteData(Id recordId) {
        String whereClause = recordId != null ? 'WHERE Quote__c = :recordId' : '';
        Map<String, Object> bindMap = new Map<String, Object>{'recordId' => recordId};
        return fetchQuoteData(whereClause, bindMap);
    }

    /**
     * Queries for tval__TValue_Quote__c records with dynamic WHERE clause.
     * Supports filtering by recordId or list of quote IDs.
     */
    private static QuoteDataWrapper fetchQuoteData(String whereClause, Map<String, Object> bindMap) {
        try {
            String query = 'SELECT Id, Name, CreatedDate, tval__Amount_Financed__c, tval__Term__c, tval__Payment_Amount__c, ' +
                          'tval__Number_of_Advanced_Payments__c, tval__Nominal_Annual_Rate__c, tval__Deferred_Payments__c, ' +
                          'tval__Purchase_Option__c, Quote__c, Quote__r.Name, Quote__r.Description, Quote__r.Notes__c ' +
                          'FROM tval__TValue_Quote__c';
            
            if (String.isNotBlank(whereClause)) {
                query += ' ' + whereClause;
            }
            
            query += ' ORDER BY CreatedDate DESC';
            
            List<tval__TValue_Quote__c> tValueQuotes = Database.queryWithBinds(query, bindMap, AccessLevel.USER_MODE);
            List<QuoteWrapper> quoteWrapperList = buildQuoteWrappers(tValueQuotes);
            return new QuoteDataWrapper(quoteWrapperList, shouldShowYieldColumn());
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching TValue quotes: ' + e.getMessage());
        }
    }

    /**
     * Queries for tval__TValue_Quote__c records by recordId and transforms them into the wrapper class.
     */
    private static List<QuoteWrapper> getTValueQuotes(Id recordId) {
        try {
            String query = 'SELECT Id, Name, CreatedDate, tval__Amount_Financed__c, tval__Term__c, tval__Payment_Amount__c, ' +
                          'tval__Number_of_Advanced_Payments__c, tval__Nominal_Annual_Rate__c, tval__Deferred_Payments__c, ' +
                          'tval__Purchase_Option__c, Quote__c, Quote__r.Name, Quote__r.Description, Quote__r.Notes__c ' +
                          'FROM tval__TValue_Quote__c';
            
            if (recordId != null) {
                query += ' WHERE Quote__c = :recordId';
            }
            
            query += ' ORDER BY CreatedDate DESC';
            
            List<tval__TValue_Quote__c> tValueQuotes = Database.query(query);
            return buildQuoteWrappers(tValueQuotes);
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching TValue quotes: ' + e.getMessage());
        }
    }

    /**
     * Fetches tval__TValue_Quote__c records by their IDs and returns them with yield visibility flag.
     * This method is called when the platform event NT_TValue_Event__e is received.
     */
    @AuraEnabled
    public static QuoteDataWrapper getTValueQuotesByIds(List<String> quoteIds) {
        String whereClause = 'WHERE Id IN :quoteIds';
        Map<String, Object> bindMap = new Map<String, Object>{'quoteIds' => quoteIds};
        return fetchQuoteData(whereClause, bindMap);
    }

    /**
     * Converts tval__TValue_Quote__c records to QuoteWrapper objects.
     */
    private static List<QuoteWrapper> buildQuoteWrappers(List<tval__TValue_Quote__c> tValueQuotes) {
        List<QuoteWrapper> quoteWrapperList = new List<QuoteWrapper>();
        for (tval__TValue_Quote__c tq : tValueQuotes) {
            quoteWrapperList.add(new QuoteWrapper(tq));
        }
        return quoteWrapperList;
    }

    /**
     * Determines if the current user should see the Yield column based on their Account settings.
     */
    private static Boolean shouldShowYieldColumn() {
        Id userId = UserInfo.getUserId();
        
        // Single query combining User and Account relationship
        List<User> userList = [SELECT Contact.Account.Show_Yield_in_Dealer_Portal__c 
                               FROM User 
                               WHERE Id = :userId AND Contact.AccountId != null 
                               LIMIT 1];
        
        if (!userList.isEmpty() && userList[0].Contact.Account.Show_Yield_in_Dealer_Portal__c != null) {
            return userList[0].Contact.Account.Show_Yield_in_Dealer_Portal__c;
        }
        return false;
    }

    /**
     * Sends an email using the data from the email modal LWC.
     */
    @AuraEnabled
    public static void sendEmail(String toAddress, String ccAddress, String subject, String body) {
        if (String.isBlank(toAddress)) {
            throw new AuraHandledException('To address cannot be blank.');
        }
        try {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{ toAddress });
            if (String.isNotBlank(ccAddress)) {
                mail.setCcAddresses(new List<String>{ ccAddress });
            }
            mail.setSubject(subject);
            mail.setPlainTextBody(body);
            
            List<OrgWideEmailAddress> owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply@peacsolutions.com' LIMIT 1];
            if (!owea.isEmpty()) {
                mail.setOrgWideEmailAddressId(owea[0].Id);
            }

            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        } catch (Exception e) {
            throw new AuraHandledException('Email sending failed: ' + e.getMessage());
        }
    }
}