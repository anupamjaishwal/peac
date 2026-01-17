@isTest
public with sharing class SL_OppContactsGuarantorsTest {
    @TestSetup
    static void makeData(){
        SL_SCTestData.createAccountAndContracts(2, 1);
        SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[0].Id, 1, 1);
        Test.startTest();
        User dpUser = null;
        System.runAs(SL_SCTestData.testUser){
            Account portalAccount = SL_SCTestData.testAccounts[1];
            dpUser = SL_SCTestData.createDPDataForUser(portalAccount);
        }
        Test.stopTest();
    }

    @isTest
    public static void scenario1() {
        Contact theContact = [SELECT Id, AccountId, FirstName, LastName, OtherStreet, OtherCity, 
                 OtherStateCode, OtherPostalCode, Title, SSN__c, BirthDate, Email, Validity_Verify__Status__c, Phone 
                 FROM Contact LIMIT 1];
        theContact.OtherCountryCode = 'US';
        String contactObj = JSON.serialize(theContact);
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        Test.startTest();
        User dpUser = [SELECT Id FROM User WHERE userName LIKE 'Portal.SL.test.user%' LIMIT 1];
        System.runAs(dpUser){
            SL_OppContactsGuarantors.hubExecute('saveOppContact', new List<String>{contactObj, oppId, 'false', 'true', 'true', 'false'});
            SL_SCTestData.testDupeId = theContact.Id;
            thecontact.Id = null;
            contactObj = JSON.serialize(theContact);
            SL_OppContactsGuarantors.hubExecute('saveOppContact', new List<String>{contactObj, oppId, 'true', 'false', 'false', 'true'});
            String wrapperObj = SL_OppContactsGuarantors.hubExecute('getAllContacts', new List<String>{theContact.AccountId, oppId});
            SL_OppContactsGuarantors.AllContactsWrapper contactsWrap = 
                (SL_OppContactsGuarantors.AllContactsWrapper)json.deserialize(wrapperObj, SL_OppContactsGuarantors.AllContactsWrapper.class);
            System.Assert.areEqual(1, contactsWrap.allContacts.size(), 'Must create one contact record');
            System.Assert.areEqual(true, contactsWrap.allContacts[0].isGuarantor, 'contact must be guarantor');
            thecontact.Id = SL_SCTestData.testDupeId;
            SL_OppContactsGuarantors.hubExecute('deleteOppContact', new List<String>{theContact.Id, oppId, 'true'});
            wrapperObj = SL_OppContactsGuarantors.hubExecute('getAllContacts', new List<String>{theContact.AccountId, oppId});
            contactsWrap = 
                (SL_OppContactsGuarantors.AllContactsWrapper)json.deserialize(wrapperObj, SL_OppContactsGuarantors.AllContactsWrapper.class);
            Test.stopTest();
            System.Assert.areEqual(0, contactsWrap.allContacts.size(), 'After deletion there are no records');
        }
    }
}