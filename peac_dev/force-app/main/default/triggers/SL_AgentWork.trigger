trigger SL_AgentWork on AgentWork (after update) {
    SL_Trigger.dispatchHandler(AgentWork.SObjectType, new SL_AgentWorkTriggerHandler());
}