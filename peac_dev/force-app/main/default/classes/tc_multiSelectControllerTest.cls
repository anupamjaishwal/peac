@isTest
public class tc_multiSelectControllerTest {
    @isTest public static void getPiklistValuesTest(){
        Test.startTest();
        tc_multiSelectController.getPiklistValues('Account','Equipment_Type__c');
        test.stopTest();
    }
}