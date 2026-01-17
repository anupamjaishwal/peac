@isTest
public class  TC_EmailBatchTest{
    
    static testMethod void testme(){
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
       TC_SendExpiredEmailsBatch ba= new TC_SendExpiredEmailsBatch();
        Id jobid= Database.executeBatch(ba,5);
        Test.stopTest();
    }
    
    static testMethod void testme22(){
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
       TC_SendScheduleEmailsBatch ba= new TC_SendScheduleEmailsBatch();
        Id jobid= Database.executeBatch(ba,5);
        Test.stopTest();
    }
    
     static testMethod void testme223(){
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
       TC_SendUploadEmailsBatch ba= new TC_SendUploadEmailsBatch();
        Id jobid= Database.executeBatch(ba,5);
        Test.stopTest();
    }
    
   
    
  
    
    //commented by Raja
    /*static testMethod void testme(){
        List<Opportunity> opps = new List<Opportunity>();
        Opportunity o = new Opportunity();
        o.Name='Testing12345';
        o.CloseDate= Date.today();
        o.StageName = 'Docs Out';
        o.Approval_Date__c = Date.today().addDays(-90);
        o.Workflow_Type__c = 'simple';
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
        List<Signer_Portal_Status__c> signers = new List<Signer_Portal_Status__c>();
        Signer_Portal_Status__c signer = new Signer_Portal_Status__c();
        signer.Name = 'Test';
        signer.Opportunity__c = o.id;
        signer.Contact__c = con.Id;
        signers.add(signer);
        insert signers;
        Test.startTest();
       TC_SendExpiredEmailsBatch ba= new TC_SendExpiredEmailsBatch();
        Id jobid= Database.executeBatch(ba,5);
        Test.stopTest();
    }
    
     static testMethod void testme1(){
        List<Opportunity> opps = new List<Opportunity>();
        Opportunity o = new Opportunity();
        o.Name='Testing12345';
        o.CloseDate= Date.today();
        o.StageName = 'Docs Out';
        o.Approval_Date__c = Date.today().addDays(-83);
        o.Workflow_Type__c = 'simple';
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
        List<Signer_Portal_Status__c> signers = new List<Signer_Portal_Status__c>();
        Signer_Portal_Status__c signer = new Signer_Portal_Status__c();
        signer.Name = 'Test';
        signer.Opportunity__c = o.id;
        signer.Contact__c = con.Id;
        signers.add(signer);
        insert signers;
        Test.startTest();
        TC_SendScheduleEmailsBatch ba= new TC_SendScheduleEmailsBatch();
        Id jobid= Database.executeBatch(ba,5);
        Test.stopTest();
    }*/
    //end
    
    /*static testMethod void testme2(){
        List<Opportunity> opps = new List<Opportunity>();
        Opportunity o = new Opportunity();
        o.Name='Testing12345';
        o.CloseDate= Date.today();
        o.StageName = 'Quote';
        o.Approval_Date__c = Date.today().addDays(-83);
        o.Workflow_Type__c = 'simple';
        o.Portal_Status_Upload__c = true;
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
        List<Signer_Portal_Status__c> signers = new List<Signer_Portal_Status__c>();
        Signer_Portal_Status__c signer = new Signer_Portal_Status__c();
        signer.Name = 'Test';
        signer.Opportunity__c = o.id;
        signer.Contact__c = con.Id;
        signers.add(signer);
        insert signers;
        Test.startTest();
        TC_SendUploadEmailsBatch ba= new TC_SendUploadEmailsBatch();
        Id jobid= Database.executeBatch(ba,5);
        Test.stopTest();
    }
    
    static testMethod void testme3(){
        List<Opportunity> opps = new List<Opportunity>();
        Opportunity o = new Opportunity();
        o.Name='Testing12345';
        o.CloseDate= Date.today();
        o.Tax_ID__c = '123456789';
        o.StageName = 'Quote';
        o.Approval_Date__c = Date.today().addDays(-83);
        o.Workflow_Type__c = 'simple';
        o.Portal_Status_Complete__c = true;
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
        List<Signer_Portal_Status__c> signers = new List<Signer_Portal_Status__c>();
        Signer_Portal_Status__c signer = new Signer_Portal_Status__c();
        signer.Name = 'Test';
        signer.Opportunity__c = o.id;
        signer.Contact__c = con.Id;
        signers.add(signer);
        insert signers;
        Test.startTest();
        TC_SendEmailNotifications.stepsEmail(null,opps,true);
        TC_SendEmailNotifications.completeEmail(null,opps,true);
        TC_SendEmailNotifications.testBoost();
        Test.stopTest();
    }*/
    //commented by Raja
    static testMethod void testSchedule1(){
        Test.startTest();
        SchedulableContext sc = null;
        TC_SendExpiredEmailsBatchSchd tsc = new TC_SendExpiredEmailsBatchSchd();
        tsc.execute(sc);
        Test.stopTest();
    }
    
    static testMethod void testSchedule2(){
        Test.startTest();
        SchedulableContext sc = null;
        TC_SendScheduleEmailsBatchSchd tsc = new TC_SendScheduleEmailsBatchSchd();
        tsc.execute(sc);
        Test.stopTest();
    }
    static testMethod void testSchedule3(){
        Test.startTest();
        SchedulableContext sc = null;
        TC_SendUploadEmailsBatchSchd tsc = new TC_SendUploadEmailsBatchSchd();
        tsc.execute(sc);
        Test.stopTest();
    }
        
}