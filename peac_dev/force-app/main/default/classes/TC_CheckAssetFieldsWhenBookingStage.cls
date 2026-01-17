public class TC_CheckAssetFieldsWhenBookingStage {
    public static Marlin_Configuration__c config = Marlin_Configuration__c.getOrgDefaults ();
public static void checkAssetFieldsWhenBookingStage (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
        
        Set <Id> bookingOppIds = new Set <Id> ();
        // only on change to booking stage
        for (Opportunity opp : newMap.values ()) {
            if (!opp.Loan_Record_Type__c && opp.StageName == 'Booking' && opp.StageName != oldMap.get (opp.Id).StageName) {
                bookingOppIds.add (opp.Id);
            }
        }
        
        if (!bookingOppIds.isEmpty ()) {
            List <Opportunity> oppsWithAssets = new List <Opportunity > ([SELECT Id, Name, (SELECT Id, Name, Opportunity__c, Description__c, List_Price__c, Cost__c, Quantity__c, Equipment_Code__c, Property_Status__c, Tax_Code__c, State_Tax_Code__c, City_Tax_Code__c, Equipment_Street__c, Equipment_City__c, Equipment_State__c, Equipment_Zip__c, End_User_Billing_Address__c, Upfront_Tax_Code__c, Upfront_Tax_Paid_To__c, County_Tax_Code__c, Upfront_Tax_Method__c, Upfront_State_Tax_Amount__c, Upfront_County_Transit_Tax_Amount__c, Upfront_County_Tax_Amount__c, Upfront_City_Transit_Tax_Amount__c, Upfront_City_Tax_Amount__c, Total_Upfront_Tax_Amount__c, Opportunity_Contract_Type__c, Equipment_Location_City__c, Equipment_Location_County__c, Equipment_Location_State__c  FROM Assets__r) FROM Opportunity WHERE Id IN :bookingOppIds]);
            
            for (Opportunity opp : oppsWithAssets) {
                List <String> errors = new List <String> ();
                for (Asset__c asset : opp.Assets__r) {
                    TC_RequiredFieldHelper.assetEnterBookingStage (asset, errors);
                    if (!errors.isEmpty () && config != null && config.Apex_Validations_Active__c) newMap.get (asset.Opportunity__c).addError ('Asset ' + asset.Name + ': ' + errors + ' required when stage is changed to Booking');
                }
            }
        }
        
    }
}