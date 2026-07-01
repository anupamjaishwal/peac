/**************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This class is used to import csv file into Salesforce records
@User Story:SAL-5080
@Created Date:January-24-2025
@Modified: Suraj Harichandan (LTIMindtree) for SAL-6285 Project Expo - RF: Asset Selection Screen for Multi-County Listings
@Modified Date: December 19, 2025
**************************************************************************************************************/

public with sharing class PEAC_ImportCSVController {
   
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method is converting CSV data into records
    @Parameters:CSV data, parent record id, object name, parent field name
    @Return: String
    **************************************************************************************************************/
    @AuraEnabled
    public static String saveFile(String base64Data, String oppId, Map<String,String> fieldsDataTypes, Map<String,Map<String,String>> picklistFieldsValueMap){
        String uploadMessage = '';
        String trueVal = 'True';
        try{
            List<Opportunity> oppList = [SELECT Id, Account_Business_Street__c,Account_Business_Street2__c,Account_Business_City__c,
                                            Account_Business_State_Province__c,Account_Business_Zip_Postal_Code__c 
                                         FROM Opportunity WHERE Id =: oppId LIMIT 1];
            //system.debug('Equipment Code picklist values ==> '+picklistFieldsValueMap.get('Equipment_Code__c'));
            //system.debug('Office Equipment - Copiers API Name ==> '+picklistFieldsValueMap.get('Equipment_Code__c').get('Office Equipment - Copiers'));
            //system.debug('model ==> '+fieldsDataTypes.get('Model__c'));
            String data = JSON.deserializeUntyped(base64Data).toString();
            List<Asset__c> assetList = new List<Asset__c> ();
            List<String> lstCSVLines = data.split('\n');
            List<String> fieldAPIList =  new List<String>();

            for(String fields : lstCSVLines[0].split(',')){
                fieldAPIList.Add(fields.trim());
            }
            for(Integer i = 1; i < lstCSVLines.size(); i++){
                Asset__c asset = new Asset__c();
                String csvLine = lstCSVLines[i];
                List<String> csvRowData = new List<String>();

                for(String column : csvLine.split(',')){
                    column = column.replaceAll(':quotes:', '').replaceAll(':comma:', ',');
                    csvRowData.add(column);
                }
                for(Integer j = 0; j < fieldAPIList.size(); j++){
                    if(String.isNotBlank(csvRowData[j]))
                        asset.put(fieldAPIList[j], getFieldvalueAsObject(fieldAPIList[j], csvRowData[j], fieldsDataTypes, picklistFieldsValueMap));
                }
                if(asset.get('Id') == null)
                {
                	asset.put('Opportunity__c', oppId);   
                }
                if(trueVal.EqualsIgnoreCase(String.Valueof(asset.get('End_User_Billing_Address__c')))){
                    asset.put('Equipment_Street__c', oppList[0].Account_Business_Street__c);
                    asset.put('Equipment_Address_2__c', oppList[0].Account_Business_Street2__c);
                    asset.put('Equipment_City__c', oppList[0].Account_Business_City__c);
                    asset.put('Equipment_State__c', oppList[0].Account_Business_State_Province__c);
                    asset.put('Equipment_Zip__c', oppList[0].Account_Business_Zip_Postal_Code__c);
                }
                assetList.add(asset);
            }
            if(!assetList.isEmpty()){
                String jobId = Database.executeBatch(new PEAC_CreateAssetsBatch(assetList,oppId), Integer.Valueof(Label.PEAC_CreateAssetsBatch_Limit));
                //String jobId = Database.executeBatch(new PEAC_CreateAssetsBatch(assetList), Integer.Valueof(Label.PEAC_CreateAssetsBatch_Limit));
                uploadMessage = 'Success';
            }
        }
        catch(Exception ex){
            throw new AuraHandledException(Label.PEAC_Asset_Upload_Message + ex.getmessage());
        }
        return uploadMessage;
    }

    /**************************************************************************************************************
    @Author:Chalapati Murru (LTIMindtree)
    @Description: This method will return the Field Datatypes
    @UserStory: SAL-5692 Expo: Opportunity Refactor
    @Return: Map<String, String>
    **************************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static String getFieldDataTypes(){
        Map<String,String> fieldsDataTypes = new Map<String,String>();
		PEAC_BulkAssetsUpload__mdt metaDataRec = [SELECT Value__c FROM PEAC_BulkAssetsUpload__mdt WHERE DeveloperName = 'FieldsAPINames_DataTypes' LIMIT 1];
		
        for(String fieldName: metaDataRec.Value__c.split(',')){
         	fieldsDataTypes.put(fieldName.split('\\|\\|')[0], fieldName.split('\\|\\|')[1]);
        }
        return JSON.serialize(fieldsDataTypes);
    }
    
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method will return the Picklist's value-API name map
    @Parameter:Object Name, Field API, Field Value
    @Return: Map<String, Map<String, String>>
    **************************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static String getPicklistLabelAPIs(String strObjectName, List<String> fieldAPIList){
        Map<String,Map<String,String>> picklistFieldsValueMap = new Map<String,Map<String,String>>();
        Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get(strObjectName).getDescribe();
        
        for(String fieldName: fieldAPIList){
            Schema.DescribeFieldResult fieldDescribe = objectDescribe.fields.getMap().get(fieldName).getDescribe();
            if(fieldDescribe.getType() == Schema.DisplayType.Picklist){
                List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
                picklistFieldsValueMap.put(fieldName, new Map<String,String>());
                for(Schema.PicklistEntry picklistEntry : picklistValues){
                    picklistFieldsValueMap.get(fieldName).put(picklistEntry.getLabel(), picklistEntry.getValue());
                }
            }
        }
        return JSON.serialize(picklistFieldsValueMap);
    }
    
    /**************************************************************************************************************
    @Author: Chalapati Murru (LTIMindtree)
    @Description: Compare field type and convert the value according to field type 
    @UserStory: SAL-5692 Expo: Opportunity Refactor
    @Return: Object
    **************************************************************************************************************/
    
    public static Object getFieldvalueAsObject(String fieldname, String stringValue, Map<String,String> fieldsDataTypes, Map<String,Map<String,String>> picklistFieldsValueMap) {
        switch on fieldsDataTypes.get(fieldname){
            when 'STRING','ID'{
                String strValue = stringValue;
                if(String.isNotBlank(strValue) && picklistFieldsValueMap?.containsKey(fieldname)){
                    strValue = picklistFieldsValueMap?.get(fieldname)?.get(stringValue);
                }
                return strValue;
            }
            when 'DATE'{
                return Date.valueOf(stringValue);
            }
            when 'DOUBLE'{
                return Double.valueOf(stringValue);
            }
            when 'CURRENCY', 'PERCENT', 'DECIMAL'{
                return Decimal.valueOf(stringValue);
            }
            when 'INTEGER'{
                return Integer.valueOf(stringValue);
            }
            when 'BOOLEAN'{
                return Boolean.valueOf(stringValue);
            }
            when else{
                return String.valueOf(stringValue);
            }
        }
    }
    
    /**************************************************************************************************************
    @Author: Suraj Harichandan (LTIMindtree)
    @Description: Returns paginated list of discrepant assets (Multiple_Counties__c = true) for an Opportunity
    @UserStory: SAL-6285
    @Created Date: December-19-2025
    @Parameter: oppId - Opportunity Id, pageNumber - current page (1-indexed), pageSize - records per page
    @Return: List<Asset__c>
    **************************************************************************************************************/
    @AuraEnabled
    public static List<Asset__c> getDiscrepantAssets(String oppId, Integer pageNumber, Integer pageSize) {
        try {
            Integer offset = (pageNumber - 1) * pageSize;
            List<Asset__c> discrepantAssets = [
                SELECT Id, Name, Serial_Number__c, Description__c, Model__c, Equipment_Zip__c,
                       Equipment_Street__c, Equipment_Address_2__c, Equipment_City__c, 
                       Equipment_State__c, Equipment_Location_City__c, Equipment_Location_County__c,
                       Equipment_Location_State__c, City_Code__c, County_Code__c, State_Code__c,
                       Multiple_Counties__c, List_Price__c, Quantity__c, New_Used__c, 
                       Equipment_Code__c, Equipment_Sub_Category__c
                FROM Asset__c 
                WHERE Opportunity__c = :oppId 
                AND Multiple_Counties__c = true
                ORDER BY CreatedDate DESC
                LIMIT :pageSize 
                OFFSET :offset
            ];
            return discrepantAssets;
        } catch (Exception ex) {
            throw new AuraHandledException('Error fetching discrepant assets: ' + ex.getMessage());
        }
    }
    
    /**************************************************************************************************************
    @Author: Suraj Harichandan (LTIMindtree)
    @Description: Returns count of discrepant assets for pagination
    @UserStory: SAL-6285
    @Created Date: December-19-2025
    @Parameter: oppId - Opportunity Id
    @Return: Integer - total count
    **************************************************************************************************************/
    @AuraEnabled
    public static Integer getDiscrepantAssetCount(String oppId) {
        try {
            return [SELECT COUNT() FROM Asset__c WHERE Opportunity__c = :oppId AND Multiple_Counties__c = true];
        } catch (Exception ex) {
            throw new AuraHandledException('Error counting discrepant assets: ' + ex.getMessage());
        }
    }
    
    /**************************************************************************************************************
    @Author: Suraj Harichandan (LTIMindtree)
    @Description: Returns tax jurisdictions for a given zip code from Bridgeware API
    @UserStory: SAL-6285
    @Created Date: December-19-2025
    @Parameter: zipCode - Equipment zip code
    @Return: List<Map<String, String>> - list of jurisdiction options with label and value
    **************************************************************************************************************/
    @AuraEnabled
    public static List<Map<String, String>> getTaxJurisdictionsForZip(String zipCode) {
        try {
            List<Map<String, String>> jurisdictionOptions = new List<Map<String, String>>();
            Set<String> uniqueZips = new Set<String>{zipCode};
            
            Map<String, Map<String, List<TC_BridgewareTaxJurisdiction>>> zipRespsMap = 
                PEAC_BridgewareSelectZipGeoCodes.getZipTaxCodes(uniqueZips);
            
            if (zipRespsMap.containsKey(zipCode) && zipRespsMap.get(zipCode).containsKey('Assets')) {
                List<TC_BridgewareTaxJurisdiction> jurisdictions = zipRespsMap.get(zipCode).get('Assets');
                for (TC_BridgewareTaxJurisdiction jurisdiction : jurisdictions) {
                    Map<String, String> option = new Map<String, String>();
                    String label = 'City: ' + jurisdiction.city + ' | County: ' + jurisdiction.county + ' | State: ' + jurisdiction.state;
                    option.put('label', label);
                    option.put('value', JSON.serialize(jurisdiction));
                    jurisdictionOptions.add(option);
                }
            }
            return jurisdictionOptions;
        } catch (Exception ex) {
            throw new AuraHandledException('Error fetching tax jurisdictions: ' + ex.getMessage());
        }
    }
    
    /**************************************************************************************************************
    @Author: Suraj Harichandan (LTIMindtree)
    @Description: Saves selected tax jurisdiction to an asset record
    @UserStory: SAL-6285
    @Created Date: December-19-2025
    @Parameter: assetId - Asset Id, taxJurisdictionJson - JSON string of TC_BridgewareTaxJurisdiction
    @Return: void
    **************************************************************************************************************/
    @AuraEnabled
    public static void saveAssetJurisdiction(String assetId, String taxJurisdictionJson) {
        try {
            TC_BridgewareTaxJurisdiction jurisdiction = 
                (TC_BridgewareTaxJurisdiction) JSON.deserialize(taxJurisdictionJson, TC_BridgewareTaxJurisdiction.class);
            
            Asset__c asset = new Asset__c(Id = assetId);
            asset.Equipment_Location_City__c = jurisdiction.city;
            asset.Equipment_Location_County__c = jurisdiction.county;
            asset.Equipment_Location_State__c = jurisdiction.state;
            asset.City_Code__c = jurisdiction.cityCode;
            asset.County_Code__c = jurisdiction.countyCode;
            asset.State_Code__c = jurisdiction.stateCode;
            asset.Multiple_Counties__c = false; // Mark as resolved
            asset.Tax_Zip_Updated__c = false;
            
            update asset;
        } catch (Exception ex) {
            throw new AuraHandledException('Error saving jurisdiction: ' + ex.getMessage());
        }
    }
}