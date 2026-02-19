/**************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: Escalation Adjustments Object trigger 
@User Story:DP-1090  
@Created Date:July-19-2024   
**************************************************************************************************************/
trigger PEAC_Escalation_AdjustmentsTrigger on Escalation_Adjustments__c (before insert,after insert) {
    SL_Trigger.dispatchHandler(Escalation_Adjustments__c.SObjectType, new PEAC_EscalationAdjustmentsTriggerHandler());
}