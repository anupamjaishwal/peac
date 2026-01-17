/**
 * This is the default handler for the job sequencer
 * If you wish to create your own custom version of this class, simply copy the relevant implementation portions and
 * define your own custom logic. Then all you need to do is reference the custom handler in your Sequence Job Custom
 * Meta Data Type record in the "Handler Class" field.
 */
global without sharing class JobSequenceDefaultHandler implements JobSequenceInterface {

    /**
     * This method will execute functions based on the function name defined in the "Execution Job" defined on the
     * sequence job custom setting, which is translated into a jobs sequence object wrapper. Each function has to be
     * defined as an option in a case statement (or if statements whichever works best for you), pointing to the
     * appropriate function either in this class or in another.
     *
     * Having the ability to run a function provides you with the ability to scale your job sequences. By providing an
     * interface you may work with, you can either adapt this class or create your own and point the sequence job custom
     * metadata type to the "Handler" of your choice. Thus you can create custom functions that meet the business needs
     * for the jobs you need to have executed in a serial fashion.
     *
     * You are able to scale this further by using parameters which can be defined in a JSON fashion in either a test
     * or production fashion, see the help documentation for further details.
     *
     * @param js    The job sequence wrapped object containing the logic needed to execute the function
     * @param scope The records to be worked with
     */
    global void executeFunction(JobSequence js, List<SObject> scope) {
        if (String.isNotBlank(js.executionJob)) {
            switch on js.executionJob.toUpperCase() {
                when 'FIELDSHIFT' {fieldShift(js, scope);}
                when 'CREATELEADFROMACCOUNT' {createLeadFromAccount(js, scope);}//SAL-1872
                when 'TRANSITIONACCOUNTSTONEWCAMPAIGNS' {transitionAccountsToNewCampaigns(js, scope);}
                when 'TRANSITIONACCOUNTSTONEWSUBCAMPAIGN' {transitionAccountsToNewSubCampaign(js, scope);}//SAL-2037
                when else {js.noFunctionFoundError();}
            }
        }
    }

    /**
     * This method will simply run a DML option based on how you've defined it in the Sequence Job Custom Meta data type
     *
     * @param js    The job sequence wrapped object containing the logic needed to execute the function
     * @param scope The records to be worked with
     */
    global void executeDML(JobSequence js, List<SObject> scope) {
        JobSequenceUtilities.logErrors(js, JobSequenceUtilities.attemptJobSequenceDML(scope, js.executionJob, js.upsertField, js.allOrNone, js.permDelete), new Map<Id, SObject>(scope).keySet());
    }

    /**
     * If you wish some custom logic to be executed when the job sequence is completed, this is where you can do so.
     * An example would be sending an email to let someone know that the sequence has been completed successfully.
     *
     * @param js    The job sequence wrapped object containing the logic needed to execute the function
     */
    global void finishJobSequence(JobSequence js) {
        //This code will look for any job sequence errors for a queueable job and send an email with the errors found
        if (js != null && !js.isBatchJob) {
            if (js.jobId != null) {
                List<Job_Sequence_Error__c> errors = [SELECT Id FROM Job_Sequence_Error__c WHERE BatchJobId__c = :js.jobId];
                if (!errors.isEmpty()) js.sendErrorEmail(js.jobId, errors);
            }
        }
    }

    /**
     * @description This function will transition all valid accounts to sub campaigns (if applicable)
     *
     * @param js    The job sequence
     * @param scope The campaign records to be run
     */
    @TestVisible void transitionAccountsToNewSubCampaign(JobSequence js, List<SObject> scope) {
        if (!Test.isRunningTest()) System.enqueueJob(new TC_SubCampaignQueueable(js, (List<Campaign>) scope));
    }

    /**
     * This method will shift field values to a new value
     * The params must be set on the job sequence object
     * The params must be formatted as follows:
     *
     * fieldApiName:NewValue
     *
     * Multiple values can be done using commas to deliminate
     *
     * @param js    The job sequence wrapped object containing the logic needed to execute the function
     * @param scope The records to be worked with
     */
    @TestVisible void fieldShift(JobSequence js, List<SObject> scope) {
        if (!scope.isEmpty()) {
            Map<String, String> params = js.paramStringsByStrings;
            Map<String, Schema.SObjectField> fldMap = scope[0].getSObjectType().getDescribe().fields.getMap();
            if (params != null && !params.isEmpty()) {
                for (SObject sobj : scope) {
                    JobSequenceUtilities.changeSobjectValueFromParameters(sobj, fldMap, params);
                }
            }
            JobSequenceUtilities.logErrors(js, JobSequenceUtilities.attemptJobSequenceDML(scope, 'UPDATE', js.allOrNone), new Map<Id, SObject>(scope).keySet());
        }
    }

    /**
     * @description This function will create a lead from an account
     * @see         SAL-1872
     *
     * @param js    The job sequence being processed
     * @param scope The batch of records being processed
     */
    @TestVisible void createLeadFromAccount(JobSequence js, List<SObject> scope) {
        if (!scope.isEmpty()) {
            if (!Test.isRunningTest()) JobSequenceUtilities.logErrors(js, new TC_AccountToLead(scope).createLeadsFromAccounts(), null);
        }
    }

    /**
     * @description This function will transition accounts to new campaigns
     *
     * @param js    The job sequence
     * @param scope The records to process
     */
    @TestVisible void transitionAccountsToNewCampaigns(JobSequence js, List<SObject> scope) {
        if (!scope.isEmpty()) {
            if (!Test.isRunningTest()) JobSequenceUtilities.logErrors(js, new TC_CampaignManagement().transitionAccountCampaign(scope), null);
        }
    }

}