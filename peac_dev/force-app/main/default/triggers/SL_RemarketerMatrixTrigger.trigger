trigger SL_RemarketerMatrixTrigger on Remarketer_Matrix_Obj__c (before insert, before update) {
    SL_Trigger.dispatchHandler(Remarketer_Matrix_Obj__c.SObjectType, new SL_RemarketerMatrixTriggerHandler()); 
}