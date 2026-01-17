/**
 * This is a default schedulable job that will initiate a Weekly job sequence job. Any schedulable class can call this
 * method.
 *
 * To schedule this class to run on Sundays at 11PM, execute the following sequence in anonymous apex
 * System.schedule('JobSequenceWeekly', Label.Job_Sequence_Weekly_Cron, new JobSequenceWeekly());
 *
 * Or
 *
 * JobSequenceUtilities.scheduleWeeklyRun();
 *
 */
public with sharing class JobSequenceWeekly implements Schedulable {
    public void execute(SchedulableContext sc) {
        System.enqueueJob(new JobSequenceQueueable('Weekly'));
    }
}