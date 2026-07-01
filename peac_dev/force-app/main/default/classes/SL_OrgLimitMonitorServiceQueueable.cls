public with sharing class SL_OrgLimitMonitorServiceQueueable implements Queueable, Database.AllowsCallouts {
    public void execute(QueueableContext context) {
        SL_OrgLimitMonitorService.checkLimits(); 
    }
}