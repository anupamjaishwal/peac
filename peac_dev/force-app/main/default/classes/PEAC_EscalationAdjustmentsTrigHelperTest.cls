/**************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description:This test class validate the business logic of Pool Trigger and Escalation Adjs Trigger Handlers
                and Helper classs
@User Story:DP-1090
@Created Date:July-24-2024
**************************************************************************************************************/
@isTest
Private with sharing class PEAC_EscalationAdjustmentsTrigHelperTest {
    /************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)    
    @Description: Testsetup method to create test data for the test class
    ************************************************************************************/
    @TestSetup
    static void createTestData(){
        SL_SCTestData.createAccountAndContracts(3,1);
    }
     
    
    /************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)     
    @Description: createEscalationTest method is testing the 
					Escalation creation details
    ************************************************************************************/
    @isTest
    static void createEscalationTest()
    {
        List<Account> accountList = [SELECT Id,OwnerId,Name FROM Account ];
        //create pools record
        List<Pool__c> poolList = new List<Pool__c>();
        for(integer i=0;i<3;i++){
            poolList.add(new Pool__c(Current_Rate__c =i+1,Dealer__c = accountList[1].Id, Customer__c=accountList[0].Id,Pool_Id__c ='Pool '+i,Read_Cycle__c = 'Yearly'));
        }
        insert poolList;
        //create escalation record 
        
        List<Escalation_Adjustments__c> escAdjList = new List<Escalation_Adjustments__c>();
        for(integer i=0;i<3;i++){
            escAdjList.add(new Escalation_Adjustments__c(Adjustment_Method__c = 'Fixed',Adjustment_Value__c=10,Audit_Pool__c=poolList[0].Id, Effective_Date__c= System.today().addYears(i)));
        }
        for(integer j=4;j<6;j++){
            escAdjList.add(new Escalation_Adjustments__c(Adjustment_Method__c='Percentage',Adjustment_Value__c=10,Audit_Pool__c=poolList[0].Id, Effective_Date__c= System.today().addYears(j)));
        }
        insert escAdjList;
        escAdjList.clear();
        for(integer j=7;j<8;j++){
            escAdjList.add(new Escalation_Adjustments__c(Adjustment_Method__c='Percentage',Audit_Pool__c=poolList[0].Id, Effective_Date__c= System.today().addYears(j)));
        }
        insert escAdjList;
        test.startTest();
        poolList[0].Current_Rate__c = 11.00;
        update poolList;
        test.stopTest();
        List<Pool__c> UpdatedPoolList = [SELECT Current_Rate__c FROM Pool__c WHERE Id =:poolList[0].id LIMIT 1];
        Assert.areEqual(UpdatedPoolList[0].Current_Rate__c, poolList[0].Current_Rate__c, 'Pool Current Rate is not updated');// Positive Test
    }
}