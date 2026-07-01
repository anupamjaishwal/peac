/**************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This test class is used to import csv file into Salesforce records
@User Story:SAL-5080
@Created Date:January-24-2025
**************************************************************************************************************/

@isTest(seeAllData=false)
private class PEAC_ImportCSVControllerTest {

    //Static String str = 'Asset_Description__c,Model__c,Serial_Number__c,List_Price__c,Quantity__c,New_Used__c,Equipment_Code__c,Equipment_Sub_Category__c,Residual_Percentage__c,End_User_Billing_Address__c,Equipment_Street__c,Equipment_Address_2__c,Equipment_City__c,Equipment_State__c,Equipment_Zip__c\n'
				//+'Test Asset,New Model,2342324,2300.00,1,New,Automotive Equipment (General),Automotive (General),10,TRUE,Jacone Drive,,Indianapolis,IN,46204';
    Static String str = 'Asset_Description__c,Model__c,Serial_Number__c,List_Price__c,Quantity__c,New_Used__c,Equipment_Code__c,Equipment_Sub_Category__c,Equipment_Street__c,Equipment_Address_2__c,Equipment_City__c,Equipment_State__c,Equipment_Zip__c\n'
				+'Test Asset,New Model,2342324,2300.00,1,New,Automotive Equipment (General),Automotive (General),Jacone Drive,,Indianapolis,IN,66067';

