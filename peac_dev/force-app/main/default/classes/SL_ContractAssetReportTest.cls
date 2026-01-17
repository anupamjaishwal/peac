@isTest
public class SL_ContractAssetReportTest {
@TestSetup
    static void setup(){
        String ServProvRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Service Provider').getRecordTypeId();
        SL_SCTestData.createAccountAndContracts(3, 1);
        List<Account> testAccs = SL_SCTestData.testAccounts;
		List<Contract__c> testCont = SL_SCTestData.testContracts;        
        SL_SCTestData.createInsurancesAndContractAssets(1, 2);
        List<Contract_Asset__c> ContAs = SL_SCTestData.testCAssets;
        Contract__c con = testCont[0];
        Account DealerAcc = testAccs[1];
        DealerAcc.RecordTypeId = SL_SCTestData.DEALER_ACC;
        con.Dealer_Name__c = DealerAcc.Id;
        Contract_Asset__c ca = ContAs[1];
        Account serviceProv = testAccs[2];
        serviceProv.RecordTypeId=ServProvRecordTypeID;
        serviceProv.Return_Authorization_Email__c ='test@testingemail.com';
        ca.Service_Provider__c = serviceProv.Id;
        ca.Return_Auth_Create_Date__c = Date.Today().addDays(-1);
        ca.Return_Authorization__c = true;
        Schema.Location testLoc = new Schema.Location();
        testLoc.Name = 'Test Location 1';
        testLoc.LocationType = 'Building';
        testLoc.Service_Provider__c = serviceProv.Id;
        testLoc.Is_Active__c = true;
        insert testLoc;
        ca.Location__c = testLoc.Id;
        update DealerAcc;
        update con;
        update serviceProv;
        update ca;
    }
    @isTest
    static void testBatch(){
       Test.startTest();
        SL_ContractAssetReport testReports = new SL_ContractAssetReport();
		ID testReportBatch = Database.executeBatch(testReports);
        Test.stopTest();
    }
    
    @isTest
    static void testBatch2(){
       Test.startTest();
        SL_ContractAssetReportUnified testReports = new SL_ContractAssetReportUnified();
		ID testReportBatch = Database.executeBatch(testReports);
        Test.stopTest();
    }
}