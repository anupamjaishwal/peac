@isTest

private class TC_RateCardTest {
  @testSetup
  static void setupData () {
    Account account = new Account(Name = 'test account');
    insert account;
    
    Opportunity opp = new Opportunity();
    opp.Name = 'test';
    opp.CloseDate = Date.today();
    opp.StageName = 'test';
    opp.AccountId = account.Id;
    opp.Equipment_Cost__c = 1500;
    insert opp;
    
    TCRE__Rule_Config__c conf = new TCRE__Rule_Config__c();
    conf.TCRE__Priority__c = 1;
    conf.TCRE__SObject_Name__c = 'Opportunity';
    insert conf;
    
    TCRE__Rule_Condition__c cond = new TCRE__Rule_Condition__c();
		cond.TCRE__Rule_Config__c = conf.Id;
    cond.TCRE__Field_Name__c = 'StageName';
    cond.TCRE__Operator__c = '=';
    cond.TCRE__Value__c = 'Proposal';
    insert cond;
    
    RateCard__c rc = new RateCard__c();
    rc.Name = 'Mtest';
    rc.Entry_Criteria__c = conf.Id;
    insert rc;
        
		Rate_Card_Column__c col = new Rate_Card_Column__c();
    col.Rate_Card__c = rc.Id;
    col.Column_Criteria__c = conf.Id;
    insert col;
    
    Rate_Card_Row__c row = new Rate_Card_Row__c(); 
    row.Rate_Card__C = rc.Id;
    row.Row_Criteria__c = conf.Id;
    insert row;
      
      Offers_Pricing_Authority__c pricingAuth = new Offers_Pricing_Authority__c();
      pricingAuth.Name='Offers/Pricing Authority (Profile)';
      pricingAuth.Minimum_Yield_12_35_months__c = 6.99;
      pricingAuth.Minimum_Yield_36_59_months__c = 5.99;
      pricingAuth.Minimum_Yield_60_months__c = 4.99;
      pricingAuth.RBP_Rate_Concession__c = 100;
      pricingAuth.SetupOwnerId = UserInfo.getProfileId();
          
      INSERT pricingAuth;
  }
    
    
  @isTest
  static void testCtrl () {

    Test.startTest();
    RateCard__c rc = [SELECT Id FROM RateCard__c LIMIT 1];

    List <Rate_Card_Column__c> cols = TC_RateCardCtrl.getColumns(rc.Id);
    List <Rate_Card_Row__c> rows = TC_RateCardCtrl.getRows(rc.Id);
            
    cols = TC_RateCardCtrl.saveRateCardValues (rc.Id, cols[0].Rate_Card_Rates__r);

    Test.stopTest();

  }
    
  @isTest
  static void testApex () {
    Test.startTest();

    Rate_Card_Rate__c rate = new Rate_Card_Rate__c();
    rate.Rate__c = 10;
    rate.Rate_Card_Column__c = [SELECT Id FROM Rate_Card_Column__c LIMIT 1].Id;
    rate.Rate_Card_Row__c = [SELECT Id FROM Rate_Card_Row__c LIMIT 1].Id;
    insert rate;

    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    opp.StageName = 'Proposal';
    opp.Credit_Risk_Grade__c = 'C2';
    opp.Offer_Made_By__c = 'Dealer';
    update opp;
    Test.stopTest();
    EF_Approved_Offers__c offer = [SELECT Id FROM EF_Approved_Offers__c LIMIT 1];
    offer.Term_in_Months__c = 12;
    Update offer;
      
    offer.Is_Selected_Offer__c = true;
    Update offer;
  }

  @isTest
  static void testApex2 () {
    Test.startTest();

    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    opp.StageName = 'Proposal';
    opp.Credit_Risk_Grade__c = 'C2';
    update opp;

    Test.stopTest();
  }

  @isTest
  static void test_ConditionValue(){
    String conditionValue = 'Proposal';
    Test.startTest();
      RateCard__c rc = [SELECT Id FROM RateCard__c LIMIT 1];
      Assert.areEqual(conditionValue, TC_RateCardCtrl.getConditionValue(rc.Id, conditionValue));
      Assert.areEqual(null, TC_RateCardCtrl.getConditionValue(rc.Id, 'test'));
    Test.stopTest();
  }
    
  @isTest
  static void testCoverageOfferSelected () {
    Test.startTest();

    Rate_Card_Rate__c rate = new Rate_Card_Rate__c();
    rate.Rate__c = 10;
    rate.Rate_Card_Column__c = [SELECT Id FROM Rate_Card_Column__c LIMIT 1].Id;
    rate.Rate_Card_Row__c = [SELECT Id FROM Rate_Card_Row__c LIMIT 1].Id;
    insert rate;

    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    opp.StageName = 'Proposal';
    opp.Credit_Risk_Grade__c = 'C2';
    opp.Offer_Made_By__c = 'Dealer';
    update opp;
    Test.stopTest();
    EF_Approved_Offers__c offer = [SELECT Id FROM EF_Approved_Offers__c LIMIT 1];
    offer.Term_in_Months__c = 60;
    Update offer;
      
    offer.Is_Selected_Offer__c = true;
    Update offer;
  }
    
    @isTest
  static void testCoverageOfferSelected2 () {
    Test.startTest();

    Rate_Card_Rate__c rate = new Rate_Card_Rate__c();
    rate.Rate__c = 10;
    rate.Rate_Card_Column__c = [SELECT Id FROM Rate_Card_Column__c LIMIT 1].Id;
    rate.Rate_Card_Row__c = [SELECT Id FROM Rate_Card_Row__c LIMIT 1].Id;
    insert rate;

    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    opp.StageName = 'Proposal';
    opp.Credit_Risk_Grade__c = 'C2';
    opp.Offer_Made_By__c = 'Dealer';
    opp.Portal_User_ID__c = 'DP-';
    update opp;
    Test.stopTest();
    EF_Approved_Offers__c offer = [SELECT Id FROM EF_Approved_Offers__c LIMIT 1];
    offer.Term_in_Months__c = 36;
    Update offer;
      
    offer.Is_Selected_Offer__c = true;
    Update offer;
  }
}