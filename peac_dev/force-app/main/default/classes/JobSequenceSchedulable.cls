/**
 * This is the schedulable interface which allows a job sequence to be scheduled for future execution, normally used
 * to provide the job sequence queueable or batch jobs with the ability to retry a run in case of too many jobs being
 * in queue or if the job fails. A maximum number of retries is enforced on the job sequence level to prevent a run away
 * transaction
 */
public with sharing class JobSequenceSchedulable implements Schedulable {
    public JobSequence js {Get;Set;}
    public Boolean isRetry {
        Get {
            if (this.isRetry == null) this.isRetry = false;
            return this.isRetry;
        }
        Set;
    }

    public void execute(SchedulableContext sc) {
        try {
            if (js == null) throw new JobSequenceException(getJobSequenceErrorMessage());
            if (js != null && js.sjcs.Enabled__c) {
                
                if (js != null && js.numRetries <= js.sjcs.MaxRetries__c) {

                    JobSequenceQueueable jsq;
                    jsq = isRetry ? new JobSequenceQueueable(js,true) : jsq;
                    jsq = !isRetry ? new JobSequenceQueueable(js) : jsq;

                    if (jsq != null) System.enqueueJob(jsq);
                    if (jsq == null) throw new JobSequenceException(getQueueableNullError());
                }
                if (js != null && js.numRetries >= js.sjcs.MaxRetries__c) js.maxRetryLimitReachedError();
            }
        } catch(Exception e) {
            js.logError(sc.getTriggerId(), e, null);
        }
    }

    /**
     * This constructor will take a job sequence wrapper
     *
     * @param js    The job sequence wrapper object
     */
    public JobSequenceSchedulable(JobSequence js) {
        this.js = js;
    }

    /**
     * This constructor will take the job sequence wrapper and whether or not the schedule job is a retry
     *
     * @param js        The job sequence wrapper object
     * @param isRetry   Whether or not this attempt is a retry
     */
    public JobSequenceSchedulable(JobSequence js, Boolean isRetry) {
        this.isRetry = isRetry;
        this.js = js;
    }

    /**
     * Indicates if the there wasn't a job sequence provided
     *
     * @return  An error message
     */
    @TestVisible static String getJobSequenceErrorMessage() {
        return String.format(
                Label.Job_Sequence_Valid_Job_Sequence_Record_Required,
                new List<String>{'JobSequenceSchedulable'}
        );
    }

    /**
     * Indicates if the queueable constructor was returned as null, if so the message will be passed to the exception
     *
     * @return
     */
    @TestVisible static String getQueueableNullError() {
        return Label.Job_Sequence_Schedulable_Queueable_Result_Invalid;
    }
}