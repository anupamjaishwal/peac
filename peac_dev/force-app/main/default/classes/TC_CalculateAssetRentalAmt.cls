public class TC_CalculateAssetRentalAmt {
public static void calculateAssetRentalAmount (Set <Id> oppIds) {
        List <Asset__c> updateList = new List <Asset__c> ();
        
        if (oppIds.size  () > 0) {
            List <Opportunity> opps = [SELECT StageName, Payment_Amount__c, of_Payments__c, Equipment_Cost__c, X_Rate_Factor__c, 
                                       (SELECT Id,
                                        List_Price__c,Opportunity_Contract_Type__c
                                        FROM Assets__r)
                                       FROM Opportunity
                                       WHERE Id IN :oppIds
                                      ];
            
            for (Opportunity opp : opps) {
                if (opp.StageName != 'Lost' && opp.Payment_Amount__c != null) {
                    Decimal oppTotalCost = 0;
                    
                    // for (Asset__c asset : opp.Assets__r) {
                    //     oppTotalCost += asset.List_Price__c == null ? 0 : asset.List_Price__c;
                    // }
                    
                    // if (oppTotalCost != 0) {
                        for (Asset__c asset : opp.Assets__r) {
                            if (asset.List_Price__c != null) {
                                //asset.Asset_Rental_Amount__c = ((asset.List_Price__c / oppTotalCost) * opp.Payment_Amount__c) * opp.of_Payments__c;
                                Decimal rateFactor = TC_NotNullorZero.notNullorZero(opp.X_Rate_Factor__c) ? opp.X_Rate_Factor__c : TC_NotNullorZero.notNullorZero(opp.Equipment_Cost__c) && TC_NotNullorZero.notNullorZero (opp.Payment_Amount__c) ? (opp.Payment_Amount__c/opp.Equipment_Cost__c) : 0;
                                asset.Asset_Rental_Amount__c = TC_NotNullorZero.notNullorZero(rateFactor) && TC_NotNullorZero.notNullorZero (asset.List_Price__c) && TC_NotNullorZero.notNullorZero (opp.of_Payments__c) ? 
                                    rateFactor * asset.List_Price__c * opp.of_Payments__c: 0; 
                                updateList.add (asset);
                            }
                        }
                    // }
                }
            }
        }
        
        if (updateList.size () > 0)
            update updateList;
    }
}