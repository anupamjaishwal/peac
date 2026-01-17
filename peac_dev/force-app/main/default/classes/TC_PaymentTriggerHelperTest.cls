@isTest public class TC_PaymentTriggerHelperTest {

    @TestSetup
    static void setup() {
        
        Marlin_Configuration__c config = Marlin_Configuration__c.getOrgDefaults ();
        config.Enable_Auto_Move_to_Booking__c = true;
        insert config;
        
        Account acc = new Account (Name = 'test', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Franchisee Account').getRecordTypeId(), Business_Address__c = 'test', Business_Phone__c = '1234567890');
        insert acc;
        
        Contact primary = new Contact (FirstName = 'test', LastName = 'test2', Email = 'test@test.com', AccountId = acc.Id);
        insert primary;
        
        Test.startTest();
        Contact billing = new Contact (FirstName = 'test', LastName = 'test2', AccountId = acc.Id);
        insert billing;
        
        Account dealer = new Account (Name = 'dealer', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId(), Equipment_Type__c = 'A/V (General)');
        insert dealer;
        Test.stopTest();
    }
    
    @isTest public static void updateOppStageTest () {
       
        Account acc = [SELECT Id FROM Account WHERE Name = 'test'];
        Account dealer = [SELECT Id FROM Account WHERE Name = 'dealer'];
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'][0];
        
        String uniqueUserName = 'dataadmin' + DateTime.now().getTime() + '@testorg.com';
        User u = new User(Alias = 'dadmin', Email='dataadmin@testorg.com',EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',LocaleSidKey='en_US', ProfileId = p.Id,TimeZoneSidKey='America/Los_Angeles',UserName=uniqueUserName);
        System.runAs(u) {
            
            RecordType rt2 = [select id,Name from RecordType where SobjectType='Opportunity' and Name LIKE '%Express%' Limit 1];
            Opportunity opp = new Opportunity (Name = 'checklistTest', StageName = 'Decision', CloseDate = Date.today () + 10, AccountId = acc.Id, Primary_Source__c = 'Direct Mail', RecordTypeId = rt2.Id, Application_Status__c = 'Manually Approved', Application__c = 'test', Equipment_Cost__c = 5000, Equipment_Description__c = 'test', Payment_Amount__c = 5000, of_Payments__c = 12);
            Test.startTest();
            insert opp;
            
            Payee__c payee = new Payee__c (Dealer__c = dealer.Id, Address1__c = 'test', City__c = 'test', State__c = 'MN', Zip__c = '11111', Email__c = 'test@test.com', SL_Vendor_ID__c = 'test');
            insert payee;
            
            Payment__c payment = new Payment__c (Payment_Status__c = 'Draft', Opportunity__c = opp.Id, Payee__c = payee.Id);
            
            insert payment; 
            Test.stopTest();
            payment.Payment_Status__c = 'Payment Confirmed';
            update payment;
            
            
        }
    }
    @IsTest public static void deleteAsCMS() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'test'];
        Account dealer = [SELECT Id FROM Account WHERE Name = 'dealer'];
        Profile p = [SELECT Id FROM Profile WHERE Name = 'CMS' LIMIT 1];
        String error;

        String uniqueUserName = 'dataadmin' + DateTime.now().getTime() + '@testorg2.com';
        User u = new User(Alias = 'dadmin', Email = 'dataadmin@testorg.com', EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = uniqueUserName);
        System.runAs(u) {

            RecordType rt2 = [select id,Name from RecordType where SobjectType = 'Opportunity' and Name LIKE '%Express%' Limit 1];
            Opportunity opp = new Opportunity (Name = 'checklistTest', StageName = 'Decision', CloseDate = Date.today () + 10, AccountId = acc.Id, Primary_Source__c = 'Direct Mail', RecordTypeId = rt2.Id, Application_Status__c = 'Manually Approved', Application__c = 'test', Equipment_Cost__c = 5000, Equipment_Description__c = 'test', Payment_Amount__c = 5000, of_Payments__c = 12);
            Test.startTest();
            insert opp;

            Payee__c payee = new Payee__c (Dealer__c = dealer.Id, Address1__c = 'test', City__c = 'test', State__c = 'MN', Zip__c = '11111', Email__c = 'test@test.com', SL_Vendor_ID__c = 'test');
            insert payee;

            Payment__c payment = new Payment__c (Payment_Status__c = 'Draft', Opportunity__c = opp.Id, Payee__c = payee.Id, Date_Sent_to_External_System__c = Datetime.now());

            insert payment;
            Test.stopTest();
            try{
                delete payment;
            }catch (Exception e){
                System.assertEquals(true,
                e.getMessage().contains('CMS should not be able to use the "Delete" function on the payment object after they have Sent to Solomon.'));
            }
        }
    }
}