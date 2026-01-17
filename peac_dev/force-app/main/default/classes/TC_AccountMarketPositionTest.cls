@IsTest
public class TC_AccountMarketPositionTest {

    private static String CRON_EXP = '0 5 0 * * ? 2023';

    @testSetup public static void setupDeal () {

        Account acc = new Account (Name = 'testMarketPositionDateAccount', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId(),
                                  Market_Position__c = 'In Market');
        insert acc;
        acc.Market_Position_Last_Populated_Date__c = Date.today().addDays(-90);
        update acc;
      
    }
    @isTest public static void marketPositionUpdateTest () {

        Test.startTest();
        System.schedule('Job Started at ' + String.valueOf(Datetime.now()), CRON_EXP, new TC_AccountMarketPositionSchd ());
        Test.stopTest();

    }

}