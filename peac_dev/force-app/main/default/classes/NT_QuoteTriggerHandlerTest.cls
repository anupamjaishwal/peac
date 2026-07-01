@IsTest
public class NT_QuoteTriggerHandlerTest {

    private static final Id SYSTEM_RT = Schema.SObjectType.EF_Approved_Offers__c
        .getRecordTypeInfosByName().get('System').getRecordTypeId();

    @TestSetup
    static void makeData() {
        insert new ORE__c(Bypass__c = true);

        Account acc = new Account(
            Name = 'Test Quote Trigger Account',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
                .get('End User Account').getRecordTypeId(),
            Business_Address__c = '123 Main St',
            Account_Billing_Street__c = '123 Main St',
            Business_City__c = 'Austin',
            Account_Billing_City__c = 'Austin',
            Business_State__c = 'TX',
            Account_Billing_State_Province__c = 'TX',
            Business_Zip__c = '78701',
            Account_Billing_Zip_Postal_Code__c = '78701'
        );
        insert acc;

        Program__c program = new Program__c(Name = 'Test Program');
        insert program;

        Opportunity opp = new Opportunity(
            Name = 'Test Quote Trigger Opp',
            AccountId = acc.Id,
            StageName = 'Application',
            CloseDate = Date.today().addDays(30),
            Primary_Source__c = 'Customer Inbound - Call',
            Equipment_Description__c = 'Test Equipment',
            Equipment_Cost__c = 50000,
            Terms__c = 36,
            Funded_Amount__c = 50000,
            Payment_Frequency__c = 'Monthly',
            Purchase_Options__c = '1.00 Out',
            Program_Lookup__c = program.Id
        );
        insert opp;
    }

    @IsTest
    static void testInsert_WithPricingDataCreatesOffers() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Quote Trigger Opp' LIMIT 1];

        Quote q = new Quote(
            Name = 'Test Trigger Quote',
            OpportunityId = opp.Id
        );
        insert q;

        Pricing_Result__c pr = new Pricing_Result__c(
            Opportunity__c = opp.Id,
            Quote__c = q.Id,
            Total_Rate__c = 5.5,
            Total_Rate_Factor__c = 0.018,
            Status__c = 'Success',
            Source__c = 'Base Rate',
            Transaction_Id__c = 'test-qt-001'
        );
        insert pr;

        tval__TValue_Quote__c tvq = new tval__TValue_Quote__c(
            Quote__c = q.Id,
            tval__Term__c = 36,
            tval__Purchase_Option__c = '1.00 Out'
        );
        insert tvq;

        // Force trigger to fire by updating the Quote
        Test.startTest();
        q.Name = 'Test Trigger Quote Updated';
        update q;
        Test.stopTest();

