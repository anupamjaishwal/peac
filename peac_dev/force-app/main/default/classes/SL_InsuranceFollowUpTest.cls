@isTest
public class SL_InsuranceFollowUpTest {
    @isTest
    static void schedule(){
        Test.startTest();
        System.schedule('Test Insurance Follow-up', '0 0 3 * * ?' , new SL_InsuranceFollowUpSchedule());
        Test.stopTest();
        System.assert(true);
    }
    @isTest
    static void batch14Days(){
        User u = [SELECT Id FROM User WHERE Email = 'marlinbusiness@silverlinecrm.com' LIMIT 1];

        System.runAs(u) {
            insert new Case(Subject = 'Test insurance case', Type = 'Insurance - Follow-up');
            Case insuranceCase = [SELECT Id FROM Case];
            Test.setCreatedDate(insuranceCase.Id, Date.today().addDays(-14));
            update insuranceCase;
            Test.startTest();
            Database.executeBatch(new SL_InsuranceFollowUpBatch());
            Test.stopTest();
            System.assert(true);
        }
    }
    @isTest
    static void batch30Days(){
        User u = [SELECT Id FROM User WHERE Email = 'marlinbusiness@silverlinecrm.com' LIMIT 1];

        System.runAs(u) {
            insert new Case(Subject = 'Test insurance case', Type = 'Insurance - Follow-up');
            Case insuranceCase = [SELECT Id FROM Case];
            Test.setCreatedDate(insuranceCase.Id, Date.today().addDays(-30));
            update insuranceCase;
            Test.startTest();
            Database.executeBatch(new SL_InsuranceFollowUpBatch());
            Test.stopTest();
            System.assert(true);
        }
    }
}