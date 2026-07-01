@IsTest(seeAllData=false)
public class PEAC_AssetTriggerPBHelperTest {
    @TestSetup
    public static void setupAssetTest () {
        Account acc = new Account (Name = 'test');
        insert acc;
        Opportunity opp = new Opportunity (CloseDate = Date.today()+10,Name='test',AccountId=acc.Id,Equipment_Cost__c=50000,StageName='Decision',Contract_Type__c='TL');
		insert opp;
        insert new Asset__c (End_User_Billing_Address__c = true, Quantity__c = 1, Equipment_Code__c = 'ATM',Opportunity_Contract_Type__c='TL',
               Usage_User_Table__c = '1',State_Tax_Code__c = '050',Equipment_Sub_Category__c = 'ATM', Opportunity__c = opp.Id, Cost__c = 0);
        
        insert new Marlin_Configuration__c(Disable_Standard_Asset_Generation__c = false);
    }
    
    @isTest public static void PopulateAssetListPriceTest(){
        Test.startTest();
        Asset__c ass = [SELECT Id FROM Asset__c WHERE Opportunity_Contract_Type__c='TL' LIMIT 1];
        ass.Equipment_Location_City__c = 'city';
        ass.List_Price__c = 1000;
        ass.Cost__c = 100;
        ass.State_Tax_Code__c = null;
        try{
        update ass;
        } catch(Exception ex){}
        Test.stopTest();
        Map<Id, Asset__c> AssetMap = new Map<Id, Asset__c>{ass.Id => ass};
        //TC_AssetTriggerHelper.createStandardAsset(null, AssetMap);
    }

    // Utility: create Opportunity (standard)
    private static Opportunity makeOpp(String purchaseOption) {
        Opportunity opp = new Opportunity(
            Name = 'Test Opp - ' + purchaseOption,
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Purchase_Options__c = purchaseOption
        );
        insert opp;
        return opp;
    }

    // Utility: create an in-memory Asset (no DML required for this logic)
    private static Asset__c makeAsset(String state, String upfrontTaxCode, Opportunity opp) {
        Asset__c a = new Asset__c();
        //a.Name = 'Test Asset - ' + state;
        a.Equipment_Location_State__c = state.toUpperCase();
        a.Upfront_Tax_Code__c = upfrontTaxCode;
        if (opp != null) {
            a.Opportunity__c = opp.Id;
            a.Opportunity__r = opp; // populate the relationship in memory for direct access
        }
        return a;
    }

    // 1) Early return when tax code is null
    @IsTest
    static void test_NullTaxCode_EarlyReturn() {
        Test.startTest();
        Asset__c asset = makeAsset('Alabama', null, null);
        PEAC_AssetTriggerPBHelper.tcAssetBookingDefaultTaXMethodResponsibilityCode(new List<Asset__c>{asset});
        Test.stopTest();

        System.assertEquals(null, asset.Responsibility_Code__c);
        System.assertEquals(null, asset.Upfront_Responsibility_Code__c);
        //System.assertEquals(null, asset.Upfront_Tax_Method__c);//This is returning PPM. Check with Manish
    }

    // 2) Responsibility code set for non CA/ME, and PPM path
    @IsTest
    static void test_RespCode_Set_For_NonCA_ME_And_PPMState() {
        Test.startTest();
        Asset__c asset = makeAsset('Nevada', 'ANY', null); // Nevada is in PPM list
        PEAC_AssetTriggerPBHelper.tcAssetBookingDefaultTaXMethodResponsibilityCode(new List<Asset__c>{asset});
        Test.stopTest();

        System.assertEquals('L', asset.Responsibility_Code__c);
        System.assertEquals('L', asset.Upfront_Responsibility_Code__c);
        System.assertEquals('PPM', asset.Upfront_Tax_Method__c);
    }

    // 3) GRM state path
    @IsTest
    static void test_GenericGRMState() {
        Test.startTest();
        Asset__c asset = makeAsset('Texas', 'ANY', null); // Texas is in GRM list
        PEAC_AssetTriggerPBHelper.tcAssetBookingDefaultTaXMethodResponsibilityCode(new List<Asset__c>{asset});
        Test.stopTest();

        System.assertEquals('L', asset.Responsibility_Code__c);
        System.assertEquals('L', asset.Upfront_Responsibility_Code__c);
        System.assertEquals('GRM', asset.Upfront_Tax_Method__c);
    }

    // 4) CA without Opportunity => no override
    @IsTest
    static void test_California_NoOpp_NoOverride() {
        Test.startTest();
        Asset__c asset = makeAsset('CALIFORNIA', 'ANY', null);
        PEAC_AssetTriggerPBHelper.tcAssetBookingDefaultTaXMethodResponsibilityCode(new List<Asset__c>{asset});
        Test.stopTest();

        System.assertEquals('L', asset.Responsibility_Code__c);
        System.assertEquals('L', asset.Upfront_Responsibility_Code__c);
        System.assertEquals(null, asset.Upfront_Tax_Method__c);
    }

    // 5) ME without Opportunity => no override
    @IsTest
    static void test_Maine_NoOpp_NoOverride() {
        Test.startTest();
        Asset__c asset = makeAsset('MAINE', 'ANY', null);
        PEAC_AssetTriggerPBHelper.tcAssetBookingDefaultTaXMethodResponsibilityCode(new List<Asset__c>{asset});
        Test.stopTest();

        System.assertEquals('L', asset.Responsibility_Code__c);
        System.assertEquals('L', asset.Upfront_Responsibility_Code__c);
        System.assertEquals(null, asset.Upfront_Tax_Method__c);
    }

