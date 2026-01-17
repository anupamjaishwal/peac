public class TC_AutoCreateMiscBillableItems {
    public static void autoCreateMiscBillableItems(Opportunity opp, Set<Id> oppsMovedToBooking, Map<Id, List<Miscellaneous_Billable_Item__c>> miscBillableItems,
    List<Miscellaneous_Billable_Item__c> miscBillablesToInsert) {
        // SAL-5293 Misael Romero
        String glCode = '0017';
        if(oppsMovedToBooking.contains(opp.Id)){
            Map<String, Miscellaneous_Billable_Item__c> mbisByGeneratedCode = new Map<String, Miscellaneous_Billable_Item__c>();
            for(Miscellaneous_Billable_Item__c mbi :miscBillableItems.get(opp.Id)){
                if(mbi.Generated_Code__c != null){
                    mbisByGeneratedCode.put(mbi.Generated_Code__c, mbi);
                }
            }       
            for(Integer i = 1; i <= 7; i++) {
                String APIName = 'Year_' + String.valueOf(i) + '_Pass_Thru_Fee__c';
                if(opp.get(APIName) != null) {
                    Decimal decimalAmount = Decimal.valueOf(String.valueOf(opp.get(APIName)));
                    if(decimalAmount > 0 && !mbisByGeneratedCode.containsKey(glCode + APIName)) {
                        Miscellaneous_Billable_Item__c newMiscBill = new Miscellaneous_Billable_Item__c(Opportunity__c = opp.Id);
                        newMiscBill.Misc_GL_Code__c = '0017 - Service Contract';
                        newMiscBill.Amount__c = decimalAmount;
                        //                        newMiscBill.Billing_Cycle__c = opp.Billing_Cycle__c; removed for SAL-868
                        newMiscBill.Generated_Code__c = glCode + APIName;
                        miscBillablesToInsert.add(newMiscBill);
                    }
                }
            }
            if(miscBillablesToInsert.size()  == 1 && mbisByGeneratedCode.keySet().size() == 0){
                miscBillablesToInsert[0].First_Payment_Date__c = opp.First_Payment_Date__c;
            }
       }
   }

//    public static void autoCreateMiscBillableItems(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap){

//    }
}