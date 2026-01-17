/**
 * This is a default schedulable job that will initiate a daily job sequence job. Any schedulable class can call this
 * method.
 *
 * To schedule this class to run daily at 11PM, execute the following sequence in anonymous apex
 * System.schedule('JobSequenceDaily', Label.Job_Sequence_Daily_Cron, new JobSequenceDaily());
 *
 * or
 *
 * JobSequenceUtilities.scheduleDailyRun();
 */
public with sharing class JobSequenceDaily implements Schedulable {
    public void execute(SchedulableContext sc) {
        System.enqueueJob(new JobSequenceQueueable('Daily'));
    }
}