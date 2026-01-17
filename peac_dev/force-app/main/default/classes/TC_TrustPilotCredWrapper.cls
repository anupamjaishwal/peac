public class TC_TrustPilotCredWrapper {

    private static Trust_Pilot_App__c tp;
    
    public static Trust_Pilot_App__c getTrustPilotApplication () {
        if (tp == null) {
            List <Trust_Pilot_App__c> tps = new List <Trust_Pilot_App__c> ([SELECT API_Key__c, Access_Token__c, Access_Token_Last_Refresh_Date__c, Secret__c, Business_Id__c, Invitation_URL__c, Password__c, Token_URL__c, Username__c  FROM Trust_Pilot_App__c]);
            if (!tps.isEmpty()) {
                tp = tps[0];
            }
        }
        return tp;
    }
    

}