/**
 * This is a default schedulable job that will initiate an annual job sequence job. Any schedulable class can call this
 * method.
 *
 * To schedule this class to run on the first day of the quarter at 12 AM, execute the following sequence in anonymous apex
 * System.schedule('JobSequenceQuarterly', Label.Job_Sequence_Quarterly_Cron, new JobSequenceQuarterly());
 *
 * or
 *
 * JobSequenceUtilities.setupQuarterlyRun();
 */
public with sharing class JobSequenceQuarterly implements Schedulable {
    public void execute(SchedulableContext sc) {
        System.enqueueJob(new JobSequenceQueueable('Quarterly'));
    }
}