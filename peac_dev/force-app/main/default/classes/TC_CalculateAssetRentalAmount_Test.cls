@isTest
public with sharing class TC_CalculateAssetRentalAmount_Test {
    @TestSetup
    static void makeData(){
        ORE__c o = new ORE__c(Bypass__c = true);
        insert o;
        
        Account acc = new Account();
        acc.Name = 'Test';
        acc.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'End User Account'][0].Id;
        insert acc;

        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = acc.Id;
        opp.StageName = 'Decision';
        opp.CloseDate = Date.today().addDays(7);
        opp.Primary_Source__c = 'Customer Inbound - Call';
        opp.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Express Decision'][0].Id;
        opp.of_Payments__c = 24;
        opp.Terms__c = 60;
        opp.Payment_Frequency__c = 'Monthly';
        opp.Equipment_Description__c = 'test description';
        opp.FraudReviewFlag__c = 1;
        opp.Payment_Amount__c = 100;
        
        Test.startTest();
        insert opp;
        Test.stopTest();

        Asset__c asset = new Asset__c (Opportunity__c = opp.Id, Cost__c = 100, List_Price__c = 10);
        insert asset;
    }

    @isTest public static void CalculateAssetRentalAmtTest(){
        List<Asset__c> assets = [SELECT Id, Opportunity__c,Cost__c, List_Price__c  FROM Asset__c];
        Map<Id, Asset__c> oldMap = new Map<Id, Asset__c>();
       List<Asset__c> newList = new List<Asset__c>();
       try{
        TC_CalculateAssetRentalAmount.calculateAssetRentalAmount(null, assets);
        }
        catch (Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }
    }

    @isTest public static void CalculateAssetRentalAmtTest2(){
        List<Asset__c> assets = [SELECT Id, Opportunity__c,Cost__c, List_Price__c  FROM Asset__c];
        Map<Id, Asset__c> oldMap = new Map<Id, Asset__c>();
       List<Asset__c> newList = new List<Asset__c>();

    //     for(Asset__c a : assets){
    //         Asset__c o = new Asset__c(
    //            Id = a.Id, 
    //            Opportunity__c =a.Opportunity__c,
    //            Cost__c = a.Cost__c,
    //            List_Price__c =30
    //            );
    //            newList.add(o);
    //    }

       try{
        TC_CalculateAssetRentalAmount.calculateAssetRentalAmount(oldMap, newList);
        }
        catch (Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }
    }
    
    @isTest public static void CalculateAssetRentalAmtTest3(){
        List<Asset__c> assets = [SELECT Id, Opportunity__c,Cost__c, List_Price__c  FROM Asset__c];
        Map<Id, Asset__c> oldMap = new Map<Id, Asset__c>();
       List<Asset__c> newList = new List<Asset__c>();

         for(Asset__c a : assets){
             Asset__c o = new Asset__c(
                Id = a.Id,
                Cost__c = a.Cost__c,
                List_Price__c =30
                );
                newList.add(o);
        }

       try{
        TC_CalculateAssetRentalAmount.calculateAssetRentalAmount(oldMap, newList);
        }
        catch (Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }
    }

}