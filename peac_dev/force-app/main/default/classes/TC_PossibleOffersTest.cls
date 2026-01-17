/**
 * Created by trohweder on 12/21/20.
 */

@IsTest
public with sharing class TC_PossibleOffersTest {

    @TestSetup
    static void setupData () {
        Account account = new Account(Name = 'test account');
        insert account;

        Opportunity opp = new Opportunity();
        opp.Name = 'test';
        opp.CloseDate = Date.today();
        opp.StageName = 'test';
        opp.AccountId = account.Id;
        opp.Equipment_Cost__c = 100;
        opp.Points__c = 0;
        insert opp;

        TCRE__Rule_Config__c conf = new TCRE__Rule_Config__c();
        conf.TCRE__Priority__c = 1;
        conf.TCRE__SObject_Name__c = 'Opportunity';
        insert conf;

        TCRE__Rule_Condition__c cond = new TCRE__Rule_Condition__c();
        cond.TCRE__Rule_Config__c = conf.Id;
        cond.TCRE__Field_Name__c = 'Equipment_Cost__c';
        cond.TCRE__Operator__c = '<';
        cond.TCRE__Value__c = '1500';
        insert cond;

        RateCard__c rc = new RateCard__c();
        rc.Name = 'Mtest';
        rc.Entry_Criteria__c = conf.Id;
        insert rc;

        Rate_Card_Column__c col = new Rate_Card_Column__c();
        col.Rate_Card__c = rc.Id;
        col.Column_Criteria__c = conf.Id;
        col.Name = '36';
        col.Residual__c = 10;
        insert col;

        Rate_Card_Row__c row = new Rate_Card_Row__c();
        row.Rate_Card__c = rc.Id;
        row.Row_Criteria__c = conf.Id;
        insert row;

        Rate_Card_Rate__c rate = new Rate_Card_Rate__c();
        rate.Rate_Card_Row__c = row.Id;
        rate.Rate_Card_Column__c = col.Id;
        rate.Rate__c = 30;
        insert rate;
    }

    @IsTest
    static void generatePossibleOffers(){
        Test.startTest();
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name='test'];
        List<TC_PossibleOffers.PossibleOffer> offers = TC_PossibleOffers.generatePossibleOffers(opp.Id);
        System.assertEquals(1,offers.size());
        Test.stopTest();
    }

    // SAL-2602
    @IsTest
    static void testGeneratePossibleOffersFromOpp(){
        Test.startTest();
        Opportunity opp = [
                SELECT Id,
                        Equipment_Cost__c,
                        Credit_Risk_Grade__c,
                        Deferral_Payments__c,
                        Lessor__c,
                        Risk_Based_Pricing__c,
                        RBP_Webservice__c,
                        Points__c
                FROM Opportunity
                WHERE Name='test'
        ];
        List<TC_PossibleOffers.PossibleOffer> offers = TC_PossibleOffers.generatePossibleOffersFromOpp(opp);
        System.assertEquals(1,offers.size());
        Test.stopTest();
    }

    @isTest
    static void test_OppNonFMVOption(){
      Test.startTest();
      Opportunity opp = [
                SELECT Id,
                        Equipment_Cost__c,
                        Credit_Risk_Grade__c,
                        Deferral_Payments__c,
                        Lessor__c,
                        Risk_Based_Pricing__c,
                        RBP_Webservice__c,
                        Points__c,
                        Purchase_Options__c
                FROM Opportunity
                WHERE Name='test'
        ];
        List<TC_PossibleOffers.PossibleOffer> offers = TC_PossibleOffers.generatePossibleOffersFromOpp(opp);
        System.assertEquals(1,offers.size());
        opp.Deferral_Payments__c = '30 days';
        opp.Equipment_Cost__c = 1100;
        opp.StageName = 'Proposal';
        opp.Terms__c = 36;
        opp.Lessor__c = 421;
        opp.Purchase_Options__c = '1.00 Out';
       UPDATE opp;
      Test.stopTest();
      for(EF_Approved_Offers__c ef : [SELECT Id, Residual__c FROM EF_Approved_Offers__c WHERE Opportunity__c = :opp.Id]){
        Assert.areEqual(null, ef.Residual__c, 'Expecting null value on Residual for non FMV Opps');
      }
    }

    @isTest
    static void test_OppFMVOption(){
      Test.startTest();
      Opportunity opp = [
                SELECT Id,
                        Equipment_Cost__c,
                        Credit_Risk_Grade__c,
                        Deferral_Payments__c,
                        Lessor__c,
                        Risk_Based_Pricing__c,
                        RBP_Webservice__c,
                        Points__c,
                        Purchase_Options__c
                FROM Opportunity
                WHERE Name='test'
        ];
        List<TC_PossibleOffers.PossibleOffer> offers = TC_PossibleOffers.generatePossibleOffersFromOpp(opp);
        system.debug('offers ' + offers);
        System.assertEquals(1,offers.size());
        opp.Deferral_Payments__c = '30 days';
        opp.Equipment_Cost__c = 1100;
        opp.StageName = 'Proposal';
        opp.Terms__c = 36;
        opp.Lessor__c = 1;
        opp.Purchase_Options__c = 'FMV';
        opp.Portal_User_ID__c = 'DP-';
        opp.Required_Adv_Payments__c = 0;
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('SNAP_Application').getRecordTypeId();
       UPDATE opp;
      Test.stopTest();
      for(EF_Approved_Offers__c ef : [SELECT Id, Residual__c FROM EF_Approved_Offers__c WHERE Opportunity__c = :opp.Id]){
        Assert.isNotNull( ef.Residual__c, 'Expecting non null value on Residual for FMV Opps');
      }
      opp.Required_Adv_Payments__c = 1;
      UPDATE opp;
    }
}