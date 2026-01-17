public with sharing class SL_DPPermissionsSchedule implements Schedulable {
    public void execute(SchedulableContext ctx) {
        SL_DPPermissions.checkDealerAdminShares();
    }
}