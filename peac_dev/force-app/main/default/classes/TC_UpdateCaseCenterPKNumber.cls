public class TC_UpdateCaseCenterPKNumber {
public static void updateCaseCenterPKNumber(Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap){
        
        System.debug('!!! trigger helper updateCaseCenterPKNumber');
        
        Set <Id> oppIds = new Set <Id> ();
        
        for (Opportunity opp : newMap.values()){
            if (opp.Loan_Record_Type__c && opp.CaseCenter__c != null && opp.PK__c != null && oldMap.get(opp.Id).PK__c != opp.PK__c) oppIds.add(opp.Id);
        }
        
        if (!oppIds.isEmpty() & oppIds.size() == 1) {
            
            List <Opportunity> oppList = [SELECT Id, CaseCenter__c, PK__c FROM Opportunity WHERE Id IN :oppIds];
            
            System.debug('opp Id: ' + oppList[0].Id);
            
            MARLIN_CaseCenterCallout.updateCaseCenterApplicationStatus(oppList[0].Id, oppList[0].CaseCenter__c, oppList[0].PK__c);
        }
    }
}