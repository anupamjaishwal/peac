@isTest
public class PrimaryContactOnOpportunity_Test {
public static testmethod void oppTest(){
   
   //create dealer type account
   RecordType rt = [select id,Name from RecordType where SobjectType='Account' and Name='End User Account' Limit 1];
        Account acct1 = new Account(Name='Test Account1' , recordTypeId=rt.id);        
        insert acct1;
        
        Account acct2 = new Account(Name='Test Account2' , recordTypeId=rt.id, Business_Phone__c = '0987654321');
        insert acct2;
        
        //create opportuntiy and associate it with the account.
        RecordType rt2 = [select id,Name from RecordType where SobjectType='Opportunity' and Name LIKE '%Express%' Limit 1];
        Opportunity op = new Opportunity();
        op.Name = 'Test Opp';
        op.Accountid = acct1.Id;
        op.Amount = 100;
        op.StageName = 'Quote';
        op.CloseDate = System.today() + 30;
        op.Primary_Source__c = 'Email';
    Test.startTest();    
    insert op;
    Test.stopTest();
   
   Contact con1 = new Contact();
   con1.AccountId = acct2.Id;
   con1.FirstName = 'contact';
   con1.LastName  = 'Test';
   insert con1 ;
   
   Contact con2 = new Contact();
   con2.AccountId = acct2.Id;
   con2.FirstName = 'contact';
   con2.LastName  = 'Test';
   insert con2 ;
   
    OpportunityContactRole ocr = new OpportunityContactRole();
    ocr.ContactId = con1.Id;
    ocr.OpportunityId = op.Id;
    ocr.IsPrimary = TRUE;
    ocr.Role = 'Decision Maker';
    insert ocr;
    
    OpportunityContactRole ocr1 = new OpportunityContactRole();
    ocr1.ContactId = con2.Id;
    ocr1.OpportunityId = op.Id;
    ocr1.IsPrimary = FALSE;
    ocr1.Role = 'Decision Maker';
    insert ocr1;
   
   }
}