@isTest
public with sharing class TC_OppDeferralChangedURFTest {
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
        
        Test.startTest();
        insert opp;
        Test.stopTest();
    }

    @isTest public static void OppDeferralChangedURFTest(){
        List<Opportunity> opp = [SELECT Id, StageName,X_Rate_Factor__c, Equipment_Cost__c,Ready_to_Doc__c  FROM Opportunity];
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>();
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();

        for(Opportunity op : opp){
               Opportunity o = new Opportunity(
               Id = op.Id, 
               StageName = 'Decision',
               Deferral_Payments__c = '30 days'
               );
               oldMap.put(op.Id, o);
       }

        for(Opportunity op : opp){
           Opportunity o = new Opportunity(
               Id = op.Id, 
               StageName = 'Booking',
               Deferral_Payments__c = '60 days'
               );
           newMap.put(op.Id, o);
       }

       try{
        TC_OppDeferralChangedUpdateRateFactor.doAction(oldMap,newMap);
        }
        catch (Exception e) {
            System.debug(e.getMessage());
        }
    }
}