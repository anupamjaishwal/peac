@isTest public class TC_DealerSuvAutoDeactivateBatchSchdTest {
	private static String CRON_EXP = '0 5 0 * * ? 2023';
    @isTest public static void test () {
        Account acc = new Account (Name = 'tet'
                                   , RecordTypeId =Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId()
                                   , Account_Dealer_Status__c = TC_DealerSuvAutoDeactivateBatch.ACTIVE
                                   , Account_Dealer_Last_App__c = Date.today().addDays (-366));
        insert acc;
        insert new Dealer_Surveillance__c (Account__C = acc.Id
                                          , Status__c = TC_DealerSuvAutoDeactivateBatch.IN_PROCESS);
        Test.startTest();
        TC_DealerSuvAutoDeactivateBatchSchd s = new TC_DealerSuvAutoDeactivateBatchSchd();
	    System.schedule('Job Started at ' + String.valueOf(Datetime.now()), CRON_EXP, s);
        Test.stopTest();
    }
}