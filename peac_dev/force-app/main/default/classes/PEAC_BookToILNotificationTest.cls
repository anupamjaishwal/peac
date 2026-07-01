@IsTest
public class PEAC_BookToILNotificationTest {

    @IsTest
    static void test_sendBookToILConfn_success_and_failure_paths() {
        // --- Create a user whose Username contains the DataLoader label value
        String dlMarker = System.Label.PEAC_DataLoaderUser;
        System.assert(!String.isBlank(dlMarker), 'PEAC_DataLoaderUser label must not be blank for this test.');
		
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        // Username MUST be unique in org; include timestamp
        String uniqueUname = 'dl.' + dlMarker + '.' + DateTime.now().getTime() + '@test.com';

        User dlUser = new User(
            FirstName = 'Data',
            LastName  = 'Loader',
            Alias     = 'dload',
            Email     = 'dl@test.com',
            Username  = uniqueUname,              // contains dlMarker
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey   = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert dlUser;

        // --- Run as DataLoader-like user so if condition passes
        System.runAs(dlUser) {

            // TargetObjectId must be a valid Id (User/Contact/Lead). We use our user Id.
            Id targetUserId = dlUser.Id;

            // -------------------------
            // Scenario 1: "Booked to IL" success branch
            // Conditions:
            // - Application_Status__c changed and new is non-null
            // - Contract__c changed and new is non-null
            // - Opportunity_Booked_Date__c null => should be set
            // - Booked_Amount__c null => should default to Equipment_Cost__c
            // -------------------------
            Opportunity oldOpp1 = new Opportunity(
                Id = '006000000000001AAA',
                Application_Status__c = 'OldStatus',
                Contract__c = 'OldContract'
            );

            Opportunity newOpp1 = new Opportunity(
                Id = oldOpp1.Id,
                Application_Status__c = 'NewStatus',
                Contract__c = 'NewContract',
                Equipment_Cost__c = 1234,
                Opportunity_Booked_Date__c = null,
                Booked_Amount__c = null,
                Booked_to_External_System_User__c = targetUserId
            );

            // -------------------------
            // Scenario 2: "Book to IL failed" branch
            // Conditions:
            // - Book_to_InfoLease_Error__c changed and new is non-null
            // -------------------------
            Opportunity oldOpp2 = new Opportunity(
                Id = '006000000000002AAA',
                Book_to_InfoLease_Error__c = null
            );

            Opportunity newOpp2 = new Opportunity(
                Id = oldOpp2.Id,
                Book_to_InfoLease_Error__c = 'Some failure occurred',
                Booked_to_External_System_User__c = targetUserId
            );

            List<Opportunity> newList = new List<Opportunity>{ newOpp1, newOpp2 };
            Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{
                oldOpp1.Id => oldOpp1,
                oldOpp2.Id => oldOpp2
            };

            Test.startTest();
            PEAC_BookToILNotification.sendBookToILConfn(newList, oldMap);
            Test.stopTest();

            // --- Assert in-memory field updates for success scenario
            System.assertNotEquals(null, newOpp1.Opportunity_Booked_Date__c,
                'Opportunity_Booked_Date__c should be set when booking happens.');

            System.assertEquals(1234, newOpp1.Booked_Amount__c,
                'Booked_Amount__c should default to Equipment_Cost__c when null.');

            System.assertNotEquals(null, newOpp1.Booked_to_External_System_Date__c,
                'Booked_to_External_System_Date__c should be set when booking happens.');
        }
    }

    @IsTest
    static void test_sendEmailNotification_blank_toAddress_returns() {
        // Covers early return in @future method
        
        List<EmailTemplate> confnILTemp = [SELECT Id FROM EmailTemplate WHERE Name = 'PEAC_OpportunityBookedToInfoLease' LIMIT 1];
		System.assert(!confnILTemp.IsEmpty(), 'PEAC_OpportunityBookedToInfoLease label must not be blank for this test.');
		List<Account> accsToInsert = new List<Account>();
        Account a = new Account();
        a.Name = 'test';
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
        a.BillingStreet = 'alksjdf';
        a.BillingCity = 'asdfad';
        a.BillingState = 'Minnesota';
        a.BillingPostalCode = '66111';
        //a.Waiting_To_Be_Sent_To_Bridgeware__c = true; // contradictory name for a flag that actually stops the call
        accsToInsert.add(a);
        insert accsToInsert;
        Account acc = [Select Id from Account where Recordtype.Name = 'End User Account' Limit 1];

        Contact c2 = new Contact();
        c2.FirstName = 'Kumar';
        c2.LastName = 'Contact';
        c2.AccountId = acc.id;
        c2.Email = 'testing1234@mailinator.com';
        c2.Phone = '5555555555';
        
        insert c2;
        RecordType rt2 = [SELECT Id,Name FROM RecordType WHERE SobjectType='Opportunity' AND Name LIKE '%CVG%' LIMIT 1];

        Opportunity op = new Opportunity();
        op.Name = 'Test Opp';
        op.Portal_User_ID__c = 'PUDA-';
        op.RecordTypeId = rt2.Id;
        op.AccountId = acc.id;
        op.Amount = 100;
        op.StageName = 'Quote';
        op.CloseDate = System.today() + 30;
        op.Primary_Source__c = 'Email';
        op.Branch__c = 'IFP - Indirect Funding Pl';
        
        op.Portal_App_Completed__c = TRUE;
        op.Created_via_App_Wizard__c = True;
        op.Application__c = '2112357';
        op.SFP_Tier_2_Status__c = NULL;
        op.Application_Status__c = 'Manually Approved';
        op.Opportunity_Status__c = 'Application In Progress';
        insert op;

        Test.startTest();
        PEAC_BookToILNotification.sendEmailNotification(op.id, confnILTemp[0].ID, UserInfo.getUserId());
        Test.stopTest();
    }
        
}