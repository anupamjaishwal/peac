public class TC_AssetTriggerHelper {
    
    public static Marlin_Configuration__c setting = Marlin_Configuration__c.getOrgDefaults ();


    /**
     * Creates standard assets to support the CSC UCC Integration
     *
     * @param oldMap
     * @param newMap
     */
    public static void createStandardAsset (Map <Id, Asset__c> oldMap, Map <Id, Asset__c> newMap) {

        if (setting != null && setting.Disable_Standard_Asset_Generation__c) return;
        
        List <Asset> assets = new List <Asset> ();
        
        Set <Id> assetIds = new Set <Id> ();
        
        for (Asset__c asset : newMap.values ()) {
            assetIds.add (asset.Id);
        }
        
        Map <Id, Id> custStndMap = new Map <Id, Id> ();
        
        for (Asset asset : [SELECT Id, Custom_Asset__c FROM Asset WHERE Custom_Asset__c IN :assetIds]) {
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
    }

    // if we get acces to TaxRules.cls, remove to reduce CPU time
    public static void copyRentalAmountFromFormula(List<Asset__c> newList) {
        for (Asset__c asset : newList) {
            asset.Asset_Rental_Amount__c = asset.Rental_Amount_fml__c;            
        }
    }

    public static void setEquipmentState(Asset__c theAsset, Boolean isNew, List<String> fieldsChanged) {
        if(getIsToUpdateOppTaxState(isNew, fieldsChanged)){
            if(!(isnew && theAsset.Equipment_Location_City__c == null) )theAsset.Equipment_City__c = theAsset.Equipment_Location_City__c;
            if(!(isnew && theAsset.Equipment_Location_State__c == null))theAsset.Equipment_State__c = TC_BridgewareUtility.transState(theAsset.Equipment_Location_State__c);
        }
    }
    
    public static Map<Id, Opportunity> setOpportunityTaxState(Asset__c theAsset, Boolean isNew, List<String> fieldsChanged,Opportunity relatedOpp,
        Map<Id, Opportunity> oppsToUpdateById) {
        
        if(relatedOpp != null && theAsset.First_Record__c && getIsToUpdateOppTaxState(isNew, fieldsChanged)){
            Opportunity oppToUpdate = oppsToUpdateById.get(relatedOpp.Id);
            if(oppToUpdate == null){
                oppToUpdate = relatedOpp;
            }
            oppToUpdate.Tax_City__c = theAsset.Equipment_Location_City__c;
            oppToUpdate.Tax_County__c = theAsset.Equipment_Location_County__c;
            oppToUpdate.Tax_State__c = theAsset.Equipment_Location_State__c;
            oppToUpdate.Tax_City_Code__c = theAsset.City_Code__c;
            //oppToUpdate.Tax_County_Code__c = theAsset.County_Code__c;
            //oppToUpdate.Tax_State_Code__c  = theAsset.State_Code__c;
            oppsToUpdateById.put(oppToUpdate.Id, oppToUpdate);
        }
        return oppsToUpdateById;
    }

    public static Boolean getIsToUpdateOppTaxState(Boolean isNew, List<String> fieldsChanged){
        return isNew || (fieldsChanged != null && (fieldsChanged.contains('Equipment_Location_City__c')
            || fieldsChanged.contains('Equipment_Location_County__c') || fieldsChanged.contains('Equipment_Location_State__c')
            || fieldsChanged.contains('City_Code__c') || fieldsChanged.contains('County_Code__c') 
            || fieldsChanged.contains('State_Code__c')));
    }

    public static void populateCostFieldsPriceFirstAsset (Asset__c theAsset, Opportunity relatedOpp) {
        if ((theAsset.Cost__c == null || theAsset.Cost__c == 0) && relatedOpp.Equipment_Cost__c != null){
            theAsset.List_Price__c = relatedOpp.Equipment_Cost__c;
            theAsset.Cost__c = relatedOpp.Equipment_Cost__c;
            theAsset.Orig_Cost__c = relatedOpp.Equipment_Cost__c;
        }
    }

    public static void listPriceUpdated(Asset__c asset, Opportunity relatedOpp) {
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
       
        if (asset.Opportunity_Contract_Type__c == 'TL') {
            asset.Depreciation_Basis__c = cost;
            asset.Federal_Calculation_Basis__c = cost; 
            asset.State_Depreciation_Basis__c = cost;
        } else {
            asset.Depreciation_Basis__c = null;
            asset.Federal_Calculation_Basis__c = null;
            asset.State_Depreciation_Basis__c = null;
        }
    }
    
    public static Decimal calculateCost (Asset__c asset) {
        return asset.Financed_Trigger__c ? returnValue (asset.Upfront_County_Tax_Amount__c) + returnValue (asset.Upfront_City_Transit_Tax_Amount__c) + returnValue (asset.Upfront_City_Tax_Amount__c) + returnValue (asset.Upfront_County_Transit_Tax_Amount__c) + returnValue (asset.Upfront_State_Tax_Amount__c) + returnValue (asset.List_Price__c) : returnValue (asset.List_Price__c);
    }
    
    private static Decimal returnValue (Decimal value) {
        return value != null ? value : 0;
    }
    
    public static void rollupFields(Map <Id, Asset__c> oldMap, Map <Id, Asset__c> newMap, Map<Id, Opportunity> oppsToUpdateById) {
        if(TC_RecursiveTriggerHelper.rollUpCalculations){
            return;
        }

        Set<Id> oppIds = new Set<Id>();
        if (newMap != null) {
            for (Asset__c asset : newMap.values ()) {
                if (oldMap == null || asset.Residual_Amount__c  != oldMap.get (asset.Id).Residual_Amount__c
                    || asset.Cost__c != oldMap.get (asset.Id).Cost__c
                    || asset.Quantity__c != oldMap.get (asset.Id).Quantity__c) {
                    oppIds.add (asset.Opportunity__c );
                }
            }
        } else {
            for (Asset__c asset : oldMap.values ()) {
                oppIds.add (asset.Opportunity__c );
            }
        }

        if (!oppIds.isEmpty ()) {
            List <Opportunity> updateList = new List <Opportunity> ();
            for (Opportunity opp : [SELECT Id, Gross_Contract__c, Equipment_Cost__c, (SELECT Id, Residual_Amount__c, Cost__c,Opportunity_Contract_Type__c, Quantity__c FROM Assets__r) FROM Opportunity WHERE Id IN :oppIds]) {
                Opportunity withOtherChanges = oppsToUpdateById.get(opp.Id);
                Opportunity oppToUpdate = withOtherChanges != null? withOtherChanges: new Opportunity (Id = opp.Id);
                Decimal residAmt = 0;
                Decimal cost = 0;
                Decimal quantity = 0;
                Integer totalAsset = 0;
                for (Asset__c asset : opp.Assets__r) {
                    totalAsset+=1;
                    if (asset.Residual_Amount__c  != null) residAmt += asset.Residual_Amount__c ;
                    if (asset.Cost__c  != null) cost += asset.Cost__c ;
                    if (asset.Quantity__c != null) quantity += asset.Quantity__c;
                }
                oppToUpdate.Residual__c = residAmt;
                oppToUpdate.Number_of_Units__c = quantity;
                //Remove list size() to totalAsset- Rajesh Kumar(LTIMindtree)
                if (totalAsset > 0 || cost != opp.Equipment_Cost__c) {
                    oppToUpdate.Gross_Finance__c = opp.Gross_Contract__c != null ? opp.Gross_Contract__c - cost : 0 - cost;
                    oppToUpdate.Equipment_Cost__c = cost;
                }
                updateList.add(oppToUpdate);
                oppsToUpdateById.put(oppToUpdate.Id, oppToUpdate);
            }
            
            if (!updateList.isEmpty()){
                TC_RecursiveTriggerHelper.rollUpCalculations=true;
            }
        }
    }

    public static void generateTaxMatrixFormerPB(Map<Id, Asset__c> newAssets, Boolean isNew, Map<Id, List<String>> fieldsChangedById, Map<Id, Opportunity> opps) {
        if(!System.isFuture() && !System.isBatch()){
            List<String> stagesForTaxMatrix = new List<String>{'Docs In', 'Funding', 'Booking'};
            for (Asset__c newAsset : newAssets.values()) {
                Opportunity theOpp = opps.get(newAsset.Opportunity__c);
                if(theOpp != null && !theOpp.Loan_Record_Type__c && stagesForTaxMatrix.contains(theOpp.StageName)){
                    Boolean okToRun = false;
                    if(isNew){
                        okToRun = true;
                    }else {
                        List<String> changedFields = fieldsChangedById.get(newAsset.Id);
                        if(changedFields != null && (changedFields.contains('Asset_Rental_Amount__c')
                        || changedFields.contains('Equipment_Location_City__c')
                        || changedFields.contains('List_Price__c'))){
                            okToRun = true;
                        }
                    }
                    if(okToRun && !TC_RecursiveTriggerHelper.oppsAlreadyTaxMatrixRan.contains(newAsset.Opportunity__c)){
                        TC_RecursiveTriggerHelper.oppsAlreadyTaxMatrixRan.add(newAsset.Opportunity__c);
                        List<Id> oppIds = new List<Id>{newAsset.Opportunity__c};
                        if(!Test.isRunningTest()){
                            // TC_TAX.TaxRules.runAutoGenerate(oppIds);
                        }
                    }
                }
            }
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

    public static void updateTNUpfrontCountyTax (Map <Id, Asset__c> oldMap, List <Asset__c> newList) {
        List <Asset__c> updateList = new List <Asset__c> ();
        
        for (Asset__c asset : newList) {
            if (asset.Equipment_Location_State__c == 'TENNESSEE' && oldMap.get (asset.Id).Tax_Date_Time__c != asset.Tax_Date_Time__c)
                updateList.add (new Asset__c (Id = asset.Id, Upfront_County_Tax_Amount__c = 0));
        }
            
        if (!updateList.isEmpty ()) update updateList;
    }
    
    public static void roundTaxAmounts (Map <Id, Asset__c> oldMap, List <Asset__c> newList) {
        //.setScale(2, RoundingMode.HALF_UP)
        
        for (Asset__c asset : newList) {
            if (asset.Upfront_State_Tax_Amount__c != null && asset.Upfront_State_Tax_Amount__c != 0 && asset.Upfront_State_Tax_Amount__c != oldMap.get (asset.Id).Upfront_State_Tax_Amount__c) asset.Upfront_State_Tax_Amount__c = asset.Upfront_State_Tax_Amount__c.setScale(2, RoundingMode.HALF_UP);
            if (asset.Upfront_County_Transit_Tax_Amount__c != null && asset.Upfront_County_Transit_Tax_Amount__c != 0 && asset.Upfront_County_Transit_Tax_Amount__c != oldMap.get (asset.Id).Upfront_County_Transit_Tax_Amount__c) asset.Upfront_County_Transit_Tax_Amount__c = asset.Upfront_County_Transit_Tax_Amount__c.setScale(2, RoundingMode.HALF_UP);
            if (asset.Upfront_City_Tax_Amount__c != null && asset.Upfront_City_Tax_Amount__c != 0 && asset.Upfront_City_Tax_Amount__c != oldMap.get (asset.Id).Upfront_City_Tax_Amount__c) asset.Upfront_City_Tax_Amount__c = asset.Upfront_City_Tax_Amount__c.setScale(2, RoundingMode.HALF_UP);
            if (asset.Upfront_City_Transit_Tax_Amount__c != null && asset.Upfront_City_Transit_Tax_Amount__c != 0 && asset.Upfront_City_Transit_Tax_Amount__c != oldMap.get (asset.Id).Upfront_City_Transit_Tax_Amount__c) asset.Upfront_City_Transit_Tax_Amount__c = asset.Upfront_City_Transit_Tax_Amount__c.setScale(2, RoundingMode.HALF_UP);
            if (asset.Upfront_County_Tax_Amount__c != null && asset.Upfront_County_Tax_Amount__c != 0 && asset.Upfront_County_Tax_Amount__c != oldMap.get (asset.Id).Upfront_County_Tax_Amount__c ) asset.Upfront_County_Tax_Amount__c = asset.Upfront_County_Tax_Amount__c.setScale(2, RoundingMode.HALF_UP);
        }
    }
    // SAL-5233 Misael Romero
    public static void setTaxCodeTo060UpfrontTaxStateFormerPB(Asset__c theAsset, Boolean isNew, Opportunity relatedOpp, List<String> fieldsChanged){
        Boolean changedUpfrontTaxCode = fieldsChanged != null && fieldsChanged.contains('Upfront_Tax_Code__c');
        Boolean changedEquipLocationCity = fieldsChanged != null && fieldsChanged.contains('Equipment_Location_City__c');
        Boolean changedStateTaxCode = fieldsChanged != null && fieldsChanged.contains('State_Tax_Code__c');
        Boolean changedUpfrontCityTaxAmt = fieldsChanged != null && fieldsChanged.contains('Upfront_City_Tax_Amount__c');
        
        List<String> purchaseOptNotForTennessee = new List<String>{'1.00 Out', 'Put', 'Customer Owned'};
        List<String> upfrontTaxCodesTemp = new List<String>{'001', '100', '150'};
        if(theAsset.Equipment_Location_State__c == 'TENNESSEE' && !purchaseOptNotForTennessee.contains(theAsset.Purchase_Options__c)
            && theAsset.Tax_Exempt_Equipment__c == 'No' && (relatedOpp != null && relatedOpp.Tax_Exempt__c == 'No')){
            theAsset.County_Tax_Code__c = '060';
        }else{
            if(((isNew || (changedUpfrontTaxCode || changedEquipLocationCity)) || theAsset.State_Tax_Code__c != '060') 
            && upfrontTaxCodesTemp.contains(theAsset.Upfront_Tax_Code__c)){
                
                if(theAsset.Equipment_Location_City__c == 'CHICAGO'){
                    theAsset.City_Tax_Code__c = '150';
                    theAsset.County_Tax_Code__c = '060';
                    theAsset.State_Tax_Code__c = '060';
                }else{
                    if(theAsset.Equipment_Location_State__c == 'ILLINOIS'){
                        theAsset.City_Tax_Code__c = '001';
                        theAsset.County_Tax_Code__c = '001';
                        theAsset.State_Tax_Code__c = '001';
                        // theAsset.Upfront_Tax_Code__c = '001';
                    }else{
                        theAsset.City_Tax_Code__c = '060';
                        theAsset.County_Tax_Code__c = '060';
                        theAsset.State_Tax_Code__c = '060';
                    }
                }
            }else{
                if(theAsset.Equipment_Location_City__c == 'CHICAGO' && theAsset.State_Tax_Code__c == '060' 
                && theAsset.Upfront_City_Tax_Amount__c > 0
                && (isNew || (changedEquipLocationCity || changedStateTaxCode || changedUpfrontCityTaxAmt))){
                    theAsset.Upfront_City_Tax_Amount__c = 0;
                }
            }
        }
    }
    
}