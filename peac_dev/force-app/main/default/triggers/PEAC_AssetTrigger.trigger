/**************************************************************************************************************
@Author: Chalapati Murru (LTIMindtree)
@Description: New trigger that invokes the appropriate handler methods based on the trigger context.
@User Story: SAL-5692 Expo: Opportunity Refactor
@Created Date: 22-Nov-2025
**************************************************************************************************************/
trigger PEAC_AssetTrigger on Asset__c (before insert, before update, after insert, after update, after delete) {

    if(DeactivateTriggers__c.getInstance('PEAC_AssetTrigger') != null && DeactivateTriggers__c.getInstance('PEAC_AssetTrigger').IsDeactived__c) return;

    switch on Trigger.operationType{
        when BEFORE_INSERT{
            PEAC_AssetTriggerHandler.handleBeforeInsert(Trigger.new);
        }
        when BEFORE_UPDATE{
            PEAC_AssetTriggerHandler.handleBeforeUpdate(Trigger.oldMap, Trigger.newMap);
        }
        when AFTER_INSERT{
            PEAC_AssetTriggerHandler.handleAfterInsert(Trigger.newMap);
        }
        when AFTER_UPDATE{
            PEAC_AssetTriggerHandler.handleAfterUpdate(Trigger.oldMap, Trigger.newMap);
        }
        when AFTER_DELETE{
            PEAC_AssetTriggerHandler.handleAfterDelete(Trigger.oldMap);
        }
    }
}