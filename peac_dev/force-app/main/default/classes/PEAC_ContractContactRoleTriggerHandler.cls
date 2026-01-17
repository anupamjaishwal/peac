/**************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This is a Contract contact role trigger handler and exceute the business logic upon
creation, updation and deletion of the record
@User Story:DP-903	    
**************************************************************************************************************/
public with sharing class PEAC_ContractContactRoleTriggerHandler extends SL_Trigger.baseHandler {
    private static Set<Id> contractSet = new Set<Id>();// 
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method will be called when the Contract contact role is created
    @User Story:DP-903	 
    @Created Date:June-18-2024   
    **************************************************************************************************************/
    public override void afterInsert(Map<Id, SObject> newMap){
        
        for(Contract_Contact_Role__c contractConRole : (List<Contract_Contact_Role__c>) newMap.values())
        {
            if(contractConRole.Role__c == PEAC_ConstantClass.PRIMARY_CONTACT){
                contractSet.Add(contractConRole.Contract__c);
            }
        } 
        if(!contractSet.isEmpty())
        {
            //call the method to update the Primary Contact on contract record
            PEAC_ContractContactRoleTriggerHelper.updateContractContactRole(contractSet);
       	}
    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method will be called when the Contract contact role is updated
    @User Story:DP-903	 
    @Created Date:June-18-2024   
    **************************************************************************************************************/
    public override void afterUpdate(Map<Id, SObject> newMap,Map<Id, SObject>oldMap){
        for(Contract_Contact_Role__c contractConRole : (List<Contract_Contact_Role__c>) newMap.values())
        {
            //get old contract contact role record
            Contract_Contact_Role__c oldContractConRole = (Contract_Contact_Role__c)oldMap.get(contractConRole.Id);
            //Check the conditions to add contract ids into the set
            if((contractConRole.Role__c == PEAC_ConstantClass.PRIMARY_CONTACT || oldContractConRole.Role__c == PEAC_ConstantClass.PRIMARY_CONTACT) && 
               (oldContractConRole.Role__c != contractConRole.Role__c ||
                oldContractConRole.contact__c != contractConRole.contact__c) ){
                    contractSet.Add(contractConRole.Contract__c);//add contract ids
                }
        } 
        if(!contractSet.isEmpty())
        {
            //call the method to update the Primary Contact on contract record
            PEAC_ContractContactRoleTriggerHelper.updateContractContactRole(contractSet);
       	}
                
    }
    
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method will be called when the Contract contact role is deleted
    @User Story:DP-903	 
    @Created Date:June-18-2024   
    **************************************************************************************************************/
    public override void afterDelete(Map<Id, SObject> oldMap){
        
        for(Contract_Contact_Role__c contractConRole : (List<Contract_Contact_Role__c>) oldMap.values())
        {
            if(contractConRole.Role__c == PEAC_ConstantClass.PRIMARY_CONTACT){
                contractSet.Add(contractConRole.Contract__c);
            }
        } 
        if(!contractSet.isEmpty())
        {
            //call the method to update the Primary Contact on contract record
            PEAC_ContractContactRoleTriggerHelper.updateContractContactRole(contractSet);
       	}
    }

    public override void beforeDelete(Map<Id, SObject> oldMap){
        //empty method
    }
    public override void beforeInsert(List<SObject> newList){
        //empty method
    }
    public override void beforeUpdate(Map<Id, SObject> newMap,Map<Id, SObject>oldMap){
        //empty method
    }
       
}