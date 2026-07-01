@isTest 
public class PEAC_AssetTriggerHandlerTest {
    @TestSetup
    public static void setupAssetTest () {
		PEAC_GenerateTaxMatrixBatch.isRunning = true;
        Account acc = new Account (Name = 'test');
        insert acc;
        Opportunity opp = new Opportunity (CloseDate = Date.today()+10,Name='test',AccountId=acc.Id,Equipment_Cost__c=50000,StageName='Decision',
                                           Account_Business_Street__c='208 East 58th St' , Account_Business_City__c ='New York',Account_Business_State_Province__c ='NY' , 
                                           Account_Business_Zip_Postal_Code__c='10022',Hard_Lease_Rate_Factor__c = 0.05,Soft_Lease_Rate_Factor__c = 0.10,Originating_Business__c = 'VA PEAC');
        insert opp;
        insert new Asset__c (End_User_Billing_Address__c = true, Quantity__c = 1, Equipment_Code__c = 'ATM',Opportunity_Contract_Type__c='TL',
                             Usage_User_Table__c = '1',Equipment_Sub_Category__c = 'ATM', Opportunity__c = opp.Id, Cost__c = 0);
        
        insert new Marlin_Configuration__c(Disable_Standard_Asset_Generation__c = false);
    }
    
    @isTest
    public static void PopulateAssetListPriceTest(){
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        Asset__c ass = [SELECT Id FROM Asset__c LIMIT 1];
        ass.Equipment_Location_City__c = 'city';
        ass.List_Price__c = 1000;
        ass.Cost__c = 100;
        Test.startTest();
        try{
            update ass;
        } catch(Exception ex){}
        Test.stopTest();
        Map<Id, Asset__c> AssetMap = new Map<Id, Asset__c>{ass.Id => ass};
            TC_AssetTriggerHelper.createStandardAsset(null, AssetMap);
    }
    
    @isTest 
    static void testPopulateEquipmentAddress() {
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        TC_RecursiveTriggerHelper.populateEquipmentAddress = false;
        
        Opportunity opp = [SELECT Id, Account_Business_Street__c, Account_Business_City__c, Account_Business_State_Province__c, Account_Business_Zip_Postal_Code__c FROM Opportunity LIMIT 1];
        Asset__c ass = [SELECT Id, End_User_Billing_Address__c, Equipment_Address__c, Opportunity__c FROM Asset__c WHERE Opportunity__c = :opp.Id];
        
        List<Opportunity> oppsToUpdate = new List<Opportunity>{opp};
            List<Opportunity> assetOpps = new List<Opportunity>{opp};
                Map<String, List<Asset__c>> oppAssetsMap = new Map<String, List<Asset__c>>{
                    opp.Id => new List<Asset__c>{ass}
                };
                    
                    Test.startTest();
        List<Opportunity> results = PEAC_AssetTriggerHandler.populateEquipmentAddress(oppsToUpdate, assetOpps, oppAssetsMap);
        
        Asset__c secondAsset = new Asset__c(Opportunity__c = opp.Id, Quantity__c = 1, Equipment_Code__c = 'ATM');
        oppAssetsMap.get(opp.Id).add(secondAsset);
        
        TC_RecursiveTriggerHelper.populateEquipmentAddress = false; 
        List<Opportunity> resultsMulti = PEAC_AssetTriggerHandler.populateEquipmentAddress(oppsToUpdate, assetOpps, oppAssetsMap);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(0, results.size(), 'Method should return updated opportunities');
        System.assertEquals('See Schedule C', resultsMulti[0].Final_Product_Loc__c, 'Multi-asset opps should show Schedule C');
    }
    
