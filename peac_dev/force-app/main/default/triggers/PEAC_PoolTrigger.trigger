/**************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: Pool Object trigger 
@User Story:DP-1090  
@Created Date:July-22-2024   
**************************************************************************************************************/
trigger PEAC_PoolTrigger on Pool__c (before insert, before update, after insert, after update) {
    SL_Trigger.dispatchHandler(Pool__c.SObjectType, new PEAC_PoolTriggerHandler());
}