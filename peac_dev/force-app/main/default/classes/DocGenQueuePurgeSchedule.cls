global class DocGenQueuePurgeSchedule implements Schedulable {
    /* seconds minutes hours year month day 
    Run at 8:30 am on every saturday. Remember this is Scheduled in the User’s timezone who schedules the job
  */
  public static final String CRON_EXPR = '0 30 8 ? * 7 *';

  /*
    Call this from Anonymous Apex to schedule at the default regularity
  */
  global static String scheduleIt() {
    DocGenQueuePurgeSchedule job = new DocGenQueuePurgeSchedule();
    return System.schedule('Delete 30days old data from DocGenQueue', CRON_EXPR, job);
  }
  
  global void execute(SchedulableContext sc) {
    // This is good practice if you are likely to be processing a
    // lot of records at a time
    DocGenQueuePurgeBatch b = new DocGenQueuePurgeBatch();
      //if(!Test.isRunningTest()){
    Database.executeBatch(b);
     // }
  }
}