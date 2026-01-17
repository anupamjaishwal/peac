public class TC_TrustPilotInvMapper {
    public static List <TC_TrustPilotInvRequestBean> createRequests (Set <Id> oppIds) {
        
        List <TC_TrustPilotInvRequestBean> requests = new List <TC_TrustPilotInvRequestBean> ();
        
        for (Opportunity opp : [SELECT Id, Contract__c, Account.Name, (SELECT Contact.Email FROM OpportunityContactRoles WHERE IsPrimary = true OR Role = 'Primary Contact') FROM Opportunity WHERE Id IN :oppIds]) {
            requests.add (new TC_TrustPilotInvRequestBean (opp.Contract__c, opp.Account.Name, opp.OpportunityContactRoles[0].Contact.Email, opp.Id));
        }
    	return requests;
    }
}