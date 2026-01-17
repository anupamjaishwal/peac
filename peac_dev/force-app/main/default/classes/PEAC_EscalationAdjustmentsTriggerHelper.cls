/**************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This is a PEAC_EscalationAdjustmentsTriggerHelper class to support 
            PEAC_EscalationAdjustmentsTriggerHandler
@User Story:DP-1090	 
@Created Date:July-19-2024   
**************************************************************************************************************/
public with sharing class PEAC_EscalationAdjustmentsTriggerHelper {
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method will be called from escalation adjs handler class to calculate the escalation rate
    @User Story:DP-1090	 
    @Created Date:July-22-2024   
    @Param: List Escalation Adjustment records without Ids
    **************************************************************************************************************/
    public static void executeEscalatation(List<Escalation_Adjustments__c> escalationList){
        Set<Id> poolIdSet = New Set<Id>();
        Map<Id,Decimal> poolIdWithEscalationRateMap =  New Map<Id,Decimal>();
        for(Escalation_Adjustments__c esc: escalationList){
            poolIdSet.add(esc.Audit_Pool__c);
        }
   		List<Pool__c> poolEscalationList = PEAC_PoolTriggerHelper.getPoolData(poolIdSet);// get pools data
        for(Pool__c pool:poolEscalationList){
            if(pool.Pool_Escalation_Adjustments__r.isEmpty()){
                poolIdWithEscalationRateMap.put(pool.id,pool.Current_Rate__c);// hold current rate from pool
            }
            else{
              Integer index = pool.Pool_Escalation_Adjustments__r.Size()-1;
              poolIdWithEscalationRateMap.put(pool.id,pool.Pool_Escalation_Adjustments__r[index].Escalated_Rate__c);// hold current rate from pool  
            }
        }
        for(Escalation_Adjustments__c escUpdate: escalationList){
            if(poolIdWithEscalationRateMap.containsKey(escUpdate.Audit_Pool__c)){
            	if(escUpdate.Adjustment_Value__c == Null)// handle null for adjustment value
                {
                    escUpdate.Adjustment_Value__c = 0; 
                }
                if(escUpdate.Adjustment_Method__c == PEAC_ConstantClass.FIXED){
                    escUpdate.Change_Value__c  = escUpdate.Adjustment_Value__c + poolIdWithEscalationRateMap.get(escUpdate.Audit_Pool__c);
                    escUpdate.Escalated_Rate__c = poolIdWithEscalationRateMap.get(escUpdate.Audit_Pool__c) + escUpdate.Adjustment_Value__c;
                }
                else {
                    //Method as Percentage
                    escUpdate.Change_Value__c = (escUpdate.Adjustment_Value__c*poolIdWithEscalationRateMap.get(escUpdate.Audit_Pool__c))/100;
                    escUpdate.Escalated_Rate__c = poolIdWithEscalationRateMap.get(escUpdate.Audit_Pool__c) + escUpdate.Change_Value__c;
                }
                poolIdWithEscalationRateMap.put(escUpdate.Audit_Pool__c,escUpdate.Escalated_Rate__c);//Update new escalation rate for the Parent Pool id
                
            }
            
        }
        
    }
}