@isTest
public with sharing class TC_GenerateTrustLinkTest {
    @TestSetup
    static void makeData(){
        ORE__c o = new ORE__c(Bypass__c = true);
        insert o;
        
        Account acc = new Account();
        acc.Name = 'Test';
        acc.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'End User Account'][0].Id;
        insert acc;

        Contact c = new Contact();
        c.FirstName = 'Test';
        c.LastName = 'Contact';
        c.Email = 'testing543@test.com';
        c.AccountId = acc.Id;
        c.Phone = '1234567890';
        insert c;

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

        OpportunityContactRole cr = new OpportunityContactRole();
        cr.OpportunityId = opp.Id;
        cr.ContactId = c.Id;
        cr.IsPrimary = true;
        insert cr;

        insert new Trust_Pilot_App__c(API_Key__c = 'test', Secret__c = 'test', Business_Id__c = 'test', Invitation_URL__c = 'TrustPilot2Resp', Password__c = 'tes', Token_URL__c = 'TrustPilot1Resp', Username__c = 'test');
    }

    
    @isTest public static void GenerateTrustLinkTest(){
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, RecordTypeId, StageName, Loan_Record_Type__c, PK__c, CaseCenter__c FROM Opportunity]);
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>([SELECT Id, Equipment_Cost__c, Opportunity_Funding_Type__c, PUT_Amount__c, Beginning_Maintenance_Fee_Amount__c, Sales_Leaseback__c, Escalation_Rate__c,Num_Pass_Thru_Fees__c,First_12_Months_Free__c,RecordTypeId, StageName, Loan_Record_Type__c, PK__c, CaseCenter__c FROM Opportunity]);


        for(Id key : newMap.keyset()){
        newMap.get(key).StageName = 'Docs In';
    }

    try{
        TC_GenerateTrustLink.generateTrustLink(newMap,oldMap);
    }catch(Exception e){
        System.debug(e.getMessage());
    }
}
}