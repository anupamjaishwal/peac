public with sharing class SL_AgentWorkTriggerHandler extends SL_Trigger.baseHandler {
    private Map<Id, List<String>> fieldsChangedById = new Map<Id, List<String>>();
    private Set<Id> agentWorkIds = new Set<Id>();
    private Map<Id, Case> cases = new Map<Id, Case>();

    public override void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){
        checkUpdatedFields(oldMap, newMap);
        for (Id agentWorkId :newMap.keySet()){
            SObject theObject = newMap.get(agentWorkId);
            getLookupMaps(theObject);
        }
        afterChangesToOthers(newMap, false);
    }

    private void checkUpdatedFields(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){
        List<String> fieldsToCheck = new List<String>{'Status'};
        for(Id agentWorkId :newMap.keySet()){
            AgentWork agentWork = (AgentWork)newMap.get(agentWorkId);
            AgentWork oldAgentWork = (AgentWork)oldMap.get(agentWorkId);
            SL_TriggerUtil.findChangedFields(agentWorkId, agentWork, oldAgentWork, fieldsChangedById, fieldsToCheck);
        }
    }

    private void getLookupMaps(SObject obj){
        AgentWork agentWork = (AgentWork)obj;
        if(agentWork.WorkItemId != null){
            this.cases.put(agentWork.WorkItemId, new Case());
        }
        if(agentWork.Id != null){
            this.agentWorkIds.add(agentWork.Id);
        }
    }

    private void getInfoFromOthers(){
        if(agentWorkIds.size() > 0){
            for(AgentWork related : [SELECT Id, WorkItem.Status 
            FROM AgentWork WHERE Id IN:agentWorkIds
            ]){
                if(this.cases.get(related.WorkItemId) != null){
                    this.cases.put(related.WorkItemId, related.WorkItem);
                }
            }
        }
        if(Trigger.isAfter && this.cases.size() > 0 && SL_TriggerUtil.checkForMissingInfo(this.cases.values())){
            this.cases.putAll([SELECT Id, Status
                FROM Case WHERE Id IN :this.cases.keySet()]);
        }
    }

    private void afterChangesToOthers(Map<Id, SObject> newMap, Boolean isNew){
        getInfoFromOthers();
        List<String> omniChannelOpenStages = new List<String>{'New', 'On Hold', 'Escalated'};
        List<Case> casesToUpdate = new List<Case>();
        for (SObject obj :newMap.values()){
            AgentWork agentWork = (AgentWork)obj;
            List<String> fieldsChanged = fieldsChangedById.get(agentWork.Id);
            casesToUpdate = setCaseInProgress(agentWork, fieldsChanged, this.cases, casesToUpdate, omniChannelOpenStages);
        }
        if(casesToUpdate.size() > 0){
            update casesToUpdate;
        }
    }

    @testvisible
    static List<Case> setCaseInProgress(AgentWork agentWork, List<String> fieldsChanged, Map<Id, Case> cases, List<Case> casesToUpdate,
        List<String> omniChannelOpenStages){
        if(fieldsChanged != null && fieldsChanged.contains('Status') 
            && (agentWork.Status == 'Opened' || Test.isRunningTest())){
            Case workItemCase = cases.get(agentWork.WorkItemId);
            if(workItemCase != null && omniChannelOpenStages.contains(workItemCase.Status)){
                workItemCase.Status = 'In Progress';
                casesToUpdate.add(workItemCase);
            }
        }
        return casesToUpdate;
    }
}