/**************************************************************************************************************
@Author: Chalapati Murru (LTIMindtree)
@Description: This class is used to handle Asset trigger
@User Story: SAL-5692 Expo: Opportunity Refactor
@Created Date: Dec-05-2025
**************************************************************************************************************/
public without sharing class PEAC_AssetTriggerHandler {
    private static Map<Id, List<String>> fieldsChangedById = new Map<Id, List<String>>();
    private static Map<Id, Opportunity> opps = new Map<Id, Opportunity>();
    private static Set<Id> assetIds = new Set<Id>();
    private static Map<Id, Opportunity> oppsToUpdateById = new Map<Id, Opportunity>();
    //public static boolean runTriggerDel = false;
    
    public static void handleBeforeInsert(List<Asset__c> newList) {
        getLookupMaps(newList);
        beforeInsertChangesToSelf(newList, true);
        //Rajesh Kumar(LTM) SAL-7196
        PEAC_AssignPropertyTaxStatus.AssignPropTaxStatus(newList, null, opps);
    }
    
    public static void handleBeforeUpdate(Map<Id, Asset__c> oldMap, Map<Id, Asset__c> newMap) {
        checkUpdatedFields(oldMap, newMap);
        //if(PEAC_CommonUtils.byPassAssetTrigger) return;
        if(!fieldsChangedById.isEmpty()){//SAL-5692 Expo: Opp Refactor-Run only when valid fields updated
            getLookupMaps(newMap.values());
            beforeUpdateChangesToSelf(newMap.values(), false);
            //Rajesh Kumar(LTM) SAL-7196
        	PEAC_AssignPropertyTaxStatus.AssignPropTaxStatus(newMap.values(), oldMap, opps);
        }
    }
    
    public static void handleAfterInsert(Map<Id, Asset__c> newMap) {
        getLookupMaps(newMap.values());
        List<Opportunity> oppsToUpdate = populateAssetInfoOnOpp(newMap.values());
        for(Opportunity opp: oppsToUpdate){
            oppsToUpdateById.put(opp.Id, opp);
        }
        TC_AssetTriggerHelper.rollupFields(null, newMap, oppsToUpdateById);
        afterChangesToOthers(true, newMap);
        if(!system.isBatch()){
            //Commenting the below code for handle async limit
            //callZipCodeApi(newMap);
        }
    }
    
    public static void handleAfterUpdate(Map<Id,Asset__c> oldMap, Map<Id,Asset__c> newMap) {
        checkUpdatedFields(oldMap, newMap);
        if(!fieldsChangedById.isEmpty()){//SAL-5692 Expo: Opp Refactor-Run only when valid fields updated
            getLookupMaps(newMap.values());
            List<Opportunity> oppsToUpdate = populateAssetInfoOnOpp(newMap.values());
            for(Opportunity opp: oppsToUpdate){
                oppsToUpdateById.put(opp.Id, opp);
            }
            TC_AssetTriggerHelper.rollupFields((Map<Id, Asset__c>)oldMap, (Map<Id, Asset__c>)newMap, oppsToUpdateById);
            afterChangesToOthers(false, newMap);
        }
    }
    
    public static void handleAfterDelete(Map<Id, Asset__c> oldMap){
        populateEquipmentAddAssetDelete(Trigger.old);
        getLookupMaps(oldMap.values());
        List<Asset__c> deletedFirstAssets = new List<Asset__c>();
        Map<Id, Asset__c> assetsToUpdateById = new Map<Id, Asset__c>();
        for (Id assetId :oldMap.keySet()){
            Asset__c deletedAsset = (Asset__c)oldMap.get(assetId);
            if(deletedAsset.First_Record__c){
                deletedFirstAssets.add(deletedAsset);
            }
        }
        TC_AssetTriggerHelper.rollupFields((Map<Id, Asset__c>)oldMap, null, oppsToUpdateById);
        if(deletedFirstAssets.size() > 0){
            getInfoFromOthers();
            FirstAssetOnOpportunity.updateFirstAsset(deletedFirstAssets, opps, assetsToUpdateById);
        }
        if(assetsToUpdateById.keySet().size() > 0){
            update assetsToUpdateById.values();
        }
        if(oppsToUpdateById.keySet().size() > 0){
            update oppsToUpdateById.values();
        }
    }
    
    //Commenting below method after reviewing with Varun since we see last record created was in 2019 in production.
    /*public static void createStandardAsset (Map<Id,Asset__c> oldMap, Map<Id,Asset__c> newMap) {
        Marlin_Configuration__c setting = Marlin_Configuration__c.getOrgDefaults ();
        if(setting != null && setting.Disable_Standard_Asset_Generation__c) return;
        
        List<Asset> assets = new List<Asset>();
        Map<Id, Id> custStndMap = new Map<Id, Id>();
        
        for (Asset asset : [SELECT Id, Custom_Asset__c FROM Asset WHERE Custom_Asset__c IN :newMap.keySet()]) {
            custStndMap.put (asset.Custom_Asset__c, asset.Id);
        }
        
        for (Asset__c asset : newMap.values ()) {
            if (oldMap == null || oldMap.get (asset.Id) == null) {
                assets.add (new Asset (Price = asset.Cost__c
                                       , Quantity = asset.Quantity__c
                                       , TCCSC2__Make__c = asset.Vehicle_Make__c
                                       , TCCSC2__Model__c = asset.Model__c
                                       , TCCSC2__Year__c = asset.Vehicle_year__c
                                       , Name = asset.Description__c != null ? asset.Description__c.left (255) : asset.Name
                                       , AccountId = setting.Static_Standard_Asset_Account_Id__c
                                       , Custom_Asset__c = asset.Id
                                       , SerialNumber = asset.Serial_Number__c));
            } else if (oldMap.get (asset.Id).Name != asset.Name
                       || oldMap.get (asset.Id).Cost__c != asset.Cost__c
                       || oldMap.get (asset.Id).Quantity__c != asset.Quantity__c
                       || oldMap.get (asset.Id).Vehicle_Make__c != asset.Vehicle_Make__c 
                       || oldMap.get (asset.Id).Model__c != asset.Model__c
                       || oldMap.get (asset.Id).Vehicle_year__c != asset.Vehicle_year__c
                       || oldMap.get (asset.Id).Description__c != asset.Description__c
                       || oldMap.get (asset.Id).Serial_Number__c != asset.Serial_Number__c) {
                           assets.add (new Asset (Price = asset.Cost__c
                                                  , Quantity = asset.Quantity__c
                                                  , TCCSC2__Make__c = asset.Vehicle_Make__c
                                                  , TCCSC2__Model__c = asset.Model__c
                                                  , TCCSC2__Year__c = asset.Vehicle_year__c
                                                  , Name = asset.Description__c != null ? asset.Description__c.left (255) : asset.Name
                                                  , SerialNumber = asset.Serial_Number__c
                                                  , Id = custStndMap.get (asset.Id)));
                       }
        }
        if (!Test.isRunningTest()) upsert assets;
    }*/
    
    /*public static void roundTaxAmounts (Map <Id, Asset__c> oldMap, List <Asset__c> newList) {
        for (Asset__c asset : newList) {
            asset.Asset_Rental_Amount__c = asset.Rental_Amount_fml__c;//This will replace copyRentalAmountFromFormula method call during before update context
            if (asset.Upfront_State_Tax_Amount__c != null && asset.Upfront_State_Tax_Amount__c != 0 && asset.Upfront_State_Tax_Amount__c != oldMap.get (asset.Id).Upfront_State_Tax_Amount__c) asset.Upfront_State_Tax_Amount__c = asset.Upfront_State_Tax_Amount__c.setScale(2, RoundingMode.HALF_UP);
            if (asset.Upfront_County_Transit_Tax_Amount__c != null && asset.Upfront_County_Transit_Tax_Amount__c != 0 && asset.Upfront_County_Transit_Tax_Amount__c != oldMap.get (asset.Id).Upfront_County_Transit_Tax_Amount__c) asset.Upfront_County_Transit_Tax_Amount__c = asset.Upfront_County_Transit_Tax_Amount__c.setScale(2, RoundingMode.HALF_UP);
            if (asset.Upfront_City_Tax_Amount__c != null && asset.Upfront_City_Tax_Amount__c != 0 && asset.Upfront_City_Tax_Amount__c != oldMap.get (asset.Id).Upfront_City_Tax_Amount__c) asset.Upfront_City_Tax_Amount__c = asset.Upfront_City_Tax_Amount__c.setScale(2, RoundingMode.HALF_UP);
            if (asset.Upfront_City_Transit_Tax_Amount__c != null && asset.Upfront_City_Transit_Tax_Amount__c != 0 && asset.Upfront_City_Transit_Tax_Amount__c != oldMap.get (asset.Id).Upfront_City_Transit_Tax_Amount__c) asset.Upfront_City_Transit_Tax_Amount__c = asset.Upfront_City_Transit_Tax_Amount__c.setScale(2, RoundingMode.HALF_UP);
            if (asset.Upfront_County_Tax_Amount__c != null && asset.Upfront_County_Tax_Amount__c != 0 && asset.Upfront_County_Tax_Amount__c != oldMap.get (asset.Id).Upfront_County_Tax_Amount__c ) asset.Upfront_County_Tax_Amount__c = asset.Upfront_County_Tax_Amount__c.setScale(2, RoundingMode.HALF_UP);
        }
    }*/
    //SAL-5692 Expo:We need to analyze if below method can be moved to before context
    //Moved this logic to afterChangesToOthers
    /*public static void updateTNUpfrontCountyTax (Map<Id, Asset__c> oldMap, List<Asset__c> newList) {
        List<Asset__c> updateList = new List<Asset__c>();
        
        for(Asset__c asset : newList){
            if(asset.Equipment_Location_State__c == 'TENNESSEE' && oldMap.get(asset.Id).Tax_Date_Time__c != asset.Tax_Date_Time__c)
                updateList.add (new Asset__c (Id = asset.Id, Upfront_County_Tax_Amount__c = 0));
        }
        if(!updateList.isEmpty ()) update updateList;
    }*/
    
    //SAL-5692 Expo: Opp Refactor-Chalapati Murru(LTIMindtree)
    private static void getLookupMaps(List<Asset__c> assets){
        for(Asset__c asset : assets){
            if(asset.Opportunity__c != null){
                opps.put(asset.Opportunity__c, new Opportunity());
            }
            if(asset.Id != null){
                assetIds.add(asset.Id);
            }
        }
    }
    
    /*Manish: Commenting it out as this not req.*/
    /*static void callZipCodeApi(Map<Id,Asset__c> assetMap) {
        List<Asset__c> newassetList = new List<Asset__c>();
        for(asset__c newAsset: assetMap.Values()){
            
            if (String.isNotEmpty(newAsset.Equipment_Zip__c)){
                asset__c newRecAsset = new asset__c();
            	newRecAsset.id = newAsset.id;
                newRecAsset.Equipment_Zip__c = newAsset.Equipment_Zip__c;
                newassetList.add(newRecAsset);
            }
        }
        if(!system.isBatch() && !newassetList.isEmpty()){
            PEAC_SelectZipGeoCodeBatch batchJob1 = new PEAC_SelectZipGeoCodeBatch(newassetList);
            Database.executeBatch(batchJob1, Integer.ValueOf(Label.PEAC_SelectZipGeoCodeBatch_Limit)); // Adjust the batch size
        }
    }*/
    /*Manish: Commenting it out as this not req.*/
    private static void beforeInsertChangesToSelf(List<Asset__c> newList, Boolean isNew){
        Set<Id> oppsWithFirstAsset = new Set<Id>();
        List<Asset__c> listPriceCostList = new List<Asset__c>();
        List<Asset__c> residPercentList = new List<Asset__c>();
        List<Asset__c> contractTypeTLList = new List<Asset__c>();
        List<Asset__c> taxExemptCertList = new List<Asset__c>();
        List<Asset__c> equipCodeList = new List<Asset__c>();//SAL-6522
        List<Asset__c> icelandZipCodeList = new List<Asset__c>();//SAL-6391
        getInfoFromOthers();
        
        for(Asset__c asset : newList){
            System.Formula.recalculateFormulas(new List<Asset__c>{asset});// SAL-6978 Rajesh Kumar  
            //List<String> fieldsChanged = fieldsChangedById.get(asset.Id);
            Opportunity relatedOpp = opps.get(asset.Opportunity__c);
            asset.Opportunity_Contract_Type__c = relatedOpp?.Contract_Type__c; //Moved here from PB- TC Asset-On Create set Contract Type from Opp
            if(relatedOpp?.Number_of_Assets__c == 0 && !oppsWithFirstAsset.contains(asset.Opportunity__c)){
                asset.First_Record__c = true;
                oppsWithFirstAsset.add(asset.Opportunity__c);
                if(relatedOpp.Equipment_Description__c != null && asset.Description__c == null){
                    asset.Description__c = relatedOpp.Equipment_Description__c;
                }
                /*if(relatedOpp.Equipment_Cost__c != null && asset.Cost__c == null){//Gets handled in below if condition
                    asset.Cost__c = (Decimal)relatedOpp.Equipment_Cost__c;
                }*/
                //TC_AssetTriggerHelper.populateCostFieldsPriceFirstAsset(asset, relatedOpp);//SAL-5692 Expo:Refactor
                if (((asset.Cost__c ?? 0) == 0) && relatedOpp.Equipment_Cost__c != null){
                    asset.List_Price__c = relatedOpp.Equipment_Cost__c;
                    asset.Cost__c = relatedOpp.Equipment_Cost__c;
                    asset.Orig_Cost__c = relatedOpp.Equipment_Cost__c;
                }
            }
            if(String.isNotBlank(asset.Equipment_Code__c)){ //SAL-6522
                equipCodeList.add(asset);
            }
            //Logic migrated from Process Builder- TC Asset : Booking Rules - Depreciation Dates
            if(relatedOpp?.Opportunity_Booked_Date__c != null ){//SAL-5692 Expo:Refactor
                asset.Begin_Depreciation_Date__c = asset.State_Begin_Depreciation_Date__c = relatedOpp?.Opportunity_Booked_Date__c.date();
            }
            //Logic migrated from Process Builder- TC Asset - Customer Owned
            if(relatedOpp?.Purchase_Options__c == 'Customer Owned') asset.State_Tax_Code__c = '050';
            //Logic migrated from Process Builder- TC Asset - On Create Set Guidelines
            if(asset.Asset_CurrentUser_Profile__c != 'DataAdmin' || asset.Asset_CurrentUser_Profile__c != 'System Administrator'){
                asset.Mandatory_Fields_Include__c = '<small style="color:red;"><i><b> Is the shipping address for this asset the same as the Business Address on the opportunity? If yes, select the checkbox below and save. If there is an alternative address, manually enter the information below. </b></i></small>';
            }
            if(asset.List_Price__c != null || asset.Cost__c != null){
                listPriceCostList.add(asset);
                //TC_AssetTriggerHelper.listPriceUpdated(asset, relatedOpp);
                //TC_AssetTriggerHelper.costUpdated(asset, relatedOpp);
            }
            asset.Asset_Rental_Amount__c = asset.Rental_Amount_fml__c;//Moved here from TC_AssetTriggerHelper.copyRentalAmountFromFormula
            /*
            //SAL-6661 moved to calculateMonthlyRent method
            Double softListPrice = asset.Asset_Classification__c == 'Soft' ? asset.List_Price__c : 0;
            Double hardListPrice = asset.Asset_Classification__c == 'Hard' ? asset.List_Price__c : 0;
            asset.Calculated_Monthly_Rent__c = (hardListPrice * (relatedOpp?.Hard_Lease_Rate_Factor__c??0)) + (softListPrice * (relatedOpp?.Soft_Lease_Rate_Factor__c??0));
            */

            //Logic migrated from TC
            //: Asset Defaults - Residual Amount
            if((asset.Residual_Percentage__c ?? 0) >= 0 && (asset.List_Price__c ?? 0) >= 0){
                residPercentList.add(asset);
                //setAssetResidualAmountFormerPB(asset, relatedOpp);//New OR (Residual_Percentage__c OR List_Price__c) changed
            }
            asset.Dealer_Residual__c = asset.Residual_Amount__c;
            //calculateManagerResidual(asset, relatedOpp);//New OR (Purchase_Options__c or Equipment_Sub_Category__c is changed)
            ///This Method has Same Logic As Process Builder - TC Asset - On Create set Contract Type from Opp
            //Added OL-Operating Lease(Rajesh LTM)
            
            if(PEAC_ConstantClass.TRUE_AND_OPERATING_LEASE.Contains(asset.Opportunity_Contract_Type__c)){
                contractTypeTLList.add(asset);
                //bookingRulesDefaultDepreciationFormerPB(asset, isNew, fieldsChanged, relatedOpp);//New OR Opportunity_Contract_Type__c changed
            }
            //Logic migrated from Process Builder- Asset: Update Equipment Address 
            if(asset.End_User_Billing_Address__c) {
                asset.Equipment_State__c = relatedOpp?.Account_Business_State_Province__c;
            }
            //Logic migrated from Process Builder TC Asset - Set List Price & Orig Cost to Cost
            if(asset.Cost__c != null && asset.List_Price__c == null) {
                asset.List_Price__c = asset.Cost__c;
                asset.Orig_Cost__c = asset.Cost__c;
            }
            //SAL-6445 -Vinod Rathod
            //Logic migrated from Process Builder TC Asset -- Tax Exempt Certificate Requested
            if(asset.Usage_User_Table__c == '1'){
                taxExemptCertList.add(asset);
            }
            //setsTaxCodeAmtPercentages(asset, isNew, fieldsChanged);//SAL-6445: Logic migrated from TC Asset: Sets Tax Code, Amt, & Percentages if 036, 060 And Set Tax Fields to Null PB.
            //TC_AssetTriggerHelper.setTaxCodeTo060UpfrontTaxStateFormerPB(asset, isNew, relatedOpp, fieldsChanged); //SAL-5233 Misael Romero
            /* Start: SAL-6391 - Set Asset State and Country Fields for Iceland - Rahul */
            if(asset.Equipment_Zip__c == PEAC_ConstantClass.ASSET_EQUIPMENT_ZIP_00000){
                icelandZipCodeList.add(asset);
            }
            /* End: SAL-6391 - Set Asset State and Country Fields for Iceland - Rahul */  
        }
        if(!equipCodeList.isEmpty()){//SAL-6522
            PEAC_AssetTriggerHelper.setAssetClassification(equipCodeList);
        }
        if(!listPriceCostList.isEmpty()){
            PEAC_AssetTriggerHelper.handleListPriceCostUpdated(listPriceCostList, opps);//New OR Cost or List Price changed
        }
        if(!residPercentList.isEmpty()){
            PEAC_AssetTriggerHelper.setAssetResidualAmountFormerPB(residPercentList, opps);//New OR (Residual_Percentage__c OR List_Price__c) changed
        }
        PEAC_AssetResidualHelper.calculateManagerResidual(newList, opps);//New OR (Purchase_Options__c or Equipment_Sub_Category__c is changed)
                
        /* Start: SAL-6284 - Manish */
        PEAC_AssetTriggerPBHelper.tcAssetBookingDefaultTaXMethodResponsibilityCode(newList);
        /* END: SAL-6284 - Manish */
        PEAC_AssetTriggerPBHelper.setsTaxCodeAmtPercentages(newList, isNew);//SAL-6445: Logic migrated from TC Asset: Sets Tax Code, Amt, & Percentages if 036, 060 And Set Tax Fields to Null PB.
		if(!contractTypeTLList.isEmpty()){
            PEAC_AssetTriggerHelper.bookingRulesDefaultDepreciationFormerPB(contractTypeTLList, opps);//New OR Opportunity_Contract_Type__c changed
        }
        PEAC_AssetTriggerHelper.setTaxCodeTo060UpfrontTaxStateFormerPB(newList, isNew, opps, fieldsChangedById); //SAL-5233 Misael Romero
        if(!taxExemptCertList.isEmpty()){
            PEAC_AssetTriggerPBHelper.tCAssetTaxExemptCertificateRequested(taxExemptCertList);//SAL-6445: Logic migrated from Process Builder TC Asset -- Tax Exempt Certificate Requested
        }
        /* Start: SAL-6284 - Manish */
        //PEAC_AssetTriggerPBHelper.tcAssetBookingDefaultTaXMethodResponsibilityCode(newList);
        /* END: SAL-6284 - Manish */
       	/* Start: SAL-6391 - Set Asset State and Country Fields for Iceland - Rahul */
        if(!icelandZipCodeList.isEmpty()){//SAL-6391 /*Adding dummy commentC*/
            PEAC_AssetTriggerHelper.setIcelandStateAndTaxCodes(icelandZipCodeList);
        }
        /* END: SAL-6391 - Set Asset State and Country Fields for Iceland - Rahul */
        //SAL-6661
        if(!newList.isEmpty()){
            PEAC_AssetTriggerHelper.calculateMonthlyRent(newList,opps);
        }
        // Developed by Suraj Harichandan(LTM) for SAL-6961 — Stamp Salvage Value for OL after Residual Amount is calculated
        PEAC_AssetTriggerHelper.stampSalvageValueForOL(newList, fieldsChangedById, isNew);
    }

    private static void beforeUpdateChangesToSelf(List<Asset__c> newList, Boolean isNew){
        System.debug('----------------beforeUpdateChangesToSelf------------------');
        /*System.assert(false);
        System.assert(true);*/
        Set<Id> oppsWithFirstAsset = new Set<Id>();
        List<Asset__c> listPriceCostList = new List<Asset__c>();
        List<Asset__c> residPercentList = new List<Asset__c>();
        List<Asset__c> purchOptionsList = new List<Asset__c>();
        List<Asset__c> zipCopeList = new List<Asset__c>();
        List<Asset__c> contractTypeTLList = new List<Asset__c>();
        List<Asset__c> taxCodeList = new List<Asset__c>();
        List<Asset__c> equipLocationList = new List<Asset__c>();
        List<Asset__c> upfrontTaxCodeList = new List<Asset__c>();
        List<Asset__c> upfrTaxLocCityList = new List<Asset__c>();
        List<Asset__c> taxExemptCertList = new List<Asset__c>();
        List<Asset__c> stateTaxCodeList = new List<Asset__c>(); /*Adding dummy comment as copado not taking var during SAL-6925 deployment*/
        List<Asset__c> equipCodeList = new List<Asset__c>();//SAL-6522
        List<Asset__c> listPriceList = new List<Asset__c>();//SAL-6661
        List<Asset__c> icelandZipCodeList = new List<Asset__c>();//SAL-6391
        getInfoFromOthers();
        
        for(Asset__c asset : newList){
            System.Formula.recalculateFormulas(new List<Asset__c>{asset});// SAL-6978 Rajesh Kumar  
            List<String> fieldsChanged = fieldsChangedById.get(asset.Id);
            Opportunity relatedOpp = opps.get(asset.Opportunity__c);
            if(fieldsChanged != null){
                //SAL-5692 Expo:Refactor-Below else is to replace TC_AssetTriggerHelper.roundTaxAmounts()
                if(fieldsChanged.contains('Upfront_State_Tax_Amount__c') && (asset.Upfront_State_Tax_Amount__c ?? 0) != 0) asset.Upfront_State_Tax_Amount__c = asset.Upfront_State_Tax_Amount__c.setScale(2, RoundingMode.HALF_UP);
                if(fieldsChanged.contains('Upfront_County_Transit_Tax_Amount__c') && (asset.Upfront_County_Transit_Tax_Amount__c ?? 0) != 0) asset.Upfront_County_Transit_Tax_Amount__c = asset.Upfront_County_Transit_Tax_Amount__c.setScale(2, RoundingMode.HALF_UP);
                if(fieldsChanged.contains('Upfront_City_Tax_Amount__c') && (asset.Upfront_City_Tax_Amount__c ?? 0) != 0) asset.Upfront_City_Tax_Amount__c = asset.Upfront_City_Tax_Amount__c.setScale(2, RoundingMode.HALF_UP);
                if(fieldsChanged.contains('Upfront_City_Transit_Tax_Amount__c') && (asset.Upfront_City_Transit_Tax_Amount__c ?? 0) != 0) asset.Upfront_City_Transit_Tax_Amount__c = asset.Upfront_City_Transit_Tax_Amount__c.setScale(2, RoundingMode.HALF_UP);
                if(fieldsChanged.contains('Upfront_County_Tax_Amount__c') && (asset.Upfront_County_Tax_Amount__c ?? 0) != 0) asset.Upfront_County_Tax_Amount__c = asset.Upfront_County_Tax_Amount__c.setScale(2, RoundingMode.HALF_UP);                
                if(asset.City_Tax_Code__c == '028'){
                    //Logic migrated from Process Builder- TC Asset: Calculate City Tax Amount
                    if (fieldsChanged.contains('City_Tax_Percentage__c')) asset.City_Tax_Amount__c = asset.City_Tax_Percentage__c * asset.Total_Cost__c;
                    //Logic migrated from Process Builder- TC Asset: Calculate City Transit Tax Amount
                    if (fieldsChanged.contains('City_Transit_Tax_Percentage__c')) asset.City_Transit_Tax_Amount__c = asset.City_Transit_Tax_Percentage__c * asset.Total_Cost__c;
                }
                if(asset.County_Tax_Code__c == '028'){
                    //Logic migrated from Process Builder- TC Asset: Calculate County Tax Amount
                    if (fieldsChanged.contains('County_Tax_Percentage__c')) asset.County_Tax_Amount__c = asset.County_Tax_Percentage__c * asset.Total_Cost__c;
                    //Logic migrated from Process Builder- TC Asset: Calculate County Transit Tax Amount
                    if (fieldsChanged.contains('County_Transit_Tax_Percentage__c')) asset.County_Transit_Tax_Amount__c = asset.County_Transit_Tax_Percentage__c * asset.Total_Cost__c;
                }
                //Logic migrated from Process Builder- TC Asset: Calculate State Tax Amount
                if (fieldsChanged.contains('State_Tax_Percentage__c') && asset.State_Tax_Code__c == '028') asset.State_Tax_Amount__c = asset.State_Tax_Percentage__c * asset.Total_Cost__c;
                
                //Logic migrated from Process Builder- TC Asset: Set Property Tax Status
                //Rajesh Kumar(LTM) SAL-7196
        	    //if(fieldsChanged.contains('Equipment_Location_State__c') && relatedOpp?.Purchase_Options__c != 'Customer Owned') asset.Property_Status__c = asset.Property_Tax_Status_Per_State__c;
                
                if(fieldsChanged.contains('Equipment_Code__c')){ //SAL-6522
                    equipCodeList.add(asset);
                }

                if(fieldsChanged.contains('List_Price__c') || fieldsChanged.contains('Financed_Trigger__c')
                        || fieldsChanged.contains('Cost__c') || fieldsChanged.contains('Upfront_State_Tax_Amount__c')
                        || fieldsChanged.contains('Upfront_County_Tax_Amount__c') || fieldsChanged.contains('Upfront_County_Transit_Tax_Amount__c')
                        || fieldsChanged.contains('Upfront_City_Tax_Amount__c') || fieldsChanged.contains('Upfront_City_Transit_Tax_Amount__c')){
                            listPriceCostList.add(asset);
                            //TC_AssetTriggerHelper.listPriceUpdated(asset, relatedOpp);
                            //TC_AssetTriggerHelper.costUpdated(asset, relatedOpp);
                }
                asset.Asset_Rental_Amount__c = asset.Rental_Amount_fml__c;//Moved here from TC_AssetTriggerHelper.copyRentalAmountFromFormula
                asset.Dealer_Residual__c = asset.Residual_Amount__c;
                /*
                //SAL-6661 logic moved to calculateMonthlyRent method
                Double softListPrice = asset.Asset_Classification__c == 'Soft' ? asset.List_Price__c : 0;
                Double hardListPrice = asset.Asset_Classification__c == 'Hard' ? asset.List_Price__c : 0;
                asset.Calculated_Monthly_Rent__c = (hardListPrice * (relatedOpp?.Hard_Lease_Rate_Factor__c??0)) + (softListPrice * (relatedOpp?.Soft_Lease_Rate_Factor__c??0));
                */
                //Logic migrated from TC: Asset Defaults - Residual Amount
                if((fieldsChanged.contains('Residual_Percentage__c') || fieldsChanged.contains('List_Price__c')) && (asset.Residual_Percentage__c ?? 0) >= 0 && (asset.List_Price__c ?? 0) >= 0){
                    residPercentList.add(asset);
                    //setAssetResidualAmountFormerPB(asset, relatedOpp);//New OR (Residual_Percentage__c OR List_Price__c) changed
					//System.debug('Manager Residual Call line 275');
                }
                /*if(fieldsChanged.contains('Purchase_Options__c') || fieldsChanged.contains('Equipment_Sub_Category__c')){
                    calculateManagerResidual(asset, relatedOpp);//New OR (Purchase_Options__c or Equipment_Sub_Category__c is changed)
                }*/
				//SAL-6218 - D Balakrishna : Ensure manager residual is recalculated whenever any dependency changes
                if(fieldsChanged.contains('Residual_Percentage__c') || fieldsChanged.contains('List_Price__c') || fieldsChanged.contains('Residual_Amount__c')
                   || fieldsChanged.contains('Purchase_Options__c') || fieldsChanged.contains('Equipment_Sub_Category__c')|| fieldsChanged.contains('Override_Buyout__c'))
                { 	// Align dealer residual with residual amount
                    asset.Dealer_Residual__c = asset.Residual_Amount__c;
                    purchOptionsList.add(asset);
                    // Manager residual from latest values
                    //calculateManagerResidual(asset, relatedOpp);
                }
                if(fieldsChanged.contains('Equipment_Zip__c')){
                    zipCopeList.add(asset);
                    //setZipUpdatedFlag(asset, isNew, fieldsChanged);//Equipment_Zip__c is changed
                    /* Start: SAL-6391 - Set Asset State and Country Fields for Iceland - Rahul - LTM */
                    if(asset.Equipment_Zip__c == PEAC_ConstantClass.ASSET_EQUIPMENT_ZIP_00000){
                        icelandZipCodeList.add(asset);
                    }
                    /* End: SAL-6391 - Set Asset State and Country Fields for Iceland - Rahul - LTM */  
                }
                //Added OL-Operating Lease(Rajesh LTM)
                if(fieldsChanged.contains('Opportunity_Contract_Type__c') && PEAC_ConstantClass.TRUE_AND_OPERATING_LEASE.Contains(asset.Opportunity_Contract_Type__c)){
                    contractTypeTLList.add(asset);
                    //bookingRulesDefaultDepreciationFormerPB(asset, isNew, fieldsChanged, relatedOpp);//New OR Opportunity_Contract_Type__c changed
                }
                //SAL-6445 -Vinod Rathod
                //Logic migrated from TC Asset: Sets Tax Code, Amt, & Percentages if 036, 060 And Set Tax Fields to Null PB.
                if(fieldsChanged.contains('State_Tax_Code__c') && asset.State_Tax_Code__c == null &&  !system.isFuture()
                  && !system.isBatch() && !System.isQueueable()){
                //if(fieldsChanged.contains('State_Tax_Code__c') && asset.State_Tax_Code__c == null){
                    stateTaxCodeList.add(asset);
                }
                /*SAL-6925: Manish - Below If Condition modified: 17-03-2026: Adding dummy commit */
                if(/*fieldsChanged.contains('State_Tax_Code__c') || */fieldsChanged.contains('Tax_Exempt_Equipment__c')){
                    taxCodeList.add(asset);
                    //setsTaxCodeAmtPercentages(asset, isNew, fieldsChanged);//
                }
                //Logic migrated from Process Builder- Asset: Update Equipment Address 
                if(fieldsChanged.contains('End_User_Billing_Address__c') && asset.End_User_Billing_Address__c ) {
                    asset.Equipment_State__c = relatedOpp?.Account_Business_State_Province__c;
                }
                //Logic migrated from Process Builder TC Asset - Set List Price & Orig Cost to Cost
                if((fieldsChanged.contains('Cost__c') || fieldsChanged.contains('List_Price__c')) && asset.Cost__c != null && asset.List_Price__c == null) {
                    asset.List_Price__c = asset.Cost__c;
                    asset.Orig_Cost__c = asset.Cost__c;
                }
                //SAL-6445 -Vinod Rathod
                //Logic migrated from Process Builder TC Asset -- Tax Exempt Certificate Requested
                if(fieldsChanged.contains('Usage_User_Table__c') && asset.Usage_User_Table__c == '1'){
                    taxExemptCertList.add(asset);   
                }
                if(fieldsChanged.contains('Equipment_Location_City__c') || fieldsChanged.contains('Equipment_Location_County__c')
                    || fieldsChanged.contains('Equipment_Location_State__c') || fieldsChanged.contains('City_Code__c') || fieldsChanged.contains('County_Code__c') || fieldsChanged.contains('State_Code__c')){
                        equipLocationList.add(asset);
                        //TC_AssetTriggerHelper.setEquipmentState(asset, isNew, fieldsChanged);
                }
                if(fieldsChanged.contains('Upfront_Tax_Code__c') || fieldsChanged.contains('Equipment_Location_City__c')
                    || fieldsChanged.contains('Purchase_Options__c') || fieldsChanged.contains('State_Tax_Code__c') || fieldsChanged.contains('Upfront_City_Tax_Amount__c')){
                        upfrontTaxCodeList.add(asset);
                        //TC_AssetTriggerHelper.setTaxCodeTo060UpfrontTaxStateFormerPB(asset, isNew, relatedOpp, fieldsChanged); //SAL-5233 Misael Romero
                }
                if(fieldsChanged.contains('Upfront_Tax_Code__c') || fieldsChanged.contains('Equipment_Location_City__c') || fieldsChanged.contains('Equipment_Location_State__c')){ /* SAL-6284 - Manish */
                    upfrTaxLocCityList.add(asset);
                    //tcAssetBookingDefaultTaXMethodResponsibilityCode(asset);
                }
                //SAL-6661
                if(fieldsChanged.contains('List_Price__c')){
                    listPriceList.add(asset);
                }

            }
        }
        
        if(!equipCodeList.isEmpty()){//SAL-6522
            PEAC_AssetTriggerHelper.setAssetClassification(equipCodeList);
        }
        if(!listPriceCostList.isEmpty()){
            PEAC_AssetTriggerHelper.handleListPriceCostUpdated(listPriceCostList, opps);//New OR Cost or List Price changed
        }
        if(!residPercentList.isEmpty()){
            PEAC_AssetTriggerHelper.setAssetResidualAmountFormerPB(residPercentList, opps);//New OR (Residual_Percentage__c OR List_Price__c) changed
        }
        if(!purchOptionsList.isEmpty()){
            PEAC_AssetResidualHelper.calculateManagerResidual(purchOptionsList, opps);//New OR (Purchase_Options__c or Equipment_Sub_Category__c is changed)
        }
        if(!zipCopeList.isEmpty()){
            PEAC_AssetTriggerHelper.setZipUpdatedFlag(zipCopeList, isNew);//Equipment_Zip__c changed
        }
        if(!contractTypeTLList.isEmpty()){
            PEAC_AssetTriggerHelper.bookingRulesDefaultDepreciationFormerPB(contractTypeTLList, opps);//New OR Opportunity_Contract_Type__c changed
        }
        
        
        if(!taxExemptCertList.isEmpty()){
            PEAC_AssetTriggerPBHelper.tCAssetTaxExemptCertificateRequested(taxExemptCertList);//SAL-6445: Logic migrated from Process Builder TC Asset -- Tax Exempt Certificate Requested
        }
        if(!equipLocationList.isEmpty()){
            PEAC_AssetTriggerHelper.setEquipmentState(equipLocationList);
        }
        if(!upfrTaxLocCityList.isEmpty()){ //moved to up stateTaxCodeChanged - Manish
            PEAC_AssetTriggerPBHelper.tcAssetBookingDefaultTaXMethodResponsibilityCode(upfrTaxLocCityList);
        }
        if(!stateTaxCodeList.isEmpty()){
        	PEAC_AssetTriggerPBHelper.stateTaxCodeChanged(stateTaxCodeList);
        }
        if(!taxCodeList.isEmpty()){
            PEAC_AssetTriggerPBHelper.setsTaxCodeAmtPercentages(taxCodeList, isNew);//SAL-6445: Logic migrated from TC Asset: Sets Tax Code, Amt, & Percentages if 036, 060 And Set Tax Fields to Null PB.
        }
        
        
        if(!upfrontTaxCodeList.isEmpty()){
            PEAC_AssetTriggerHelper.setTaxCodeTo060UpfrontTaxStateFormerPB(upfrontTaxCodeList, isNew, opps, fieldsChangedById);
        }
        if(!icelandZipCodeList.isEmpty()){//SAL-6391
            PEAC_AssetTriggerHelper.setIcelandStateAndTaxCodes(icelandZipCodeList);
        }
         if(!listPriceList.isEmpty()){//SAL-6661
            PEAC_AssetTriggerHelper.calculateMonthlyRent(listPriceList,opps);
        }
        // Developed by Suraj Harichandan(LTM) for SAL-6961 — Stamp Salvage Value for OL after Residual Amount is calculated
        PEAC_AssetTriggerHelper.stampSalvageValueForOL(newList, fieldsChangedById, false);
    }
    
    private static void afterChangesToOthers(Boolean isNew, Map<Id, Asset__c> newMap){
        /*SAL-7139: START: */
        Map<Id, Opportunity> opportunityIdMap = new Map<Id, Opportunity>();
        Set<String> quickAppOpportunityStatus = new Set<String>{PEAC_ConstantClass.OPPORTUNITY_STAGENAME_APPLICATION, PEAC_ConstantClass.OPPORTUNITY_STAGENAME_QUOTE};
        Boolean opportunityCreatedFromQuickApp = false;
        /*SAL-7139: END: */
        List<Asset__c> zipCopeList = new List<Asset__c>();
        getInfoFromOthers();
        TC_CreditDecision.runRules(newMap, isNew, fieldsChangedById, opps);//This can be optimized further
        //SAL-5692 Expo: Opportunity Refactor-Commented because actual method call is commented inside this method.[Review with Varun]
        //TC_AssetTriggerHelper.generateTaxMatrixFormerPB(newMap, isNew, fieldsChangedById, opps);
        List<Asset__c> updateList = new List<Asset__c>();
        for(Asset__c asset : newMap.values()){
            Opportunity relatedOpp = opps.get(asset.Opportunity__c);
            opportunityCreatedFromQuickApp = quickAppOpportunityStatus.contains(relatedOpp.StageName);
            List<String> fieldsChanged = fieldsChangedById.get(asset.Id);
            //DupeRuleMessage(asset, isNew, fieldsChanged);//SAL-5692 Expo: Opportunity Refactor
            //Rajesh Kumar(LTM) SAL-7196
            /*if(isNew){
                //Logic migrated from Process Builder- TC Asset: Set Property Tax Status
                if(String.isNotEmpty(asset.Equipment_Location_State__c) && relatedOpp?.Purchase_Options__c != 'Customer Owned'){
                    updateList.add(new Asset__c (Id = asset.Id, Property_Status__c = asset.Property_Tax_Status_Per_State__c));
                }
            }*/
            if(isNew || (fieldsChanged != null && (fieldsChanged.contains('Equipment_Full_Address__c') || fieldsChanged.contains('Description__c')))){
                setOpportunityFieldsFromAsset(isNew, asset, relatedOpp, fieldsChanged);
            }
            //Commented as part of SAL-5692 Expo: Opportunity Refactor-Chalapati Murru[setOpportunityFieldsFromAsset() handles below 3 methods]
            /*if(isNew || (fieldsChanged != null && fieldsChanged.contains('Equipment_Full_Address__c'))){
                updateProductLocationFormerPB(asset, isNew, relatedOpp, fieldsChanged);//New OR Equipment_Full_Address__c changed
            }
            if(isNew || (fieldsChanged != null && fieldsChanged.contains('Description__c'))){
                updateInvoiceDescriptionFormerPB(asset, isNew, relatedOpp, fieldsChanged);//New OR Description__c changed
            }
            if(fieldsChanged != null && fieldsChanged.contains('Description__c')){
                updateAssetDescriptionFormerPB(asset, relatedOpp, fieldsChanged);//Description__c changed
            }*/
            /*SAL-7139: START: */
            if(isNew || (fieldsChanged != null && ((fieldsChanged.contains('First_Record__c') && asset.First_Record__c ) || fieldsChanged.contains('Equipment_Location_City__c')
                || fieldsChanged.contains('Equipment_Location_County__c') || fieldsChanged.contains('Equipment_Location_State__c')
                || fieldsChanged.contains('City_Code__c') || fieldsChanged.contains('County_Code__c') || fieldsChanged.contains('State_Code__c')))){
                    //oppsToUpdateById = TC_AssetTriggerHelper.setOpportunityTaxState(asset, isNew, fieldsChanged, relatedOpp, oppsToUpdateById);
                    if(!opportunityIdMap.containsKey(relatedOpp.Id)){
                        opportunityIdMap = TC_AssetTriggerHelper.setOpportunityTaxState(asset, isNew, fieldsChanged, relatedOpp, oppsToUpdateById);
            }
                    
            }
            /*SAL-7139: END: */
            if(fieldsChanged != null && fieldsChanged.contains('Tax_Date_Time__c') && asset.Equipment_Location_State__c == 'TENNESSEE'){
                updateList.add(new Asset__c (Id = asset.Id, Upfront_County_Tax_Amount__c = 0));
            }
            //Added by Rajesh Kumar(LTIMindtree)
            if(asset.Tax_Zip_Updated__c && !System.isBatch()){
                zipCopeList.add(asset);
                //setZipUpdatedFlag(asset, isNew, fieldsChanged);
            }
        }
        /*SAL-7139: START: */
        if(!opportunityIdMap.isEmpty()){
            //update opportunityIdMap.values();
            oppsToUpdateById.putAll(opportunityIdMap);
        }
        if(!oppsToUpdateById.isEmpty()){
            //update oppsToUpdateById.values();
            if (!opportunityCreatedFromQuickApp && !System.isQueueable() && !System.isBatch() && !System.isFuture()) {
                System.enqueueJob(new PEAC_GenericUpdateQueueable(oppsToUpdateById.values()));
            } else {
                update oppsToUpdateById.values();
            }
        }
        /*SAL-7139: END: */
        /*SAL-6925: STARTS: Manish - LTM: 17-03-2026: 23-03-2026: Adding dummy commit */
        //if(!updateList.isEmpty()) update updateList;
		if (!updateList.isEmpty() && !System.isQueueable() && !System.isBatch() && !System.isFuture()) { System.enqueueJob(new PEAC_GenericUpdateQueueable(updateList)); } /*23-03-2026: Adding dummy commit */
        /*SAL-6925: STARTS: ENDS: 17-03-2026: 23-03-2026: Adding dummy commit */
      /* Adding dummy commit */
        if(!zipCopeList.isEmpty()){
            PEAC_AssetTriggerHelper.setZipUpdatedFlag(zipCopeList, isNew);//Equipment_Zip__c changed
        }
    }
    
    private static void getInfoFromOthers(){
        if(assetIds.size() > 0){
            for(Asset__c related : [SELECT Id,Residual_Amount__c,Opportunity__r.StageName, Opportunity__r.Loan_Record_Type__c,Opportunity__r.Number_of_Assets__c, Opportunity__r.Invoice_Description__c,Opportunity__r.Opportunity_Booked_Date__c,Opportunity__r.AccountId,Opportunity__r.Account.Buyout__c,Opportunity__r.Vendor_Name__c,
                                    Opportunity__r.Branch__c,Opportunity__r.Originating_Business__c, Opportunity__r.Last_Date_Scorex_Retrieved__c, Opportunity__r.Equipment_Description__c, Opportunity__r.Gross_Contract__c,Opportunity__r.Tax_Exempt__c,Opportunity__r.Contract_Type__c,Opportunity__r.Vendor_Team__c,Opportunity__r.Terms__c,
                                    Opportunity__r.Purchase_Options__c,Opportunity__r.Equipment_Cost__c,Opportunity__r.Probability, Opportunity__r.Opportunity_CurrentUser_Profile__c,Opportunity__r.Account_Business_State_Province__c,Opportunity__r.Soft_Lease_Rate_Factor__c,Opportunity__r.Hard_Lease_Rate_Factor__c
                                    FROM Asset__c WHERE Id IN :assetIds]){
                                        if(opps.get(related.Opportunity__c) != null){
                                            opps.put(related.Opportunity__c, related.Opportunity__r);
                                        }
                                    }
        }
        if((Trigger.isBefore || (Trigger.isAfter && Trigger.isDelete)) && opps.size() > 0 && SL_TriggerUtil.checkForMissingInfo(opps.values())){
            opps.putAll([SELECT Id, StageName, Loan_Record_Type__c, Branch__c,Originating_Business__c,Last_Date_Scorex_Retrieved__c,Purchase_Options__c,Account_Business_State_Province__c,
                         Number_of_Assets__c, Invoice_Description__c, Equipment_Description__c, Gross_Contract__c, Equipment_Cost__c,AccountId,Account.Buyout__c,Vendor_Name__c,Terms__c,
                         Probability, Opportunity_CurrentUser_Profile__c, Opportunity_Booked_Date__c, Tax_Exempt__c,Contract_Type__c,Vendor_Team__c,Soft_Lease_Rate_Factor__c,Hard_Lease_Rate_Factor__c
                         FROM Opportunity WHERE Id IN :opps.keySet()]);
        }
    }
    
    private static void checkUpdatedFields(Map<Id, Asset__c> oldMap, Map<Id, Asset__c> newMap){
        List<String> fieldsToCheck = null;
        if(Trigger.isBefore){
            fieldsToCheck = new List<String>{'City_Code__c','Cost__c','County_Code__c','Equipment_Location_City__c','County_Tax_Percentage__c',
                'Equipment_Location_County__c','Equipment_Location_State__c','Equipment_Zip__c','Financed_Trigger__c','County_Transit_Tax_Percentage__c',
                'List_Price__c','Opportunity_Contract_Type__c','Quantity__c','Residual_Amount__c','State_Code__c','State_Tax_Percentage__c',
                'Upfront_City_Tax_Amount__c','Upfront_City_Transit_Tax_Amount__c','Upfront_County_Tax_Amount__c','City_Transit_Tax_Percentage__c',
                'Upfront_County_Transit_Tax_Amount__c','Purchase_Options__c','State_Tax_Code__c','City_Tax_Percentage__c','Residual_Percentage__c',
                'Upfront_State_Tax_Amount__c', 'Upfront_Tax_Code__c','End_User_Billing_Address__c','Usage_User_Table__c','Tax_Exempt_Equipment__c',
				'Equipment_Sub_Category__c','Override_Buyout__c','Equipment_Code__c'
		};
        }else{// isAfter
            fieldsToCheck = new List<String>{'Asset_Rental_Amount__c','City_Code__c','County_Code__c','Description__c','Tax_Date_Time__c',
                'Equipment_Full_Address__c', 'Equipment_Location_City__c', 'Equipment_Location_County__c', 'Equipment_Location_State__c', 
                'Equipment_State__c', 'Equipment_Sub_Category__c', 'Financed_Trigger__c', 'Is_Titled__c', 'List_Price__c', 
                'Model__c', 'Quantity__c', 'Residual_Amount__c', 'Serial_Number__c', 'State_Code__c','First_Record__c'};
        }
        //Commented as part of SAL-5692 Expo: Opportunity Refactor
        /*for(Id recordId : newMap.keySet()){
            SObject newObj = newMap.get(recordId);
            SObject oldObj = oldMap.get(recordId);
            SL_TriggerUtil.findChangedFields(recordId, newObj, oldObj, fieldsChangedById, fieldsToCheck);
        }*/
        SL_TriggerUtil.identifyChangedFieldsBulk(oldMap, newMap, fieldsChangedById, fieldsToCheck);
    }
    
    public static List<Opportunity> populateAssetInfoOnOpp(List<Asset__c> newList) {
        Set<String> lAssetsOpptyID = new Set<String>();
        List<Opportunity> lUpdateOpptyList = new List<Opportunity>();
        Map<String, List<Asset__c>> oppAssetsMap = new Map<String, List<Asset__c>>();//SAL-5692 Expo: Opportunity Refactor
        
        if(TC_RecursiveTriggerHelper.populateAssetInfoOnOpp) {
            return lUpdateOpptyList;
        } else{
            TC_RecursiveTriggerHelper.populateAssetInfoOnOpp = true;
        }
        for(Asset__c asset : newList){
            if(asset.Opportunity__c != null)
                lAssetsOpptyID.Add(asset.Opportunity__c);
        }
        
        if(lAssetsOpptyID.size() == 0)
            return lUpdateOpptyList;
        //Added fields from adjointed function to query (10/11/2023) C.Herrera
        List<Opportunity> lOpptyAssets = [SELECT ID,NAME,Equipment_Address__c ,Account_Business_City__c,Account_Business_Street__c,Account_Business_State_Province__c,Account_Business_Zip_Postal_Code__c
                                          //(SELECT ID, Name, Quantity__c,Equipment_Code__c,Description__c,Serial_Number__c,Model__c,Equipment_City__c,Equipment_State__c,Equipment_Street__c,Equipment_Zip__c,End_User_Billing_Address__c,Equipment_Address__c FROM Assets__r)
                                          FROM Opportunity WHERE Id IN: lAssetsOpptyID];
        //SAL-5692 Expo: Opportunity Refactor
        for(Asset__c asset : [SELECT Id,Opportunity__c,Equipment_Code__c,End_User_Billing_Address__c,Equipment_Address__c FROM Asset__c WHERE Opportunity__c IN: lAssetsOpptyID]){
            if(!oppAssetsMap.containsKey(asset.Opportunity__c)){
                oppAssetsMap.put(asset.Opportunity__c, new List<Asset__c>{asset});
            }else{
                oppAssetsMap.get(asset.Opportunity__c).add(asset);
            }
        }
        // Commented as part of SAL-5692 Expo: Opp Refactor-Chalapati Murru(LTIMindtree)
        /*for(Opportunity opty : lOpptyAssets)  {
            // Made change, swapped 33,34,35,36,37: lCounter with i
            for(Integer i=1; i<6; i++){
                if (i == 1) opty.Put('Equip_Code' + String.ValueOf(i) + '__c',null); break;
            }
            // Made change, moved counter inside loop
            Integer lCounter = 1;
            for(Asset__c ast : opty.Assets__r) {
                if (lCounter == 1) opty.Put('Equip_Code' + String.ValueOf(lCounter) + '__c',ast.Equipment_Code__c); break;
            }
            lUpdateOpptyList.Add(opty);
        }*/
        for(Opportunity opp : lOpptyAssets)  {
            opp.put('Equip_Code1__c', oppAssetsMap.get(opp.Id)[0].Equipment_Code__c);
            lUpdateOpptyList.add(opp);
        }
        //removed Update operation, calling subsequent function to clear from trigger, Update shall be performed there. C.Herrera
        return populateEquipmentAddress(lUpdateOpptyList, lOpptyAssets, oppAssetsMap);//SAL-5692 Expo: Opp Refactor-Chalapati Murru(LTIMindtree)
    }
    
    public static List<Opportunity> populateEquipmentAddress(List<Opportunity> OppsToUpdate, List<Opportunity> assetOpps, Map<String, List<Asset__c>> oppAssetsMap){
        List<Opportunity> finalUpdateList = new List<Opportunity>();
        if (TC_RecursiveTriggerHelper.populateEquipmentAddress) {
            return finalUpdateList;
        } else {
            TC_RecursiveTriggerHelper.populateEquipmentAddress = true;
        }
        //List<id> optyIds = new List<id>();
        List<opportunity> optyListToUpdate = new List<opportunity>();
        /*for(Asset__c assLst: newAssetList){ //SAL-5692 Expo: Chalapati: newAssetList parameter removed.
        	optyIds.add(assLst.Opportunity__c);
        }*/
        //List<Opportunity> lstOptyAssets = AssetOpps;//SAL-5692 Expo: Chalapati: replaced this variable with assetOpps.
        if(assetOpps.size() > 0){
            for(Opportunity opty : assetOpps){
                //List<Asset__c> lstAsset = opty.Assets__r;
                List<Asset__c> lstAsset = oppAssetsMap.get(opty.Id);//SAL-5692 Expo: Opportunity Refactor-Chalapati Murru(LTIMindtree)
                if(lstAsset.size() == 1){
                    Opportunity op = new Opportunity();
                    op.id = opty.Id;
                    if(lstAsset[0].End_User_Billing_Address__c == true){
                        op.Equipment_Address__c = opty.Account_Business_Street__c + ' ' + opty.Account_Business_City__c + ' ' +opty.Account_Business_State_Province__c + ' '+ opty.Account_Business_Zip_Postal_Code__c;
                        op.Final_Product_Loc__c = opty.Account_Business_Street__c + ' ' + opty.Account_Business_City__c + ' ' +opty.Account_Business_State_Province__c + ' '+ opty.Account_Business_Zip_Postal_Code__c;
                        optyListToUpdate.add(op);
                    }else{
                        op.Equipment_Address__c = lstAsset[0].Equipment_Address__c;
                        op.Final_Product_Loc__c = lstAsset[0].Equipment_Address__c;
                        optyListToUpdate.add(op);
                    }
                }else {
                    Opportunity op = new Opportunity();
                    op.id = opty.Id;
                    op.Final_Product_Loc__c = 'See Schedule C';
                    op.Equipment_Address__c = null;
                    optyListToUpdate.add(op);
                }
            }
        }
        List<String> finalUpdateListIds = new List<String>();
        
        for(Opportunity opU : optyListToUpdate){
            for(Opportunity opU2: OppsToUpdate){
                if(opU.Id == opU2.Id){
                    opU2.Final_Product_Loc__c = opU.Final_Product_Loc__c;
                    opU2.Equipment_Address__c = opU.Equipment_Address__c;
                    finalUpdateList.add(opU2);
                    finalUpdateListIds.add(opU2.Id);
                }
            }
        }
        for(Opportunity Ops : optyListToUpdate){
            if(!finalUpdateListIds.contains(Ops.Id)){
                finalUpdateList.add(Ops);
                finalUpdateListIds.add(Ops.Id);
            }
        }
        for(Opportunity OPS: OppsToUpdate){
            if(!finalUpdateListIds.contains(OPS.Id)){
                finalUpdateList.add(OPS);
                finalUpdateListIds.add(OPS.Id);
            }
        }
        return finalUpdateList;
    }
    //Commented as part of SAL-5692 Expo: Opportunity Refactor-Chalapati Murru
    /*static void updateProductLocationFormerPB(Asset__c theAsset, Boolean isNew, Opportunity relatedOpp, List<String> fieldsChanged){
        if(relatedOpp != null){
            Boolean changedEquimpentFullAddress = fieldsChanged != null && fieldsChanged.contains('Equipment_Full_Address__c');
            if((isNew || changedEquimpentFullAddress) && relatedOpp.Number_of_Assets__c == 1){
                Opportunity oppToUpdate = oppsToUpdateById.get(relatedOpp.Id);
                if(oppToUpdate == null){
                    oppToUpdate = relatedOpp;
                }
                oppToUpdate.Product_Location__c = theAsset.Equipment_Full_Address__c;
                oppsToUpdateById.put(oppToUpdate.Id, oppToUpdate);
            }
        }
    }*/
    //Commented as part of SAL-5692 Expo: Opportunity Refactor-Chalapati Murru
    /*static void updateInvoiceDescriptionFormerPB(Asset__c theAsset, Boolean isNew, Opportunity relatedOpp, List<String> fieldsChanged){
        if(relatedOpp != null){
            Boolean changedDescription = fieldsChanged != null && fieldsChanged.contains('Description__c');
            if(String.isNotBlank(theAsset.Description__c) 
               && (isNew || changedDescription) && String.isBlank(relatedOpp.Invoice_Description__c)){
                   Opportunity oppToUpdate = oppsToUpdateById.get(relatedOpp.Id);
                   if(oppToUpdate == null){
                       oppToUpdate = relatedOpp;
                   }
                   oppToUpdate.Invoice_Description__c = theAsset.Description__c;
                   oppsToUpdateById.put(oppToUpdate.Id, oppToUpdate);
               }
        }
    }*/
    
    //Commented as part of SAL-5692 Expo: Opportunity Refactor-Chalapati Murru
    /*static void updateAssetDescriptionFormerPB(Asset__c theAsset, Opportunity relatedOpp, List<String> fieldsChanged){
        if(relatedOpp != null){
            Boolean changedDescription = fieldsChanged != null && fieldsChanged.contains('Description__c');
            if(relatedOpp.Number_of_Assets__c == 1 && changedDescription && theAsset.Description__c != relatedOpp.Equipment_Description__c){
                Opportunity oppToUpdate = oppsToUpdateById.get(relatedOpp.Id);
                if(oppToUpdate == null){
                    oppToUpdate = relatedOpp;
                }
                oppToUpdate.Equipment_Description__c = theAsset.Description__c;
                oppsToUpdateById.put(oppToUpdate.Id, oppToUpdate);
            }
        }
    }*/

    static void setOpportunityFieldsFromAsset(Boolean isNew, Asset__c theAsset, Opportunity relatedOpp, List<String> fieldsChanged){
        if (relatedOpp != null) {
            Boolean changedEquipmentFullAddress = fieldsChanged != null && fieldsChanged.contains('Equipment_Full_Address__c');
            Boolean changedDescription = fieldsChanged != null && fieldsChanged.contains('Description__c');
            Opportunity oppToUpdate = oppsToUpdateById.get(relatedOpp.Id);

            if (oppToUpdate == null) {
                oppToUpdate = relatedOpp;
            }
            // 1) Update Product_Location__c when new or address changed and only one asset
            if ((isNew || changedEquipmentFullAddress) && relatedOpp.Number_of_Assets__c == 1) {
                oppToUpdate.Product_Location__c = theAsset.Equipment_Full_Address__c;
            }
            // 2) Update Invoice_Description__c when asset has description, new or changed, and Opp invoice description is blank
            if ((isNew || changedDescription) && String.isNotBlank(theAsset.Description__c) && String.isBlank(relatedOpp.Invoice_Description__c)) {
                oppToUpdate.Invoice_Description__c = theAsset.Description__c;
            }
            // 3) Update Equipment_Description__c when only one asset and description changed to a different value
            if (!isNew && relatedOpp.Number_of_Assets__c == 1 && changedDescription && theAsset.Description__c != relatedOpp.Equipment_Description__c) {
                oppToUpdate.Equipment_Description__c = theAsset.Description__c;
            }
            oppsToUpdateById.put(oppToUpdate.Id, oppToUpdate);
        }
    }
    
    public static void populateEquipmentAddAssetDelete(list<Asset__c> AssetList){
        List<Id> oppIds = new List<Id>();
        List<opportunity> optyListToUpdate = new List<opportunity>();
        for(Asset__c assLst: AssetList){
            oppIds.add(assLst.Opportunity__c);
        } 
        List<Opportunity> lstOptyAssets = [Select Id,Name,Equipment_Address__c ,Account_Business_City__c,Account_Business_Street__c,Account_Business_State_Province__c,Account_Business_Zip_Postal_Code__c from Opportunity where Id IN : oppIds];
        //SAL-5692 Expo: Opportunity Refactor - avoided asset sub-query using oppAssetsMap
        Map<String, List<Asset__c>> oppAssetsMap = new Map<String, List<Asset__c>>();
        for(Asset__c asset : [SELECT Id,Opportunity__c,Name,End_User_Billing_Address__c,Equipment_Address__c FROM Asset__c WHERE Opportunity__c IN: oppIds]){
            if(!oppAssetsMap.containsKey(asset.Opportunity__c)){
                oppAssetsMap.put(asset.Opportunity__c, new List<Asset__c>{asset});
            }else{
                oppAssetsMap.get(asset.Opportunity__c).add(asset);
            }
        }
        for(Opportunity opty : lstOptyAssets){
            List<Asset__c> lstAsset = oppAssetsMap.get(opty.Id);
            if(lstAsset?.size() == 1){
                Opportunity op = new Opportunity();
                op.Id = opty.Id;
                if(lstAsset[0].End_User_Billing_Address__c == true){
                    op.Equipment_Address__c = opty.Account_Business_Street__c + ' ' + opty.Account_Business_City__c + ' ' +opty.Account_Business_State_Province__c + ' '+ opty.Account_Business_Zip_Postal_Code__c;
                    op.Final_Product_Loc__c = opty.Account_Business_Street__c + ' ' + opty.Account_Business_City__c + ' ' +opty.Account_Business_State_Province__c + ' '+ opty.Account_Business_Zip_Postal_Code__c;
                    optyListToUpdate.add(op);
                }
                else{
                    op.Equipment_Address__c = lstAsset[0].Equipment_Address__c;
                    op.Final_Product_Loc__c = lstAsset[0].Equipment_Address__c;
                    optyListToUpdate.add(op);
                }
            }
            else if(lstAsset?.size() == 0){
                Opportunity op = new Opportunity();
                op.id = opty.Id;
                op.Final_Product_Loc__c = '';
                optyListToUpdate.add(op);
            }
            else {
                Opportunity op = new Opportunity();
                op.id = opty.Id;
                op.Final_Product_Loc__c = 'See Schedule C';
                op.Equipment_Address__c = null;
                optyListToUpdate.add(op);
            }
        }
        if(optyListToUpdate.size()>0){
            update optyListToUpdate;
        }
    }
}