	@testSetup
    static void prepareData(){
        SL_SCTestData.createBridgeWareSetting();
        Account acc = new Account (Name = 'testbeni', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId(), Business_Phone__c = '1234567890');
        insert acc;
        Contact c = new Contact (AccountId = acc.Id, FirstName = 'test', LastName = 'testbeni', OtherStreet = 'test', OtherCity = 'test', OtherStateCode = 'MN', OtherPostalCode = '11111', Title = 'title', SSN__c = '111111111', BirthDate = Date.today (), Email = 'test@test.com');
        insert c;
        insert new Beneficial_Owner__c (Account__c = acc.Id, Contact__c = c.Id, Ownership_Percent__c = 50);
		
        Test.startTest();
        Opportunity opp = new Opportunity (AccountId = acc.Id,StageName = 'Quote',CloseDate = date.today()+10,Name = 'test');
        insert opp;
        insert new Asset__c (End_User_Billing_Address__c = true, Quantity__c = 1, Equipment_Code__c = 'ATM', 
            Equipment_Sub_Category__c = 'ATM',Opportunity__c = opp.Id, Cost__c = 0
        );
        //Asset__c asset = new Asset__c(Asset_Description__c='Test',Opportunity__c=opp.Id,Quantity__c=1,Equipment_Code__c='Automotive (General)',Equipment_Sub_Category__c='Automotive (General)',Equipment_Zip__c='66067');
        //insert asset;
        Test.stopTest(); 
    }
    static testmethod void saveFileTest(){
        Tax_Rules_Settings__c settings = new Tax_Rules_Settings__c();
        settings.Parent_Object__c = 'Opportunity';
        settings.Rate_Object__c = 'Rate__c';
        settings.Rate_State_Field__c = 'State__c';
        settings.Rate_County_Field__c = 'County__c';
        settings.Rate_City_Field__c = 'City__c';
        settings.Rate_Code_Field__c = 'Rate_Code__c';
        settings.State_Tax_Rate_Field__c = 'State_Tax_Rate__c';
        settings.County_Tax_Rate_Field__c = 'County_Tax_Rate__c';
        settings.TCounty_Tax_Rate_Field__c = 'County_Transit_Tax_Rate__c';
        settings.City_Tax_Rate_Field__c = 'City_Tax_Rate__c';
        settings.TCity_Tax_Rate_Field__c = 'City_Transit_Tax_Rate__c';
        settings.Tax_Parent_Object_Field__c = 'Opportunity__c';
        settings.Parent_Generate_Tax_Matrix_Message_Field__c = 'Description';
        settings.Parent_Tax_Calculation_Begin_Field__c = 'Last_Tax_Calculation_Begin__c';
        settings.Parent_Tax_Calculation_Complete_Field__c = 'Last_Tax_Calculation_Complete__c';
        settings.Parent_Tax_Calculation_Successful_Field__c = 'Last_Tax_Calculation_Successful__c';
        settings.Parent_Tax_Calculation_Error_Field__c = 'Last_Tax_Calculation_Error_Details__c';
        settings.Parent_Tax_Calculation_In_Progress_Field__c = 'Is_Tax_Calculation_In_Progress__c';
        settings.Tax_Calculation_Completion_Alert_Seconds__c = 90;
        insert settings;
        List<opportunity> oppList = [SELECT ID FROM Opportunity LIMIT 1];
        
        Map<String,String> fieldsDataTypes = new Map<String,String>{'Description__c'=>'String','Quantity__c'=>'INTEGER','List_Price__c'=>'DOUBLE'};
        Map<String,Map<String,String>> picklistFieldsValueMap = new Map<String,Map<String,String>>{'Equipment_Sub_Category__c'=>new Map<String,String>{'Copiers'=>'Copiers'}};
            
        Test.startTest();
        //Test.setMock(HttpCalloutMock.class, new TC_BridgewareSelectZipGeoCalloutMockImpl());
        //TC_BridgewareService service = new TC_BridgewareServiceImpl();
        String fieldTypes = PEAC_ImportCSVController.getFieldDataTypes();
        String picklistLabels = PEAC_ImportCSVController.getPicklistLabelAPIs('Asset__c',new List<String>{'Equipment_Sub_Category__c'});
        PEAC_ImportCSVController.saveFile(JSON.serialize(str),oppList[0].Id, fieldsDataTypes,picklistFieldsValueMap);
        Test.stopTest();
                
        String toAddress = 'marlintest@peacsolutions.com'; 
        String status = 'Success';
        List<String> failedAssetList = new List<String>();
        Integer successCount = 1;
        Integer failedCount = 1;
        Asset__c asset = new Asset__c(Asset_Description__c='Test',Opportunity__c=oppList[0].Id,Quantity__c=1,Equipment_Code__c='Automotive (General)',Equipment_Sub_Category__c='Automotive (General)',Equipment_Zip__c='66067');
        //insert asset;
        List<Asset__c> assetList = [SELECT ID FROM Asset__c LIMIT 1];
        Assert.areEqual(assetList.size(), 1, 'There is no asset created on opportunity.');
        PEAC_CommonUtils comUtils = new PEAC_CommonUtils();
        PEAC_CommonUtils.byPassAssetTrigger = false;
        PEAC_SelectZipGeoCodeBatch batchJob1 = new PEAC_SelectZipGeoCodeBatch(assetList);
        PEAC_SelectZipGeoCodeBatch.sendToUserMail(toAddress,  status, failedAssetList, successCount, failedCount);
        PEAC_GenerateTaxMatrixBatch taxBatch = new PEAC_GenerateTaxMatrixBatch(new Set<Id>{oppList[0].Id}, false);
        PEAC_GenerateTaxMatrixBatch.sendToUserMail(toAddress,  status, failedAssetList, successCount, failedCount);
    }
    

