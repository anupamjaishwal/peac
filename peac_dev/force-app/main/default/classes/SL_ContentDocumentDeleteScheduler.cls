/**
 * ContentDocumentPurgeScheduler
 * 
 * Schedulable wrapper for ContentDocumentPurgeBatch.
 * 
 * To schedule via Anonymous Apex:
 *   System.schedule('Content Doc Purge - Nightly', '0 0 2 * * ?', new ContentDocumentPurgeScheduler());
 * 
 * To reschedule with a different time, abort the existing job first:
 *   for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'Content Doc Purge - Nightly']) {
 *       System.abortJob(ct.Id);
 *   }
 */
public with sharing class SL_ContentDocumentDeleteScheduler implements Schedulable{
    public void execute(SchedulableContext sc) {
        SL_ContentDocumentDeleteBatch batch = new SL_ContentDocumentDeleteBatch();
        Database.executeBatch(batch, 200);
    }
}