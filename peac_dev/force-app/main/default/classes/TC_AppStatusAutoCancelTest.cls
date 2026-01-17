/**
 * Created by andrewmayer on 2/13/20.
 */

@istest public with sharing class TC_AppStatusAutoCancelTest {

    private static String CRON_EXP = '0 5 0 * * ? 2023';

    @testSetup public static void setupDeal () {

        Account acc = new Account (Name = 'testbeni', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId());
        insert acc;

        insert new Opportunity (AccountId = acc.Id
                , StageName = 'test'
                , CloseDate = date.today () + 10
                , Name = 'More Info Test'
                , Initial_More_Info_Date__c = Datetime.now().addDays(-50)
                , Application_Status__c = 'More Info');
        

        


    }
    @isTest public static void cancelApprovedDealTest () {

        Test.startTest();
        System.schedule('Job Started at ' + String.valueOf(Datetime.now()), CRON_EXP, new TC_AppStatusAutoCancelApprovedSchd ());
        Test.stopTest();

    }

    @isTest public static void cancelMoreInfoDealTest () {


        Test.startTest();
        System.schedule('Job Started at ' + String.valueOf(Datetime.now()), CRON_EXP, new TC_AppStatusAutoCancelMoreInfoSchd ());
        Test.stopTest();

    }

}