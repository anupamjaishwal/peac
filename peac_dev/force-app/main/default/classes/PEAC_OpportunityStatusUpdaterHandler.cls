public class PEAC_OpportunityStatusUpdaterHandler {
    // --- Constants for readability & to avoid typos ---
    private static final String STAGE_APPLICATION    = PEAC_ConstantClass.OPPORTUNITY_STAGENAME_APPLICATION;
    private static final String STAGE_DECISION       = PEAC_ConstantClass.OPPORTUNITY_STAGENAME_DECISION;//'Decision';
    private static final String STAGE_DOCS_REQUESTED = PEAC_ConstantClass.OPPORTUNITY_STAGENAME_DOCS_REQUESTED;//'Docs Requested';
    private static final String STAGE_DOCS_OUT       = PEAC_ConstantClass.OPPORTUNITY_STAGENAME_DOCS_OUT;//'Docs Out';
    private static final String STAGE_DOCS_IN        = PEAC_ConstantClass.OPPORTUNITY_STAGENAME_DOCS_IN;//'Docs In';
    private static final String STAGE_LOST           = PEAC_ConstantClass.OPPORTUNITY_STAGENAME_LOST;//'Lost';

    private static final String STATUS_APPLICATION_IN_PROGRESS = PEAC_ConstantClass.OPPORTUNITY_STATUS_APPLICATION_IN_PROGRESS;//'Application In Progress';
    private static final String STATUS_CREDIT_IN_QUEUE         = PEAC_ConstantClass.OPPORTUNITY_STATUS_CREDIT_IN_QUEUE;//'Credit - In Queue';
    private static final String STATUS_CREDIT_IN_REVIEW        = PEAC_ConstantClass.OPPORTUNITY_STATUS_CREDIT_IN_REVIEW;//'Credit - In Review';
    private static final String STATUS_CREDIT_MORE_INFO        = PEAC_ConstantClass.OPPORTUNITY_STATUS_CREDIT_MORE_INFO;//'Credit - More Info Requested';
    private static final String STATUS_CREDIT_DECLINED         = PEAC_ConstantClass.OPPORTUNITY_STATUS_CREDIT_DECLINED;//'Credit - Declined';
    private static final String STATUS_DOCS_REQUESTED          = PEAC_ConstantClass.OPPORTUNITY_STATUS_DOCS_REQUESTED;//'Docs Requested';
    private static final String STATUS_ASSIGNED_TO_CMS         = PEAC_ConstantClass.OPPORTUNITY_STATUS_ASSIGNED_TO_CMS;//'Assigned to CMS';
    private static final String STATUS_DOCS_OUT                = PEAC_ConstantClass.OPPORTUNITY_STATUS_DOCS_OUT;//'Docs Out';
    private static final String STATUS_DOCS_IN_PENDING_REVIEW  = PEAC_ConstantClass.OPPORTUNITY_STATUS_DOCS_IN_PENDING_REVIEW;//'Docs in - Pending review';
    private static final String STATUS_LOST                    = PEAC_ConstantClass.OPPORTUNITY_STATUS_LOST;//'Lost';

    private static final String FRAUD_REVIEW                   = PEAC_ConstantClass.OPPORTUNITY_STATUS_FRAUD_REVIEW;//'Fraud Review';
    private static final String FRAUD_MORE_INFO                = PEAC_ConstantClass.OPPORTUNITY_STATUS_FRAUD_MORE_INFO;//'Fraud More Info Requested';
    private static final String SUSPICIOUS_DECLINED            = PEAC_ConstantClass.OPPORTUNITY_STATUS_SUSPICIOUS_DECLINED;//'Suspicious activity - Declined';

    private static final String READY_YES                      = PEAC_ConstantClass.Yes;//'Yes';

    /**
     * Entry point called from trigger.
     * @param newList Trigger.new
     * @param oldMap  Trigger.oldMap (may be null in before insert)
     * PEAC_OpportunityStatusUpdaterHandler.evaluateAndSetStatus(Trigger.new, Trigger.isUpdate ? Trigger.oldMap : null);
     */
    public static void evaluateAndSetStatus(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        if (newList == null || newList.isEmpty()) return;

        // Compute bypass flag once (label may contain comma-separated usernames)
        Boolean isBypassUser = false;
        try {
            String bypassList = System.Label.PEAC_By_Pass_Credit_Review;
            if (bypassList != null) {
                isBypassUser = bypassList.contains(UserInfo.getUserName());
            }
        } catch (Exception e) {
            // If label missing, default to not bypassing.
            isBypassUser = false;
        }

        for (Opportunity opp : newList) {
            Opportunity oldOpp = (oldMap != null) ? oldMap.get(opp.Id) : null;

            // Normalize strings (defensive null handling)
            String stage        = (opp.StageName == null) ? '' : opp.StageName;
            String appStatus    = (String)opp.get('Application_Status__c');
            String decisionStat = (String)opp.get('Decision_Status__c');
            String reasonAppr   = (String)opp.get('Reason_for_Approval__c');
            String oppStatus    = (String)opp.get('Opportunity_Status__c');

            String readyToDoc   = (String)opp.get('Ready_to_Doc__c');
            String loanReadyDoc = (String)opp.get('Loan_Ready_To_Doc__c');

            Id     assignedCreditUserId = (Id)opp.get('Assigned_Credit_User__c');
            Id     assignToCMSUserId    = (Id)opp.get('Assign_To_CMS_User__c'); // per flow reference
            Boolean creditDecision      = (Boolean)opp.get('Credit_Decision__c');
            Boolean resubToCredit       = (Boolean)opp.get('Resubmitted_to_Credit__c');

            Datetime docsOutDt          = (Datetime)opp.get('Docs_Out__c');
            Datetime docsInDt           = (Datetime)opp.get('Docs_In__c');

            // ---------------------------
            // Stage-based mappings (Flow: myDecision blocks)
            // ---------------------------

            // 1) Stage = Application → Status: Application In Progress
            // Annual_Revenue__c , Requested_Amount__c
            // Flow node: myDecision / myRule_1 ("Opportunity Stage = Application")
            if (stage == STAGE_APPLICATION && (oldOpp == null || oldOpp.StageName != stage)) {
                opp.put('Opportunity_Status__c', STATUS_APPLICATION_IN_PROGRESS);
            }

            // 2) Stage = Lost → Status: Lost
            if (stage == STAGE_LOST && (oldOpp == null || oldOpp.StageName != stage)) {
                opp.put('Opportunity_Status__c', STATUS_LOST);
            }

            // 3) Docs Requested logic:
            // StageName = 'Docs Requested' AND (- Ready_to_Doc__c = 'Yes' OR Loan_Ready_To_Doc__c = 'Yes')
            if (stage == STAGE_DOCS_REQUESTED && ((oldOpp == null || oldOpp.StageName != stage) || (
                 (READY_YES.equalsIgnoreCase(readyToDoc) || READY_YES.equalsIgnoreCase(loanReadyDoc))
                && (oldOpp == null
                    || !((readyToDoc != null && readyToDoc.equalsIgnoreCase((String)oldOpp.get('Ready_to_Doc__c'))) || (loanReadyDoc != null && loanReadyDoc.equalsIgnoreCase((String)oldOpp.get('Loan_Ready_To_Doc__c')))))))) {
                opp.put('Opportunity_Status__c', STATUS_DOCS_REQUESTED);
            }

            // 4) Stage = Docs Requested AND Assign_To_CMS_User__c not null → Assigned to CMS
            // Flow node: myDecision12 / myRule_13 ("Assigned to CMS")
            if (stage == STAGE_DOCS_REQUESTED && assignToCMSUserId != null
                && (oldOpp == null || (Id)oldOpp.get('Assign_To_CMS_User__c') != assignToCMSUserId)) {
                opp.put('Opportunity_Status__c', STATUS_ASSIGNED_TO_CMS);
            }

            // 5) Stage = Docs Out AND Docs_Out__c has value → Docs Out
            // Flow node: myDecision14 / myRule_15
            // Added stage change as well
            if (stage == STAGE_DOCS_OUT && ((oldOpp == null || oldOpp.StageName != stage) || (docsOutDt != null
                && (oldOpp == null || ((Datetime)oldOpp.get('Docs_Out__c') != docsOutDt && (Datetime)oldOpp.get('Docs_Out__c') == null))))) {
                opp.put('Opportunity_Status__c', STATUS_DOCS_OUT);
            }

            // 6) Stage = Docs In AND Docs_In__c has value → Docs in - Pending review
            // Flow node: myDecision16 / myRule_17
            if (stage == STAGE_DOCS_IN && ((oldOpp == null || oldOpp.StageName != stage) || (docsInDt != null
                && (oldOpp == null || ((Datetime)oldOpp.get('Docs_In__c') != docsInDt && (Datetime)oldOpp.get('Docs_In__c') == null)))))  {
                opp.put('Opportunity_Status__c', STATUS_DOCS_IN_PENDING_REVIEW);
            }

            // ---------------------------
            // Decision-stage logic (Flow: myDecision2 → 4 → 6 → 8)
            // ---------------------------

            // 7) Credit - In Queue
            // Flow node: myDecision2 / myRule_3 (complex AND conditions)
            // Conditions:
            //  - Stage = Decision
            //  - Decision_Status__c NOT IN ('AM','C','R') AND NOT NULL
            //  - Reason_for_Approval__c != 'Instant Auto Decision'
            //  - Credit_Decision__c == false
            //  - Assigned_Credit_User__c == null
            //  - Application_Status__c NOT IN ('Cancelled','Booked')
            //  - Resubmitted_to_Credit__c == true
            if (stage == STAGE_DECISION && 
                ((Opp.Resubmitted_to_Credit__c && (oldOpp == null || oldOpp.Resubmitted_to_Credit__c != Opp.Resubmitted_to_Credit__c))||
                (decisionStat != null && !isOneOf(decisionStat, new Set<String>{'AM','C','R'})
                && !equalsIgnoreCaseSafe(reasonAppr, 'Instant Auto Decision')
                && (creditDecision == null || creditDecision == false)
                && assignedCreditUserId == null
                && !isOneOf(appStatus, new Set<String>{'Cancelled','Booked'}))))
           	{
                opp.put('Opportunity_Status__c', STATUS_CREDIT_IN_QUEUE);
            }

            // 8) Credit - In Review (formula: Assigned_Credit_User__c changed from blank → not blank)
            // Flow node: myDecision4 / myRule_5 + formula_myRule_5
            //  - Prevent if current Status = 'Fraud Review'
            //  - Prevent if current user is in $Label.PEAC_By_Pass_Credit_Review
            if (stage == STAGE_DECISION
                && oldOpp != null
                && oldOpp.get('Assigned_Credit_User__c') == null
                && assignedCreditUserId != null
                && !equalsIgnoreCaseSafe(oppStatus, FRAUD_REVIEW)
                && !isBypassUser) {
                opp.put('Opportunity_Status__c', STATUS_CREDIT_IN_REVIEW);
            }

            // 9) Credit - More Info Requested
            // Flow node: myDecision6 / myRule_7 ("3 AND (1 OR 2) AND 4")
            //  - Stage = Decision
            //  - Application_Status__c IN ('More Info','Returned to Submitter')
            //  - Current Opp Status != 'Fraud More Info Requested'
            if (stage == STAGE_DECISION
                && isOneOf(appStatus, new Set<String>{'More Info','Returned to Submitter'})
                && !equalsIgnoreCaseSafe(oppStatus, FRAUD_MORE_INFO) && (oldOpp == null || (String)oldOpp.get('Application_Status__c') != appStatus)) {
                opp.put('Opportunity_Status__c', STATUS_CREDIT_MORE_INFO);
            }

            // 10) Credit - Declined
            // Flow node: myDecision8 / myRule_9 ("4 AND (1 OR 2 OR 3) AND 5")
            //  - Stage = Decision
            //  - Application_Status__c IN ('Rejected','Automatically Declined','Declined')
            //  - Current Opp Status != 'Suspicious activity - Declined'
            if (stage == STAGE_DECISION
                && isOneOf(appStatus, new Set<String>{'Rejected','Automatically Declined','Declined'})
                && !equalsIgnoreCaseSafe(oppStatus, SUSPICIOUS_DECLINED) && (oldOpp == null || (String)oldOpp.get('Application_Status__c') != appStatus)) {
                opp.put('Opportunity_Status__c', STATUS_CREDIT_DECLINED);
            }

            // If none of the rules matched, we leave Opportunity_Status__c unchanged.
        }
    }

    // ---------- Helpers ----------
    private static Boolean isOneOf(String value, Set<String> options) {
        if (value == null) return false;
        return options.contains(value);
    }
    private static Boolean equalsIgnoreCaseSafe(String a, String b) {
        if (a == null || b == null) return false;
        return a.equalsIgnoreCase(b);
    }
}