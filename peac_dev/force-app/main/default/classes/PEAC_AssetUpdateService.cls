/**************************************************************************************************************
@Author: Chalapati Murru (LTIMindtree)
@Description: This will replace "TC Opportunity - Not True Lease Null Out Depreciation Section Flow"
@User Story: SAL-7139 Unable to move app from Funding to booking receiving Too many SOQL queries: 101
@Created Date: 23-Apr-2026
**************************************************************************************************************/

public class PEAC_AssetUpdateService {
    public static Map<Id, Set<String>> oppIdActionsMap = new Map<Id, Set<String>>();
    
    public static void handleAssetUpdates(Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap){
        oppIdActionsMap = new Map<Id, Set<String>>();
        Map<id,Date> commenDateMap = new Map<Id, Date>();
        Set<String> oppStages = new Set<String>{'Docs In','Funding','Booking'};
        if((!system.isBatch() && !system.isFuture() && !system.isQueueable()))
        {
            for(Opportunity opp : newMap.values()){
                //TC Opportunity - Not True Lease Null Out Depreciation Section Flow
                if(!PEAC_ConstantClass.TRUE_AND_OPERATING_LEASE.contains(opp.Contract_Type__c) && ((opp.Contract_Type__c != oldMap.get(opp.Id).Contract_Type__c)
                   || (opp.StageName != oldMap.get(opp.Id).StageName && opp.StageName == PEAC_ConstantClass.OPPORTUNITY_STAGENAME_BOOKING))){
                       setActions(opp.Id, 'ClearDeprFields');
                       
                }
                //BEGIN: TC Opportunity Set Asset Info If 031, 050 Flow
                //Condition 1 : Tax Exempt Org
                if(!opp.IsClosed && PEAC_ConstantClass.Yes.equals(opp.Tax_Exempt__c) && (opp.Tax_Exempt__c != oldMap.get(opp.Id).Tax_Exempt__c || (opp.StageName != oldMap.get(opp.Id).StageName && oppStages.contains(opp.StageName)))){
                    setActions(opp.Id, 'TaxExemptOrg');
                }
                //Condition 2 : Customer Owned
                if(opp.Purchase_Options__c == 'Customer Owned' && ((!opp.IsClosed && opp.Purchase_Options__c != oldMap.get(opp.Id).Purchase_Options__c) 
                    || (opp.StageName != oldMap.get(opp.Id).StageName && !opp.Loan_Record_Type__c && (opp.StageName == PEAC_ConstantClass.OPPORTUNITY_STAGENAME_FUNDING || opp.StageName == PEAC_ConstantClass.OPPORTUNITY_STAGENAME_BOOKING))
                    || (!opp.IsClosed && opp.Contract_Type__c != oldMap.get(opp.Id).Contract_Type__c && opp.Contract_Type__c == 'RL')))
                {
                    setActions(opp.Id, 'CustomerOwned');
                }
                //Condition 3 : Tax Exempt No
                if(opp.Tax_Exempt__c != oldMap.get(opp.Id).Tax_Exempt__c && opp.Tax_Exempt__c != 'Yes'){
                    setActions(opp.Id, 'TaxExemptNo');
                }
                //END: TC Opportunity Set Asset Info If 031, 050 Flow
                
                //Start:TC Opportunity: Booking Rules - Depreciation Dates Flow
                If(!opp.IsClosed && !opp.Loan_Record_Type__c && opp.Opportunity_Booked_Date__c !=null && oldMap.get(opp.Id).Opportunity_Booked_Date__c != opp.Opportunity_Booked_Date__c){
                   setActions(opp.Id, 'DepreciationDate'); 
                }
                if(!opp.IsClosed && !opp.Loan_Record_Type__c && opp.Commencement_Date__c !=null && oldMap.get(opp.Id).Commencement_Date__c != opp.Commencement_Date__c){
                   commenDateMap.put(opp.Id, opp.Commencement_Date__c); 
                }
                //End:TC Opportunity: Booking Rules - Depreciation Dates Flow
                
            }
            if((!system.isBatch() && !system.isFuture() && !oppIdActionsMap.isEmpty() && !system.isQueueable())){
                updateAssetFields(JSON.serialize(oppIdActionsMap),newMap);
            }
            if(!system.isBatch() && !system.isFuture() && !commenDateMap.isEmpty() && !system.isQueueable())
            {
                updateCommencDate(commenDateMap);
            }
        }
    }
    public static void updateCommencDate(Map<Id,Date> commenDateMap)
    {
        List<Blended_Income_Item__c> blendedIncomeItemList = new List<Blended_Income_Item__c>();
        blendedIncomeItemList = [SELECT Id,Opportunity__c,Begin_Date__c FROM Blended_Income_Item__c WHERE Opportunity__c IN: commenDateMap.Keyset()];
        
        if(!blendedIncomeItemList.isEmpty())
        {
          	for(Blended_Income_Item__c bItem:blendedIncomeItemList)
            {
                bItem.Begin_Date__c = commenDateMap.get(bItem.Opportunity__c);
            }
            System.enqueueJob(new PEAC_GenericUpdateQueueable(blendedIncomeItemList));  
        }
    }
    public static void setActions(id oppId, String actionName)
    {
        if(!oppIdActionsMap.containsKey(oppId)){
        	oppIdActionsMap.put(oppId, new Set<String>());	
        }
        oppIdActionsMap.get(oppId).add(actionName);
    }
    
