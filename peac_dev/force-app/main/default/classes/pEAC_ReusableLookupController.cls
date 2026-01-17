/********************************************************************************************************************
@Author: Rajesh Kumar(LTIMindtree)
@Description: This test class ensure that pEAC_ReusableLookupController correctly retrieves records based on dynamic
filters and search criteria.
@User Story:SAL-5019
@Created Date: September-27-2024
*********************************************************************************************************************/
public with sharing class pEAC_ReusableLookupController {
    /********************************************************************************************************************
@Author: Rajesh Kumar(LTIMindtree)
@Description: This method fetches records from a specified object based on the provided search and filter criteria.
@Param: InputWrapper The wrapper object containing search and filter criteria for querying the records.
@return: A list of ResultWrapper objects containing the results of the query.
*********************************************************************************************************************/
    @AuraEnabled
    public static List<ResultWrapper> fetchRecords(SearchWrapper inputWrapper) {
        try {
            // Check if the inputWrapper is not null
            if(inputWrapper != null){
                // Build the SOQL query by selecting Id and the fields specified in inputWrapper
                String fieldsToQuery = 'SELECT Id, ';
                // Add the first field to query if specified
                if(string.isNotBlank(inputWrapper.fieldApiName)){
                    fieldsToQuery = fieldsToQuery + inputWrapper.fieldApiName;
                }
                // Add the second field to query if specified
                if(string.isNotBlank(inputWrapper.otherFieldApiName)){
                    fieldsToQuery = fieldsToQuery + ', ' + inputWrapper.otherFieldApiName;
                }
                // Start constructing the query string
                String query = fieldsToQuery + ' FROM '+ inputWrapper.objectApiName;
                // Define the LIKE clause based on the search string, escaping any single quotes
                String likeCriteria = inputWrapper.fieldApiName + ' LIKE ' + '\'' + String.escapeSingleQuotes(inputWrapper.searchString.trim()) + '%\' LIMIT 10';
                // If a specific record ID is provided, query based on that ID
                if(String.isNotBlank(inputWrapper.selectedRecordId)) {
                    query += ' WHERE Id = \''+ inputWrapper.selectedRecordId + '\'';
                }
                // Otherwise, build the WHERE clause based on filter criteria if they exist
                else if (inputWrapper.filterCriteriaList.size() > 0){
                    string filterString = ' WHERE ';
                    Integer count = 1;
                    // Loop through the filter criteria list and build the filter condition string
                    for(FilterWrapper filter : inputWrapper.filterCriteriaList) {
                        // Handle string type filters by wrapping values in quotes
                        if(filter.dataType == 'string') {
                            filterString += filter.fieldAPIName + ' ' + filter.operator + ' \'' + filter.value  + '\' ';
                        } else {
                            filterString += filter.fieldAPIName + ' ' + filter.operator + ' ' + filter.value ;
                        }
                        // Append 'AND' between multiple filter conditions
                        if(count <= inputWrapper.filterCriteriaList.size()) {
                            filterString += ' AND ';
                        }
                        count++;
                    }
                    // Append the LIKE clause to the filter string
                    query += filterString + likeCriteria;
                }  
                // If no filter criteria, just append the LIKE clause
                else {
                    query += ' WHERE '+ likeCriteria;
                }
                // Execute the SOQL query and fetch the results
                List<ResultWrapper> returnWrapperList = new List<ResultWrapper>();
                System.debug('QUERY '+ query);
                for(SObject sRecord : Database.query(query)) {
                    // Wrap each result in a ResultWrapper and add it to the list
                    ResultWrapper wrap = new ResultWrapper();
                    wrap.mainField = (String)sRecord.get(inputWrapper.fieldApiName);
                    wrap.subField = (String)sRecord.get(inputWrapper.otherFieldApiName);
                    wrap.id = (String)sRecord.get(PEAC_ConstantClass.ID);
                    returnWrapperList.add(wrap);
                }
                // Return the list of wrapped results
                return returnWrapperList;
            }
            // Return null if inputWrapper is null
            return null;
        }
        // Catch any exceptions and throw a custom AuraHandledException
        catch (Exception err) {
            throw new AuraHandledException(err.getMessage());
        }
    }
    /****************************************************************************
@Author: Rajesh Kumar(LTIMindtree)
@Description: Wrapper class for holding the result data from the query.
*****************************************************************************/
    public class ResultWrapper{
        @AuraEnabled public String mainField{get;set;}   // Main field value (e.g., Name)
        @AuraEnabled public String subField{get;set;}    // Secondary field value (e.g., Type)
        @AuraEnabled public String id{get;set;}          // Record Id
    }
    
    /****************************************************************************
@Author: Rajesh Kumar(LTIMindtree)
@Description: Wrapper class for input data passed to the fetchRecords method,
including search and filter criteria.
*****************************************************************************/
    
    public class SearchWrapper {
        @AuraEnabled public String objectApiName{get;set;}           // API name of the object to query (e.g., Account)
        @AuraEnabled public String fieldApiName{get;set;}            // Main field to query (e.g., Name)
        @AuraEnabled public String otherFieldApiName{get;set;}       // Additional field to query (e.g., Type)
        @AuraEnabled public String searchString{get;set;}            // The search string used for LIKE filtering
        @AuraEnabled public String selectedRecordId{get;set;}        // Record Id for querying a specific record
        @AuraEnabled public List<FilterWrapper> filterCriteriaList{get;set;}  // List of filter criteria
    }
    
    /****************************************************************************
@Author: Rajesh Kumar(LTIMindtree)
@Description: Wrapper class for filter criteria used in the dynamic query.
*****************************************************************************/
    public class FilterWrapper {
        @AuraEnabled public String fieldAPIName{get;set;}   // API name of the field to filter (e.g., Name)
        @AuraEnabled public String operator{get;set;}       // Operator for the filter (e.g., =, !=)
        @AuraEnabled public String value{get;set;}          // Value for the filter condition
        @AuraEnabled public String datatype{get;set;}       // Data type of the field (e.g., string, number)
    }
}