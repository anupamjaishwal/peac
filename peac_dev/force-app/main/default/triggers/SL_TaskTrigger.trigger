trigger SL_TaskTrigger on Task (before insert, before update, after insert, after update) {
	SL_Trigger.dispatchHandler(Task.SObjectType, new SL_TaskTriggerHandler());
}