    static testmethod void getDiscrepantAssetsTest(){

        SL_SCTestData.createAccountAndContracts(1, 1);
        List<Account> accounts = SL_SCTestData.testAccounts;
        System.runAs(SL_SCTestData.testUser){
            accounts[0].DBA__c = '987654321';
            accounts[0].Account_Billing_State_Province__c = 'AZ';
            accounts[0].Date_Established__c = Date.today().addYears(-1);
            //accounts[0].AnnualRevenue = 100.00;
            
            update accounts;
            //Test.startTest();
            /*SL_SCTestData.createOpportunitiesAndAssets(accounts[0].Id, 2, 1);
            
            List<Opportunity> opps = SL_SCTestData.testOpportunities;*/
            List<Opportunity> opps = PEAC_TestDataFactory.createOpportunities(accounts[0].Id, 1);
            Test.startTest();
            System.debug(LoggingLevel.INFO, 'Number of SOQL queries used: ' + Limits.getQueries());
            List<Asset__c> testAssets = PEAC_ImportCSVController.getDiscrepantAssets(opps[0].Id, 1, 1);
        	Test.stopTest();
        }
    }
    
    static testmethod void getDiscrepantAssetCountTest(){
        SL_SCTestData.createAccountAndContracts(1, 1);
        List<Account> accounts = SL_SCTestData.testAccounts;
        System.runAs(SL_SCTestData.testUser){
            accounts[0].DBA__c = '987654321';
            accounts[0].Account_Billing_State_Province__c = 'AZ';
            accounts[0].Date_Established__c = Date.today().addYears(-1);
            //accounts[0].AnnualRevenue = 100.00;
            
            update accounts;
       
            //Test.startTest();
            /*SL_SCTestData.createOpportunitiesAndAssets(accounts[0].Id, 2, 1);
            
            List<Opportunity> opps = SL_SCTestData.testOpportunities;*/
            List<Opportunity> opps = PEAC_TestDataFactory.createOpportunities(accounts[0].Id, 1);
            Test.startTest();
            System.debug(LoggingLevel.INFO, 'Number of SOQL queries used: ' + Limits.getQueries());
            Integer count = PEAC_ImportCSVController.getDiscrepantAssetCount(opps[0].Id);
            Test.stopTest();
        }
    }

    @isTest
    static void testSaveAssetJurisdictionException() {
        Test.startTest();
        
        // Test saveAssetJurisdiction exception - invalid JSON causes deserialization error
        Boolean saveExThrown = false;
        try {
            PEAC_ImportCSVController.saveAssetJurisdiction('a01000000000001AAA', 'not_valid_json');
        } catch (AuraHandledException ex) {
            saveExThrown = true;
        }
        Assert.isTrue(saveExThrown, 'AuraHandledException expected for invalid JSON in saveAssetJurisdiction');
        
        Test.stopTest();
    }
    
        @isTest
    static void testSaveAssetJurisdictionAssetNullException() {
        Test.startTest();
        
        // Test saveAssetJurisdiction exception - invalid JSON causes deserialization error
        Boolean saveExThrown = false;
        TC_BridgewareTaxJurisdiction mockJurisdiction = new TC_BridgewareTaxJurisdiction();
        mockJurisdiction.city = 'Fort Campbell North';
        mockJurisdiction.county = 'Christiannnn';
        mockJurisdiction.state = 'Kentucky';
        mockJurisdiction.cityCode = '002';
        mockJurisdiction.countyCode = '047222';
        mockJurisdiction.stateCode = null;        
        mockJurisdiction.rateCode = '001';
        mockJurisdiction.stateTaxRate = 0.01;
        mockJurisdiction.countyTransTaxRate = 0.01;
        mockJurisdiction.countyTaxRate = 0.01;
        mockJurisdiction.cityTaxRate = 0.01;
        mockJurisdiction.cityTransTaxRate = 0.01;
        try {
            PEAC_ImportCSVController.saveAssetJurisdiction('a01000000000001AAA', JSON.serialize(mockJurisdiction));
        } catch (AuraHandledException ex) {
            saveExThrown = true;
        }
        Assert.isTrue(saveExThrown, 'AuraHandledException expected for invalid JSON in saveAssetJurisdiction');
        
        Test.stopTest();
    }

