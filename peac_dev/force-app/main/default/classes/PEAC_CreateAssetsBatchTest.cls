/**************************************************************************************************************
@Author: Chalapati Murru (LTIMindtree)
@Description: This test class is used to cover PEAC_ImportCSVController, PEAC_CreateAssetsBatch and PEAC_BridgewareSelectZipGeoCodes
@User Story: SAL-5692 Expo: Opportunity Refactor
@Created Date: 01-Sep-2025
**************************************************************************************************************/

@isTest
private class PEAC_CreateAssetsBatchTest {

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
        PEAC_TestDataFactory.createBridgeWareSetting();
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
        Test.setMock(HttpCalloutMock.class, new TC_BridgewareSelectZipGeoCalloutMockImpl());
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
    static testmethod void saveFile1Test(){
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
        Test.setMock(HttpCalloutMock.class, new TC_BridgewareSelectZipGeoCalloutMockImpl());
        
        List<Asset__c> assetList = new List<Asset__c>();
        Asset__c asset = new Asset__c(Asset_Description__c='Test',Opportunity__c=oppList[0].Id,Quantity__c=1,Equipment_Code__c='Automotive (General)',Equipment_Sub_Category__c='Automotive (General)',Equipment_Zip__c='66067');
        assetList.add(asset);
        insert assetList;
         
        PEAC_CreateAssetsBatch taxMatBatch = new PEAC_CreateAssetsBatch(assetList);
        Database.executeBatch(taxMatBatch, Integer.Valueof(Label.PEAC_SelectZipGeoCodeBatch_Limit)); 
        Test.stopTest();
        
    }
}