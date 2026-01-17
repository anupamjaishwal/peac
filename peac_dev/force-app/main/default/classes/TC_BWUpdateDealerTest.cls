/**
 * Created by jhber on 3/6/2019.
 */

@isTest
public with sharing class TC_BWUpdateDealerTest {

    @TestSetup static void setup () {
        // Setup test data
        SL_SCTestData.createBridgeWareSetting();

        Account act = new Account ();
        act.name = 'Update Dealer Test1';
        act.Dealer_Number__c = '12345';
        act.Pass_Through_Maint__c = 'Yes';
        act.Pass_Thru_Maintenance_Frequency__c = 'QTLY';
        act.Account_Dealer_Status__c = 'Active';
        act.Dealer_Number__c = '585412.1234';
        act.Waiting_To_Be_Sent_To_Bridgeware__c = true;
        insert act;
/*
        Dealer_Surveillance__c surv = new Dealer_Surveillance__c();
        surv.Account__c = act.Id;
        surv.Status__c = 'Completed';
        surv.Additional_Review_Comments__c = 'Comments Here!';
        surv.Review_Date__c = System.today().addYears(1);
        insert surv;*/
        
        Dealer_Surveillance_Model__c dsm = new Dealer_Surveillance_Model__c();
        dsm.Actual_Vs_Project_Max__c = 250;
        dsm.Delinquency_Max__c = 7.5;
        dsm.Net_Investment_Maximum__c = 250000;
        dsm.Net_Investment_Minimum__c = 0;
        insert dsm;
    }

    @isTest
    static void testUpdate() {
        List<Account> acc = [SELECT Id, Name, Dealer_Number__c, Pass_Thru_Maintenance_Frequency__c FROM Account];
        
        Test.setMock(HttpCalloutMock.class, new TC_BWDealerCalloutMockImpl ());
        Test.startTest();
        
        
        Dealer_Surveillance__c surv = new Dealer_Surveillance__c();
        surv.Account__c = acc[0].Id;
        surv.Status__c = 'Completed';
        surv.Completed_By_Auto_Process__c = true;
        surv.Additional_Review_Comments__c = 'Comments Here!';
        surv.Review_Date__c = System.today().addYears(1);
        insert surv;
        
        TC_BWUpdateDealerCtrl.updateDealer(acc);
        Test.stopTest ();
    }

    @isTest
    static void testUpdateSurveillance() {
        List<Account> acc = [SELECT Id, Name, Dealer_Number__c, Pass_Thru_Maintenance_Frequency__c FROM Account];
        //List<Dealer_Surveillance__c> surv = [SELECT Id, Name, Status__c, Additional_Review_Comments__c, Review_Date__c FROM Dealer_Surveillance__c];
        Test.setMock(HttpCalloutMock.class, new TC_BWDealerCalloutMockImpl ());
        Test.startTest();
        
        
        Dealer_Surveillance__c surv = new Dealer_Surveillance__c();
        surv.Account__c = acc[0].Id;
        surv.Status__c = 'Completed';
        surv.Completed_By_Auto_Process__c = true;
        surv.Additional_Review_Comments__c = 'Comments Here!';
        surv.Review_Date__c = System.today().addYears(1);
        insert surv;
        
        TC_BWUpdateDealerSurveillanceCtrl.updateDealerSurveillance(new List <Dealer_Surveillance__c> {surv});
        Test.stopTest ();
    }

    @isTest
    static void testInvalidUpdate() {
        List<Account> acc = [SELECT Id, Name, Dealer_Number__c, Pass_Thru_Maintenance_Frequency__c FROM Account];

        acc[0].Pass_Thru_Maintenance_Frequency__c = 'INV';
        Test.setMock(HttpCalloutMock.class, new TC_BWDealerCalloutMockImpl ());
        
        Test.startTest();
        
        Dealer_Surveillance__c surv = new Dealer_Surveillance__c();
        surv.Account__c = acc[0].Id;
        surv.Status__c = 'In Queue';
        surv.Completed_By_Auto_Process__c = true;
        surv.Additional_Review_Comments__c = 'Comments Here!';
        surv.Review_Date__c = System.today().addYears(1);
        insert surv;
        
        TC_BWUpdateDealerCtrl.updateDealer(acc);
        Test.stopTest ();
    }
    
    
        @isTest
    static void portfolioThresholdUpdate() {
        List<Account> acc = [SELECT Id, Name, Dealer_Number__c, Pass_Thru_Maintenance_Frequency__c FROM Account];
        //List<Dealer_Surveillance__c> surv = [SELECT Id, Name, Status__c, Additional_Review_Comments__c, Review_Date__c FROM Dealer_Surveillance__c];
        //
        List<Dealer_Surveillance__c> survList = new List<Dealer_Surveillance__c>();
        Dealer_Surveillance__c surv = new Dealer_Surveillance__c();
        surv.Account__c = acc[0].Id;
        surv.Status__c = 'In Queue';
        surv.Completed_By_Auto_Process__c = true;
        surv.Additional_Review_Comments__c = 'Comments Here!';
        surv.Review_Date__c = System.today().addYears(1);
        surv.Reputational_Search__c = 'Satisfactory' ;
        surv.Credit_Profile_Update__c = 'Satisfactory';
        surv.Dealer_Surveillance__c='Portfolio Threshold $250K';
        surv.Review_Type__c = 'Portfolio Threshold';
        survList.add(surv);
        
         Dealer_Surveillance__c surv2 = new Dealer_Surveillance__c();
        surv2.Account__c = acc[0].Id;
        surv2.Status__c = 'In Queue';
        surv2.Completed_By_Auto_Process__c = true;
        surv2.Additional_Review_Comments__c = 'Comments Here!';
        surv2.Review_Date__c = System.today().addYears(1);
        surv2.Review_Type__c = 'Portfolio Threshold';
		surv2.Reputational_Search__c = 'Satisfactory' ;
		surv2.Credit_Profile_Update__c='Satisfactory';
		surv2.Dealer_Surveillance__c='Portfolio Threshold $500K';
        survList.add(surv2);
        
        insert survList;
        Test.setMock(HttpCalloutMock.class, new TC_BWDealerCalloutMockImpl ());
        
        
        Test.startTest();
        
		
        surv2.Status__c = 'Completed';
        update surv2;
        
        TC_BWUpdateDealerSurveillanceCtrl.updateDealerSurveillance(new List <Dealer_Surveillance__c> {surv});
        Test.stopTest ();
    }

}