/**************************************************************************************************************
@Author: Chalapati Murru (LTIMindtree)
@Description: This class is used to handle Asset trigger
@User Story: SAL-5692 Expo: Opportunity Refactor
@Created Date: Jan-02-2026
**************************************************************************************************************/
public class PEAC_AssetTriggerHelper {
    
    //SAL-5692 Expo: Below method is to replace Asset Process Builder - TC: Asset Defaults - Residual Amount
    public static void setAssetResidualAmountFormerPB(List<Asset__c> assets, Map<Id, Opportunity> opps){
        Set<String> purOptns = new Set<String>{'1.00 Out', 'Assign Resid No Renewal', 'Assigned Residual', 'Customer Owned'};
        for(Asset__c asset : assets){
            if(!purOptns.contains(opps.get(asset.Opportunity__c)?.Purchase_Options__c)){
                asset.Residual_Amount__c = (((asset.Residual_Percentage__c??0)/100) * (asset.List_Price__c??0));
            }else if(opps.get(asset.Opportunity__c)?.Purchase_Options__c == '1.00 Out' && asset.First_Record__c ){
                asset.Residual_Amount__c = 1;   
            }else if(opps.get(asset.Opportunity__c)?.Purchase_Options__c == '1.00 Out' && !asset.First_Record__c){
				asset.Residual_Amount__c = 0;   
            }
             if(asset.Residual_Percentage__c > 0 && purOptns.contains(opps.get(asset.Opportunity__c)?.Purchase_Options__c)){
                asset.Residual_Percentage__c = 0;
                asset.Residual_Amount__c = 0; /*SAL-7139: Making residual amount to 0 as percentage is also 0*/
            }
        }        
    }

    // Developed by Suraj Harichandan(LTM) for SAL-6961
    // Stamps Salvage_Value__c with Residual_Amount__c for Operating Lease (OL) assets.
    // Skips stamping when Opportunity_Contract_Type__c was just changed (preserves existing value).
    // 0 is a valid value and will be stamped.
    public static void stampSalvageValueForOL(List<Asset__c> assets, Map<Id, List<String>> fieldsChangedById, Boolean isNew) {
        for (Asset__c asset : assets) {
            Boolean isOL = asset.Opportunity_Contract_Type__c == PEAC_ConstantClass.OPERATING_LEASE;
            List<String> fieldsChanged = fieldsChangedById != null ? fieldsChangedById.get(asset.Id) : null;
            Boolean contractTypeJustChanged = !isNew && fieldsChanged != null
                && fieldsChanged.contains('Opportunity_Contract_Type__c');
            if ((isNew && isOL) || (!isNew && isOL && !contractTypeJustChanged)) {
                asset.Salvage_Value__c = asset.Residual_Amount__c;
            } else if (!isOL) {
                asset.Salvage_Value__c = 0;
            }
        }
    }
    
    public static void setZipUpdatedFlag(List<Asset__c> assets, Boolean isNew) {
        for(Asset__c asset : assets){
            if (Trigger.isBefore && !isNew && String.isNotEmpty(asset.Equipment_Zip__c)){// SAL-5596 Misael Romero
                    asset.Tax_Zip_Updated__c = true;
            }
            if(Trigger.isAfter && asset.Tax_Zip_Updated__c && !System.isBatch() &&  !PEAC_ConstantClass.ASSET_EQUIPMENT_ZIP_00000.equals(asset.Equipment_Zip__c)){
                TC_BridgewareUtility.selectZipGeoCode(asset.Id, asset.Equipment_Zip__c);
            }
        }
    }
    
    public static void setEquipmentState(List<Asset__c> assets) {
        //SAL-5692 Expo:Refactor-Removed getIsToUpdateOppTaxState(). Added conditions before method call 
        for(Asset__c asset : assets){
            if(asset.Equipment_Location_City__c != null) asset.Equipment_City__c = asset.Equipment_Location_City__c;
        	if(asset.Equipment_Location_State__c != null) asset.Equipment_State__c = TC_BridgewareUtility.transState(asset.Equipment_Location_State__c);
        }
    }
    
