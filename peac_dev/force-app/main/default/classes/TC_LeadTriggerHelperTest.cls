// this test class exist so we can push the manual lead conversion stuff seperatly from the auto-batch

@isTest private class TC_LeadTriggerHelperTest {
    
    @testSetup static void setupData () {
        TC_LeadTestHelper.insertLead2 ();
        
    }
    static testmethod void leadConvertTest () {
         // Setup test data
        // Create a unique UserName
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='DataAdmin'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/New_York',
         UserName=uniqueUserName);

        System.runAs(u) {
              // The following code runs as user 'u'
              System.debug('Current User: ' + UserInfo.getUserName());
              System.debug('Current Profile: ' + UserInfo.getProfileId());
            Lead l = [Select Id FROM Lead WHERE Company = 'CompanyTest'][0];

        
        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(l.Id);
        lc.convertedStatus = 'Web Lead';
        
        Test.startTest();
        //Database.convertLead(lc);
        Test.stopTest();
          } 
        
        
    }
}