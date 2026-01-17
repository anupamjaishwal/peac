@isTest
public class SL_assetTriggerHelperTest {
    
    @isTest
    public static void generalTest(){
        SL_SCTestData.createBridgeWareSetting();
        String accntid = '';
        RecordType accrectypeid = [select id from RecordType where DeveloperName = 'End_User'];
        Account acc = new Account();
        acc.RecordTypeId = accrectypeid.id;
        acc.Name = 'Test Account';
        insert acc;
        accntid = acc.id;
        
        Opportunity opty = new Opportunity();            
        opty.Name = 'Testing Trigger Opportunity Franchise';
        opty.AccountId = accntid;
        opty.StageName = 'Quote';
        opty.CloseDate = system.today() + 10;
        opty.Account_Business_City__c = 'city';
        opty.Account_Business_Street__c= 'street';
        opty.Account_Business_State_Province__c= 'IL';
        opty.Account_Business_Zip_Postal_Code__c= '678909';
        // opty.Equipment_Cost__c = 1234;
        opty.Equipment_Description__c = 'test Descript';
        insert opty;
        
        Asset__c newAsset = new Asset__c ();
        newAsset.Opportunity__c = opty.id;
        newAsset.Equipment_Code__c = 'ATM';        
        newAsset.Equipment_Street__c = 'CMC Street';
        newAsset.Equipment_City__c = 'Chester';
        newAsset.Equipment_State__c = 'IL';
        newAsset.Equipment_Zip__c = '60607';
        newAsset.Residual_Amount__c = 1;
        newAsset.Quantity__c = 1;
        newAsset.List_Price__c = 0;
        newAsset.Opportunity_Contract_Type__c = 'TL';
        newAsset.Equipment_Location_State__c = 'ILLINOIS';
        newAsset.Equipment_Location_City__c = 'CHESTER';
        newAsset.Upfront_Tax_Code__c = '150';

        
        Asset__c newAsset2 = new Asset__c ();
        newAsset2.Opportunity__c = opty.id;
        newAsset2.Equipment_Code__c = 'ATM';
        newAsset2.Description__c = 'Testing';
        newAsset2.Cost__c = 1234;
        newAsset2.Equipment_Street__c = 'CMC Street';
        newAsset2.Equipment_City__c = 'Chicago';
        newAsset2.Equipment_State__c = 'IL';
        newAsset2.Equipment_Zip__c = '60607';
        newAsset2.End_User_Billing_Address__c = true;
        newAsset2.Residual_Amount__c = 2;
        newAsset2.Quantity__c = 1;
        newAsset2.List_Price__c = 0;
        newAsset2.Opportunity_Contract_Type__c = 'TL';
        newAsset2.State_Tax_Code__c = '031';
        newAsset2.Equipment_Location_State__c = 'TENNESSEE';
        newAsset2.Tax_Exempt_Equipment__c = 'No';
        
        Asset__c newAsset3 = new Asset__c ();
        newAsset3.Opportunity__c = opty.id;
        newAsset3.Equipment_Code__c = 'ATM';
        newAsset3.Description__c = 'Testing';
        newAsset3.Cost__c = 1234;
        newAsset3.Equipment_Street__c = 'CMC Street';
        newAsset3.Equipment_City__c = 'Chicago';
        newAsset3.Equipment_State__c = 'IL';
        newAsset3.Equipment_Zip__c = '60607';
        newAsset3.Quantity__c = 1;
        newAsset3.List_Price__c = 0;
        newAsset3.State_Tax_Code__c = '036';
        newAsset3.Equipment_Location_City__c = 'CHICAGO';
        newAsset3.Upfront_Tax_Code__c = '100';
        
        List<Asset__c> testAssets = new List<Asset__c>();
        testAssets.add(newAsset);
        testAssets.add(newAsset2);
        testAssets.add(newAsset3);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TC_BridgewareBookContractCalloutMockImpl ());
        insert testAssets;
        testAssets[0].Quantity__c = 7;
        testAssets[2].Opportunity_Contract_Type__c = 'TL';
        //insert newAsset2;
        update testAssets;
        List<Opportunity> oppsAfter = [SELECT Id, Residual__c, Number_of_Units__c, Equipment_Cost__c, Opportunity_Booked_Date__c,
            (SELECT Id, Begin_Depreciation_Date__c, Calculate_ACE_Depr__c, Calculate_AMT__c, Depreciation_Basis__c,
            Federal_Calculation_Basis__c, Federal_Convention__c, Federal_Life__c, Federal_Method__c, State_Begin_Depreciation_Date__c,
            State_Depreciation_Basis__c, State_Life_in_Months__c, State_Method__c, Cost__c, Purchase_Options__c,
            City_Tax_Code__c, County_Tax_Code__c, State_Tax_Code__c FROM Assets__r) 
            FROM Opportunity];
        List<Asset__c> assetsAfter = oppsAfter[0].Assets__r;
        System.Assert.areEqual('58', assetsAfter[0].Federal_Method__c, 'Federal Depreciation Method is set to default: 58');
        System.Assert.areEqual('21', assetsAfter[1].Federal_Method__c, 'When State Tax Code is 031 Federal Depreciation Method is set to S/L - No Bonus');
        System.Assert.areEqual('21', assetsAfter[2].Federal_Method__c, 'When State Tax Code is 036 Federal Depreciation Method is set to S/L - No Bonus');
        System.Assert.areEqual(oppsAfter[0].Opportunity_Booked_Date__c, assetsAfter[2].Begin_Depreciation_Date__c, 'opp booked date is stamped to begin depreciation date');
        System.Assert.areEqual(true, assetsAfter[2].Calculate_ACE_Depr__c, 'default values for opp type TL');
        System.Assert.areEqual(true, assetsAfter[2].Calculate_AMT__c, 'default values for opp type TL');
        System.Assert.areEqual(assetsAfter[2].Cost__c, assetsAfter[2].Depreciation_Basis__c, 'default values for opp type TL');
        System.Assert.areEqual(assetsAfter[2].Cost__c, assetsAfter[2].Federal_Calculation_Basis__c, 'default values for opp type TL');
        System.Assert.areEqual('6', assetsAfter[2].Federal_Convention__c, 'default values for opp type TL');
        System.Assert.areEqual(60, assetsAfter[2].Federal_Life__c, 'default values for opp type TL');
        System.Assert.areEqual(oppsAfter[0].Opportunity_Booked_Date__c, assetsAfter[2].State_Begin_Depreciation_Date__c, 'default values for opp type TL');
        System.Assert.areEqual(assetsAfter[2].Cost__c, assetsAfter[2].State_Depreciation_Basis__c, 'default values for opp type TL');
        System.Assert.areEqual(60, assetsAfter[2].State_Life_in_Months__c, 'default values for opp type TL');
        System.Assert.areEqual('3', assetsAfter[2].State_Method__c, 'default values for opp type TL');
        System.Assert.areEqual('001', assetsAfter[0].City_Tax_Code__c, 'for ILLINOIS but not CHICAGO');// SAL-5233 Misael Romero
        System.Assert.areEqual('001', assetsAfter[0].County_Tax_Code__c, 'for ILLINOIS but not CHICAGO');
        System.Assert.areEqual('001', assetsAfter[0].State_Tax_Code__c, 'for ILLINOIS but not CHICAGO');
        System.Assert.areEqual('060', assetsAfter[1].County_Tax_Code__c, 'former PB sets countyTaxCode to 060 for TENESSEE');
        System.Assert.areEqual('150', assetsAfter[2].City_Tax_Code__c, 'for CHICAGO, ILLINOIS');
        System.Assert.areEqual('060', assetsAfter[2].County_Tax_Code__c, 'for CHICAGO, ILLINOIS');
        System.Assert.areEqual('060', assetsAfter[2].State_Tax_Code__c, 'for CHICAGO, ILLINOIS');

