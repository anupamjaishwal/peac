public without sharing class SL_ContractMiscBillableTriggerHandler extends SL_Trigger.baseHandler {
    public override void afterInsert(Map<Id, SObject> newMap){
        List<Contract_Misc_Billable__c> newRecords = (List<Contract_Misc_Billable__c>) newMap.values();
        checkAndSetActiveServiceBillable(newRecords);
    }

    public override void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){
        List<Contract_Misc_Billable__c> newRecords = (List<Contract_Misc_Billable__c>) newMap.values();
        List<Contract_Misc_Billable__c> oldRecords = (List<Contract_Misc_Billable__c>) oldMap.values();
        checkAndSetActiveServiceBillable(newRecords);
        checkAndUnsetActiveServiceBillableOnGLCodeChange(oldRecords, newRecords);
        checkAndUnsetActiveServiceBillableOnActiveChange(oldRecords, newRecords);
    }

    public override void afterDelete(Map<Id, SObject> oldMap){
        List<Contract_Misc_Billable__c> oldRecords = (List<Contract_Misc_Billable__c>) oldMap.values();
        checkAndUnsetActiveServiceBillable(oldRecords);
    }

    public void checkAndSetActiveServiceBillable(List<Contract_Misc_Billable__c> newRecords) {
        Set<Id> contractIds = new Set<Id>();
        
        // Collect Contract__c Ids from new records where GL_Code__c is '0017' and Active__c is true
        for (Contract_Misc_Billable__c cmb : newRecords) {
            if (cmb.Contract__c != null && cmb.GL_Code__c == '0017' && cmb.Active__c == true) {
                contractIds.add(cmb.Contract__c);
            }
        }
        
        if (!contractIds.isEmpty()) {
            // Query Contracts to check Active_Service_Billable__c field
            List<Contract__c> contractsToUpdate = new List<Contract__c>();
            for (Contract__c contract : [SELECT Id, Active_Service_Billable__c FROM Contract__c WHERE Id IN :contractIds]) {
                if (!contract.Active_Service_Billable__c) {
                    contract.Active_Service_Billable__c = true;
                    contractsToUpdate.add(contract);
                }
            }
            
            if (!contractsToUpdate.isEmpty()) {
                update contractsToUpdate;
            }
        }
    }

    public void checkAndUnsetActiveServiceBillable(List<Contract_Misc_Billable__c> oldRecords) {
        Set<Id> contractIds = new Set<Id>();
        
        // Collect Contract__c Ids from old records where GL_Code__c is '0017' and Active__c is true
        for (Contract_Misc_Billable__c cmb : oldRecords) {
            if (cmb.Contract__c != null && cmb.GL_Code__c == '0017' && cmb.Active__c == true) {
                contractIds.add(cmb.Contract__c);
            }
        }
        
        if (!contractIds.isEmpty()) {
            // Query Contracts to check if they have any other related Contract_Misc_Billable__c records with GL_Code__c '0017' and Active__c is true
            List<Contract__c> contractsToUpdate = new List<Contract__c>();
            for (Contract__c contract : [
                SELECT Id, 
                       (SELECT Id FROM Contract_Misc_Billables__r WHERE GL_Code__c = '0017' AND Active__c = true) 
                FROM Contract__c 
                WHERE Id IN :contractIds
            ]) {
                if (contract.Contract_Misc_Billables__r.isEmpty()) {
                    contract.Active_Service_Billable__c = false;
                    contractsToUpdate.add(contract);
                }
            }
            
            if (!contractsToUpdate.isEmpty()) {
                update contractsToUpdate;
            }
        }
    }

    public void checkAndUnsetActiveServiceBillableOnGLCodeChange(List<Contract_Misc_Billable__c> oldRecords, List<Contract_Misc_Billable__c> newRecords) {
        Set<Id> contractIds = new Set<Id>();
        
        // Collect Contract__c Ids from old records where GL_Code__c was '0017' and changed to a different value
        for (Integer i = 0; i < oldRecords.size(); i++) {
            Contract_Misc_Billable__c oldRecord = oldRecords[i];
            Contract_Misc_Billable__c newRecord = newRecords[i];
            
            if (oldRecord.Contract__c != null && oldRecord.GL_Code__c == '0017' && newRecord.GL_Code__c != '0017' && oldRecord.Active__c == true) {
                contractIds.add(oldRecord.Contract__c);
            }
        }
        
        if (!contractIds.isEmpty()) {
            // Query Contracts to check if they have any other related Contract_Misc_Billable__c records with GL_Code__c '0017' and Active__c is true
            List<Contract__c> contractsToUpdate = new List<Contract__c>();
            for (Contract__c contract : [
                SELECT Id, 
                       (SELECT Id FROM Contract_Misc_Billables__r WHERE GL_Code__c = '0017' AND Active__c = true) 
                FROM Contract__c 
                WHERE Id IN :contractIds
            ]) {
                if (contract.Contract_Misc_Billables__r.isEmpty()) {
                    contract.Active_Service_Billable__c = false;
                    contractsToUpdate.add(contract);
                }
            }
            
            if (!contractsToUpdate.isEmpty()) {
                update contractsToUpdate;
            }
        }
    }

    public void checkAndUnsetActiveServiceBillableOnActiveChange(List<Contract_Misc_Billable__c> oldRecords, List<Contract_Misc_Billable__c> newRecords) {
        Set<Id> contractIds = new Set<Id>();
        
        // Collect Contract__c Ids from old records where Active__c was true and changed to false
        for (Integer i = 0; i < oldRecords.size(); i++) {
            Contract_Misc_Billable__c oldRecord = oldRecords[i];
            Contract_Misc_Billable__c newRecord = newRecords[i];
            
            if (oldRecord.Contract__c != null && oldRecord.Active__c == true && newRecord.Active__c == false && oldRecord.GL_Code__c == '0017') {
                contractIds.add(oldRecord.Contract__c);
            }
        }
        
        if (!contractIds.isEmpty()) {
            // Query Contracts to check if they have any other related Contract_Misc_Billable__c records with GL_Code__c '0017' and Active__c is true
            List<Contract__c> contractsToUpdate = new List<Contract__c>();
            for (Contract__c contract : [
                SELECT Id, 
                       (SELECT Id FROM Contract_Misc_Billables__r WHERE GL_Code__c = '0017' AND Active__c = true) 
                FROM Contract__c 
                WHERE Id IN :contractIds
            ]) {
                if (contract.Contract_Misc_Billables__r.isEmpty()) {
                    contract.Active_Service_Billable__c = false;
                    contractsToUpdate.add(contract);
                }
            }
            
            if (!contractsToUpdate.isEmpty()) {
                update contractsToUpdate;
            }
        }
    }
}