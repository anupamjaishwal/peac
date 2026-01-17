public class TC_UpdateCaseCenterApplicationStatus {
public static void updateCaseCenterApplicationStatus(Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap){
        
        System.debug('!!! trigger helper updateCaseCenterApplicationStatus');
        
        Set <Id> oppIdsApplicationStatus = new Set <Id> ();
        
        for (Opportunity opp : newMap.values()){
            if (opp.Loan_Record_Type__c && opp.CaseCenter__c != null && opp.Application_Status__c == 'Booked' && oldMap.get(opp.Id).Application_Status__c != 'Booked') oppIdsApplicationStatus.add(opp.Id);
        }
        
        if (!oppIdsApplicationStatus.isEmpty() & oppIdsApplicationStatus.size() == 1) {
            
            List <Opportunity> oppList = [SELECT Id, CaseCenter__c FROM Opportunity WHERE Id IN :oppIdsApplicationStatus];
            
            System.debug('opp Id: ' + oppList[0].Id);
            
            MARLIN_CaseCenterCallout.updateCaseCenterApplicationStatus(oppList[0].Id, oppList[0].CaseCenter__c, null);
        }
    }
}