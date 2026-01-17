public class TC_FranchisorLockRule extends TC_LockRuleAbstract{
    
	// If in a lockable stage and user is not credit, do not allow user to add a broker
    public override void doCheck (TC_TriggerParams params) {
        
        Map <Id, Franchisor__c> newMap = (Map <Id, Franchisor__c>) params.getNewMap ();
        Map <Id, Franchisor__c> oldMap = (Map <Id, Franchisor__c>) params.getOldMap ();
        
        List <Franchisor__c> filtered = getFilteredList (params);
        Set <Id> oppIds = new Set <Id> ();
        Set <Id> accIds = new Set <Id> ();
        
        for (Franchisor__c fran : filtered) {
            oppIds.add (fran.Opportunity__c);
            accIds.add (fran.Franchisor__c);
        }
        
        if (oppIds.isEmpty () || accIds.isEmpty()) return;
        
        
        Map <Id, Account> franAccounts = getAccMap (accIds);
        

        if (!oppIds.isEmpty ()) {
            
            Map <Id, Opportunity> oppMap = getOppMap (oppIds);
        	User user = getCurrentUser ();
            if (isCreditUser(user) || alwaysExcludedFromRules (user)) return;
            
            for (Franchisor__c fran : filtered) {
                if (inLockableStage (oppMap.get (fran.Opportunity__c))
                    && !oppMap.get (fran.Opportunity__c).Loan_Record_Type__c
                    && !franAccounts.get (fran.Franchisor__c).Override_Sales_Lockdown_Restrictions__c) {
                       fran.addError ('Only Credit Users can add/update/delete a Franchisor in this stage'); 
                    }
            }
        }
        
        
    }
}