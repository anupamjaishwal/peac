/**************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This test class is used to import csv file into Salesforce records
@User Story:SAL-5080
@Created Date:January-24-2025
**************************************************************************************************************/

@isTest
private class PEAC_BridgewareSelectZipGeoCodesTest {

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
    
    @isTest
    static void saveFileTest(){
        //List<opportunity> oppsList = [SELECT ID FROM Opportunity limit 1];
        Test.setMock(HttpCalloutMock.class, new TC_BridgewareSelectZipGeoCalloutMockImpl ());
        TC_BridgewareService service = new TC_BridgewareServiceImpl ();
        
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
    
    @isTest
    static void searchMultipleAssets(){
        //List<opportunity> oppList = [SELECT ID FROM Opportunity limit 1];
        Test.setMock(HttpCalloutMock.class, new TC_BridgewareSelectZipGeoCalloutMockImpl ());
        TC_BridgewareService service = new TC_BridgewareServiceImpl ();
        
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
        TC_BridgewareTaxJurisdiction mockJurisdiction = new TC_BridgewareTaxJurisdiction();
        mockJurisdiction.city = 'Fort Campbell North';
        mockJurisdiction.county = 'Christian';
        mockJurisdiction.state = 'Kentucky';
        mockJurisdiction.cityCode = '001';
        mockJurisdiction.countyCode = '047';
        mockJurisdiction.stateCode = 'KY';
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
        List<Asset__c> assetList = [SELECT ID,Equipment_Zip__c FROM Asset__c LIMIT 1];
        Assert.areEqual(assetList.size(), 1, 'There is no asset created on opportunity.');
        PEAC_CommonUtils comUtils = new PEAC_CommonUtils();
        PEAC_CommonUtils.byPassAssetTrigger = false;
        Map<String, String> fieldsConfig = new Map<String, String>();
        for(PEAC_BulkAssetsUpload__mdt mdt : [SELECT DeveloperName,Value__c FROM PEAC_BulkAssetsUpload__mdt WHERE DeveloperName IN ('AssetFieldsRespDataMapping','RateFieldsRespDataMapping')]){
			fieldsConfig.put(mdt.DeveloperName, mdt.Value__c);
		}
        PEAC_BridgewareSelectZipGeoCodes.searchMultipleAssets(assetList);
        PEAC_BridgewareSelectZipGeoCodes.updateAssets(assetList[0], new List<TC_BridgewareTaxJurisdiction>{mockJurisdiction},fieldsConfig.get('AssetFieldsRespDataMapping'));
        //PEAC_SelectZipGeoCodeBatch.sendToUserMail(toAddress,  status, failedAssetList, successCount, failedCount);
        PEAC_GenerateTaxMatrixBatch taxBatch = new PEAC_GenerateTaxMatrixBatch(new Set<Id>{oppList[0].Id}, false);
        PEAC_GenerateTaxMatrixBatch.sendToUserMail(toAddress,  status, failedAssetList, successCount, failedCount);
    }
    
    @isTest
    static void saveRatesTest() {
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
        
        Rate__c rate = new Rate__c();
        rate.State__c = 'MN';
        rate.County__c = 'WASHINGTON';
        rate.City__c = 'WOODBURY';
        rate.State_Code__c = '24';
        rate.County_Code__c = '163';
        rate.City_Code__c = '1740';
        rate.Rate_Code__c = '001';
        rate.State_Tax_Rate__c = 0.01;
        rate.County_Tax_Rate__c = 0.01;
        rate.County_Transit_Tax_Rate__c = 0.01;
        rate.City_Tax_Rate__c = 0.01;
        rate.City_Transit_Tax_Rate__c = 0.01;
        insert rate;
        
        TCRE__Rule_Config__c conf = new TCRE__Rule_Config__c();
        conf.TCRE__SObject_Name__c = 'Opportunity';
        conf.TCRE__Priority__c = 1;
        insert conf;
        
        TCRE__Rule_Condition__c cond1 = new TCRE__Rule_Condition__c();
        cond1.TCRE__Field_Name__c = 'StageName';
        cond1.TCRE__Operator__c = '=';
        cond1.TCRE__Value__c = 'test';
        cond1.TCRE__Rule_Config__c = conf.Id;
        insert cond1;

        TCRE__Rule_Condition__c cond2 = new TCRE__Rule_Condition__c();
        cond2.TCRE__Field_Name__c = 'CreatedDate';
        cond2.TCRE__Operator__c = '>';
        cond2.TCRE__Value__c = '12/12/2010';
        cond2.TCRE__Rule_Config__c = conf.Id;
        insert cond2;
        
        TCRE__Rule_Condition__c cond3 = new TCRE__Rule_Condition__c();
        cond3.TCRE__Field_Name__c = 'Amount';
        cond3.TCRE__Operator__c = '<';
        cond3.TCRE__Value__c = '234.56';
        cond3.TCRE__Rule_Config__c = conf.Id;
        insert cond3;
        
        Tax_Rule__c tr = new Tax_Rule__c();
        tr.Rule_Config__c = conf.Id;
        tr.State__c = 'MN';
        tr.Tax_Basis_Field__c = 'Amount';
        tr.Rate_Code_to_Use__c = '001';
        tr.Description__c = 'Description';
        tr.Tax_type__c = 'Regular';
        tr.State_Rate_Code_to_Use__c = '001';
        tr.County_Rate_Code_to_Use__c = '001';
        tr.TCounty_Rate_Code_to_Use__c = '001';
        tr.City_Rate_Code_to_Use__c = '001';
        tr.TCity_Rate_Code_to_Use__c = '001';
        insert tr;
        
        Account acc = new Account();
        acc.Name = 'test';
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.StageName = 'test';
        opp.CloseDate = Date.today();
        opp.Amount = 123.45;
        opp.Name = 'test';
        opp.AccountId = acc.Id;
        opp.Tax_State__c = 'MN';
        opp.Tax_County__c = 'WASHINGTON';
        opp.Tax_City__c = 'WOODBURY';
        insert opp;
        
        TC_BridgewareTaxJurisdiction mockJurisdiction = new TC_BridgewareTaxJurisdiction();
        mockJurisdiction.city = 'Fort Campbell North';
        mockJurisdiction.county = 'Christian';
        mockJurisdiction.state = 'Kentucky';
        mockJurisdiction.cityCode = '001';
        mockJurisdiction.countyCode = '047';
        mockJurisdiction.stateCode = 'KY';        
        mockJurisdiction.rateCode = '001';
        mockJurisdiction.stateTaxRate = 0.01;
        mockJurisdiction.countyTransTaxRate = 0.01;
        mockJurisdiction.countyTaxRate = 0.01;
        mockJurisdiction.cityTaxRate = 0.01;
        mockJurisdiction.cityTransTaxRate = 0.01;
        Map<String, String> fieldsConfig = new Map<String, String>();
        for(PEAC_BulkAssetsUpload__mdt mdt : [SELECT DeveloperName,Value__c FROM PEAC_BulkAssetsUpload__mdt WHERE DeveloperName IN ('AssetFieldsRespDataMapping','RateFieldsRespDataMapping')]){
			fieldsConfig.put(mdt.DeveloperName, mdt.Value__c);
		}
        
        PEAC_BridgewareSelectZipGeoCodes.saveRates(new List<TC_BridgewareTaxJurisdiction>{mockJurisdiction},fieldsConfig.get('RateFieldsRespDataMapping'));
        
    }
    
    @isTest
    public static void getTaxJurisdictionsTest(){
        TC_BridgewareSelectZipGeoCodeRespBean bean = new TC_BridgewareSelectZipGeoCodeRespBean();
        TC_BridgewareSelectZipGeoCodeRespBean.UniDataZipGeoCodeContentData uniData = new TC_BridgewareSelectZipGeoCodeRespBean.UniDataZipGeoCodeContentData();
        TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipState uniDataVtZipState = new TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipState();
        uniDataVtZipState.setCode('test');
        uniDataVtZipState.setDescription('test');
        TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipCounty uniDataVtZipCounty = new TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipCounty();
        uniDataVtZipCounty.setCode('test');
        uniDataVtZipCounty.setDescription('test');
        TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipCity uniDataVtZipCity = new TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipCity();
        uniDataVtZipCity.setCode('test');
        uniDataVtZipCity.setDescription('test');
        TC_BridgewareSelectZipGeoCodeRespBean.UniDataTaxType uniDataVtTaxType = new TC_BridgewareSelectZipGeoCodeRespBean.UniDataTaxType();
        uniDataVtTaxType.setCode('test');
        uniDataVtTaxType.setDescription('test');
        uniDataVtTaxType.setStateTaxRate(1);
        uniDataVtTaxType.setCountyTaxRate(1);
        uniDataVtTaxType.setCountyTransTaxRate(1);
        uniDataVtTaxType.setCityTaxRate(1);
        uniDataVtTaxType.setCityTransTaxRate(1);

        uniDataVtZipCity.setTaxTypeList(new List<TC_BridgewareSelectZipGeoCodeRespBean.UniDataTaxType>{uniDataVtTaxType});
        uniDataVtZipCounty.setVtZipCityList(new List<TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipCity>{uniDataVtZipCity});
        uniDataVtZipState.setVtZipCountyList(new List<TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipCounty>{uniDataVtZipCounty});
        uniData.setVtZipStateList(new List<TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipState>{uniDataVtZipState});
        bean.setContentData(uniData);

        PEAC_BridgewareSelectZipGeoCodes.getTaxJurisdictions(bean);
    }
}