/******************************************************************************************************************************
@Author:Vinod Rathod(LTIMindtree)
@Description: PEAC_GdsScoreCardViewController Apex for dynamically fetching specified fields from Opportunity, its 
related child objects, and parent objects (Via dot notaion) based on custom metadata cofigurations(Scorecard_Field_Mapping__mdt).
@User Story:SAL-5547
@Created Date:July-02-2025 	    
*******************************************************************************************************************************/
public with sharing class PEAC_GdsScoreCardViewController {
    @AuraEnabled(cacheable=true)
    Public static Map<String, Map<String,object>> fetchScorecrdData(Id opportunityId){
        Map<String, map<String,object>> result = New Map<String, map<String,object>>();
        
        // Step 1: Get custom metadata configuration
        List<Scorecard_Field_Mapping__mdt> configs = [SELECT Field_API_Names__c,Object_Name__c,Order__c FROM Scorecard_Field_Mapping__mdt order by Order__c Asc]; 
        System.debug(' Metadata configs  ==>' + configs);
        
        // Step 2: Process each metadata config
        If(!configs.isEmpty()){
            For(Scorecard_Field_Mapping__mdt config: configs){
                String objectName = config.Object_Name__c;
                List<String> fieldList = config.Field_API_Names__c.split('\\,');
                String fields = String.join(fieldList, ',');
                System.debug('fields======>' + fields  );
                
                // Step 3: Dynamically query records
                If(objectName == 'Opportunity' ){
                    String query = 'SELECT '+ fields + ' FROM ' + objectName +' WHERE Id =: opportunityId';
                    System.debug('query======>' + query  );
                    List<Sobject> oppRecords = Database.query(query);
                    System.debug('oppRecords======>' + oppRecords  );
                    if (!oppRecords.isEmpty()) {
                        Map<String, Object> fieldMap = getFieldsAsMap(objectName,oppRecords[0],fieldList);
                        result.put(objectName,fieldMap);
                    }
                    
                }else{
                    // Child objects assumed to have Opportunity__c lookup
                    String query = 'SELECT '+ fields + ' FROM ' + objectName +' WHERE Opportunity__c =: opportunityId order by CreatedDate Desc LIMIT 1';
                    List<Sobject> childRecords = Database.query(query);
                    Map<String, Object> fieldValue;
                    if (!childRecords.isEmpty()) {
                        fieldValue = getFieldsAsMap(objectName,childRecords[0],fieldList);
                        result.put(objectName,fieldValue);
                    }else {
                        fieldValue = getEmptyFieldsMap(objectName,fieldList);
                        result.put(objectName,fieldValue);
                    }
                }                 
            }
            
        }
        
        System.debug('result======>' + result  );
        return result;  
    }
    
    
    /*****************************************************************************************************************************
@Author:Vinod Rathod(LTIMindtree)
@Description: Helper method to retrieve field values and corresponding labels, including parent fields for a given record.
@User Story: SAL-5547
@Created Date: July-02-2025     
@Param :- 
objectName - The API Name of the object for the current record (e.g. 'Opportunity').
record     - The queried Sobject record whose fields need to be extracted.
fieldNames - The set of field API names (including parent dot notation fields) to retrieve.
******************************************************************************************************************************/
    private static Map<String, Object> getFieldsAsMap(String objectName, Sobject record, List<String> fieldNames){
        Map<String, Object>  fieldMap = New  Map<String, Object>();
        
        Map<String, Schema.SObjectField> fieldDescribeMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        
        for(String fieldName : fieldNames){
            if (fieldName.contains('.')) {
                // Handle parent field e.g. Account.Sic
                List<String> parts = fieldName.split('\\.');
                if (parts.size() != 2) {
                    System.debug('Invalid mapping line' + fieldName);
                    continue;
                }
                System.debug('List parts======>' + parts  );
                String parentObjName = parts[0].trim();
                String parentFieldName = parts[1].trim();
                SObject parentRecord = record.getSObject(parentObjName);
                System.debug('parentRecord======>' + parentRecord  );
                if (parentRecord != null && globalDescribe.containsKey(parentObjName)) {
                    Map<String, Schema.SObjectField> parentDescribeMap = globalDescribe.get(parentObjName).getDescribe().fields.getMap();
                    if (parentDescribeMap.containsKey(parentFieldName)) {
                        String label = parentDescribeMap.get(parentFieldName).getDescribe().getLabel();
                        Object value = parentRecord.get(parentFieldName);
                        if(value == 'NULL' || value== NULL || value== 'null' ){
                            fieldMap.Put(label,'' );   
                        }else 
                            fieldMap.put(label, value);
                        System.debug('parentRecord fieldMap======>' + fieldMap  );  
                    }
                }   
            }else 
                // Handle direct field
                If(fieldDescribeMap.containsKey(fieldName)){
                    String label = fieldDescribeMap.get(fieldName).getDescribe().getlabel();
                    Object value = record.get(fieldName);
                    if(value == 'NULL' || value== NULL || value== 'null' ){
                        fieldMap.Put(label,'' );   
                    }else 
                        fieldMap.Put(label,value ); 
                }
        }
        System.debug('fieldMap======>' + fieldMap  );
        return fieldMap;  
    }    
    /*****************************************************************************************************************************
@Author : Vinod Rathod(LTIMindtree)
@Description : This Method used when child record doesn't exist, so that the UI can still display all configurd fields with blank 
values.
@User Story : SAL-5547
@Created Date : July-02-2025     
@Param :- 
objectName - The API Name of the object for the current record (e.g. 'Opportunity') 
fieldNames - The set of field API names.
******************************************************************************************************************************/
    private static Map<String, Object> getEmptyFieldsMap(String objectName, List<String> fieldNames){
        Map<String, Object>  fieldMap = New  Map<String, Object>();  
        Map<String, Schema.SObjectField> fieldDescribeMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
        
        for(String fieldName : fieldNames){
            String label = fieldDescribeMap.get(fieldName).getDescribe().getlabel();
            fieldMap.Put(label,'' ); 
        }
        return fieldMap;
        
    } 
}