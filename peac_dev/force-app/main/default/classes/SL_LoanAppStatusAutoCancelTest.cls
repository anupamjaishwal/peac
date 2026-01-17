@isTest
private class SL_LoanAppStatusAutoCancelTest {

    private static Id oppId;

    // Setup method to create test data and simulate history changes
    @TestSetup
    private static void setupTestData() {
        List<Account> accsToupdate = new List<Account>();

        Account a = new Account();
        a.Name = 'test';
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
        a.BillingStreet = 'alksjdf';
        a.BillingCity = 'asdfad';
        a.BillingState = 'Minnesota';
        a.BillingPostalCode = '66111';
        a.CCAN__c= '4667537';
        a.CCID__c= '1667537';
        accsToupdate.add(a);

        Account b = new Account();
        b.Name = 'broker';
        b.Business_Phone__c = '5558888888';
        b.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker Account').getRecordTypeId();
        b.Submitted_Loan__c = true;
        b.Approved_Loan__c = true;
        b.Declined_Loan__c = true;
        b.More_Info_Loan__c = true;
        b.Docs_In_Loan__c = true;
        b.Docs_Out_Loan__c = true;
        b.Docs_Out_Contracts_Loan__c = false;
        b.Funded_Loan__c = true;

        accsToupdate.add(b);
        System.debug('Broker Created');

        List<Contact> contacts = new List<Contact>();
        Contact c = new Contact();
        c.FirstName = 'Bob';
        c.LastName = 'Johnson';
        c.AccountId = a.Id;
        c.Phone = '5555555555';
        contacts.add(c);

             
        insert accsToupdate;

        Contact c2 = new Contact();
        c2.FirstName = 'Carmen';
        c2.LastName = 'Contact';
        c2.AccountId = b.Id;
        c2.Email = 'testing@mailinator.com';
        c2.Phone = '5555555555';
        c2.Receive_All_Loan_Notifications__c = true;
        contacts.add(c2) ;
        System.debug('Broker Contact Created');
        
		Contact c3 = new Contact();
        c3.FirstName = 'Dealer Repurchase DocGen';
        c3.LastName = 'DO NOT DELETE';
        c3.AccountId = a.Id;
        c3.Phone = '5555555557';
		contacts.add(c3);
 		insert contacts;

        Test.startTest();
        RecordType rt2 = [SELECT Id,Name FROM RecordType WHERE SobjectType='Opportunity' AND Name LIKE '%Loan%' LIMIT 1];
        System.debug('Got Record');

        
        Opportunity op = new Opportunity();
        op.Name = 'Test Opp';
        op.RecordTypeId = rt2.Id;
        op.AccountId = a.Id;
        op.Amount = 100;
        op.CloseDate = System.today() + 30;
        op.Primary_Source__c = 'Email';
        op.Loan_Purpose__c = 'Cash Crunch';
        op.CaseCenter__c = 'L78697698';
        op.StageName = 'Decision';
        //op.Initial_Approval_Date__c =System.today() - 40;
		//op.Initial_More_Info_Date__c =System.today() - 40;
        //op.LastStageChangeDate = System.today().add(-30);

        insert op;



        System.debug('Opportunity Created Created');
        
        Broker__c broker = new Broker__c();
        broker.Account__c = b.Id;
        broker.Opportunity__c = op.Id;
        insert broker;
        System.debug('Broker Relationship Created');


        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.ContactId = c2.Id;
        ocr.OpportunityId = op.Id;
        ocr.Role = 'Dealer Primary Contact';
        insert ocr;
        
        Guarantor__c g = new Guarantor__c();
        g.Opportunity__c = op.Id;
        g.Account__c = a.Id;
        g.PG_Number__c = 'PG1';
        //insert g;
        Test.stopTest();


    }
    

    @isTest static void testBatchAndSchedulerApproved() {
                Opportunity opp = [SELECT ID, Initial_Approval_Date__c, Application_Status__c, LastStageChangeDate, StageName   FROM Opportunity LIMIT 1];
        opp.Application_Status__c = 'Manually Approved';
        opp.StageName = 'Proposal';
        update opp;
        
        System.debug('OPP ' + opp);
                System.debug('OPP LastStageChangeDate' + opp.LastStageChangeDate);

        Test.startTest();
        SL_LoanAppStatusAutoCancelBatch batch = new SL_LoanAppStatusAutoCancelBatch();
        Database.executeBatch(batch, 200);

        String cronExp = '0 0 0 ? * * *'; // Runs immediately during test context
        System.schedule('TestScheduleLoanCancel', cronExp, new SL_LoanAppStatusAutoCancelScheduler());
        Test.stopTest();
    }
    
        @isTest static void testBatchAndSchedulerMoreInfo() {
                Opportunity opp = [SELECT ID, Initial_More_Info_Date__c, Application_Status__c, LastStageChangeDate, StageName   FROM Opportunity LIMIT 1];
        opp.Application_Status__c = 'More Info';
        opp.StageName = 'Proposal';
        update opp;
        
        System.debug('OPP ' + opp);
                System.debug('OPP LastStageChangeDate' + opp.LastStageChangeDate);

        Test.startTest();
        SL_LoanAppStatusAutoCancelBatch batch = new SL_LoanAppStatusAutoCancelBatch();
        Database.executeBatch(batch, 200);

        String cronExp = '0 0 0 ? * * *'; // Runs immediately during test context
        System.schedule('TestScheduleLoanCancel', cronExp, new SL_LoanAppStatusAutoCancelScheduler());
        Test.stopTest();
    }
}