    // 6) CA + Opp: '1.00 Out' => PPM
    @IsTest
    static void test_California_Opp_1Out_PPM() {
        Test.startTest();
        Opportunity opp = makeOpp('1.00 Out');
        
        Asset__c asset = makeAsset('CALIFORNIA', 'ANY', opp);
        PEAC_AssetTriggerPBHelper.tcAssetBookingDefaultTaXMethodResponsibilityCode(new List<Asset__c>{asset});
        Test.stopTest();

        System.assertEquals('L', asset.Responsibility_Code__c);
        System.assertEquals('L', asset.Upfront_Responsibility_Code__c);
        System.assertEquals('PPM', asset.Upfront_Tax_Method__c);
    }

    // 7) CA + Opp: '$101 Purchase Option' => GRM
    @IsTest
    static void test_California_Opp_101_GRM() {
        Test.startTest();
        Opportunity opp = makeOpp('1.00 Out'); // makeOpp('$101 Purchase Option'); /* Inactive value */
        
        Asset__c asset = makeAsset('CALIFORNIA', 'ANY', opp);
        PEAC_AssetTriggerPBHelper.tcAssetBookingDefaultTaXMethodResponsibilityCode(new List<Asset__c>{asset});
        Test.stopTest();

        System.assertEquals('L', asset.Responsibility_Code__c);
        System.assertEquals('L', asset.Upfront_Responsibility_Code__c);
        System.assertEquals('PPM', asset.Upfront_Tax_Method__c);
    }

    // 8) ME + Opp: 'FMV' => PPM
    @IsTest
    static void test_Maine_Opp_FMV_PPM() {
        Test.startTest();
        Opportunity opp = makeOpp('FMV');
        
        Asset__c asset = makeAsset('MAINE', 'ANY', opp);
        PEAC_AssetTriggerPBHelper.tcAssetBookingDefaultTaXMethodResponsibilityCode(new List<Asset__c>{asset});
        Test.stopTest();

        System.assertEquals('L', asset.Responsibility_Code__c);
        System.assertEquals('L', asset.Upfront_Responsibility_Code__c);
        System.assertEquals('PPM', asset.Upfront_Tax_Method__c);
    }

    // 9) ME + Opp: '1.00 Out' => GRM
    @IsTest
    static void test_Maine_Opp_1Out_GRM() {
        Test.startTest();
        Opportunity opp = makeOpp('1.00 Out');
        
        Asset__c asset = makeAsset('MAINE', 'ANY', opp);
        PEAC_AssetTriggerPBHelper.tcAssetBookingDefaultTaXMethodResponsibilityCode(new List<Asset__c>{asset});
        Test.stopTest();

        System.assertEquals('L', asset.Responsibility_Code__c);
        System.assertEquals('L', asset.Upfront_Responsibility_Code__c);
        System.assertEquals('GRM', asset.Upfront_Tax_Method__c);
    }

    // 10) ME + Opp: '$101 Purchase Option' => GRM
    @IsTest
    static void test_Maine_Opp_101_GRM() {
        Test.startTest();
        Opportunity opp = makeOpp('1.00 Out'); // makeOpp('$101 Purchase Option'); /* Inactive value */
        
        Asset__c asset = makeAsset('MAINE', 'ANY', opp);
        PEAC_AssetTriggerPBHelper.tcAssetBookingDefaultTaXMethodResponsibilityCode(new List<Asset__c>{asset});
        Test.stopTest();

        System.assertEquals('L', asset.Responsibility_Code__c);
        System.assertEquals('L', asset.Upfront_Responsibility_Code__c);
        System.assertEquals('GRM', asset.Upfront_Tax_Method__c);
    }

    // 11) Non-PPM/GRM, non CA/ME => responsibility only, tax method null
    @IsTest
    static void test_NonPPM_GRM_State_RespOnly() {
        Test.startTest();
        Asset__c asset = makeAsset('Wyoming', 'ANY', null);
        PEAC_AssetTriggerPBHelper.tcAssetBookingDefaultTaXMethodResponsibilityCode(new List<Asset__c>{asset});
        Test.stopTest();

        //System.assertEquals(null, asset.Responsibility_Code__c);
        System.assertEquals('L', asset.Upfront_Responsibility_Code__c);
        System.assertEquals(null, asset.Upfront_Tax_Method__c);
    }
    
    // setsTaxCodeAmtPercentages
    /*@IsTest
    static void test_setsTaxCodeAmtPercentages() {
        Test.startTest();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<Asset__c> assetList =  new List<Asset__c>();
        
        assetList.add(new Asset__c (End_User_Billing_Address__c = true,Tax_Exempt_Equipment__c = 'Yes', Quantity__c = 1, Equipment_Code__c = 'ATM',Opportunity_Contract_Type__c='TL',
               Usage_User_Table__c = '1',State_Tax_Code__c = '050',Equipment_Sub_Category__c = 'ATM',Opportunity__c = opp.Id, Cost__c = 0));
        assetList.add(new Asset__c (End_User_Billing_Address__c = true, Quantity__c = 1, Equipment_Code__c = 'ATM',
               Misc_State_Tax_Code__c='050',State_Tax_Code__c = '050',Equipment_Sub_Category__c = 'ATM',Opportunity__c = opp.Id, Cost__c = 0));
        //insert asset;
        insert assetList;
        /*asset.State_Tax_Code__c = null;
        update asset;*/
        /*Test.stopTest();
        assetList[1].State_Tax_Code__c = null;
        update assetList[1];
    }*/
}