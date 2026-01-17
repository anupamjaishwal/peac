@isTest
public with sharing class TC_AddPointsReviewForBookingTest {
    @TestSetup
    static void dataSetup(){
        Account acc = new Account (
            Name = 'test', 
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId()
        );
        insert acc;

        Opportunity opp = new Opportunity(
            AccountId = acc.Id,
            Resubmitted_to_Credit__c = true,
            Credit_Decision__c = false,
            CloseDate = date.today()+100,
            Probability = 80,
            StageName = 'test',
            Loan_Purpose__c = 'Expansion/Hiring',
            Primary_Source__c = 'Indirect',
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan Opportunity').getRecordTypeId(),
            Name = 'test'
        );
        insert opp;
    }

    @isTest
    public static void runTest(){

        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, StageName, Loan_Record_Type__c, PK__c, CaseCenter__c FROM Opportunity]);
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>([SELECT Id, StageName, Loan_Record_Type__c, PK__c, CaseCenter__c FROM Opportunity]);


        for(Id key : newMap.keyset()){
           newMap.get(key).Renewal_Payoff_Amount__c = 100;
           newMap.get(key).StageName = 'Review for Booking';
        //    newMap.get(key).Loan_Amount__c = 50000;
        //    newMap.get(key).Max_Fees__c = 10;
       }

       try{
        TC_AddPointsReviewForBooking.addPointsReviewForBooking(oldMap, newMap);
       }catch(Exception e){
           System.debug(e);
       }
    }


    @IsTest
    public static void addPointsReviewForBookingTest(){
        List<Opportunity> opp = [SELECT Id, StageName FROM Opportunity];
         Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>();
         Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();
 
         for(Opportunity op : opp){
                Opportunity o = new Opportunity(
                Id = op.Id, 
                StageName = 'Funding',
                Docs_In__c = Date.Today(),
                Ready_to_Doc__c = 'Yes');
                oldMap.put(op.Id, o);
        }

         for(Opportunity op : opp){
            Opportunity o = new Opportunity(
                Id = op.Id, 
                StageName = 'Review for Booking',
                Renewal_Payoff_Amount__c = 100);
            newMap.put(op.Id, o);
        }

        try{
            TC_AddPointsReviewForBooking.addPointsReviewForBooking(oldMap, newMap);
            }
            catch (DmlException e) {
             
            }
            catch (Exception e) {
               
            }
    }
}