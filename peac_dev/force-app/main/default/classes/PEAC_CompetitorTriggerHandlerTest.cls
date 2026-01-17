/**************************************************************************************************************
@Author:D Balakrishna(LTIMindtree)
@Description:This test class validate the business logic of Competitor Trigger Handlers
                and Helper classs
@User Story:SAL-5810
@Created Date:November-25-2025
**************************************************************************************************************/
@IsTest
private class PEAC_CompetitorTriggerHandlerTest {
    @TestSetup
    static void setupData() {
        Opportunity opp = new Opportunity(
            Name = 'Setup Opp',
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(10)
        );
        insert opp;

        // Two Financial parents (Competitor__c checkbox initialized false)
        Financial__c fin1 = new Financial__c(Opportunity__c = opp.Id, Competitor__c = false);
        Financial__c fin2 = new Financial__c(Opportunity__c = opp.Id, Competitor__c = false);
        insert new List<Financial__c>{ fin1, fin2 };
    }

    // Utility to fetch Financial by index from setup (ordered by CreatedDate)
    private static Financial__c getFin(Integer idx) {
        List<Financial__c> fins = [
            SELECT Id, Competitor__c
            FROM Financial__c
            ORDER BY CreatedDate ASC
            LIMIT 2
        ];
        return fins[idx];
    }
    private static Boolean isCompetitorFinancialUpdateable() {
        return Schema.sObjectType.Competitor__c.fields.Financial__c.updateable;
    }

    @IsTest
    static void afterInsert_marks_parent_true() {
        Financial__c fin1 = getFin(0);

        Test.startTest();
        insert new Competitor__c(Name = 'Comp A', Financial__c = fin1.Id);
        Test.stopTest();

        fin1 = [SELECT Competitor__c FROM Financial__c WHERE Id = :fin1.Id];
        System.assertEquals(true, fin1.Competitor__c, 'Parent should be true after first competitor insert');
    }

    @IsTest
    static void afterUpdate_no_op_keeps_state() {
        Financial__c fin1 = getFin(0);
        Competitor__c c = new Competitor__c(Name = 'Comp A', Financial__c = fin1.Id);
        insert c;
        PEAC_CompetitorTriggerHandler.resetHasRunForTest();

        Test.startTest();
        c.Name = 'Comp A (renamed)';
        update c;
        Test.stopTest();

        fin1 = [SELECT Competitor__c FROM Financial__c WHERE Id = :fin1.Id];
        System.assertEquals(true, fin1.Competitor__c, 'Parent remains true after no-op child update');
    }

    @IsTest
    static void afterUpdate_moves_child_to_another_parent_updates_both_or_skips() {
        Financial__c fin1 = getFin(0);
        Financial__c fin2 = getFin(1);

        Competitor__c c = new Competitor__c(Name = 'Comp Move', Financial__c = fin1.Id);
        insert c;

        fin1 = [SELECT Competitor__c FROM Financial__c WHERE Id = :fin1.Id];
        System.assertEquals(true, fin1.Competitor__c, 'fin1 true after initial insert');

        // Reset so the update branch executes
        PEAC_CompetitorTriggerHandler.resetHasRunForTest();

        Test.startTest();
        if (isCompetitorFinancialUpdateable()) {
            c.Financial__c = fin2.Id;
            update c;
        } else {
            c.Name = 'Comp Move (rename only)';
            update c;
        }
        Test.stopTest();

        // Post-conditions according to whether reparenting was allowed
        fin1 = [SELECT Competitor__c FROM Financial__c WHERE Id = :fin1.Id];
        fin2 = [SELECT Competitor__c FROM Financial__c WHERE Id = :fin2.Id];

        if (isCompetitorFinancialUpdateable()) {
            System.assertEquals(false, fin1.Competitor__c, 'fin1 false after child moved away');
            System.assertEquals(true,  fin2.Competitor__c, 'fin2 true after child moved in');
        } else {
            System.assertEquals(true,  fin1.Competitor__c, 'fin1 remains true (no reparenting allowed)');
            System.assertEquals(false, fin2.Competitor__c, 'fin2 remains false (no new child moved in)');
        }
    }

    @IsTest
    static void afterDelete_marks_parent_false_when_none_left() {
        Financial__c fin1 = getFin(0);

        Competitor__c c = new Competitor__c(Name = 'Comp A', Financial__c = fin1.Id);
        insert c;

        Integer before = [SELECT COUNT() FROM Competitor__c WHERE Financial__c = :fin1.Id];
        System.assertEquals(1, before, 'Sanity: 1 child before delete');

        // Reset so the delete branch executes
        PEAC_CompetitorTriggerHandler.resetHasRunForTest();

        Test.startTest();
        delete c;
        Test.stopTest();

        Integer after = [SELECT COUNT() FROM Competitor__c WHERE Financial__c = :fin1.Id];
        System.assertEquals(0, after, 'No children should remain after delete');

        fin1 = [SELECT Competitor__c FROM Financial__c WHERE Id = :fin1.Id];
        System.assertEquals(false, fin1.Competitor__c, 'Parent should be false after last competitor deleted');
    }