    public static void setTaxCodeTo060UpfrontTaxStateFormerPB(List<Asset__c> assets, Boolean isNew, Map<Id, Opportunity> opps, Map<Id, List<String>> fieldsChangedById){
        for(Asset__c asset : assets){
            List<String> fieldsChanged = fieldsChangedById.get(asset.Id);
            Boolean changedUpfrontTaxCode = fieldsChanged != null && fieldsChanged.contains('Upfront_Tax_Code__c');
            Boolean changedEquipLocationCity = fieldsChanged != null && fieldsChanged.contains('Equipment_Location_City__c');
            Boolean changedStateTaxCode = fieldsChanged != null && fieldsChanged.contains('State_Tax_Code__c');
            Boolean changedUpfrontCityTaxAmt = fieldsChanged != null && fieldsChanged.contains('Upfront_City_Tax_Amount__c');
            
            List<String> purchaseOptNotForTennessee = new List<String>{'1.00 Out', 'Put', 'Customer Owned'};
            List<String> upfrontTaxCodesTemp = new List<String>{'001', '100', '150'};
            if(asset.Equipment_Location_State__c == 'TENNESSEE' && !purchaseOptNotForTennessee.contains(asset.Purchase_Options__c)
               && asset.Tax_Exempt_Equipment__c == 'No' && (opps.get(asset.Opportunity__c) != null && opps.get(asset.Opportunity__c).Tax_Exempt__c == 'No')){
                   asset.County_Tax_Code__c = '060';
            }else{
                if(((isNew || (changedUpfrontTaxCode || changedEquipLocationCity)) || asset.State_Tax_Code__c != '060') 
                    && upfrontTaxCodesTemp.contains(asset.Upfront_Tax_Code__c)){
                      
                    if(asset.Equipment_Location_City__c == 'CHICAGO'){
                        asset.City_Tax_Code__c = '150';
                        asset.County_Tax_Code__c = '060';
                        asset.State_Tax_Code__c = '060';
                    }else{
                        if(asset.Equipment_Location_State__c == 'ILLINOIS'){
                            asset.City_Tax_Code__c = '001';
                            asset.County_Tax_Code__c = '001';
                            asset.State_Tax_Code__c = '001';
                            // asset.Upfront_Tax_Code__c = '001';
                        }else{
                            asset.City_Tax_Code__c = '060';
                            asset.County_Tax_Code__c = '060';
                            asset.State_Tax_Code__c = '060';
                        }
                    }
                }else{
                    if(asset.Equipment_Location_City__c == 'CHICAGO' && asset.State_Tax_Code__c == '060' 
                        && asset.Upfront_City_Tax_Amount__c > 0
                        && (isNew || (changedEquipLocationCity || changedStateTaxCode || changedUpfrontCityTaxAmt))){
                            asset.Upfront_City_Tax_Amount__c = 0;
                    }
                }
           }
        }
    }
    
    //This Method has Same Logic As Process Builder - TC Asset - On Create set Contract Type from Opp
    public static void bookingRulesDefaultDepreciationFormerPB(List<Asset__c> assets, Map<Id, Opportunity> opps){
        for(Asset__c theAsset : assets){
            //Added OL-Operating Lease(Rajesh LTM)
            if(PEAC_ConstantClass.TRUE_AND_OPERATING_LEASE.Contains(theAsset.Opportunity_Contract_Type__c)){
                Datetime oppBooked1 = opps.get(theAsset.Opportunity__c) != null? opps.get(theAsset.Opportunity__c).Opportunity_Booked_Date__c: null;
                Date oppBookedDate = oppBooked1 != null? oppBooked1.dateGMT(): null;
                Decimal term = opps.get(theAsset.Opportunity__c) != null? opps.get(theAsset.Opportunity__c).Terms__c : null;
                theAsset.Begin_Depreciation_Date__c = oppBookedDate;
                theAsset.Calculate_ACE_Depr__c = true;
                theAsset.Calculate_AMT__c = true;
                theAsset.Depreciation_Basis__c = theAsset.Cost__c;
                theAsset.Federal_Calculation_Basis__c = theAsset.Cost__c;
                theAsset.Federal_Convention__c = '6';
                theAsset.Federal_Life__c = 60;
                theAsset.Federal_Method__c = '58';//200% DDB - 80% Bonus. But In PB Values is '28' (200% DDB - No Bonus).Need to Review.	
                theAsset.State_Begin_Depreciation_Date__c = oppBookedDate;
                theAsset.State_Depreciation_Basis__c = theAsset.Cost__c;
                theAsset.State_Life_in_Months__c = 60;
                theAsset.State_Method__c = '3';
                if(PEAC_ConstantClass.OPERATING_LEASE.Contains(theAsset.Opportunity_Contract_Type__c)){ // SAL-7087 Vinod LTM 
                    theAsset.Operating_Depreciation_Method__c = 'S';
                    theAsset.Operating_Depreciation_Life__c = term;
                    theAsset.Operating_Begin_Depreciation_Date__c = oppBookedDate;
                    theAsset.Operating_Depreciation_Basis__c = theAsset.Cost__c;
                }
                if(theAsset.State_Tax_Code__c == '031' || theAsset.State_Tax_Code__c == '036'){
                    theAsset.Federal_Method__c = '21'; //S/L - No Bonus
                }
            }
        }
    }
    
