public with sharing class SL_LogACall {

    @AuraEnabled
    public static List<Contract_Contact_Role__c> fetchCCRRecords(String ContractId){
        try {
            List<Contract_Contact_Role__c> l_Types = new List<Contract_Contact_Role__c>();
             
            l_Types = [Select id, Name, Contact__c, Contact__r.Name from Contract_Contact_Role__c where Contract__C =:ContractId And Contact__c != null]; 
            return l_Types;
        } catch (Exception e) {
            System.debug('Exception: '+e.getMessage());
            return null;
        }
    }

    @AuraEnabled
    public static Contract_Contact_Role__c populateNewCreatedCCR(String recordId){
        try {
            return [Select id, Name, Contact__c, Contact__r.Name from Contract_Contact_Role__c where Contract__C =:recordId And Contact__c != null order by LastModifiedDate desc Limit 1]; 
            
        } catch (Exception e) {
            System.debug('Exception: '+e.getMessage());
            return null;
        }
    }
    
    @AuraEnabled
    public static Contract_Contact_Role__c createContactRecord(Contract_Contact_Role__c newRecord){
        try {
            insert newRecord;
            return newRecord;
            
        } catch (Exception e) {
            System.debug('Exception: '+e.getMessage());
            return null;
        }
    }

    @AuraEnabled
    public static string hubExecute(String methodName, List<String> methodParameters){
        try {
            String result = '';
            switch on methodName {
                when 'loadEmulatedTask'{
                    result = loadEmulatedTask(methodParameters[0]);
                }
                when 'calculateFollowup'{
                    result = calculateFollowup(methodParameters[0], methodParameters[1]);
                }
                when 'validateBusinessDay'{
                    result = validateBusinessDay(methodParameters[0]);
                }
                when 'saveTask'{
                    result = saveTask(methodParameters[0], methodParameters[1], methodParameters[2],
                        methodParameters[3], methodParameters[4], methodParameters[5],
                        methodParameters[6], methodParameters[7]);
                }
            }
            return result;
        } catch (Exception e) {
            system.debug('exception::'+e.getMessage()+'--'+e.getLineNumber()+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @testVisible
    static String loadEmulatedTask(String fieldList){
        List<String> fields = fieldList.split(',');
        String result = '';
        Map<String, List<OptionWrapper>> optionsByField = new Map<String, List<OptionWrapper>>();
        Map<String, Map<String, List<String>>> dependencies = new Map<String, Map<String, List<String>>>();
        Set<String> controllingFields = new Set<String>();
        Set<String> dependentFields = new Set<String>();
        Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get('Task').getDescribe().Fields.getMap();
        if (fMap != null){
            for(String fieldApi : fields){
                //system.debug(fieldApi+' :' + fMap.get(fieldApi));
                Schema.SObjectField dependentField = fMap.get(fieldApi);
                if(dependentField.getDescribe().getType() == Schema.DisplayType.PICKLIST
                    || dependentField.getDescribe().getType() == Schema.DisplayType.MULTIPICKLIST){
                    Schema.sObjectField controllerField = dependentField.getDescribe().getController();
                    if(controllerField != null){
                        Map<String, List<String>> valuesMatrix = getDependentPicklistValues(dependentField);
                        dependencies.put(controllerField.getDescribe().getName() + '_' + dependentField.getDescribe().getName(), valuesMatrix);
                        controllingFields.add(controllerField.getDescribe().getName());
                        dependentFields.add(fieldApi);
                    }
                    List<OptionWrapper> picklistOptions = new List<OptionWrapper>();
                    for(Schema.PicklistEntry entry : dependentField.getDescribe().getPicklistValues()){
                        picklistOptions.add(new OptionWrapper(entry.getLabel(), entry.getValue()));
                    }
                    optionsByField.put(fieldApi, picklistOptions);
                }
            }
            result = '{"dependencies": ' + JSON.serialize(dependencies, true)
                + ', "optionsByField": ' + JSON.serialize(optionsByField, true)
                + ', "controllingFields": ' + JSON.serialize(controllingFields, true)
                + ', "dependentFields": ' + JSON.serialize(dependentFields, true) + '}';
        }

        return result;
    }
    @testVisible
    static String calculateFollowup(String department, String callOutcome){
        SL_MessageCodeHelper msgCodeHelperCls = new SL_MessageCodeHelper();
        String result = '';
        List<String> managerRoles = new List<String>{
            'Collections Manager',
            'Collections Supervisor',
            'Customer Service Management',
            'System Admin',
            'VP of Collections'
        };
        Date nextFollowupDate = null;
        nextFollowupDate = msgCodeHelperCls.handleMessageCodes(department, callOutcome);
        if(nextFollowupDate != null){
            result = '{"followupDate": ' + JSON.serialize(nextFollowupDate);
            List<UserRole> currentRole = [SELECT Id, Name FROM UserRole WHERE Id = :System.UserInfo.getUserRoleId()];
            Date maxFollowup = null;
            Date minFollowup = null;
            if(currentRole.size() == 1 && !managerRoles.contains(currentRole[0].Name)){
                maxFollowup = msgCodeHelperCls.addBussinessDays(nextFollowupDate, 14);
                minFollowup = msgCodeHelperCls.addBussinessDays(nextFollowupDate, -14);
            }
            result += ', "maxFollowup": ' + JSON.serialize(maxFollowup)
                    + ', "minFollowup": ' + JSON.serialize(minFollowup)
                    + '}';
        }else{
            result = '{"followupDate": null, "maxFollowup": null, "minFollowup": null}';
        }
       // system.debug(result);
        return result;
    }

    @testVisible
    static String validateBusinessDay(String dateString){
        SL_MessageCodeHelper msgCodeHelperCls = new SL_MessageCodeHelper();
        Date selectedDate = Date.valueOf(dateString);
        String result = '{"isValid": '
            + JSON.serialize(msgCodeHelperCls.isWorkingDay(DateTime.newInstanceGMT(selectedDate.year(), selectedDate.month(), selectedDate.day(), 11, 59, 59))) + '}';
        return result;
    }
    
    @testVisible
    static String saveTask(String recordId, String department, String activity, String primaryCallOutcome, String secondaryOutcome,
            String followupDate, String taskDescription, String taskContact){
        Contract__c contract = [SELECT Id, Customer__c FROM Contract__c WHERE Id = :recordId];
        Id serviceRecordTypeId = [SELECT Id, Name, DeveloperName, IsActive  FROM RecordType Where isActive = true AND SobjectType = 'Task' AND DeveloperName = 'Service_Activity' LIMIT 1].Id;
        Date convertedFollowup = followupDate != null? Date.valueOf(followupDate): null;// SL-1832 Misael Romero
        Task newTask = new Task(Subject = 'Call',
            WhatId = contract.Customer__c,
            Contract__c = contract.Id,
            RecordTypeId = serviceRecordTypeId,
            Status = 'Completed',
            Activity_Type__c = 'Outbound',
            isContractCallFollowup__c = true,
            Department__c = department,
            Activity__c = activity,
            Primary_Call_Outcome__c = primaryCallOutcome,
            Secondary__c = secondaryOutcome,
            Followup_Date__c = convertedFollowup,
            Description = taskDescription);
                if(taskContact != '' && taskContact != null){
                    newTask.Contact__c = taskContact; 
                }
        insert newTask;
        return 'success';
    }
    public static  Map<String, List<String>> getDependentPicklistValues(Schema.sObjectField dependToken) {
        Schema.DescribeFieldResult depend = dependToken.getDescribe();
        Schema.sObjectField controlToken = depend.getController();
        if (controlToken == null) {
            return new Map<String, List<String>>();
        }
     
        Schema.DescribeFieldResult control = controlToken.getDescribe();
        List<Schema.PicklistEntry> controlEntries;
        if(control.getType() != Schema.DisplayType.Boolean) {
            controlEntries = control.getPicklistValues();
        }
     
        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        Map<String,List<String>> dependentPicklistValues = new Map<String,List<String>>();
        for (Schema.PicklistEntry entry : depend.getPicklistValues()) {
            if (entry.isActive() && String.isNotEmpty(String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')))) {
                List<String> base64chars =
                        String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')).split('');
                for (Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++) {
                    Object controlValue =
                            (controlEntries == null
                                    ?   (Object) (index == 1)
                                    :   (Object) (controlEntries[index].isActive() ? controlEntries[index].getValue() : null)
                            );
                    Integer bitIndex = index / 6;
                    if (bitIndex > base64chars.size() - 1) {
                        break;
                    }
                    Integer bitShift = 5 - Math.mod(index, 6);
                    if  (controlValue == null || (base64map.indexOf( base64chars[ bitIndex ] ) & (1 << bitShift)) == 0)
                        continue;
                    if (!dependentPicklistValues.containsKey((String) controlValue)) {
                        dependentPicklistValues.put((String) controlValue, new List<String>());
                    }
                    dependentPicklistValues.get((String) controlValue).add(entry.getValue());
                }
            }
        }
        return dependentPicklistValues;
    }

    class OptionWrapper{
        String label;
        String value;

        public OptionWrapper(String label, String value){
            this.label = label;
            this.value = value;
        }
    }
}