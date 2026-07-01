/************************************************************************************************************************
 @Description: This is a generic calss to generate csv file from salesforce objects
 @Author: Rajesh Kumar(LTIMindtree)
 @User Story: SAL-6229
 @Created Date: 02/23/2026
 ************************************************************************************************************************/

public with sharing class PEAC_CSVFileDownloadController {
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: Get record from sobject
    @User Story:SAL-6229	
    @Param:Object Name, List of fields,parent object name and record id 
    @Created Date:02/23/2026   
    **************************************************************************************************************/
   @AuraEnabled(cacheable=true)
    public static List<SObject> getRecords(String objectName, List<String> fields, String parentFieldName, String recordId) {
        String query = 'SELECT ' + String.join(fields, ',') + ' FROM ' + objectName + ' WHERE ' + parentFieldName + ' = \'' + String.escapeSingleQuotes(recordId) + '\' LIMIT 49999';
        return Database.query(query);

        
    }
}