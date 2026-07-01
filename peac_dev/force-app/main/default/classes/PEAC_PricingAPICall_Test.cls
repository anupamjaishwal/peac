@IsTest
public class PEAC_PricingAPICall_Test {

    @TestSetup
    static void setupData() {
        // Create Accounts
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Opportunities (initial stage NOT Proposal)
        List<Opportunity> opps = new List<Opportunity>{
            new Opportunity(
                Name = 'Opp Without Quote',
                StageName = 'Qualification',
                CloseDate = Date.today().addDays(30),
                AccountId = acc.Id
            ),
            new Opportunity(
                Name = 'Opp With Quote',
                StageName = 'Qualification',
                CloseDate = Date.today().addDays(30),
                AccountId = acc.Id
            )
        };
        insert opps;

        // Add a TValue Quote for the second opportunity
        tval__TValue_Quote__c quote = new tval__TValue_Quote__c(
            tval__Opportunity__c = opps[1].Id
        );
        insert quote;
    }

    @IsTest
    static void test_tValuePricing() {
        // Load test data
        List<Opportunity> opps = [
            SELECT Id, StageName
            FROM Opportunity
            ORDER BY Name
        ];
			System.Debug('oldOpp....'+opps);
            //System.Debug('newOpp.StageName ....'+newOpp.StageName);
        Opportunity oppWithoutQuote = New Opportunity();
        Opportunity oppWithQuote = New Opportunity();
        oppWithoutQuote.Id = opps[0].Id;
        oppWithoutQuote.StageName = PEAC_ConstantClass.OPPORTUNITY_STAGENAME_PROPOSAL;
        oppWithQuote.Id = opps[1].Id;
        oppWithQuote.StageName = PEAC_ConstantClass.OPPORTUNITY_STAGENAME_PROPOSAL;
        
        

        // Simulate stage change to Proposal
        
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>{ 
            oppWithoutQuote.Id => oppWithoutQuote,
            oppWithQuote.Id => oppWithQuote
        };

        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{ 
            opps[0].Id => opps[0],
            opps[1].Id => opps[1]
        };
		test.StartTest();
        System.Debug('oldOpp....'+oldMap);
       	PEAC_PricingAPICall.tValuePricing(newMap,oldMap);
		test.Stoptest();
       
    }
}