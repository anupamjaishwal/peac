/*************************************************************************************************************************
@Author: Chalapati Murru (LTIMindtree)
@Description: This test class is used for PEAC_UpdateAssetsBlenIncItemAsync code coverage
@User Story: SAL-5692 Expo: Opportunity Refactor
@Created Date: Jan-30-2026
*************************************************************************************************************************/
@IsTest(seeAllData=false)
public class PEAC_UpdateAssetsBlenIncItemAsyncTest {
	private static Opportunity makeOpp(
        String name,
        Boolean loanRecordType,
        String stage,
        Decimal totalPaymentsSent,
        Decimal totalPaymentsSentLoan,
        DateTime bookedDt,
        Date commencementDt,
        Decimal floridaSum,
        String purchaseOptions,
        Boolean readyToDoc,
        Boolean manualFunding,
        Decimal secDeposit
    ) {
        Opportunity o = new Opportunity(
            Name = name,
            StageName = stage,
            Opportunity_Booked_Date__c = bookedDt,
            Commencement_Date__c = commencementDt,
            Purchase_Options__c = purchaseOptions,
            Ready_to_Doc__c = readyToDoc ? PEAC_ConstantClass.Yes : PEAC_ConstantClass.No,
            Manual_Funding__c = manualFunding,
            Security_Deposit__c = secDeposit,
            closeDate = DateTime.now().Date()
        );
        Account acc = TestDataFactory.createTestAccount();
        Contact con = TestDataFactory.createTestContact(acc.Id);
        Opportunity opp = TestDataFactory.createTestOpp(acc.Id);
        return opp;
    }
    
    private static Asset__c makeAsset(Id oppId, String street, String city, String state, String zip) {
        Asset__c a = new Asset__c(
            Opportunity__c = oppId,
            Equipment_Street__c = street,
            Equipment_City__c = city
        );
        insert a;
        return a;
    }
    
    private static Blended_Income_Item__c makeBII(Id oppId) {
        Blended_Income_Item__c b = new Blended_Income_Item__c(
            Opportunity__c = oppId
        );
        insert b;
        return b;
    }
    
    @IsTest static void bookedDateUpdatesBII_Test() {
        Opportunity o = makeOpp('Opp-01', false, PEAC_ConstantClass.OPPORTUNITY_STAGENAME_BOOKING,
                                0.0, 0.0, DateTime.now(), (Date)null, 0.0, (String)null, false, false,0.0);
        
        Blended_Income_Item__c bii = makeBII(o.Id);
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>{ o.Id => o };

        Test.startTest();
        o.Commencement_Date__c = DateTime.now().Date();
        update o;
        Test.stopTest();

        bii = [SELECT Begin_Date__c FROM Blended_Income_Item__c WHERE Id = :bii.Id];
        System.assertEquals(o.Commencement_Date__c, bii.Begin_Date__c, 'BII booking date should match Opp Commencement_Date__c');
    }
    
    @IsTest static void assetsQueueableTest() {
        Opportunity o = makeOpp('Opp-01', false, PEAC_ConstantClass.OPPORTUNITY_STAGENAME_BOOKING,
                                0.0, 0.0, DateTime.now(), (Date)null, 0.0, (String)null, false, false,0.0);
        
		makeAsset(o.Id, '1 Main', 'CityA', 'AL', '12345');
        Test.startTest();
        o.Opportunity_Booked_Date__c = DateTime.now().Date();
        update o;
        Test.stopTest();
	}
    
}