        delete testAssets;       
        Test.stopTest();
        oppsAfter = [SELECT Id, Residual__c, Number_of_Units__c, Equipment_Cost__c FROM Opportunity];
        System.Assert.areEqual(3, oppsAfter[0].Residual__c, 'on TC_AssetTriggerHelper the Residual Amount is rolled Up to Opp');
        System.Assert.areEqual(3, oppsAfter[0].Number_of_Units__c, 'on TC_AssetTriggerHelper the Quantity__c is rolled Up to Opp');
        System.Assert.areEqual(2468, oppsAfter[0].Equipment_Cost__c, 'on TC_AssetTriggerHelper the Cost__c is rolled Up to Opp');
    }
    
    @isTest
    public Static void singleAsset(){
        SL_SCTestData.createBridgeWareSetting();
        String accntid = '';
        Id endUserRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
        Account acc = new Account();
        acc.RecordTypeId = endUserRecordTypeId;
        acc.Name = 'Test Account';
        insert acc;
        accntid = acc.id;
        
        Opportunity opty = new Opportunity();            
        opty.Name = 'Testing Trigger Opportunity Franchise';
        opty.AccountId = accntid;
        opty.StageName = 'Quote';
        opty.CloseDate = system.today() + 10;
        opty.Account_Business_City__c = 'city';
        opty.Account_Business_Street__c= 'street';
        opty.Account_Business_State_Province__c= 'IL';
        opty.Account_Business_Zip_Postal_Code__c= '678909';
        opty.Equipment_Cost__c = 1234;
        opty.Equipment_Description__c = 'test Descript';
        opty.Invoice_Description__c = 'opp invoice test desc';
        insert opty;
        
        Asset__c newAsset1 = new Asset__c ();
        newAsset1.Quantity__c = 3;
        newAsset1.Opportunity__c = opty.id;
        newAsset1.Equipment_Code__c = 'ATM';
        newAsset1.Description__c = 'Testing asset desc';
        newAsset1.Cost__c = 1234;
        newAsset1.Equipment_Street__c = 'CMC Street';
        newAsset1.Equipment_City__c = 'Chicago';
        newAsset1.Equipment_State__c = 'IL';
        newAsset1.Equipment_Zip__c = '60607';
        newAsset1.End_User_Billing_Address__c = true;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TC_BridgewareBookContractCalloutMockImpl ());
        insert newAsset1;
        newAsset1.Cost__c = 2345;
        newAsset1.Equipment_Location_City__c = 'CHICAGO';
        newAsset1.State_Tax_Code__c = '060';
        newAsset1.Upfront_City_Tax_Amount__c = 120;
        update newAsset1;
        Opportunity oppAfter = [SELECT Id, Equip_Code1__c, Equipment_Address__c, Account_Business_Street__c,
            Account_Business_City__c, Account_Business_State_Province__c, Account_Business_Zip_Postal_Code__c,
            Final_Product_Loc__c, Product_Location__c, Invoice_Description__c, Equipment_Description__c,
            (SELECT Id, Equipment_Code__c, Equipment_Full_Address__c, Description__c,
            First_Record__c, Upfront_City_Tax_Amount__c FROM Assets__r)
            FROM Opportunity WHERE Id = :opty.Id];
            Asset__c assetAfter = oppAfter.Assets__r[0];
        System.Assert.areEqual(oppAfter.Equip_Code1__c, assetAfter.Equipment_Code__c, 'in assetTriggerHandler the code from first Asset__c is updated in the Opp');
        System.Assert.areEqual(oppAfter.Account_Business_Street__c + ' ' + oppAfter.Account_Business_City__c + ' ' +oppAfter.Account_Business_State_Province__c + ' '+ oppAfter.Account_Business_Zip_Postal_Code__c,
            oppAfter.Equipment_Address__c, 'in assetTriggerHandler Equipment Address is compossed from the business location info');
        System.Assert.areEqual(oppAfter.Equipment_Address__c,
            oppAfter.Final_Product_Loc__c, 'in assetTriggerHandler Final Product Location is made the same as Equipment Address');
        System.Assert.areEqual(oppAfter.Product_Location__c,
           assetAfter.Equipment_Full_Address__c, 'in assetTriggerHandler Product Location is made the same as Equipment Full Address');
        System.Assert.areEqual(true,
            assetAfter.First_Record__c, 'in assetTriggerHandler the first asset gets First Record = true');
        // SAL-5233 Misael Romero
        System.Assert.areEqual(0, assetAfter.Upfront_City_Tax_Amount__c, 'for city CHICAGO and tax code 060 Upfront_City_Tax_Amount__c is cleared');
        newAsset1.Description__c = 'Testing asset desc 2';
        newAsset1.Equipment_Location_State__c = 'NEW JERSEY';
        newAsset1.Equipment_Location_City__c = 'RIO GRANDE';
        newAsset1.Upfront_Tax_Code__c = '001';
        update newAsset1;
        oppAfter = [SELECT Id, Invoice_Description__c, Equipment_Description__c,
            (SELECT Id, Equipment_Code__c, Equipment_Full_Address__c, Description__c, City_Tax_Code__c, 
            County_Tax_Code__c, State_Tax_Code__c FROM Assets__r)
            FROM Opportunity WHERE Id = :opty.Id];
        assetAfter = oppAfter.Assets__r[0];
        System.Assert.areEqual(oppAfter.Invoice_Description__c,
            assetAfter.Description__c, 'in assetTriggerHandler Invoice Description is made the same as the Asset\'s Description');
        System.Assert.areEqual(oppAfter.Equipment_Description__c,
            assetAfter.Description__c, 'in assetTriggerHandler Equipment Description is made the same as the Asset\'s Description');
        // SAL-5233 Misael Romero
        System.Assert.areEqual('060', assetAfter.City_Tax_Code__c, 'for non-ILLINOIS states with upfront tax codes 001, 100 and 150');
        System.Assert.areEqual('060', assetAfter.County_Tax_Code__c, 'for non-ILLINOIS states with upfront tax codes 001, 100 and 150');
        System.Assert.areEqual('060', assetAfter.State_Tax_Code__c, 'for non-ILLINOIS states with upfront tax codes 001, 100 and 150');
        Test.stopTest();
    }

    // not sure if this is deprecated, I think it is
    // @isTest
    // public Static void deleteSecondAsset(){
    //     SL_SCTestData.createAccountAndContracts(1, 1);
    //     Account acc = SL_SCTestData.testAccounts[0];
    //     SL_SCTestData.createOpportunitiesAndAssets(acc.Id, 1, 2);
    //     Test.startTest();
    //     delete SL_SCTestData.testAssets[1];
    //     Test.stopTest();
    //     Opportunity oppAfter = [SELECT Id, Contract_Type__c,
    //         (SELECT Id, Federal_Method__c FROM Assets__r)
    //         FROM Opportunity];
    //         Asset__c assetAfter = oppAfter.Assets__r[0];
    //     System.Assert.areEqual('58', assetAfter.Federal_Method__c, 'Federal Depreciation Method is actually default: 58');
    // }


    /// came from fullCopy, I don't know what it does yet
    @isTest
    public Static void singleAssetDelete(){
        SL_SCTestData.createBridgeWareSetting();
        String accntid = '';
        Id endUserRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
        Account acc = new Account();
        acc.RecordTypeId = endUserRecordTypeId;
        acc.Name = 'Test Account';
        insert acc;
        accntid = acc.id;
        
        Opportunity opty = new Opportunity();            
        opty.Name = 'Testing Trigger Opportunity Franchise';
        opty.AccountId = accntid;
        opty.StageName = 'Quote';
        opty.CloseDate = system.today() + 10;
        opty.Account_Business_City__c = 'city';
        opty.Account_Business_Street__c= 'street';
        opty.Account_Business_State_Province__c= 'IL';
        opty.Account_Business_Zip_Postal_Code__c= '678909';
        opty.Equipment_Cost__c = 1234;
        opty.Equipment_Description__c = 'test Descript';
        opty.Invoice_Description__c = 'opp invoice test desc';
        insert opty;
        
        Asset__c newAsset1 = new Asset__c ();
        newAsset1.Quantity__c = 3;
        newAsset1.Opportunity__c = opty.id;
        newAsset1.Equipment_Code__c = 'ATM';
        newAsset1.Description__c = 'Testing asset desc';
        newAsset1.Cost__c = 1234;
        newAsset1.Equipment_Street__c = 'CMC Street';
        newAsset1.Equipment_City__c = 'Chicago';
        newAsset1.Equipment_State__c = 'IL';
        newAsset1.Equipment_Zip__c = '60607';
        newAsset1.End_User_Billing_Address__c = true;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TC_BridgewareBookContractCalloutMockImpl ());
        insert newAsset1;
        delete newAsset1;
        Test.stopTest();
    }

    @isTest
    public Static void costUpdated(){
        SL_SCTestData.createAccountAndContracts(1, 1);
        SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[0].Id, 1, 1);
        Opportunity theOpp = SL_SCTestData.testOpportunities[0];
        Asset__c theAsset = SL_SCTestData.testAssets[0];
        theAsset.Financed_Trigger__c = true;
        theAsset.State_Code__c = 'AZ';
        theAsset.Equipment_Location_State__c = 'ARIZONA';
        theAsset.Equipment_Location_City__c = 'PHOENIX';
        Test.startTest();
        update theAsset;
        List<Asset__c> assetsAfter = [SELECT Id, Equipment_City__c, Equipment_State__c, Equipment_Location_State__c, 
            Opportunity__r.Tax_City__c, Opportunity__r.Tax_State__c FROM Asset__c];
        System.Assert.areEqual('PHOENIX', assetsAfter[0].Equipment_City__c, 'In TC_AssetTriggerHelper Equipment_City__c must be copied from Equipment_Location_City__c');
        System.Assert.areEqual('AZ', assetsAfter[0].Equipment_State__c, 'In TC_AssetTriggerHelper Equipment_State__c must be translated from Equipment_Location_State__c');
        System.Assert.areEqual(assetsAfter[0].Equipment_City__c, assetsAfter[0].Opportunity__r.Tax_City__c, 'In TC_AssetTriggerHelper opp.Tax_City__c  must be copied from first Asset');
        System.Assert.areEqual(assetsAfter[0].Equipment_Location_State__c, assetsAfter[0].Opportunity__r.Tax_State__c, 'In TC_AssetTriggerHelper opp.Tax_State__c  must be copied from first Asset');
        
        TC_AssetTriggerHelper.createStandardAsset (null, new Map<Id, Asset__c>{theAsset.Id => theAsset});
        Map<Id, Asset__c> newAssets = new Map<Id, Asset__c>();
        Map<Id, List<String>> fieldsChangedById = new Map<Id, List<String>>();
        Map<Id, Opportunity> opps = new Map<Id, Opportunity>();
        newAssets.put(theAsset.Id, theAsset);
        fieldsChangedById.put(theAsset.Id, new List<String>{'Equipment_Location_City__c'});
        theOpp.StageName = 'Funding';
        opps.put(theOpp.Id, theOpp);
        try{
            TC_AssetTriggerHelper.generateTaxMatrixFormerPB(newAssets, true, fieldsChangedById, opps);
        }catch(Exception e){

        }
        Test.stopTest();
    }

    @isTest
    public Static void FirstAssetOnOpportunity(){
        SL_SCTestData.createAccountAndContracts(1, 1);
        Test.startTest();
        SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[0].Id, 1, 5);
        Opportunity theOpp = SL_SCTestData.testOpportunities[0];
        List<Asset__c> assets = SL_SCTestData.testAssets;
        delete assets[0];
        Test.stopTest();
        List<Asset__c> assetsAfter = [SELECT Id, First_Record__c FROM Asset__c];
        System.assert.areEqual(true, assetsAfter[0].First_Record__c, 'the next Asset created must get First_Record__c=true when deleting');
        System.assert.areEqual(false, assetsAfter[1].First_Record__c, 'only one asset per Opportunity should have First_Record__c=true');
    }

    @isTest
    public static void tc_AssetTriggerHelper(){
        SL_SCTestData.createAccountAndContracts(1, 1);
        Account theAcc = SL_SCTestData.testAccounts[0];
        SL_SCTestData.createOpportunitiesAndAssets(theAcc.Id, 1, 1);
        Opportunity theOpp = SL_SCTestData.testOpportunities[0];
        Asset__c theAsset = SL_SCTestData.testAssets[0];
        Test.startTest();
        Map<Id, Asset__c> newAssets = new Map<Id, Asset__c>();
        Map<Id, List<String>> fieldsChangedById = new Map<Id, List<String>>();
        Map<Id, Opportunity> opps = new Map<Id, Opportunity>();
        newAssets.put(theAsset.Id, theAsset);
        fieldsChangedById.put(theAsset.Id, new List<String>{'Equipment_Location_City__c'});
        theOpp.StageName = 'Funding';
        opps.put(theOpp.Id, theOpp);
        try{
            TC_AssetTriggerHelper.generateTaxMatrixFormerPB(newAssets, false, fieldsChangedById, opps);
        }catch(Exception e){

        }
        Test.stopTest();
    }
    
    @isTest
    public static void calculateManagerResidual(){
        SL_SCTestData.createAccountAndContracts(1, 1);
        SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[0].Id, 8, 1);
        List<Opportunity> opps = SL_SCTestData.testOpportunities;
        List<Asset__c> assets = SL_SCTestData.testAssets;
        Test.startTest();
        opps[0].Purchase_Options__c = '1.00 Out';
        assets[0].Equipment_Code__c = 'Copiers';
        assets[0].Equipment_Sub_Category__c = 'Copiers';
        assets[0].Residual_Amount__c = 100;
        opps[1].Purchase_Options__c = 'FMV';
        assets[1].Equipment_Code__c = 'Computer Hardware(Gen)';
        assets[1].Equipment_Sub_Category__c = 'Computer Hard/Soft (Gen)';
        assets[1].Residual_Amount__c = 100;
        opps[2].Purchase_Options__c = 'FMV';
        assets[2].Equipment_Code__c = 'Copiers';
        assets[2].Equipment_Sub_Category__c = 'Copiers';
        assets[2].Residual_Amount__c = 100;
        opps[3].Purchase_Options__c = 'FMV';
        assets[3].Equipment_Code__c = 'Commercial Cleaning';
        assets[3].Equipment_Sub_Category__c = 'Commercial Cleaning';
        assets[3].Residual_Amount__c = 100;
        opps[4].Purchase_Options__c = 'FMV';
        assets[4].Equipment_Code__c = 'Playground';
        assets[4].Equipment_Sub_Category__c = 'Playground';
        assets[4].Residual_Amount__c = 100;
        // opps[5].Purchase_Options__c = 'FMV-Used Equipment';
        // assets[5].Equipment_Code__c = 'Playground';
        // assets[5].Equipment_Sub_Category__c = 'LCD Projector';
        // assets[5].Residual_Amount__c = 100;
        // opps[6].Purchase_Options__c = 'FMV Muni No Renewal';
        // assets[6].Equipment_Code__c = 'Playground';
        // assets[6].Equipment_Sub_Category__c = 'Playground';
        // assets[6].Residual_Amount__c = 100;
        opps[7].Purchase_Options__c = 'Guaranteed Residual';
        assets[7].Equipment_Code__c = 'Playground';
        assets[7].Equipment_Sub_Category__c = 'Playground';
        assets[7].Residual_Amount__c = 100;
        update opps;
        update assets;
        Test.stopTest();
        List<Asset__c> assetsAfter = [SELECT Id, Manager_Residual__c FROM Asset__c];
        System.Assert.areEqual(0.00, assetsAfter[0].Manager_Residual__c);
        System.Assert.areEqual(175.00, assetsAfter[1].Manager_Residual__c);
        System.Assert.areEqual(250.00, assetsAfter[2].Manager_Residual__c);
        System.Assert.areEqual(300.00, assetsAfter[3].Manager_Residual__c);
        System.Assert.areEqual(150.00, assetsAfter[4].Manager_Residual__c);
        // System.Assert.areEqual(250.00, assetsAfter[5].Manager_Residual__c);
        // System.Assert.areEqual(100.00, assetsAfter[6].Manager_Residual__c);
        System.Assert.areEqual(100.00, assetsAfter[7].Manager_Residual__c);
    }
}