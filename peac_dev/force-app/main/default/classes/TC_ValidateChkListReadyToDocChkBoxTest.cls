@IsTest
public with sharing class TC_ValidateChkListReadyToDocChkBoxTest {

    @TestSetup
    static void makeData(){



        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';

        Profile p = [SELECT Id FROM Profile WHERE Name='DataAdmin'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/New_York',
        UserName=uniqueUserName, Vendor_Team__c = 'NJI');

        insert u;

        Account acc = new Account (
            Name = 'test', 
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId()
        );
        insert acc;
        
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
            OwnerId = u.Id
        );
        insert opp;
    }

    @IsTest
    public static void runTest(){

        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, Ready_to_Doc__c, Channel__c FROM Opportunity]);
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>([SELECT Id, Ready_to_Doc__c, Channel__c FROM Opportunity]);

        Test.startTest();
        for(Id key : oldMap.keyset()){
            newMap.get(key).Ready_to_Doc__c = 'Yes';
        
            TC_Origination__Checklist_Template__c template = new TC_Origination__Checklist_Template__c();
            template.Name = 'Credit Stips';
            insert template;

            TC_Origination__Checklist__c checklist = new TC_Origination__Checklist__c();
            checklist.Name = 'test checklist';
            checklist.TC_Origination__Opportunity__c = key;
            checklist.TC_Origination__Checklist_Template__c = template.Id;
            
            insert checklist;

            TC_Origination__Checklist_Item_with_Attachments__c item = new TC_Origination__Checklist_Item_with_Attachments__c();
            item.Name = 'test item';
            item.TC_Origination__Checklist__c = checklist.Id;
            item.TC_Origination__Included__c = true;
            item.TC_Origination__Checklist_s_Opportunity__c = key;
            item.TC_Origination__Primary_Reviewer__c = true;
            item.TC_Origination__Category__c = 'Pre-Doc';

            insert item;
        }
        Test.stopTest();
        TC_ValidateChkListReadyToDocChkBox.validateCreditChecklistReadyToDocCheckbox(oldMap, newMap);
    }
}