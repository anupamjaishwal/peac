@isTest public class TC_DealerSurvModelBackfillBatchTest {
    @isTest public static void test () {
        Account acc = new Account (X1_app_in_the_last_12_months__c = 1
                                   , Net_Investment__c = 2
                                   , Actual_Vs_Projected_Loss__c = 1
                                   , Account_Total_Past_Due_Percentage__c = 1
                                   , Name = 'test');
        insert acc;
        
        insert new Dealer_Surveillance__c (Status__c = 'In Process', Account__c = acc.Id);
        insert new Dealer_Surveillance_Model__c (Actual_Vs_Project_Max__c = 3
                                                , Delinquency_Max__c = 3
                                                , Net_Investment_Maximum__c = 999999999
                                                , Net_Investment_Minimum__c = 0
                                                , Name = 'test');
		Test.startTest();
        Database.executeBatch(new TC_DealerSurveillanceModelBackfillBatch(), 1);
        Test.stopTest();
    }
}