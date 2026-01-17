public class TC_UpdateApprovedAmount {
 public static void updateApprovedAmount(Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
        for (Opportunity opp : newMap.values()) {
            if (opp.Last_Date_Scorex_Retrieved__c != null && opp.Approved_Amount__c == null &&
                (opp.Application_Status__c == 'Manually Approved' || opp.Application_Status__c == 'Automatically Approved')) {
                    opp.Approved_Amount__c = opp.Credit_Amount__c;
                }
        }
    }
}