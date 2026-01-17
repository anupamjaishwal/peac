global with sharing class SL_LoanAppStatusAutoCancelScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        SL_LoanAppStatusAutoCancelBatch batchJob = new SL_LoanAppStatusAutoCancelBatch();
        Database.executeBatch(batchJob, 200);
    }
}