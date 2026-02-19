/****************************************************************************************
* @Author       Sumedha G
* @Date         Aprl  19, 2017
*
*****************************************************************************************/

trigger assetTrigger on Asset__c(before insert, before update, after insert, after update, after delete) {
  
    SL_Trigger.dispatchHandler(Asset__c.SObjectType, new assetTriggerHandler());
    
}