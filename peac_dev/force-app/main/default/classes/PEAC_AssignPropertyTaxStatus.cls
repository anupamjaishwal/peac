/**************************************************************************************************************
@Author: Rajesh Kumar(LTM)
@Description: This clas is used to assign property tax status on assets in before insert and update
@User Story: SAL-7193
@Created Date: May-05-2026
**************************************************************************************************************/

public class PEAC_AssignPropertyTaxStatus {
	public static Map<String, Map<String, String>> apiNameValueMap = getPropertyStatusMetadata();
    /**************************************************************************************************************
    @Author: Rajesh Kumar(LTM)
    @Description: Assign Property Status on asset based on custom metadata
    @User Story: SAL-7193
    @Created Date: May-05-2026
	@Param:List of asset, map of old asset and map of opportunity
	@Return:None
    **************************************************************************************************************/
    
    public static void AssignPropTaxStatus(List<Asset__c> assetList,Map<Id,Asset__c> oldAssetMap,Map<Id, Opportunity> opps ) {
		
		// Assign property status
        for (Asset__c assetR : assetList) {
            Asset__c oldAsset = oldAssetMap != null ? oldAssetMap.get(assetR.Id) : null;
            assignPropStatusAsset(opps.get(assetR.Opportunity__c) , assetR, oldAsset);
		}
    }
    /**************************************************************************************************************
    @Author: Rajesh Kumar(LTM)
    @Description: Assign Property Status on asset based on custom metadata
    @User Story: SAL-7193
    @Created Date: May-05-2026
	@Param:Opportunity, asset and old asset
	@Return:None
    **************************************************************************************************************/
    
    public static void assignPropStatusAsset(Opportunity relatedOpp ,Asset__c assetR,Asset__c oldAsset)
    {
       		
        	
        	// Equipment_Location_State__c
            if (assetR.Equipment_Location_State__c != null &&
                apiNameValueMap.containsKey('Equipment_Location_State__c')) {

                String mapped = apiNameValueMap.get('Equipment_Location_State__c')
                                               .get(assetR.Equipment_Location_State__c);
                if (mapped != null) assetR.Property_Status__c = mapped;
            }	
        
			
            // Purchase_Options__c
            if (relatedOpp.Purchase_Options__c != null &&
                apiNameValueMap.containsKey('Purchase_Options__c')) {

                String mapped = apiNameValueMap.get('Purchase_Options__c').get(relatedOpp.Purchase_Options__c);
                if (mapped != null) assetR.Property_Status__c = mapped;
            }
        	// Should override the Property Tax StatusEquipment_code__c
            if (((oldAsset == Null && assetR.Equipment_Code__c != null) || (oldAsset!= null && 
             	assetR.Equipment_Code__c !=oldAsset.Equipment_Code__c))
                && apiNameValueMap.containsKey('Equipment_Code__c')) {

                String mapped = apiNameValueMap.get('Equipment_Code__c').get(assetR.Equipment_code__c);
                if (mapped != null) assetR.Property_Status__c = mapped;
            }
   }
    /**************************************************************************************************************
    @Author: Rajesh Kumar(LTM)
    @Description: Get Property Status on asset based on custom metadata
    @User Story: SAL-7193
    @Created Date: May-05-2026
	@Param:None
	@Return:Map of asset field api with map of field value and property status code
    **************************************************************************************************************/
    
    public static Map<String, Map<String, String>> getPropertyStatusMetadata()
    {
        apiNameValueMap = new Map<String, Map<String, String>> ();
        // Query metadata once
        for (PEAC_Asset_Property_Status__mdt mdt : [
            SELECT Asset_Field_API__c, Property_Status_Mapping__c
            FROM PEAC_Asset_Property_Status__mdt
        ]) {

            // Ensure inner map exists
            if (!apiNameValueMap.containsKey(mdt.Asset_Field_API__c)) {
                apiNameValueMap.put(mdt.Asset_Field_API__c, new Map<String, String>());
            }

            // Parse mapping string: "Intangible||10,Intang||11"
            for (String pair : mdt.Property_Status_Mapping__c.split(',')) {
                List<String> parts = pair.split('\\|\\|');
                if (parts.size() == 2) {
                    apiNameValueMap.get(mdt.Asset_Field_API__c).put(parts[0], parts[1]);
                }
            }
        }
        system.debug(logginglevel.Error,'apiNameValueMap...'+apiNameValueMap);
        return apiNameValueMap;
    }
    
}