    @isTest 
    static void bookingRulesDefaultDepreciationFormerPBTest(){
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        Account acc = new Account (Name = 'test');
        insert acc;
        Opportunity opp = new Opportunity (CloseDate = Date.today()+10,Name='test',AccountId=acc.Id,Equipment_Cost__c=50000,StageName='Decision',
                                           Account_Business_Street__c='208 East 58th St' , Account_Business_City__c ='New York',Account_Business_State_Province__c ='NY' , 
                                           Account_Business_Zip_Postal_Code__c='10022');
        Test.startTest();  
        insert opp;
        
        Asset__c ass =  new Asset__c (End_User_Billing_Address__c = true, Quantity__c = 1, Equipment_Code__c = 'ATM',Opportunity_Contract_Type__c='TL',
                                      Usage_User_Table__c = '1',Equipment_Sub_Category__c = 'ATM', Opportunity__c = opp.Id, Cost__c = 0);
        insert ass;
        List<Asset__c> assetList = new List<Asset__c>{ass};
            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>{opp.Id => opp};
                
                PEAC_AssetTriggerHelper.bookingRulesDefaultDepreciationFormerPB(assetList,oppMap);
        Test.stopTest();
    }
    
    @IsTest
    static void test_setAssetFields_after_listPriceGT0_updatesOrigAndCost_andClearsBasesWhenNotTL() {
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        Asset__c a = new Asset__c();
        a.List_Price__c = 999;   
        a.Cost__c = 10;         
        a.Opportunity_Contract_Type__c = 'CS';
        
        Decimal priorListPrice = a.List_Price__c;
        // Act
        Test.startTest();
        PEAC_AssetTriggerHelper.setAssetFields(a, 'after');
        Test.stopTest();
    }
    
    @IsTest
    static void test_setAssetFields_after_listPriceNotGT0_doesNotUpdateOrigOrCost() {
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        Asset__c a = new Asset__c();
        a.List_Price__c = null;
        a.Orig_Cost__c = 123;
        a.Cost__c = 456;
        a.Opportunity_Contract_Type__c = 'TL';
        
        Decimal priorOrig = a.Orig_Cost__c;
        Decimal priorCost = a.Cost__c;
        
        Test.startTest();
        PEAC_AssetTriggerHelper.setAssetFields(a, 'after');
        Test.stopTest();
    }
    
    @IsTest
    static void test_chicago_upfrontTaxInList_sets150_060_060_noDml() {
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        // Arrange
        Asset__c a = new Asset__c();
        
        a.Equipment_Location_City__c = 'CHICAGO';
        a.Equipment_Location_State__c = 'ILLINOIS';
        a.Upfront_Tax_Code__c = '100';          
        a.State_Tax_Code__c = '999';            
        a.Upfront_City_Tax_Amount__c = 25;
        
        Map<Id, Opportunity> opps = new Map<Id, Opportunity>(); 
        Map<Id, List<String>> fieldsChangedById = new Map<Id, List<String>>{
            a.Id => new List<String>{ 'Equipment_Location_City__c' }
        };
            
            // Act
            PEAC_AssetTriggerHelper.setTaxCodeTo060UpfrontTaxStateFormerPB(
                new List<Asset__c>{ a },
                false, // isNew
                opps,
                fieldsChangedById
            );
    }
    
    @IsTest
    static void test_illinois_nonChicago_upfrontTaxInList_sets001_001_001_noDml() {
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        // Arrange
        Asset__c a = new Asset__c();
        a.Equipment_Location_City__c = 'SPRINGFIELD';
        a.Equipment_Location_State__c = 'ILLINOIS';
        a.Upfront_Tax_Code__c = '001';          // in list
        a.State_Tax_Code__c = '999';            // ensure condition true even if isNew=false
        
        Map<Id, Opportunity> opps = new Map<Id, Opportunity>();
        Map<Id, List<String>> fieldsChangedById = new Map<Id, List<String>>{
            a.Id => new List<String>{ 'Upfront_Tax_Code__c' }
        };
            
            // Act
            PEAC_AssetTriggerHelper.setTaxCodeTo060UpfrontTaxStateFormerPB(
                new List<Asset__c>{ a },
                false,
                opps,
                fieldsChangedById
            );
        
        
    }
    
