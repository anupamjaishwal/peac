public with sharing class SL_Repurchase_InvoiceTriggerHandler extends SL_Trigger.baseHandler {

// Map status transitions to task description templates
    public static final Map<String, String> STATUS_DESCRIPTION_MAP = new Map<String, String>{
        'OpenToPaid'       => 'Repurchase Invoice #{0} has been paid. ${1} was received.',
        'OpenToDelinquent' => 'Repurchase Invoice #{0} is now delinquent.',
        'OpenToCancelled'   => 'Repurchase Invoice #{0} is now canceled.'
    };

    public override void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {

        checkStatusChange(oldMap, newMap);

    }

    //SL-2204 - Rodrigo Castro
    public void checkStatusChange(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){
                System.debug('checkStatusChange ' );

        Map<Id, Repurchase_Invoice__c> newInvoices = (Map<Id, Repurchase_Invoice__c>)newMap;
        Set<Id> contractIds = new Set<Id>();
        for(Repurchase_Invoice__c inv : newInvoices.values()){
            contractIds.add(inv.Contract__c);
        }

    Map<Id, Contract__c> contracts = new Map<Id, Contract__c>([SELECT Id, Customer__c FROM Contract__c WHERE Id IN :contractIds]);    
    List<Task> newTasks = new List<Task>();
        for(Repurchase_Invoice__c inv : newInvoices.values()){
            if(inv.Status__c == 'Paid' && ((Repurchase_Invoice__c)oldMap.get(inv.Id)).Status__c == 'Open'){
                newTasks.add(createTask(inv,'OpenToPaid', contracts.get(inv.Contract__c).Customer__c));
            }
            if(inv.Status__c == 'Delinquent' && ((Repurchase_Invoice__c)oldMap.get(inv.Id)).Status__c == 'Open'){
                newTasks.add(createTask(inv,'OpenToDelinquent', contracts.get(inv.Contract__c).Customer__c));
            }
            if(inv.Status__c == 'Cancelled' && ((Repurchase_Invoice__c)oldMap.get(inv.Id)).Status__c == 'Open'){
                newTasks.add(createTask(inv,'OpenToCancelled', contracts.get(inv.Contract__c).Customer__c));
            }
        }
        if(newTasks.size() > 0){
            insert newTasks;
        }
    }


    public Task createTask(Repurchase_Invoice__c invoiceRecord, String statusChange, String customerId){
            //Creating task for automatic notation as requested in SL-2204
            Task taskRecord =  new Task();
            taskRecord.Contract__c =invoiceRecord.Contract__c;
            taskRecord.WhatId = customerId;
            taskRecord.Type ='Other';
            taskRecord.ActivityDate =Date.today();
            taskRecord.Description = String.format(STATUS_DESCRIPTION_MAP.get(statusChange), new List<String>{invoiceRecord.Name, String.valueOf(invoiceRecord.Amount_Invoiced__c)});
            taskRecord.Status ='Completed';
            return taskRecord;
        }
    


}