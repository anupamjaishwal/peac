/**************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description:This test is used in pEAC_MeterCase lwc component where dealer user will be creating a meter read
case.
@User Story:DP-957
@Created Date:July-03-2024
**************************************************************************************************************/
@isTest
Private with sharing class PEAC_MeterReadCaseController_Test {
    /************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)    
@Description: Testsetup method to create test data for the test class
************************************************************************************/
    @TestSetup
    static void createTestData(){
        SL_SCTestData.createAccountAndContracts(3,1);
        SL_SCTestData.createManufacturer(1,True);
    }
    
    
    /************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)     
@Description: getDetailedCaseTest method is testing the 
Case details
************************************************************************************/
    @isTest
    static void getDetailedCaseTest()
    {
        List<Account> accountList = [SELECT Id,OwnerId FROM Account];
        user dpUser = SL_SCTestData.createDPDataForUser(accountList[0]);
        system.runAS(dpUser)
        {
            test.StartTest();
            Map<String,String> reasonNameMap = PEAC_MeterReadCaseController.getCaseReason();
            List<String> reasonList =  reasonNameMap.values();
            PEAC_MeterReadCaseController.getDetailedCase(reasonList[1]); 
            PEAC_MeterReadCaseController.getDetailedCase(reasonList[0]); 
            Assert.areEqual(reasonNameMap.size(), reasonList.size(), 'There is no case reason.');// Positive test case            test.StopTest();
        }
        
    }
    
}