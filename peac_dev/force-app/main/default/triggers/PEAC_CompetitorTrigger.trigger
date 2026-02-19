/**************************************************************************************************************
@Author:D Balakrishna(LTIMindtree)
@Description:Competitor Object Trigger 
@User Story:SAL-5810
@Created Date:November-25-2025
**************************************************************************************************************/
trigger PEAC_CompetitorTrigger on Competitor__c (after insert, after update, after delete, after undelete) {
    if (PEAC_CompetitorTriggerHandler.isFirstRun()) {
        PEAC_CompetitorTriggerHandler handler = new PEAC_CompetitorTriggerHandler();

        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            handler.afterUpdate(Trigger.new, Trigger.old);
        }
        if (Trigger.isDelete) {
            handler.afterDelete(Trigger.old);
        }
        if (Trigger.isUndelete) {
            handler.afterUndelete(Trigger.new);
        }
    }
}