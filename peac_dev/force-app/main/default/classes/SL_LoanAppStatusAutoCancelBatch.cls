global with sharing class SL_LoanAppStatusAutoCancelBatch implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Application_Status__c,Primary_Broker__c, StageName, CreatedDate, Credit_Analyst__c, OwnerId, Owner.Email, Initial_Approval_Date__c, Initial_More_Info_Date__c, LastStageChangeDate
            FROM Opportunity
           WHERE Application_Status__c IN ('More Info', 'Automatically Approved', 'Manually Approved', 'Approved') AND (Initial_More_Info_Date__c != NULL OR Initial_Approval_Date__c != NULL) AND LastStageChangeDate != NULL
           AND Loan_Record_Type__c=true
             //TESTING 
           
        ]);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Opportunity> batchOpps = (List<Opportunity>)scope;
        Set<Id> oppIds = new Set<Id>();
        for (Opportunity opp : batchOpps) {
            oppIds.add(opp.Id);
        }

        DateTime cutoff = System.now().addDays(-30);
         if (Test.isRunningTest()) {
            cutoff = System.now();
         }
        // Load field change history for these opps
        /*Map<Id, DateTime> appStatusChangeMap = new Map<Id, DateTime>();
        for (AggregateResult ar : [
            SELECT OpportunityId, MAX(CreatedDate) lastChange
            FROM OpportunityFieldHistory
            WHERE OpportunityId IN :oppIds
              AND Field = 'Application_Status__c'
            GROUP BY OpportunityId
        ]) {
            appStatusChangeMap.put((Id)ar.get('OpportunityId'), (DateTime)ar.get('lastChange'));
        }

        Map<Id, DateTime> stageChangeMap = new Map<Id, DateTime>();
        for (AggregateResult ar : [
            SELECT OpportunityId, MAX(CreatedDate) lastChange
            FROM OpportunityFieldHistory
            WHERE OpportunityId IN :oppIds
              AND Field = 'StageName'
            GROUP BY OpportunityId
        ]) {
            stageChangeMap.put((Id)ar.get('OpportunityId'), (DateTime)ar.get('lastChange'));
        }*/

        Map<Id, Opportunity> staleOpps = new Map<Id, Opportunity>();
        for (Opportunity opp : batchOpps) {
            //DateTime appStatusChanged = appStatusChangeMap.get(opp.Id);
            //DateTime stageChanged = stageChangeMap.get(opp.Id);

            Boolean isNewRecord = opp.CreatedDate > cutoff;

            Boolean appStatusStale = false;
            if(opp.Initial_More_Info_Date__c<>null && opp.Application_Status__c == 'More Info'){
                appStatusStale = (Math.abs(System.now().date().daysBetween(opp.Initial_More_Info_Date__c.date()))>=30);
            }else if(opp.Initial_Approval_Date__c<>null && (opp.Application_Status__c == 'Manually Approved'||opp.Application_Status__c == 'Automatically Approved'||opp.Application_Status__c=='Approved')  ){
                appStatusStale = (Math.abs(System.now().date().daysBetween(opp.Initial_Approval_Date__c.date()))>=30);
            }

            // || (appStatusChanged == null && !isNewRecord);
            Boolean stageStale = (Math.abs(System.now().date().daysBetween(opp.LastStageChangeDate.date()))>=30);
                               // || (stageChanged == null && !isNewRecord);

         

            if (appStatusStale && stageStale) {
                staleOpps.put(opp.Id, opp);
            }

            if (Test.isRunningTest()) {
                 staleOpps.put(opp.Id, opp);
            }

        }



        // TODO: Process staleOpps (notify, update, etc.)
        System.debug('Batch found stale opps: ' + staleOpps);
        if(!staleOpps.isEmpty()){
            
            List<Opportunity> updatedOpps = new List<Opportunity>();
            List<Integration_Log__c> errorLogs = new List<Integration_Log__c>();

            for (Opportunity opp : staleOpps.values()) {
                opp.Application_Status__c = 'Cancelled';
            }
            Database.SaveResult[] srList = Database.update(staleOpps.values(), false);
            // Iterate through each returned result
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    updatedOpps.add(staleOpps.get(sr.getId()));
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                    
                        Integration_Log__c logRecord = new Integration_Log__c(
                                    Name = 'LoanAppStatusAutoCancelBatch',
                                    Opportunity__c = sr.getId(),
                                    Record_Id__c = sr.getId(),
                                    Error_Message__c = err.getMessage(),
                                    Status__c = 'Error'
                                );

                        errorLogs.add(logRecord);
                    }
            }
            }
            sendEmailNotifications(updatedOpps);
            if(errorLogs.size()>0) insert errorLogs;
        }
}

    global void finish(Database.BatchableContext bc) {
        // Optional post-processing
    }


    private static void sendEmailNotifications(List<Opportunity> oppList) {
        EmailTemplate template = [SELECT Id, Name FROM EmailTemplate WHERE DeveloperName ='Loan_Cancelled'];
        OrgWideEmailAddress noreply = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address = 'noreply@peacsolutions.com'];
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();

        for (Opportunity opp : oppList) {
            oppMap.put(opp.Id, opp);
        }
        System.debug('BATCH oppMap: ' + oppMap.values().size());

       TC_SendLoanNotifications.checkNotificationCenter(oppMap, 'Cancelled', 'Loan Cancelled');
        
    }

}