public with sharing class tvalueQuotePickerController {
    @AuraEnabled(cacheable=true)
    public static List<QuoteWrapper> getQuotes(String recordId) {
        List<QuoteWrapper> quoteWrapperList = new List<QuoteWrapper>();
        
        try {
            List<Quote> quotes = [
                SELECT Id, Name, Description, Total_Financed_Amount__c, Term__c, Payment__c, 
                       Advance_Payments__c, Rate__c, Deferral__c, End_of_Term_Option__c, 
                       Notes__c, CreatedDate
                FROM Quote
                //WHERE (OpportunityId = :recordId OR AccountId = :recordId)
                //ORDER BY CreatedDate DESC
            ];
            
            for (Quote q : quotes) {
                quoteWrapperList.add(new QuoteWrapper(q));
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching quotes: ' + e.getMessage());
        }
        
        return quoteWrapperList;
    }
    
    public class QuoteWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public Boolean isSelected;
        @AuraEnabled public String quoteOptionName;
        @AuraEnabled public String description;
        @AuraEnabled public Decimal financedAmount;
        @AuraEnabled public Decimal term;
        @AuraEnabled public Decimal payment;
        @AuraEnabled public Decimal advancePayments;
        @AuraEnabled public Decimal yield;
        @AuraEnabled public String deferral;
        @AuraEnabled public String endOption;
        @AuraEnabled public String notes;
        @AuraEnabled public DateTime createdDate;
        
        public QuoteWrapper(Quote q) {
            this.isSelected = false;
            this.id = q.Id;
            this.quoteOptionName = q.Name;
            this.description = q.Description;
            this.financedAmount = q.Total_Financed_Amount__c;
            this.term = q.Term__c;
            this.payment = q.Payment__c;
            this.advancePayments = q.Advance_Payments__c;
            this.yield = q.Rate__c;
            this.deferral = q.Deferral__c;
            this.endOption = q.End_of_Term_Option__c;
            this.notes = q.Notes__c;
            this.createdDate = q.CreatedDate;
            //this.quoteOption = q.Quote_Option__c;
        }
    }

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
            
            // Set Org-Wide Email Address if available
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