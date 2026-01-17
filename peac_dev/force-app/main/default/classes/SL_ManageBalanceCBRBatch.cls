public with sharing class SL_ManageBalanceCBRBatch implements Database.Batchable<SObject>, Database.Stateful{
    Decimal minimalLimit, maximalLimit, minimalLimit_XBS_ADR, maximalLimit_XBS_ADR;
    Boolean allXBS;
    List<Database.SaveResult> allResults;

    public SL_ManageBalanceCBRBatch(Decimal previousMaxBalance, Decimal currentMaxBalance, Decimal previousMaxBalance_XBS_ADR, Decimal currentMaxBalance_XBS_ADR, Boolean allXBS) {
        this.minimalLimit = System.Math.min(previousMaxBalance, currentMaxBalance);
        this.maximalLimit = System.Math.max(previousMaxBalance, currentMaxBalance);
        this.minimalLimit_XBS_ADR = System.Math.min(previousMaxBalance_XBS_ADR, currentMaxBalance_XBS_ADR);
        this.maximalLimit_XBS_ADR = System.Math.max(previousMaxBalance_XBS_ADR, currentMaxBalance_XBS_ADR);
        this.allXBS = allXBS;
        this.allResults = new List<Database.SaveResult>();
    }

    public Database.querylocator start(Database.BatchableContext BC){
        if(allXBS){
            return Database.getQueryLocator('SELECT Name, Collection_Group__c '+
            'FROM Contract__c WHERE '
            + '(Customer__c != null AND (NOT Status__c LIKE \'%Disposed%\') '
            + 'AND (IsXBS__c = true OR Lessor_Code__c IN (\'101\',\'102\',\'471\'))) AND Delinquency_Status_Code__c =\'01\'' 
            );
        }
        else{
            return Database.getQueryLocator('SELECT Name, Collection_Group__c '+
            'FROM Contract__c WHERE (Customer__c != null AND (NOT Status__c LIKE \'%Disposed%\') '
            + 'AND Contract_Balance_Remaining__c > ' + String.valueOf(this.minimalLimit) + ' '
            + 'AND Contract_Balance_Remaining__c <= ' + String.valueOf(this.maximalLimit) + ' '
            + 'AND Collection_Group__c IN (\'Dialer Regular\',  \'Dialer Team Assigned\', \'Dialer Do Not Call\') )'
            + 'OR'
            + '(Customer__c != null AND (NOT Status__c LIKE \'%Disposed%\') '
            + 'AND Contract_Balance_Remaining__c > ' + String.valueOf(this.minimalLimit_XBS_ADR) + ' '
            + 'AND Contract_Balance_Remaining__c <= ' + String.valueOf(this.maximalLimit_XBS_ADR) + ' '
            + 'AND Collection_Group__c IN (\'XBS Dialer Regular\',  \'XBS Dialer Team Assigned\', \'XBS Low Balance\', \'ADR Dialer Team Assigned\', \'ADR Dialer Regular\', \'ADR Low Balance\')  '
            + 'AND (IsXBS__c = true OR Lessor_Code__c IN (\'101\',\'102\',\'471\')))'            
            );
        }

    }
    public void execute(Database.BatchableContext BC, List<SObject> scope){
        List<Contract__c> contractsToUpdate = new List<Contract__c>();
        for(SObject s :scope){
            Contract__c contract = (Contract__c)s;
            contract.Collection_Group__c = null;
            contractsToUpdate.add(contract);
        }
        System.debug(' SL_ManageBalanceCBRBatch contractsToUpdate ' + contractsToUpdate.size() );
        if(contractsToUpdate.size() > 0){
            List<Database.SaveResult> contractResult = Database.update(contractsToUpdate, false);
            allResults.addAll(contractResult);
        }
    }
    public void finish(Database.BatchableContext BC){
        Integer alreadyQueuedJobs = [SELECT COUNT() from asyncapexjob WHERE ApexClass.Name = 'SL_CollectionAssignmentQ' AND (NOT Status IN ('Aborted', 'Completed', 'Failed'))];
        if(alreadyQueuedJobs == 0){
            System.enqueueJob(new SL_CollectionAssignmentQ());
        }
    }

}