/**
 * Created by trohweder on 10/5/20.
 */
@IsTest
public with sharing class TC_LeadStatusChangeTest {
    @TestSetup
    public static void testSetup(){
        Lead l = new Lead (
                // required fields for standard objects
                LastName = 'LeadStatusTest',
                FirstName = 'Test',
                Company = 'LeadStatusTest',
                Lead_Type__c = 'End User',
                LeadSource = 'Banner Ad',
                Do_Not_Sync_to_Marketo__c = true
        );

        insert l;
        Map<String, Id> profileNameToId = new Map<String, Id>();
        for (Profile p : [SELECT Id, Name FROM Profile]) {
            profileNameToId.put(p.Name, p.Id);
        }
        //Updating the logic here per SAL-2551 to use profiles instead of vendor teams to distinguish between BFA and SDR
        User u = new User(Alias = 'standt', Email = 'testFeedItemDelete@testorg.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Testing',
                LanguageLocaleKey = 'fr',
                LocaleSidKey = 'en_US',
                ProfileId = profileNameToId.get('SDR'),
                TimeZoneSidKey = 'America/Los_Angeles',
                Username = 'testFeedItemDeleteNew@testorg.com');

        insert u;

        User u2 = new User(Alias = 'standt2', Email = 'testFeedItemDelete2@testorg.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Testing2',
                LanguageLocaleKey = 'fr',
                LocaleSidKey = 'en_US',
                ProfileId = profileNameToId.get('Express Rep'),
                TimeZoneSidKey = 'America/Los_Angeles',
                Username = 'testFeedItemDeleteNew2@testorg.com');


        insert u2;
    }
    @IsTest
    public static void testLeadOwnerChanges(){


        Lead test = [SELECT Id, Status, OwnerId FROM Lead WHERE Company = 'LeadStatusTest' LIMIT 1];

        System.assertEquals('Unassigned', test.Status);
        System.debug('Unassigned test passed');


        User u = [SELECT Id FROM User WHERE LastName = 'Testing' LIMIT 1];
        User u2 = [SELECT Id FROM User WHERE LastName = 'Testing2' LIMIT 1];
        test.OwnerId = u.Id;
        update test;


        Lead test2 = [SELECT Id, Status, OwnerId, IsConverted, fml_LeadClosed__c FROM Lead WHERE Company = 'LeadStatusTest' LIMIT 1];

        System.debug(test2.Status + ' + ' + test2.IsConverted + '=' + test2.fml_LeadClosed__c);

        System.assertEquals('Prospecting', test2.Status);
        System.debug('Prospecting test passed');

        test2.OwnerId = u2.Id;

        update test2;

        Lead test3 = [SELECT Id, Status, OwnerId FROM Lead WHERE Company = 'LeadStatusTest' LIMIT 1];

        System.assertEquals('Prospecting', test3.Status);

    }
 
}