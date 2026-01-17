@isTest
public class MARLIN_CaseCenterCalloutTest {
    
    @testSetup static void testSetupMethod() {
    
        Id accBrokRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
        Account acc = new Account(Name='Test', CCAN__c='123456', Tax_ID__c='123435678', RecordTypeId = accBrokRecordTypeId, Business_State__c = 'AL', Business_City__c='New York', Business_Phone__c = '1234543247',
                                   Business_Country__c = 'UK', Business_Address__c = 'Test Test', Business_Type__c = 'Proprietorship', Business_Zip__c = '12345');
        insert acc;
        Contact con = TestDataFactory.createTestContact(acc.Id);
        Opportunity opp=new Opportunity(Name='Test opp',CloseDate=System.today()+30, 
                        AccountId=acc.Id,State_Tax_Code__c='MN',Tax_City__c='WOODBURY',Tax_ID__c='622666666',
                                      Tax_County__c = 'WASHINGTON', Tax_Exempt__c='Yes', Amount=33, Billing_Cycle__c='December',
                                      Recurring__c='Recurring Only', StageName='Application', Primary_Source__c = 'Indirect',  Equipment_Cost__c = 150 ,  Equipment_Description__c = 'test',
                                         Terms__c = 123);
        insert opp;
    
        
        //Creating OpportunityContactRole Record
        OpportunityContactRole OppConRoleObj = new OpportunityContactRole();
        OppConRoleObj.OpportunityId = opp.Id;
        OppConRoleObj.ContactId = con.Id;
        OppConRoleObj.Role = 'Primary Contact';
        OppConRoleObj.IsPrimary = false;
        insert OppConRoleObj;
        
        Id oppLoanRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan Booking').getRecordTypeId();
        Opportunity oppLoan=new Opportunity(Name='Test opp',CloseDate=System.today()+30, 
                        AccountId=acc.Id,State_Tax_Code__c='MN',Tax_City__c='WOODBURY',Tax_ID__c='622666666',
                                      Tax_County__c = 'WASHINGTON', Tax_Exempt__c='Yes', Amount=33, Billing_Cycle__c='December',
                                      Recurring__c='Recurring Only', StageName='Application',  Equipment_Cost__c = 150 ,  Equipment_Description__c = 'test',
                                         Terms__c = 123, recordTypeId = oppLoanRecordTypeId, Primary_Source__c='Customer Outbound',   Annual_Revenue__c = 1200, Requested_Amount__c = 1000);
        insert oppLoan;
        
        
        //Creating Broker Record
        //  Broker__c brokObj = new Broker__c();
        // brokObj.Opportunity__c = opp.id;
        //  brokObj.Primary_Broker__c = false;
        // insert brokObj;
        
        //Creating Guarantor Record
        Guarantor__c guaObj = new Guarantor__c();
        guaObj.Account__c = acc.Id;
        guaObj.Contact__c = con.Id;
        guaObj.Opportunity__c = opp.Id;
        guaObj.Type__c = 'Personal Guarantor';
        guaObj.RP_PRIN_GUAR_CODE__c = 'Guarantor';
        insert guaObj;
   
        
        //Creating Opportunity Attachment Record
        Opportunity_Attachment__c oppAttObj = new Opportunity_Attachment__c();
        oppAttObj.Account__c = acc.Id;
        oppAttObj.Opportunity__c = opp.Id;
        oppAttObj.Description__c = 'Test';
        oppAttObj.Sent_To_Ocrolus__c  = false;
        oppAttObj.Updated_Rapport__c = false;
        oppAttObj.Type__c = 'LC - Misc';
        oppAttObj.Sent_To_OnBase__c = false;
        insert oppAttObj;
  }
    
    
    static testMethod void testPostCallout() {
       Test.startTest();
     Test.setMock(HttpCalloutMock.class, new MARLIN_CaseCenterCalloutMockImpl());
     Opportunity opp = [Select Id from Opportunity limit 1];
       String value = MARLIN_CaseCenterCallout.submitAppToCaseCenter(opp.Id);
       String value1 = MARLIN_CaseCenterCallout.submitUpdatedAppToCaseCenter(opp.Id,'343', null);
       MARLIN_CaseCenterCallout.updateCaseCenterApplicationStatus(opp.Id,'3434',null);
       MARLIN_CaseCenterCallout.updateCaseCenterApplicationStatus(opp.Id,'3434','123456789');
     System.debug('value==>'+ value);
       System.debug('value==>'+ value1);
       Test.stopTest();
   
    }
    
    
      static testMethod void testPostCallout2() {
       Test.startTest();
     Test.setMock(HttpCalloutMock.class, new MARLIN_CaseCenterCalloutMockImpl());
       Id oppLoanRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan Booking').getRecordTypeId();
       Account acc = [Select Id from Account Limit 1];
        Opportunity opp=new Opportunity(Name='Test opp',CloseDate=System.today()+30, 
                        AccountId=acc.Id,State_Tax_Code__c='MN',Tax_City__c='WOODBURY',Tax_ID__c='622666666',
                                      Tax_County__c = 'WASHINGTON', Tax_Exempt__c='Yes', Amount=33, Billing_Cycle__c='December',
                                      Recurring__c='Recurring Only', StageName='Application',  Equipment_Cost__c = 150 ,  Equipment_Description__c = 'test',
                                         Terms__c = 123, recordTypeId = oppLoanRecordTypeId, Primary_Source__c='Customer Outbound',   Annual_Revenue__c = 1200, Requested_Amount__c = 1000);
        insert opp;
        System.debug('Record !!!'+ opp);
     //Opportunity opp = [Select Id from Opportunity Where RecordTypeId = : oppLoanRecordTypeId Limit 1];
       String value = MARLIN_CaseCenterCallout.submitAppToCaseCenter(opp.Id);
       String value1 = MARLIN_CaseCenterCallout.submitUpdatedAppToCaseCenter(opp.Id,'343', null);
       MARLIN_CaseCenterCallout.updateCaseCenterApplicationStatus(opp.Id,'3434','3433');
     System.debug('value==>'+ value);
       System.debug('value==>'+ value1);
       Test.stopTest();
   
    }
    
    static testMethod void testMethod1() {
       Test.startTest();
       Opportunity opp = [Select Id from Opportunity limit 1];
       List<Guarantor__c> listOfGuarantor = [SELECT Id, Account__c, Contact__c, Contact__r.FirstName, Contact__r.SSN__c, Contact__r.LastName, Contact__r.Email, Contact__r.OtherStreet, Contact__r.OtherCity, Contact__r.OtherState, Contact__r.OtherStateCode, Contact__r.BirthDate, Contact__r.Ownership_Pct__c,  Opportunity__c, Type__c, RP_PRIN_GUAR_CODE__c 
                                             FROM Guarantor__c];
       String value1 = MARLIN_CaseCenterCallout.validateApplicationForSubmission(opp.Id);
       String guarantorReturnString = MARLIN_CaseCenterHelper.validateGuarantorFields(listOfGuarantor);
       System.debug('value1==>'+ value1);
       Test.stopTest();
    }
}