@isTest 

public class TC_LGHTNSendPaymentsCTRLTest {
    @testSetup public static void testSetup () {
        // SAL-6664 Misael Romero
        SL_SCTestData.createAccountAndContracts(2, 1);
        Account dealer = SL_SCTestData.testAccounts[0];
        Account acc = SL_SCTestData.testAccounts[1];
        dealer.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId();
        dealer.Equipment_Type__c = 'A/V (General)';
        dealer.Waiting_To_Be_Sent_To_Bridgeware__c = true;// this stops calls we don't need in the test
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Franchisee Account').getRecordTypeId();
        acc.Waiting_To_Be_Sent_To_Bridgeware__c = true;

        List<Account> accountsToUpdate = new List<Account>();
        accountsToUpdate.add(dealer);
        accountsToUpdate.add(acc);
        update accountsToUpdate; // SAL-2913 bulk insert accounts to avoid SOQL query limit

        Payee__c payee = new Payee__c (Dealer__c = dealer.Id, Address1__c = 'test', City__c = 'test', State__c = 'MN', Zip__c = '11111', Email__c = 'test@test.com', SL_Vendor_ID__c = 'test');
        insert payee;

        Opportunity opp = new Opportunity (Name = 'checklistTest', StageName = 'test', CloseDate = Date.today () + 10,
                                           AccountId = acc.Id, Primary_Source__c = 'Direct Mail',
                                           recordtypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan Docs').getRecordTypeId(), 
                                           Stipulations__c = 'Municipal addendum',Equipment_Cost__c = 20);
        List<Asset__c> assetLst = new List<Asset__c>();
         Asset__c asset = new Asset__c (Equipment_Code__c = 'Fitness',Equipment_Sub_Category__c = 'Fitness',
                        List_Price__c = 3000, Equipment_City__c = 'narnia',
                        Equipment_Street__c = '1 st');
        Asset__c asset1 = new Asset__c ( Equipment_Code__c='Computer Hardware(Gen)',List_Price__c = 3001, Equipment_City__c = 'narnia',
                        Equipment_Street__c = '2 nd');
                    
                
            
        
        
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg1.com';
		Map<String,String> profileMap = new Map<String, String>();
        List<Profile> p = [SELECT Id,Name FROM Profile WHERE Name IN ('CMS','SDR')];
        for(profile pp : p){
            profileMap.put(pp.Name,pp.Id);
        }
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = profileMap.get('CMS'),
        TimeZoneSidKey='America/New_York',CMS_Credit_Authority_Lease__c = 7500,
        UserName=uniqueUserName, Vendor_Team__c = 'IFP', Doc_Fee_Exception_approver__c = false);
        insert u;
        system.runAs(u){
        Test.startTest();
        insert opp;
           
        asset.Opportunity__c = opp.Id;
            //asset1.Opportunity__c = opp.Id;
            assetLst.add(asset);
           // assetLst.add(asset1);
        insert assetLst;
        Payment__c payment = new Payment__c (Payment_Status__c = 'Ready to Send', Opportunity__c = opp.Id, Payee__c = payee.Id);
        insert payment; 
        
        Payment__c draftPayment = new Payment__c (Payment_Status__c = 'Ready to Send', Opportunity__c = opp.Id, Payee__c = payee.Id);
        insert draftPayment;      
            Test.stopTest();
        }
    }
    
    @isTest public static void sendPaymentTest () {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock ();
        mock.setStaticResource('TC_tam_sendpayment_resp');   
        mock.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        try {
            TC_LGHTNSendPaymentsCTRL.sendPayments ([SELECT Id,Opportunity__c FROM Payment__c WHERE Payment_Status__c = 'Ready to Send'][0].Opportunity__c );
            TC_LGHTNSendPaymentsCTRL.sendPayments ([SELECT Id,Opportunity__c FROM Payment__c WHERE Payment_Status__c = 'Ready to Send'][0].Id );
            TC_LGHTNSendPaymentsCTRL.sendPayments ([SELECT Id FROM Payment__c WHERE Payment_Status__c = 'Ready to Send'][0].Opportunity__c );
            TC_LGHTNSendPaymentsCTRL.throwException('testException');
        } catch (Exception e) {
            System.debug (e);
        }
        Test.stopTest();

        
    }
    
    @isTest public static void sendPaymentTest1 () {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock ();
        mock.setStaticResource('TC_tam_sendpayment_resp');   
        mock.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, mock);
        
        String uniqueUserName = 'standarduser1' + DateTime.now().getTime() + '@testorg1.com';
       Profile p = [SELECT Id,Name FROM Profile WHERE Name ='SDR'];
       
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/New_York',CMS_Credit_Authority_Lease__c = 7500,
        UserName=uniqueUserName, Vendor_Team__c = 'IFP', Doc_Fee_Exception_approver__c = false);
        insert u;
        system.runAs(u){
        Test.startTest();
        
        try {
            TC_LGHTNSendPaymentsCTRL.sendPayments ([SELECT Id,Opportunity__c FROM Payment__c WHERE Payment_Status__c = 'Ready to Send'][0].Opportunity__c );
            TC_LGHTNSendPaymentsCTRL.sendPayments ([SELECT Id,Opportunity__c FROM Payment__c WHERE Payment_Status__c = 'Ready to Send'][0].Id );
            
        } catch (Exception e) {
            System.debug (e);
        }
        Test.stopTest();
        }
        
    }
    
    @isTest public static void sendDraftTest () {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock ();
        mock.setStaticResource('TC_tam_sendpayment_resp');   
        mock.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        try {
            TC_LGHTNSendPaymentsCTRL.sendPayments ([SELECT Id,opportunity__c FROM Payment__c WHERE Payment_Status__c = 'Ready to Send'][0].Id);
            TC_LGHTNSendPaymentsCTRL.throwException('abc');
        } catch (Exception e) {
            System.debug (e);
        }
        Test.stopTest();

        
    }
}