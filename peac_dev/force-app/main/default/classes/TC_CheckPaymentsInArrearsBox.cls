public class TC_CheckPaymentsInArrearsBox {
    public static void checkPaymentsInArrearsBox(Map <Id, Opportunity> newMap, List<Opportunity> newList){
        check(newList != null? newList: newMap.values());
    }

    public static void check(List<Opportunity> opps){
        for(Opportunity opp : opps){
            if(opp.Commencement_Date__c != null && opp.First_Payment_Date__c != null){
                Integer noOfMonths = opp.Commencement_Date__c.monthsBetween(opp.First_Payment_Date__c);
                if(noOfMonths >= 1){
                    opp.Payments_In_Arrears__c = true;
                }
            }
        }
    }
}