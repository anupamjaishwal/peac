/**
 * This is a default schedulable job that will initiate an annual job sequence job. Any schedulable class can call this
 * method.
 *
 * To schedule this class to run on the first day of the year at 12 AM, execute the following sequence in anonymous apex
 * System.schedule('JobSequenceYearly', Label.Job_Sequence_Yearly_Cron, new JobSequenceYearly());
 *
 * or
 *
 * JobSequenceUtilities.scheduleYearlyRun();
 */
public with sharing class JobSequenceYearly implements Schedulable {
    public void execute(SchedulableContext sc) {
        System.enqueueJob(new JobSequenceQueueable('Yearly'));
    }
}