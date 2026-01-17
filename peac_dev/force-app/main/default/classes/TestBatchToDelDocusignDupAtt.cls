@isTest
public class TestBatchToDelDocusignDupAtt {
    static testMethod void testBatchClass() {

        Account acc = new Account (Name = 'test', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Franchisee Account').getRecordTypeId());
        insert acc;
        Opportunity opp = new Opportunity (Name = 'test1', StageName = 'Funded/Booked',Tax_ID__c = '987655678',CloseDate = Date.today () + 10, AccountId = acc.Id, Primary_Source__c = 'Direct Mail', Stipulations__c = 'Municipal addendum');
        insert opp;
        dsfs__DocuSign_Status__c dsfs = new dsfs__DocuSign_Status__c();
        dsfs.dsfs__Opportunity__c = opp.Id;
        insert dsfs;
        Attachment attach=new Attachment();   	
    	attach.Name='Unit Test Attachment';
    	Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
    	attach.body=bodyBlob;
        attach.parentId=dsfs.id;
        insert attach;    
               
        Datetime lastyearrec = Datetime.now().addYears(-1);
         
        Test.setCreatedDate(attach.Id, lastyearrec);  
    	Test.startTest(); 
        BatchToDelDocusignDupAtt ob = new BatchToDelDocusignDupAtt();
        Database.executeBatch(ob);
        Test.stopTest();
    }
}