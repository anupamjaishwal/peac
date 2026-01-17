/************************************************************************************************************
*@Author: Rodrigo Castro
@Description:This class is used to call GDS stored procedure
@Created Date:06/05/2025
@User Story:SAL-5479
 ************************************************************************************************************/
public with sharing class SL_CaseCenterStoredProcedure {

    public class MappingException extends Exception {}

    public static List<Integration_Log__c> logs = new List<Integration_Log__c>();

    public static void SL_CaseCenterStoredProcedure(List<String> storedProcedures, Id recordId) {
        List<Webservice_Field__c> recordsToInsert = new List<Webservice_Field__c>();
        string storeproc = '';
        try{
            if(storedProcedures.size()>0){
                for(String sp : storedProcedures){
                    storeproc = sp;
                    Webservice_Field__c wsf = new Webservice_Field__c();
                    wsf = executeStoredProcedureCall(recordId, sp);
                    /*if(wsf != null){
                    recordsToInsert.add(wsf);
                    }*/
                    recordsToInsert.add(wsf);
                }

                if(recordsToInsert.size()>0){
                    insert recordsToInsert;
                }
            }
        }
        catch(Exception ex)
        {
            logs.add(new Integration_Log__c(
                Name = 'executeStoredProcedureCall - '+ storeproc,
                Error_Message__c = ex.GetMessage(),
                Status__c = 'Error',Opportunity__c	= recordId ,Record_Id__c = recordId));
        }
        finally{
            insert logs; 
        }

    }

    private static Webservice_Field__c executeStoredProcedureCall(Id recordId, String storedProcedure){

        Webservice_Field__c wsfRecord = new Webservice_Field__c();
        String result = '';
        Integration_Log__c integLog = new Integration_Log__c(
            Name = 'executeStoredProcedureCall - '+ storedProcedure,
            Record_Id__c = recordId, Opportunity__c	= recordId);    
        //Get the credentials from TC_DwhStoredProcedureCredential custom metadata type 
        TC_DwhStoredProcedureCredential__mdt credentials = [SELECT Endpoint__c, Request__c, Response__c, Username__c, Password__c, x_api_key__c  FROM TC_DwhStoredProcedureCredential__mdt WHERE DeveloperName=:storedProcedure ];

        // Create Basic Auth header
        String rawCreds = credentials.Username__c + ':' + credentials.Password__c;
        String encodedCreds = EncodingUtil.base64Encode(Blob.valueOf(rawCreds));
        String authHeader = 'Basic ' + encodedCreds;

        // JSON body
        String requestString = buildRequest(recordId, credentials.Request__c);

       // Set up HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(credentials.Endpoint__c); // replace with actual endpoint
        req.setMethod('POST');
        req.setHeader('Authorization', authHeader);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('x-api-key', credentials.x_api_key__c); // Add the API key header
        req.setBody(requestString);

        Http http = new Http();
        integLog.Name = 'executeStoredProcedureCall - '+ storedProcedure;
        integLog.Record_Id__c = recordId;
        
        integLog.Request_Message__c = requestString;
        
        HttpResponse res = http.send(req);
		integLog.Status__c = (res?.getStatusCode() == 200 ? 'Success' : 'Error');
        integLog.Error_Code__c = (res?.getStatusCode()!=null ? string.valueOf(res.getStatusCode()) : '401');
        integLog.Error_Message__c = res?.getStatus() !=null? res.getStatus():'Error';
        integLog.Response_Message__c= trimMessage(string.valueOf(res),131071) ;
        logs.add(integLog);
        result = res.getBody();
		
        SObject WSFobject = convertResponse(result, credentials.Response__c, recordId);
        WSFobject.put('Stored_Procedure__c', storedProcedure);
        wsfRecord = (Webservice_Field__c)WSFobject;
        
        
        return wsfRecord;
    }

    public static String trimMessage (String message, Integer fieldLimit) {
         return message != null && message.length() >= fieldLimit ? message.left(fieldLimit) : message;
    }

public static String buildRequest(Id opportunityId, String fieldMappingStr) {
    if (opportunityId == null || String.isBlank(fieldMappingStr)) {
        throw new MappingException('Opportunity ID or field mapping is missing');
    }

    // Store field mappings
    Map<String, String> jsonToFieldMap = new Map<String, String>();
    Set<String> fieldSet = new Set<String>(); // Opportunity fields and parent fields
    Set<String> guarantorsSubQueryFieldSet = new Set<String>(); // Fields in Guarantor__r

    List<String> mappingLines = fieldMappingStr.split('\n');
    for (String line : mappingLines) {
        line = line.trim();
        if (String.isBlank(line)) continue;

        List<String> parts = line.split('-');
        if (parts.size() != 2) {
            throw new MappingException('Invalid mapping line (expected "JSONTag - OpportunityField"): ' + line);
        }

        String jsonTag = parts[0].trim();
        String sfField = parts[1].trim();

        if (sfField.startsWith('Guarantor__r[')) {
            // Extract field name for subquery
            Integer idxStart = sfField.indexOf('[');
            Integer idxEnd = sfField.indexOf(']');
            if (idxStart < 0 || idxEnd < 0 || idxEnd <= idxStart) {
                throw new MappingException('Invalid Guarantor__r index format in: ' + sfField);
            }

            String childField = sfField.substringAfter('].'); // e.g., SSN__c
            guarantorsSubQueryFieldSet.add(childField);
        } else {
            fieldSet.add(sfField); // e.g., Account.Tax_ID__c or simple fields
        }

        jsonToFieldMap.put(jsonTag, sfField);
    }

    // Add Guarantor__r subquery if needed
    if (guarantorsSubQueryFieldSet.size() > 0) {
        String guarantorsQueryFieldList = String.join(new List<String>(guarantorsSubQueryFieldSet), ',');
        String guarantorsQuery = '(SELECT ' + guarantorsQueryFieldList + ' FROM Guarantor__r ORDER BY Priority__c ASC)';
        fieldSet.add(guarantorsQuery);
    }

    // Build and execute SOQL query
    String fieldList = String.join(new List<String>(fieldSet), ',');
    String query = 'SELECT ' + fieldList + ' FROM Opportunity WHERE Id = :opportunityId';
    System.debug(logginglevel.Error,'QUERY '+ query);
    Opportunity opp;
    opp = (Opportunity) Database.query(query);
    

    // Build JSON map
    Map<String, Object> jsonMap = new Map<String, Object>();
    for (String jsonTag : jsonToFieldMap.keySet()) {
        String sfField = jsonToFieldMap.get(jsonTag);

       
            if (sfField.startsWith('Guarantor__r[')) {
                // Parse index and field for child records
                Integer idxStart = sfField.indexOf('[');
                Integer idxEnd = sfField.indexOf(']');
                Integer index = Integer.valueOf(sfField.substring(idxStart + 1, idxEnd));
                String childField = sfField.substringAfter('].');

                List<SObject> guarantors = (List<SObject>) opp.getSObjects('Guarantor__r');
                if (guarantors != null && guarantors.size() > index) {
                    SObject targetGuarantor = guarantors[index];
                    Object val = targetGuarantor.get(childField);
                    jsonMap.put(jsonTag, val);
                } else {
                    jsonMap.put(jsonTag, null); // Not enough guarantors
                }
            } else if (sfField.contains('.')) {
                // Handle parent relationship field e.g. Account.CCAN__c
                List<String> parts = sfField.split('\\.');
                if (parts.size() == 2) {
                    String parentRel = parts[0];
                    String childField = parts[1];
                    SObject parentObj = opp.getSObject(parentRel);
                    if (parentObj != null) {
                        Object val = parentObj.get(childField);
                        jsonMap.put(jsonTag, val);
                    } else {
                        jsonMap.put(jsonTag, null);
                    }
                } else {
                    // Unexpected multi-level relationship - treat as null or add your logic
                    jsonMap.put(jsonTag, null);
                }
            } else {
                // Simple field
                Object val = opp.get(sfField);
                jsonMap.put(jsonTag, val);
            }
       
    }

    return JSON.serialize(jsonMap);
}



    //This method is to read the JSON response and convert it to a Webservice_Field__c record.
    public static SObject convertResponse(String jsonResponse, String fieldMappingStr, ID recordId) {

        String sObjectName = 'Webservice_Field__c';
        Schema.SObjectType t  = Schema.getGlobalDescribe().get(sObjectName);
        SObject record = t.newSObject();
        record.put('Opportunity__c', recordId);

        if (String.isBlank(jsonResponse)) {
            throw new MappingException('Invalid input to mapJsonToSObject');

        }

               // Step 1: Parse the JSON root
        Map<String, Object> rootMap;
        
        rootMap = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
        

        // Step 2: Extract "results" list
        if (!rootMap.containsKey('results')) {
            throw new MappingException('JSON response does not contain "results" node.');
        }

        Object resultsNode = rootMap.get('results');
        if (!(resultsNode instanceof List<Object>)) {
            throw new MappingException('"results" node is not a JSON array.');
        }

        List<Object> resultsList = (List<Object>) resultsNode;
        if (resultsList.isEmpty()) {
            throw new MappingException('"results" array is empty.');
        }

        Object firstItem = resultsList[0];
        if (!(firstItem instanceof Map<String, Object>)) {
            throw new MappingException('First item in "results" is not an object.');
        }



        Map<String, Object> rawResponseMap = (Map<String, Object>) firstItem;
        // Step 3: Parse the mapping string
        List<String> mappingLines = fieldMappingStr.split('\n');

        // Normalize JSON keys (trim whitespace)
        Map<String, Object> responseMap = new Map<String, Object>();
        for (String key : rawResponseMap.keySet()) {
            responseMap.put(key.trim(), rawResponseMap.get(key));
        }

        for (String line : mappingLines) {
            line = line.trim();
            if (String.isBlank(line)) continue;

            List<String> parts = line.split('-');
            if (parts.size() != 2) {
                System.debug(logginglevel.Error,'Invalid mapping line (expected "JSONTag - SObjectField"): ' + line);
                continue;
            }

            String jsonTag = parts[0].trim();
            String sfField = parts[1].trim();
            if (responseMap.containsKey(jsonTag)) {
                Object jsonValue = responseMap.get(jsonTag);
                
                    // Optional: Add conversion logic here if needed
                    if(String.valueOf(jsonValue) == 'null'){
                        record.put(sfField, null);
                    }
                    else{
                        record.put(sfField, String.valueOf(jsonValue));
                    }
                
            } else {
                System.debug(logginglevel.Error,'JSON response does not contain tag: ' + jsonTag);
            }
        }

        return record;
    }



}