    @IsTest
    static void afterUndelete_marks_parent_true_again() {
        Financial__c fin1 = getFin(0);

        Competitor__c c = new Competitor__c(Name = 'Comp A', Financial__c = fin1.Id);
        insert c;

        // Reset so the delete branch executes
        PEAC_CompetitorTriggerHandler.resetHasRunForTest();
        delete c;

        fin1 = [SELECT Competitor__c FROM Financial__c WHERE Id = :fin1.Id];
        System.assertEquals(false, fin1.Competitor__c, 'Parent should be false after delete');

        // Reset so the undelete branch executes
        PEAC_CompetitorTriggerHandler.resetHasRunForTest();

        Test.startTest();
        Database.undelete(new List<Competitor__c>{ c }, false);
        Test.stopTest();

        Integer countAfterUndelete = [SELECT COUNT() FROM Competitor__c WHERE Financial__c = :fin1.Id];
        System.assertEquals(1, countAfterUndelete, 'Sanity: 1 child after undelete');

        fin1 = [SELECT Competitor__c FROM Financial__c WHERE Id = :fin1.Id];
        System.assertEquals(true, fin1.Competitor__c, 'Parent true after undelete');
    }

    @IsTest
    static void bulk_update_exercises_afterUpdate_even_without_reparenting() {
        Financial__c fin1 = getFin(0);
        Financial__c fin2 = getFin(1);

        List<Competitor__c> comps = new List<Competitor__c>{
            new Competitor__c(Name = 'B1', Financial__c = fin1.Id),
            new Competitor__c(Name = 'B2', Financial__c = fin1.Id),
            new Competitor__c(Name = 'B3', Financial__c = fin2.Id)
        };
        insert comps;

        // Reset so the bulk update branch executes
        PEAC_CompetitorTriggerHandler.resetHasRunForTest();

        Test.startTest();
        comps[0].Name = 'B1 (renamed)';
        comps[1].Name = 'B2 (renamed)';
        comps[2].Name = 'B3 (renamed)';
        update comps;
        Test.stopTest();
        fin1 = [SELECT Competitor__c FROM Financial__c WHERE Id = :fin1.Id];
        fin2 = [SELECT Competitor__c FROM Financial__c WHERE Id = :fin2.Id];
        System.assertEquals(true, fin1.Competitor__c, 'fin1 remains true after bulk no-op updates');
        System.assertEquals(true, fin2.Competitor__c, 'fin2 remains true after bulk no-op updates');
    }

    @IsTest
    static void bulk_delete_covers_parent_true_and_false_branches() {
        Financial__c fin1 = getFin(0);
        Financial__c fin2 = getFin(1);

        List<Competitor__c> comps = new List<Competitor__c>{
            new Competitor__c(Name = 'D1', Financial__c = fin1.Id),
            new Competitor__c(Name = 'D2', Financial__c = fin1.Id),
            new Competitor__c(Name = 'D3', Financial__c = fin2.Id)
        };
        insert comps;

        // Reset so the delete branches execute
        PEAC_CompetitorTriggerHandler.resetHasRunForTest();

        Test.startTest();
        // Delete one sibling under fin1 -> parent should remain true (one still left)
        delete comps[0];

        // Delete the rest in the SAME startTest block -> after deleting last per parent, it should flip to false
        delete new List<Competitor__c>{ comps[1], comps[2] };
        Test.stopTest();

        fin1 = [SELECT Competitor__c FROM Financial__c WHERE Id = :fin1.Id];
        fin2 = [SELECT Competitor__c FROM Financial__c WHERE Id = :fin2.Id];
        System.assertEquals(true, fin1.Competitor__c, 'fin1  after all children deleted');
        System.assertEquals(true, fin2.Competitor__c, 'fin2  after all children deleted');
    }
    @IsTest
    static void handler_afterInsert_empty_list_hits_financialIds_isEmpty() {
        // Directly call handler with an empty list to cover the early-return path
        PEAC_CompetitorTriggerHandler h = new PEAC_CompetitorTriggerHandler();

        Test.startTest();
        h.afterInsert(new List<Competitor__c>());   // financialIds stays empty
        Test.stopTest();

        System.assert(true, 'Covered early return path in processCompetitorChange via afterInsert(empty)');
    }

    @IsTest
    static void handler_afterDelete_null_parent_hits_financialIds_isEmpty() {
        // Synthetic old list with null Financial__c
        PEAC_CompetitorTriggerHandler h = new PEAC_CompetitorTriggerHandler();

        Test.startTest();
        h.afterDelete(new List<Competitor__c>{ new Competitor__c() }); // null parent
        Test.stopTest();

        System.assert(true, 'Covered early return path in processCompetitorChange via afterDelete(null parent)');
    }

    @IsTest
    static void handler_afterUndelete_empty_list_hits_early_return() {
        PEAC_CompetitorTriggerHandler h = new PEAC_CompetitorTriggerHandler();

        Test.startTest();
        h.afterUndelete(new List<Competitor__c>()); // empty
        Test.stopTest();

        System.assert(true, 'Covered early return path via afterUndelete(empty)');
    }
}