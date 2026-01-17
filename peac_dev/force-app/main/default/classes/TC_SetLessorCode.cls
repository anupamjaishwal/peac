public class TC_SetLessorCode {
    public static void setLessorCode(Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
        
        for (Opportunity opp : newMap.values()) {
            if (opp.Branch__c != 'Commercial Vehicle Group') {
                if (opp.Marlin_Referral_Decision__c == 'Referral' || opp.Marlin_Referral_Decision__c == 'Syndication') {
                    opp.Lessor__c = 150;
                }
            }
        }
    }
    public static void setLessorCode(List<Opportunity> newList){
        for (Opportunity opp : newList) {
            if (opp.Branch__c != 'Commercial Vehicle Group') {
                if (opp.Marlin_Referral_Decision__c == 'Referral' || opp.Marlin_Referral_Decision__c == 'Syndication') {
                    opp.Lessor__c = 150;
                }
            }
        }
    }
    //added by RajaSirivella SAL-4274
    public static void populateInvoiceSection(Map <Id, Opportunity> oldMap, List<Opportunity> newList){
    if(oldMap.isEmpty()){
        for (Opportunity opp : newList) {
                opp.Invoice_Code__c = 'A';
                opp.Invoice_Description__c = string.ISBlank(opp.Equipment_Description__c) ? '' : (opp.Equipment_Description__c).left(254);
                opp.Payment_Option__c = 'N';
        }
     }else if(!oldMap.isEmpty()){
         for(Opportunity opp : newList){
             Opportunity oldOpty = oldMap.get(opp.Id);
             if(oldOpty.Equipment_Description__c != opp.Equipment_Description__c){
                 opp.Invoice_Description__c = string.ISBlank(opp.Equipment_Description__c) ? '' : (opp.Equipment_Description__c).left(254);
             }
         }
     }
    }//end
}