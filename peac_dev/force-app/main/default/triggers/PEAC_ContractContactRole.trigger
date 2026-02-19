/**************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: Contract Contact Role Object trigger 
@User Story:DP-903   
@Created Date:June-18-2024   
**************************************************************************************************************/
trigger PEAC_ContractContactRole on Contract_Contact_Role__c (before insert, before update, before delete,after insert, after update,after delete) {
    SL_Trigger.dispatchHandler(Contract_Contact_Role__c.SObjectType, new PEAC_ContractContactRoleTriggerHandler());
}