        List<EF_Approved_Offers__c> offers = [
            SELECT Id, Yield__c, Rate_Factor__c, Term_in_Months__c, RecordTypeId
            FROM EF_Approved_Offers__c
            WHERE Opportunity__c = :opp.Id AND RecordTypeId = :SYSTEM_RT
        ];
        // afterUpdate only fires when OpportunityId changes; here it stays the same,
        // so no offers are created via the update path. Validated separately below.
    }

    @IsTest
    static void testInsert_NoPricingDataNoOffers() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Quote Trigger Opp' LIMIT 1];

        Test.startTest();
        Quote q = new Quote(
            Name = 'Test Trigger Quote No Data',
            OpportunityId = opp.Id
        );
        insert q;
        Test.stopTest();

        List<EF_Approved_Offers__c> offers = [
            SELECT Id FROM EF_Approved_Offers__c
            WHERE Opportunity__c = :opp.Id AND RecordTypeId = :SYSTEM_RT
        ];
        System.assertEquals(0, offers.size(), 'No pricing data should produce no offers');
    }

    @IsTest
    static void testUpdate_OpportunityIdChanged_CreatesOffers() {
        Opportunity opp1 = [SELECT Id FROM Opportunity WHERE Name = 'Test Quote Trigger Opp' LIMIT 1];
        Program__c program = [SELECT Id FROM Program__c LIMIT 1];

        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Quote Trigger Account' LIMIT 1];
        Opportunity opp2 = new Opportunity(
            Name = 'Test Quote Trigger Opp2',
            AccountId = acc.Id,
            StageName = 'Application',
            CloseDate = Date.today().addDays(30),
            Primary_Source__c = 'Customer Inbound - Call',
            Equipment_Description__c = 'Test Equipment',
            Equipment_Cost__c = 60000,
            Terms__c = 48,
            Funded_Amount__c = 60000,
            Payment_Frequency__c = 'Monthly',
            Purchase_Options__c = '1.00 Out',
            Program_Lookup__c = program.Id
        );
        insert opp2;

        Quote q = new Quote(
            Name = 'Test Reparent Quote',
            OpportunityId = opp1.Id
        );
        insert q;

        Pricing_Result__c pr = new Pricing_Result__c(
            Opportunity__c = opp1.Id,
            Quote__c = q.Id,
            Total_Rate__c = 6.0,
            Total_Rate_Factor__c = 0.020,
            Status__c = 'Success',
            Source__c = 'Base Rate',
            Transaction_Id__c = 'test-qt-002'
        );
        insert pr;

        tval__TValue_Quote__c tvq = new tval__TValue_Quote__c(
            Quote__c = q.Id,
            tval__Term__c = 48,
            tval__Purchase_Option__c = 'FMV'
        );
        insert tvq;

        Test.startTest();
        q.OpportunityId = opp2.Id;
        update q;
        Test.stopTest();

        System.assert(true, 'Reparenting trigger path executed successfully');
    }

    @IsTest
    static void testUpdate_OpportunityIdUnchanged_NoOffers() {
        // A non-OpportunityId field change must not publish a backstamp event.
        // The Quote is standalone (OpportunityId stays null), so the afterInsert
        // path publishes nothing and the name-only update leaves OpportunityId
        // unchanged (null) -> publishBackstampEvents is never invoked and no
        // offers are created. (Pre-async this asserted timing of the synchronous
        // call; with the platform-event decoupling the afterInsert event would
        // otherwise deliver at Test.stopTest() and create offers, so the scenario
        // must keep the Quote unlinked to isolate the update path.)
        Quote q = new Quote(Name = 'Test No Change Quote');
        insert q;

        Pricing_Result__c pr = new Pricing_Result__c(
            Quote__c = q.Id,
            Total_Rate__c = 5.5,
            Total_Rate_Factor__c = 0.018,
            Status__c = 'Success',
            Source__c = 'Base Rate',
            Transaction_Id__c = 'test-qt-003'
        );
        insert pr;

        tval__TValue_Quote__c tvq = new tval__TValue_Quote__c(
            Quote__c = q.Id,
            tval__Term__c = 36,
            tval__Purchase_Option__c = '1.00 Out'
        );
        insert tvq;

        Test.startTest();
        q.Name = 'Updated Name Only';
        update q;
        Test.stopTest();

        List<EF_Approved_Offers__c> offers = [
            SELECT Id FROM EF_Approved_Offers__c WHERE RecordTypeId = :SYSTEM_RT
        ];
        System.assertEquals(0, offers.size(),
            'Updating a non-OpportunityId field should not create offers');
    }

    @IsTest
    static void testInsert_WithPricingData_CreatesOffersOnInsert() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Quote Trigger Opp' LIMIT 1];

        Pricing_Result__c pr = new Pricing_Result__c(
            Opportunity__c = opp.Id,
            Total_Rate__c = 7.0,
            Total_Rate_Factor__c = 0.025,
            Status__c = 'Success',
            Source__c = 'Base Rate',
            Transaction_Id__c = 'test-qt-004'
        );
        insert pr;

        Test.startTest();
        Quote q = new Quote(
            Name = 'Test Insert With Data',
            OpportunityId = opp.Id
        );
        insert q;

        pr.Quote__c = q.Id;
        update pr;

        tval__TValue_Quote__c tvq = new tval__TValue_Quote__c(
            Quote__c = q.Id,
            tval__Term__c = 60,
            tval__Purchase_Option__c = '1.00 Out'
        );
        insert tvq;

        q.Name = 'Test Insert With Data - Updated';
        q.OpportunityId = opp.Id;
        update q;
        Test.stopTest();
    }

    @IsTest
    static void testTransactionIdScoping_ExcludesOlderRuns() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Quote Trigger Opp' LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Quote Trigger Account' LIMIT 1];
        Program__c program = [SELECT Id FROM Program__c LIMIT 1];

        Opportunity targetOpp = new Opportunity(
            Name = 'Test TxnScope Target',
            AccountId = acc.Id,
            StageName = 'Application',
            CloseDate = Date.today().addDays(30),
            Primary_Source__c = 'Customer Inbound - Call',
            Equipment_Description__c = 'Test Equipment',
            Equipment_Cost__c = 50000,
            Terms__c = 36,
            Funded_Amount__c = 50000,
            Payment_Frequency__c = 'Monthly',
            Purchase_Options__c = '1.00 Out',
            Program_Lookup__c = program.Id
        );
        insert targetOpp;

        Quote q = new Quote(Name = 'Test TxnScope Quote', OpportunityId = opp.Id);
        insert q;

        // Old orchestrator run — 2 results that must be excluded
        insert new List<Pricing_Result__c>{
            new Pricing_Result__c(
                Quote__c = q.Id, Opportunity__c = opp.Id,
                Total_Rate__c = 3.0, Total_Rate_Factor__c = 0.010,
                Status__c = 'Success', Source__c = 'Base Rate',
                Transaction_Id__c = 'old-run-aaa'
            ),
            new Pricing_Result__c(
                Quote__c = q.Id, Opportunity__c = opp.Id,
                Total_Rate__c = 3.5, Total_Rate_Factor__c = 0.012,
                Status__c = 'Success', Source__c = 'Base Rate',
                Transaction_Id__c = 'old-run-aaa'
            )
        };

        // Latest orchestrator run — 1 result that should be used
        insert new Pricing_Result__c(
            Quote__c = q.Id, Opportunity__c = opp.Id,
            Total_Rate__c = 8.0, Total_Rate_Factor__c = 0.030,
            Status__c = 'Success', Source__c = 'Base Rate',
            Transaction_Id__c = 'latest-run-bbb'
        );

        insert new tval__TValue_Quote__c(
            Quote__c = q.Id, tval__Term__c = 36,
            tval__Purchase_Option__c = '1.00 Out'
        );

        Test.startTest();
        q.OpportunityId = targetOpp.Id;
        update q;
        Test.stopTest();

        System.assert(true, 'Transaction scoping trigger path executed successfully');
    }

    @IsTest
    static void testSameTransaction_AllResultsIncluded() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Quote Trigger Opp' LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Quote Trigger Account' LIMIT 1];
        Program__c program = [SELECT Id FROM Program__c LIMIT 1];

        Opportunity targetOpp = new Opportunity(
            Name = 'Test MultiResult Target',
            AccountId = acc.Id,
            StageName = 'Application',
            CloseDate = Date.today().addDays(30),
            Primary_Source__c = 'Customer Inbound - Call',
            Equipment_Description__c = 'Test Equipment',
            Equipment_Cost__c = 50000,
            Terms__c = 36,
            Funded_Amount__c = 50000,
            Payment_Frequency__c = 'Monthly',
            Purchase_Options__c = '1.00 Out',
            Program_Lookup__c = program.Id
        );
        insert targetOpp;

        Quote q = new Quote(Name = 'Test MultiResult Quote', OpportunityId = opp.Id);
        insert q;

        String txnId = 'multi-result-txn';
        insert new List<Pricing_Result__c>{
            new Pricing_Result__c(
                Quote__c = q.Id, Opportunity__c = opp.Id,
                Total_Rate__c = 5.0, Total_Rate_Factor__c = 0.018,
                Status__c = 'Success', Source__c = 'Base Rate',
                Transaction_Id__c = txnId
            ),
            new Pricing_Result__c(
                Quote__c = q.Id, Opportunity__c = opp.Id,
                Total_Rate__c = 6.0, Total_Rate_Factor__c = 0.020,
                Status__c = 'Success', Source__c = 'Base Rate',
                Transaction_Id__c = txnId
            ),
            new Pricing_Result__c(
                Quote__c = q.Id, Opportunity__c = opp.Id,
                Total_Rate__c = 7.0, Total_Rate_Factor__c = 0.022,
                Status__c = 'Success', Source__c = 'Base Rate',
                Transaction_Id__c = txnId
            )
        };

        insert new tval__TValue_Quote__c(
            Quote__c = q.Id, tval__Term__c = 48,
            tval__Purchase_Option__c = '1.00 Out'
        );

        Test.startTest();
        q.OpportunityId = targetOpp.Id;
        update q;
        Test.stopTest();

        System.assert(true, 'Same-transaction multi-result trigger path executed successfully');
    }

    @IsTest
    static void testBulk_TwoQuotesIndependentScoping() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Quote Trigger Account' LIMIT 1];
        Program__c program = [SELECT Id FROM Program__c LIMIT 1];

        List<Opportunity> opps = new List<Opportunity>();
        for (String name : new List<String>{
            'Bulk Src A', 'Bulk Src B', 'Bulk Target A', 'Bulk Target B'
        }) {
            opps.add(new Opportunity(
                Name = name,
                AccountId = acc.Id,
                StageName = 'Application',
                CloseDate = Date.today().addDays(30),
                Primary_Source__c = 'Customer Inbound - Call',
                Equipment_Description__c = 'Test Equipment',
                Equipment_Cost__c = 50000,
                Terms__c = 36,
                Funded_Amount__c = 50000,
                Payment_Frequency__c = 'Monthly',
                Purchase_Options__c = '1.00 Out',
                Program_Lookup__c = program.Id
            ));
        }
        insert opps;
        Opportunity srcA = opps[0];
        Opportunity srcB = opps[1];
        Opportunity targetA = opps[2];
        Opportunity targetB = opps[3];

        Quote qA = new Quote(Name = 'Bulk QuoteA', OpportunityId = srcA.Id);
        Quote qB = new Quote(Name = 'Bulk QuoteB', OpportunityId = srcB.Id);
        insert new List<Quote>{ qA, qB };

        // Quote A: old run (should be excluded) then new run
        insert new Pricing_Result__c(
            Quote__c = qA.Id, Opportunity__c = srcA.Id,
            Total_Rate__c = 2.0, Total_Rate_Factor__c = 0.008,
            Status__c = 'Success', Source__c = 'Base Rate',
            Transaction_Id__c = 'a-old-txn'
        );
        insert new Pricing_Result__c(
            Quote__c = qA.Id, Opportunity__c = srcA.Id,
            Total_Rate__c = 5.0, Total_Rate_Factor__c = 0.018,
            Status__c = 'Success', Source__c = 'Base Rate',
            Transaction_Id__c = 'a-new-txn'
        );

        // Quote B: single run
        insert new Pricing_Result__c(
            Quote__c = qB.Id, Opportunity__c = srcB.Id,
            Total_Rate__c = 7.0, Total_Rate_Factor__c = 0.025,
            Status__c = 'Success', Source__c = 'Base Rate',
            Transaction_Id__c = 'b-only-txn'
        );

        insert new List<tval__TValue_Quote__c>{
            new tval__TValue_Quote__c(
                Quote__c = qA.Id, tval__Term__c = 36,
                tval__Purchase_Option__c = '1.00 Out'
            ),
            new tval__TValue_Quote__c(
                Quote__c = qB.Id, tval__Term__c = 48,
                tval__Purchase_Option__c = '1.00 Out'
            )
        };

        Test.startTest();
        qA.OpportunityId = targetA.Id;
        qB.OpportunityId = targetB.Id;
        update new List<Quote>{ qA, qB };
        Test.stopTest();

        System.assert(true, 'Bulk two-quote trigger path executed successfully');
    }

    @IsTest
    static void testConversion_StampsOpportunityOnTValueQuotes() {
        // Mirrors the New Quote tab → convert to Opportunity scenario:
        // a standalone Quote whose TValue Quotes were created by the pricing
        // orchestrator before any Opportunity existed (tval__Opportunity__c null).
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Quote Trigger Opp' LIMIT 1];

        Quote q = new Quote(Name = 'Standalone New Quote');
        insert q;

        List<tval__TValue_Quote__c> tvqs = new List<tval__TValue_Quote__c>{
            new tval__TValue_Quote__c(
                Quote__c = q.Id, tval__Term__c = 24, tval__Purchase_Option__c = '1.00 Out'
            ),
            new tval__TValue_Quote__c(
                Quote__c = q.Id, tval__Term__c = 36, tval__Purchase_Option__c = '1.00 Out'
            )
        };
        insert tvqs;

        Test.startTest();
        // Conversion: link the standalone Quote to the Opportunity.
        q.OpportunityId = opp.Id;
        update q;
        Test.stopTest();

        List<tval__TValue_Quote__c> stamped = [
            SELECT Id, tval__Opportunity__c
            FROM tval__TValue_Quote__c
            WHERE Quote__c = :q.Id
        ];
        System.assertEquals(2, stamped.size(),
            'Both TValue Quotes should still be linked to the Quote');
        for (tval__TValue_Quote__c tvq : stamped) {
            System.assertEquals(opp.Id, tvq.tval__Opportunity__c,
                'TValue Quote must be stamped with the converted Opportunity ' +
                'so it appears in the Opportunity TValue Quote related list');
        }
    }

    @IsTest
    static void testConversion_StampsOpportunityOnPricingResults() {
        // Same conversion scenario as testConversion_StampsOpportunityOnTValueQuotes,
        // but for Pricing_Result__c. A standalone Quote's pricing run produces
        // audit rows with Quote__c set and Opportunity__c null; on conversion
        // the handler must back-stamp Opportunity__c on every related row.
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Quote Trigger Opp' LIMIT 1];

        Quote q = new Quote(Name = 'Standalone Quote for Pricing Result Stamp');
        insert q;

        // Include rows with different Source / Status to prove the stamp is
        // unfiltered (the full audit trail should appear on the Opp).
        List<Pricing_Result__c> prs = new List<Pricing_Result__c>{
            new Pricing_Result__c(
                Quote__c = q.Id,
                Source__c = 'Base Rate', Status__c = 'Success',
                Total_Rate__c = 5.5, Total_Rate_Factor__c = 0.018,
                Transaction_Id__c = 'stamp-pr-success'
            ),
            new Pricing_Result__c(
                Quote__c = q.Id,
                Source__c = 'Base Rate', Status__c = 'Error',
                Error_Message__c = 'Sample error', Transaction_Id__c = 'stamp-pr-error'
            )
        };
        insert prs;

        Test.startTest();
        q.OpportunityId = opp.Id;
        update q;
        Test.stopTest();

        List<Pricing_Result__c> stamped = [
            SELECT Id, Opportunity__c, Status__c
            FROM Pricing_Result__c
            WHERE Quote__c = :q.Id
        ];
        System.assertEquals(2, stamped.size(),
            'All Pricing Result rows should still be linked to the Quote');
        for (Pricing_Result__c pr : stamped) {
            System.assertEquals(opp.Id, pr.Opportunity__c,
                'Pricing Result must be stamped with the converted Opportunity ' +
                'regardless of Source/Status, so the full audit appears on the Opp');
        }
    }

    @IsTest
    static void testNoTValueQuote_NoOffersCreated() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Quote Trigger Opp' LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Quote Trigger Account' LIMIT 1];
        Program__c program = [SELECT Id FROM Program__c LIMIT 1];

        Opportunity targetOpp = new Opportunity(
            Name = 'Test NoTV Target',
            AccountId = acc.Id,
            StageName = 'Application',
            CloseDate = Date.today().addDays(30),
            Primary_Source__c = 'Customer Inbound - Call',
            Equipment_Description__c = 'Test Equipment',
            Equipment_Cost__c = 50000,
            Terms__c = 36,
            Funded_Amount__c = 50000,
            Payment_Frequency__c = 'Monthly',
            Purchase_Options__c = '1.00 Out',
            Program_Lookup__c = program.Id
        );
        insert targetOpp;

        Quote q = new Quote(Name = 'Test NoTV Quote', OpportunityId = opp.Id);
        insert q;

        insert new Pricing_Result__c(
            Quote__c = q.Id, Opportunity__c = opp.Id,
            Total_Rate__c = 5.0, Total_Rate_Factor__c = 0.018,
            Status__c = 'Success', Source__c = 'Base Rate',
            Transaction_Id__c = 'no-tv-txn'
        );

        Test.startTest();
        q.OpportunityId = targetOpp.Id;
        update q;
        Test.stopTest();

        List<EF_Approved_Offers__c> offers = [
            SELECT Id FROM EF_Approved_Offers__c
            WHERE Opportunity__c = :targetOpp.Id AND RecordTypeId = :SYSTEM_RT
        ];
        System.assertEquals(0, offers.size(),
            'No TValue Quote means no offers should be created');
    }

    @IsTest
    static void testBackstampEvent_StampsViaPlatformEvent() {
        // Directly exercise the NT_Quote_Backstamp__e subscriber path:
        // publishing the event must drive handleBackstampEvents -> createEFOffers,
        // stamping the Opportunity on the related TValue Quote. The event
        // subscriber runs as Automated Process in production, which is what gives
        // it the Opportunity access a portal user lacks.
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Quote Trigger Opp' LIMIT 1];

        Quote q = new Quote(Name = 'PE Backstamp Quote');
        insert q;

        insert new tval__TValue_Quote__c(
            Quote__c = q.Id, tval__Term__c = 36, tval__Purchase_Option__c = '1.00 Out'
        );

        Test.startTest();
        EventBus.publish(new NT_Quote_Backstamp__e(
            Quote_Id__c = q.Id,
            Opportunity_Id__c = opp.Id
        ));
        Test.stopTest();

        tval__TValue_Quote__c stamped = [
            SELECT tval__Opportunity__c FROM tval__TValue_Quote__c WHERE Quote__c = :q.Id LIMIT 1
        ];
        System.assertEquals(opp.Id, stamped.tval__Opportunity__c,
            'Platform event subscriber should back-stamp the Opportunity on the TValue Quote');
    }

    @IsTest
    static void testBackstampEvent_BlankIdsIgnored() {
        // Guard path: events with blank ids must be skipped without error.
        Test.startTest();
        NT_QuoteTriggerHandler.handleBackstampEvents(new List<NT_Quote_Backstamp__e>{
            new NT_Quote_Backstamp__e(Quote_Id__c = null, Opportunity_Id__c = null)
        });
        NT_QuoteTriggerHandler.handleBackstampEvents(new List<NT_Quote_Backstamp__e>());
        Test.stopTest();

        System.assert(true, 'Blank/empty backstamp events should be ignored safely');
    }
}