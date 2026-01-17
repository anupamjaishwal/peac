public with sharing class RemarketerMatrixScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        RemarketerMatrixSyncClient.syncRemarketersToSandbox();
    }
}