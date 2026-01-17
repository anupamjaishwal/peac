/********************************************************************************************************************
@Author:Vinod Rathod(LTIMindtree)
@Description: This test class is reasponsilbe to generate CCID number.
@User Story:SAL-5449
@Created Date:July-14-2024 	    
*********************************************************************************************************************/
@isTest
public class PEAC_AutoCCIDNumberTest {
    @isTest
    Public static void updateCCIDNumberTest(){
        // Create a test Account
        SL_SCTestData.createAccountAndContracts(5,1);
        List<Account> testAccounts = [SELECT Id,CCID__c,RecordTypeId FROM Account LIMIT 5];
        
        for(Account acc : testAccounts){
            acc.CCID__c= null;
        }
        Update testAccounts;
        
        Map<Id, Account> newMap = new Map<Id, Account>();
        
        for(Account acc : testAccounts){
            
            newMap.put(acc.id,acc);
        }
        test.startTest();
        PEAC_AutoCCIDNumber.createCCID(newMap);
        test.stopTest();
        Account accountRecord = [SELECT Id,CCID__c,RecordTypeId FROM Account LIMIT 1];
        assert.areNotEqual(accountRecord.CCID__c,Null,'Account CCID Should Not be Null');
          
    }

}