    @isTest
    static void getTaxJurisdictionsForZipTest(){
        Test.setMock(HttpCalloutMock.class, new TC_BridgewareSelectZipGeoCalloutMockImpl ());
        TC_BridgewareService service = new TC_BridgewareServiceImpl();
        
        TC_BridgewareTaxJurisdiction mockJurisdiction = new TC_BridgewareTaxJurisdiction();
        mockJurisdiction.city = 'Fort Campbell North';
        mockJurisdiction.county = 'Christian';
        mockJurisdiction.state = 'Kentucky';
        mockJurisdiction.cityCode = '001';
        mockJurisdiction.countyCode = '047';
        mockJurisdiction.stateCode = 'KY';
        Test.startTest();
        try{
            PEAC_ImportCSVController.getTaxJurisdictionsForZip('047');
        }catch(Exception ex){}
        Test.stopTest();
    }

        @isTest
    static void getTaxJurisdictionsForZipExceptionTest(){
        Test.setMock(HttpCalloutMock.class, new TC_BridgewareSelectZipGeoCalloutMockImpl ());
        TC_BridgewareService service = new TC_BridgewareServiceImpl();
        
        TC_BridgewareTaxJurisdiction mockJurisdiction = new TC_BridgewareTaxJurisdiction();
        mockJurisdiction.city = 'Fort Campbell North';
        mockJurisdiction.county = 'Christian';
        mockJurisdiction.state = 'Kentucky';
        mockJurisdiction.cityCode = '001';
        mockJurisdiction.countyCode = '047';
        mockJurisdiction.stateCode = 'KY';
        Test.startTest();
        try{
            PEAC_ImportCSVController.getTaxJurisdictionsForZip('');
        }catch(Exception ex){}
        Test.stopTest();
    }
    
    @isTest
    static void saveFileTestException(){
        Test.startTest();
        try{
            PEAC_ImportCSVController.saveFile('','',new  Map<String,String>(),new Map<String,Map<String,String>>());
        }catch(Exception ex){}
        Test.stopTest();
        
    }

