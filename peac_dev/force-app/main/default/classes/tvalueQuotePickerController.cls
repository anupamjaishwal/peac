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
     * Main method called by the LWC. Determines yield visibility and fetches quote data.
     */
    @AuraEnabled(cacheable=true)
    public static QuoteDataWrapper getQuoteData(Id recordId) {
        Boolean shouldShowYield = false;
        Id userId = UserInfo.getUserId();
        
        List<User> userList = [SELECT Contact.AccountId FROM User WHERE Id = :userId AND ContactId != null LIMIT 1];
        if (!userList.isEmpty() && userList[0].Contact.AccountId != null) {
            Account userAccount = [SELECT Show_Yield_in_Dealer_Portal__c FROM Account WHERE Id = :userList[0].Contact.AccountId LIMIT 1];
            if (userAccount.Show_Yield_in_Dealer_Portal__c) {
                shouldShowYield = true;
            }
        }

        List<QuoteWrapper> quoteWrapperList = getTValueQuotes(recordId);
        return new QuoteDataWrapper(quoteWrapperList, shouldShowYield);
    }

    /**
     * Queries for tval__TValue_Quote__c records and transforms them into the wrapper class.
     */
    private static List<QuoteWrapper> getTValueQuotes(Id recordId) {
        List<QuoteWrapper> quoteWrapperList = new List<QuoteWrapper>();
        try {
            List<tval__TValue_Quote__c> tValueQuotes;
            String baseQuery = 'SELECT Id, Name, CreatedDate, tval__Amount_Financed__c, tval__Term__c, tval__Payment_Amount__c, ' +
                               'tval__Number_of_Advanced_Payments__c, tval__Nominal_Annual_Rate__c, tval__Deferred_Payments__c, ' +
                               'tval__Purchase_Option__c, Quote__c, Quote__r.Name, Quote__r.Description, ' +
                               'Quote__r.Notes__c ' +
                               'FROM tval__TValue_Quote__c';

            if (recordId != null) {
                tValueQuotes = Database.query(baseQuery + ' WHERE Quote__c = :recordId ORDER BY CreatedDate DESC');
            } else {
                tValueQuotes = Database.query(baseQuery + ' ORDER BY CreatedDate DESC');
            }
            
            for (tval__TValue_Quote__c tq : tValueQuotes) {
                quoteWrapperList.add(new QuoteWrapper(tq));
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching TValue quotes: ' + e.getMessage());
        }
        return quoteWrapperList;
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