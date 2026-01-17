public interface SL_Trigger_ITriggerHandler {
    /**
    * @date 11/9/2014
    * @description Optional. Called by the trigger framework to carry out bulk actions (ex, getting describe info, querying recordtypes) prior to before triggers.
    */
    void bulkBefore();

    /**
    * @date 11/9/2014
    * @description Optional. Called by the trigger framework to carry out bulk actions (ex, getting describe info, querying recordtypes) prior to after triggers.
    */
    void bulkAfter();

    /**
    * @date 3/1/2018
    * @description dml handler methods. NOTE: only implement the methods for DML operations the trigger actually runs on.
    */
    void beforeInsert(List<SObject> newList);
    void afterInsert(Map<Id, SObject> newMap);
    void beforeUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap);
    void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap);
    void beforeDelete(Map<Id, SObject> oldMap);
    void afterDelete(Map<Id, SObject> oldMap);
    void afterUndelete(Map<Id, SObject> newMap);

    /**
    * @date 3/1/2018
    * @description Optional. Allows you to define custom handlers if the DML operation is being run recursively. e.g. To avoid running Account.beforeUpdate multiple times.
    */
    void beforeInsertRecursive(List<SObject> newList);
    void afterInsertRecursive(Map<Id, SObject> newMap);
    void beforeUpdateRecursive(Map<Id, SObject> oldMap, Map<Id, SObject> newMap);
    void afterUpdateRecursive(Map<Id, SObject> oldMap, Map<Id, SObject> newMap);
    void beforeDeleteRecursive(Map<Id, SObject> oldMap);
    void afterDeleteRecursive(Map<Id, SObject> oldMap);
    void afterUndeleteRecursive(Map<Id, SObject> newMap);

    void execute(SL_Trigger.Parameters tp, String context);
}