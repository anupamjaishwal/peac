//DP-904 - Carlos Herrera
@isTest
public class SL_ContractInvoicedSummaryTest {
    @isTest
    public static void dataTest(){
        SL_SCTestData.createAccountAndContracts(1, 1);
        Contract_Invoiced_Amount__c cia = new Contract_Invoiced_Amount__c();
        cia.CCAN__c = SL_SCTestData.testAccounts[0].Id;
        cia.Contract__c = SL_SCTestData.testContracts[0].Id;
        cia.Type__c = 'Service';
        cia.Current_Amount_Due__c = 100.00;
        cia.Past_Due__c = 100.00;
        cia.Total__c = 200.00;
        insert cia;
        Test.startTest();
        List<Map<String,Object>> testList = SL_ContractInvoicedSummary.SummaryAccount(cia.CCAN__c);
        Test.stopTest();
    }

}