    @IsTest
    static void getFieldvalueAsObjectallBranchesTest() {

        // Arrange: datatype map
        Map<String, String> fieldsDataTypes = new Map<String, String>{
            'Name'          => 'STRING',
            'OwnerId'       => 'ID',
            'Stage__c'      => 'STRING',     // used for picklist mapping
            'CloseDate__c'  => 'DATE',
            'Ratio__c'      => 'DOUBLE',
            'Amount__c'     => 'CURRENCY',
            'Discount__c'   => 'PERCENT',
            'DecField__c'   => 'DECIMAL',
            'Count__c'      => 'INTEGER',
            'IsActive__c'   => 'BOOLEAN',
            'Other__c'      => 'SOMETHING_ELSE' // forces when else
        };

        // Arrange: picklist mapping for Stage__c
        Map<String, Map<String, String>> picklistFieldsValueMap = new Map<String, Map<String, String>>{
            'Stage__c' => new Map<String, String>{
                'Prospecting' => 'Prospecting (API)',
                'Closed Won'  => 'Closed Won (API)'
            }
        };

        // Act + Assert: STRING without picklist mapping
        Object nameVal = PEAC_ImportCSVController.getFieldvalueAsObject('Name', 'Acme', fieldsDataTypes, picklistFieldsValueMap);
        System.assertEquals('Acme', (String)nameVal);

        // Act + Assert: ID (no mapping)
        Object ownerVal = PEAC_ImportCSVController.getFieldvalueAsObject('OwnerId', '005000000000001AAA', fieldsDataTypes, picklistFieldsValueMap);
        System.assertEquals('005000000000001AAA', (String)ownerVal);

        // Act + Assert: STRING with picklist mapping (maps label->api value)
        Object stageVal = PEAC_ImportCSVController.getFieldvalueAsObject('Stage__c', 'Prospecting', fieldsDataTypes, picklistFieldsValueMap);
        System.assertEquals('Prospecting (API)', (String)stageVal);

        // Act + Assert: STRING with picklist map present but blank value -> should return blank (no mapping)
        Object stageBlank = PEAC_ImportCSVController.getFieldvalueAsObject('Stage__c', '', fieldsDataTypes, picklistFieldsValueMap);
        System.assertEquals('', (String)stageBlank);

        // Act + Assert: DATE
        Object dateVal = PEAC_ImportCSVController.getFieldvalueAsObject('CloseDate__c', '2026-02-18', fieldsDataTypes, picklistFieldsValueMap);
        System.assertEquals(Date.newInstance(2026, 2, 18), (Date)dateVal);

        // Act + Assert: DOUBLE
        Object doubleVal = PEAC_ImportCSVController.getFieldvalueAsObject('Ratio__c', '12.34', fieldsDataTypes, picklistFieldsValueMap);
        System.assertEquals(12.34, (Double)doubleVal);

        // Act + Assert: CURRENCY
        Object currencyVal = PEAC_ImportCSVController.getFieldvalueAsObject('Amount__c', '1234.56', fieldsDataTypes, picklistFieldsValueMap);
        System.assertEquals(Decimal.valueOf('1234.56'), (Decimal)currencyVal);

        // Act + Assert: PERCENT
        Object percentVal = PEAC_ImportCSVController.getFieldvalueAsObject('Discount__c', '10.5', fieldsDataTypes, picklistFieldsValueMap);
        System.assertEquals(Decimal.valueOf('10.5'), (Decimal)percentVal);

        // Act + Assert: DECIMAL
        Object decVal = PEAC_ImportCSVController.getFieldvalueAsObject('DecField__c', '99.99', fieldsDataTypes, picklistFieldsValueMap);
        System.assertEquals(Decimal.valueOf('99.99'), (Decimal)decVal);

        // Act + Assert: INTEGER
        Object intVal = PEAC_ImportCSVController.getFieldvalueAsObject('Count__c', '42', fieldsDataTypes, picklistFieldsValueMap);
        System.assertEquals(42, (Integer)intVal);

        // Act + Assert: BOOLEAN
        Object boolVal = PEAC_ImportCSVController.getFieldvalueAsObject('IsActive__c', 'true', fieldsDataTypes, picklistFieldsValueMap);
        System.assertEquals(true, (Boolean)boolVal);

        // Act + Assert: ELSE branch (unknown datatype)
        Object elseVal = PEAC_ImportCSVController.getFieldvalueAsObject('Other__c', 'xyz', fieldsDataTypes, picklistFieldsValueMap);
        System.assertEquals('xyz', (String)elseVal);

        // Extra: field not present in datatype map -> fieldsDataTypes.get() is null -> hits when else
        Object missingType = PEAC_ImportCSVController.getFieldvalueAsObject('Missing__c', 'abc', fieldsDataTypes, picklistFieldsValueMap);
        System.assertEquals('abc', (String)missingType);
    }
    
    
    /**************************************************************************************************************
    @Description: Test TC_BridgewareSelectZipGeoCodeCtrl.getCurrentValues with trigger bypass
    @UserStory: SAL-6285
    @Modified: Test method fix in Migration - Suraj Harichandan (LTIMindtree) - February 17, 2026
    **************************************************************************************************************/
    @isTest
    static void testGetCurrentValues() {
        List<Opportunity> oppList = [SELECT ID FROM Opportunity LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new TC_BridgewareSelectZipGeoCalloutMockImpl());
        
        Asset__c testAsset = [SELECT Id From Asset__c LIMIT 1];
        /*Asset__c testAsset = new Asset__c(
            Opportunity__c = oppList[0].Id,
            Description__c = 'Test Asset for getCurrentValues',
            Equipment_Street__c = 'Test Street',
            Equipment_City__c = 'Saint Paul',
            Equipment_State__c = 'MN',
            List_Price__c = 1000.00,
            Residual_Percentage__c = 10,
            Quantity__c = 1,
            Equipment_Zip__c = '55125',
            Multiple_Counties__c = true
        );
        insert testAsset;*/
        
        Test.startTest();
        TC_BridgewareTaxJurisdiction result = TC_BridgewareSelectZipGeoCodeCtrl.getCurrentValues(testAsset.Id);
        Test.stopTest();
    }

