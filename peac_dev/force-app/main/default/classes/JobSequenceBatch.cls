/**
 * This class is responsible for handling items in a batch context.
 */
public without sharing class JobSequenceBatch implements Database.Batchable<SObject>,Database.Stateful, Database.AllowsCallouts {
    private JobSequence js {Get;Set;}

    public Database.QueryLocator start(Database.BatchableContext BC) {
        Database.QueryLocator returnLocator;
        try {
            js.query = String.isBlank(js.query) ? 'SELECT Id FROM User LIMIT 0' : js.query;
            returnLocator = Database.getQueryLocator(js.query);
        } catch (Exception e) {
            js.logError(BC.getJobId(), e, null);
            returnLocator = Database.getQueryLocator('SELECT Id FROM '+js.query.toUpperCase().substringAfterLast(' FROM ').substringBefore(' ')+' LIMIT 0');
        }

        return returnLocator;
    }
    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        try {
            JobSequenceExe.execute(js, scope);
        } catch (Exception e) {
            JobSequenceUtilities.logError(js,scope,e);
        }

    }
    public void finish(Database.BatchableContext BC) {
        handleFinish(bc,js);
    }

    public JobSequenceBatch(JobSequence js) {
        this.js = js;
    }

    /**
     * This function will handle the finish actions for the batch job and will send an email if errors are found
     * and enqueue the next job sequence
     *
     * @param bc    The batch context
     * @param js    The job sequence
     */
    private static void handleFinish(Database.BatchableContext bc, JobSequence js) {
        List<Job_Sequence_Error__c> errors = [SELECT Id FROM Job_Sequence_Error__c WHERE BatchJobId__c = :BC.getJobId()];
        if (!errors.isEmpty()) js.sendErrorEmail(bc.getJobId(), errors);
        System.enqueueJob(new JobSequenceQueueable(js));
    }

}