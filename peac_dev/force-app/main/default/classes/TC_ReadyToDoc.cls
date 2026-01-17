public class TC_ReadyToDoc {
public static void readyToDoc (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
        for (Opportunity opp : newMap.values()) {
            if (opp.Probability <75 && ((opp.Ready_To_Doc__c == 'Yes' && oldMap.get (opp.Id).Ready_To_Doc__c != opp.Ready_To_Doc__c) || (opp.Loan_Ready_To_Doc__c == 'Yes' && oldMap.get (opp.Id).Loan_Ready_To_Doc__c != opp.Loan_Ready_To_Doc__c ))) {
                opp.StageName = 'Docs Requested';
            }
        }
        
    }
}