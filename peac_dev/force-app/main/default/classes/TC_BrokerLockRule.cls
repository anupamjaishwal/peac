public class TC_BrokerLockRule extends TC_LockRuleAbstract{
    
	// If in a lockable stage and user is not credit, do not allow user to add a broker
    public override void doCheck (TC_TriggerParams params) {
        
        Map <Id, Broker__c> newMap = (Map <Id, Broker__c>) params.getNewMap ();
        Map <Id, Broker__c> oldMap = (Map <Id, Broker__c>) params.getOldMap ();
        
        List <Broker__c> filtered = getFilteredList (params);
        Set <Id> oppIds = new Set <Id> ();
        Set <Id> accIds = new Set <Id> ();
        
        for (Broker__c broker : filtered) {
            oppIds.add (broker.Opportunity__c);
            accIds.add (broker.Account__c);
        }
        
        if (oppIds.isEmpty () || accIds.isEmpty()) return;
        
        Map <Id, Opportunity> oppMap = getOppMap (oppIds);
        Map <Id, Account> brokerAccounts = getAccMap (accIds);
        User user = getCurrentUser ();
            
        if (isCreditUser(user) || alwaysExcludedFromRules (user)) return;
            
        for (Broker__c broker : filtered) {
			if (inLockableStage (oppMap.get (broker.Opportunity__c))
				&& !oppMap.get (broker.Opportunity__c).Loan_Record_Type__c
                && !brokerAccounts.get (broker.Account__c).Override_Sales_Lockdown_Restrictions__c) {
					broker.addError ('Only Credit Users can add/update/delete a Broker in this stage'); 
			}
         }
    }
}