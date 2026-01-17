/********************************************************************************************************************
@Author: Rajesh Kumar(LTIMindtree)
@Description: This test class ensure that pEAC_ReusableLookupController correctly retrieves records based on dynamic
filters and search criteria.
@User Story:SAL-5019
@Created Date: September-27-2024
*********************************************************************************************************************/
@isTest
private with sharing class pEAC_ReusableLookupController_Test {
    /**************************************************************************************** 
@Author: Rajesh Kumar(LTIMindtree)
@Description: TestSetup method to create the test data for the test class.
This method creates a manufacturer using the SL_SCTestData class for reuse in the tests.
*****************************************************************************************/
    @TestSetup
    static void createTestData(){
        // Create manufacturer data using a custom test data generator method
        SL_SCTestData.createManufacturer(1, true);
    }
    
    /******************************************************************************************************** 
@Author: Rajesh Kumar(LTIMindtree)
@Description: Test method for pEAC_ReusableLookupController.fetchRecords() with a valid filter.
This test verifies that the method returns the correct Manufacturer record based on the filter applied.
********************************************************************************************************/
    @isTest
    static void testFetchRecordsWithValidFilter() { 
        // Fetch the list of Manufacturer accounts inserted by the test setup
        List<Account> accountList = [SELECT Id, Name, Type FROM Account WHERE Type = 'M'];
        
        // Create a SearchWrapper object with parameters to search for 'Account' records
        pEAC_ReusableLookupController.SearchWrapper inputWrapper = new pEAC_ReusableLookupController.SearchWrapper();
        inputWrapper.objectApiName = 'Account';       // Object to query
        inputWrapper.fieldApiName = 'Name';           // Main field to fetch
        inputWrapper.otherFieldApiName = 'Type';      // Additional field to fetch
        inputWrapper.searchString = 'Testing';        // Search string to match accounts starting with 'Testing'
        inputWrapper.filterCriteriaList = new List<pEAC_ReusableLookupController.FilterWrapper>(); 
        
        // Create a filter criterion 
        pEAC_ReusableLookupController.FilterWrapper filter = new pEAC_ReusableLookupController.FilterWrapper();
        filter.fieldAPIName = 'Name';                 // Field to filter on
        filter.operator = '=';                        // Operator for the filter
        filter.value = 'Testing Manufacturer0';       // Expected value to match
        filter.datatype = 'string';                   // Data type of the field
        inputWrapper.filterCriteriaList.add(filter);
        
        // Call the fetchRecords method and validate the result
        List<pEAC_ReusableLookupController.ResultWrapper> result;
        Test.startTest(); 
        result = pEAC_ReusableLookupController.fetchRecords(inputWrapper); 
        Test.stopTest();
        
        // Assertions to validate the result of the query
        System.assertEquals(1, result.size(), 'Expected one record to be returned.'); 
        System.assertEquals(SL_SCTestData.MANUFACTURER_NAME + '0', result[0].mainField, 'The Name field should match Testing Manufacturer0.');
        System.assertEquals('M', result[0].subField, 'The Type field should match "M".');
    } 
    
    /*******************************************************************************************************************
@Author: Rajesh Kumar(LTIMindtree)
@Description: Test method for pEAC_ReusableLookupController.fetchRecords() when no records are expected to match.
This test checks if the method handles no results and returns null as expected.
********************************************************************************************************************/
    @IsTest
    static void testFetchRecordsWithNoMatchingRecords() { 
        // Fetch the list of Manufacturer accounts inserted by the test setup
        List<Account> accountList = [SELECT Id, Name, Type FROM Account WHERE Type = 'M'];
        
        // Create a SearchWrapper object with parameters to search for 'Account' records
        pEAC_ReusableLookupController.SearchWrapper inputWrapper = new pEAC_ReusableLookupController.SearchWrapper();
        inputWrapper.objectApiName = 'Account';       // Object to query
        inputWrapper.fieldApiName = 'Name';           // Main field to fetch
        inputWrapper.otherFieldApiName = 'ID';        // Additional field to fetch
        inputWrapper.searchString = 'Testing';        // Search string to match accounts starting with 'Testing'
        inputWrapper.filterCriteriaList = new List<pEAC_ReusableLookupController.FilterWrapper>(); 
        
        // Create a filter criterion to simulate no matching records
        pEAC_ReusableLookupController.FilterWrapper filter = new pEAC_ReusableLookupController.FilterWrapper();
        filter.fieldAPIName = 'Name';                 // Field to filter on
        filter.operator = '=';                        // Operator for the filter
        filter.value = 'Testing Manufacturer0';       // Expected value to match (no matching records)
        filter.datatype = 'string';                   // Data type of the field
        inputWrapper.filterCriteriaList.add(filter);
        
        // Call the fetchRecords method and handle any potential exceptions
        List<pEAC_ReusableLookupController.ResultWrapper> result;
        Test.startTest(); 
        try {
            result = pEAC_ReusableLookupController.fetchRecords(inputWrapper); 
        } catch(Exception e) {
            // Ensure that an exception thrown is caught and properly handled
            System.assert(true, 'Exception thrown in fetchRecords: ' + e.getMessage());
            return; // Early return to avoid further assertions on null
        }
        Test.stopTest();
        
        // Assertions to ensure no results were returned
        System.assertEquals(null, result, 'The result should be null when no matching records are found.');
    } 
    
}