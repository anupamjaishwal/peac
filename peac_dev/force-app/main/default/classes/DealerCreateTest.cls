/*********************************************************************
 * Description: Test Class for dealer trigger
 * *******************************************************************/
@isTest
public class DealerCreateTest {
    
    @TestSetup
    static void setup(){
        List<Account> lstAcc = new List<Account>();        
        //Account record of type dealer
        RecordType rt = [select id,Name from RecordType where SobjectType='Account' and Name='Dealer_Qualification' Limit 1];
        Account accRecDealer = new Account(Name='Test Account1' , recordTypeId=rt.id, Business_Phone__c = '0987654321');
        lstAcc.add(accRecDealer);
        
        //Account record of type End USer
        RecordType rt1 = [select id,Name from RecordType where SobjectType='Account' and Name='End User Account' Limit 1];
        Account accRecEndUser = new Account(Name='Test Account1' , recordTypeId=rt1.id,Business_Phone__c = '0987654321');
        lstAcc.add(accRecEndUser);
        insert lstAcc;
        
       
        //program for an account
        Program__c pr = new Program__c(Name = 'testProgram');
        insert pr;
        
        //Account Program for dealer Account 
        Account_Program__c ap = new Account_Program__c(Account__c = accRecDealer.id , Program__c = pr.id);
        insert ap;
        
        //Opportunity Record
       
        //RecordType rt2 = [select id,Name from RecordType where SobjectType='Opportunity' and Name LIKE '%Express%' Limit 1];
         opportunity opp = new opportunity(Name='testOpty' , Accountid = accRecEndUser.Id , StageName = 'Quote' , 
                                          CloseDate = System.today() , Primary_Source__c = 'Email', Equipment_Cost__c = 51000,
                                         Decision_Status__c = 'A');
       	List<opportunity> optyLst = new List<opportunity>();
        Test.startTest();
       /* for(Integer i=0; i<=5;i++){
            opportunity opp = new opportunity(Name='testOpty' , Accountid = accRecEndUser.Id , StageName = 'Quote' , 
                                          CloseDate = System.today() , Primary_Source__c = 'Email', Equipment_Cost__c = 51000,
                                         Decision_Status__c = 'A');
            optyLst.add(opp);
        }
        insert optyLst;*/
        insert opp;
        Test.stopTest();
  //      delete dlr;
    }

    @IsTest
    static void testInsertDealer() {

        Account accRecDealer = [SELECT Id, Name, RecordType.Name FROM Account WHERE Name = 'Test Account1' AND RecordType.Name = 'Dealer_Qualification'];
        Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Name = 'testOpty' limit 1];
        Program__c pr = [Select Id from Program__c limit 1];
        List<Opportunity_Program__c> optyPrLst = new List<Opportunity_Program__c>();
        for(integer i=0; i<=2;i++){
            Opportunity_Program__c optyPr = new Opportunity_Program__c();
            optyPr.Opportunity__c = opp.Id;
            optyPr.Program__c = pr.Id;
            optyPrLst.add(optyPr);
        }
        insert optyPrLst;
        List<Dealer__c> dealerLst = new List<Dealer__c>();
		for(Integer i=0; i<=5;i++){
        //Dealer Record
        Dealer__c dlr = new Dealer__c(Dealer__c = accRecDealer.id , Opportunity__c = opp.id,  Primary_Dealer__c = false);
            dealerLst.add(dlr);
        }
        Test.startTest();
        insert dealerLst; 
        delete dealerLst[0]; 
        Test.stopTest();
    }
    
}