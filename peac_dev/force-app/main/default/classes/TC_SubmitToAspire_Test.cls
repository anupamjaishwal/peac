@isTest
public with sharing class TC_SubmitToAspire_Test {
        @TestSetup
        static void dataSetup(){
            Account acc = new Account (
            Name = 'test', 
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId()
            );
            insert acc;
    
            Opportunity opp = new Opportunity(
                AccountId = acc.Id,
                StageName = 'Proposal',
                CloseDate = date.today () + 10,
                Auto_Submit_to_Aspire__c = true,
                Name = 'test'
            );
            insert opp;
        }
        @IsTest
        public static void SubmitToAspire_Test(){
     
            Opportunity opp = [SELECT Id,Auto_Submit_to_Aspire__c FROM Opportunity];
            try{
            TC_SubmitToAspire.submitToAspire(new List<Opportunity>{opp});
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