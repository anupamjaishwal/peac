/**
 * This is a default schedulable job that will initiate a Monthly job sequence job. Any schedulable class can call this
 * method.
 *
 * To schedule this class to run on the first day of a month at 12 AM, execute the following sequence in anonymous apex
 * System.schedule('JobSequenceMonthly', Label.Job_Sequence_Monthly_Cron, new JobSequenceMonthly());
 *
 * or
 *
 * JobSequenceUtilities.scheduleMonthlyRun();
 */
public with sharing class JobSequenceMonthly implements Schedulable {
    public void execute(SchedulableContext sc) {
        System.enqueueJob(new JobSequenceQueueable('Monthly'));
    }
}