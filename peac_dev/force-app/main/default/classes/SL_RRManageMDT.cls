public without sharing class SL_RRManageMDT {
    private static List<String> fullNames;
    public static List<String> synchronizeRRAssignees(){
        fullNames = new List<String>();
        synchronizeRRQueues(false, true);
        return fullNames;
    }

    public static void synchronizeRRQueues(Boolean isForRRQueues, Boolean retrieveDeletionOnly){
        Map<Id, Group> groupQueues =  new Map<Id, Group>();
        Map<Id, Group> contractQueues =  new Map<Id, Group>();
        Map<Id, Map<Id, GroupMember>> queueMembers = new Map<Id, Map<Id, GroupMember>>();
        Map<Id, Map<Id, QueueSobject>> targetObjects = new Map<Id, Map<Id, QueueSobject>>();
        Set<Id> userIds = new Set<Id>();
        Map<Id, User> users = new Map<Id, User>();
        Map<Id, RR_Queue__mdt> rrQueues = new Map<Id, RR_Queue__mdt>();
        Map<Id, RR_Assignee__mdt> rrAssignees = new Map<Id, RR_Assignee__mdt>();
        
        groupQueues.putAll([SELECT Id, Name, developerName, relatedId, type FROM Group WHERE Type='Queue']);
        List<GroupMember> allGroupMembers = [SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId IN :groupQueues.keySet()];
        List<QueueSobject> allTargetObjects = [SELECT Id, QueueId, SobjectType FROM QueueSobject WHERE QueueId IN :groupQueues.keySet()];
        
        for(Id queueId :groupQueues.keySet()){
            queueMembers.put(queueId, new Map<Id, GroupMember>());
            targetObjects.put(queueId, new Map<Id, QueueSobject>());
        }
        for(Id queueId :groupQueues.keySet()){
            for(GroupMember member : allGroupMembers){
                if(member.GroupId == queueId){
                    queueMembers.get(queueId).put(member.Id, member);
                }
            }
            for(Id groupMemberId :queueMembers.get(queueId).keySet()){
                GroupMember member = queueMembers.get(queueId).get(groupMemberId);
                userIds.add(member.UserOrGroupId);
            }
            for(QueueSobject target : allTargetObjects){
                if(target.QueueId == queueId){
                    targetObjects.get(queueId).put(target.Id, target);
                }
            }
        }
        users.putAll([SELECT id, Username, FirstName, LastName, Name FROM User WHERE Id IN :userIds]);
        rrQueues.putAll([SELECT Id, Name__c, Is_Active__c, QueueId__c FROM RR_Queue__mdt]);
        rrAssignees.putAll([SELECT Id, Name__c, Is_Active__c, User__c, Last_Assigned__c, RR_Queue__c FROM RR_Assignee__mdt]);
        for(Id groupQueueId : groupQueues.keySet()){
            Group queue = groupQueues.get(groupQueueId);
            if(isContractQueue(targetObjects.get(queue.Id))){
                contractQueues.put(queue.Id, queue);
            }
        }

        if(isForRRQueues){
            checkForNewQueues(contractQueues, rrQueues);
        }else{
            checkForNewAssignees(queueMembers, rrQueues, users, rrAssignees, retrieveDeletionOnly);
        }
    }

    static void checkForNewQueues(Map<Id, Group> contractQueues, Map<Id, RR_Queue__mdt> rrQueues){
        List<RR_Queue__mdt> rrQueuesToAdd = new List<RR_Queue__mdt>();
        List<RR_Queue__mdt> rrQueuesToRemove = new List<RR_Queue__mdt>();

        for(Id groupQueueId : contractQueues.keySet()){
            Group queue = contractQueues.get(groupQueueId);
            if(findInRRQueue(queue.Id, rrQueues) == null){
                rrQueuesToAdd.Add(new RR_Queue__mdt(Name__c = queue.DeveloperName,
                    Is_Active__c = true,
                    QueueId__c = queue.Id));
            }
        }
        for(Id rrQueueId : rrQueues.keySet()){
            RR_Queue__mdt rrQueue = rrQueues.get(rrQueueId);
            if(contractQueues.get(rrQueue.QueueId__c) == null){
                //rrQueuesToRemove.Add(rrQueue);// as of July 2021 there is no way to remove mdt records through apex
            }
        }
        if(rrQueuesToAdd.size() > 0){
            SL_RRManageMDT.updateRRQueues(rrQueuesToAdd);
        }
    }

    static void checkForNewAssignees(Map<Id, Map<Id, GroupMember>> queueMembers, 
        Map<Id, RR_Queue__mdt> rrQueues, Map<Id, User> users, Map<Id, RR_Assignee__mdt> rrAssignees, Boolean retrieveDeletionOnly){
        List<RR_Assignee__mdt> rrAssigneesToAdd = new List<RR_Assignee__mdt>();
        List<RR_Assignee__mdt> rrAssigneesToRemove = new List<RR_Assignee__mdt>();
        Map<Id, List<Id>> userIdsPerQueue = new Map<Id, List<Id>>();
        Map<Id, Map<Id, RR_Assignee__mdt>> rrQueueAssignees = new Map<Id, Map<Id, RR_Assignee__mdt>>();
        for(Id rrQueueId :rrQueues.keySet()){
            RR_Queue__mdt rrQueue = rrQueues.get(rrQueueId);
            userIdsPerQueue.put(rrQueue.QueueId__c, new List<Id>());
            rrQueueAssignees.put(rrQueue.QueueId__c, new Map<Id, RR_Assignee__mdt>());
            for(Id groupMemberId :queueMembers.get(rrQueue.QueueId__c).keySet()){
                GroupMember queueMember = queueMembers.get(rrQueue.QueueId__c).get(groupMemberId);
                if(findInRRAssignee(rrQueue.Id, queueMember.UserOrGroupId, rrAssignees) == null){
                    User theUser = users.get(queueMember.UserOrGroupId);
                    if(theUser != null){
                        rrAssigneesToAdd.Add(new RR_Assignee__mdt(Name__c = theUser.Name,
                            Is_Active__c = true,
                            User__c = queueMember.UserOrGroupId,
                            Last_Assigned__c = null,
                            RR_Queue__c = rrQueue.Id));
                    }
                    
                }
                userIdsPerQueue.get(rrQueue.QueueId__c).add(queueMember.UserOrGroupId);
                
                
            }
            for(Id rrAssigneeId : rrAssignees.keySet()){
                RR_Assignee__mdt rrAssignee = rrAssignees.get(rrAssigneeId);
                if(rrQueue.Id == rrAssignee.RR_Queue__c){
                    rrQueueAssignees.get(rrQueue.QueueId__c).put(rrAssignee.Id, rrAssignee);
                }
            }
        }
        for(Id rrQueueId :rrQueues.keySet()){
            RR_Queue__mdt rrQueue = rrQueues.get(rrQueueId);
            for(Id rrAssigneeId : rrQueueAssignees.get(rrQueue.QueueId__c).keySet()){
                RR_Assignee__mdt rrAssignee = rrQueueAssignees.get(rrQueue.QueueId__c).get(rrAssigneeId);
                if(!userIdsPerQueue.get(rrQueue.QueueId__c).contains(rrAssignee.User__c)){
                    rrAssigneesToRemove.Add(rrAssignee);
                }
            }
        }
        if(rrAssigneesToRemove.size() > 0 && retrieveDeletionOnly){
            deleteRRAssignees(rrAssigneesToRemove, rrQueues);
        }
        if(rrAssigneesToAdd.size() > 0 && !retrieveDeletionOnly){
            updateRRAssignees(rrAssigneesToAdd, rrQueues);
        }
    }

    static Boolean isContractQueue(Map<Id, QueueSobject> targetObjects){
        return isQueueForObject('Contract__c', targetObjects);
    }

    public static Boolean isQueueForObject(String objectApiName, Map<Id, QueueSobject> targetObjects){
        Boolean result = false;
        for(Id queueObjId : targetObjects.keySet()){
            QueueSobject targetObject = targetObjects.get(queueObjId);
            if(targetObject.SobjectType == objectApiName){
                result = true;
                break;
            }
        }
        return result;
    }

    static RR_Queue__mdt findInRRQueue(Id queueId, Map<Id, RR_Queue__mdt> rrQueues){
        RR_Queue__mdt result = null;
        for(Id rrQueueId : rrQueues.keySet()){
            RR_Queue__mdt rrQueue = rrQueues.get(rrQueueId);
            if(rrQueue.QueueId__c == queueId){
                result = rrQueue;
                break;
            }
        }
        return result;
    }

    static RR_Assignee__mdt findInRRAssignee(Id rrQueueId, Id userId, Map<Id, RR_Assignee__mdt> rrAssignees){
        RR_Assignee__mdt result = null;
        for(Id rrAssigneeId : rrAssignees.keySet()){
            RR_Assignee__mdt rrAssignee = rrAssignees.get(rrAssigneeId);
            if(rrAssignee.RR_Queue__c == rrQueueId && rrAssignee.User__c == userId && rrAssignee.Is_Active__c){
                result = rrAssignee;
                break;
            }
        }
        return result;
    }

    public static void updateRRQueues(List<RR_Queue__mdt> rrQueuesToAdd) {
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        for(RR_Queue__mdt rrQueue : rrQueuesToAdd){
            Metadata.CustomMetadata customMetadata =  new Metadata.CustomMetadata();
            customMetadata.fullName = 'RR_Queue.' + rrQueue.Name__c;
            customMetadata.label = rrQueue.Name__c.replace('_', ' ');
    
            Metadata.CustomMetadataValue name = new Metadata.CustomMetadataValue();
            name.field = 'Name__c';
            name.value = rrQueue.Name__c;
            customMetadata.values.add(name);
            Metadata.CustomMetadataValue isActive = new Metadata.CustomMetadataValue();
            isActive.field = 'Is_Active__c';
            isActive.value = rrQueue.Is_Active__c;
            customMetadata.values.add(isActive);
            Metadata.CustomMetadataValue queueId = new Metadata.CustomMetadataValue();
            queueId.field = 'QueueId__c';
            queueId.value = rrQueue.QueueId__c;
            customMetadata.values.add(queueId);

            mdContainer.addMetadata(customMetadata);
        }
        AfterNewRRQueue updateAssignees = new AfterNewRRQueue();
        if(!Test.isRunningTest()){
            Metadata.Operations.enqueueDeployment(mdContainer, updateAssignees);
        }
    }

    public static void deleteRRAssignees(List<RR_Assignee__mdt> rrAssigneesToRemove, Map<Id, RR_Queue__mdt> rrQueues){
        for(RR_Assignee__mdt rrAssignee : rrAssigneesToRemove){
            fullNames.add('RR_Assignee.' + rrAssignee.RR_Queue__c + '_' + rrAssignee.Name__c.replace(' ', '_'));
        }
    }

    public static void updateRRAssignees(List<RR_Assignee__mdt> rrAssigneesToAdd, Map<Id, RR_Queue__mdt> rrQueues){
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        for(RR_Assignee__mdt rrAssignee : rrAssigneesToAdd){
            Metadata.CustomMetadata customMetadata =  new Metadata.CustomMetadata();
            customMetadata.fullName = 'RR_Assignee.' + rrAssignee.RR_Queue__c + '_' + rrAssignee.Name__c.replace(' ', '_');
            customMetadata.label = rrAssignee.Name__c;
    
            Metadata.CustomMetadataValue name = new Metadata.CustomMetadataValue();
            name.field = 'Name__c';
            name.value = rrAssignee.Name__c;
            customMetadata.values.add(name);
            Metadata.CustomMetadataValue userId = new Metadata.CustomMetadataValue();
            userId.field = 'User__c';
            userId.value = String.valueOf(rrAssignee.User__c);
            customMetadata.values.add(userId);
            
            Metadata.CustomMetadataValue lastAssigned = new Metadata.CustomMetadataValue();
            lastAssigned.field = 'Last_Assigned__c';
            lastAssigned.value = rrAssignee.Last_Assigned__c;
            customMetadata.values.add(lastAssigned);
            Metadata.CustomMetadataValue isActive = new Metadata.CustomMetadataValue();
            isActive.field = 'Is_Active__c';
            isActive.value = rrAssignee.Is_Active__c;
            customMetadata.values.add(isActive);
            Metadata.CustomMetadataValue rrQueueApiName = new Metadata.CustomMetadataValue();
            rrQueueApiName.field = 'RR_Queue__c';
            if(Test.isRunningTest()){
                rrQueueApiName.value = 'testApiName';
            }else{
                rrQueueApiName.value = rrQueues.get(rrAssignee.RR_Queue__c).Name__c;
            }
            customMetadata.values.add(rrQueueApiName);
            
            mdContainer.addMetadata(customMetadata);
        }
        StandardDeployCallback doNothing = new StandardDeployCallback();
        if(!Test.isRunningTest()){
            Metadata.Operations.enqueueDeployment(mdContainer, doNothing);
        }
    }
    
    public static void updateLastAssigned(Map<Id, RR_Assignee__mdt> rrAssignees){
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        for(RR_Assignee__mdt rrAssignee :rrAssignees.values()){
            Metadata.CustomMetadata customMetadata =  new Metadata.CustomMetadata();
            customMetadata.fullName = 'RR_Assignee.' + rrAssignee.RR_Queue__c + '_' + rrAssignee.Name__c.replace(' ', '_');
            customMetadata.label = rrAssignee.Name__c;
    
            Metadata.CustomMetadataValue lastAssigned = new Metadata.CustomMetadataValue();
            lastAssigned.field = 'Last_Assigned__c';
            lastAssigned.value = rrAssignee.Last_Assigned__c;
            customMetadata.values.add(lastAssigned);
            
            mdContainer.addMetadata(customMetadata);
        }
        StandardDeployCallback doNothing = new StandardDeployCallback();
        if(!Test.isRunningTest()){
            Metadata.Operations.enqueueDeployment(mdContainer, doNothing);
        }
    }

    public class StandardDeployCallback implements Metadata.DeployCallback {
        public void handleResult(Metadata.DeployResult result,
                                 Metadata.DeployCallbackContext context) {
            
        }
    }
    public class AfterNewRRQueue implements Metadata.DeployCallback {
        public void handleResult(Metadata.DeployResult result,
                                 Metadata.DeployCallbackContext context) {
            Id jobId = context.getCallbackJobId();
    
            
            switch on (result.status) {
                when Succeeded {
                    synchronizeRRQueues(false, false);
                }
                
            }
        }
    }
}