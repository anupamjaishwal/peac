@isTest
private class SL_SendDelayedEmailScheduleTest {

    @isTest
    static void testEmailSending() {

        
        // Create a test EmailMessage record
        EmailMessage emailMessage = new EmailMessage(
            Subject = 'Test Email',
            ToAddress = 'test@example.com',
            FromAddress = 'sender@example.com',
            Status = '5', // Scheduled status
            MessageDate = Date.today(),
            Scheduled__c = true
        );
        insert emailMessage;
        
        // Create a test Attachment record
        Attachment attachment = new Attachment(
            ParentId = emailMessage.Id,
            Name = 'TestAttachment.txt',
            Body = Blob.valueOf('This is a test attachment.')
        );
        insert attachment;
        
        // Create OrgWideEmailAddress for testing
        OrgWideEmailAddress orgWideEmail = new OrgWideEmailAddress(
            Address = 'sender@example.com',
            DisplayName = 'Test Sender'
        );
        //insert orgWideEmail;
        
        // Set up the mock for EmailMessage so we can simulate actual sending
        Test.startTest();
        
        // Schedule the job to run immediately
        String cronExp = '0 5 * * * ?';  // This schedules to run 5 minutes past the hour
        SL_SendDelayedEmailSchedule myJob = new SL_SendDelayedEmailSchedule(true);
        System.schedule('Delayed Email Send Job TT', cronExp, myJob);
        
        Test.stopTest();
        
        // Verify that the job executed and the EmailMessage records were updated
        List<EmailMessage> emails = [SELECT Id, Status FROM EmailMessage WHERE Status = '3'];
        
        // Assert that the email has been marked as 'Sent'
        System.assertNotEquals(0, emails.size(), 'Expected at least one email to be sent');
        System.assertEquals('3', emails[0].Status, 'Expected email status to be "Sent"');
    }
    
    @isTest
    static void testHandleNoEmailsToSend() {
        // Test case where no EmailMessage records are found
        Test.startTest();
        
        // Schedule the job to run immediately
        String cronExp = '0 5 * * * ?';  // This schedules to run 5 minutes past the hour
        SL_SendDelayedEmailSchedule myJob = new SL_SendDelayedEmailSchedule(true);
        System.schedule('Delayed Email Send Job TT2', cronExp, myJob);
        
        Test.stopTest();
        
        // No emails should have been sent, so check if no updates occurred
        List<EmailMessage> emails = [SELECT Id, Status FROM EmailMessage];
        System.assertEquals(0, emails.size(), 'No emails should have been sent');
    }
}