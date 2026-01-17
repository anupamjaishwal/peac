/**
 * This class is responsible for handling the job sequence execution logic. It will take the handler file name that is
 * defined in the sequence job custom metadata record (translated into the job sequence wrapper object) and execute the
 * handler that extends the job sequence interface. This will help simplify the management of multiple job sequences
 * where custom code has been written for functions or base DML updates
 */
global without sharing class JobSequenceExe {
    private static JobSequenceInterface handler;

    /**
     * When called this function will either execute a batch or queueable job based on the job sequence record passed.
     * These are kept separate due to the rules governing Batch and Queueable processing.
     *
     * @param js    The Job Sequence object wrapper to process
     * @param scope The records to process
     */
    global static void execute(JobSequence js, List<SObject> scope) {
        try {
            if (js != null) {
                if (js.isBatchJob) executeBatch(js, scope);
                if (!js.isBatchJob) executeQueueable(js);
            }
            if (js == null) throw new JobSequenceException(Label.Job_Sequence_No_Job_Sequence_Object_Found_Error);
        } catch (Exception e) {
            JobSequenceUtilities.logError(js, scope, e);
        }
    }

    /**
     * When this function is called, it will execute a job with the assumption that it is a batch execution.
     *
     * @param js        The Job Sequence object wrapper to process
     * @param scope     The records to process
     */
    global static void executeBatch(JobSequence js, List<SObject> scope) {
        try {
            if (js != null) {
                if (handler == null) handler = getHandler(js);
                if (handler != null && String.isNotBlank(js.jobType)) {
                    if (js.jobType.equalsIgnoreCase('DML')) handler.executeDML(js, scope);
                    if (js.jobType.equalsIgnoreCase('Function')) handler.executeFunction(js, scope);
                    handler.finishJobSequence(js);
                }
            }
            if (js == null) throw new JobSequenceException(Label.Job_Sequence_No_Job_Sequence_Object_Found_Error);
        } catch (Exception e) {
            JobSequenceUtilities.logError(js, scope, e);
        }
    }

    /**
     * When this function is called, it will execute the job with the assumption that it was called from a queueable
     * type job. It will query any appropriate records ahead of time if it's called for by the job, so no scope need be
     * passed into it.
     *
     * @param js    The Job Sequence object wrapper to process
     */
    global static void executeQueueable(JobSequence js) {
        executeQueueable(js, String.isNotBlank(js.query) ? Database.query(js.query) : null);
    }

    /**
     * When this function is called, it will execute the job with the assumption that it was called from a queueable
     * type job. It will query any appropriate records ahead of time if it's called for by the job, so no scope need be
     * passed into it.
     *
     * @param js        The Job Sequence object wrapper to process
     * @param scope     The records to process
     */
    global static void executeQueueable(JobSequence js, List<SObject> scope) {
        try {
            if (js != null) {
                if (handler == null) handler = getHandler(js);
                if (handler != null && String.isNotBlank(js.jobType)) {
                    scope = String.isNotBlank(js.query) && (scope == null || scope.isEmpty()) ? Database.query(js.query) : scope;
                    if (js.jobType.equalsIgnoreCase('DML')) handler.executeDML(js, scope);
                    if (js.jobType.equalsIgnoreCase('Function')) handler.executeFunction(js, scope);
                    handler.finishJobSequence(js);
                }
            }
            if (js == null) throw new JobSequenceException(Label.Job_Sequence_No_Job_Sequence_Object_Found_Error);
        } catch (Exception e) {
            JobSequenceUtilities.logError(js, scope, e);
        }
    }

    /**
     * This method will get the handler based on the handler name passed by the job sequence record
     *
     * @param js    The job sequence object wrapper
     *
     * @return      The job sequence interface handler that is used to execute the job sequence logic
     */
    private static JobSequenceInterface getHandler(JobSequence js) {
        JobSequenceInterface jobSequenceInterface;
        try {
            Type h = Type.forName(js.handlerName);
            if (h != null && h.newInstance() instanceof JobSequenceInterface) {
                jobSequenceInterface = (JobSequenceInterface) h.newInstance();
            } else {
                throw new JobSequenceException(Label.Job_Sequence_No_Handler_Found_Error);
            }

        } catch (Exception e) {
            JobSequenceUtilities.logError(js, null, e);
        }
        return jobSequenceInterface;
    }


}