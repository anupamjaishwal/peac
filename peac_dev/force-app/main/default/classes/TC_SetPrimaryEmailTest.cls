@IsTest
public with sharing class TC_SetPrimaryEmailTest {
    
    @TestSetup
    static void makeData(){
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
            Name = 'test'
        );
        insert opp;
        
        OpportunityContactRole role3 = new OpportunityContactRole();
        role3.ContactId = c.Id;
        role3.OpportunityId = opp.Id;
        role3.Role = 'Dealer Primary Contact';
        insert role3;
        
    }

    @IsTest
    public static void runTest(){

        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, CaseCenter__c, Portal_App_Completed__c, Primary_Contact_Email__c, Primary_Contact_Name__c FROM Opportunity]);
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();
        Map<Id, List<OpportunityContactRole>> contactRoles = new Map<Id, List<OpportunityContactRole>>();
        OpportunityContactRole role = new OpportunityContactRole(
            ContactId = [SELECT Id FROM Contact LIMIT 1].Id,
            Role = 'Primary Contact',
            IsPrimary = true
        );
        
        
        for(Opportunity opp : [SELECT Id, (SELECT ID, Role, ContactId, IsPrimary, OpportunityId, Contact.Receive_All_Notifications__c, Contact.Email,
                Contact.Name, Contact.Emailage_Result__c, Contact.Override_Emailage_Result__c
                FROM OpportunityContactRoles) FROM Opportunity WHERE Id IN :oldMap.keySet()]){
                
           contactRoles.put(opp.Id, new List<OpportunityContactRole>());
           contactRoles.get(opp.Id).addAll(opp.OpportunityContactRoles);
        }

        for(Id key : oldMap.keyset()){
            Opportunity o = new Opportunity(Id = key, CaseCenter__c = 'test', Portal_App_Completed__c = true);
            newMap.put(key, o);
            role.OpportunityId = key;
        }
        insert role;

        TC_SetPrimaryEmail.setPrimaryEmail(oldMap, newMap, contactRoles);
    }
}