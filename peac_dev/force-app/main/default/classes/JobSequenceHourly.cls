/**
 * This is a default schedulable job that will initiate a hourly job sequence job. Any schedulable class can call this
 * method.
 *
 * To schedule this class to run, execute the following sequence in anonymous apex
 * System.schedule('JobSequenceHourly', Label.Job_Sequence_Hourly_Cron, new JobSequenceHourly());
 *
 * or
 *
 * JobSequenceUtilities.scheduleHourlyRun();
 */
public with sharing class JobSequenceHourly implements Schedulable {
    public void execute(SchedulableContext sc) {
        System.enqueueJob(new JobSequenceQueueable('Hourly'));
    }

}