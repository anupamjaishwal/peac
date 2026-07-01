public without sharing class NT_RateCardDiag {

    public static void run(Id oppId) {
        Opportunity opp = [
            SELECT Id, Name, StageName, Terms__c, Max_Term_Approved__c,
                   Purchase_Options__c, Equipment_Cost__c, Credit_Risk_Grade__c,
                   Lessor__c, Dealer_Account__c, Dealer_User__c, Portal_User_ID__c,
                   Loan_Record_Type__c, Required_Adv_Payments__c,
                   AccountId, Account.Name
            FROM Opportunity WHERE Id = :oppId
        ];

        d('========== STEP 1: OPPORTUNITY FIELDS ==========');
        d('Name:                ' + opp.Name);
        d('Stage:               ' + opp.StageName);
        d('Terms:               ' + opp.Terms__c);
        d('Max Term Approved:   ' + opp.Max_Term_Approved__c);
        d('Purchase Options:    ' + opp.Purchase_Options__c);
        d('Equipment Cost:      ' + opp.Equipment_Cost__c);
        d('Credit Risk Grade:   ' + opp.Credit_Risk_Grade__c);
        d('Lessor:              ' + opp.Lessor__c);
        d('Loan Record Type:    ' + opp.Loan_Record_Type__c);
        d('Dealer Account:      ' + opp.Dealer_Account__c);
        d('Dealer User:         ' + opp.Dealer_User__c);
        d('Portal User ID:      ' + opp.Portal_User_ID__c);
        d('Account:             ' + opp.Account.Name);
        Boolean isPortalOpp = (opp.Portal_User_ID__c != null && opp.Portal_User_ID__c.containsIgnoreCase('DP-'));
        d('Is Portal Opp:       ' + isPortalOpp);

        // Step 2: All rate cards
        d('');
        d('========== STEP 2: ALL RATE CARDS ==========');
        List<RateCard__c> allRateCards = [
            SELECT Id, Name, Active__c, Rate_Card_Type__c, Entry_Criteria__c,
                   Effective_Start_Date__c, Effective_End_Date__c
            FROM RateCard__c
        ];
        d('Total rate cards: ' + allRateCards.size());
        Set<Id> allEntryCriteriaIds = new Set<Id>();
        for (RateCard__c rc : allRateCards) {
            d('  [' + rc.Name + '] Active=' + rc.Active__c + ' | Type=' + rc.Rate_Card_Type__c + ' | EntryCriteria=' + rc.Entry_Criteria__c);
            if (rc.Entry_Criteria__c != null) allEntryCriteriaIds.add(rc.Entry_Criteria__c);
        }

        d('');
        d('--- Entry Criteria Rule Conditions ---');
        for (TCRE__Rule_Config__c config : [
            SELECT Id, TCRE__SObject_Name__c, TCRE__Evaluation_Logic_Picklist__c,
                   TCRE__Custom_Rule_Evaluation_Logic__c,
                   (SELECT Id, TCRE__Field_Name__c, TCRE__Operator__c, TCRE__Value__c
                    FROM TCRE__Rule_Conditions__r ORDER BY CreatedDate ASC)
            FROM TCRE__Rule_Config__c WHERE Id IN :allEntryCriteriaIds
        ]) {
            String rcName = rcNameForConfig(allRateCards, config.Id);
            d('  Config [' + config.Id + '] "' + rcName + '" SObject=' + config.TCRE__SObject_Name__c + ' Logic=' + config.TCRE__Evaluation_Logic_Picklist__c);
            Integer n = 1;
            for (TCRE__Rule_Condition__c c : config.TCRE__Rule_Conditions__r) {
                d('    ' + n + ': ' + c.TCRE__Field_Name__c + ' ' + c.TCRE__Operator__c + ' ' + c.TCRE__Value__c);
                n++;
            }
        }

        // Step 3: Evaluate entry criteria
        d('');
        d('========== STEP 3: ENTRY CRITERIA EVALUATION ==========');
        SL_RuleEngine rateCardRE = new SL_RuleEngine();
        Set<Id> objIds = new Set<Id>{ oppId };
        rateCardRE.logicObjectIds = objIds;
        rateCardRE.ruleObjectType = 'RateCard__c';
        rateCardRE.TestRuleConditions();

        Set<Id> trueRateCardIds = new Set<Id>();
        for (Map<Id, Boolean> rule : rateCardRE.RuleResults.values()) {
            for (Id ruleId : rule.keySet()) {
                Boolean matched = rule.get(ruleId);
                d('  [' + rcNameForConfig(allRateCards, ruleId) + '] => ' + (matched ? 'MATCH' : 'NO MATCH'));
                if (matched) trueRateCardIds.add(ruleId);
            }
        }
        dumpConditionDetail(rateCardRE, allRateCards, null, null);

        if (trueRateCardIds.isEmpty()) {
            d('*** NO RATE CARDS MATCHED. Stopping. ***');
            return;
        }

        // Step 4: Row criteria
        d('');
        d('========== STEP 4: ROW CRITERIA ==========');
        List<Rate_Card_Row__c> rows = [
            SELECT Id, Name, Rate_Card__r.Name, Row_Criteria__c, Order__c
            FROM Rate_Card_Row__c WHERE Rate_Card__r.Entry_Criteria__c IN :trueRateCardIds
        ];
        Set<Id> rowRuleConfigIds = new Set<Id>();
        for (Rate_Card_Row__c r : rows) {
            rowRuleConfigIds.add(r.Row_Criteria__c);
            d('  Row [' + r.Name + '] RC="' + r.Rate_Card__r.Name + '" Order=' + r.Order__c);
        }

        dumpRuleConditions(rowRuleConfigIds, 'Row');

        SL_RuleEngine rateRowRE = new SL_RuleEngine();
        rateRowRE.logicObjectIds = objIds;
        rateRowRE.ruleConfigIds = rowRuleConfigIds;
        rateRowRE.ruleObjectType = 'Rate_Card_Row__c';
        rateRowRE.TestRuleConditions();

        Set<Id> trueRowIds = new Set<Id>();
        for (Map<Id, Boolean> rule : rateRowRE.RuleResults.values()) {
            for (Id ruleId : rule.keySet()) {
                Boolean matched = rule.get(ruleId);
                String rowName = '';
                for (Rate_Card_Row__c r : rows) { if (r.Row_Criteria__c == ruleId) rowName = r.Name; }
                d('  Row "' + rowName + '" => ' + (matched ? 'MATCH' : 'NO MATCH'));
                if (matched) trueRowIds.add(ruleId);
            }
        }
        dumpConditionDetail(rateRowRE, null, rows, null);

        // Step 5: Column criteria
        d('');
        d('========== STEP 5: COLUMN CRITERIA ==========');
        List<Rate_Card_Column__c> allCols = [
            SELECT Id, Name, Rate_Card__r.Name, Column_Criteria__c, Order__c, Residual__c
            FROM Rate_Card_Column__c WHERE Rate_Card__r.Entry_Criteria__c IN :trueRateCardIds
        ];
        Set<Id> colRuleConfigIds = new Set<Id>();
        for (Rate_Card_Column__c c : allCols) {
            colRuleConfigIds.add(c.Column_Criteria__c);
            d('  Col [' + c.Name + '] RC="' + c.Rate_Card__r.Name + '" Order=' + c.Order__c + ' Residual=' + c.Residual__c);
        }

        dumpRuleConditions(colRuleConfigIds, 'Column');

        SL_RuleEngine rateColRE = new SL_RuleEngine();
        rateColRE.logicObjectIds = objIds;
        rateColRE.ruleConfigIds = colRuleConfigIds;
        rateColRE.ruleObjectType = 'Rate_Card_Column__c';
        rateColRE.TestRuleConditions();

        Set<Id> trueColIds = new Set<Id>();
        for (Map<Id, Boolean> rule : rateColRE.RuleResults.values()) {
            for (Id ruleId : rule.keySet()) {
                Boolean matched = rule.get(ruleId);
                String colName = '';
                for (Rate_Card_Column__c c : allCols) { if (c.Column_Criteria__c == ruleId) colName = c.Name; }
                d('  Col "' + colName + '" => ' + (matched ? 'MATCH' : 'NO MATCH'));
                if (matched) trueColIds.add(ruleId);
            }
        }
        dumpConditionDetail(rateColRE, null, null, allCols);

        // Step 6: Rate lookup
        d('');
        d('========== STEP 6: RATES ==========');
        List<Rate_Card_Rate__c> allTermRates = [
            SELECT Id, Rate__c, Rate_Card_Column__r.Name, Rate_Card_Column__r.Residual__c, Rate_Card_Column__r.Order__c
            FROM Rate_Card_Rate__c
            WHERE Rate_Card_Row__r.Row_Criteria__c IN :trueRowIds
            ORDER BY Rate_Card_Column__r.Order__c
        ];
        d('Rates for matching rows: ' + allTermRates.size());
        for (Rate_Card_Rate__c r : allTermRates) {
            d('  Term=' + r.Rate_Card_Column__r.Name + ' | Rate=' + r.Rate__c + ' | Residual=' + r.Rate_Card_Column__r.Residual__c);
        }

        // Step 7: Dry run
        d('');
        d('========== STEP 7: DRY RUN (no DML) ==========');
        Integer ct = 0;
        for (Rate_Card_Rate__c rcr : allTermRates) {
            Integer term;
            try { term = Integer.valueOf(rcr.Rate_Card_Column__r.Name); } catch (Exception e) { continue; }
            Boolean create = false;
            if ((term <= opp.Max_Term_Approved__c || opp.Max_Term_Approved__c == null) && !isPortalOpp) {
                create = true;
            } else if (term == opp.Terms__c && isPortalOpp) {
                create = true;
            }
            Decimal res = opp.Purchase_Options__c == 'FMV' ? rcr.Rate_Card_Column__r.Residual__c : null;
            d('  Term=' + term + ' Rate=' + rcr.Rate__c + ' Residual=' + res + ' => ' + (create ? 'CREATE' : 'SKIP'));
            if (create) ct++;
        }
        d('Total offers: ' + ct);
        d('========== DONE ==========');
    }

    private static String rcNameForConfig(List<RateCard__c> rcs, Id configId) {
        for (RateCard__c rc : rcs) { if (rc.Entry_Criteria__c == configId) return rc.Name; }
        return '?';
    }

    private static void dumpRuleConditions(Set<Id> configIds, String label) {
        d('--- ' + label + ' Rule Conditions ---');
        for (TCRE__Rule_Config__c config : [
            SELECT Id, TCRE__Evaluation_Logic_Picklist__c,
                   (SELECT Id, TCRE__Field_Name__c, TCRE__Operator__c, TCRE__Value__c
                    FROM TCRE__Rule_Conditions__r ORDER BY CreatedDate ASC)
            FROM TCRE__Rule_Config__c WHERE Id IN :configIds
        ]) {
            d('  Config [' + config.Id + '] Logic=' + config.TCRE__Evaluation_Logic_Picklist__c);
            Integer n = 1;
            for (TCRE__Rule_Condition__c c : config.TCRE__Rule_Conditions__r) {
                d('    ' + n + ': ' + c.TCRE__Field_Name__c + ' ' + c.TCRE__Operator__c + ' ' + c.TCRE__Value__c);
                n++;
            }
        }
    }

    private static void dumpConditionDetail(SL_RuleEngine eng, List<RateCard__c> rcs, List<Rate_Card_Row__c> rows, List<Rate_Card_Column__c> cols) {
        if (eng.ruleConditionResult == null) return;
        d('--- Per-Condition Detail ---');
        for (String objKey : eng.ruleConditionResult.keySet()) {
            for (Id configId : eng.ruleConditionResult.get(objKey).keySet()) {
                String lbl = String.valueOf(configId);
                if (rcs != null) { for (RateCard__c rc : rcs) { if (rc.Entry_Criteria__c == configId) lbl = rc.Name; } }
                if (rows != null) { for (Rate_Card_Row__c r : rows) { if (r.Row_Criteria__c == configId) lbl = r.Name; } }
                if (cols != null) { for (Rate_Card_Column__c c : cols) { if (c.Column_Criteria__c == configId) lbl = c.Name; } }
                d('  [' + lbl + ']:');
                for (Id condId : eng.ruleConditionResult.get(objKey).get(configId).keySet()) {
                    d('    ' + condId + ' => ' + eng.ruleConditionResult.get(objKey).get(configId).get(condId));
                }
            }
        }
    }

    private static void d(String msg) {
        System.debug(LoggingLevel.DEBUG, msg);
    }
}