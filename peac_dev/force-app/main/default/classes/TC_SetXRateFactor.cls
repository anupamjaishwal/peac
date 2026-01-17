public class TC_SetXRateFactor {
public static void setXRateFactor (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
        for (Opportunity opp : newMap.values ()) {

            // TODO SAL-2884 removed from 3.4 release - uncomment this when 2884 is in current release
            if (opp.EF_Approved_Offers__c != null 
                && oldMap.get (opp.Id).EF_Approved_Offers__c != opp.EF_Approved_Offers__c) 
            {
                // SAL-2884 When Offer is selected then update rate 
               opp.X_Rate_Factor__c = opp.Offer_Rate_Factor__c;

            } else 
            
            if (
                ( oldMap.get (opp.Id).StageName != opp.StageName
                    && opp.StageName == 'Docs In'
                    //&& oldMap.get(opp.Id).X_Rate_Factor__c == null
                )
                ||
                (
                    oldMap.get (opp.Id).Payment_Amount__c != opp.Payment_Amount__c
                    && oldMap.get(opp.Id).X_Rate_Factor__c == opp.X_Rate_Factor__c
                    && oldMap.get (opp.Id).Equipment_Cost__c == opp.Equipment_Cost__c
                    && opp.Probability.round() >= 90 
                )
            ) {
                opp.X_Rate_Factor__c = opp.Equipment_Cost__c != null && opp.Equipment_Cost__c != 0 && opp.Payment_Amount__c != null ? opp.Payment_Amount__c/opp.Equipment_Cost__c : 0;
            
            } else if (opp.Probability < 90 && opp.EF_Approved_Offers__c == null ) {
                opp.X_Rate_Factor__c = null;
            }
            if(opp.X_Rate_Factor__c != null){
                opp.X_Rate_Factor__c = opp.X_Rate_Factor__c.setscale(10);
            }
        }
    }
}