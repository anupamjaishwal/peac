@isTest
public with sharing class TC_UpdateEndingPaymentAmountTest {
    @TestSetup
    static void makeData(){
        
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

    }

    @isTest public static void UpdateEndingPaymentAmountTest(){
        List<Opportunity> opp = [SELECT Id, StageName,X_Rate_Factor__c, Equipment_Cost__c,Ready_to_Doc__c  FROM Opportunity];
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>();
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();

        for(Opportunity op : opp){
               Opportunity o = new Opportunity(
               Id = op.Id, 
               StageName = 'Decision',
               of_ending_payments__c = 2,
               Payment_Amount__c = 100
               );
               oldMap.put(op.Id, o);
       }

        for(Opportunity op : opp){
           Opportunity o = new Opportunity(
               Id = op.Id, 
               StageName = 'Decision',
               of_ending_payments__c = 4,
               Payment_Amount__c = 200
               );
           newMap.put(op.Id, o);
       }

       try{
        TC_UpdateEndingPaymentAmount.updateEndingPaymentAmount(oldMap,newMap);
        }
        catch (DmlException e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }
        catch (Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }
    }
    
    @isTest public static void UpdateEndingPaymentAmountTest2(){
        List<Opportunity> opp = [SELECT Id, StageName,X_Rate_Factor__c, Equipment_Cost__c,Ready_to_Doc__c  FROM Opportunity];
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>();
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();

        for(Opportunity op : opp){
               Opportunity o = new Opportunity(
               Id = op.Id, 
               StageName = 'Decision',
               of_ending_payments__c = 2,
               Payment_Amount__c = 100
               );
               oldMap.put(op.Id, o);
       }

        for(Opportunity op : opp){
           Opportunity o = new Opportunity(
               Id = op.Id, 
               StageName = 'Decision',
               of_ending_payments__c = 0,
               Payment_Amount__c = 0
               );
           newMap.put(op.Id, o);
       }

       try{
        TC_UpdateEndingPaymentAmount.updateEndingPaymentAmount(oldMap,newMap);
        }
        catch (DmlException e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }
        catch (Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }
    }
}