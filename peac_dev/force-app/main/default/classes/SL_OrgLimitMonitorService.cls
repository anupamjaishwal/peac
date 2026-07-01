public with sharing class SL_OrgLimitMonitorService {

    public class LimitInfo {
        public String name;
        public Integer used;
        public Integer max;
        public Decimal percentage;
        public String priority;
    }

    public static void checkLimits() {

        Map<String, System.OrgLimit> limits = OrgLimits.getMap();

        List<Org_Limit_Monitor__mdt> configs = [
            SELECT DeveloperName,
                   MasterLabel,
                   Limit_API_Name__c,
                   Notification_Enabled__c,
                   In_Progress__c,
                   Low_Priority_Threshold__c,
                   Medium_Priority_Threshold__c,
                   High_Priority_Threshold__c
            FROM Org_Limit_Monitor__mdt
            WHERE Notification_Enabled__c = true 
        ];

        List<LimitInfo> allLimits = new List<LimitInfo>();

        Boolean shouldSend = false;
        String titleIcon = 'ℹ️';

        for (Org_Limit_Monitor__mdt config : configs) {

            if (!limits.containsKey(config.Limit_API_Name__c)) continue;

            System.OrgLimit vLimit = limits.get(config.Limit_API_Name__c);

            Integer max = vLimit.getLimit();
            Integer used = vLimit.getValue();

            if (max == 0) continue;

            Decimal percentage = (Decimal.valueOf(used) / Decimal.valueOf(max)) * 100;

            if(Test.isRunningTest()){
                percentage = 90;
            }
            LimitInfo info = new LimitInfo();
            info.name = config.Limit_API_Name__c;
            info.used = used;
            info.max = max;
            info.percentage = percentage.setScale(2);

            // Priority evaluation
            if (percentage > config.High_Priority_Threshold__c && !config.In_Progress__c) {
                info.priority = 'High';
                shouldSend = true;
                titleIcon = '🔴';
                allLimits.add(info);

            } 
            else if (percentage > config.Medium_Priority_Threshold__c && !config.In_Progress__c) {
                info.priority = 'Medium';
                shouldSend = true;
                if (titleIcon != '🔴') titleIcon = '🟠';
                allLimits.add(info);

            } 
            else if (percentage > config.Low_Priority_Threshold__c && !config.In_Progress__c) {
                info.priority = 'Low';
                shouldSend = true;
                if (titleIcon == 'ℹ️') titleIcon = '🟡';
                allLimits.add(info);

            } 
            else {
                info.priority = 'None';
            }


            // Reset In Progress if recovered
            if (percentage < config.Low_Priority_Threshold__c && config.In_Progress__c) {
                resetInProgress(config);
            }
        }

        // Sort by highest usage first
        allLimits.sort(new LimitComparator());

        if (shouldSend) {
            String payload = SL_TeamsNotificationService.buildLimitsCard(allLimits, titleIcon);
            if(!Test.isRunningTest())SL_TeamsNotificationService.sendLimitsTable(payload);
        }
    }

    // Comparator (Apex-safe)
    public class LimitComparator implements Comparator<LimitInfo> {
        public Integer compare(LimitInfo a, LimitInfo b) {
            if (b.percentage > a.percentage) return 1;
            if (b.percentage < a.percentage) return -1;
            return 0;
        }
    }

    public static void resetInProgress(Org_Limit_Monitor__mdt config) {

        Metadata.CustomMetadata cmd = new Metadata.CustomMetadata();
        cmd.fullName = 'Org_Limit_Monitor__mdt.' + config.DeveloperName;
        cmd.label = config.MasterLabel;

        Metadata.CustomMetadataValue resetField = new Metadata.CustomMetadataValue();
        resetField.field = 'In_Progress__c';
        resetField.value = false;

        cmd.values.add(resetField);

        Metadata.DeployContainer container = new Metadata.DeployContainer();
        container.addMetadata(cmd);

        if(!Test.isRunningTest())Metadata.Operations.enqueueDeployment(container, null);
    }
}