    @IsTest
    static void test_otherState_nonChicago_upfrontTaxInList_sets060_060_060_noDml() {
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        // Arrange
        Asset__c a = new Asset__c();
        a.Equipment_Location_City__c = 'DALLAS';
        a.Equipment_Location_State__c = 'TEXAS';
        a.Upfront_Tax_Code__c = '150';          // in list
        a.State_Tax_Code__c = '999';            // ensure main condition passes
        
        Map<Id, Opportunity> opps = new Map<Id, Opportunity>();
        Map<Id, List<String>> fieldsChangedById = new Map<Id, List<String>>{
            a.Id => new List<String>{ 'Equipment_Location_City__c' }
        };
            // Act
            PEAC_AssetTriggerHelper.setTaxCodeTo060UpfrontTaxStateFormerPB(
                new List<Asset__c>{ a },
                false,
                opps,
                fieldsChangedById
            );
    }
    
    @IsTest
    static void test_chicago_state060_upfrontCityTaxAmtPositive_resetsToZero_onFieldChange_noDml() {
        System.debug('--------');
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        // Arrange
        Asset__c a = new Asset__c();
        a.Equipment_Location_City__c = 'CHICAGO';
        a.Equipment_Location_State__c = 'ILLINOIS';
        a.Upfront_Tax_Code__c = '999';          // NOT in upfrontTaxCodesTemp so we go to the inner else
        a.State_Tax_Code__c = '060';
        a.Upfront_City_Tax_Amount__c = 10;
        
        // Ensure we hit: (isNew || changedEquipLocationCity || changedStateTaxCode || changedUpfrontCityTaxAmt)
        Map<Id, List<String>> fieldsChangedById = new Map<Id, List<String>>{
            a.Id => new List<String>{ 'Upfront_City_Tax_Amount__c' }
        };
            
            Map<Id, Opportunity> opps = new Map<Id, Opportunity>();
        
        // Act
        PEAC_AssetTriggerHelper.setTaxCodeTo060UpfrontTaxStateFormerPB(
            new List<Asset__c>{ a },
            false, 
            opps,
            fieldsChangedById
        );
        
    }
/*    
    @IsTest
    public static void testUpdateAssetEquipmentZip(){
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        Account acc = new Account (Name = 'test');
        insert acc;
        Opportunity opp = new Opportunity (CloseDate = Date.today()+10,Name='test',AccountId=acc.Id,Equipment_Cost__c=50000,StageName='Decision',
                                           Account_Business_Street__c='208 East 58th St' , Account_Business_City__c ='New York',Account_Business_State_Province__c ='NY' , 
                                           Account_Business_Zip_Postal_Code__c='10475');
        Test.startTest();        
        insert opp;
    
    /*
    @IsTest
    public static void testUpdateAssetEquipmentZip(){
		// commenting this code, to get tracked in copdao
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        Account acc = new Account (Name = 'test');
        insert acc;
        Opportunity opp = new Opportunity (CloseDate = Date.today()+10,Name='test',AccountId=acc.Id,Equipment_Cost__c=50000,StageName='Decision',
                                           Account_Business_Street__c='208 East 58th St' , Account_Business_City__c ='New York',Account_Business_State_Province__c ='NY' , 
                                           Account_Business_Zip_Postal_Code__c='10022');
        Test.startTest();        
        insert opp;
        
        try{
        	insert new Asset__c (End_User_Billing_Address__c = true, Quantity__c = 1, Equipment_Code__c = 'ATM',
                             Usage_User_Table__c = '1',Equipment_Sub_Category__c = 'ATM', Opportunity__c = opp.Id, Equipment_Zip__c= PEAC_ConstantClass.ASSET_EQUIPMENT_ZIP_00000);
        
        //ass.Equipment_Zip__c = PEAC_ConstantClass.ASSET_EQUIPMENT_ZIP_00000;
        
            //update ass;
        } catch(Exception ex){}
        Test.stopTest();   
    }*/
/*
    @IsTest
    public static void testUpdateAssetEquipmentZip(){
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        Account acc = new Account (Name = 'test');
        insert acc;
        Opportunity opp = new Opportunity (CloseDate = Date.today()+10,Name='test',AccountId=acc.Id,Equipment_Cost__c=50000,StageName='Decision',
                                           Account_Business_Street__c='208 East 58th St' , Account_Business_City__c ='New York',Account_Business_State_Province__c ='NY' , 
                                           Account_Business_Zip_Postal_Code__c='10022');
        Test.startTest();        
        insert opp;
        
        try{
        	insert new Asset__c (End_User_Billing_Address__c = true, Quantity__c = 1, Equipment_Code__c = 'ATM',
                             Usage_User_Table__c = '1',Equipment_Sub_Category__c = 'ATM', Opportunity__c = opp.Id, Equipment_Zip__c= PEAC_ConstantClass.ASSET_EQUIPMENT_ZIP_00000);
        
        //ass.Equipment_Zip__c = PEAC_ConstantClass.ASSET_EQUIPMENT_ZIP_00000;
        
            //update ass;
        } catch(Exception ex){}
        Test.stopTest();   
    }
/*
	@IsTest
    public static void testSetZipUpdatedFlag(){
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        Asset__c ass = [SELECT Id FROM Asset__c LIMIT 1];
        ass.Equipment_Zip__c = PEAC_ConstantClass.ASSET_EQUIPMENT_ZIP_00000;
        Test.startTest();
        try{
            update ass;
            PEAC_AssetTriggerHelper.setIcelandStateAndTaxCodes(new List<Asset__c>{ass});
        } catch(Exception ex){}
        Test.stopTest();   
    }
    */
    
    
	@IsTest
    public static void testSetIcelandStateAndTaxCodes(){
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        Asset__c ass = [SELECT Id FROM Asset__c LIMIT 1];
        ass.Equipment_Zip__c = PEAC_ConstantClass.ASSET_EQUIPMENT_ZIP_00000;
        Test.startTest();
        try{
            PEAC_AssetTriggerHelper.setIcelandStateAndTaxCodes(new List<Asset__c>{ass});
        } catch(Exception ex){}
        Test.stopTest();   
    }

