public class TC_FundingAuthoritySearchLtng {
    
	@AuraEnabled
    public static List <UserWrapper> getFundingAuthUsers(String term, Id recordId) {
        try {
            List <UserWrapper> returnList = new List <UserWrapper> ();
            List <Opportunity> opps = new List <Opportunity> ([SELECT Id, Loan_Record_Type__c, Loan_Amount__c, Equipment_Cost__c  FROM Opportunity WHERE Id = :recordId]);
            if (String.isNotBlank(term)) {
                term = '%' + term + '%';

                for (User user : [SELECT ID, CMS_Credit_Authority_Lease__c, CMS_Credit_Authority_Loan__c, Name, UserName  FROM User WHERE IsActive = true AND (Name LIKE :term OR UserName LIKE :term)]) {
                    if (!opps[0].Loan_Record_Type__c) {
                        // loan
                        if (user.CMS_Credit_Authority_Lease__c >= opps[0].Equipment_Cost__c) returnList.add (new UserWrapper (user, user.CMS_Credit_Authority_Lease__c));
                    } else {
                        // lease
                        if (user.CMS_Credit_Authority_Loan__c >= opps[0].Loan_Amount__c)returnList.add (new UserWrapper (user, user.CMS_Credit_Authority_Loan__c));
                    }
                }
            }
            
            return returnList;
            
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static void selectUser (String userJson, Id recordId) {

        try {
            UserWrapper user = (UserWrapper) JSON.deserialize(userJson, UserWrapper.class);
            
            update new Opportunity (Id = recordId, Funding_Authority_Approval_Process_User__c  = user.record.Id);
            
            
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    
    public class UserWrapper {
        @auraEnabled
        public User record;
        @auraEnabled
        public Boolean selected;
        @auraEnabled
        public Decimal authority;
        
        public UserWrapper (User record, Decimal authority) {
            this.record = record;
            this.authority = authority; 
        }
    }
}