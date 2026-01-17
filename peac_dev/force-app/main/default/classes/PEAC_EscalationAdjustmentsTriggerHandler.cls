/**************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This is a PEAC_EscalationAdjustmentsTriggerHandler class to support 
            PEAC_Escalation_AdjustmentsTrigger
@User Story:DP-1090	 
@Created Date:July-19-2024   
**************************************************************************************************************/
public with sharing class PEAC_EscalationAdjustmentsTriggerHandler extends SL_Trigger.baseHandler{
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method will be called when the Escalation Adjustment is created
    @User Story:DP-1090	 
    @Created Date:July-19-2024   
    **************************************************************************************************************/
    public override void beforeInsert(List<SObject> newList){
        PEAC_EscalationAdjustmentsTriggerHelper.executeEscalatation(newList);
    }
    public override void afterInsert(Map<Id, SObject> newMap){
        //Empty Method
    }
    
    
    
}