@isTest
public with sharing class TC_ResubmissionToCDHandlerTest {
    @TestSetup
    static void setup(){
        
        Account acc = new Account();
        acc.Name = 'test';
        acc.Business_Phone__c = '1111111111';
        acc.RecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
        acc.Business_Address__c = '123 Street Ave N';
        acc.Business_City__c = 'Minneapolis';
        acc.Business_State__c = 'MN';
        acc.Business_Zip__c = '55401';
        insert acc;

        Opportunity opp = new Opportunity();
        opp.Name = 'test';
        opp.CloseDate = System.today();
        opp.StageName = 'Decision';
        opp.Opportunity_Status__c = 'Credit - In Queue';
        opp.AccountId = acc.Id;
        opp.Equipment_Cost__c = 12345;
        opp.Equipment_Description__c = 'test';
        opp.Terms__c = 60;
        opp.Credit_Decision__c = false;
        opp.Approved_Amount__c = 100;
        Test.startTest();
        insert opp;
        Test.stopTest();

        Resubmission_to_Credit_Details__c rcd = new Resubmission_to_Credit_Details__c();
        rcd.Opportunity__c = opp.Id;
        rcd.Appeal_Type__c = '1st';
        insert rcd;
        
        Resubmission_to_Credit_Details__c rcd1 = new Resubmission_to_Credit_Details__c();
        rcd1.Opportunity__c = opp.Id;
        rcd1.Appeal_Type__c = '2nd';
        insert rcd1;
    }

    @IsTest
    static void doActionTest() {
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, Approved_Amount__c, Credit_Decision__c, Deferral_Payments__c, Variable_Payment__c, Probability, RecordTypeId, StageName, Loan_Record_Type__c, PK__c, CaseCenter__c FROM Opportunity]);
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>([SELECT Id, Approved_Amount__c, Credit_Decision__c, Deferral_Payments__c, Loan_Record_Type__c, Probability, First_12_Months_Free__c, Beginning_Maintenance_Fee_Amount__c, 
                                                                Equipment_Cost__c, Opportunity_Funding_Type__c,Variable_Payment__c,
                                                                RecordTypeId, StageName
                                                                FROM Opportunity]);

        for(Id key : oldMap.keyset()){
            Opportunity o = new Opportunity(
                Id = key, 
                Deferral_Payments__c = '60 days',
                Credit_Decision__c = true,
                StageName = 'Booking'
                );
            newMap.put(key, o);
        }

        try{
            TC_ResubmissionToCreditDetailsHandler.doAction(oldMap,newMap );
        }
        catch(exception e){

        }
    }

    @IsTest
    static void creditDecisionChangedToTrueTest() {
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, StageName, Deferral_Payments__c, Deferral_Periods__c, EF_Approved_Offers__c, Required_Adv_Payments__c, Loan_Record_Type__c FROM Opportunity]);
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();

        for(Id key : oldMap.keyset()){
            Opportunity o = new Opportunity(
                Id = key, 
                Deferral_Payments__c = '60 days',
                StageName = 'Booking',
                Credit_Decision__c = true
                );
            newMap.put(key, o);
        }

        try{
            //TC_ResubmissionToCreditDetailsHandler.creditDecisionChangedToTrue(oldMap,newMap );
        }
        catch(exception e){
            
        }
    }

    @IsTest
    static void getMostRecentResubmissionToCreditDetailsTest() {
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, StageName, Deferral_Payments__c, Deferral_Periods__c, EF_Approved_Offers__c, Required_Adv_Payments__c, Loan_Record_Type__c FROM Opportunity]);

        try{
            TC_ResubmissionToCreditDetailsHandler.getMostRecentResubmissionToCreditDetails(oldMap);
        }
        catch(exception e){
            
        }
    }

    @IsTest
    static void updateResubmissionToCreditDetailsTest() {
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, StageName, Deferral_Payments__c, Deferral_Periods__c, EF_Approved_Offers__c, Required_Adv_Payments__c, Loan_Record_Type__c FROM Opportunity]);
        Map<Id, Resubmission_to_Credit_Details__c>resubmissionsMap = new Map<Id, Resubmission_to_Credit_Details__c>([SELECT Id, Appeal_Type__c FROM Resubmission_to_Credit_Details__c WHERE Opportunity__c != null]);

        try{
            TC_ResubmissionToCreditDetailsHandler.updateResubmissionToCreditDetails(oldMap,resubmissionsMap );
        }
        catch(exception e){
            
        }
    }
}