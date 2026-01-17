/**************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This test class is validating Manufacturer Number generation
@User Story:SAL-5019
@Created Date:September-25-2024   
**************************************************************************************************************/
@isTest
private class PEAC_ManufacturerNumberClassTest {
/************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)    
@Description: Testsetup method to create test data for the test class
************************************************************************************/
    @TestSetup
    static void createTestData(){
        SL_SCTestData.createAccountAndContracts(3,1);
    }
    
    
    
    @isTest
    static void createManufacturerTest()
    {
		test.StartTest();
      	SL_SCTestData.createManufacturer(1, True);
        List<Account> acclist  = [SELECT ID, Type FROM Account WHERE Type ='M'];
        assert.areEqual(acclist[0].Type, 'M', 'There is no Manufacturer created');// Positive test case
        test.StopTest();    
    }
    
}