    public static void handleListPriceCostUpdated(List<Asset__c> assets, Map<Id, Opportunity> opps) {
        for(Asset__c asset : assets){
            Boolean isSalesUser = checkIfSalesUser(opps.get(asset.Opportunity__c).Opportunity_CurrentUser_Profile__c);
            if(asset.List_Price__c != null && !canUpdateAssetWithEquipmentCost(isSalesUser, opps.get(asset.Opportunity__c))) {
                setAssetFields(asset, 'after');
            }
            if(asset.Cost__c != null && canUpdateAssetWithEquipmentCost(isSalesUser, opps.get(asset.Opportunity__c))) {
                setAssetFields(asset, 'before');
            }
        }
    }
    
	/*public static void listPriceUpdated(Asset__c asset, Opportunity relatedOpp) {
        Boolean isSalesUser = checkIfSalesUser(relatedOpp.Opportunity_CurrentUser_Profile__c);
        if(asset.List_Price__c != null && !canUpdateAssetWithEquipmentCost(isSalesUser, relatedOpp)) {
            setAssetFields(asset, 'after');
        }
    }
    
    public static void costUpdated(Asset__c asset, Opportunity relatedOpp) {
        Boolean isSalesUser = checkIfSalesUser(relatedOpp.Opportunity_CurrentUser_Profile__c);
        if(asset.Cost__c != null && canUpdateAssetWithEquipmentCost(isSalesUser, relatedOpp)) {
            setAssetFields(asset, 'before');
        }
    }*/
    
    public static Decimal calculateCost (Asset__c asset) {
        return asset.Financed_Trigger__c ? returnValue (asset.Upfront_County_Tax_Amount__c) + returnValue (asset.Upfront_City_Transit_Tax_Amount__c) + returnValue (asset.Upfront_City_Tax_Amount__c) + returnValue (asset.Upfront_County_Transit_Tax_Amount__c) + returnValue (asset.Upfront_State_Tax_Amount__c) + returnValue (asset.List_Price__c) : returnValue (asset.List_Price__c);
    }
    
    public static void setAssetFields (Asset__c asset, String beforeOrAfterDocsRequested) {
        Boolean listPriceGreaterThanZero = asset.List_Price__c != null && asset.List_Price__c > 0;
        system.debug(beforeOrAfterDocsRequested+' listPriceGreaterThanZero:'+listPriceGreaterThanZero);
        Decimal cost = beforeOrAfterDocsRequested == 'before' ? returnValue (asset.Cost__c) : calculateCost (asset);
        if (beforeOrAfterDocsRequested == 'before') {
            asset.List_Price__c = cost;
            asset.Orig_Cost__c = cost;
        } else if (listPriceGreaterThanZero) {
            asset.Orig_Cost__c  = asset.List_Price__c;
            asset.Cost__c = cost;
        } 
        //Added OL-Operating Lease(Rajesh LTM)
        if (PEAC_ConstantClass.TRUE_AND_OPERATING_LEASE.Contains(asset.Opportunity_Contract_Type__c)) {
            asset.Depreciation_Basis__c = cost;
            asset.Federal_Calculation_Basis__c = cost; 
            asset.State_Depreciation_Basis__c = cost;
            if(PEAC_ConstantClass.OPERATING_LEASE.Contains(asset.Opportunity_Contract_Type__c)){
            asset.Operating_Depreciation_Basis__c = cost;
            }
        } else {
            asset.Depreciation_Basis__c = null;
            asset.Federal_Calculation_Basis__c = null;
            asset.State_Depreciation_Basis__c = null;
            asset.Operating_Depreciation_Basis__c = null;
        }
    }
    
