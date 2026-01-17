/** @author : Northteq Consulting, Inc.
 * @date : 11/10/20
 * @description: Do Not Sync to Marketo Schedulable Test class
 *
 */

@IsTest
public with sharing class TC_DNSMarketoSchedulableTest {

    @IsTest
    static void test() {
        String CRON_EXP = '0 0 0 3 9 ? 2022';
        insert new Marlin_Configuration__c(DNS_Marketo_Timer__c = 30);
        Test.startTest();
        String jobId = System.schedule('TC_DNSMarketoSchedulableTest', CRON_EXP, new TC_DNSMarketoSchedulable());
        Test.stopTest();
    }
}