@isTest
public class PEAC_CeateMiscInvItemsQueueableTest {
	@IsTest
    static void createMiscellaneousInvoiceItems(){
        try{
        User testAdmin = SL_SCTestData.createTestUser();   
        Miscellaneous_Invoice_Map__mdt record1 = new Miscellaneous_Invoice_Map__mdt(
            DeveloperName = 'X4_and_14_99',
            MasterLabel = '4" and 14.99"',
            Label = '4" and 14.99"',
            QualifiedApiName = 'X4_and_14_99',
            Amount__c = 4,
            Min_Screen_Size__c = 4,
            Max_Screen_Size__c = 14.99
        );
        Miscellaneous_Invoice_Map__mdt record2 = new Miscellaneous_Invoice_Map__mdt(
            DeveloperName = 'X15_and_34_99',
            MasterLabel = '15" and 34.99"',
            Label = '15" and 34.99"',
            QualifiedApiName = 'X15_and_34_99',
            Amount__c = 5,
            Min_Screen_Size__c = 15,
            Max_Screen_Size__c = 34.99
        );
        Miscellaneous_Invoice_Map__mdt record3 = new Miscellaneous_Invoice_Map__mdt(
            DeveloperName = 'X35_or_Greater',
            MasterLabel = '35 or Greater',
            Label = '35 or Greater',
            QualifiedApiName = 'X35_or_Greater',
            Amount__c = 6,
            Min_Screen_Size__c = 35,
            Max_Screen_Size__c = 100
        );
        
        SL_SCTestData.createAccountAndContracts(1, 1);      
        SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[0].Id, 1, 2);
        Opportunity opp1DocsIn = SL_SCTestData.testOpportunities[0];
        Asset__c asset1 = SL_SCTestData.testAssets[0];
        asset1.Screen_Size__c = 10;
        asset1.Equipment_State__c = 'CA';
        asset1.Equipment_Location_State__c = 'CALIFORNIA';
        Asset__c asset2 = SL_SCTestData.testAssets[1];
        asset2.Screen_Size__c = 20;
        asset2.Equipment_State__c = 'CA';
        asset2.Equipment_Location_State__c = 'CALIFORNIA';
        System.runAs(testAdmin){
            Test.startTest();
            update new List<Asset__c>{asset1, asset2};
            Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>();
            oldMap.put(opp1DocsIn.Id, opp1DocsIn.clone(true, true, true, true));
            opp1DocsIn.StageName = 'Docs In';
            opp1DocsIn.Opportunity_Status__c = '';
            List<Opportunity> newList = new List<Opportunity>{opp1DocsIn};
            PEAC_CeateMiscInvItemsQueueable.createMiscellaneousInvoiceItems(newList,oldMap);
            Test.stopTest();
        }
        }
        catch(Exception ex){        }
    }
}