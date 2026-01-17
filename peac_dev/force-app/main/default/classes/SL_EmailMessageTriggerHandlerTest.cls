@isTest
public with sharing class SL_EmailMessageTriggerHandlerTest {
    @isTest
    public static void case1_fromContract() {
        SL_SCTestData.createAccountAndContracts(4, 1);
        List<Contract__c> contracts = SL_SCTestData.testContracts;
        contracts[0].Lessor_Code__c = '404';
        contracts[1].Lessor_Code__c = '404';
        contracts[2].Lessor_Code__c = '020';
        contracts[3].Lessor_Code__c = '113';
        update contracts;
        // fromCase
        Case relatedCase = new Case(Contract_custom__c = contracts[2].Id, Origin = 'Phone', Status = 'New');
        insert relatedCase;
        List<EmailMessage> mails = new List<EmailMessage>{
            new EmailMessage(RelatedToId = contracts[0].id, ValidatedFromAddress = 'noreply@peacsolutions.com'),
            new EmailMessage(RelatedToId = contracts[1].id, FromAddress = 'noreply@peacsolutions.com'),
            new EmailMessage(RelatedToId = relatedCase.Id, FromAddress = 'customerservice@lease-services.com'), // 'returns@lease-services.com'
            new EmailMessage(RelatedToId = contracts[3].id, FromAddress = 'noreply@peacsolutions.com')
        };
        Test.startTest();
        List<Database.SaveResult> emailResults = Database.insert(mails, false);
        Test.stopTest();
        Integer mailsAfter = [SELECT COUNT() FROM EmailMessage];
        System.debug('emailResults: ' + emailResults);
        System.Assert.isTrue(emailResults[0].getErrors()[0].getMessage().contains(' is a Blind contract. Please send from '));
        System.Assert.isTrue(emailResults[1].getErrors()[0].getMessage().contains(' is a Blind contract. Please send from '));
        System.Assert.isTrue(emailResults[2].getErrors()[0].getMessage().contains(' is not Blind. Please use '));
        System.Assert.isTrue(emailResults[3].getErrors()[0].getMessage().contains(' is XBS. Please use an XFS address.'));
        System.Assert.areEqual(0, mailsAfter, 'all give error due to the blind or xbs email address');
    }

    // @isTest
    // public static void fromClosedCase() {
    //     SL_SCTestData.createAccountAndContracts(1, 1);
    //     Contract__c ctr = [SELECT Id, Lessor_Code__c from Contract__c];
    //     ctr.Lessor_Code__c = '020';
    //     update ctr;
    //     insert new Case(Subject = 'test parent', Description = 'test parent case',
    //         Contract_custom__c = ctr.Id, Origin = 'Phone', Status = 'New');
    //     Case closedCase = [SELECT Id, Contract_custom__c FROM Case];
    //     closedCase.Status = 'Closed';
    //     update closedCase;
    //     EmailMessage sourceEmail = new EmailMessage(ToAddress = 'yet.another.email@address.com', 
    //         Subject = 'test', TextBody = 'body with ach test.', ParentId = closedCase.Id,
    //         Incoming = true);
    //     Test.startTest();
    //     insert sourceEmail;
    //     Test.stopTest();
    //     // SL-2599 it is now called asynchronous
    //     // List<Case> casesAfter = [SELECT Id, ParentId, Contract_custom__c, Subject, Description FROM Case WHERE Id != :closedCase.Id];
    //     // System.assertEquals(closedCase.Id, casesAfter[0].ParentId);
    //     // System.assertEquals(closedCase.Contract_custom__c, casesAfter[0].Contract_custom__c);
    //     // System.assertEquals('test', casesAfter[0].Subject);
    //     // System.assertEquals('body with ach test.', casesAfter[0].Description);
    // }
    // @isTest
    // public static void fromClosedCase_withOwner() {
    //     SL_SCTestData.createAccountAndContracts(1, 1);
    //     Contract__c ctr = [SELECT Id, Lessor_Code__c from Contract__c];
    //     ctr.Lessor_Code__c = '020';
    //     update ctr;
    //     insert new Case(Subject = 'test parent', Description = 'test parent case',
    //         Contract_custom__c = ctr.Id, Origin = 'Phone', Status = 'New');
    //     Case closedCase = [SELECT Id, Contract_custom__c FROM Case];
    //     closedCase.Status = 'Closed';
    //     update closedCase;
    //     EmailMessage sourceEmail = new EmailMessage(ToAddress = 'wclcustomerservice@peacsolutions.com', 
    //         Subject = 'test', TextBody = 'body with ach test.', ParentId = closedCase.Id,
    //         Incoming = true);
    //     Test.startTest();
    //     insert sourceEmail;
    //     Test.stopTest();
    //     // SL-2599 it is now called asynchronous so cases are not created yet, maybe if I modify the mock response
    //     // List<Case> casesAfter = [SELECT Id, ParentId, Contract_custom__c, Subject, Description, OwnerId FROM Case WHERE Id != :closedCase.Id];
    //     // Group wcQueue = [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Working_Capital'];
    //     // System.assertEquals(closedCase.Id, casesAfter[0].ParentId);
    //     // System.assertEquals(closedCase.Contract_custom__c, casesAfter[0].Contract_custom__c);
    //     // System.assertEquals(wcQueue.Id, casesAfter[0].OwnerId);
    //     // System.assertEquals('body with ach test.', casesAfter[0].Description);
    // }

    @isTest
    public static void fromContract() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        Contract__c contract = [SELECT Id, Customer__c from Contract__c];
        EmailMessage sourceEmail = new EmailMessage(ToAddress = 'yet.another.email@address.com', 
            Subject = 'test', TextBody = 'body with ach test. ', RelatedToId = contract.Id);
        Test.startTest();
        insert sourceEmail;
        Test.stopTest();
        EmailMessage emailAfter = [SELECT Id, ActivityId FROM EmailMessage];
        List<Task> tasksAfter = [SELECT Id, WhatId, Contract__c FROM Task WHERE Id = :emailAfter.ActivityId];
        System.assertEquals(contract.Customer__c, tasksAfter[0].WhatId);
        System.assertEquals(contract.Id, tasksAfter[0].Contract__c);
        sourceEmail.Subject = 'edited test';
        update sourceEmail;
    }
    // @isTest
    // public static void fromClosedCase_withOwner2() {
    //     SL_SCTestData.createAccountAndContracts(1, 1);
    //     Contract__c ctr = [SELECT Id, Lessor_Code__c from Contract__c];
    //     ctr.Lessor_Code__c = '020';
    //     update ctr;
    //     insert new Case(Subject = 'test parent', Description = 'test parent case',
    //         Contract_custom__c = ctr.Id, Origin = 'Phone', Status = 'New');
    //     Case closedCase = [SELECT Id, Contract_custom__c FROM Case];
    //     closedCase.Status = 'Closed';
    //     update closedCase;
    //     EmailMessage sourceEmail = new EmailMessage(ToAddress = 'customerservicefax@peacsolutions.com', 
    //         Subject = 'test', TextBody = 'body with ach test.', ParentId = closedCase.Id,
    //         Incoming = true);
    //     Test.startTest();
    //     insert sourceEmail;
    //     Test.stopTest();
    //     List<Case> casesAfter = [SELECT Id, ParentId, Contract_custom__c, Subject, Description, OwnerId FROM Case WHERE Id != :closedCase.Id];
    //     Group wcQueue = [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = 'All_Other'];
    //     System.assertEquals(closedCase.Id, casesAfter[0].ParentId);
    //     System.assertEquals(closedCase.Contract_custom__c, casesAfter[0].Contract_custom__c);
    //     System.assertEquals(wcQueue.Id, casesAfter[0].OwnerId);
    //     System.assertEquals('body with ach test.', casesAfter[0].Description);
    // }

