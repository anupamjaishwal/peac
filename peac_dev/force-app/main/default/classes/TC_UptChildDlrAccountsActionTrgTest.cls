@IsTest
public with sharing class TC_UptChildDlrAccountsActionTrgTest {
    @IsTest
    static void testTrigger(){
        TC_Update_Child_Dealer_Accounts__e e = new TC_Update_Child_Dealer_Accounts__e();
    
        test.startTest();
        Eventbus.publish(e);
        test.stopTest();
    }
}