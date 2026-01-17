@IsTest(SeeAllData=true)
public class SL_Test_DocumentChecklist {
    
    public static testMethod void codeCoverage() {
        
        list<RecordType> recTypeCase = [SELECT Id,name, DeveloperName 
                                        FROM RecordType 
                                        WHERE SObjectType = 'Case' and IsActive=true limit 1];
        list<RecordType> recType = [SELECT Id,name, DeveloperName 
                                    FROM RecordType 
                                    WHERE SObjectType = 'Opportunity' and IsActive=true  limit 1];
        
        Case objCase = new Case(status='New',Origin='Phone');
        if(!recTypeCase.isEmpty()){
            objCase.put('recordTypeId',recTypeCase[0].Id);
        }
        INSERT objCase;
        
        DocumentStatus__c objDocChecklist = new DocumentStatus__c(Case__c = objCase.ID);
        Insert objDocChecklist;
        
        DocumentStatus__c objDocStatus = [SELECT ID
                                          FROM DocumentStatus__c
                                          WHERE Case__c=:objCase.Id limit 1];
        Account acc= new Account(Name='Partner Account');
        INSERT acc;    
        date mydate = date.parse('1/1/2050');
        Opportunity opportunityToCreate = new Opportunity(	StageName = 'Sourcing Demand', 
                                                          CloseDate = mydate,
                                                          AccountID = acc.ID,
                                                          Name = 'Test Opportunity Triggers');
        if(!recType.isEmpty()){
            opportunityToCreate.put('recordTypeId',recType[0].Id);
        }
        INSERT opportunityToCreate; 
        
        String strJson =  '{"Id":"'+objDocStatus.Id+'","Name":"new","Case__c":"'+objCase.ID+'","Required__c":false,"Status__c":"Pending Internal Review","Description__c":"test","Year__c":"2018"}';
        String strJson1 =  '{"Id":"'+objDocStatus.Id+'","Name":"new","Case__c":"'+objCase.ID+'",}';
        
        ContentVersion testContentInsert =new ContentVersion(); 
        testContentInsert.ContentURL='http://www.google.com/'; 
        testContentInsert.Title ='Google.com'; 
        INSERT testContentInsert; 
        ContentVersion objContentVer = [SELECT id,ContentDocumentId FROM contentversion WHERE id=:testContentInsert.Id limit 1];
        
        
        Test.startTest();
        
        SL_DocumentChecklist.updateFile(objContentVer.ContentDocumentId, objCase.ID);
        SL_DocumentChecklist.getColumns();
        SL_DocumentChecklist.SaveRecord('Test', '','',objContentVer.ContentDocumentId,objCase.Id,'Case');
        SL_DocumentChecklist.SaveRecord('Test', '','',objContentVer.ContentDocumentId,opportunityToCreate.Id,'Opportunity');
        
        SL_DocumentChecklist.getselectOptions('Status__c');
        list<String> lstStr = new list<String>{'Id', 'Name'};
            SL_DocumentChecklist.getrecords(objCase.ID,'Case',lstStr);
        SL_DocumentChecklist.getrecords(opportunityToCreate.ID,'Opportunity',lstStr);
        
        SL_DocumentChecklist.updateRecord(strJson);
        SL_DocumentChecklist.updateRecord(strJson1);
        
        Test.stopTest();   
    }
}