@isTest
public with sharing class TC_CheckAssetFieldsWhenBookingStageTest {
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
        
        Test.startTest();
        insert opp;
        Test.stopTest();

        Asset__c asset = new Asset__c (Opportunity__c = opp.Id, Cost__c = 100);
        insert asset;

    }

    @isTest public static void CalculateAssetCostTest(){
        List<Opportunity> opp = [SELECT Id, StageName,X_Rate_Factor__c, Equipment_Cost__c,Ready_to_Doc__c  FROM Opportunity];
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>();
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();

        for(Opportunity op : opp){
               Opportunity o = new Opportunity(
               Id = op.Id, 
               StageName = 'Decision',
               Probability = 60
               );
               oldMap.put(op.Id, o);
       }

        for(Opportunity op : opp){
           Opportunity o = new Opportunity(
               Id = op.Id, 
               StageName = 'Booking',
               Probability = 90
               );
           newMap.put(op.Id, o);
       }

       try{
        TC_CheckAssetFieldsWhenBookingStage.checkAssetFieldsWhenBookingStage(oldMap,newMap);
        }
        catch (Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }
    }


}