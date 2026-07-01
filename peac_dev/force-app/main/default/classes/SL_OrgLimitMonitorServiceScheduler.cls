global class SL_OrgLimitMonitorServiceScheduler implements Schedulable {


    global void execute(SchedulableContext sc) {

        try {
            System.enqueueJob(new SL_OrgLimitMonitorServiceQueueable());          
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        } finally {
            cleanExistingJobs();
            scheduleNext();
        }
    }


    private void cleanExistingJobs() {
        List<CronTrigger> jobs = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE 'OrgLimitMonitor%'
        ];

        for (CronTrigger job : jobs) {
            System.abortJob(job.Id);
        }
    }


    private void scheduleNext() {
        Datetime nextRun = System.now().addMinutes(15);

        String cron = '0 ' + nextRun.minute() + ' ' +
                      nextRun.hour() + ' ' +
                      nextRun.day() + ' ' +
                      nextRun.month() + ' ? ' +
                      nextRun.year();

        System.schedule(
            'OrgLimitMonitor_' + nextRun.getTime(),
            cron,
            new SL_OrgLimitMonitorServiceScheduler()
        );
    }
}