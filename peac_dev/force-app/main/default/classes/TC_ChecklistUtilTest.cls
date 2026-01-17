@isTest public class TC_ChecklistUtilTest {
    @testSetup public static void setupTemplates () {
        List < TC_Origination__Checklist_Template__c> templates = new List <TC_Origination__Checklist_Template__c>  {new TC_Origination__Checklist_Template__c (TC_Origination__API_Name__c = 'Credit Stips'), new TC_Origination__Checklist_Template__c (TC_Origination__API_Name__c = 'Loan Credit Stips'), new TC_Origination__Checklist_Template__c (TC_Origination__API_Name__c = 'Funding Booking Lease', Name = 'Funding Booking Lease'), new TC_Origination__Checklist_Template__c (TC_Origination__API_Name__c = 'Funding Booking Loan'), new TC_Origination__Checklist_Template__c (TC_Origination__API_Name__c = 'Loan Credit Stips')};
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

    @isTest public static void addStipsLeaseTest () {
        Test.startTest();
        TC_CreditApprovalAddStipsToChecklist.updateStipulations (new List <Id> {[SELECT Id FROM Opportunity WHERE Name = 'checklistTest'][0].Id});
        Test.stopTest();
    }

    @isTest public static void addStipsLoanTest () {
        Test.startTest();
        TC_CreditApprovalAddStipsToChecklistLoan.updateStipulations (new List <Id> {[SELECT Id FROM Opportunity WHERE Name = 'checklistTest'][0].Id});
        Test.stopTest();
    }

    @isTest public static void waiveStipsLeaseTest () {
        Test.startTest();
        TC_CreditApprovalWaivedReceivedStips.updateWaivedOrReceived (new List <Id> {[SELECT Id FROM Opportunity WHERE Name = 'checklistTest'][0].Id});
        Test.stopTest();
    }
    @isTest public static void waiveStipsLoanTest () {
        Test.startTest();
        TC_CreditApprovalWaivedReceivedStipsLoan.updateWaivedOrReceived (new List <Id> {[SELECT Id FROM Opportunity WHERE Name = 'checklistTest'][0].Id});
        Test.stopTest();
    }
    @isTest public static void mergeFieldTest() {
    Test.startTest ();
        TC_PopulateOppMergeFields.populateOppMergeFields(new List <Id> {[SELECT Id FROM Opportunity WHERE Name = 'checklistTest'][0].Id});
    Test.stopTest ();
    }

    @isTest public static void addFundingBookingLeaseChecklistTest () {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'checklistTest'][0];
        Id tempId = [SELECT Id FROM TC_Origination__Checklist_Template__c WHERE TC_Origination__API_Name__c = 'Funding Booking Lease'][0].Id;
        
        Test.startTest();
        insert new TC_Origination__Checklist__c (TC_Origination__Opportunity__c = opp.Id, TC_Origination__API_Name__c = 'Funding Booking Lease', Name = 'Funding Booking Lease', TC_Origination__Checklist_Template__c = tempId);
        Test.stopTest();
    }
    
    @isTest public static void addFundingBookingLoanChecklistTest () {
        //Test.startTest();
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'checklistTest'][0];
        Id tempId = [SELECT Id FROM TC_Origination__Checklist_Template__c WHERE TC_Origination__API_Name__c = 'Funding Booking Loan'][0].Id;
        Id tempLoanStipsId = [SELECT Id FROM TC_Origination__Checklist_Template__c WHERE TC_Origination__API_Name__c = 'Loan Credit Stips'][0].Id;
        TC_Origination__Checklist__c checklist = new TC_Origination__Checklist__c (TC_Origination__Opportunity__c = opp.Id, TC_Origination__API_Name__c = 'Funding Booking Loan', Name = 'Funding Booking Loan', TC_Origination__Checklist_Template__c = tempId);
        TC_Origination__Checklist__c checklistLoanStips = new TC_Origination__Checklist__c (TC_Origination__Opportunity__c = opp.Id, TC_Origination__API_Name__c = 'Loan Credit Stips', Name = 'Loan Credit Stips', TC_Origination__Checklist_Template__c = tempLoanStipsId);
        Test.startTest();
        /*TC_Origination__Checklist_Item_with_Attachments__c item = new TC_Origination__Checklist_Item_with_Attachments__c (TC_Origination__Checklist__c = checklist.Id, Name = 'tet');
        insert item;
        item.TC_Origination__Primary_Reviewer__c = true;
        update item;
        item.TC_Origination__Primary_Reviewer__c = false;
        update item;*/

        insert checklist;
        insert checklistLoanStips;
        
        List <TC_Origination__Checklist_Item_with_Attachments__c > items = new List <TC_Origination__Checklist_Item_with_Attachments__c > ([SELECT Id FROM TC_Origination__Checklist_Item_with_Attachments__c  WHERE TC_Origination__Checklist__c = :checklist.Id]);
        for (TC_Origination__Checklist_Item_with_Attachments__c item : items) {
            item.TC_Origination__Primary_Reviewer__c = true;
        }
        //update items;  //// TC_CheckListWithAttachmentsTriggerHelper is going to recursion
        for (TC_Origination__Checklist_Item_with_Attachments__c item : items) {
            item.TC_Origination__Primary_Reviewer__c = false;
        }
        //update items;
        
        List <TC_Origination__Checklist_Item_with_Attachments__c > stipItems = new List <TC_Origination__Checklist_Item_with_Attachments__c > ([SELECT Id FROM TC_Origination__Checklist_Item_with_Attachments__c  WHERE TC_Origination__Checklist__c = :checklistLoanStips.Id]);
        for (TC_Origination__Checklist_Item_with_Attachments__c item : stipItems) {
            item.TC_Origination__Primary_Reviewer__c = true;
        }
        //update stipItems; // TC_CheckListWithAttachmentsTriggerHelper is going to recursion
        for (TC_Origination__Checklist_Item_with_Attachments__c item : stipItems) {
            item.TC_Origination__Primary_Reviewer__c = false;
        }
       // update stipItems;
        Test.stopTest();
    }
    
    
    @isTest public static void addFundingBookingLoanChecklistTest1 () {
        //Test.startTest();
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'checklistTest'][0];
        Id tempId = [SELECT Id FROM TC_Origination__Checklist_Template__c WHERE TC_Origination__API_Name__c = 'Funding Booking Loan'][0].Id;
        Id tempLoanStipsId = [SELECT Id FROM TC_Origination__Checklist_Template__c WHERE TC_Origination__API_Name__c = 'Loan Credit Stips'][0].Id;
        TC_Origination__Checklist__c checklist = new TC_Origination__Checklist__c (TC_Origination__Opportunity__c = opp.Id, TC_Origination__API_Name__c = 'Funding Booking Loan', Name = 'Funding Booking Loan', TC_Origination__Checklist_Template__c = tempId);
        TC_Origination__Checklist__c checklistLoanStips = new TC_Origination__Checklist__c (TC_Origination__Opportunity__c = opp.Id, TC_Origination__API_Name__c = 'Loan Credit Stips', Name = 'Loan Credit Stips', TC_Origination__Checklist_Template__c = tempLoanStipsId);
        Test.startTest();
        /*TC_Origination__Checklist_Item_with_Attachments__c item = new TC_Origination__Checklist_Item_with_Attachments__c (TC_Origination__Checklist__c = checklist.Id, Name = 'tet');
        insert item;
        item.TC_Origination__Primary_Reviewer__c = true;
        update item;
        item.TC_Origination__Primary_Reviewer__c = false;
        update item;*/

        insert checklist;
        insert checklistLoanStips;
        
        List <TC_Origination__Checklist_Item_with_Attachments__c > items = new List <TC_Origination__Checklist_Item_with_Attachments__c > ([SELECT Id FROM TC_Origination__Checklist_Item_with_Attachments__c  WHERE TC_Origination__Checklist__c = :checklist.Id]);
        for (TC_Origination__Checklist_Item_with_Attachments__c item : items) {
            item.TC_Origination__Primary_Reviewer__c = true;
        }
        //update items;
        for (TC_Origination__Checklist_Item_with_Attachments__c item : items) {
            item.TC_Origination__Primary_Reviewer__c = false;
        }
        update items;
        
        List <TC_Origination__Checklist_Item_with_Attachments__c > stipItems = new List <TC_Origination__Checklist_Item_with_Attachments__c > ([SELECT Id FROM TC_Origination__Checklist_Item_with_Attachments__c  WHERE TC_Origination__Checklist__c = :checklistLoanStips.Id]);
        for (TC_Origination__Checklist_Item_with_Attachments__c item : stipItems) {
            item.TC_Origination__Primary_Reviewer__c = true;
        }
        //update stipItems;
        for (TC_Origination__Checklist_Item_with_Attachments__c item : stipItems) {
            item.TC_Origination__Primary_Reviewer__c = false;
        }
        update stipItems;
        Test.stopTest();
    }
}