public class TC_ExpressOrtValidation {
    public static void expressOrtValidation(Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap, List<Opportunity> newList){
       validateOpportunities(newList != null? newList: newMap.values());
    }

    public static void validateOpportunities(List<Opportunity> opps){
        for(Opportunity opp : opps){
            String str = Schema.SObjectType.Opportunity.getRecordTypeInfosById().get(opp.recordtypeid).getName();
            if(str.contains('Express')){
                /*Taken out per SAL-3038
                if(opp.Lessor__c == 409){
                    opp.Lessor__c.addError('Express ORT can not have "409" in Lessor field.');
                }*/

                /*Taken out per SAL-3012 
                if(opp.Advance_Rental_Amount__c > 0){
                    opp.Advance_Rental_Amount__c.addError('In Express ORT , Advance Rental Amount Should be only Null or 0');
                }
                */

                if(opp.Equipment_Cost__c < 25000 && opp.Opportunity_Funding_Type__c =='Delivery Guarantee'){
                    opp.Opportunity_Funding_Type__c.addError('Express ORT do not prefer Funding Type as Delivery Guarantee if Equipment Cost <$25,000');
                    
                }
                /* Taken out per SAL-3374
                 * if(opp.Points__c != 0 && opp.Points__c != null){
                    opp.Points__c.addError('Express ORT can have Points either 0 or Null');
                }*/
                
                if(opp.PUT_Amount__c != 0 && opp.PUT_Amount__c != null){
                    opp.PUT_Amount__c.addError('Express ORT can have PUT Amount either 0 or Null');
                }

                /*Taken out per SAL-3012
                if(opp.Required_Adv_Payments__c !=0 && opp.Required_Adv_Payments__c != null){
                    opp.Required_Adv_Payments__c.addError('Express ORT can have # Required Adv. Payments either 0 or Null');
                }
                */

                if(opp.Sales_Leaseback__c == true){
                    opp.Sales_Leaseback__c.addError('Express ORT can only have false Sale Leaseback');
                }
                if(opp.Beginning_Maintenance_Fee_Amount__c != null){
                    opp.Beginning_Maintenance_Fee_Amount__c.addError('Beginning Maintenance Fee Amount should be Null in Express ORT');
                }
                if(opp.Escalation_Rate__c != null  ){
                    opp.Escalation_Rate__c.addError('Express ORT can only have null Escalation Rate');
                } 
                if(opp.First_12_Months_Free__c != false){
                    opp.First_12_Months_Free__c.addError('Express ORT can only have false First 12 months Free ');
                }
                if(opp.Num_Pass_Thru_Fees__c != null && opp.Num_Pass_Thru_Fees__c != 0){
                    opp.Num_Pass_Thru_Fees__c.addError('Express ORT can only have null # of Pass Thru Fees');
                }
             /*   if(opp.Year_1_Pass_Thru_Fee__c !=0 && opp.Year_1_Pass_Thru_Fee__c != null) {
                    opp.addError('Year 1 Pass Thru Fee should be Null');
                }
                if(opp.Year_2_Pass_Thru_Fee__c !=0 && opp.Year_2_Pass_Thru_Fee__c != null) {
                    opp.addError('Year 2 Pass Thru Fee should be Null');
                }
                if(opp.Year_3_Pass_Thru_Fee__c !=0 && opp.Year_3_Pass_Thru_Fee__c != null) {
                    opp.addError('Year 3 Pass Thru Fee should be Null');
                }
                if(opp.Year_4_Pass_Thru_Fee__c !=0 && opp.Year_4_Pass_Thru_Fee__c != null) {
                    opp.addError('Year 4 Pass Thru Fee should be Null');
                }
                if(opp.Year_5_Pass_Thru_Fee__c !=0 && opp.Year_5_Pass_Thru_Fee__c != null) {
                    opp.addError('Year 5 Pass Thru Fee should be Null');
                }
                if(opp.Year_6_Pass_Thru_Fee__c !=0 && opp.Year_6_Pass_Thru_Fee__c != null) {
                    opp.addError('Year 6 Pass Thru Fee should be Null');
                }
              
                if(opp.Year_7_Pass_Thru_Fee__c !=0 && opp.Year_7_Pass_Thru_Fee__c != null) {
                    opp.addError('Year 7 Pass Thru Fee should be Null');
                } */
                
            } 
        }
    }
}