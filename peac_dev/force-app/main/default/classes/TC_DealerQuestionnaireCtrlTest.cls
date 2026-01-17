@isTest public class TC_DealerQuestionnaireCtrlTest {
    
    @testSetup
    public static void setupTest () {
        insert new Account (Name = 'test');
    }
    
    @isTest
    public static void dealerQuestionnaireTest () {
        TC_DealerQuestionnaireCtrl.questionnaireInit ([SELECT Name FROM Account WHERE Name = 'test'][0].Id);
    }

}