public with sharing class SL_InsuranceFollowUpSchedule implements Schedulable {
    public void execute(SchedulableContext ctx) {
        Database.executeBatch(new SL_InsuranceFollowUpBatch());
    }
}