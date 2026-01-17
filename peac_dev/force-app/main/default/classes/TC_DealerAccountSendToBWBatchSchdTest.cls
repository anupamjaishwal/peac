@isTest public class TC_DealerAccountSendToBWBatchSchdTest {
    private static String CRON_EXP = '0 5 0 * * ? ';
    @isTest public static void runTest () {
        insert new Account (Name = 'test', Waiting_To_Be_Sent_To_Bridgeware__c = true);
        
        Test.startTest ();
        CRON_EXP +=String.valueOf(Date.today().year() + 1);
        TC_DealerAccountSendToBWBatchSchd s = new TC_DealerAccountSendToBWBatchSchd();
        System.schedule('Job Started at ' + String.valueOf(Datetime.now()), CRON_EXP, s);
        
        Test.stopTest ();
        
    }
}