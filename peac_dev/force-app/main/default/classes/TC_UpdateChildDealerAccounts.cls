/**
 * @author Northteq Consulting, Inc. 
 * @date: 3/29/21
 * @description: Refactored for SAL-2852
 * 
 * */

public with sharing class TC_UpdateChildDealerAccounts{

    /*public void doAction(TC_TriggerContext tc) {

        //if (TC_RecursiveTriggerHelper.updateChildAccountsOfDealer) return;
        //TC_RecursiveTriggerHelper.updateChildAccountsOfDealer = true;

        Map <Id, Account> newMap = (Map <Id, Account>) tc.getNewMap();
        Map <Id, Account> oldMap = (Map <Id, Account>) tc.getOldMap();
        Boolean isAfter = tc.isAfter();
        Boolean isInsert = tc.isInsert();
        Boolean isUpdate = tc.isUpdate();

        categorize(newMap, oldMap, isAfter, isInsert, isUpdate);
    }*/

    public static void categorize(Map<Id, Account> newMap, Map<Id, Account> oldMap, Boolean isAfter, Boolean isInsert, Boolean isUpdate) {

        if (!isAfter && TC_RecursiveTriggerHelper.updateChildAccountsOfDealerBefore) return;
        if(!isAfter) TC_RecursiveTriggerHelper.updateChildAccountsOfDealerBefore = true;
        if(isAfter && TC_RecursiveTriggerHelper.updateChildAccountsOfDealerAfter) return;
        if(isAfter) TC_RecursiveTriggerHelper.updateChildAccountsOfDealerAfter = true;

        Map<Id, Account> parentMap = new Map<Id, Account>();
        Map<Id, Account> childMap = new Map<Id, Account>();

        String roleName = getUserRoleName();

        if (roleName <> null) {
            if (newMap <> null) {
                for (Account acc : newMap.values()) {
                    if (acc.Is_Dealer__c) {
                        if (acc.ParentId == null) {
                            if (oldMap <> null) {
                                if (oldMap.get(acc.Id).ParentId <> null) {
                                    childMap.put(acc.Id, acc);
                                } else {
                                    parentMap.put(acc.Id, acc);
                                }
                            } else {
                                parentMap.put(acc.Id, acc);
                            }
                        } else {
                            childMap.put(acc.Id, acc);
                        }
                    }
                }
            }

         /*   if (parentMap.size() > 0 && isAfter && isUpdate) {
                handleParents(oldMap, parentMap, roleName);
            } */ 

            if (!isAfter && (isInsert || isUpdate)) {
                handleChildren(oldMap, newMap, childMap, roleName);
            }
        }
    }

    public static void handleParents(Map<Id, Account> oldMap, Map<Id, Account> parentMap, String roleName) {

        Boolean isRep = isRepRole(roleName);
        Boolean isManager = isManagerRole(roleName);

        Map<Id, Account> updatedAccounts = new Map<Id, Account>();

        Set<Id> parentAccountKeySet = parentMap.keySet();

        Map<Id, Dealer_Child_Account_Field__mdt> dealerChildAccountFieldMap = queryFieldsFromMetadata();
        List<String> fieldNames = createListFromFieldNames(dealerChildAccountFieldMap);

        Map<Id, List<Account>> parentToChildMap = new Map<Id, List<Account>>();
        for (Account child : Database.query('SELECT Id, ParentId, ' + String.join(fieldNames, ',') + ' FROM Account WHERE ParentId IN :parentAccountKeySet AND Is_Dealer__c = TRUE')) {
            if (parentToChildMap.get(child.ParentId) == null) {
                parentToChildMap.put(child.ParentId, new List<Account>{child});
            } else {
                parentToChildMap.get(child.ParentId).add(child);
            }
        }

        for (Account parent : parentMap.values()) {
            for (Dealer_Child_Account_Field__mdt field : dealerChildAccountFieldMap.values()) {
                if (parent.get(field.Field_API_Name__c) <> oldMap.get(parent.Id).get(field.Field_API_Name__c) && isRep &&
                        parentToChildMap.get(parent.Id) <> null && parentToChildMap.get(parent.Id).size() > 0) {
                    parent.addError('Reps cannot edit ' + field.Field_API_Name__c + ' on parent dealer accounts!');
                }
            }
            try{
                if (parentToChildMap.size() > 0) {
                    for (Account child : parentToChildMap.get(parent.Id)) {
                        for (Dealer_Child_Account_Field__mdt field : dealerChildAccountFieldMap.values()) {
                            if (parent.get(field.Field_API_Name__c) <> oldMap.get(parent.Id).get(field.Field_API_Name__c)) {
                                child.put(field.Field_API_Name__c, parent.get(field.Field_API_Name__c));
                            }
                        }
                        updatedAccounts.put(child.Id, child);
                    }
                }
            } catch (Exception e) {
                System.debug(e);
            }
        }

        if (updatedAccounts.size() > 0) {
            if (!System.isQueueable()) {
                TC_RecursiveTriggerHelper.updateChildAccountsOfDealerAfter = true;
                List<TC_Update_Child_Dealer_Accounts__e> events = new List<TC_Update_Child_Dealer_Accounts__e>();
                for (Account acc : parentMap.values()) {
                    events.add(new TC_Update_Child_Dealer_Accounts__e(Record_Id__c = acc.Id));
                }
                EventBus.publish(events);
            }
        }
    }

    public static void handleChildrenAction(List<TC_Update_Child_Dealer_Accounts__e> events) {

        for (TC_Update_Child_Dealer_Accounts__e event : events) {
            System.enqueueJob(new TC_UpdateChildDealerAccountsQueueable(event.Record_Id__c, null));
        }
    }

    public static void handleChildren(Map<Id, Account> oldMap, Map<Id, Account> newMap, Map<Id, Account> childMap, String roleName) {

        Boolean isRep = isRepRole(roleName);
        Boolean isManager = isManagerRole(roleName);

        Set<Id> parentAccountKeySet = new Set<Id>();
        for (Account child : childMap.values()) {
            parentAccountKeySet.add(child.ParentId);
        }

        Map<Id, Dealer_Child_Account_Field__mdt> dealerChildAccountFieldMap = queryFieldsFromMetadata();
        List<String> fieldNames = createListFromFieldNames(dealerChildAccountFieldMap);

        Map<Id, Account> parents = new Map<Id, Account>((List<Account>) Database.query('SELECT Id, ' + String.join(fieldNames, ',') + ' FROM Account WHERE Id IN :parentAccountKeySet AND Is_Dealer__c = TRUE'));

        for (Account child : childMap.values()) {
            if (oldMap == null) {
                for (Dealer_Child_Account_Field__mdt field : dealerChildAccountFieldMap.values()) {
                    child.put(field.Field_API_Name__c, parents.get(child.ParentId).get(field.Field_API_Name__c));
                }
            } else if (child.ParentId == null && child.ParentId <> oldMap.get(child.Id).ParentId) {
                for (Dealer_Child_Account_Field__mdt field : dealerChildAccountFieldMap.values()) {
                    if (Schema.SObjectType.Account.fields.getMap().get(field.Field_API_Name__c).getDescribe().getType().name() == 'BOOLEAN') {
                        child.put(field.Field_API_Name__c, false);
                    } else {
                        child.put(field.Field_API_Name__c, null);
                    }
                }
            } else {
                for (Dealer_Child_Account_Field__mdt field : dealerChildAccountFieldMap.values()) {
                    try {
                        if (child.get(field.Field_API_Name__c) <> parents.get(child.ParentId).get(field.Field_API_Name__c)) {
                            if (child.ParentId <> oldMap.get(child.Id).ParentId) {
                                child.put(field.Field_API_Name__c, parents.get(child.ParentId).get(field.Field_API_Name__c));
                            } else if (newMap.get(child.Id).get(field.Field_API_Name__c) <> oldMap.get(child.Id).get(field.Field_API_Name__c)) {
                                if (isRep || isManager) {
                                    child.addError('Managers and reps cannot edit restricted parent account fields on child dealer accounts!');
                                }
                            }
                        }
                    } catch (Exception e) {}
                }
            }
        }

        if (System.isQueueable()) {

            List<Dealer_Surveillance__c> surv = [
                SELECT Id, Account__c, Status__c, Waiting_To_Be_Sent_To_Bridgeware__c 
                FROM Dealer_Surveillance__c 
                WHERE Account__c IN :childMap.keySet() 
                AND Status__c = 'Completed' 
                AND Waiting_To_Be_Sent_To_Bridgeware__c = false
            ];

            for (Dealer_Surveillance__c s : surv) {
                s.Waiting_To_Be_Sent_To_Bridgeware__c = true;
            }

            if (surv.size() > 0) {
                Database.SaveResult[] results = Database.update(surv);
                for (Database.SaveResult result : results) {
                    if (!result.isSuccess()) {
                        System.debug('dealer surveillance update error: ' + result.getErrors());
                    }
                }
            }

            update childMap.values();
        }
    }

    public static String getUserRoleName() {

        Id roleId = UserInfo.getUserRoleId();
        String roleName;
        if (roleId <> null) {
            roleName = [SELECT Id, Name FROM UserRole WHERE Id = :roleId].Name;
        }

        return roleName;
    }

    public static Boolean isRepRole (String roleName) {

        return roleName?.containsIgnoreCase('rep');
    }

    public static Boolean isManagerRole (String roleName) {

        return roleName?.containsIgnoreCase('manager');
    }

    public static Map <Id, Dealer_Child_Account_Field__mdt> queryFieldsFromMetadata() {

        Map<Id, Dealer_Child_Account_Field__mdt> dealerChildAccountFieldMap = new Map<Id, Dealer_Child_Account_Field__mdt>([SELECT Id, DeveloperName, Field_API_Name__c FROM Dealer_Child_Account_Field__mdt]);

        return dealerChildAccountFieldMap;
    }

    public static List<String> createListFromFieldNames(Map<Id, Dealer_Child_Account_Field__mdt> dealerChildAccountFieldMap) {

        List<String> fieldNames = new List<String>();

        for (Dealer_Child_Account_Field__mdt accountField : dealerChildAccountFieldMap.values()) {
            fieldNames.add(accountField.Field_API_Name__c);
        }

        return fieldNames;
    }
}