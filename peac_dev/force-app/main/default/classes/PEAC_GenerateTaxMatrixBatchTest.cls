@isTest
public class PEAC_GenerateTaxMatrixBatchTest {
    @testSetup
    public static void setupAssetTest () {
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        Account acc = new Account (Name = 'test');
        insert acc;
        Opportunity opp = new Opportunity (
            CloseDate = Date.today() + 10, Name = 'test', AccountId = acc.Id, Equipment_Cost__c = 50000,
            StageName = 'Decision'
        );
        insert opp;
        Test.startTest();
        insert new Asset__c (
            End_User_Billing_Address__c = true, Quantity__c = 1, Equipment_Code__c = 'ATM', 
            Equipment_Sub_Category__c = 'ATM', Opportunity__c = opp.Id, Cost__c = 0,
        	Equipment_Location_City__c='TUCSON',Equipment_Location_County__c='PIMA',Equipment_Location_State__c='ARIZONA');
        Marlin_Configuration__c mc = new Marlin_Configuration__c(Disable_Standard_Asset_Generation__c = false);
        insert mc;
        Test.stopTest();
        
        Miscellaneous_Billable_Item__c miscBillableItem = new Miscellaneous_Billable_Item__c(Opportunity__c = opp.Id,Misc_GL_Code__c = '0000 - NOT ON FILE');
        insert miscBillableItem;
        
        List<Miscellaneous_Invoice_Item__c> miscInvoiceItems = new List<Miscellaneous_Invoice_Item__c>{
            new Miscellaneous_Invoice_Item__c(Opportunity__c = opp.Id, GL_Code__c = '0000 - NOT ON FILE'),
            new Miscellaneous_Invoice_Item__c(Opportunity__c = opp.Id, GL_Code__c = '0003 - OneTime Documentation Fee'),
            new Miscellaneous_Invoice_Item__c(Opportunity__c = opp.Id, GL_Code__c = '0005 - Security Deposit')};
        insert miscInvoiceItems;
    }
    @isTest public static void PopulateAssetListPriceTest(){
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        Tax_Rules_Settings__c settings = new Tax_Rules_Settings__c();
        settings.Parent_Object__c = 'Opportunity';
        settings.Rate_Object__c = 'Rate__c';
        settings.Rate_State_Field__c = 'State__c';
        settings.Rate_County_Field__c = 'County__c';
        settings.Rate_City_Field__c = 'City__c';
        settings.Rate_Code_Field__c = 'Rate_Code__c';
        settings.State_Tax_Rate_Field__c = 'State_Tax_Rate__c';
        settings.County_Tax_Rate_Field__c = 'County_Tax_Rate__c';
        settings.TCounty_Tax_Rate_Field__c = 'County_Transit_Tax_Rate__c';
        settings.City_Tax_Rate_Field__c = 'City_Tax_Rate__c';
        settings.TCity_Tax_Rate_Field__c = 'City_Transit_Tax_Rate__c';
        settings.Tax_Parent_Object_Field__c = 'Opportunity__c';
        settings.Parent_Generate_Tax_Matrix_Message_Field__c = 'Description';
        settings.Parent_Tax_Calculation_Begin_Field__c = 'Last_Tax_Calculation_Begin__c';
        settings.Parent_Tax_Calculation_Complete_Field__c = 'Last_Tax_Calculation_Complete__c';
        settings.Parent_Tax_Calculation_Successful_Field__c = 'Last_Tax_Calculation_Successful__c';
        settings.Parent_Tax_Calculation_Error_Field__c = 'Last_Tax_Calculation_Error_Details__c';
        settings.Parent_Tax_Calculation_In_Progress_Field__c = 'Is_Tax_Calculation_In_Progress__c';
        settings.Tax_Calculation_Completion_Alert_Seconds__c = 90;
        insert settings;
        
        List<Opportunity> opps = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        PEAC_GenerateTaxMatrixBatch taxBatch = new PEAC_GenerateTaxMatrixBatch(new Set<Id>{opps[0].Id}, true);
        Database.executeBatch(taxBatch, 5);
        Test.stopTest();
    }
}