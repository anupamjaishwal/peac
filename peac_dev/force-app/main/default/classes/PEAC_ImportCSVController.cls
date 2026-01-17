/**************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This class is used to import csv file into Salesforce records
@User Story:SAL-5080
@Created Date:January-24-2025
**************************************************************************************************************/

public with sharing class PEAC_ImportCSVController {
    public static Map<String, SOAPType> columnTypeMap = new Map<String, SOAPType>();
    public static  Map<String,Map<String,String>> picklistFieldsValueMap = new Map<String,Map<String,String>>();
   
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method is converting CSV data into records
    @Parameters:CSV data, parent record id, object name, parent field name
    @Return: String
    **************************************************************************************************************/
    @AuraEnabled
    public static String saveFile(String base64Data, String recId, String objectName, String parentFieldName)
        
    {
        String uploadMessage = '';
        String recordId = recId;
        String trueVal = 'True';
        try{
            List<Opportunity> oppList = [SELECT Id, Account_Business_Street__c,Account_Business_Street2__c,
                                        Account_Business_City__c,Account_Business_State_Province__c,Account_Business_Zip_Postal_Code__c 
                                         FROM Opportunity WHERE Id =: recId LIMIT 1];
            
            String data    = JSON.deserializeUntyped(base64Data).toString();
            List<SObject> objectList = new List<Sobject> ();
            List<String> lstCSVLines = data.split('\n');
            List<String> fieldAPIList =  New List<String>();
            for(String fields : lstCSVLines[0].split(','))
            {
                fieldAPIList.Add(fields.trim());
            }
            getFieldTypeMap(objectName,fieldAPIList);
            getPicklistApi(objectName,fieldAPIList);//Get picklist label and value mapping
            for(Integer i = 1; i < lstCSVLines.size(); i++)
            {
                SObject obj = Schema.getGlobalDescribe().get(objectName).newSObject();
                String csvLine = lstCSVLines[i];
                List<String> csvRowData = new List<String>();
                for(String column : csvLine.split(','))
                {
                    column = column.replaceAll(':quotes:', '').replaceAll(':comma:', ',');
                    csvRowData.add(column);
                    
                }
                for(Integer j = 0; j < fieldAPIList.size(); j++)
                {
                    if(String.isNotBlank(csvRowData[j]))
                    obj.put(fieldAPIList[j],getFieldvalueAsObject(fieldAPIList[j], csvRowData[j],objectName));
                }
                if( String.isNotBlank(parentFieldName))
                {
                    obj.put(parentFieldName, recordId);
                }
                if(trueVal.EqualsIgnoreCase(String.Valueof(obj.get('End_User_Billing_Address__c')) ))
                {
                    obj.put('Equipment_Street__c', oppList[0].Account_Business_Street__c);
                    obj.put('Equipment_Address_2__c', oppList[0].Account_Business_Street2__c);
                    obj.put('Equipment_City__c', oppList[0].Account_Business_City__c);
                    obj.put('Equipment_State__c', oppList[0].Account_Business_State_Province__c);
                    obj.put('Equipment_Zip__c', oppList[0].Account_Business_Zip_Postal_Code__c);
                }
                
                

                objectList.add(obj);
                
                }
                if(!objectList.isEmpty())
                    
                {
                    
                    String jobId = Database.executeBatch(new PEAC_CreateAssetsBatch(objectList), Integer.Valueof(Label.PEAC_CreateAssetsBatch_Limit));
                    uploadMessage = 'Success';    
                }
            }   
            catch(Exception ex)
            {
                throw new AuraHandledException(Label.PEAC_Asset_Upload_Message+ ex.getmessage());
            } 
        
       return uploadMessage;
        
    }
    
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method will return the field value for string and picklist
    @Parameter:Object Name, Field API, Field Value
    @Return: Field value
    **************************************************************************************************************/
    public static void getPicklistApi(String strObjectName,List<String> fieldAPIList)
    {
        //Map<String,Map<String,String>> picklistFieldsValueMap = new Map<String,Map<String,String>>();
        picklistFieldsValueMap = new Map<String,Map<String,String>>();
       
        // Get the object type of the SObject.
        // Describe the object and field
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(strObjectName);
        Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
		for(String fieldName: fieldAPIList)
        {
         	Schema.DescribeFieldResult fieldDescribe = objectDescribe.fields.getMap().get(fieldName).getDescribe();
        	
            // Check if the field is a picklist
            if (fieldDescribe.getType() == Schema.DisplayType.Picklist) {
                
                // Retrieve picklist values and labels
                List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
                picklistFieldsValueMap.put(fieldName, new Map<String,String>());
                // Iterate through picklist values and labels
                for (Schema.PicklistEntry picklistEntry : picklistValues) {
                    picklistFieldsValueMap.get(fieldName).put(picklistEntry.getLabel(),picklistEntry.getValue());
                }   
        	}
        }
        
        
    }
    
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method is mapping field api from the object and CSV 
    @Parameter:Object Name, List of columns name
    @Return: None
    **************************************************************************************************************/
    
    public static void getFieldTypeMap(String strObjectName,List<String> fieldAPIList){
        Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
        Schema.SObjectType sobjType = gd.get(strObjectName); 
        Schema.DescribeSObjectResult describeResult = sobjType.getDescribe(); 
        Map<String,Schema.SObjectField> fieldsMap = describeResult.fields.getMap(); 
        columnTypeMap = new Map<String, SOAPType>();
        for (String column : fieldAPIList) {
            columnTypeMap.put(column, fieldsMap.get(column.toLowerCase()).getDescribe().getSOAPType());
        }
    }
     /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: Compare field type and convert the value according to field type 
    @Parameter:Field Name, Field Value, Object Name
    @Return: Object
    **************************************************************************************************************/
    
    public static Object getFieldvalueAsObject(String fieldname, String stringValue, String objectName) {
        if (columnTypeMap.get(fieldname) == SOAPType.String) {
            String strValue = stringValue;
            if(String.isNotBlank(strValue) && picklistFieldsValueMap!=Null && picklistFieldsValueMap.get(fieldname)!=Null)
            {
                strValue = picklistFieldsValueMap.get(fieldname).get(stringValue);
            }
            return strValue;
        }
        else if (columnTypeMap.get(fieldname) == SOAPType.Date) {
            return Date.valueOf(stringValue);
        }
        else if (columnTypeMap.get(fieldname) == SOAPType.Double) {
            return Double.valueOf(stringValue);
        }
        else if (columnTypeMap.get(fieldname) == SOAPType.Integer) {
            return Integer.valueOf(stringValue);
        }
        else if (columnTypeMap.get(fieldname) == SOAPType.ID) {
            return String.valueOf(stringValue);
        }
        else if (columnTypeMap.get(fieldname) == SOAPType.Boolean) {
            return Boolean.valueOf(stringValue);
        }
        else {
            // other data type
            return String.valueOf(stringValue);
        }
    }
    
    
}