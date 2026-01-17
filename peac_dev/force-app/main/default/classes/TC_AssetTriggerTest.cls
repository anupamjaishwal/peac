@isTest 
public class TC_AssetTriggerTest {
    @TestSetup
    public static void setupAssetTest () {
        Account acc = new Account (Name = 'test');
        insert acc;
        Opportunity opp = new Opportunity (
            CloseDate = Date.today() + 10, Name = 'test', AccountId = acc.Id, Equipment_Cost__c = 50000,
            StageName = 'Decision'
        );
        insert opp;
        insert new Asset__c (
                End_User_Billing_Address__c = true, Quantity__c = 1, Equipment_Code__c = 'ATM', 
            Equipment_Sub_Category__c = 'ATM',
            Opportunity__c = opp.Id, Cost__c = 0
        );
        Marlin_Configuration__c mc = new Marlin_Configuration__c(Disable_Standard_Asset_Generation__c = false);
        insert mc;
       
    }
    @isTest public static void PopulateAssetListPriceTest(){
        Asset__c ass = [SELECT Id FROM Asset__c LIMIT 1];
        ass.Equipment_Location_City__c = 'city';
        ass.List_Price__c = 1000;
        ass.Cost__c = 100;
        try{
        update ass;
        } catch(Exception ex){}
        Map<Id, Asset__c> AssetMap = new Map<Id, Asset__c>{ass.Id => ass};
        TC_AssetTriggerHelper.createStandardAsset(null, AssetMap);
    }
}