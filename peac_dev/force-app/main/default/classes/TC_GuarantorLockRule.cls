public class TC_GuarantorLockRule extends TC_LockRuleAbstract{
    
    // If in a lockable stage and user is not credit, do not allow user to add a guarantor
    public override void doCheck (TC_TriggerParams params) {
        
        
        Map <Id, Guarantor__c> newMap = (Map <Id, Guarantor__c>) params.getNewMap ();
        Map <Id, Guarantor__c> oldMap = (Map <Id, Guarantor__c>) params.getOldMap ();
        
        List <Guarantor__c> filtered = getFilteredList (params);
        Set <Id> oppIds = new Set <Id> ();
        Set <Id> accIds = new Set <Id> ();
        Set <Id> opportunityIds = new Set <Id> ();
        
        for (Guarantor__c guar : filtered) {
            oppIds.add (guar.Opportunity__c);
            if (guar.Account__c != null) accIds.add (guar.Account__c);
            if(Trigger.isDelete){
                
                opportunityIds.add(guar.Opportunity__c);
        }
        
        }
        if(!opportunityIds.isEmpty()){
            List<Opportunity> updateOpps = new List<Opportunity>();
            for(Id oppId : opportunityIds){
                updateOpps.add(new Opportunity(Id = oppId,IsPGDeleted__c = true));
            }
            if(!updateOpps.isEmpty()){
                update updateOpps;
            }
        }
        if (!oppIds.isEmpty ()) {
            Map<Id,Account> cgs = new Map <Id, Account> ();
            if (!accIds.isEmpty ()) cgs = getAccMap (accIds);
            Map <Id, Opportunity> oppMap = getOppMap (oppIds);
            User user = getCurrentUser ();
            
            if (isCreditUser(user) || alwaysExcludedFromRules (user)) return;
            
            for (Guarantor__c guar : filtered) {
                if (inLockableStage (oppMap.get (guar.Opportunity__c))
                    && !oppMap.get (guar.Opportunity__c).Loan_Record_Type__c
                    && !isExcludedCG (cgs, guar.Account__c)) {
                       guar.addError ('Only Credit Users can add/update/delete a Guarantor in this stage'); 
                    }
            }
        }
    }
    
    private Boolean isExcludedCG (Map<Id,Account> cgs, Id accId) {
        return !cgs.isEmpty () && cgs.get (accId).Override_Sales_Lockdown_Restrictions__c;
    }
}