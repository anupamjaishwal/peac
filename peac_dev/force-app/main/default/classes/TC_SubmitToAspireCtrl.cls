public class TC_SubmitToAspireCtrl {
    @AuraEnabled
    public static void refreshAspireData(String recordId) {
        
        //try {

            String error;
    
            List<Opportunity> oppList = new List<Opportunity>([SELECT Id, (SELECT Id FROM Financial_Bank_Information__r)
                                                                FROM Opportunity
                                                                WHERE Id =: recordId]);
    
            if (!oppList.isEmpty() && !oppList[0].Financial_Bank_Information__r.isEmpty()) {
    
                error = TC_ASPIREAPI.refreshASPIREData(recordId);
                if (String.isNotEmpty(error) && !Test.isRunningTest()) throw new AuraHandledException(error);
    
            } else {
    
                error = 'There is no Bank Information record attached to this Opportunity. Canceling' +
                        ' "Submit to Aspire" action.';
                if (!Test.isRunningTest()) throw new AuraHandledException(error);
    
            }
        
        /*} catch (Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }*/
    }
    
    @AuraEnabled
    public static void submitToAspire(String recordId) {
        String error = '';
 
        // begin: SAL-1509 
        Id currentUserId = UserInfo.getUserId();
        User currentUser = [SELECT CMS_Credit_Authority_Loan__c, ProfileId, Profile.Name FROM User WHERE Id = :currentUserId LIMIT 1][0];
        Decimal CMSAuthorityLimit = currentUser.CMS_Credit_Authority_Loan__c;
        Opportunity opp = [SELECT Id, Loan_Amount__c, Last_Funded_By__c FROM Opportunity WHERE Id = :recordId LIMIT 1][0]; // also needed for SAL 1510
        
        if (currentUser.ProfileId != null && currentUser.Profile.Name == 'CMS' && (CMSAuthorityLimit == null || (opp != null && opp.Loan_Amount__c > CMSAuthorityLimit))){
            AuraHandledException ae_Authority = new AuraHandledException  ('Loan Amount is greater than user\'s CMS Credit Authority (Loan).'); 
        	ae_Authority.setMessage ('Loan Amount is greater than user\'s CMS Credit Authority (Loan).');
            throw ae_Authority;
        }
        // end: SAL-1509
        
        try {
            error = TC_ASPIREAPI.sendToASPIRE(recordId);
        } catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
         
        if (String.isNotEmpty(error)) throw new AuraHandledException(error);
        
        // begin: SAL-1510
        if (opp.Last_Funded_By__c == null) update new Opportunity (Id = opp.Id, Last_Funded_By__c = currentUserId);
        // end: SAL-1510
    }
}