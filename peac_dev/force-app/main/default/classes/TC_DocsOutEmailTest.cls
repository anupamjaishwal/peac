@isTest
public class TC_DocsOutEmailTest {
    
    //// Start: Test class to cover codcoverage for decommision class-By Raja Sirivella

    
         static testMethod void testme224(){
        List<Contact> cons = new List<Contact>();
        Contact con = new Contact();
        //con.AccountId = acc.Id;
        con.FirstName = 'Te';
        con.LastName = 'Test';
        con.Phone ='1111111111';
        con.Email = 'test@test.com';
        cons.add(con);
        insert cons;
        Test.startTest();
       TC_SendDocsOutReminderEmailBatch ba= new TC_SendDocsOutReminderEmailBatch();
        Id jobid= Database.executeBatch(ba,5);
        Test.stopTest();
    }

    static testMethod void testSchedule1(){
        Test.startTest();
        SchedulableContext sc = null;
        TC_SendDocsOutReminderEmailBatchSchd tsc = new TC_SendDocsOutReminderEmailBatchSchd();
        tsc.execute(sc);
        Test.stopTest();
    }
    /*static testMethod void test1(){
        List<Opportunity> opps = new List<Opportunity>();
        Opportunity o = new Opportunity();
        o.Name='Testing12345';
        o.CloseDate= Date.today();
        o.StageName = 'Docs Out';
        o.Approval_Date__c = Date.today();
        o.Workflow_Type__c = 'simple';
        o.Docs_Out__c = Date.today();
        opps.add(o);
        insert opps;
        List<Account> accs = new List<Account>();
        Account acc = new Account();
        acc.Name = 'test';
        accs.add(acc);
        insert accs;
        List<Contact> cons = new List<Contact>();
        Contact con = new Contact();
        con.AccountId = acc.Id;
        con.FirstName = 'Te';
        con.LastName = 'Test';
        con.Phone ='1111111111';
        con.Email = 'test@test.com';
        cons.add(con);
        insert cons;
        List<dsfs__DocuSign_Status__c> signers = new List<dsfs__DocuSign_Status__c>();
        dsfs__DocuSign_Status__c signer = new dsfs__DocuSign_Status__c();
        signer.dsfs__Opportunity__c = o.id;
        signer.dsfs__Envelope_Status__c = 'Created';
        signers.add(signer);
        insert signers;
        List<dsfs__DocuSign_Recipient_Status__c> recips = new List<dsfs__DocuSign_Recipient_Status__c>();
        dsfs__DocuSign_Recipient_Status__c recip = new dsfs__DocuSign_Recipient_Status__c();
        recip.dsfs__DocuSign_Recipient_Id__c = '1';
        recip.dsfs__Parent_Status_Record__c = signer.id;
        recip.dsfs__Contact__c = con.id;
        recip.dsfs__DocuSign_Routing_Order__c = 1;
        recip.dsfs__DocuSign_Recipient_Email__c = con.email;
        recips.add(recip);
        insert recips;
        Test.startTest();
        TC_SendDocsOutReminderEmailBatch ba= new TC_SendDocsOutReminderEmailBatch();
        Id jobid= Database.executeBatch(ba,5);
        Test.stopTest();
    } */
    
}