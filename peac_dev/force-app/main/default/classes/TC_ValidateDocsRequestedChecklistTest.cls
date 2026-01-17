@isTest 
public with sharing class TC_ValidateDocsRequestedChecklistTest {
    @TestSetup
    static void dataSetup(){
        Account acc = new Account (
            Name = 'test', 
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId()
        );
        insert acc;
        List<Opportunity> oppsToTest = new List<Opportunity>();
        Opportunity opp = new Opportunity(
            AccountId = acc.Id,
            Resubmitted_to_Credit__c = true,
            Credit_Decision__c = false,
            CloseDate = date.today()+100,
            Probability = 80,
            StageName = 'Docs Requested',
            Application_Status__c = 'Cancelled',
            Name = 'test'
        );
        oppsToTest.add(opp);
        Opportunity opp2 = new Opportunity(
            AccountId = acc.Id,
            Resubmitted_to_Credit__c = true,
            Credit_Decision__c = false,
            CloseDate = date.today()+100,
            Probability = 80,
            StageName = 'Docs In',
            Application_Status__c = 'Cancelled',
            Name = 'test',
            Docs_In__c = Date.Today(),
            Ready_to_Doc__c = 'Yes'
        );
        oppsToTest.add(opp2);
        Opportunity opp3 = new Opportunity(
            AccountId = acc.Id,
            Resubmitted_to_Credit__c = true,
            Credit_Decision__c = false,
            CloseDate = date.today()+100,
            Probability = 80,
            StageName = 'Docs In',
            Application_Status__c = 'Cancelled',
            Name = 'test',
            Docs_In__c = Date.Today(),
            Ready_to_Doc__c = 'Yes'
        );
        oppsToTest.add(opp3);
        insert oppsToTest;
        
    }

    @IsTest
    public static void ValidateDocsRequestedChecklistTest(){
 
         Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, StageName FROM Opportunity]);
         Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();
 
         for(Id key : oldMap.keyset()){
             Opportunity o = new Opportunity(
                 Id = key, 
                 StageName = 'Docs In',
                 Docs_In__c = Date.Today(),
                 Ready_to_Doc__c = 'Yes');
             newMap.put(key, o);
         }
 
        Test.startTest();
         try{
 
            TC_ValidateDocsRequestedChecklist.doAction(oldMap, newMap);
         }
         catch (DmlException e) {
             System.debug(e.getMessage());
             System.debug(e.getStackTraceString());
         }
         catch (Exception e) {
             System.debug(e.getMessage());
             System.debug(e.getStackTraceString());
         }
        Test.stopTest();
     }
    @IsTest
    public static void ValidateDocsRequestedChecklistTest2(){
 
         Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, StageName FROM Opportunity]);
         Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();
 
         for(Id key : oldMap.keyset()){
             Opportunity o = new Opportunity(
                 Id = key, 
                 StageName = 'Docs Out',
                 Docs_In__c = Date.Today(),
                 Ready_to_Doc__c = 'Yes');
             newMap.put(key, o);
         }
 
        Test.startTest();
         try{
 
            TC_ValidateDocsRequestedChecklist.doAction(oldMap, newMap);
         }
         catch (DmlException e) {
             System.debug(e.getMessage());
             System.debug(e.getStackTraceString());
         }
         catch (Exception e) {
             System.debug(e.getMessage());
             System.debug(e.getStackTraceString());
         }
        Test.stopTest();
     }
    @IsTest
    public static void ValidateDocsInReviewTest(){
 
         Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, StageName FROM Opportunity]);
         Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();
 
         for(Id key : oldMap.keyset()){
             Opportunity o = new Opportunity(
                 Id = key, 
                 StageName = 'Docs Requested',
                 Docs_In__c = Date.Today(),
                 Ready_to_Doc__c = 'Yes');
             newMap.put(key, o);
         }
 
        Test.startTest();
         try{
 
            TC_ValidateChecklistDocsInReview.doAction(oldMap, newMap);
         }
         catch (DmlException e) {
             System.debug(e.getMessage());
             System.debug(e.getStackTraceString());
         }
         catch (Exception e) {
             System.debug(e.getMessage());
             System.debug(e.getStackTraceString());
         }
        Test.stopTest();
     }
    @IsTest
    public static void ValidateDocsInReviewTest2(){
 
         Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, StageName FROM Opportunity]);
         Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();
 
         for(Id key : oldMap.keyset()){
             Opportunity o = new Opportunity(
                 Id = key, 
                 StageName = 'Docs Out',
                 Docs_In__c = Date.Today(),
                 Ready_to_Doc__c = 'Yes');
             newMap.put(key, o);
         }
 
        Test.startTest();
         try{
 
            TC_ValidateChecklistDocsInReview.doAction(oldMap, newMap);
         }
         catch (DmlException e) {
             System.debug(e.getMessage());
             System.debug(e.getStackTraceString());
         }
         catch (Exception e) {
             System.debug(e.getMessage());
             System.debug(e.getStackTraceString());
         }
        Test.stopTest();
     }
    @IsTest
    public static void ValidateDocsInReviewTest3(){
 
         Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, StageName FROM Opportunity]);
         Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();
 
         for(Id key : oldMap.keyset()){
             Opportunity o = new Opportunity(
                 Id = key, 
                 StageName = 'Booking (Loan)',
                 Docs_In__c = Date.Today(),
                 Ready_to_Doc__c = 'Yes');
             newMap.put(key, o);
         }
 
        Test.startTest();
         try{
 
            TC_ValidateChecklistDocsInReview.doAction(oldMap, newMap);
         }
         catch (DmlException e) {
             System.debug(e.getMessage());
             System.debug(e.getStackTraceString());
         }
         catch (Exception e) {
             System.debug(e.getMessage());
             System.debug(e.getStackTraceString());
         }
        Test.stopTest();
     }

}