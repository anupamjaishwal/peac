@isTest
public class TC_GenerateTaxMatrixCtrlTest {


    @testsetup
    static void setupTest() {
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
        
        Rate__c rate = new Rate__c();
        rate.State__c = 'MN';
        rate.County__c = 'WASHINGTON';
        rate.City__c = 'WOODBURY';
        rate.State_Code__c = '24';
        rate.County_Code__c = '163';
        rate.City_Code__c = '1740';
        rate.Rate_Code__c = '001';
        rate.State_Tax_Rate__c = 0.01;
        rate.County_Tax_Rate__c = 0.01;
        rate.County_Transit_Tax_Rate__c = 0.01;
        rate.City_Tax_Rate__c = 0.01;
        rate.City_Transit_Tax_Rate__c = 0.01;
        insert rate;
        
        TCRE__Rule_Config__c conf = new TCRE__Rule_Config__c();
        conf.TCRE__SObject_Name__c = 'Opportunity';
        conf.TCRE__Priority__c = 1;
        insert conf;
        
        TCRE__Rule_Condition__c cond1 = new TCRE__Rule_Condition__c();
        cond1.TCRE__Field_Name__c = 'StageName';
        cond1.TCRE__Operator__c = '=';
        cond1.TCRE__Value__c = 'test';
        cond1.TCRE__Rule_Config__c = conf.Id;
        insert cond1;

        TCRE__Rule_Condition__c cond2 = new TCRE__Rule_Condition__c();
        cond2.TCRE__Field_Name__c = 'CreatedDate';
        cond2.TCRE__Operator__c = '>';
        cond2.TCRE__Value__c = '12/12/2010';
        cond2.TCRE__Rule_Config__c = conf.Id;
        insert cond2;
        
        TCRE__Rule_Condition__c cond3 = new TCRE__Rule_Condition__c();
        cond3.TCRE__Field_Name__c = 'Amount';
        cond3.TCRE__Operator__c = '<';
        cond3.TCRE__Value__c = '234.56';
        cond3.TCRE__Rule_Config__c = conf.Id;
        insert cond3;
        
        Tax_Rule__c tr = new Tax_Rule__c();
        tr.Rule_Config__c = conf.Id;
        tr.State__c = 'MN';
        tr.Tax_Basis_Field__c = 'Amount';
        tr.Rate_Code_to_Use__c = '001';
        tr.Description__c = 'Description';
        tr.Tax_type__c = 'Regular';
        tr.State_Rate_Code_to_Use__c = '001';
        tr.County_Rate_Code_to_Use__c = '001';
        tr.TCounty_Rate_Code_to_Use__c = '001';
        tr.City_Rate_Code_to_Use__c = '001';
        tr.TCity_Rate_Code_to_Use__c = '001';
        insert tr;
        
        Account acc = new Account (Name = 'testtax', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId());
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.StageName = 'test';
        opp.CloseDate = Date.today();
        opp.Amount = 123.45;
        opp.Name = 'test';
        opp.AccountId = acc.Id;
        opp.Tax_State__c = 'MN';
        opp.Tax_County__c = 'WASHINGTON';
        opp.Tax_City__c = 'WOODBURY';
        insert opp;
        
        Asset__c asst = new Asset__c();
        asst.Opportunity__c = opp.Id;
        asst.Equipment_City__c = 'Seattle';
        asst.Equipment_State__c = 'IL';
        asst.Equipment_Zip__c = '60607';
        insert asst;
        
        /*
        TC_GenerateTaxMatrixCtrl.generateTaxMatrix(asst.Id);
        
        try {
            TC_GenerateTaxMatrixCtrl.generateTaxMatrix(opp.Id);
        }
        catch (Exception e) {
        }*/
    }
    @isTest
    public static void testOpp () {
    
        Id oppId = [select id from opportunity where name = 'test'][0].Id;
        /*
        Asset__c asst = new Asset__c();
        asst.Opportunity__c = oppId;
        asst.Equipment_City__c = 'Seattle';
        insert asst;*/
        
        Test.startTest ();
        try {
        
            TC_GenerateTaxMatrixCtrl.generateTaxMatrix(oppId);
        } catch (Exception e) {
        }
        
        Test.stopTest ();
    
    }
  @isTest
    public static void testAsset () {
        Id assetId = [select id from asset__c LIMIT 1].Id; 
        
        Test.startTest ();
        TC_GenerateTaxMatrixCtrl.generateTaxMatrix(assetId);
        Test.stopTest ();
    }
}