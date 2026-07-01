/********************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This test calss is used to make a api call to onboard dealers in infolease.
@User Story:SAL-6561
@Created Date:January-16-2026 	    
*********************************************************************************************************************/

@isTest
private class PEAC_SendDealerToInfoleaseBatchTest {

     /************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)    
@Description: Testsetup method to create test data for the test class
************************************************************************************/
    @TestSetup
    static void createTestData(){
        SL_SCTestData.createAccountAndContracts(3,1);
        SL_SCTestData.createManufacturer(1,True);
    }
    @isTest
    static void sendDealerInfolease()
    {
        Test.StartTest();
        
        
        String theQuery = '';
        String type = 'Dealer Account';
        String dateString = '2026-01-01T00:00:00Z';
        String userIdString = UserInfo.getUserId();
        theQuery = 'SELECT Id FROM ACCOUNT WHERE RecordType.Name = \'' + type + '\' AND CreatedDate >= 2026-01-01T00:00:00Z AND CreatedById = ' + '\'' + userIdString + '\'';
        PEAC_SendDealerToInfoleaseBatch batch = new PEAC_SendDealerToInfoleaseBatch(theQuery);
        Database.executeBatch(batch,20);
        Test.stopTest();
    }
}