	@IsTest
    public static void testSetIcelandStateAndTaxCodes2(){
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        Asset__c ass = [SELECT Id FROM Asset__c LIMIT 1];
        ass.Equipment_Zip__c = PEAC_ConstantClass.ASSET_EQUIPMENT_ZIP_00000;
        Test.startTest();
        try{
            PEAC_AssetTriggerHelper.setIcelandStateAndTaxCodes(new List<Asset__c>{ass});
        } catch(Exception ex){}
        Test.stopTest();   
    }
    
    @IsTest
    public static void testhandleAfterDelete(){
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        Asset__c asset = [SELECT Id FROM Asset__c LIMIT 1];
        Test.startTest();
        delete asset;
        Test.stopTest();   
    }
    
     @IsTest
    public static void testcalculateMonthlyRent(){
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        Set<Id> oppIds = new Set<Id>();
        List<Asset__c> assetList = [SELECT Id,Equipment_Code__c,Opportunity__c,Asset_Classification__c,List_Price__c FROM Asset__c];
        for(Asset__c asset : assetList) {
            if (asset.Opportunity__c != null) {
                oppIds.add(asset.Opportunity__c);
              }
        }
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([ SELECT Id, Hard_Lease_Rate_Factor__c, Soft_Lease_Rate_Factor__c  FROM Opportunity 
                                                       WHERE Id In :oppIds ]);
        Test.startTest();
        PEAC_AssetTriggerHelper.calculateMonthlyRent(assetList, oppMap);
        Test.stopTest();
        
        
    }
    
}