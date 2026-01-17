/**************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This is a PEAC_PoolTriggerHandler class to support 
            PEAC_PoolTrigger
@User Story:DP-1090	 
@Created Date:July-22-2024   
**************************************************************************************************************/
public with sharing class PEAC_PoolTriggerHandler extends SL_Trigger.baseHandler{
    
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method will be called when the Pool is updated
    @User Story:DP-1090	 
    @Created Date:July-22-2024   
    **************************************************************************************************************/
    public override void afterUpdate(Map<Id, SObject> newMap,Map<Id, SObject>oldMap){
        Set<Id> poolIdSet = New set<Id>();
        for (Pool__c pool : (List<Pool__c>)newMap.Values()) {
            Pool__c oldPoolRecord = (Pool__c)oldMap.get(pool.Id);
            if(pool.Current_Rate__c != oldPoolRecord.Current_Rate__c){
                poolIdSet.add(pool.Id);
            }
        }
        //Call pool helper class to recalculate the pool escalation rate
        if(!poolIdSet.isEmpty()){
            PEAC_PoolTriggerHelper.escalationRate(poolIdSet);
        }
                
    }
    
    public override void afterInsert(Map<Id,SObject> newMap){
        //empty method
    }
    
    public override void beforeInsert(List<SObject> newList){
        //empty method
    }
    public override void beforeUpdate(Map<Id, SObject> newMap,Map<Id, SObject>oldMap){
        //empty method
    }
}