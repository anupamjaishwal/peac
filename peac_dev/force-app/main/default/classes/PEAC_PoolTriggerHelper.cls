/**************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This is a PEAC_PoolTriggerHelper class to support 
            PEAC_PoolTriggerHandler
@User Story:DP-1090	 
@Created Date:July-22-2024   
**************************************************************************************************************/
public with sharing class PEAC_PoolTriggerHelper {

     
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method will be called from pool handler class to recalculate the escalation rate
    @User Story:DP-1090	 
    @Created Date:July-22-2024   
    @Param: Set of Pool Ids
    **************************************************************************************************************/
   
    public static void escalationRate(Set<Id> poolsIDSet){
        //list of Escalation records to be updated
        List<Escalation_Adjustments__c> toBeUpdatedEscList = New List<Escalation_Adjustments__c>();
        list<Pool__C> poolEscalationList = getPoolData(poolsIDSet);// get the pool details
                
        for(Pool__c pool:poolEscalationList){
            if(!pool.Pool_Escalation_Adjustments__r.isEmpty()){
                Decimal escalationRate = 0.00000;
                escalationRate = pool.Current_Rate__c;//Assign the current rate to escalation rate
                Integer index = 0;// Initialise index for the Pool's escalation records
                Integer sizeOfAdj = pool.Pool_Escalation_Adjustments__r.size();//get the size of escalation records
                index = getRecordIndex(pool.Pool_Escalation_Adjustments__r);//get the index number of the records from where to be updated
                //loop through the pool's escalation records with latest index
                for(Integer k = index;  k<sizeOfAdj;k++){
                    Escalation_Adjustments__c esc = pool.Pool_Escalation_Adjustments__r[k];//get the escalation record based on index
                    Escalation_Adjustments__c escAdj = calculatEscalation(esc,escalationRate);// call the method to calculate escalation rate
                    escalationRate = escAdj.Escalated_Rate__c;
                    toBeUpdatedEscList.add(escAdj);//Add the escalation record to the list to be updated
                }
            }
        }
        
        if(!toBeUpdatedEscList.isEmpty())
        {
            update toBeUpdatedEscList;//Update the list of escalation records.
        }
    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: Get List of Pool's Records
    @User Story:DP-1090	 
    @Created Date:July-22-2024   
    @Param:Set of Pool ids
    @Return: List of Pool's records
    **************************************************************************************************************/
   
    public static List<Pool__c> getPoolData(Set<Id> poolsIDSet)
    {
        List<Pool__c> poolEscalationList = New List<Pool__c>();
        poolEscalationList = [SELECT Id,Current_Rate__c, (SELECT Id,Adjustment_Method__c,Adjustment_Value__c,Change_Value__c,
                            Effective_Date__c,Escalated_Rate__c FROM Pool_Escalation_Adjustments__r 
                            ORDER BY Effective_Date__c ASC) FROM Pool__c WHERE Id IN:poolsIDSet];
        return poolEscalationList;
    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: Get escalation record index number to start the update from.
    @User Story:DP-1090	 
    @Created Date:July-22-2024   
    @Param:List of Escalation records
    @Return: Integer
    **************************************************************************************************************/
   
    public static Integer getRecordIndex(List<Escalation_Adjustments__c> escalationList)
    {
        Integer index = 0;
        Integer sizeOfAdj = escalationList.size();
        for(Escalation_Adjustments__c escIndex:escalationList){
            index = index + 1;
            Date currentRecDate = escIndex.Effective_Date__c;//Get the current escalation record's date
            Date nextRecDate = escalationList[index].Effective_Date__c;// Get the next escalation records' date
            Integer daysBetween = nextRecDate.daysBetween(System.today());// find the days between next record and today
            //next record's date is in future and today is within the next record's date
            if(nextRecDate > currentRecDate && daysBetween < = 0 ){
                index = index - 1;
                break;
            } 
        }
        return index;
    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: Calculate the escalation rate
    @User Story:DP-1090	 
    @Created Date:July-22-2024   
    @Param: Escalation_Adjustments__c record
    **************************************************************************************************************/
  
    public static Escalation_Adjustments__c calculatEscalation(Escalation_Adjustments__c esc, Decimal escalationRate){
        Escalation_Adjustments__c escAdj = New Escalation_Adjustments__c();
        escAdj.id = esc.id;
        if(esc.Adjustment_Value__c == Null)
        {
           esc.Adjustment_Value__c = 0; 
        }
        //Check for method as Fixed= Escalation Rate + Adjustment Value
        if(esc.Adjustment_Method__c == PEAC_ConstantClass.FIXED){
            escAdj.Change_Value__c  = esc.Adjustment_Value__c + escalationRate;
            escAdj.Escalated_Rate__c = escalationRate + esc.Adjustment_Value__c;
        }
        else {
            //Method as Percentage
            escAdj.Change_Value__c = (esc.Adjustment_Value__c*escalationRate)/100;
            escAdj.Escalated_Rate__c = escalationRate + escAdj.Change_Value__c;
        }
        return escAdj;
    }
}