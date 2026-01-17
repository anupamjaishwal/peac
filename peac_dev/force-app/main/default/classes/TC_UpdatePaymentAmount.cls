public class TC_UpdatePaymentAmount {
    public static void updatePaymentAmount (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
        
        for (Opportunity opp : newMap.values ()) {
            if(opp.Opportunity_CurrentUser_Profile__c != 'DataAdmin' && !opp.Loan_Record_Type__c
                && opp.Payment_Amount__c == oldMap.get(opp.Id).Payment_Amount__c
                && (opp.Equipment_Cost__c != oldMap.get(opp.Id).Equipment_Cost__c
                || opp.X_Rate_Factor__c != oldMap.get(opp.Id).X_Rate_Factor__c)){
                opp.Payment_Amount__c = opp.Equipment_Cost__c != null && opp.Equipment_Cost__c != 0 && opp.X_Rate_Factor__c != null && opp.X_Rate_Factor__c != 0 ? (opp.X_Rate_Factor__c*((opp.Equipment_Cost__c))).setScale(2, RoundingMode.HALF_UP) : 0;
            }
            if (
                (
                    // Equipment Cost changes but x rate factor and payment amount not changed
                    (opp.Equipment_Cost__c != oldMap.get (opp.Id).Equipment_Cost__c
                     && opp.X_Rate_Factor__c == oldMap.get (opp.Id).X_Rate_Factor__c
                    )
                    ||
                    // Or X Rate Factor changes and equipment cost does not change and payment amount does not change
                    (opp.Equipment_Cost__c == oldMap.get (opp.Id).Equipment_Cost__c
                     && opp.X_Rate_Factor__c != oldMap.get (opp.Id).X_Rate_Factor__c
                    )
                )
                
            )
            {
                /*taking out per SAL-3442
                //Changing per SAL-3373
                //opp.Payment_Amount__c = opp.Equipment_Cost__c != null && opp.Equipment_Cost__c != 0 && opp.X_Rate_Factor__c != null && opp.X_Rate_Factor__c != 0 ? (opp.X_Rate_Factor__c*((opp.Equipment_Cost__c))).setScale(2, RoundingMode.HALF_UP) : 0;
                if(opp.Equipment_Cost__c != null && opp.Equipment_Cost__c != 0 && opp.X_Rate_Factor__c != null && opp.X_Rate_Factor__c != 0){
                    if(opp.Points__c == null && opp.Advance_Rental_Amount__c == null){
                      opp.Payment_Amount__c = (opp.X_Rate_Factor__c * ((opp.Equipment_Cost__c*(1 + (0/100))) - 0)).setScale(2, RoundingMode.HALF_UP);  
                    }
                    else if(opp.Points__c == null){
                        opp.Payment_Amount__c = (opp.X_Rate_Factor__c * ((opp.Equipment_Cost__c*(1 + (0/100))) - opp.Advance_Rental_Amount__c)).setScale(2, RoundingMode.HALF_UP);
                    }
                    else if(opp.Advance_Rental_Amount__c == null){
                        opp.Payment_Amount__c = (opp.X_Rate_Factor__c * ((opp.Equipment_Cost__c*(1 + (opp.Points__c/100))) - 0)).setScale(2, RoundingMode.HALF_UP);
                    }
                    else{
						opp.Payment_Amount__c = (opp.X_Rate_Factor__c * ((opp.Equipment_Cost__c*(1 + (opp.Points__c/100))) - opp.Advance_Rental_Amount__c)).setScale(2, RoundingMode.HALF_UP);
                    }
                }
                else{
                    opp.Payment_Amount__c = 0;
                }
                */
				
                opp.Payment_Amount__c = opp.Equipment_Cost__c != null && opp.Equipment_Cost__c != 0 && opp.X_Rate_Factor__c != null && opp.X_Rate_Factor__c != 0 ? (opp.X_Rate_Factor__c*((opp.Equipment_Cost__c))).setScale(2, RoundingMode.HALF_UP) : 0;
                opp.First_Payment_Amount__c = opp.Equipment_Cost__c != null && opp.Equipment_Cost__c != 0 && opp.X_Rate_Factor__c != null && opp.X_Rate_Factor__c != 0 ? (opp.Equipment_Cost__c*opp.X_Rate_Factor__c).setScale(2, RoundingMode.HALF_UP) : 0;
                
                opp.Ending_Pymts_in_Advance__c = opp.Equipment_Cost__c != null && opp.Equipment_Cost__c != 0 && opp.X_Rate_Factor__c != null && opp.X_Rate_Factor__c != 0 ? (opp.Equipment_Cost__c*opp.X_Rate_Factor__c).setScale(2, RoundingMode.HALF_UP) * opp.of_ending_payments__c : 0;
                
                TC_CalculateGrossContract.calculateGrossContract (opp);
            }
        }
        TC_UpdateEndingPaymentAmount.updateEndingPaymentAmount (oldMap, newMap);
        
    }
}