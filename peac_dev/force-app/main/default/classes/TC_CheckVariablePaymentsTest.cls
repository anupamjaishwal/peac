@isTest
public with sharing class TC_CheckVariablePaymentsTest {
    @TestSetup
    static void makeData(){
        ORE__c o = new ORE__c(Bypass__c = false);
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
        opp.Probability = 96;
        opp.Tax_ID__c ='123123123';
        opp.Variable_Payment__c = false;
        opp.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Express Decision'][0].Id;
        
        Test.startTest();
        insert opp;
        Test.stopTest();

        Variable_Payment__c vp = new Variable_Payment__c(Opportunity__c = opp.Id, Payment_Amount__c = 100, of_payments__c = 2);
        insert vp;
    }

    @IsTest
    public static void CheckVariablePaymentsTest(){
        
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, Variable_Payment__c, Probability, RecordTypeId, StageName, Loan_Record_Type__c, PK__c, CaseCenter__c FROM Opportunity]);
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>([SELECT Id, Loan_Record_Type__c, Probability, First_12_Months_Free__c, Beginning_Maintenance_Fee_Amount__c, 
                                                                Equipment_Cost__c, Opportunity_Funding_Type__c,Variable_Payment__c,
                                                                RecordTypeId, StageName
                                                                FROM Opportunity]);


        for(Id key : newMap.keyset()){
        	newMap.get(key).StageName = 'Booking';
            newMap.get(key).Docs_In__c = Date.Today();
            newMap.get(key).Ready_to_Doc__c = 'Yes';
            newMap.get(key).Variable_Payment__c = false;
            newMap.get(key).Probability = 96;
            oldMap.get(key).StageName = 'Funding';
            oldMap.get(key).Docs_In__c = Date.Today(); 
            oldMap.get(key).Ready_to_Doc__c = 'Yes';
    	}
        try{
            TC_CheckVariablePayments.checkVariablePayments(oldMap, newMap);
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