    //@future
    public static void updateAssetFields(String serializedMap,Map<Id, Opportunity> newMap){
        List<Asset__c> assetsToUpdate = new List<Asset__c>();
        Map<Id, List<Asset__c>> oppAssets = new Map<Id, List<Asset__c>>();
        Map<Id, Set<String>> oppIdActions = (Map<Id, Set<String>>) JSON.deserialize(serializedMap, Map<Id, Set<String>>.class);
        
        for(Asset__c asset : [SELECT Id,Opportunity__c FROM Asset__c WHERE Opportunity__c IN :oppIdActions.keySet()]){
            if(oppAssets.containsKey(asset.Opportunity__c)){
                oppAssets.get(asset.Opportunity__c).add(asset);
            }else{
                oppAssets.put(asset.Opportunity__c, new List<Asset__c>{asset});
            }
        }
        for(Id oppId : oppIdActions.keySet()){
            System.debug(LoggingLevel.ERROR, 'oppAssets.get(oppId): ' + oppAssets.get(oppId));
            System.debug(LoggingLevel.ERROR, 'oppAssets.containskey(oppId): ' + oppAssets.containskey(oppId));
            if(oppAssets.containskey(oppId)){
            if(oppIdActions.get(oppId).contains('ClearDeprFields')){
                clearEquipDeprFields(oppAssets.get(oppId));
            }            
            if(oppIdActions.get(oppId).contains('TaxExemptOrg')){
                clearTaxExemptOrg(oppAssets.get(oppId));
            }
            if(oppIdActions.get(oppId).contains('CustomerOwned')){
                clearCustomerOwned(oppAssets.get(oppId));
            }
            if(oppIdActions.get(oppId).contains('TaxExemptNo')){
                clearTaxExemptNo(oppAssets.get(oppId));
            }
            if(oppIdActions.get(oppId).contains('DepreciationDate')){
                setDepreciationDate(oppAssets.get(oppId),newMap);
            }
            
            assetsToUpdate.addAll(oppAssets.get(oppId));
        }        
        }        
        if(!assetsToUpdate.isEmpty()){
            System.enqueueJob(new PEAC_GenericUpdateQueueable(assetsToUpdate));
        }
    }
    
    public static void clearEquipDeprFields(List<Asset__c> assets){
        for(Asset__c asset : assets){
            asset.ACE_Depreciation_Basis__c = null;
            asset.ADS_Class_Life_in_Months__c = null;
            asset.AMT_Depreciation_Basis__c = null;
            asset.Begin_Depreciation_Date__c = null;
            asset.Calculate_ACE_Depr__c = false;
            asset.Calculate_AMT__c = false;
            asset.Depreciation_Basis__c = null;
            asset.Federal_Calculation_Basis__c = null;
            asset.Federal_Convention__c = null;
            asset.Federal_Life__c = null;
            asset.Federal_Method__c = null;
            asset.Operating_Begin_Depreciation_Date__c = null;
            asset.Operating_Depreciation_Basis__c = null;
            asset.Operating_Depreciation_Life__c = null;
            asset.Operating_Depreciation_Method__c = null;
            asset.State_Begin_Depreciation_Date__c = null;
            asset.State_Depreciation_Basis__c = null;
            asset.State_Life_in_Months__c = null;
            asset.State_Method__c = null;
        }
    }
    
