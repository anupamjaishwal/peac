@isTest
public with sharing class SL_DataTableController_Test {

  @TestSetup
  static void makeData(){
    SL_SCTestData.createAccountAndContracts(1, 1);
    List<Account> accounts = SL_SCTestData.testAccounts;
    SL_SCTestData.createOpportunitiesAndAssets(accounts[0].Id, 1, 1);
  }

  @isTest
  public static void dataTableResponseTest(){
    test.startTest();
    List<Opportunity> lstOpps     = [SELECT Id, AccountId FROM Opportunity];
    String  sObjectName           = 'Opportunity';
    String  fieldSetName          = 'Opportunity_Deal_Portal';
    String  sObjectLookupIDField  = 'AccountId';
    String  additionalWhereClause = 'IsClosed = FALSE';
    String  recordId              = lstOpps[0].AccountId;
    Boolean includeName           = true;
    String  orderBy               = 'Name';

    SL_DataTableController.DataTableResponse response = SL_DataTableController.getSobjectRecords(sObjectName, fieldSetName, 
                                                                                                sObjectLookupIDField, additionalWhereClause,
                                                                                                recordId, includeName, orderBy);
    test.stopTest();

    system.assertEquals(1, response.dataTableData.size());
    system.assert(!response.listColumns.isEmpty());
  }
}