public class TC_DealerLockRule extends TC_LockRuleAbstract{
    
    public static Boolean alreadyRan = false; // recursive issues, maybe add this to super class if i run into this more
    private static Final Set <String> DEALER_LOCKABLE_BRANCH = new Set <String> {'oeg', 'retail', 'snap', 'hkf', 'cvg'};
    
	// If in a lockable stage and user is not credit, do not allow user to add a dealer
    public override void doCheck (TC_TriggerParams params) {
        if (alreadyRan) return;
        
        Map <Id, Dealer__c> newMap = (Map <Id, Dealer__c>) params.getNewMap ();
        Map <Id, Dealer__c> oldMap = (Map <Id, Dealer__c>) params.getOldMap ();
        
        List <Dealer__c> filtered = getFilteredList (params);
        Set <Id> oppIds = new Set <Id> ();
        Set <Id> accIds = new Set <Id> ();
        
        for (Dealer__c dealer : filtered) {
            oppIds.add (dealer.Opportunity__c);
            accIds.add (dealer.Dealer__c);
        }
        

        if (!oppIds.isEmpty ()) {
            alreadyRan = true;
            
            Map <Id, Opportunity> oppMap = getOppMap (oppIds);
        	User user = getCurrentUser ();
            
            // getting related dealer status
            Map <Id, Account> dealerAccounts = getAccMap (accIds);
            
            // credit can add/remove/modify dealers in any status
            // sales managers can only remove/modify dealers, but only add active dealers
            
            if (isCreditUser(user) || alwaysExcludedFromRules (user)) return;

            Boolean isInsert = oldMap == null;
            Boolean userIsAllowedToAdd = isSalesManagementUser (user);

            //they should only be able to add an active dealer: https://marlinbusiness.atlassian.net/browse/SAL-1598
            
            // if it's in a lockable stage & is a lease & is not a valid user & is not insert
            
            for (Dealer__c dealer : filtered) {

                if (
                    !String.isBlank (oppMap.get (dealer.Opportunity__c).Channel__c)
                    && DEALER_LOCKABLE_BRANCH.contains(oppMap.get (dealer.Opportunity__c).Channel__c.toLowerCase ())
                    && inLockableStage (oppMap.get (dealer.Opportunity__c))
                    && !oppMap.get (dealer.Opportunity__c).Loan_Record_Type__c
                    && !dealerAccounts.get (dealer.Dealer__c).Override_Sales_Lockdown_Restrictions__c
                   ) {

                       if (userIsAllowedToAdd) {
                           if (isInsert && dealerAccounts.get (dealer.Dealer__c).Account_Dealer_Status__c != 'Active'
                              && dealerAccounts.get (dealer.Dealer__c).Account_Dealer_Status__c != '1x Exception') {
                               dealer.addError ('Cannot add a inactive Dealer in this stage'); 
                           }
                       } else {

                           // if the opp has a broker or franchisor, or has a dealer called 'Unknown Dealer' or 'Sales Leaseback',
                           // then allow adding/updating/deleting the dealer prior to Docs Requested, else do not allow

                           Boolean hasBroker = oppMap.get(dealer.Opportunity__c).No_of_Broker__c > 0;
                           Boolean hasFranchisor = oppMap.get(dealer.Opportunity__c).No_of_Franchisors__c > 0;
                           Boolean hasUnknownDealer = false; // default to false
                           Boolean hasSalesLeaseback = false; // default to false
                           for (Dealer__c dlr : oppMap.get(dealer.Opportunity__c).Brokers__r) {
                               if (dlr.Account_Name__c.contains('Unknown Dealer')) {
                                   hasUnknownDealer = true;
                               } else if (dlr.Account_Name__c.contains('Sales Leaseback')) {
                                   hasSalesLeaseback = true;
                               }
                           }

                           if (hasBroker == true || hasFranchisor == true || hasUnknownDealer == true || hasSalesLeaseback == true){
                               // do nothing
                           } else {
                               dealer.addError ('Cannot add/update/delete a Dealer in this stage');
                           }
                       }  
                   }
                
            }
        }
    }
}