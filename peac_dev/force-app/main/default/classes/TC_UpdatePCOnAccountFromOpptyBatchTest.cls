@isTest
public class TC_UpdatePCOnAccountFromOpptyBatchTest {

    @IsTest 
    static void setMostRecentOppTest() {
        
        Account acct = TC_SDR_TestUtility.constructAccount('Test', null,null);
        acct.Business_Phone__c = '1234567890';
        insert acct;

        Contact con = new Contact();
        con.FirstName = 'TestFirst';
        con.LastName = 'Test Name';
        con.AccountId = acct.Id;
        insert con;
        Test.startTest();
        Opportunity opp = TC_SDR_TestUtility.constructOpportunity('Test',acct.Id);
        opp.Primary_Contact__c = con.Id;
        insert opp;
        acct = [SELECT Id, MostRecentOpportunity__c FROM Account WHERE Id = :acct.Id];
        
        TC_UpdatePCOnAccountFromOpptyBatch objBatch = new TC_UpdatePCOnAccountFromOpptyBatch();
        Database.executeBatch(objBatch);
        Test.stopTest();
        // System.assert(acct.MostRecentOpportunity__c != null);
    }
}