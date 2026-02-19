/** @author : Northteq Consulting, Inc.
 * @date : 2/23/21
 * @description: SAL-2320 - Trigger on the Task object, which includes the Activity object. This follows the Trigger Action pattern.
 */
trigger TC_TaskTrigger on Task (after insert) {

    TC_TriggerContext tc = new TC_TriggerContext (Trigger.oldMap, Trigger.newMap, Trigger.new, Trigger.operationType, 'Task');

    for (String action : TC_TriggerConfiguation.getConfigs (tc)) {

        System.debug('TC_TaskTrigger**');
        TC_TriggerActionFactory.getTriggerAction (action).doAction (tc);
    }
}