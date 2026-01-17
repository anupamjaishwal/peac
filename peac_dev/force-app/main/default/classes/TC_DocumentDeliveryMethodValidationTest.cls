@IsTest
public with sharing class TC_DocumentDeliveryMethodValidationTest {

    @TestSetup
    static void makeData(){
        Account acc = new Account (
            Name = 'test', 
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId()
        );
        insert acc;

        Account dealer = new Account(
            Name = 'dealer',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId(),
            Approved_Document_Delivery_Method__c = 'DocuSign Only'
        );
        insert dealer;
        
        Contact c = new Contact (
            AccountId = acc.Id, 
            FirstName = 'test', 
            LastName = 'contact', 
            MailingStreet = 'test', 
            MailingCity = 'test', 
            MailingStateCode = 'MN', 
            MailingPostalCode = '11111', 
            MailingCountry='United States', 
            Phone='5555555555',
            Title = 'title', 
            SSN__c = '111111111', 
            BirthDate = Date.today (), 
            Email = 'test123@test.com'
        );
        insert c;

        Opportunity opp = new Opportunity(
            AccountId = acc.Id,
            StageName = 'test',
            CloseDate = date.today () + 10,
            Name = 'test',
            Approved_Document_Delivery_Method__c = 'DocuSign or .pdf',
            recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('CVG Booking').getRecordTypeId()
        );
        Test.startTest();
        insert opp;
        opp.Document_Delivery_Method__c = 'PDF';
        opp.branch__c = 'Arrow';
        
        update opp;
        
        Dealer__c d = new Dealer__c(Opportunity__c = opp.Id, Dealer__c = dealer.Id, Primary_Dealer__c = false);
        insert d;
        Test.stopTest();
    }

    @IsTest
    public static void runtest() {

        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';

        Profile p = [SELECT Id FROM Profile WHERE Name='DataAdmin'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/New_York',
        UserName=uniqueUserName,  Doc_Fee_Exception_approver__c = false);
        insert u;

        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, Document_Delivery_Method__c, Branch__c FROM Opportunity]);
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>([SELECT Id, Document_Delivery_Method__c, Branch__c FROM Opportunity]);
         List<Dealer__c> dl = [Select Id from Dealer__c];
         
        Map<Id, List<Dealer__c>> dealers = new Map<Id, List<Dealer__c>>();
        for(Dealer__c deal : dl){
            dealers.put(deal.id,new List<Dealer__c>{deal});
        }
        for(Id key : newMap.keyset()){
            newMap.get(key).Document_Delivery_Method__c = 'PDF';
            newMap.get(key).Branch__c = 'NJ Retail';
        }

        System.runas(u){
            TC_DocumentDeliveryMethodValidation.documentDeliveryMethodValidation(oldMap, newMap,new Map<Id, List<Dealer__c>>());
            TC_DocumentDeliveryMethodValidation.documentDeliveryMethodValidation(oldMap, newMap,dealers);
        }

    }
}