// new

    private class RoutingMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"records":[{"EmailAddress":"queue1@example.com","CaseOwner":"Partner"},{"EmailAddress":"queue2@example.com","CaseOwner":"MeterReadsCPC"}]}');
            return res;
        }
    }

    @isTest
    static void test_EmailRoutingProcessor() {
		List<Group> partnerQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Partner'];
         User testAdmin = new User(Alias = 'testur0', Email = 'marlinbusiness@peacsolutions.com', EmailEncodingKey='UTF-8',
                                  LastName = 'testing', FirstName = 'user', LanguageLocaleKey = 'en_US',
                                  LocaleSidKey = 'en_US', ProfileId = [SELECT Id FROM Profile WHERE Name = 'Services Admin'].Id, TimeZoneSidKey = 'America/Los_Angeles',
                                  Username = 'Testadmin.test.user@silverlinecrm.com', Doc_Fee_Exception_Approver__c = true,
                                  Personnel_Number__c = '0321');
        INSERT testAdmin;
        
        System.runAs(testAdmin){
            GroupMember gm = new GroupMember(
            GroupId = partnerQueue[0].Id,
            UserOrGroupId = UserInfo.getUserId()
            );
            insert gm;
        SL_SCTestData.createAccountAndContracts(2,1);
        Test.setMock(HttpCalloutMock.class, new RoutingMock());
        List<Contract__c> contracts = SL_SCTestData.testContracts;
        contracts[0].Lessor_Code__c = '002';
        contracts[1].Lessor_Code__c = '002';
        update contracts;
           
        List<Case> cases = new List<Case>{
            new Case(
                Contract_custom__c = contracts[0].Id,
                Status             = 'Closed',
                Origin             = 'Email',
                OwnerId = partnerQueue[0].Id
            ),
            new Case(
                Contract_custom__c = contracts[1].Id,
                Origin             = 'Email',
                OwnerId = partnerQueue[0].Id
            )
        };
        insert cases;
        List<EmailMessage> emails = new List<EmailMessage>{
            new EmailMessage(
                ParentId    = cases[0].Id,
                Incoming    = true,
                FromAddress = 'x@lease-services.com',
                ToAddress   = 'queue1@example.com;queue2@example.com',
                Subject     = 't',
                TextBody    = 'b',
                MessageIdentifier = '<testidentifier1>'
            ),
            new EmailMessage(
                ParentId    = cases[1].Id,
                Incoming    = true,
                FromAddress = 'x@lease-services.com',
                CcAddress   = 'queue1@example.com;queue2@example.com',
                Subject     = 't',
                TextBody    = 'b',
                MessageIdentifier = '<testidentifier2>'
            ),
            new EmailMessage(
                ParentId    = cases[0].Id,
                Incoming    = true,
                FromAddress = 'x@lease-services.com',
                ToAddress   = 'queue1@example.com;queue2@example.com',
                Subject     = 't',
                TextBody    = 'b',
                MessageIdentifier = '<testidentifier1>'
            ),
            new EmailMessage(
                ParentId    = cases[1].Id,
                Incoming    = true,
                FromAddress = 'x@lease-services.com',
                CcAddress   = 'queue1@example.com;queue2@example.com',
                Subject     = 't',
                TextBody    = 'b',
                MessageIdentifier = '<testidentifier2>'
            )
        };
        Test.startTest();
        insert emails[0];// yeah, it is disgusting but email-to-case also does not bulkify the email creation so this is accurate
        insert emails[1];
        insert emails[2];
        insert emails[3];
        Test.stopTest();
        List<Case> casesAfter = [SELECT Id, IsClosed, SourceId FROM Case];
        System.Assert.areEqual(5, casesAfter.size(), 'original 2 cases, created 2 from closed case and 1 from open case');
            List<EmailMessage> emailsAfter = [SELECT Id, Cloned_From__c, Cloned_FromMsg__c FROM EmailMessage WHERE Incoming = true];
        System.Assert.areEqual(5, emailsAfter.size(), 'original 4 emails, Added 3 clones, deleted original 2 from closed case');
        System.Assert.areEqual(null, emailsAfter[0].Cloned_FromMsg__c, 'this is original email');
        System.Assert.areEqual(emails[0].Id, emailsAfter[2].Cloned_From__c, 'cloned emails get flagged');
        System.Assert.areEqual(emails[0].MessageIdentifier, emailsAfter[2].Cloned_FromMsg__c, 'cloned emails get flagged');
        List<EmailMessage> replyNotifications = [SELECT Id, Cloned_From__c, Cloned_FromMsg__c, FromAddress,toAddress FROM EmailMessage WHERE Incoming = false];
        system.debug('replyNotifications:' + replyNotifications);
        System.Assert.areEqual(4, [SELECT Id, Cloned_From__c, Cloned_FromMsg__c FROM EmailMessage WHERE Incoming = false].size(), 'Notification on replies');
        }
    }

    @isTest
    static void routingProcessorFirstEmails() {
        SL_SCTestData.createAccountAndContracts(1,1);
        Test.setMock(HttpCalloutMock.class, new RoutingMock());
        List<Contract__c> contracts = SL_SCTestData.testContracts;
        contracts[0].Lessor_Code__c = '002';
        update contracts;
        List<Group> partnerQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Partner'];
        List<Case> cases = new List<Case>{
            new Case(
                Contract_custom__c = contracts[0].Id,
                Origin             = 'Web',
                OwnerId = partnerQueue[0].Id
            ),
            new Case(
                Origin             = 'Web'
            ),
            new Case(
                Origin             = 'Web'
            )
        };
        insert cases;
        List<EmailMessage> emails = new List<EmailMessage>{
            new EmailMessage(
                ParentId    = cases[0].Id,
                Incoming    = false,
                FromAddress = 'x@lease-services.com',
                ToAddress   = 'queue1@example.com;queue2@example.com',
                Subject     = 't',
                TextBody    = 'b',
                MessageIdentifier = '<testidentifier1>'
            ),
            new EmailMessage(
                ParentId    = cases[1].Id,
                Incoming    = true,
                FromAddress = 'x@lease-services.com',
                CcAddress   = 'queue1@example.com;queue2@example.com',
                Subject     = 't',
                TextBody    = 'b',
                MessageIdentifier = '<testidentifier1>'
            ),
            new EmailMessage(
                ParentId    = cases[2].Id,
                Incoming    = true,
                FromAddress = 'x@lease-services.com',
                ToAddress   = 'queue1@example.com;queue2@example.com',
                Subject     = 't',
                TextBody    = 'b',
                MessageIdentifier = '<testidentifier1>'
            )
        };
        // need to check this
        SL_Trigger_Settings__c slTrigger = SL_Trigger_Settings__c.getOrgDefaults(); 
        slTrigger.KillSwitch__c = true;
        UPDATE slTrigger;
        //
        Test.startTest();
        insert emails[0];// yeah, it is disgusting but email-to-case also does not bulkify the email creation so this is accurate
        cases[1].SourceId = emails[0].Id;
        update cases[1];
        insert emails[1];
        insert emails[2];
        Map<String, EmailMessage> firstMessages = new Map<String, EmailMessage>{'<testidentifier1>' => emails[1]};
        SL_EmailRoutingProcessor testInstance = new SL_EmailRoutingProcessor(new List<Id>{emails[0].Id}, 'triggered');
        testInstance.setParentCaseForNewEmails(firstMessages);
        Test.stopTest();
        List<Case> casesAfter = [SELECT Id, IsClosed, ParentId, Contract_Custom__c, SourceId FROM Case];
        System.Assert.areEqual(casesAfter[0].Id, casesAfter[1].ParentId, 'set the first case as the parent to the second one via the MessageIdentifier.');
        System.Assert.areEqual(casesAfter[0].Contract_Custom__c, casesAfter[2].Contract_Custom__c, 'set the ContractId from the parent.');
    }
}