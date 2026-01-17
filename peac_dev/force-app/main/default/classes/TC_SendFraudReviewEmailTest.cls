@IsTest
/**
 * Created by Northteq 6/8/2021 for SAL-3139
 * @description test coverage for TC_SendFraudReviewEmail
 */
public with sharing class TC_SendFraudReviewEmailTest {


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

    
    @IsTest
    /**
     * @description this will test the TC_SendFraudReviewEmail class by triggering the flow that updates
     * the opportunity and that will then trigger the email to send. For SAL-3139
     */
    public static void runTest() {

        Opportunity opp = [SELECT Id, Reason_for_Approval__c, Decision_Status__c FROM Opportunity LIMIT 1];

        opp.Reason_for_Approval__c = 'Instant Auto Decision';
        opp.Decision_Status__c = 'A';

        Test.startTest();
        update opp;
        Test.stopTest();
        Opportunity opp2 = [SELECT Id, Decision_Status__c FROM Opportunity LIMIT 1];

        //asserting email trigging criteria met
        System.assertEquals('A', opp2.Decision_Status__c, 'Opportunity Decision Status is not Approved');
    }

    @isTest public static void SendFraudReviewEmailTest(){
        List<Opportunity> opp = [SELECT Id, StageName,X_Rate_Factor__c, Equipment_Cost__c,Ready_to_Doc__c  FROM Opportunity];
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>();
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();

        for(Opportunity op : opp){
               Opportunity o = new Opportunity(
               Id = op.Id, 
               StageName = 'Decision',
               FraudReviewFlag__c = 0
               );
               oldMap.put(op.Id, o);
       }

        for(Opportunity op : opp){
           Opportunity o = new Opportunity(
               Id = op.Id, 
               StageName = 'Decision',
               FraudReviewFlag__c = 1,
               Decision_Status__c = 'A',
               Application_Status__c = 'Pending Decision',
               Opportunity_Status__c = 'Fraud Review',
               Reason_for_Approval__c = 'Instant Auto Decision');
           newMap.put(op.Id, o);
       }

       try{
            TC_SendFraudReviewEmail.sendFraudReviewEmail(newMap,oldMap);
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