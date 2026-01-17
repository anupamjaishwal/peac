@isTest public class TC_OpportunityAssetTriggerHelperTest {

    @testSetup public static void oppTestSetup1 () {
        Bridgeware_Service_Setting__c setting = new Bridgeware_Service_Setting__c ();
        setting.Enable_Debug_Log__c = true;
        setting.Mock_Callout__c = true;
        setting.Mock_Endpoint__c = 'https://private-b2bb6-bridgewaretamarack.apiary-mock.com/';
        setting.SetupOwnerId = UserInfo.getOrganizationId ();
        setting.Config_Name__c = 'TEST';
        insert setting;
        Test.startTest();
        Account acc = new Account (Name = 'test', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Franchisee Account').getRecordTypeId(), Business_Address__c = 'test', Business_City__c = 'test', Business_State__c = 'MN', Business_Zip__c = '11111', Business_Phone__c = '1234567890');
        insert acc;
        
        
        
        Marlin_Configuration__c config = Marlin_Configuration__c.getOrgDefaults ();
        config.Static_Standard_Asset_Account_Id__c = acc.Id;
        insert config;
        
        Account dealer = new Account (Name = 'dealer', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId(), Equipment_Type__c = 'A/V (General)');
        
        insert dealer;
        Test.stopTest();
        Opportunity opp = new Opportunity (Name = 'checklistTest', StageName = 'Decision', CloseDate = Date.today () + 10, AccountId = acc.Id, Primary_Source__c = 'Direct Mail', RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Express Application').getRecordTypeId(), Application_Status__c = 'Manually Approved', Application__c = 'test', Equipment_Cost__c = 5000, Equipment_Description__c = 'test', Payment_Amount__c = 0, of_Payments__c = 12, Required_Adv_Payments__c = 0, of_beginning_payments__c = 1, Documentation_Fee__c = 200, of_ending_payments__c = 1, Document_Delivery_Method__c = 'DocuSign', Estimated_Funding_Month__c = 'January', Sec_Dep_Pymts__c = 200,  Account_Billing_Street__c = 'test');
        opp.Payment_Frequency__c = 'Monthly';
        insert opp;
            
        Asset__c asset = new Asset__c (Quantity__c = 1, End_User_Billing_Address__c = true, List_Price__c = 5000, Opportunity__c = opp.Id, Equipment_Code__c = '2 Way Radios');
        //insert asset;
    }

    @isTest public static void oppTest1 () {
        
        Account acc = [SELECT Id FROM Account WHERE Name = 'test'];
        Opportunity opp = [Select Id FROM Opportunity WHERE Name = 'checklistTest'][0];
        Profile p = [SELECT Id FROM Profile WHERE Name='DataAdmin'][0];
        Account dealer = [Select id from Account WHERE Name = 'dealer'][0];
        
        Contact primary = new Contact (FirstName = 'test', LastName = 'test2', Email = 'test@test.com', AccountId = acc.Id);
        insert primary;
        
        
        Contact billing = new Contact (FirstName = 'test', LastName = 'test2', AccountId = acc.Id);
        insert billing;
        
        String uniqueUserName = 'dataadmin' + DateTime.now().getTime() + '@testorg.com';
        User u = new User(Alias = 'dadmin', Email='dataadmin@testorg.com',EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',LocaleSidKey='en_US', ProfileId = p.Id,TimeZoneSidKey='America/Los_Angeles',UserName=uniqueUserName);
        System.runAs(u) {
            
            Test.startTest();
            
            Dealer__c dealerRec = new Dealer__c (Dealer__c = dealer.Id, Opportunity__c = opp.Id);
        //    insert dealerRec;
            
            insert new OpportunityContactRole (ContactId = primary.Id, Role = 'Primary Contact', OpportunityId = opp.Id);
            insert new OpportunityContactRole (ContactId = billing.Id, Role = 'Billing Contact', OpportunityId = opp.Id);
            
            
            opp.StageName = 'Docs Requested';
            opp.Variable_Payment__c = true;
            opp.Ready_to_Doc__c = 'Yes';
            
        
            Test.setMock(HttpCalloutMock.class, new TC_BridgewareBookContractCalloutMockImpl ());
            
            
         //   update opp;
            
            Variable_Payment__c vp = new Variable_Payment__c (Opportunity__c = opp.Id, Payment_Amount__c = 5000, of_payments__c = 12);
            insert vp;
            //delete vp;
            Test.stopTest();
        }
        
    }
    
    @isTest public static void variablePaymentTest () {
      //  Test.setMock(HttpCalloutMock.class, new TC_BridgewareBookContractCalloutMockImpl ());
        Test.startTest();
         Opportunity opp = [Select Id FROM Opportunity WHERE Name = 'checklistTest'][0];
        Variable_Payment__c vp = new Variable_Payment__c (Payment_Amount__c = 5000, of_payments__c = 12);
        insert vp;
        update vp;
        delete vp;
        
        Test.stopTest();
    }



}