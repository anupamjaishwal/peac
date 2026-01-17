public class SL_ContractUpdateBatch implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Contract__c, GL_Code__c, Active__c, Contract__r.Active_Service_Billable__c ' +
                       'FROM Contract_Misc_Billable__c ' +
                       'WHERE GL_Code__c = \'0017\' AND ' +
                       '((Active__c = false AND Contract__r.Active_Service_Billable__c = true) OR ' +
                       '(Active__c = true AND Contract__r.Active_Service_Billable__c = false))';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Contract_Misc_Billable__c> scope) {
        Set<Id> contractIds = new Set<Id>();
        for (Contract_Misc_Billable__c cmb : scope) {
            contractIds.add(cmb.Contract__c);
        }

        // Query all related Contract_Misc_Billable__c records in one query
        Map<Id, List<Contract_Misc_Billable__c>> contractToCmbMap = new Map<Id, List<Contract_Misc_Billable__c>>();
        for (Contract_Misc_Billable__c cmb : [SELECT Id, Contract__c, Active__c FROM Contract_Misc_Billable__c WHERE Contract__c IN :contractIds]) {
            if (!contractToCmbMap.containsKey(cmb.Contract__c)) {
                contractToCmbMap.put(cmb.Contract__c, new List<Contract_Misc_Billable__c>());
            }
            contractToCmbMap.get(cmb.Contract__c).add(cmb);
        }

        // Query all related Contract__c records in one query
        Map<Id, Contract__c> contractsMap = new Map<Id, Contract__c>([SELECT Id, Active_Service_Billable__c FROM Contract__c WHERE Id IN :contractIds]);
    
        List<Contract__c> contractsToUpdate = new List<Contract__c>();
        for (Id contractId : contractToCmbMap.keySet()) {
            Boolean shouldBeActive = false;
            for (Contract_Misc_Billable__c cmb : contractToCmbMap.get(contractId)) {
                if (cmb.Active__c == true) {
                    shouldBeActive = true;
                    break;
                }
            }

            Contract__c contract = contractsMap.get(contractId);
            if (contract.Active_Service_Billable__c != shouldBeActive) {
                contract.Active_Service_Billable__c = shouldBeActive;
                contractsToUpdate.add(contract);
            }
        }

        if (!contractsToUpdate.isEmpty()) {
            update contractsToUpdate;
        }
    }

    public void finish(Database.BatchableContext bc) {
        // Optional: Add any post-processing logic here
    }
}