    /**************************************************************************************************************
    @Description: Test TC_BridgewareSelectZipGeoCodeCtrl.getOpportunityProbability with trigger bypass
    @UserStory: SAL-6285
    @Modified: Test method fix in Migration - Suraj Harichandan (LTIMindtree) - February 17, 2026
    **************************************************************************************************************/
    @isTest
    static void testGetOpportunityProbability() {
        List<Opportunity> oppList = [SELECT ID FROM Opportunity LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new TC_BridgewareSelectZipGeoCalloutMockImpl());
        
        Asset__c testAsset = [SELECT Id From Asset__c LIMIT 1];
        
        Test.startTest();
        Decimal probability = TC_BridgewareSelectZipGeoCodeCtrl.getOpportunityProbability(testAsset.Id);
        Test.stopTest();
    }

    /**************************************************************************************************************
    @Description: Test TC_BridgewareSelectZipGeoCodeCtrl.search with trigger bypass
    @UserStory: SAL-6285
    @Modified: Test method fix in Migration - Suraj Harichandan (LTIMindtree) - February 17, 2026
    **************************************************************************************************************/
    @isTest
    static void testSearchZipGeoCode() {
        List<Opportunity> oppList = [SELECT ID FROM Opportunity LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new TC_BridgewareSelectZipGeoCalloutMockImpl());
        
        Asset__c testAsset = [SELECT Id From Asset__c LIMIT 1];
        
        Test.startTest();
        List<TC_BridgewareTaxJurisdiction> results = TC_BridgewareSelectZipGeoCodeCtrl.search(testAsset.Id, '55125');
        Test.stopTest();
    }

    /**************************************************************************************************************
    @Description: Test TC_BridgewareSelectZipGeoCodeCtrl.save with trigger bypass and validation compliance
    @UserStory: SAL-6285
    @Modified: Test method fix in Migration - Suraj Harichandan (LTIMindtree) - February 17, 2026
    **************************************************************************************************************/
    @isTest
    static void testSaveZipGeoCode() {
        List<Opportunity> oppList = [SELECT ID FROM Opportunity LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new TC_BridgewareSelectZipGeoCalloutMockImpl());
        
        Asset__c testAsset = [SELECT Id From Asset__c LIMIT 1];
        
        Test.startTest();
        TC_BridgewareTaxJurisdiction jurisdiction = new TC_BridgewareTaxJurisdiction();
        jurisdiction.city = 'Woodbury';
        jurisdiction.county = 'Washington';
        jurisdiction.state = 'Minnesota';
        jurisdiction.cityCode = '1740';
        jurisdiction.countyCode = '163';
        jurisdiction.stateCode = 'MN';
        
        TC_BridgewareSelectZipGeoCodeCtrl.save(testAsset.Id, JSON.serialize(jurisdiction));
        Test.stopTest();
        
        Asset__c updatedAsset = [SELECT Multiple_Counties__c FROM Asset__c WHERE Id = :testAsset.Id];
    }

    /**************************************************************************************************************
    @Description: Test TC_BridgewareSelectZipGeoCodeCtrl exception handling via invalid Id
    @UserStory: SAL-6285
    @Modified: Test method fix in Migration - Suraj Harichandan (LTIMindtree) - February 17, 2026
    **************************************************************************************************************/
    @isTest
    static void testHandleExceptionInAuraContext() {
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            TC_BridgewareSelectZipGeoCodeCtrl.getCurrentValues('invalidId');
        } catch (Exception ex) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
        Assert.isTrue(exceptionThrown, 'Exception should be thrown for invalid Id');
    }
}