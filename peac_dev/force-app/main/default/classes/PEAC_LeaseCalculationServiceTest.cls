@isTest 
public class PEAC_LeaseCalculationServiceTest {
    
    @TestSetup
    public static void setupAssetTest () {
		PEAC_GenerateTaxMatrixBatch.isRunning = true;
        Account acc = new Account (Name = 'test');
        insert acc;
        Opportunity opp = new Opportunity (CloseDate = Date.today()+10,Name='test',AccountId=acc.Id,Equipment_Cost__c=50000,StageName='Decision',
                                           Account_Business_Street__c='208 East 58th St' , Account_Business_City__c ='New York',Account_Business_State_Province__c ='NY' , 
                                           Account_Business_Zip_Postal_Code__c='10022',Hard_Lease_Rate_Factor__c = 0.05,Soft_Lease_Rate_Factor__c = 0.10 );
        insert opp;
        insert new Asset__c (End_User_Billing_Address__c = true, Quantity__c = 1, Equipment_Code__c = 'ATM',Opportunity_Contract_Type__c='TL',
                             Usage_User_Table__c = '1',Equipment_Sub_Category__c = 'ATM', Opportunity__c = opp.Id, Cost__c = 0);
        
        insert new Marlin_Configuration__c(Disable_Standard_Asset_Generation__c = false);
    }
    
    @IsTest
    public static void updateAssetsFromOpportunityAsyncTest(){
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        
        Opportunity opp = [ SELECT Id, Hard_Lease_Rate_Factor__c, Soft_Lease_Rate_Factor__c  FROM Opportunity ];
        Set<Id> oppIds = new Set<Id>{opp.Id};
        
        Test.startTest();
        PEAC_LeaseCalculationService.updateAssetsFromOpportunityAsync(oppIds);
        Test.stopTest();
                       
    }

}