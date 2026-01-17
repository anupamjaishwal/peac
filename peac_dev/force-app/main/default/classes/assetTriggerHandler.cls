public with sharing class assetTriggerHandler extends SL_Trigger.baseHandler {
    private Map<Id, List<String>> fieldsChangedById = new Map<Id, List<String>>();
    Map<Id, Opportunity> opps = new Map<Id, Opportunity>();
    private Set<Id> assetIds = new Set<Id>();
    Map<Id, Opportunity> oppsToUpdateById = new Map<Id, Opportunity>();
    public static boolean runTriggerDel = false;

    public override void beforeInsert(List<SObject> newList){
        // copyOptyDescAndCostToAsset(Trigger.new);
        for (SObject obj :newList){
            getLookupMaps(obj);
        }
        beforeChangesToSelf(null, newList, true);
    }
    public override void beforeUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
        checkUpdatedFields(oldMap, newMap);
        List<Asset__c> assetList = new List<Asset__c>();
        for (Id assetId :newMap.keySet()){
            getLookupMaps(newMap.get(assetId));
            assetList.add((Asset__c)newMap.get(assetId));
        }
        beforeChangesToSelf(oldMap, newMap.values(), false);
    }
    public override void afterInsert(Map<Id, SObject> newMap){
        // List<Asset__c> assetList = new List<Asset__c>();
        for (Id assetId :newMap.keySet()){
            getLookupMaps(newMap.get(assetId));
            // assetList.add((Asset__c)newMap.get(assetId));
        }
        List<Opportunity> oppsToUpdate = populateAssetInfoOnOpp(Trigger.new);
        for(Opportunity opp: oppsToUpdate){
            this.oppsToUpdateById.put(opp.Id, opp);
        }
        TC_AssetTriggerHelper.rollupFields(null, (Map<Id, Asset__c>)newMap, this.oppsToUpdateById);
        afterChangesToOthers(true, newMap);
        callZipCodeApi((Map<Id, Asset__c>)newMap);
    }
    public override void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
        checkUpdatedFields(oldMap, newMap);
        for (Id assetId :newMap.keySet()){
            getLookupMaps(newMap.get(assetId));
        }
        List<Opportunity> oppsToUpdate = populateAssetInfoOnOpp(Trigger.new);
        for(Opportunity opp: oppsToUpdate){
            this.oppsToUpdateById.put(opp.Id, opp);
        }
        TC_AssetTriggerHelper.rollupFields((Map<Id, Asset__c>)oldMap, (Map<Id, Asset__c>)newMap, this.oppsToUpdateById);
        afterChangesToOthers(false, newMap);
    }
    public override void afterDelete(Map<Id, SObject> oldMap){
        populateEquipmentAddAssetDelete(Trigger.old);
        List<Asset__c> deletedFirstAssets = new List<Asset__c>();
        Map<Id, Asset__c> assetsToUpdateById = new Map<Id, Asset__c>();
        for (Id assetId :oldMap.keySet()){
            Asset__c deletedAsset = (Asset__c)oldMap.get(assetId);
            getLookupMaps(deletedAsset);
            if(deletedAsset.First_Record__c){
                deletedFirstAssets.add(deletedAsset);
            }
        }
        TC_AssetTriggerHelper.rollupFields((Map<Id, Asset__c>)oldMap, null, oppsToUpdateById);
        if(deletedFirstAssets.size() > 0){
            getInfoFromOthers();
            FirstAssetOnOpportunity.updateFirstAsset(deletedFirstAssets, this.opps, assetsToUpdateById);
        }
        if(assetsToUpdateById.keySet().size() > 0){
            update assetsToUpdateById.values();
        }
        if(oppsToUpdateById.keySet().size() > 0){
            update oppsToUpdateById.values();
        }
    }

    private void checkUpdatedFields(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){
        List<String> fieldsToCheck = null;
        if(Trigger.isBefore){
            fieldsToCheck = new List<String>{'City_Code__c', 'Cost__c', 'County_Code__c', 'Equipment_Location_City__c', 
                'Equipment_Location_County__c', 'Equipment_Location_State__c','Equipment_Zip__c', 'Financed_Trigger__c',
                'List_Price__c', 'Opportunity_Contract_Type__c', 'Quantity__c', 'Residual_Amount__c', 'State_Code__c', 'State_Tax_Code__c', 
                'Upfront_City_Tax_Amount__c', 'Upfront_City_Transit_Tax_Amount__c', 'Upfront_County_Tax_Amount__c', 
                'Upfront_County_Transit_Tax_Amount__c',
                'Upfront_State_Tax_Amount__c', 'Upfront_Tax_Code__c'};
        }else{// isAfter
            fieldsToCheck = new List<String>{'Asset_Rental_Amount__c', 'City_Code__c', 'County_Code__c', 'Description__c', 
                'Equipment_Full_Address__c', 'Equipment_Location_City__c', 'Equipment_Location_County__c', 'Equipment_Location_State__c', 
                'Equipment_State__c', 'Equipment_Sub_Category__c', 'Financed_Trigger__c', 'Is_Titled__c', 'List_Price__c', 
                'Model__c', 'Quantity__c', 'Residual_Amount__c', 'Serial_Number__c', 'State_Code__c'};
        }
        
        for(Id recordId : newMap.keySet()){
            SObject newObj = newMap.get(recordId);
            SObject oldObj = oldMap.get(recordId);
            SL_TriggerUtil.findChangedFields(recordId, newObj, oldObj, fieldsChangedById, fieldsToCheck);
        }
    }

    private void getLookupMaps(SObject obj){
        Asset__c theAsset = (Asset__c)obj;
        if(theAsset.Opportunity__c != null){
            this.opps.put(theAsset.Opportunity__c, new Opportunity());
        }
        if(theAsset.Id != null){
            this.assetIds.add(theAsset.Id);           
        }
    }

    private void getInfoFromOthers(){
        if(assetIds.size() > 0){
            for(Asset__c related : [SELECT Id, Opportunity__r.StageName, Opportunity__r.Loan_Record_Type__c,
                Opportunity__r.Branch__c, Opportunity__r.Last_Date_Scorex_Retrieved__c, 
                Opportunity__r.Number_of_Assets__c, Opportunity__r.Invoice_Description__c,
                Opportunity__r.Equipment_Description__c, Opportunity__r.Gross_Contract__c, Opportunity__r.Equipment_Cost__c,
                Opportunity__r.Probability, Opportunity__r.Opportunity_CurrentUser_Profile__c, Opportunity__r.Opportunity_Booked_Date__c,
                Opportunity__r.Tax_Exempt__c
                FROM Asset__c WHERE Id IN :assetIds]){
                if(this.opps.get(related.Opportunity__c) != null){
                    this.opps.put(related.Opportunity__c, related.Opportunity__r);
                }
            }
        }
        if((Trigger.isBefore || (Trigger.isAfter && Trigger.isDelete)) && this.opps.size() > 0 && SL_TriggerUtil.checkForMissingInfo(this.opps.values())){
            this.opps.putAll([SELECT Id, StageName, Loan_Record_Type__c, Branch__c, Last_Date_Scorex_Retrieved__c,
                Number_of_Assets__c, Invoice_Description__c, Equipment_Description__c, Gross_Contract__c, Equipment_Cost__c,
                Probability, Opportunity_CurrentUser_Profile__c, Opportunity_Booked_Date__c, Tax_Exempt__c
                FROM Opportunity WHERE Id IN :this.opps.keySet()]);
        }
    }
	
    private void beforeChangesToSelf(Map<Id, SObject> oldMap, List<SObject> newList, Boolean isNew){
        Set<Id> OppsWithfirstAsset = new Set<Id>();
        getInfoFromOthers();
        // TC_AssetTriggerHelper.updateCostFieldsOnAsset((List<Asset__c>)newList, this.opps);
        for(SObject obj : newList){
            Asset__c theAsset = (Asset__c) obj;
            List<String> fieldsChanged = fieldsChangedById.get(theAsset.Id);
            Opportunity relatedOpp = this.opps.get(theAsset.Opportunity__c);
            if(isNew){
                if(relatedOpp != null && relatedOpp.Number_of_Assets__c == 0
                    && !OppsWithfirstAsset.contains(theAsset.Opportunity__c)){
                    theAsset.First_Record__c = true;
                    OppsWithfirstAsset.add(theAsset.Opportunity__c);
                    // moved copyOptyDescAndCostToAsset functionality here
                    if(relatedOpp.Equipment_Description__c != null && theAsset.Description__c == null){
                        theAsset.Description__c = relatedOpp.Equipment_Description__c;
                       
                    }
                    if(relatedOpp.Equipment_Cost__c != null && theAsset.Cost__c == null){
                        theAsset.Cost__c = (Decimal)relatedOpp.Equipment_Cost__c;
                    }
                    TC_AssetTriggerHelper.populateCostFieldsPriceFirstAsset(theAsset, relatedOpp);
                }
            }
            if((isNew && (theAsset.List_Price__c != null || theAsset.Cost__c != null)) 
            || (fieldsChanged != null && (fieldsChanged.contains('List_Price__c')
            || fieldsChanged.contains('Cost__c') || fieldsChanged.contains('Upfront_State_Tax_Amount__c')
            || fieldsChanged.contains('Upfront_County_Transit_Tax_Amount__c')
            || fieldsChanged.contains('Upfront_City_Tax_Amount__c')
            || fieldsChanged.contains('Upfront_City_Transit_Tax_Amount__c')
            || fieldsChanged.contains('Upfront_County_Tax_Amount__c') 
            || fieldsChanged.contains('Financed_Trigger__c')))){
                TC_AssetTriggerHelper.listPriceUpdated(theAsset, relatedOpp);
                TC_AssetTriggerHelper.costUpdated(theAsset, relatedOpp);
            }
            calculateManagerResidual(theAsset);
            theAsset.Dealer_Residual__c = theAsset.Residual_Amount__c;
            setZipUpdatedFlag(theAsset, isNew, fieldsChanged);
            bookingRulesDefaultDepreciationFormerPB(theAsset, isNew, fieldsChanged, relatedOpp);
            TC_AssetTriggerHelper.setEquipmentState(theAsset, isNew, fieldsChanged);
            TC_AssetTriggerHelper.setTaxCodeTo060UpfrontTaxStateFormerPB(theAsset, isNew, relatedOpp, fieldsChanged); // SAL-5233 Misael Romero
        }
    }

    private void afterChangesToOthers(Boolean isNew, Map<Id, SObject> newMap){
        Map<Id, Asset__c> newAssets = (Map<Id, Asset__c>)newMap;
        getInfoFromOthers();
        TC_CreditDecision.runRules(newAssets, isNew, fieldsChangedById, opps);
        TC_AssetTriggerHelper.generateTaxMatrixFormerPB(newAssets, isNew, fieldsChangedById, opps);
        for(SObject obj :newMap.values()){
            Asset__c theAsset = (Asset__c) obj;
            Opportunity relatedOpp = this.opps.get(theAsset.Opportunity__c);
            List<String> fieldsChanged = fieldsChangedById.get(theAsset.Id);
            DupeRuleMessage(theAsset, isNew, fieldsChanged);
            updateProductLocationFormerPB(theAsset, isNew, relatedOpp, fieldsChanged);
            updateInvoiceDescriptionFormerPB(theAsset, isNew, relatedOpp, fieldsChanged);
            updateAssetDescriptionFormerPB(theAsset, relatedOpp, fieldsChanged);
            this.oppsToUpdateById = TC_AssetTriggerHelper.setOpportunityTaxState(theAsset, isNew, fieldsChanged, relatedOpp, this.oppsToUpdateById);
            //Added by Rajesh Kumar(LTIMindtree)
             setZipUpdatedFlag(theAsset, isNew, fieldsChanged);
        }
        if(this.oppsToUpdateById.values().size() > 0){
            update this.oppsToUpdateById.values();
        }
    }

    public static List<Opportunity> populateAssetInfoOnOpp(List<Asset__c> newList) {
        List<Opportunity> lUpdateOpptyList = new List<Opportunity>();
        
        if (TC_RecursiveTriggerHelper.populateAssetInfoOnOpp) {
            return lUpdateOpptyList;
        } else {
            TC_RecursiveTriggerHelper.populateAssetInfoOnOpp = true;
        }
        
        
        Set<String> lAssetsOpptyID = new Set<String>();
        
        
        for(Asset__c asset : newList){
            
            if(asset.Opportunity__c != null)
                lAssetsOpptyID.Add(asset.Opportunity__c);
        }
        
        if(lAssetsOpptyID.Size()  == 0)
            return lUpdateOpptyList;
        //Added fields from adjointed function to query (10/11/2023) C.Herrera
        List<Opportunity> lOpptyAssets = [SELECT ID,NAME,Equipment_Address__c ,Account_Business_City__c,Account_Business_Street__c,Account_Business_State_Province__c,Account_Business_Zip_Postal_Code__c,
                                          (SELECT ID, Name, Quantity__c,Equipment_Code__c,Description__c,Serial_Number__c,Model__c,Equipment_City__c,Equipment_State__c,Equipment_Street__c,Equipment_Zip__c,End_User_Billing_Address__c,Equipment_Address__c FROM Assets__r)
                                          FROM OPPORTUNITY WHERE ID IN: lAssetsOpptyID];
        
        for(Opportunity opty : lOpptyAssets)  {
            
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
            
        }
        
        //removed Update operation, calling subsequent function to clear from trigger, Update shall be performed there. C.Herrera
        return populateEquipmentAddress(newList, lUpdateOpptyList, lOpptyAssets);
    }
    
    
    // public static void copyOptyDescAndCostToAsset(list<Asset__c> newAssetList){
    //     List<id> optyIds = new List<id>();
    //     for(Asset__c assLst: newAssetList){
    //         optyIds.add(assLst.Opportunity__c);             
    //     }
    //     if(optyIds.Size()  == 0){
    //         return;
    //     }
    //     else{
    //         map<id,opportunity> optyRec = new map<id,opportunity>([SELECT Equipment_Description__c,Equipment_Cost__c,Oppty_Desc_Copy__c,(select id,name from Assets__r) from opportunity where id in :optyIds]);
    //         for(Asset__c assetRec: newAssetList){   
    //             opportunity opp = optyRec.get(assetRec.Opportunity__c);
    //             if(opp != null && opp.Assets__r != null && opp.Assets__r.size()<=0){
    //                 if(optyRec.get(assetRec.Opportunity__c).get('Equipment_Description__c') != null && assetRec.Description__c == null){
    //                     assetRec.Description__c = string.valueOf(optyRec.get(assetRec.Opportunity__c).get('Equipment_Description__c'));
                       
    //                 }
    //                 if(optyRec.get(assetRec.Opportunity__c).get('Equipment_Cost__c') != null && assetRec.Cost__c == null){
    //                     assetRec.Cost__c = (Decimal)optyRec.get(assetRec.Opportunity__c).get('Equipment_Cost__c');
    //                 }
    //             }
    //         }
    //     }
    // }
    
    public static List<Opportunity> populateEquipmentAddress(list<Asset__c> newAssetList, List<Opportunity> OppsToUpdate, List<Opportunity>AssetOpps){
        List<Opportunity> finalUpdateList = new List<Opportunity>();
        if (TC_RecursiveTriggerHelper.populateEquipmentAddress) {
            return finalUpdateList;
        } else {
            TC_RecursiveTriggerHelper.populateEquipmentAddress = true;
        }
        List<id> optyIds = new List<id>();
        list<opportunity> optyListToUpdate = new list<opportunity>();
        for(Asset__c assLst: newAssetList){
            optyIds.add(assLst.Opportunity__c);             
        } 
        
        List<Opportunity> lstOptyAssets = AssetOpps;
        if(lstOptyAssets.size()>0){
            for(Opportunity opty : lstOptyAssets){
                List<Asset__c> lstAsset = opty.Assets__r;
                if(lstAsset.size() == 1){
                    Opportunity op = new Opportunity();
                    op.id = opty.Id;
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
                else {
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
        for(Opportunity Ops:optyListToUpdate){
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
    
    
    public static void populateEquipmentAddAssetDelete(list<Asset__c> AssetList){
        if(runTriggerDel == true){
            return;
        }
        else{
            runTriggerDel = true;
        }
        
        List<id> optyIds = new List<id>();
        list<opportunity> optyListToUpdate = new list<opportunity>();
        for(Asset__c assLst: AssetList){
            optyIds.add(assLst.Opportunity__c);             
        } 
        
        List<Opportunity> lstOptyAssets = [Select Id,Name,Equipment_Address__c ,Account_Business_City__c,Account_Business_Street__c,Account_Business_State_Province__c,Account_Business_Zip_Postal_Code__c,(select id,name,End_User_Billing_Address__c,Equipment_Address__c  from Assets__r) from Opportunity where Id in : optyIds ];
        
        for(Opportunity opty : lstOptyAssets){
            List<Asset__c> lstAsset = opty.Assets__r;
            if(lstAsset.size() == 1){
                Opportunity op = new Opportunity();
                op.id = opty.Id;
                
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
            else if(lstAsset.size() == 0){
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
    
    void updateProductLocationFormerPB(Asset__c theAsset, Boolean isNew, Opportunity relatedOpp, List<String> fieldsChanged){
        if(relatedOpp != null){
            Boolean changedEquimpentFullAddress = fieldsChanged != null && fieldsChanged.contains('Equipment_Full_Address__c');
            if((isNew || changedEquimpentFullAddress) && relatedOpp.Number_of_Assets__c == 1){
                Opportunity oppToUpdate = this.oppsToUpdateById.get(relatedOpp.Id);
                if(oppToUpdate == null){
                    oppToUpdate = relatedOpp;
                }
                oppToUpdate.Product_Location__c = theAsset.Equipment_Full_Address__c;
                this.oppsToUpdateById.put(oppToUpdate.Id, oppToUpdate);
            }
        }
    }

    void updateInvoiceDescriptionFormerPB(Asset__c theAsset, Boolean isNew, Opportunity relatedOpp, List<String> fieldsChanged){
        if(relatedOpp != null){
            Boolean changedDescription = fieldsChanged != null && fieldsChanged.contains('Description__c');
            if(String.isNotBlank(theAsset.Description__c) 
                && (isNew || changedDescription) && String.isBlank(relatedOpp.Invoice_Description__c)){
                Opportunity oppToUpdate = this.oppsToUpdateById.get(relatedOpp.Id);
                if(oppToUpdate == null){
                    oppToUpdate = relatedOpp;
                }
                oppToUpdate.Invoice_Description__c = theAsset.Description__c;
                this.oppsToUpdateById.put(oppToUpdate.Id, oppToUpdate);
            }
        }
    }

    void updateAssetDescriptionFormerPB(Asset__c theAsset, Opportunity relatedOpp, List<String> fieldsChanged){
        if(relatedOpp != null){
            Boolean changedDescription = fieldsChanged != null && fieldsChanged.contains('Description__c');
            if(relatedOpp.Number_of_Assets__c == 1 
                && changedDescription &&  theAsset.Description__c != relatedOpp.Equipment_Description__c){
                Opportunity oppToUpdate = this.oppsToUpdateById.get(relatedOpp.Id);
                if(oppToUpdate == null){
                    oppToUpdate = relatedOpp;
                }
                oppToUpdate.Equipment_Description__c = theAsset.Description__c;
                this.oppsToUpdateById.put(oppToUpdate.Id, oppToUpdate);
            }
        }
    }
    
    void calculateManagerResidual(Asset__c theAsset){
        Decimal residualAmount = theAsset.Residual_Amount__c != null? theAsset.Residual_Amount__c: 0;
        switch on theAsset.Purchase_Options__c {
            when '1.00 Out', 'Assign Resid No Renewal'{
                theAsset.Manager_Residual__c = 0.00;
            }
            when 'FMV'{
                switch on theAsset.Equipment_Sub_Category__c {
                    when 'Computer Hard/Soft (Gen)'{
                        theAsset.Manager_Residual__c = 1.75 * residualAmount;
                    }
                    when 'Office Equipment(General)', 'Copier - Used', 'Copiers', 'Fax', 'LCD Projector', 'Mailing'{
                        theAsset.Manager_Residual__c = 2.50 * residualAmount;
                    }
                    when 'Commerce & Indus (Gen)', 'Commercial Cleaning', 'Construction (General)', 'Landscaping'{
                        theAsset.Manager_Residual__c = 3 * residualAmount;
                    }
                    when else {
                        theAsset.Manager_Residual__c = 1.5 * residualAmount;
                    }
                }
                
            }
            // the below are currently inactive values for theAsset.Purchase_Options__c so this is unreachable
            /*
            when 'FMV - Capped', 'FMV-Used Equipment', 'FMV-Muni', 'FMV No Renewal', 'FMV Cap No Renewal',
                 'FMV Used No Renewal', 'FMV Muni No Renewal'{
                if(theAsset.Equipment_Sub_Category__c == 'Office Equipment(General)' || theAsset.Equipment_Sub_Category__c == 'Copier - Used'
                  || theAsset.Equipment_Sub_Category__c == 'Copiers' || theAsset.Equipment_Sub_Category__c == 'Fax'
                  || theAsset.Equipment_Sub_Category__c == 'LCD Projector' || theAsset.Equipment_Sub_Category__c == 'Mailing'){
                    theAsset.Manager_Residual__c = 2.50 * residualAmount;
                } else {
                    theAsset.Manager_Residual__c = residualAmount;
                }
            }*/
            when else{
                theAsset.Manager_Residual__c = residualAmount;
            }
        }
    }
    public static void DupeRuleMessage(Asset__c asset, Boolean isNew, List<String> fieldsChanged){
        if(isNew || (fieldsChanged != null && (fieldsChanged.contains('Serial_Number__c') 
        || fieldsChanged.contains('Equipment_Sub_Category__c') || fieldsChanged.contains('Model__c')
        || fieldsChanged.contains('Equipment_State__c')))){// just check if the fields involved in the duplicate rule are changed, this reduces CPU time
            String dupeId = SL_DealerPortalCreateApp.getDupeId(asset);
            System.debug('Dupe Found: '+ dupeID);
            if (dupeID<>null){
                Database.SaveResult sr = EventBus.publish(new SL_BW_Integration_Status__e(Message__c='STOP! Please recheck the serial number, this equipment is currently listed on another asset/account.',Record_Id__c = asset.Id, Status__c='Error'));
                Database.SaveResult sr2 = EventBus.publish(new SL_BW_Integration_Status__e(Message__c='STOP! Please recheck the serial number, this equipment is currently listed on another asset/account.',Record_Id__c = asset.Opportunity__c, Status__c='Error'));
                System.debug(sr.isSuccess());
            }
        }
    }

    static void setZipUpdatedFlag(Asset__c theAsset, Boolean isNew, List<String> fieldsChanged) {
        if (Trigger.isBefore && !isNew && String.isNotEmpty(theAsset.Equipment_Zip__c)
        && fieldsChanged != null && fieldsChanged.contains('Equipment_Zip__c')){// SAL-5596 Misael Romero
            theAsset.Tax_Zip_Updated__c = true;
        }
        if(Trigger.isAfter && theAsset.Tax_Zip_Updated__c && !System.isBatch()){
            TC_BridgewareUtility.selectZipGeoCode(theAsset.Id, theAsset.Equipment_Zip__c);
        }
    }
    /*********************************************************************************************************
     * Created By:Rajesh Kumar(LTIMindtree)
     * Description:Call this method after saving Asset record to set updated zip code related field from API Call
     * Created Date:05/19/2025
     * Parameter1:List of new assets
     * Return:None
     *********************************************************************************************************/
    static void callZipCodeApi(Map<Id,Asset__c> assetMap) {
        List<Asset__c> newassetList = new List<Asset__c>();
        for(asset__c newAsset: assetMap.Values())
        {
            if (String.isNotEmpty(newAsset.Equipment_Zip__c))
            {
                newassetList.add(newAsset);
            }
        }
        if(!system.isBatch() && !newassetList.isEmpty())
        {
            PEAC_SelectZipGeoCodeBatch batchJob1 = New PEAC_SelectZipGeoCodeBatch(newassetList);
        	Database.executeBatch(batchJob1, Integer.ValueOf(Label.PEAC_SelectZipGeoCodeBatch_Limit)); // Adjust the batch size

        }
        
    }

    public static void bookingRulesDefaultDepreciationFormerPB(Asset__c theAsset, Boolean isNew, List<String> fieldsChanged, Opportunity relatedOpp){
        if(theAsset.Opportunity_Contract_Type__c == 'TL'){
            if(isNew || (fieldsChanged != null && fieldsChanged.contains('Opportunity_Contract_Type__c'))){
                Datetime oppBooked1 = relatedOpp != null? relatedOpp.Opportunity_Booked_Date__c: null;
                Date oppBookedDate = oppBooked1 != null? oppBooked1.dateGMT(): null;
                theAsset.Begin_Depreciation_Date__c = oppBookedDate;
                theAsset.Calculate_ACE_Depr__c = true;
                theAsset.Calculate_AMT__c = true;
                theAsset.Depreciation_Basis__c = theAsset.Cost__c;
                theAsset.Federal_Calculation_Basis__c = theAsset.Cost__c;
                theAsset.Federal_Convention__c = '6';
                theAsset.Federal_Life__c = 60;
                theAsset.Federal_Method__c = '58';
                theAsset.State_Begin_Depreciation_Date__c = oppBookedDate;
                theAsset.State_Depreciation_Basis__c = theAsset.Cost__c;
                theAsset.State_Life_in_Months__c = 60;
                theAsset.State_Method__c = '3';
            }
            if(theAsset.State_Tax_Code__c == '031' || theAsset.State_Tax_Code__c == '036'){
                theAsset.Federal_Method__c = '21'; // S/L - No Bonus
            }
        }
    }
    
}