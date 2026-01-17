/** @author : Northteq Consulting, Inc.
 * @date : 2/5/21
 * @description: Test class for TC_NotificationEmailBatch
 *
 */

@IsTest
public with sharing class TC_NotificationEmailBatchTest {

    /**
     * Create a dummy end user account and opportunity
     */
    // SAL-5496 Misael Romero
    // @TestSetup
    // static void setup() {

    //     Account acc = new Account();
    //     acc.Name = 'Test';
    //     acc.Business_Phone__c = '1234567890';
    //     acc.RecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
    //     insert acc;

    //     Test.startTest();
    //     Opportunity opp = new Opportunity();
    //     opp.Name = 'Test';
    //     opp.StageName = 'Quote';
    //     opp.CloseDate = Date.today();
    //     opp.AccountId = acc.Id;
    //     insert opp;
    //     Test.stopTest();
    // }

    /**
     * Test scheduling the submitted notification
     */
    @IsTest
    static void testSubmitted() {
// SAL-5496 Misael Romero
        SL_SCTestData.createAccountAndContracts(1, 1);
        SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[0].Id, 1, 1);
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>();
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();
        Opportunity opp1 = SL_SCTestData.testOpportunities[0];
        Opportunity opp2 = opp1.clone(true);
        oldMap.put(opp1.Id, opp1);
        newMap.put(opp2.Id, opp2);
                Test.startTest();
        TC_NotificationEmailBatch batch = new TC_NotificationEmailBatch(oldMap, newMap, 'Submitted');
        try {
            Database.executeBatch(batch);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
        }
        Test.stopTest();

// /*
//          Query the dummy opportunity in newMap then clone it to oldMap.
//          We're not testing the notifications themselves, so there's nothing to compare.
//          */
//         Map<Id, Opportunity> newMap = new Map<Id, Opportunity>([
//                 SELECT Id,
//                         Name,
//                         Branch__c,
//                         Loan_Record_Type__c,
//                         Primary_Dealer__c,
//                         Created_via_App_Wizard__c,
//                         Portal_App_Completed__c,
//                         Application__c,
//                         SFP_Tier_2_Status__c,
//                         Portal_User_ID__c,
//                         Opportunity_Owner__c
//                 FROM Opportunity
//                 WHERE Name = 'Test'
//         ]);
//         Map<Id, Opportunity> oldMap = newMap.clone();


    }

    // SAL-5496 Misael Romero
    // /**
    //  * Test scheduling the approval notification
    //  */
    // @IsTest
    // static void testApproved() {

    //     /*
    //      Query the dummy opportunity in newMap then clone it to oldMap.
    //      We're not testing the notifications themselves, so there's nothing to compare.
    //      */
    //     Map<Id, Opportunity> newMap = new Map<Id, Opportunity>([
    //             SELECT Id,
    //                     Name,
    //                     Application_Status__c,
    //                     Primary_Dealer__c,
    //                     Branch__c,
    //                     Loan_Record_Type__c,
    //                     Portal_App_Completed__c,
    //                     SFP_Tier_2_Status__c,
    //                     Portal_User_ID__c,
    //                     Opportunity_Owner__c
    //             FROM Opportunity
    //             WHERE Name = 'Test'
    //     ]);
    //     Map<Id, Opportunity> oldMap = newMap.clone();

    //     Test.startTest();
    //     TC_NotificationEmailBatch batch = new TC_NotificationEmailBatch(oldMap, newMap, 'Approved');
    //     try {
    //         Database.executeBatch(batch);
    //     } catch (Exception e) {
    //         System.debug(LoggingLevel.ERROR, e.getMessage());
    //     }
    //     Test.stopTest();
    // }

    // /**
    //  * Test scheduling the rejected notification
    //  */
    // @IsTest
    // static void testRejected() {

    //     /*
    //      Query the dummy opportunity in newMap then clone it to oldMap.
    //      We're not testing the notifications themselves, so there's nothing to compare.
    //      */
    //     Map<Id, Opportunity> newMap = new Map<Id, Opportunity>([
    //             SELECT Id,
    //                     Name,
    //                     Opportunity_Status__c
    //             FROM Opportunity
    //             WHERE Name = 'Test'
    //     ]);
    //     Map<Id, Opportunity> oldMap = newMap.clone();

    //     Test.startTest();
    //     TC_NotificationEmailBatch batch = new TC_NotificationEmailBatch(oldMap, newMap, 'Rejected');
    //     try {
    //         Database.executeBatch(batch);
    //     } catch (Exception e) {
    //         System.debug(LoggingLevel.ERROR, e.getMessage());
    //     }
    //     Test.stopTest();
    // }

    // /**
    //  * Test scheduling the More Info notification
    //  */
    // @IsTest
    // static void testMoreInfo() {

    //     /*
    //      Query the dummy opportunity in newMap then clone it to oldMap.
    //      We're not testing the notifications themselves, so there's nothing to compare.
    //      */
    //     Map<Id, Opportunity> newMap = new Map<Id, Opportunity>([
    //             SELECT Id,
    //                     Name,
    //                     Opportunity_Status__c
    //             FROM Opportunity
    //             WHERE Name = 'Test'
    //     ]);
    //     Map<Id, Opportunity> oldMap = newMap.clone();

    //     Test.startTest();
    //     TC_NotificationEmailBatch batch = new TC_NotificationEmailBatch(oldMap, newMap, 'More Info');
    //     try {
    //         Database.executeBatch(batch);
    //     } catch (Exception e) {
    //         System.debug(LoggingLevel.ERROR, e.getMessage());
    //     }
    //     Test.stopTest();
    // }
    
    // /**
    //  * Test scheduling the Submitted Loan notification
    //  */
    // @IsTest
    // static void testSubmittedLoan() {

    //     /*
    //      Query the dummy opportunity in newMap then clone it to oldMap.
    //      We're not testing the notifications themselves, so there's nothing to compare.
    //      */
    //     Map<Id, Opportunity> newMap = new Map<Id, Opportunity>([
    //             SELECT Id,
    //                     Name,
    //                     Opportunity_Status__c,
    //         			OwnerId
    //             FROM Opportunity
    //             WHERE Name = 'Test'
    //     ]);
    //     Map<Id, Opportunity> oldMap = newMap.clone();

    //     Test.startTest();
    //     TC_NotificationEmailBatch batch = new TC_NotificationEmailBatch(oldMap, newMap, 'Submitted Loan');
    //     try {
    //         Database.executeBatch(batch);
    //     } catch (Exception e) {
    //         System.debug(LoggingLevel.ERROR, e.getMessage());
    //     }
    //     Test.stopTest();
    // }
}