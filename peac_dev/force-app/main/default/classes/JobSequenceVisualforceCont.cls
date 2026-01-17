/**
 * This controller handles functions for Job Sequencer visualforce pages
 */
public with sharing class JobSequenceVisualforceCont {
    public JobSequenceVisualforceCont() {}

    /**
     * This function will get the page reference for the sequence jobs so the users can be re-directed to it after
     * clicking on the tab.
     *
     * @return  The page reference for the Sequence Job custom meta data type
     */
    public PageReference getPageRefForSequenceJobs() {
        String prefix = Sequence_Job__mdt.SObjectType.getDescribe().getKeyPrefix();
        PageReference pr = new PageReference('/'+prefix+'?setupid=CustomMetadata');
        pr.setRedirect(true);
        return pr;
    }

    /**
     * This function will return the page reference for the sequence job custom settings, so they users can be re-directed
     * after clicking on the tab
     *
     * @return  The page reference to the custom settings for the sequence Job
     */
    public PageReference getPageRefForSequenceJobCustomSettingSetup() {
       String preFix = Sequence_Jobs_Settings__c.SObjectType.getDescribe().getKeyPrefix();
        PageReference pr = new PageReference('/setup/ui/listCustomSettingsData.apexp?id='+preFix);
        pr.setRedirect(true);
        return pr;
    }

    /**
     * Schedules all of the out of the box job sequence runs
     */
    public void scheduleAllRuns() {
        JobSequenceUtilities.scheduleAllRuns();
    }

    /**
     * This function will schedule the hourly class
     */
    public void scheduleHourlyRun() {
        JobSequenceUtilities.scheduleHourlyRun();
    }

    /**
     * This function will schedule the daily class
     */
    public void scheduleDailyRun() {
        JobSequenceUtilities.scheduleDailyRun();
    }

    /**
     * This function will schedule the weekly class
     */
    public void scheduleWeeklyRun() {
        JobSequenceUtilities.scheduleWeeklyRun();
    }

    /**
     * This function will schedule the monthly class
     */
    public void scheduleMonthlyRun() {
        JobSequenceUtilities.scheduleMonthlyRun();
    }

    /**
     * This function will schedule the quarterly class
     */
    public void scheduleQuarterlyRun() {
        JobSequenceUtilities.scheduleQuarterlyRun();
    }

    /**
     * This function will schedule the yearly class
     */
    public void scheduleYearlyRun() {
        JobSequenceUtilities.scheduleYearlyRun();
    }
}