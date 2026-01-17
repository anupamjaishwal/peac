public class SL_InsuranceTVCheckBatch implements Database.Batchable<SObject>, Database.Stateful {
    List<String> allErrors = new List<String>();

    public Database.querylocator start(Database.BatchableContext BC){
        return Database.getQueryLocator('SELECT Titled_Vehicles__c, '
        + '(SELECT Id, Asset_Code__c FROM Contract_Assets__r '
        + 'WHERE Asset_Code__c != null AND Asset_Code__c LIKE \'%Titled_V%\') '
        + 'FROM Insurance__c');
    }
    public void execute(Database.BatchableContext BC, List<SObject> scope){
        List<Insurance__c> insurancesTochange = new List<Insurance__c>();
        for(sObject s : scope){
            Insurance__c insurance = (Insurance__c)s;
            Boolean hasTitledVehicle = insurance.Contract_Assets__r.size() > 0;
            if(insurance.Titled_Vehicles__c != hasTitledVehicle){
                insurance.Titled_Vehicles__c = hasTitledVehicle;
                insurancesTochange.add(insurance);
            }
        }
        if (insurancesTochange.size() > 0){
            List<List<SObject>> bigInsertList = SL_DPSharingRecalcBatch.splitDMLList(insurancesTochange);
            allErrors = SL_DPSharingRecalcBatch.bigUpsert(bigInsertList, false, allErrors);
        }
    }
    public void finish(Database.BatchableContext BC){
        if(allErrors.size() > 0){
            String serializedMap = String.join(allErrors, '. \r\n');
            MARLIN_IntegrationLog.addLog ('Insurance TV Check Batch', BC.getJobId(), 'Error', '', serializedMap.left(131071),
                'Error', 'Error encountered while update Insurance records described in the Response_Message__c field, Validation errors are expected though.');
            MARLIN_IntegrationLog.insertLogs();
            //System.enqueueJob(new SL_CollectionAssignmentQ('dl-salesforcesupport@peacsolutions.com', 'Error Summary shareObject: ' + shareObject, serializedMap));
        }
    }
}