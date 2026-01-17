@istest
public with sharing class TC_CreateUpdateVariablePaymentRecordTest {
    @TestSetup
    static void dataSetup(){
        Account acc = new Account (
            Name = 'test', 
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId()
        );
        insert acc;

        Opportunity opp1 = new Opportunity(
            AccountId = acc.Id,
            Resubmitted_to_Credit__c = true,
            Credit_Decision__c = false,
            CloseDate = date.today()+100,
            Probability = 80,
            Deferral_Payments__c = '30 days',
            StageName = 'test',
            Name = 'test'
        );
        insert opp1;
    

    }

    
    @IsTest
    public static void CreateUpdateVariablePaymentRecordTest(){

        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id,Deferral_Payments__c, Deferral_Periods__c, Probability, Required_Adv_Payments__c, Loan_Record_Type__c FROM Opportunity]);
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();

        for(Id key : oldMap.keyset()){
            Opportunity o = new Opportunity(
                Id = key, 
                Deferral_Payments__c = '60 days',
                Probability = 80
                );
            newMap.put(key, o);
        }
        try{
            Opportunity opp = newMap.values()[0];
            Map<Id, List<Variable_Payment__c>> variablePayments = new Map<Id, List<Variable_Payment__c>>();
            List<String> fieldsChanged = new List<String>{'Deferral_Payments__c'};
            List<Variable_Payment__c> lstVariablePayments = new List<Variable_Payment__c>();
            TC_CreateUpdateVariablePaymentRecord.createUpdateVariablePaymentRecord(opp, variablePayments, fieldsChanged, lstVariablePayments);
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