/**
 * Created by trohweder on 2/25/21.
 * Test coverage for TC_OpportunityDealerContactValidation.validateDealerContacts SAL-2234
 * Edited to prevent soql error for SAL-2903
 */

@IsTest
public with sharing class TC_OpportunityDealerConValidationTest {

    @TestSetup
    public static void createTestData(){

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

        ORE__c setting = new ORE__c();
        setting.StageBypass__c = true;
        insert setting;

        Test.startTest();

        Account acc = new Account();
        acc.Name = 'Test';
        acc.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'End User Account' LIMIT 1].Id;
        acc.Tax_ID__c = '888776666';
        acc.Business_Phone__c = '5555555555';
        acc.BillingCity = 'asdfa';
        acc.BillingState = 'Minnesota';
        acc.BillingStreet = 'cxvz';
        acc.BillingPostalCode = '55421';
        acc.Business_City__c = 'asdf';
        acc.Business_State__c = 'MN';
        acc.Business_Zip__c = '55421';
        acc.Business_Address__c = 'adsf';
        acc.Account_EU_FS_SIC_Description__c = '0100';

        insert acc;

        Contact c = new Contact();
        c.AccountId = acc.Id;
        c.FirstName = 'fn';
        c.LastName = 'ln';
        c.Phone = '6666666666';
        c.Email = 'testing2@mailinator.com';
        insert c;

        Opportunity opp = new Opportunity();
        opp.Name = 'Test';
        opp.Application__c = 'salkdjflksjdf';
        opp.RecordType = [SELECT Id FROM RecordType WHERE Name = 'Express Booking' LIMIT 1];
        opp.AccountId = acc.Id;
        opp.StageName = 'Docs In';
        opp.Primary_Source__c = 'Customer Inbound Call';
        opp.CloseDate = Date.today();
        opp.Equipment_Cost__c = 0;
        opp.Terms__c = 24;
        opp.Billing_Contact__c = c.Id;
        opp.Primary_Contact__c = c.Id;
        opp.Credit_Stips_Completed_Date__c = Date.today();
        opp.Additional_Docs__c = 'D&A';
        opp.Probability = 0.8;
        opp.Lessor__c = 1;
        opp.Tax_State__c = 'MN';
        opp.Tax_County__c = 'WASHINGTON';
        opp.Tax_City__c = 'WOODBURY';
        opp.Payment_Option__c = 'A';
        opp.Invoice_Code__c = 'M';
        opp.Equipment_Description__c = 'test';

        insert opp;

        Test.stopTest();

        Account dealerAcc = new Account();
        dealerAcc.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Dealer Account' LIMIT 1].Id;
        dealerAcc.Name = 'Test2';
        dealerAcc.Business_Phone__c = '5555555555';
        dealerAcc.Account_Dealer_Status__c = 'Active';
        insert dealerAcc;

        Contact dealerContact = new Contact();
        dealerContact.FirstName = 'first';
        dealerContact.LastName = 'last';
        dealerContact.AccountId = dealerAcc.Id;
        dealerContact.Emailage_Result__c = 'FAIL';
        dealerContact.Override_Emailage_Result__c = true;
        dealerContact.Email = 'testing@mailinator.com';
        insert dealerContact;

    }

    @IsTest
    public static void testOpportunityDealerContactValidationRule(){
        
        Opportunity opp = [SELECT Id, StageName, Account.Id, Account.NAme FROM Opportunity WHERE Name = 'Test' LIMIT 1];

        List<OpportunityContactRole> roles = new List<OpportunityContactRole>();

        OpportunityContactRole role = new OpportunityContactRole();
        role.ContactId = [SELECT Id FROM Contact WHERE LastName = 'last'].Id;
        role.OpportunityId = opp.Id;
        role.Role = 'Dealer Primary Contact';
        roles.add(role);

        OpportunityContactRole role2 = new OpportunityContactRole();
        role2.ContactId = [SELECT Id FROM Contact WHERE LastName = 'ln'].Id;
        role2.OpportunityId = opp.Id;
        role2.Role = 'Primary Contact';
        roles.add(role2);

        insert roles;

        Test.startTest();

        Dealer__c dealer = new Dealer__c();
        dealer.Opportunity__c = opp.Id;
        dealer.Dealer__c = [SELECT Id FROM Account WHERE Name = 'Test2'].Id;
        dealer.Primary_Dealer__c = true;
        insert dealer;

        Opportunity opp2 = [SELECT Id, OwnerId, StageName, Probability, 
        Gross_Finance__c, Docs_Out__c, Docs_In__c, P_O_Issued__c, Application__c, Account.Business_Phone__c,
        OnBase_Trigger_Flag__c, Booking_Sheet__c, Docs_Requested__c, AccountId, Account.Id, 
        Account.Tax_ID__c, Business_Phone__c, Tax_ID__c FROM Opportunity WHERE Name = 'Test' LIMIT 1];
        System.debug('opp2: ' + opp2);

        opp2.StageName = 'Funding';
        opp2.Probability = 0.9;
        opp2.Gross_Finance__c = 40000;
        opp2.Docs_Out__c = Date.today();
        opp2.Docs_In__c = Date.today();
        opp2.P_O_Issued__c = Date.today();
        opp2.Booking_Sheet__c = 'No';
        opp2.Docs_Requested__c = Date.today();
        user u = new user(id = opp2.OwnerId, Phone = '13456789088', MobilePhone = '23456789567');
        update u;
        try {
        update opp2;
        } catch (exception e){
        
        }
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>{opp2.Id => opp2};
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{opp2.Id => opp2};
        TC_OpportunityTriggerHandlerRefactor.afterUpdate(newMap, oldMap, new Map<Id, Account>{opp2.Account.Id=>opp2.Account});
        TC_OpportunityTriggerHandlerRefactor.afterInsert(new List<opportunity> {opp2}, new Map<Id, Account>{opp2.Account.Id=>opp2.Account});
        Test.stopTest();

    }

}