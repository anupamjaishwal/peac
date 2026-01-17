/**
 * SAL-2778 Handles the Fraud Render Decision opportunity button logic
 */
public with sharing class TC_FraudRenderDecisionCtrl {

    /**
     * @description Retrieves the profile and role names of a given user ID
     * @param  userId a user ID to query
     * @return        a user record containing their profile and role names
     */
    @AuraEnabled(cacheable=true)
    public static User getUserInfo(Id userId) {
        User u = [SELECT Id, Profile.Name, UserRole.Name FROM User WHERE Id = :userId];
        return u;
    }

    /**
     * @description Updates opportunity and account fields given an inputted fraud decision
     * @param  opportunityId the ID of the opportunity to be updated
     * @param  decision      the value of the Fraud Decision Status picklist
     */
    @AuraEnabled
    public static void renderDecision(Id opportunityId, String decision) {

        // Query the opportunity and its parent account ID for field updates
        Opportunity opp = TC_DataUtility.getAllFieldsOnOpportunityByRecordId(opportunityId);
        
        User acu;
        try {
            acu = [SELECT Id, Name FROM User WHERE Id = :opp.Assigned_Credit_User__c];
        } catch (Exception e) {
            System.debug ('Exception caught! Is there an Assigned Credit User on the opportunity?');
            System.debug (e.getMessage());
            throw new AuraHandledException('Exception caught! Is there an Assigned Credit User on the opportunity?');
        }

        Boolean isChanged = false;

        try {
            switch on decision {
                when 'Approved' {
                    updateAccountFraudStatus(opp.AccountId, 'PASS', System.now());
                    setOpportunityFraudFields(opp, decision, System.now(), UserInfo.getUserId());
                    opp.StageName = 'Proposal';
                    setOpportunityStatusFields(opp, 'Manually Approved', 'Proposal');
                    isChanged = true;
                }
                when 'Rejected' {
                    updateAccountFraudStatus(opp.AccountId, 'FAIL', System.now());
                    setOpportunityFraudFields(opp, decision, System.now(), UserInfo.getUserId());
                    setOpportunityStatusFields(opp, 'Rejected', 'Suspicious activity - Declined');
                    opp.Decline_Reason__c = 'Unable to Verify Ownership';
                    isChanged = true;
                }
                when 'More Info' {
                    updateAccountFraudStatus(opp.AccountId, '', System.now());
                    setOpportunityFraudFields(opp, decision, System.now(), UserInfo.getUserId());
                    setOpportunityStatusFields(opp, 'More Info', 'Fraud More Info Requested');
                    isChanged = true;
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        } finally {
            if (isChanged) {
                if (opp.Decisioned_By__c == null) {
                    opp.Decisioned_By__c = acu?.Name;
                }

                opp.Resubmitted_to_Credit__c = false;
                opp.Credit_Decision__c = true;

                update opp;

                updateRelatedResubmissionToCredit(opp);
            }
        }
    }

    /**
     * @description Set the Fraud Status field on an account
     * @param  accountId the ID of the account to update
     * @param  status    the value of the Fraud Status field to set
     * @param  dt        the current date/time
     */
    private static void updateAccountFraudStatus(Id accountId, String status, Datetime dt) {
        Account acc = new Account (Id = accountId, Account_Fraud_Status__c = status, Fraud_Review_Date__c = dt);
        update acc;
    }

    /**
     * @description Sets the fraud fields on an opportunity
     * @param  opp      the opportunity to update
     * @param  decision the decision to set
     * @param  dt       the date/time for the Fraud Review Date field
     * @param  userId   the ID of the user making the fraud decision
     */
    private static void setOpportunityFraudFields(Opportunity opp, String decision, Datetime dt, Id userId) {
        opp.Fraud_Review_Status__c = decision;
        opp.Fraud_Review_Date__c = dt;
        opp.Fraud_Decisioned_By__c = userId;
    }

    /**
     * @description Sets the status fields on an opportunity
     * @param  opp               the opportunity to update
     * @param  applicationStatus the Application Status to set
     * @param  opportunityStatus the Opportunity Status to set
     */
    private static void setOpportunityStatusFields(Opportunity opp, String applicationStatus, String opportunityStatus) {
        opp.Application_Status__c = applicationStatus;
        opp.Opportunity_Status__c = opportunityStatus;
    }

    /**
     * @description Update related Resubmission to Credit records 
     * @param  opp the opportunity to update their related records 
     */
    public static void updateRelatedResubmissionToCredit(Opportunity opp) {

        List<Resubmission_to_Credit_Details__c> resubList = [
            SELECT Id,
            Render_Decision_Date_Time__c
            FROM Resubmission_to_Credit_Details__c
            WHERE Opportunity__c = :opp.Id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (resubList.size() > 0) {
            Resubmission_to_Credit_Details__c resub = resubList[0];

            String decimalStrWithDollarSign = '';
            if (String.isNotBlank(String.valueOf(opp.Approved_Amount__c))) {
                decimalStrWithDollarSign = String.format('${0}', new String[]{String.valueOf(opp.Approved_Amount__c.setScale(2).format())});
            }

            String maxTermApproved = '';
            if (String.isNotBlank(String.valueOf(opp.Max_Term_Approved__c))) {
                maxTermApproved = String.valueOf(opp.Max_Term_Approved__c);
            }

            resub.Render_Decision_Date_Time__c = System.now();
            resub.Resub_Decisioned_By__c = UserInfo.getUserId();
            resub.Field_Values_at_Resub_Render_Decision__c = 'Decision Status: ' + opp.Decision_Status__c + '\nApproved Amount: ' + decimalStrWithDollarSign + '\n Max Term Approved: ' + maxTermApproved;
            update resub;
        }
    }
}