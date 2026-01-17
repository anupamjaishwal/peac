@isTest
public class SL_EscalateCaseActionTest {
    @isTest
    static void getQueueId_success() {
        test.startTest();
        String queueId = SL_EscalateCaseAction.getQueueId();
        test.stopTest();
        System.assert(String.isNotBlank(queueId));
    }
}