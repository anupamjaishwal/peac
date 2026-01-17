public class TC_RequiredFieldHelper {
    
    public static void assetEnterBookingStage (Asset__c asset, List <String> errors) {
        if (asset.Description__c == null) errors.add ('Description');
        if (asset.List_Price__c == null) errors.add ('List Price');
        if (asset.Cost__c == null) errors.add ('Cost');
        if (asset.Quantity__c == null || asset.Quantity__c == 0) errors.add ('Quanity');
        if (asset.Equipment_Code__c == null) errors.add ('Equipment Code');
        if (asset.Property_Status__c == null) errors.add ('Property Status');
        if (asset.County_Tax_Code__c == null || asset.State_Tax_Code__c == null || asset.City_Tax_Code__c == null) errors.add ('County, City, and State Tax Code');
        if (asset.Equipment_Street__c == null || asset.Equipment_City__c == null || asset.Equipment_State__c == null || asset.Equipment_Zip__c == null) errors.add ('Equipment Location Section');
    	if (asset.Equipment_Location_City__c == null) errors.add ('Equipment City');
        if (asset.Equipment_Location_County__c == null) errors.add ('Equipment County');
        if (asset.Equipment_Location_State__c == null) errors.add ('Equipment State');
    }
}