/** @author : Northteq Consulting, Inc.
 * @date : 2/23/21
 * @description: SAL-2320 - Set the Last Contact Activity field on an Account record
 *
 */
public with sharing class TC_UpdateLastContactActivityField implements TC_TriggerActionI {

    /**
     * @param tc The trigger context pointing to the inserted records
     */
    public void doAction(TC_TriggerContext tc) {

        List<Task> activities = (List<Task>) tc.getNewList(); // Newly-inserted activities

        // Get the IDs of accounts and lead primary accounts that are related to the activities
        Set<Id> accountIds = getAccountIds(activities);

        // Update the Last Contact Activity field on each account
        updateLastContactActivity(accountIds);
    }

    /**
     * Checks that the activities meet the entry criteria defined in SAL-2320 and returns related record IDs
     * @param activities The newly-inserted activities
     * @return A set of account IDs, which can be related accounts to activities or a related lead's primary account
     */
    private static Set<Id> getAccountIds(List<Task> activities) {

        // Split the IDs into two sets - they will effectively be joined together later on
        Set<Id> accountIds = new Set<Id>();
        Set<Id> leadIds = new Set<Id>();

        for (Task activity : activities) {

            // Check if the Subject is filled out and meets the entry criteria
            Boolean subjectMet = activity.Subject <> null &&
                    (!activity.Subject.contains('Outbound Call') || !activity.Subject.contains('Inbound Call'));

            // Check if the Task Outcome is filled out and meets the entry criteria
            Boolean taskOutcomeMet = activity.fml_TaskOutcome__c <> null &&
                    (activity.fml_TaskOutcome__c.contains('Contact with Decision Maker')
                            || activity.fml_TaskOutcome__c.contains('Provided Quote')
                            || activity.fml_TaskOutcome__c.contains('Follow-up'));

            if (subjectMet && taskOutcomeMet) {

                // Check if the activity is related to an account and add it to the account ID set
                if (activity.WhatId <> null && String.valueOf(activity.WhatId).substring(0, 3) == '001') {
                    accountIds.add(activity.WhatId);
                }

                // Else check if the activity is related to a lead and add it to the lead ID set
                else if (activity.WhoId <> null && String.valueOf(activity.WhoId).substring(0, 3) == '00Q') {
                    leadIds.add(activity.WhoId);
                }
            }
        }

        // Query the PrimaryAccount__c IDs from the lead IDs and add them to the account ID set
        if (leadIds.size() > 0) {
            for (Lead l : [SELECT Id, PrimaryAccount__c FROM Lead WHERE Id IN :leadIds AND PrimaryAccount__c <> NULL]) {
                accountIds.add(l.PrimaryAccount__c);
            }
        }

        return accountIds;
    }

    /**
     * Sets the Last Contact Activity field on a set of account IDs and updates them
     * @param accountIds Account IDs to query and update records
     */
    private static void updateLastContactActivity(Set<Id> accountIds) {

        // Construct a list of accounts to update and to set their Last Contact Activity date
        List<Account> accountsToUpdate = new List<Account>();
        for (Id accountId : accountIds) {
            accountsToUpdate.add(new Account(Id = accountId, Last_Contact_activity__c = Date.today()));
        }

        // Update the accounts and output the results
        if (accountsToUpdate.size() > 0) {
            Database.SaveResult[] results = Database.update(accountsToUpdate);
            for (Database.SaveResult result : results) {
                if (result.isSuccess()) {
                    System.debug(LoggingLevel.INFO, 'Account ' + result.getId() + ' was successfully updated!');
                } else {
                    for (Database.Error error : result.getErrors()) {
                        System.debug(LoggingLevel.ERROR, 'An error has occurred! ' + error.getMessage());
                        System.debug(LoggingLevel.ERROR, 'Status code: ' + error.getStatusCode());
                        System.debug(LoggingLevel.ERROR, 'Fields: ' + error.getFields() + '\n');
                    }
                }
            }
        }
    }
}