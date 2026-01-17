@isTest
public with sharing class TC_CalculateDocFeeTest {
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
        opp.Ready_to_Doc__c = 'No';
        opp.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Express Decision'][0].Id;
        
        Test.startTest();
        insert opp;
        Test.stopTest();
    }

    @isTest public static void CalculateDocFeeTest(){
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, Doc_Fee_Exception_Amount__c, Ready_to_Doc__c, RecordTypeId, StageName, Loan_Record_Type__c, PK__c, CaseCenter__c FROM Opportunity]);
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>([SELECT Id, Doc_Fee_Exception_Amount__c, Channel__c, Ready_to_Doc__c ,RecordTypeId, StageName, Loan_Record_Type__c, PK__c, CaseCenter__c FROM Opportunity]);


        for(Id key : oldMap.keyset()){
            oldMap.get(key).Ready_to_Doc__c = 'No';
            oldMap.get(key).StageName = 'Decision';
        }
    
        for(Id key : newMap.keyset()){
            newMap.get(key).Ready_to_Doc__c = 'Yes';
            newMap.get(key).StageName = 'Proposal';
        }
		system.debug('OMAP: '+oldMap);
        system.debug('NMAP: '+newMap);
        try{
            TC_CalculateDocFee.calculateDocFee(oldMap,newMap);
        }catch(Exception e){
            System.debug(e.getMessage());
        }
    }
    @isTest public static void CalculateDocFeeTest2(){
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, Ready_to_Doc__c, RecordTypeId, StageName, Loan_Record_Type__c, PK__c, CaseCenter__c FROM Opportunity]);
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>([SELECT Id,Doc_Fee_Exception_Amount__c,Documentation_Fee__c,Channel__c, Ready_to_Doc__c ,RecordTypeId, StageName, Loan_Record_Type__c, PK__c, CaseCenter__c FROM Opportunity]);


        for(Id key : oldMap.keyset()){
            oldMap.get(key).Ready_to_Doc__c = 'No';
        }
    
        for(Id key : newMap.keyset()){
        newMap.get(key).Ready_to_Doc__c = 'Yes';
        newMap.get(key).StageName = 'Proposal';
        newMap.get(key).Doc_Fee_Exception_Amount__c = 100;
        newMap.get(key).Documentation_Fee__c = 11;
        }

        try{
            TC_CalculateDocFee.calculateDocFee(oldMap,newMap);
        }catch(Exception e){
            System.debug(e.getMessage());
        }
    }
}