@isTest
public with sharing class TC_ValidateCreditChecklistDocsInTest {
    @TestSetup
    static void dataSetup(){

        User u = [SELECT Id, Vendor_Team__c FROM User WHERE Id = :UserInfo.getUserId()];
        u.Vendor_Team__c = 'OEG';
        update u;

        ORE__c o = new ORE__c(Bypass__c = true);
        insert o;

        List < TC_Origination__Checklist_Template__c> templates = new List <TC_Origination__Checklist_Template__c>  {new TC_Origination__Checklist_Template__c (TC_Origination__API_Name__c = 'Credit Stips',  Name = 'Credit Stips'), new TC_Origination__Checklist_Template__c (TC_Origination__API_Name__c = 'Loan Credit Stips'), new TC_Origination__Checklist_Template__c (TC_Origination__API_Name__c = 'Funding Booking Lease', Name = 'Funding Booking Lease'), new TC_Origination__Checklist_Template__c (TC_Origination__API_Name__c = 'Funding Booking Loan'), new TC_Origination__Checklist_Template__c (TC_Origination__API_Name__c = 'Loan Credit Stips')};
        insert templates;
        insert new List <TC_Origination__Checklist_Template_Item__c > {
            new TC_Origination__Checklist_Template_Item__c (
                TC_Origination__Checklist_Template__c = templates[0].Id, 
                Name = 'Municipal addendum')
            , new TC_Origination__Checklist_Template_Item__c (
                TC_Origination__Checklist_Template__c = templates[1].Id, 
                Name = 'Municipal addendum')
            , new TC_Origination__Checklist_Template_Item__c (
                TC_Origination__Checklist_Template__c = templates[templates.size() -2].Id, 
                Name = 'Municipal addendum', 
                TC_Origination__Included__c  = true)
            ,  new TC_Origination__Checklist_Template_Item__c (
                TC_Origination__Checklist_Template__c = templates[templates.size() -1].Id, 
                Name = 'Municipal addendum', 
                TC_Origination__Included__c  = true)
            , new TC_Origination__Checklist_Template_Item__c (
                TC_Origination__Checklist_Template__c = templates[0].Id, 
                Name = 'ACH Guarantee Form', 
                TC_Origination__API_Name__c = 'ACH Guarantee Form',
                TC_Origination__Included__c  = true)};
        Account acc = new Account (Name = 'test', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Franchisee Account').getRecordTypeId());
        insert acc;
        Opportunity opp = new Opportunity (Name = 'checklistTest', StageName = 'test', CloseDate = Date.today () + 10, AccountId = acc.Id, Primary_Source__c = 'Direct Mail', Stipulations__c = 'Municipal addendum');
        insert opp;
        Test.startTest();
        insert new List <TC_Origination__Checklist__c> {new TC_Origination__Checklist__c (TC_Origination__Opportunity__c = opp.Id, TC_Origination__API_Name__c = 'Credit Stips', Name = 'Credit Stips', TC_Origination__Checklist_Template__c = templates[0].Id), new TC_Origination__Checklist__c (TC_Origination__Opportunity__c = opp.Id, TC_Origination__API_Name__c = 'Loan Credit Stips', Name = 'Loan Credit Stips', TC_Origination__Checklist_Template__c = templates[1].Id)};
        opp.Stipulations__c = 'ACH Guarantee Form';
        opp.Waived_Stipulations__c = 'Municipal addendum';
        opp.Received_Stipulations__c = 'Municipal addendum';

        update opp;
        Test.stopTest();

    }

    @IsTest
    public static void ValidateCreditChecklistDocsInTest(){
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, Docs_In__c, Channel__c, record_type_name__c, RecordTypeId, StageName, Loan_Record_Type__c FROM Opportunity]);
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>([SELECT Id, Docs_In__c, Channel__c, record_type_name__c, RecordTypeId, Loan_Record_Type__c, StageName FROM Opportunity]);

        for(Id key : newMap.keyset()){
            newMap.get(key).Docs_In__c = Date.Today();
        }
            try{
                TC_ValidateCreditChecklistDocsIn.validateCreditChecklistDocsIn(oldMap,newMap);
                }
                catch (DmlException e) {
                    System.debug(e.getMessage());
                    System.debug(e.getStackTraceString());
                }
                catch (Exception e) {
                    System.debug(e.getMessage());
                    System.debug(e.getStackTraceString());
                }
    }

}