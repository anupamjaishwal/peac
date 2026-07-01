@IsTest
private class NT_ModifierCycleDetectionHandlerTest {

    // ── Helpers ───────────────────────────────────────────────────────────────

    /**
     * Rate Cards used as Modifier_Rate_Card__c targets must satisfy the
     * lookup filter: Rate_Card_Type__c EQUALS 'Interest Rate' OR 'Rate Factor'
     * Using 'Interest Rate' consistently across all tests.
     */
    private static RateCard__c makeRateCard(String name) {
        RateCard__c rc = new RateCard__c(
            Name              = name,
            Rate_Card_Type__c = 'Interest Rate'
        );
        insert rc;
        return rc;
    }

    private static Modifier__c makeModifier(Id rateCardId, Id modifierRateCardId) {
        Modifier__c m = new Modifier__c(
            Rate_Card__c          = rateCardId,
            Modifier_Rate_Card__c = modifierRateCardId
        );
        insert m;
        return m;
    }

    // ── Scenario 1: Valid linear chain (A → B → C) ───────────────────────────
    @IsTest
    static void testValidChain() {
        RateCard__c rcA = makeRateCard('RC-A');
        RateCard__c rcB = makeRateCard('RC-B');
        RateCard__c rcC = makeRateCard('RC-C');

        // A → B
        Modifier__c mA = makeModifier(rcA.Id, rcB.Id);
        // B → C (C has no further modifier, chain ends cleanly)
        Modifier__c mB = makeModifier(rcB.Id, rcC.Id);

        System.assertNotEquals(null, mA.Id, 'Modifier A should have been saved');
        System.assertNotEquals(null, mB.Id, 'Modifier B should have been saved');
    }

    // ── Scenario 2: Direct self-reference ────────────────────────────────────
    @IsTest
    static void testDirectSelfReference() {
        RateCard__c rcA = makeRateCard('RC-Self');

        Modifier__c m = new Modifier__c(
            Rate_Card__c          = rcA.Id,
            Modifier_Rate_Card__c = rcA.Id
        );

        Test.startTest();
        Database.SaveResult sr = Database.insert(m, false);
        Test.stopTest();

        System.assert(!sr.isSuccess(), 'Insert should have failed');
        System.assert(
            sr.getErrors()[0].getMessage().contains('Modifier cannot reference itself'),
            'Expected self-reference error but got: ' + sr.getErrors()[0].getMessage()
        );
    }

    // ── Scenario 3: Indirect circular reference (A → B → A) ─────────────────
    @IsTest
    static void testIndirectCircularReference() {
        RateCard__c rcA = makeRateCard('RC-Indirect-A');
        RateCard__c rcB = makeRateCard('RC-Indirect-B');

        // A → B (valid)
        makeModifier(rcA.Id, rcB.Id);

        // B → A (creates cycle)
        Modifier__c mB = new Modifier__c(
            Rate_Card__c          = rcB.Id,
            Modifier_Rate_Card__c = rcA.Id
        );

        Test.startTest();
        Database.SaveResult sr = Database.insert(mB, false);
        Test.stopTest();

        System.assert(!sr.isSuccess(), 'Insert should have failed due to indirect cycle');
        System.assert(
            sr.getErrors()[0].getMessage().contains('circular reference'),
            'Expected circular reference error but got: ' + sr.getErrors()[0].getMessage()
        );
    }

    // ── Scenario 3 (extended): Three-node cycle (A → B → C → A) ─────────────
    @IsTest
    static void testThreeNodeCycle() {
        RateCard__c rcA = makeRateCard('RC-Cycle-A');
        RateCard__c rcB = makeRateCard('RC-Cycle-B');
        RateCard__c rcC = makeRateCard('RC-Cycle-C');

        // A → B, B → C (both valid)
        makeModifier(rcA.Id, rcB.Id);
        makeModifier(rcB.Id, rcC.Id);

        // C → A (closes the cycle)
        Modifier__c mC = new Modifier__c(
            Rate_Card__c          = rcC.Id,
            Modifier_Rate_Card__c = rcA.Id
        );

        Test.startTest();
        Database.SaveResult sr = Database.insert(mC, false);
        Test.stopTest();

        System.assert(!sr.isSuccess(), 'Insert should have failed (3-node cycle)');
        System.assert(
            sr.getErrors()[0].getMessage().contains('circular reference'),
            'Expected circular reference error but got: ' + sr.getErrors()[0].getMessage()
        );
    }

    // ── Scenario 4: Exceeds maximum depth ────────────────────────────────────
    @IsTest
    static void testMaxDepthExceeded() {
        // Build 12 Rate Cards: cards[0] through cards[11]
        List<RateCard__c> cards = new List<RateCard__c>();
        for (Integer i = 0; i < 12; i++) {
            cards.add(new RateCard__c(
                Name              = 'RC-Depth-' + i,
                Rate_Card_Type__c = 'Interest Rate'
            ));
        }
        insert cards;

        // Chain cards[0]→cards[1]→...→cards[10] (10 modifiers, depth = 10, at the limit)
        List<Modifier__c> mods = new List<Modifier__c>();
        for (Integer i = 0; i < 10; i++) {
            mods.add(new Modifier__c(
                Rate_Card__c          = cards[i].Id,
                Modifier_Rate_Card__c = cards[i + 1].Id
            ));
        }
        insert mods;

        // cards[11] → cards[0] would require traversing 11 hops — exceeds MAX_DEPTH
        Modifier__c extraMod = new Modifier__c(
            Rate_Card__c          = cards[11].Id,
            Modifier_Rate_Card__c = cards[0].Id
        );

        Test.startTest();
        Database.SaveResult sr = Database.insert(extraMod, false);
        Test.stopTest();

        System.assert(!sr.isSuccess(), 'Insert should have failed (exceeds max depth)');
        System.assert(
            sr.getErrors()[0].getMessage().contains('maximum depth'),
            'Expected max depth error but got: ' + sr.getErrors()[0].getMessage()
        );
    }

    // ── Scenario 5: Update triggering a cycle ────────────────────────────────
    @IsTest
    static void testUpdateCreatingCycle() {
        RateCard__c rcA = makeRateCard('RC-Upd-A');
        RateCard__c rcB = makeRateCard('RC-Upd-B');
        RateCard__c rcC = makeRateCard('RC-Upd-C');
        RateCard__c rcD = makeRateCard('RC-Upd-D');

        // A → B → C (valid linear chain)
        makeModifier(rcA.Id, rcB.Id);
        makeModifier(rcB.Id, rcC.Id);
        // C currently points to D (no cycle — D is a dead end)
        Modifier__c mC = makeModifier(rcC.Id, rcD.Id);

        // Now update mC: C → A, making chain A→B→C→A (cycle)
        mC.Modifier_Rate_Card__c = rcA.Id;

        Test.startTest();
        Database.SaveResult sr = Database.update(mC, false);
        Test.stopTest();

        System.assert(!sr.isSuccess(), 'Update should have failed (cycle via update)');
        System.assert(
            sr.getErrors()[0].getMessage().contains('circular reference'),
            'Expected circular reference error but got: ' + sr.getErrors()[0].getMessage()
        );
    }
}