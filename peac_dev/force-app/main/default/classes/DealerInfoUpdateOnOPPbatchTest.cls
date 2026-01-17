@isTest
public class DealerInfoUpdateOnOPPbatchTest {
     @TestSetup
     static void makeData(){
        List<Account> lstAcc = new List<Account>();        
        //Account record of type dealer
        
        RecordType rt = [select id,Name from RecordType where SobjectType='Account' and Name='Dealer_Qualification' Limit 1];
        Account accRecDealer = new Account(Name='Test Account1' , recordTypeId=rt.id, Business_Phone__c = '0987654321');
        lstAcc.add(accRecDealer);
        
        
        //Account record of type End USer
        RecordType rt1 = [select id,Name from RecordType where SobjectType='Account' and Name='End User Account' Limit 1];
        Account accRecEndUser = new Account(Name='Test Account2' , recordTypeId=rt1.id,Business_Phone__c = '0987654321');
        lstAcc.add(accRecEndUser);
        insert lstAcc;

        //program for an account
        Program__c pr = new Program__c(Name = 'testProgram');
        insert pr;
        
        //Account Program for dealer Account 
        Account_Program__c ap = new Account_Program__c(Account__c = accRecDealer.id , Program__c = pr.id);
        insert ap;
        Test.startTest();
        opportunity opp = new opportunity(Name='testOpty' , StageName = 'Quote', 
                                          CloseDate = System.today() , Primary_Source__c = 'Email');
        
        opp.AccountId = accRecEndUser.Id;                            
        insert opp;
        Test.stopTest();
     }
     public static testMethod void testData(){

        Test.startTest();
        //Dealer Record
        Dealer__c dlr = new Dealer__c();
        dlr.Opportunity__c = [SELECT Id FROM Opportunity LIMIT 1].Id;
        dlr.Dealer__c = [SELECT Id FROM Account WHERE Name='Test Account1' LIMIT 1].Id;
        insert dlr;
        Test.stopTest();
        DealerInfoUpdateOnOPPbatch dd=new  DealerInfoUpdateOnOPPbatch();
        Database.executeBatch(dd); 
    }

}