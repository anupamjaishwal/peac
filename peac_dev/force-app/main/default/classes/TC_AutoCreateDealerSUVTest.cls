@isTest public class TC_AutoCreateDealerSUVTest {
    
    private static String CRON_EXP = '0 5 0 * * ? ';
    
    @testSetup public static void setupData () {

//         Bridgeware_Service_Setting__c setting = new Bridgeware_Service_Setting__c ();
//         setting.Enable_Debug_Log__c = true;
//         setting.Mock_Callout__c = true;
//         setting.Mock_Endpoint__c = 'https://private-b2bb6-bridgewaretamarack.apiary-mock.com/';
// //        setting.SetupOwnerId = UserInfo.getOrganizationId ();
//         setting.Config_Name__c = 'TEST';
//         setting.Mock_Callout_createCustomer__c = 'https://private-b2bb6-bridgewaretamarack.apiary-mock.com/';
//         insert setting;
        SL_SCTestData.createBridgeWareSetting();
        
        Account a = new Account();
        a.Name = 'dealerSurveillanceTestAccount';
        a.Next_Scheduled_Review__c = Date.today ();
        a.Dealer_Number__c = '12345';
        a.Pass_Through_Maint__c = 'Yes';
        a.Pass_Thru_Maintenance_Frequency__c = 'QTLY';
        a.Account_Dealer_Status__c = 'Active';
        a.Dealer_Number__c = '585412.1234';
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId();
        a.X1_app_in_the_last_24_months__c = 1;
        a.Account_Total_CBR__c = 1000;
        a.Equipment_Type__c = 'A/V (General)';
        a.Business_Phone__c = '5854121234';
        insert a;
        
    }
    
    @isTest public static void salesforceTest () {
        
        TC_DealerSurveillanceBatchSchd s = new TC_DealerSurveillanceBatchSchd ();
        test.startTest();
        CRON_EXP +=String.valueOf(Date.today().year() + 1);
        System.schedule('Job Started at ' + String.valueOf(Datetime.now()), CRON_EXP, s);
        test.stopTest();
    }
    
    @isTest public static void infoLeaseTest () {
        Account a = [SELECT Id FROM Account WHERE Name = 'dealerSurveillanceTestAccount'][0];
        Dealer_Surveillance__c dealerSurv = new Dealer_Surveillance__c(Account__c = a.Id, Status__c = 'Completed', Waiting_To_Be_Sent_To_Bridgeware__c = true);
        insert dealerSurv;

        Test.setMock(HttpCalloutMock.class, new TC_BWDealerCalloutMockImpl ());
        Test.startTest();

        TC_DealerSurveillanceSendToBWBatchSchd  s = new TC_DealerSurveillanceSendToBWBatchSchd ();
        CRON_EXP +=String.valueOf(Date.today().year() + 1);
        System.schedule('Job Started at ' + String.valueOf(Datetime.now()), CRON_EXP, s);
        TC_BWupdateDealerSurveillanceCtrl.updateDealerSurveillanceFuture(dealerSurv.Id);
        Test.stopTest();
    }
    
    @isTest public static void infoLeaseBackfillTest () {
        Account a = [SELECT Id FROM Account WHERE Name = 'dealerSurveillanceTestAccount'][0];
        insert new Dealer_Surveillance__c(Account__c = a.Id, Status__c = 'Completed', Waiting_To_Be_Sent_To_Bridgeware__c = true, Created_via_Backfill_Job__c = true);

        Test.setMock(HttpCalloutMock.class, new TC_BWDealerCalloutMockImpl ());
        Test.startTest();
        
        Database.executeBatch(new TC_DealerSurvSendToBWBackfillBatch(), 200);
        
        Test.stopTest();
    }
}