/**
 * Created by corycafferty on 2019-07-23.
 */

@IsTest public with sharing class TC_DealerSurveillanceBatchSchdTest {
    private static String CRON_EXP = '0 5 0 * * ? 2023';

    @TestSetup static void setupData () {

        Bridgeware_Service_Setting__c setting = new Bridgeware_Service_Setting__c ();
        setting.Enable_Debug_Log__c = true;
        setting.Mock_Callout__c = true;
        setting.Mock_Endpoint__c = 'https://private-b2bb6-bridgewaretamarack.apiary-mock.com/';
//        setting.SetupOwnerId = UserInfo.getOrganizationId ();
        setting.Config_Name__c = 'TEST';
        setting.Mock_Callout_createCustomer__c = 'https://private-b2bb6-bridgewaretamarack.apiary-mock.com/';
        insert setting;
        
        Test.setMock(HttpCalloutMock.class, new TC_BWDealerCalloutMockImpl ());
        Test.startTest();

        Account a = new Account(Name = 'dealerSurveillanceTestAccount', Next_Scheduled_Review__c = Date.today());
        a.Dealer_Number__c = '12345';
        a.Pass_Through_Maint__c = 'Yes';
        a.Pass_Thru_Maintenance_Frequency__c = 'QTLY';
        a.Account_Dealer_Status__c = 'Active';
        a.Dealer_Number__c = '585412.1234';
        a.X1_app_in_the_last_24_months__c = 1;
        a.Account_Total_CBR__c = 100;
        a.Waiting_To_Be_Sent_To_Bridgeware__c = true;
        Account a2 = new Account(Name = 'dealerSurveillanceTestAccount2', Next_Scheduled_Review__c = Date.today());
        a2.Dealer_Number__c = '12345';
        a2.Pass_Through_Maint__c = 'Yes';
        a2.Pass_Thru_Maintenance_Frequency__c = 'QTLY';
        a2.Account_Dealer_Status__c = 'Active';
        a2.Dealer_Number__c = '585412.1234';
        a2.Waiting_To_Be_Sent_To_Bridgeware__c = true;
        insert new List <Account> {a,a2};
        
        Dealer_Surveillance__c suv = new Dealer_Surveillance__c  (Account__c = a.Id, Status__c = 'Completed', Completed_By_Auto_Process__c = true, Next_Scheduled_Review__c = Date.today());
        insert suv;
        
        Dealer_Surveillance__c suv2 = new Dealer_Surveillance__c  (Account__c = a2.Id, Status__c = 'Completed', Completed_By_Auto_Process__c = true, Next_Scheduled_Review__c = Date.today());
        insert suv2;
        Test.stopTest();

    }

    testMethod static void dealerSurveillanceTest () {

        Account a = [SELECT Id FROM Account WHERE Name = 'dealerSurveillanceTestAccount'][0];


        Test.setMock(HttpCalloutMock.class, new TC_BWDealerCalloutMockImpl ());
        Test.startTest();

        insert new Dealer_Surveillance__c(Account__c = a.Id, Status__c = 'Completed', Completed_By_Auto_Process__c = true, Waiting_To_Be_Sent_To_Bridgeware__c = true);



        TC_DealerSurveillanceBatchSchd s = new TC_DealerSurveillanceBatchSchd();
        System.schedule('Job Started at ' + String.valueOf(Datetime.now()), CRON_EXP, s);
        Test.stopTest();
    }
}