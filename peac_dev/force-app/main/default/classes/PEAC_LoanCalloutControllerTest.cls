/********************************************************************************************************************
@Author:Vinod Rathod(LTIMindtree)
@Description: This test class is used to validate and process data to GDS,Onbase and Ocrolus application for loan opportunity
@User Story:SAL-5460
@Created Date:July-18-2024 	    
*********************************************************************************************************************/
@isTest
public class PEAC_LoanCalloutControllerTest {
    
    static Id personalRecordTypeId = Schema.SObjectType.Guarantor__c.getRecordTypeInfosByName().get('Personal').getRecordTypeId();
    static Id corpRecordTypeId = Schema.SObjectType.Guarantor__c.getRecordTypeInfosByName().get('Corporate').getRecordTypeId();
    static Id brokerRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker Account').getRecordTypeId();
    static Id franchiseRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Franchisor Account').getRecordTypeId();
    static Id dealerRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId();


    @TestSetup
    static void testSetup(){
        User ifpRep = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'IFP Rep'].Id,
            LastName = 'last',
            Email = 'test@marlincapitalsolutions.com',
            Username = 'test@marlincapitalsolutions.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            );

        insert ifpRep;



        User systemAdmin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = TRUE LIMIT 1];

        System.runAs(systemAdmin)
        {

            insert new DeactivateTriggers__c(Name = 'opportunityTrigger', IsDeactived__c = true, ObjectName__c = 'Opportunity');
            insert new DeactivateTriggers__c(Name = 'AccountContactRelTrigger', IsDeactived__c = true, ObjectName__c ='Account Contact Relationship');
            insert new DeactivateTriggers__c(Name = 'OpportunityDocGenTrigger', IsDeactived__c = true, ObjectName__c = 'Opportunity');
            insert new DeactivateTriggers__c(Name = 'TC_AccountTrigger', IsDeactived__c = true, ObjectName__c = 'Account');
            insert new DeactivateTriggers__c(Name = 'TC_ContactTrigger', IsDeactived__c = true, ObjectName__c = 'TC_ContactTrigger');
            insert new DeactivateTriggers__c(Name = 'TC_Lead', IsDeactived__c = true, ObjectName__c = 'TC_Lead');
            insert new DeactivateTriggers__c(Name = 'TC_OpportunityTrigger', IsDeactived__c = true, ObjectName__c = 'Opportunity');
            insert new Marlin_Configuration__c(Name = 'test', Disable_Standard_Asset_Generation__c = true,  Apex_Validations_Active__c = false);
            //insert new SL_Trigger_Settings__c(Name = 'default', KillSwitch__c = true, KillList__c = 'Account Opportunity');



            Bridgeware_Service_Setting__c setting = new Bridgeware_Service_Setting__c ();
            setting.Enable_Debug_Log__c = true;
            setting.Mock_Callout__c = true;
            setting.Mock_Endpoint__c = 'https://private-b2bb6-bridgewaretamarack.apiary-mock.com/';
            setting.SetupOwnerId = UserInfo.getOrganizationId ();
            setting.Config_Name__c = 'TEST';
            insert setting;



            insert new Quick_App_Settings__c (Broker_Record_Type_Label__c = 'Broker Account'
                                              , CCG_Junction_Record_Type_Label__c = 'Corporate'
                                              , Dealer_Record_Type_Label__c = 'Dealer Account'
                                              , End_User_Record_Type_Label__c = 'End User Account'
                                              , Franchiosor_Record_Type_Label__c = 'Franchisor Account'
                                              , PG_Junction_Record_Type_Label__c = 'Personal');

			list<Account> accList = new list<Account>();
            Account acct = new Account(Name='Test', CCAN__c='111111', Tax_ID__c='111111111');
            accList.add(acct);
            //insert acct;

            Account acct2 = new Account(Name='Test', RecordTypeId = brokerRecTypeId,CCID__c = 'C989786');
            //insert acct2;
			accList.add(acct2);
            Account acct3 = new Account(Name='Test',  RecordTypeId = franchiseRecTypeId,CCID__c = 'C989789');
            //insert acct3;
            accList.add(acct3);

            Account acct4 = new Account(Name='Test',  RecordTypeId = dealerRecTypeId, Points__c = '1',CCID__c = 'C980786');
            //insert acct4;
            accList.add(acct4);
            insert accList;
            Contact contact = new Contact(FirstName='John', LastName='Smith', OK_to_Pull_Credit__c = true, ssn__c = '111111111', AccountId=acct4.Id, phone='888-999-8889', Email='test@test.com', MailingStreet = '123 example street', MailingCity = 'Saint Paul', MailingStateCode = 'MN',OtherCity = 'Saint Paul', OtherStreet = '123 example street', OtherStateCode = 'MN', MailingPostalCode = '55110', OtherPostalCode = '55110', Birthdate = Date.newInstance(1990, 1, 1), Ownership_Pct__c = 99 );
            insert contact;
			test.StartTest();
            Opportunity opp = new Opportunity (Name = 'oppp',  Fraud_PG_Required__c =1, Annual_Revenue__c = 1000000, Requested_Amount__c = 250000, Oppt_FS_Use_Of_Funds__c = 'test', StageName = 'Application', Points__c = 1, CloseDate = Date.today () + 10, AccountId = acct.Id, Primary_Source__c = 'Direct Mail', RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan Opportunity').getRecordTypeId(), Application_Status__c = 'Manually Approved', Advance_Rental_Amount__c = null,  Application__c = 'test', Equipment_Cost__c = 5000, Equipment_Description__c = 'test', Payment_Amount__c = 0, of_Payments__c = 12, Required_Adv_Payments__c = 0, of_beginning_payments__c = 1, Documentation_Fee__c = 200, of_ending_payments__c = 1, Document_Delivery_Method__c = 'DocuSign', Estimated_Funding_Month__c = 'January', Sec_Dep_Pymts__c = 200,  Account_Billing_Street__c = 'test', Loan_Purpose__c = 'testing');
            opp.Payment_Frequency__c = 'Weekly';
            insert opp;

            List<Guarantor__c> guarantors = new List<Guarantor__c>();
            guarantors.add(new Guarantor__c(RecordTypeId = personalRecordTypeId, Opportunity__c = opp.Id, Contact__c = contact.Id, PG_Number__c = 'PG1'));
            //guarantors.add(new Guarantor__c(RecordTypeId = corpRecordTypeId, Opportunity__c = opp.Id, Account__c = acct.Id,PG_Number__c = 'PG2'));
            insert guarantors;

            List<Broker__c> brokers = new List<Broker__c>();
            brokers.add(new Broker__c(Opportunity__c = opp.Id, Account__c = accList[1].Id));
            insert brokers;

            List<Franchisor__c> franchisors = new List<Franchisor__c>();
            franchisors.add(new Franchisor__c(Opportunity__c = opp.Id,  Franchisor__c = accList[2].Id));
            insert franchisors;

            List<Dealer__c> dealers = new List<Dealer__c>();
            dealers.add(new Dealer__c(Opportunity__c = opp.Id,  Dealer__c = accList[3].Id, Primary_Dealer__c = false));
            insert dealers;

            OpportunityContactRole ocr = new OpportunityContactRole();
            ocr.OpportunityId = opp.Id;
            ocr.ContactId = contact.Id;
            ocr.IsPrimary = true;
            ocr.Role = 'Dealer Primary Contact';
            insert ocr;

            insert new Webservice_Field__c(Opportunity__c = opp.Id);
            
            Opportunity_Attachment__c att = new Opportunity_Attachment__c(
            Name = 'Bank Statement',
            Opportunity__c = opp.Id,
            Type__c = 'FS - Bank Statements'
        );
        insert att;
            test.StopTest();
        }
    }
    
    @isTest
    static void testValidateApplicationForSubmission_success() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.CaseCenter__c = null;
        update opp;
        Guarantor__c g = [SELECT Id,SSN__c,Contact__r.SSN__c FROM Guarantor__c WHERE Opportunity__c = : opp.Id LIMIT 1];
        
        System.debug('Opportunity record Test method'+opp);
        System.debug('Guarantor__c record Test method'+g);        
        Test.startTest();
        String result = PEAC_LoanCalloutController.validateApplicationForSubmission(opp.Id);
        Test.stopTest();
        //System.assertEquals('Success', result);
        
    }
    @isTest
    static void testValidateApplicationForSubmission_failure() {
        // Create an Opportunity without setting required fields
        Opportunity opp = [SELECT Id,Name,StageName FROM Opportunity LIMIT 1];
        
        Test.startTest();
        String result = PEAC_LoanCalloutController.validateApplicationForSubmission(opp.Id);
        Test.stopTest();
        System.assert(result.startsWith('Fail'), 'Validation should fail due to missing fields');
    }
    @isTest
    static void testSubmitAppToGDS() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        // Setup Opportunity for submission
        Opportunity opp = [SELECT Id, CaseCenter__c FROM Opportunity LIMIT 1];
        opp.CaseCenter__c= null;
        update opp;
        String result = PEAC_LoanCalloutController.submitAppToGDS(opp.Id);
        
        System.debug('Opportunity record Test method'+ opp + 'Result conatain application number'+result);   
        Test.stopTest();
        
        System.assert(result.contains('Application Number'), 'Response should contain application number text');
    }
    
    @isTest
    static void testPGValidation() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        // Setup Opportunity for submission
        Opportunity opp = [SELECT Id, CaseCenter__c FROM Opportunity LIMIT 1];
        opp.CaseCenter__c= null;
        update opp;
        List<Guarantor__c> guarantors = new List<Guarantor__c>();
        guarantors.add(new Guarantor__c(RecordTypeId = personalRecordTypeId, Opportunity__c = opp.Id));

        String result = PEAC_LoanCalloutController.validateGuarantorFields(guarantors);
        System.debug('Opportunity record Test method'+ opp + 'Result conatain application number'+result);   
        Test.stopTest();
        
       // System.assert(result.contains('Application Number'), 'Response should contain application number text');
    }
    
}