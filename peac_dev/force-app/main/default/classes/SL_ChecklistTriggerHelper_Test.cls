@isTest
public with sharing class SL_ChecklistTriggerHelper_Test {
  Private final static Integer OPP_COUNT = 20;
  private static final Id PROGRAM_APPLICATION_RT_ID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('SNAP_Application').getRecordTypeId();
  private static final String OEG_DEALER_PROFILE = 'OEG Dealer';
  private static final String USERNAME = 'Portal.SL.test.user@silverlinecrm.com';

  @TestSetup
  static void makeData(){
    Account portalAccount = new Account(name = 'portalAccount', Business_Phone__c = '1234567890');//create a portal account first
    INSERT portalAccount;
    
    Contact portalContact = new contact(LastName = 'portalContact', FirstName = 'Test', AccountId = portalAccount.Id); //create a portal contact
    INSERT portalContact;
    

    User u = new User(Alias = 'testuser', Email = 'marlinbusiness@peacsolutions.com', EmailEncodingKey='UTF-8',
            LastName = 'testing', FirstName = 'user', LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US', ProfileId = [SELECT Id, Name FROM Profile WHERE Name = :OEG_DEALER_PROFILE].Id, TimeZoneSidKey = 'America/Los_Angeles',
            Username = USERNAME, Doc_Fee_Exception_Approver__c = true, PortalRole = 'Manager', ContactId = portalContact.Id);
    INSERT u;

    List<Opportunity> lstOpps = new List<Opportunity>();
    TC_OpportunityTriggerHandler.SITE_ID = 'Test Portal';

    system.runAs(u){
      for(Integer i=0; i<OPP_COUNT; i++){
        Opportunity opp = new Opportunity(Name = 'Test Opp Portal ' + i, AccountId = portalAccount.Id, StageName = 'Quote', RecordTypeId = PROGRAM_APPLICATION_RT_ID,
                          CloseDate = Date.today(), Terms__c = 12, Equipment_Cost__c = 1500, Equipment_Description__c = 'Test', Dealer_User__c = u.Id);
        lstOpps.add(opp);
      }
      INSERT lstOpps;
        TC_ChecklistUtilTest.setupTemplates();
    }
/*
    TC_Origination__Checklist_Template__c template = new TC_Origination__Checklist_Template__c (TC_Origination__API_Name__c = 'Credit Stips');
    INSERT template;

    List<TC_Origination__Checklist__c> lstChecklist = new List<TC_Origination__Checklist__c>();
    for(Opportunity opp :lstOpps){
      TC_Origination__Checklist__c checklist = new TC_Origination__Checklist__c();
      checklist.name = opp.Name;
      checklist.TC_Origination__Opportunity__c  = opp.Id;
      checklist.TC_Origination__API_Name__c = opp.Name;
      checklist.TC_Origination__Checklist_Template__c = template.Id;

      lstChecklist.add(checklist);
    }
    INSERT lstChecklist;
      */
      

  }

  @isTest
  static void test_checklistApexSharing(){
    User u = [SELECT Id FROM User WHERE Username = :USERNAME];
    system.runAs(u){
      List<TC_Origination__Checklist__c> checklists = [SELECT Id, Dealer_User__c, TC_Origination__Opportunity__c FROM TC_Origination__Checklist__c];
      Test.startTest();
      update checklists;
      Test.stopTest();
      List<Opportunity> oppsAfter = [SELECT Id, Dealer_User__c FROM Opportunity WHERE Id = :checklists[0].TC_Origination__Opportunity__c];
      System.Assert.areEqual(oppsAfter[0].Dealer_User__c, checklists[0].Dealer_User__c, 'Dealer user must be copied from Opp.');
    }
  }
}