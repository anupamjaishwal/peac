@isTest
public class SL_ReturnAuthorizationControllerTest {

    @isTest
    static void testSetFieldsGroupedByAddressPartialBuyout() {
        // Create necessary test data using SL_SCTestData methods
        SL_SCTestData.createAccountAndContracts(3, 1);
        SL_SCTestData.createInsurancesAndContractAssets(3, 2); // Creating 1 insurance with 2 contract assets
        SL_SCTestData.updateCAssetsWithLocation(2, 4);
        Contract__c theContract = SL_SCTestData.testContracts[2];
        // Create a Buyout__c record with Partial_Buyout__c set to true
        Buyout__c buyout = new Buyout__c(
            Contract__c = theContract.Id,
            Name = 'TestBuyout',
            Quote_Sequence__c = '2',
            Partial_Buyout__c = true
        );
        insert buyout;

        // Create Buyout_Asset__c records linked to the Buyout__c
        List<Buyout_Asset__c> buyoutAssets = new List<Buyout_Asset__c>();
        for(Integer i = 4; i < SL_SCTestData.testCAssets.size(); i++){
            Contract_Asset__c asset = SL_SCTestData.testCAssets[i];
            buyoutAssets.add(new Buyout_Asset__c(
                Buyout__c = buyout.Id,
                Contract_Asset__c = asset.Id
            ));
        }
        insert buyoutAssets;

        // Setup the test context with page parameters
        ApexPages.StandardController sc = new ApexPages.StandardController(theContract);
        ApexPages.currentPage().getParameters().put('contractId', theContract.Id);
        ApexPages.currentPage().getParameters().put('buyoutSeq', '2');

        // Initialize the controller
        SL_ReturnAuthorizationController controller = new SL_ReturnAuthorizationController();

    }

}