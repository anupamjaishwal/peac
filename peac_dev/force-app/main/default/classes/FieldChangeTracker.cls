public with sharing class FieldChangeTracker {

    public static void trackDetails(TrackerWrapper trackObj) {
        if (!shouldTrackUser(trackObj)) return;
        if (!isValidInput(trackObj)) return;

        FieldTrackingForLoan__mdt config = getTrackingConfig(trackObj.objectApiName);
        if (config == null) return;

        Map<String, Schema.SObjectField> fieldDescMap = getFieldDescribeMap(trackObj.objectApiName);
        List<String> fieldList = getFieldNames(config);

        List<Field_Tracker__c> auditRecords = new List<Field_Tracker__c>();
        Set<String> oppIdSet = new Set<String>();

        // Determine if this is a record creation (oldRecordMap is null)
        Boolean isNewRecord = trackObj.oldRecordMap == null;

        for (Id recordId : trackObj.newRecordMap.keySet()) {
            SObject newRec = trackObj.newRecordMap.get(recordId);
            SObject oldRec = trackObj.oldRecordMap != null ? trackObj.oldRecordMap.get(recordId) : null;
            
            for (String fieldApi : fieldList) {
                // For new records, we only track if a value was explicitly provided AND it's not null.
                // For updates, we check if the field has changed from its previous value.
                if (isNewRecord) {
                    if (newRec.get(fieldApi) != null) {
                        // For new records, we consider a non-null value for a tracked field as a "change" for scoring purposes
                        // (unless you have a different definition for "Scored Field Modified" during creation).
                        // If you only want to track changes *after* creation, you would add more conditions here
                        // to ensure the field wasn't just auto-populated or didn't have a default value.
                        String label = getFieldLabel(fieldDescMap, fieldApi);
                        if (Boolean.valueOf(config.Junction_Object__c) || Boolean.valueOf(config.If_Parent__c)) {
                            oppIdSet.addAll(processJunctionTracking(trackObj, recordId, fieldApi, label, oldRec, newRec, config, auditRecords));
                        } else {
                            String oppId = getDirectOppId(newRec, config, recordId);
                            auditRecords.add(createAuditRecord(trackObj.objectApiName, oppId, recordId, fieldApi, label, oldRec, newRec));
                            oppIdSet.add(oppId);
                        }
                    }
                } else { // This is an update
                    if (hasFieldChanged(oldRec, newRec, fieldApi)) {
                        String label = getFieldLabel(fieldDescMap, fieldApi);

                        if (Boolean.valueOf(config.Junction_Object__c) || Boolean.valueOf(config.If_Parent__c)) {
                            oppIdSet.addAll(processJunctionTracking(trackObj, recordId, fieldApi, label, oldRec, newRec, config, auditRecords));
                        } else {
                            String oppId = getDirectOppId(newRec, config, recordId);
                            auditRecords.add(createAuditRecord(trackObj.objectApiName, oppId, recordId, fieldApi, label, oldRec, newRec));
                        oppIdSet.add(oppId);
                    }
                }
            }
        }
        }

        if (!auditRecords.isEmpty()) {
            Database.insert(auditRecords, false);
        }

        // Only set Scored_Field_Modified__c to true if changes were explicitly tracked, 
        // which means the auditRecords list will be populated.
        if (!oppIdSet.isEmpty()) {
            updateScoreFieldFlag(oppIdSet, true);
        }
    }

    public static void removeTrackedChanges(List<String> opportunityIds) {
        try {
            delete [SELECT Id FROM Field_Tracker__c WHERE Opportunity__c IN :opportunityIds LIMIT 10000];
            updateScoreFieldFlag(new Set<String>(opportunityIds), false);
        } catch(Exception ex) {
            System.debug('removeTrackedChanges::'+ex.getMessage());
        }
    }
    
    public static void updateScoreFieldFlag(Set<String> oppIds, Boolean value) {
        try {
            System.debug('updateScoreFieldFlag::calling');
            List<Opportunity> oppList = new List<Opportunity>();
            for (Opportunity opp : [select Id from Opportunity where StageName != 'Quote' AND Id IN :oppIds]) {
                opp.Scored_Field_Modified__c = value;
                oppList.add(opp);
            }
            if (!oppList.isEmpty()) update oppList;
        } catch (Exception ex) {
            System.debug('updateScoreFieldFlag::' + ex.getMessage());
        }
    }

    public static void trackCreateAndDeleteForChilds(Map<Id, SObject> recordMap, String objectName, String actionType) {
        try {
            FieldTrackingForLoan__mdt config = getTrackingConfig(objectName);
            if (config == null) return;

            List<Field_Tracker__c> auditRecords = new List<Field_Tracker__c>();
            Set<String> oppIds = new Set<String>();

            for (Id recordId : recordMap.keySet()) {
                SObject rec = recordMap.get(recordId);
                String oppId = String.valueOf(rec.get(config.ChildObject_RelationshipName__c));

                auditRecords.add(new Field_Tracker__c(
                    Object_Name__c = objectName,
                    Opportunity__c = oppId,
                    Action__c =  actionType,
                    Field_Label__c = 'Id',
                    Field_Name__c = 'Id',
                    New_Value__c = recordId                    
                ));

                oppIds.add(oppId);
            }

            if (!auditRecords.isEmpty()) Database.insert(auditRecords, false);
            if (!oppIds.isEmpty()) updateScoreFieldFlag(oppIds, true);
        } catch (Exception ex) {
            System.debug('trackCreateAndDeleteForChilds::' + ex.getMessage());
        }
    }

    // ----- Helpers -----

    private static Boolean shouldTrackUser(TrackerWrapper trackObj) {
        // SAL-5468 Misael Romero
        // User u = [SELECT Name, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
        List<ExcludeUsersFromFieldTracking__c> exclusionList = new List<ExcludeUsersFromFieldTracking__c>();
        System.debug('TC_RecursiveTriggerHelper.isToTrackUser: ' + TC_RecursiveTriggerHelper.isToTrackUser);
        if(TC_RecursiveTriggerHelper.isToTrackUser){
            String firstName = System.UserInfo.GetFirstName();
            String userFullName = firstName + (!String.isBlank(firstName)? ' ': '') + System.UserInfo.GetLastName();
            SObject oneRecord = trackObj.newRecordMap.values().size() > 0? trackObj.newRecordMap.values()[0]: null;
            String profileName = trackObj.objectApiName == 'Account'? ((Account)oneRecord).Account_CurrentUser_Profile__c:
                trackObj.objectApiName == 'Opportunity'? ((Opportunity)oneRecord).Opportunity_CurrentUser_Profile__c: 
                [SELECT Name, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
            exclusionList = [
            SELECT Name FROM ExcludeUsersFromFieldTracking__c
                WHERE (Type__c = 'User' AND Name = :userFullName)
                OR (Type__c = 'Profile' AND Name = :profileName)
        ];
            TC_RecursiveTriggerHelper.isToTrackUser = exclusionList.isEmpty();
        }
        
        return exclusionList.isEmpty();
    }

    private static Boolean isValidInput(TrackerWrapper trackObj) {
        return trackObj != null &&
               !String.isBlank(trackObj.objectApiName) &&
               trackObj.newRecordMap != null &&
               !trackObj.newRecordMap.isEmpty();
    }

    private static FieldTrackingForLoan__mdt getTrackingConfig(String objectApiName) {
        // SAL-5468 Misael Romero
        // List<FieldTrackingForLoan__mdt> configs = [
        //     SELECT Object_Name__c, FieldNames__c, Is_ChildObject__c, Junction_Object__c, 
        //            ChildObject_RelationshipName__c, If_Parent__c
        //     FROM FieldTrackingForLoan__mdt
        //     WHERE Object_Name__c = :objectApiName
        //     LIMIT 1
        // ];
        FieldTrackingForLoan__mdt configForObject = null;
        for(FieldTrackingForLoan__mdt config :FieldTrackingForLoan__mdt.getAll().values()){
            if(config.Object_Name__c == objectApiName){
                configForObject = config;
            }
        }
        return configForObject;
    }

    /*private static List<String> getFieldNames(FieldTrackingForLoan__mdt config){// SAL-5468 Misael Romero
        String fieldNames = config.FieldNames__c;
        if(fieldNames.length() == 255){
            fieldNames = [SELECT FieldNames__c 
                FROM FieldTrackingForLoan__mdt WHERE DeveloperName = :config.DeveloperName].FieldNames__c;
        }
        return fieldNames.split(';');
    }*/
    
    private static List<String> getFieldNames(FieldTrackingForLoan__mdt config) {
        if (config == null || String.isBlank(config.FieldNames__c)) {
            return new List<String>();
        }
        
        String fieldNames = config.FieldNames__c;
        if (fieldNames != null && fieldNames.length() == 255) {
            fieldNames = [
                SELECT FieldNames__c 
                FROM FieldTrackingForLoan__mdt 
                WHERE DeveloperName = :config.DeveloperName
                LIMIT 1
            ].FieldNames__c;
        }
        return String.isBlank(fieldNames) ? new List<String>() : fieldNames.split(';');
    }
    

    private static Map<String, Schema.SObjectField> getFieldDescribeMap(String objectApiName) {
        return Schema.getGlobalDescribe()
                     .get(objectApiName)
                     .getDescribe()
                     .fields.getMap();
    }

    private static Boolean hasFieldChanged(SObject oldRec, SObject newRec, String fieldApi) {
        Object oldVal = oldRec != null ? oldRec.get(fieldApi) : null;
        Object newVal = newRec.get(fieldApi);
        return (oldVal == null && newVal != null) ||
               (oldVal != null && newVal == null) ||
               (oldVal != null && !oldVal.equals(newVal));
    }

    private static String getFieldLabel(Map<String, Schema.SObjectField> fieldDescMap, String fieldApi) {
        return fieldDescMap.containsKey(fieldApi)
            ? fieldDescMap.get(fieldApi).getDescribe().getLabel()
            : fieldApi;
    }

    private static List<String> processJunctionTracking(
        TrackerWrapper trackObj,
        Id recordId,
        String fieldApi,
        String label,
        SObject oldRec,
        SObject newRec,
        FieldTrackingForLoan__mdt config,
        List<Field_Tracker__c> auditRecords
    ) {
        List<String> oppIds = new List<String>();
        if (trackObj.recordIdWithOppIdsMap == null || !trackObj.recordIdWithOppIdsMap.containsKey(recordId)) {
            System.debug('Missing opportunity mapping for recordId: ' + recordId);
            return oppIds;
        }

        for (String oppId : trackObj.recordIdWithOppIdsMap.get(recordId)) {
            auditRecords.add(createAuditRecord(config.Object_Name__c, oppId, recordId, fieldApi, label, oldRec, newRec));
            oppIds.add(oppId);
        }
        return oppIds;
    }

    private static String getDirectOppId(SObject record, FieldTrackingForLoan__mdt config, Id fallbackId) {
        return Boolean.valueOf(config.Is_ChildObject__c)
            ? String.valueOf(record.get(config.ChildObject_RelationshipName__c))
            : String.valueOf(fallbackId);
    }

    private static Field_Tracker__c createAuditRecord(
        String objectName,
        String oppId,
        Id recordId,
        String fieldApi,
        String label,
        SObject oldRec,
        SObject newRec
    ) {
        return new Field_Tracker__c(
            Object_Name__c = objectName,
            Opportunity__c = oppId,
            Record_Id__c = recordId,
            Field_Label__c = label,
            Field_Name__c = fieldApi,
            Action__c = 'Modified',
            Old_Value__c = String.valueOf(oldRec != null ? oldRec.get(fieldApi) : null),
            New_Value__c = String.valueOf(newRec.get(fieldApi))
        );
    }

    // Wrapper input class
    public class TrackerWrapper {
        public String objectApiName;
        public Map<Id,Set<Id>> recordIdWithOppIdsMap;
        public Map<Id, SObject> oldRecordMap;
        public Map<Id, SObject> newRecordMap;
    }
}