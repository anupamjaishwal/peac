public class TC_PayoffTriggerHelper {
    // tbd if lease
    public static void updatePayoffTotalsOnOpp (Map <Id, Payoff__c> oldMap, Map <Id, Payoff__c> newMap) {
        Set <Id> oppIds = new Set <Id> ();
        
        if (newMap != null) {
            // on insert or update
            for (Payoff__c payoff : newMap.values ()) {
                if (oldMap == null || (oldMap.get (payoff.Id).Third_Party__c != payoff.Third_Party__c || oldMap.get (payoff.Id).Payoff_Amount__c != payoff.Payoff_Amount__c )) oppIds.add (payoff.Opportunity__c);
            }
        } else { 
            // on delete
            for (Payoff__c payoff : oldMap.values ()) {
                oppIds.add (payoff.Opportunity__c);
            }
        }
        
        if (!oppIds.isEmpty()) {
            List <Opportunity> updateList = new List <Opportunity> ();
            for (Opportunity opp : [SELECT Id, (SELECT Id, Third_Party__c, Payoff_Amount__c FROM Payoffs__r) FROM Opportunity WHERE Id IN :oppIds AND Loan_Record_Type__c = true]) {
                Decimal renewalAmount = 0;
                Decimal competitorAmount = 0;
                if (!opp.Payoffs__r.isEmpty ()) {
                    for (Payoff__c payoff : opp.Payoffs__r) {
                        if (payoff.Third_Party__c) {
                            competitorAmount += payoff.Payoff_Amount__c;
                        } else {
                            renewalAmount += payoff.Payoff_Amount__c;
                        }
                    }
                }
                updateList.add (new Opportunity (Id = opp.Id, Competitor_Payoff_Amount__c = competitorAmount, Renewal_Payoff_Amount__c  = renewalAmount));
            }
            
            if (!updateList.isEmpty ()) update updateList;
        }
    }

    // 2 functions for readability
    
    // sets flag for funding checklist item. This flag is used to auto include an item when the chcklist is generated
    // https://marlinbusiness.atlassian.net/browse/SAL-1689
    public static void setPayoffExistFlagOnOpportunity (Map <Id,Payoff__c> payoffs) {

        Set <Id> oppIds = getOppIds (payoffs);
        if (oppIds.isEmpty()) return;

        List <Opportunity> updateList = new List <Opportunity> ();

        for (Id oppId : oppIds) {
            updateList.add (new Opportunity (Id = oppId, Payoff_Exists__c = true));
        }

        update updateList;
    }

    // un-sets flag for funding checklist item. This flag is used to auto include an item when the chcklist is generated
    // https://marlinbusiness.atlassian.net/browse/SAL-1689
    public static void unsetPayoffExistFlagOnOpportunity (Map <Id,Payoff__c> payoffs) {

        Set <Id> oppIds = getOppIds (payoffs);
        if (oppIds.isEmpty()) return;

        Map <Id, Opportunity> oppMap = new Map <Id, Opportunity> ([SELECT Id, (SELECT Id FROM Payoffs__r) FROM Opportunity WHERE Id IN :oppIds]);

        List <Opportunity> updateList = new List <Opportunity> ();

        for (Id oppId : oppIds) {
            if (oppMap.get (oppId).Payoffs__r.isEmpty()) updateList.add (new Opportunity (Id = oppId, Payoff_Exists__c = false));
        }

        update updateList;
    }

    private static Set <Id> getOppIds (Map <Id,Payoff__c> payoffs) {
        Set <Id> oppIds = new Set <Id> ();

        for (Payoff__c payoff : payoffs.values ()) {
            // Opportunity__c not a master detail
            if (!String.isBlank(payOff.Opportunity__c)) oppIds.add (payOff.Opportunity__c);
        }
        return oppIds;
    }
}