    public static Boolean checkIfSalesUser(String currentUserProfile){
        Boolean isSalesUser = currentUserProfile != null && (currentUserProfile.containsIgnoreCase('rep') 
            || currentUserProfile.containsIgnoreCase('manager')
            || currentUserProfile.containsIgnoreCase('mgr'));
        return isSalesUser;
    }
    
    public static Boolean canUpdateAssetWithEquipmentCost (Boolean isSalesUser, Opportunity opp) {
        Boolean canUpdateAssetWithEquipmentCost = false;
        if(opp != null && ((isSalesUser && (opp.StageName == 'Docs Requested' || opp.Probability < 75)) 
        || (!isSalesUser && opp.Probability < 75))){
            canUpdateAssetWithEquipmentCost = true;
        }
        return canUpdateAssetWithEquipmentCost;
    }
    
         //SAL-6522 HARD/SOFT Assets auto Classification via meta-data
    public static void setAssetClassification(List<Asset__c> assets) {
        Map<String, String> equipCodeClssftnMap = new Map<String, String>();
        
        for(MARLIN_Rapport_Mapping__mdt  mapping : [SELECT Id, MasterLabel, Asset_Classification__c FROM MARLIN_Rapport_Mapping__mdt WHERE Field_Name__c = 'Equipment_Code']){
            equipCodeClssftnMap.put(mapping.MasterLabel, mapping.Asset_Classification__c);
        }
        for(Asset__c asset : assets){
            asset.Asset_Classification__c = equipCodeClssftnMap?.get(asset.Equipment_Code__c);
        }
    }

    private static Decimal returnValue (Decimal value) {
        return value != null ? value : 0;
    }
    
    
    //SAL-6391 - Set Asset State and Country Fields for Iceland - START - Adding dummy comment for copado tracking
    public static void setIcelandStateAndTaxCodes(List<Asset__c> assets){
        for(Asset__c asset : assets){
            setStateAndTaxCodes(asset,PEAC_ConstantClass.ASSET_ICELAND_TAXCODE,PEAC_ConstantClass.ASSET_EQUIPMENT_STATE_NON_US_STATES,PEAC_ConstantClass.ASSET_EQUIPMENT_LOCATION);
        }
    }
    
    
    public static void setStateAndTaxCodes(Asset__c asset, String taxCode, String state, String country){
        asset.State_Tax_Code__c = taxCode;
        asset.LC_State_Tax_Code__c = taxCode;
        asset.Misc_State_Tax_Code__c = taxCode;
        asset.County_Tax_Code__c = taxCode;
        asset.LC_County_Tax_Code__c = taxCode;
        asset.Misc_County_Tax_Code__c = taxCode;
        asset.City_Tax_Code__c = taxCode;
        asset.LC_City_Tax_Code__c = taxCode;
        asset.Misc_City_Tax_Code__c = taxCode;
        asset.Equipment_State__c = state;
        asset.Equipment_Location_State__c = state;
        asset.Equipment_Location_City__c = country;
        asset.Equipment_Location_County__c = country; 
        asset.State_Code__c = PEAC_ConstantClass.ASSET_STATE_LOCATION_CODE_98;
        asset.City_Code__c = PEAC_ConstantClass.ASSET_CITY_LOCATION_CODE_8855;
        asset.County_Code__c = PEAC_ConstantClass.ASSET_COUNTY_LOCATION_CODE_855;
    }
    //SAL-6391 - Set Asset State and Country Fields for Iceland - END
    
    //SAL-6661 Vinod LTM
    public static void calculateMonthlyRent(List<Asset__c> assetList, Map<Id, Opportunity> oppMap) {
        
    for (Asset__c asset : assetList) {
		
		if(asset.Asset_Classification__c == null){
		   continue;
		}
        Opportunity relatedOpp = (oppMap != null) ? oppMap.get(asset.Opportunity__c) : null;
        
        // 2. Determine Price based on Classification
        Double softListPrice = asset.Asset_Classification__c == 'Soft' ? (asset.List_Price__c ?? 0) : 0;
        Double hardListPrice = asset.Asset_Classification__c == 'Hard' ? (asset.List_Price__c ?? 0) : 0;

        // 3. Perform Calculation using Factors from the correct Opp
        Double hardFactor = relatedOpp?.Hard_Lease_Rate_Factor__c ?? 0;
        Double softFactor = relatedOpp?.Soft_Lease_Rate_Factor__c ?? 0;

        asset.Calculated_Monthly_Rent__c = (hardListPrice * hardFactor) + (softListPrice * softFactor);
    }
    }
}