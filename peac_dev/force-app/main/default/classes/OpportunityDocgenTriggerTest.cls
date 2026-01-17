@isTest
private with sharing class OpportunityDocgenTriggerTest {
    public static testMethod void testOppTrigger(){
		User usr1 = [Select Id, Name from User where name like 'User MarlinNet' limit 1];
        
        system.runAs(usr1){
        
        RecordType rt1 = [select id,Name from RecordType where SobjectType='Account' and Name='End User Account' Limit 1];
        Account accRecEndUser = new Account(Name='Test Account1' , recordTypeId=rt1.id,Business_Phone__c = '0987654321');
        insert accRecEndUser;
            
        //Opportunity Record
        
        opportunity opp = new opportunity(Name='testOpty' , Accountid = accRecEndUser.Id , StageName = 'Quote' , 
                                          CloseDate = System.today() , Primary_Source__c = 'Email');

        insert opp;
        
		    
        opp.Description = '[JDR-Action:Generate PDF]';
        
        Test.startTest();
        update opp;
            
        // CREATE DDP TEST DATA
        Loop__DDP__c ddp = new Loop__DDP__c(Name='MarlinNet Docs');
        insert ddp;
        
        Loop__DDP_Integration_Option__c delivOpt = new Loop__DDP_Integration_Option__c(Name='DocGen Queue', Loop__DDP__c=ddp.Id);
        
        insert delivOpt;
       
        update opp;
        Test.stopTest();
        }
    }
}