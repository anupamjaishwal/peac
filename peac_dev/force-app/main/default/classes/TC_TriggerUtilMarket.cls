/*
 * 
 * 
 Class should contain any market setting related logic
*/

public class TC_TriggerUtilMarket {
    
	//IF DLG Opportunity created THEN Market Position (on EU Account) = In Market
    public static void setDLGMarketPosition (Map <Id, Opportunity> newMap) {
        Set <Id> recordTypeIds = new Set <Id> ();
        for (Opportunity opp : newMap.values ()) {
            if (opp.AccountId != null && opp.RecordTypeId != null) recordTypeIds.add (opp.RecordTypeId);
        }
        if (!recordTypeIds.isEmpty ()) {
            Set <Account> updateSet = new Set <Account> ();
            Map <Id, RecordType> recordTypes = new Map <Id, RecordType> ([SELECT Id, Name FROM RecordType WHERE Id IN :recordTypeIds]);
            for (Opportunity opp : newMap.values ()) {
            	if (recordTypes.get (opp.RecordTypeId) != null && recordTypes.get (opp.RecordTypeId).Name.toUpperCase().contains ('DLG')) updateSet.add (new Account (Id = opp.AccountId, Market_Position__c = 'In Market'));
        	}
            if (!updateSet.isEmpty()) {
                List <Account> updateList = new List <Account> ();
                updateList.addAll (updateSet);
                update updateList;
            }
        } 
    } 
    
    //IF DLG Opportunity Stage = Lost AND No other active Opportunities THEN Market Position (on EU Account) = Out of Market
    public static void setDLGOutOfMarket (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
		Set <Id> accIds = new Set <Id> ();
        for (Opportunity opp : newMap.values ()) {
            if (opp.StageName == 'Lost' && oldMap.get (opp.Id).StageName != 'Lost' && opp.record_type_name__c != null && opp.record_type_name__c.toUpperCase().contains ('DLG')) accIds.add (opp.AccountId);
        }
		
        if (!accIds.isEmpty ()) {
            List <Account> updateList = new List <Account> ();
            for (Account acc : [SELECT Id, (SELECT Id FROM Opportunities WHERE StageName NOT IN ('No Contact','Lost','Funded/Booked') AND Application_Status__c NOT IN ('Cancelled','Rejected','Automatically Declined','Declined','Withdrawn')) FROM Account WHERE Id IN :accIds]) {
                if (acc.Opportunities.isEmpty ()) updateList.add (new Account (Id = acc.Id, Market_Position__c = 'Out of Market'));
            }
            if (!updateList.isEmpty ()) update updateList;
        }
		        
    }
    
}