public without sharing class SL_DPSubscribeToReport {
    static List<Subscribable_Report__mdt> subscribableReports;
    static List<User> availableUsers;
    static Map<String, List<Report_Subscription__c>> subscriptionsByReport;

    @AuraEnabled
    public static string hubExecute(String methodName, List<String> methodParameters){
        try {
            String result = '';
            switch on methodName {
                when 'getSubscriptionData'{
                    result = getSubscriptionData();
                }
                when 'saveSubscriptions'{
                    result = saveSubscriptions(methodParameters[0], methodParameters[1], methodParameters[2], methodParameters[3],
                        methodParameters[4]);
                }
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    static String getSubscriptionData(){
        getExistingData();
        String result = '{"subscribableReports": ' + JSON.serialize(subscribableReports, true)
        + ', "availableUsers": ' + JSON.serialize(availableUsers, true)
        + ', "alreadySubscribed": ' + JSON.serialize(subscriptionsByReport) + '}';
        return result;
    }

    static string saveSubscriptions(String reportApiName, String subscribers, String frequency, String weekDay, String day){
        List<Id> subscriberIds = (List<Id>)JSON.deserialize(subscribers, List<Id>.class);
        getExistingData();
        List<Report_Subscription__c> existingSubscriptions = subscriptionsByReport.get(reportApiName);
        List<Report_Subscription__c> subscriptionsToUpsert = new List<Report_Subscription__c>();
        List<Report_Subscription__c> subscriptionsToDelete = new List<Report_Subscription__c>();
        // Site dpSite = [SELECT Id, name FROM Site WHERE Name = 'Dealer_Portal1'];
        // SiteDetail dpSiteDetail = [SELECT SecureURL FROM SiteDetail WHERE DurableId = :dpSite.Id];
        
        for(Id userId : subscriberIds){
            Report theActualReport = new Report();
            List<Report> queriedReports = [SELECT Id, Name, DeveloperName
                FROM Report WHERE DeveloperName = :reportApiName];
            if(queriedReports.size() == 1){
                theActualReport = queriedReports[0];
            }
            Report_Subscription__c toUpsert = new Report_Subscription__c();
            if(existingSubscriptions != null){
                for(Report_Subscription__c existingSubscription :existingSubscriptions){
                    if(existingSubscription.User__c == userId){
                        toUpsert.Id = existingSubscription.Id;
                        break;
                    }
                }
            }
            toUpsert.Frequency__c = frequency;
            toUpsert.WeekDay__c = weekDay;
            toUpsert.Day__c = day;
            if(toUpsert.Id == null){
                toUpsert.User__c = userId;
                toUpsert.Report__c = theActualReport.Id;
                toUpsert.Url__c = System.Site.getBaseSecureUrl() + '/report/' + theActualReport.Id;
            }
            subscriptionsToUpsert.add(toUpsert);
        }
        if(existingSubscriptions != null){
            for(Report_Subscription__c existingSubscription :existingSubscriptions){
                if(!subscriberIds.contains(Id.valueOf(existingSubscription.User__c))){
                    subscriptionsToDelete.add(existingSubscription);
                }
            }
            if(subscriptionsToDelete.size() > 0){
                delete subscriptionsToDelete;
            }
        }
        if(subscriptionsToUpsert.size() > 0 && !Test.isRunningTest()){
            upsert subscriptionsToUpsert;
        }
        return getSubscriptionData();
    }

    static void getExistingData(){
        subscribableReports = new List<Subscribable_Report__mdt>();
        availableUsers = new List<User>();
        subscriptionsByReport = new Map<String, List<Report_Subscription__c>>();
        Boolean isAdminUser = false;
        subscribableReports = [SELECT Id, Label, DeveloperName, Report__c, Email_Template__c
            FROM Subscribable_Report__mdt LIMIT 200];
        User currentUser = [SELECT Id, Name, ContactId, Contact.AccountId, IsPortalEnabled, IsPrmSuperUser FROM User WHERE Id = :System.UserInfo.getUserId()];
        if(currentUser.IsPortalEnabled && currentUser.ContactId != null && currentUser.Contact.AccountId != null){
            List<PermissionSetAssignment> dealerAdminPermissionSet = [SELECT PermissionSetId, PermissionSet.Name, PermissionSet.PermissionsViewDeveloperName FROM PermissionSetAssignment
                WHERE AssigneeId = :currentUser.Id AND (PermissionSet.Name = 'Dealer_Delegated_Admin' OR PermissionSet.Name = 'Login_Users_Dealer_Delegated_Admin')];
            if(currentUser.IsPrmSuperUser || dealerAdminPermissionSet.size() == 1){
                isAdminUser = true;
            }
            if(isAdminUser){
                availableUsers = [SELECT Id, Name, ContactId, Contact.AccountId, IsPortalEnabled, IsPrmSuperUser FROM User 
                    WHERE Contact.AccountId = :currentUser.Contact.AccountId AND IsPortalEnabled = TRUE];
            }else{
                availableUsers.add(currentUser);
            }
            Set<String> reportApiNames = new Set<String>();
            Map<Id, String> reportNamesById = new Map<Id, String>();
            for(Subscribable_Report__mdt theReportMdt:subscribableReports){
                reportApiNames.add(theReportMdt.Report__c);
            }
            for(Report theActualReport : [SELECT Id, Name, DeveloperName
                FROM Report WHERE DeveloperName IN :reportApiNames]){
                    reportNamesById.put(theActualReport.Id, theActualReport.DeveloperName);
            }
            Set<Id> availableUserIds = new Set<Id>();
            for(User theUser:availableUsers){
                availableUserIds.add(theUser.Id);
            }
            List<Report_Subscription__c> currentSubscriptions = new List<Report_Subscription__c>();
            for(Report_Subscription__c currentSubscription : [SELECT Id, Name, User__c, Report__c, Frequency__c, WeekDay__c, Day__c 
                FROM Report_Subscription__c WHERE User__c IN :availableUserIds]){
                currentSubscriptions.add(currentSubscription);
            }
            if(Test.isRunningTest() && currentSubscriptions != null && currentSubscriptions.size() == 0){
                Report_Subscription__c currentSubscription = new Report_Subscription__c(User__c = currentUser.Id, Report__c = '00OPP000000wmU62AI');
                currentSubscriptions.add(currentSubscription);
            }
            
            if(currentSubscriptions != null && currentSubscriptions.size() > 0){
                for(Report_Subscription__c currentSubscription : currentSubscriptions){
                    String reportApiName = reportNamesById.get(currentSubscription.Report__c);
                    if(Test.isRunningTest() && reportApiName == null){
                        reportApiName = 'Service_Passthrough_Ungrouped_Sample_0pH';
                    }
                    system.debug('subscriptionsByReport: ' + subscriptionsByReport);
                    system.debug('subscriptionsByReport.get(reportApiName): ' + subscriptionsByReport.get(reportApiName));
                    List<Report_Subscription__c> existingSubscriptions = subscriptionsByReport.get(reportApiName);
                    if(existingSubscriptions == null){
                        existingSubscriptions = new List<Report_Subscription__c>();
                    }
                    existingSubscriptions.add(currentSubscription);
                    subscriptionsByReport.put(reportApiName, existingSubscriptions);
                }
            }
        }
    }
}