    public static void clearTaxExemptOrg(List<Asset__c> assets){
        for(Asset__c asset : assets){
            asset.City_Tax_Amount__c = 0;
            asset.City_Tax_Code__c = '031';
            asset.City_Tax_Percentage__c = 0;
            asset.City_Transit_Tax_Amount__c = 0;
            asset.City_Transit_Tax_Percentage__c = 0;
            asset.County_Tax_Amount__c = 0;
            asset.County_Tax_Code__c = '031';
            asset.County_Tax_Percentage__c = 0;
            asset.County_Transit_Tax_Amount__c = 0;
            asset.County_Transit_Tax_Percentage__c = 0;
            asset.Misc_City_Tax_Code__c = '031';
            asset.Misc_County_Tax_Code__c = '031';
            asset.Misc_State_Tax_Code__c = '031';
            asset.Responsibility_Code__c = null;
            asset.State_Tax_Amount__c = 0;
            asset.State_Tax_Code__c = '031';
            asset.State_Tax_Percentage__c = 0;
            asset.Tax_Date_Time__c = System.now();
            asset.Upfront_City_Tax_Amount__c = 0;
            asset.Upfront_City_Transit_Tax_Amount__c = 0;
            asset.Upfront_County_Tax_Amount__c = 0;
            asset.Upfront_County_Transit_Tax_Amount__c = 0;
            asset.Upfront_State_Tax_Amount__c = 0;
            asset.Upfront_Tax_Code__c = '031';
            asset.Upfront_Tax_Method__c = null;
            asset.Usage_User_Table__c = '2';
        }
    }
    
    public static void clearCustomerOwned(List<Asset__c> assets){
        for(Asset__c asset : assets){
            asset.ACE_Depreciation_Basis__c = 0;
            asset.City_Tax_Amount__c = 0;
            asset.City_Tax_Code__c = '050';
            asset.City_Tax_Percentage__c = 0;
            asset.City_Transit_Tax_Percentage__c = 0;
            asset.County_Tax_Amount__c = 0;
            asset.County_Tax_Code__c = '050';
            asset.County_Tax_Percentage__c = 0;
            asset.County_Transit_Tax_Amount__c = 0;
            asset.County_Transit_Tax_Percentage__c = 0;
            asset.LC_City_Tax_Code__c = '050';
            asset.LC_County_Tax_Code__c = '050';
            asset.LC_State_Tax_Code__c = '050';
            asset.Misc_City_Tax_Code__c = '050';
            asset.Misc_County_Tax_Code__c = '050';
            asset.Misc_State_Tax_Code__c = '050';
            asset.Property_Status__c = '10';
            asset.Responsibility_Code__c = null;
            asset.State_Tax_Amount__c = 0;
            asset.State_Tax_Code__c = '050';
            asset.State_Tax_Percentage__c = 0;
            asset.Tax_Date_Time__c = System.now();
            asset.Upfront_City_Tax_Amount__c = 0;
            asset.Upfront_City_Transit_Tax_Amount__c = 0;
            asset.Upfront_County_Tax_Amount__c = 0;
            asset.Upfront_County_Transit_Tax_Amount__c = 0;
            asset.Upfront_Responsibility_Code__c = null;
            asset.Upfront_State_Tax_Amount__c = 0;
            asset.Upfront_Tax_Code__c = '050';
            asset.Upfront_Tax_Method__c = null;
        }
    }
    
    public static void clearTaxExemptNo(List<Asset__c> assets){
        for(Asset__c asset : assets){
            asset.City_Tax_Code__c = null;
            asset.County_Tax_Code__c = null;
            asset.State_Tax_Code__c = null;
            asset.Upfront_Tax_Code__c = null;
        }
    }
    
    public static void setDepreciationDate(List<Asset__c> assets,Map<Id, Opportunity> newMap)
    {
        for(Asset__c asset : assets){
            asset.Begin_Depreciation_Date__c = newMap.get(asset.Opportunity__c).Opportunity_Booked_Date__c.date();
            asset.State_Begin_Depreciation_Date__c = newMap.get(asset.Opportunity__c).Opportunity_Booked_Date__c.date();
        }
    }
}