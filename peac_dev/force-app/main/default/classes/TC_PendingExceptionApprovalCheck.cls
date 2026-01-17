// Andrew Mayer
// https://marlinbusiness.atlassian.net/browse/SAL-1751
// don't let user move deal out of proposal if any ef approved offers are Pending Exception Approval


public class TC_PendingExceptionApprovalCheck{
    
  /*  public static void doAction (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
        
        Set <Id> oppIds = new Set <Id> ();
        
        for (Opportunity opp : newMap.values ()) {
            if (oldMap.get (opp.Id).StageName == 'Proposal' && opp.StageName != oldMap.get (opp.Id).StageName) {
                oppIds.add (opp.Id);
            }
        }
        
        if (oppIds.isEmpty()) return;
        
        for (Opportunity opp : [SELECT Id, (SELECT Id FROM EF_Approved_Offers__r WHERE Offer_Selected__c = 'Pending Exception Approval') FROM Opportunity WHERE Id IN :oppIds]) {
            if (!opp.EF_Approved_Offers__r.isEmpty ()) newMap.get (opp.Id).addError ('Can\t leave proposal stage if any EF Approved Offers are pending exception approval');
        }
        
    }*/

}