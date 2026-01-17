public without sharing class SL_QueueAdmin {
    @AuraEnabled
    public static string hubExecute(String methodName, List<String> methodParameters){
        try {
            String result = '';
            switch on methodName {
                when 'getRole'{
                    result = getRole();
                }
                when 'getGroupMembers'{
                    result = getGroupMembers(methodParameters[0]);
                }
                when 'saveGroupMembers'{
                    result = saveGroupMembers(methodParameters[0], methodParameters[1], methodParameters[2]);
                }
                when 'addRRAssignees'{
                    result = addRRAssignees();
                }
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @testVisible
    static String getRole(){
        List<UserRole> roles = [SELECT Id, Name FROM UserRole WHERE Id = :System.UserInfo.getUserRoleId()];
        String result = '';
        Boolean isCustomerService = roles.size() > 0 && (roles[0].Name.toLowerCase().contains('customer service') || roles[0].Name == 'Insurance Management');
        if(roles.size() > 0){
            if(isCustomerService){
                result = '{"roleName": "Customer Service"';
            }
            if(roles[0].Name.toLowerCase().contains('collections')){
                result = '{"roleName": "Collections"';
            }
        } 
        if(result.length() == 0){
            result = '{"error": "User ' + System.UserInfo.getName() + ' doesn\'t have a valid Role"}';
        }else{
            List<Group> queues = new List<Group>();
            String objectApiName = isCustomerService? 'Case': 'Contract__c';
            Map<Id, Group> groupQueues =  new Map<Id, Group>();
            groupQueues.putAll([SELECT Id, Name, DeveloperName, relatedId, type FROM Group WHERE Type='Queue']);
            List<QueueSobject> allTargetObjects = [SELECT Id, QueueId, SobjectType FROM QueueSobject WHERE QueueId IN :groupQueues.keySet()];
            for(Id queueId :groupQueues.keySet()){
                for(QueueSobject target : allTargetObjects){
                    if(target.QueueId == queueId && target.SobjectType == objectApiName){
                        queues.add(groupQueues.get(queueId));
                        break;
                    }
                }
            }
            List<User> allUsers = [SELECT id, Username, Name FROM User WHERE isActive = TRUE ORDER BY Name];
            result = result + ', "queues": ' + JSON.serialize(queues) + ', "allUsers": ' + JSON.serialize(allUsers) + '}';
        }
        return result;
    }
    @testVisible
    static String getGroupMembers(String queueId){
        Set<Id> ids = new Set<Id>();
        List<GroupMember> groupMembers = [SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId = :queueId];
        for(GroupMember member : groupMembers){
            ids.add(member.UserOrGroupId);
        }
        List<User> selectedUsers = [SELECT Id, Name FROM User WHERE Id IN : ids];
        
        return '{"members": ' + JSON.serialize(selectedUsers, true) + '}';
    }
    @testVisible
    static String saveGroupMembers(String queueId, String memberList, String objectApiName){
        List<String> userIds = new List<String>();
        if(memberList.length() > 0){
            userIds = memberList.split(',');
        }
        List<GroupMember> toInsert = new List<GroupMember>();
        List<GroupMember> toDelete = new List<GroupMember>();
        List<GroupMember> oldGroupMembers = [SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId = :queueId];
        List<String> existingUserIds = new List<String>();
        for(GroupMember member : oldGroupMembers){
            if(!userIds.contains(String.valueOf(member.UserOrGroupId))){
                toDelete.add(member);
            }
            existingUserIds.add(String.valueOf(member.UserOrGroupId));
        }

        for(String userId : userIds){
            if(!existingUserIds.contains(userId)){
                GroupMember newMember = new GroupMember(GroupId = queueId, UserOrGroupId = userId);
                toInsert.add(newMember);
            }
        }
        insert toInsert;
        delete toDelete;
        String result = '{"success": true';
        if(objectApiName == 'Contract__c'){
            List<String> fullNamesToDelete = SL_RRManageMDT.synchronizeRRAssignees();
            if(fullNamesToDelete.size() > 0){
                result = result + ', "fullNames": ' + JSON.serialize(fullNamesToDelete);
            }
        }
        result = result + '}';
        return result;
    }
    @testVisible
    static String addRRAssignees(){
        SL_RRManageMDT.synchronizeRRQueues(false, false);
        return 'success';
    }
}