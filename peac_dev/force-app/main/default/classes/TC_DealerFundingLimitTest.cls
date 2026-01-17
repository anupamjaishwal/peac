@isTest
public class TC_DealerFundingLimitTest{
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


            Account acct = new Account(Name='Test', CCAN__c='111111', Tax_ID__c='111111111');
            insert acct;
            Opportunity opp = new Opportunity (Name = 'oppp',  Fraud_PG_Required__c =1, Annual_Revenue__c = 1000000, Requested_Amount__c = 250000, Oppt_FS_Use_Of_Funds__c = 'test', StageName = 'Decision', Points__c = 1, CloseDate = Date.today () + 10, AccountId = acct.Id, Primary_Source__c = 'Direct Mail', RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan Opportunity').getRecordTypeId(), Application_Status__c = 'Manually Approved', Advance_Rental_Amount__c = null,  Application__c = 'test', Equipment_Cost__c = 5000, Equipment_Description__c = 'test', Payment_Amount__c = 0, of_Payments__c = 12, Required_Adv_Payments__c = 0, of_beginning_payments__c = 1, Documentation_Fee__c = 200, of_ending_payments__c = 1, Document_Delivery_Method__c = 'DocuSign', Estimated_Funding_Month__c = 'January', Sec_Dep_Pymts__c = 200,  Account_Billing_Street__c = 'test', Loan_Purpose__c = 'testing');
            opp.Payment_Frequency__c = 'Weekly';
            insert opp;
        
        }
    }
    static testMethod void DealerFundingLimit(){

        
        test.startTest();
        TC_DealerFundingLimit.dummyMethod();
        test.stopTest();
    }
    
}