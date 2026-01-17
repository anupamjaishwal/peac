@isTest
public with sharing class pEAC_FetchAccountDetailsTest {
    private static final String OEG_DEALER_PROFILE = 'OEG Dealer';
    private static final String USERNAME = 'Portal.SL.test.user@silverlinecrm.com';
    @isTest
    public static void scenario1() {
        Account portalAccount = new Account(name = 'portalAccount', Business_Phone__c = '1234567890');//create a portal account first
        INSERT portalAccount;
        Contact portalContact = new contact(LastName = 'portalContact', FirstName = 'Test', AccountId = portalAccount.Id); //create a portal contact
        INSERT portalContact;
        User u = new User(Alias = 'testuser', Email = 'marlinbusiness@peacsolutions.com', EmailEncodingKey='UTF-8',
              LastName = 'testing', FirstName = 'user', LanguageLocaleKey = 'en_US',
              LocaleSidKey = 'en_US', ProfileId = [SELECT Id, Name FROM Profile WHERE Name = :OEG_DEALER_PROFILE].Id, TimeZoneSidKey = 'America/Los_Angeles',
              Username = USERNAME, Doc_Fee_Exception_Approver__c = true, PortalRole = 'Manager', ContactId = portalContact.Id,
              IsPrmSuperUser = true);
        INSERT u;
        System.runAs(u){
            Account acc = pEAC_FetchAccountDetails.getFastTrackURL();
            Boolean containsId = acc.ID == portalAccount.Id;
            Assert.isTrue(containsId); 
        }
        
    }
}