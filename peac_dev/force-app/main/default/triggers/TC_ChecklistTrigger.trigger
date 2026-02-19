/**
 * Created by corycafferty on 2019-02-14.
 */

trigger TC_ChecklistTrigger on TC_Origination__Checklist__c (after insert, after update, before insert, before update) {
    TC_TriggerContext tc = new TC_TriggerContext (Trigger.oldMap, Trigger.newMap, Trigger.new, Trigger.operationType, 'TC_Origination__Checklist__c');
    for (String action : TC_TriggerConfiguation.getConfigs (tc)) {
        system.debug('TC_ChecklistTrigger**');
        TC_TriggerActionFactory.getTriggerAction (action).doAction (tc);
    }
    
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert){
            TC_ChecklistTriggerHelper.mapCreditStipsToFundingBookingChecklists(Trigger.newMap);
            TC_ChecklistTriggerHelper.updateDependentCheckLists(Trigger.new);
            SL_ChecklistTriggerHelper.afterInsert(Trigger.newMap);
        } else if (Trigger.isUpdate) {
            TC_ChecklistTriggerHelper.uncheckChecklistComplete (Trigger.oldMap, Trigger.newMap);
            SL_ChecklistTriggerHelper.afterUpdate(Trigger.newMap, Trigger.oldMap);
        }
    }else if(Trigger.isbefore){
      if (Trigger.isInsert){
        SL_ChecklistTriggerHelper.beforeInsert(Trigger.new);
      }else if(Trigger.isUpdate){
        SL_ChecklistTriggerHelper.beforeUpdate(Trigger.newMap, Trigger.oldMap);
      } 
    }
    


}