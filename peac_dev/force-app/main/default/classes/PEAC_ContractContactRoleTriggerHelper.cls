/********************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This is a PEAC_ContractContactRoleTriggerHelper class to support PEAC_ContractContactRoleTriggerHandler
class
@User Story:DP-903
@Created Date:June-18-2024 	    
*********************************************************************************************************************/

public class PEAC_ContractContactRoleTriggerHelper {
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method will updated the Contract Primary Contact field based on
                    Contract contact role record creation, updation and deletion
    @User Story:DP-903	 
    @Created Date:June-18-2024   
    **************************************************************************************************************/
    
    public static void updateContractContactRole(Set<Id> contractSet){
        list<Contract__c> contractList = new list<Contract__c>();//Store Contract Records
        list<Contract__c> tobeContractList = new list<Contract__c>();//Store to be updated contract records with primary contact
        contractList = [SELECT Id,Primary_Contact__c,
                        (SELECT ID,Contact__c FROM Contract_Roles__r WHERE Role__c =:PEAC_ConstantClass.PRIMARY_CONTACT 
                         ORDER BY CreatedDate ASC LIMIT 1) FROM Contract__c WHERE Id IN:contractSet
                       ];
        for(Contract__c contract :contractList)
        {	
           if((!contract.Contract_Roles__r.isEmpty() && (Trigger.isInsert || Trigger.isUpdate)) 
                || (Trigger.isDelete && !contract.Contract_Roles__r.isEmpty() && contract.Primary_Contact__c != contract.Contract_Roles__r[0].Contact__c))  // check for contract contact role record 
            {
                contract.Primary_Contact__c = contract.Contract_Roles__r[0].Contact__c;// Assign contact id to contract primary contact field
                tobeContractList.add(contract);// add to the updated contract list
            }
            else
            {
               contract.Primary_Contact__c = PEAC_ConstantClass.NULL_VALUE;// Assign contact id as empty
               tobeContractList.add(contract);// add to the updated contract list 
            }
        }
        if(!tobeContractList.isEmpty())// check for empty contract list
        {
            update tobeContractList;// update the contract list with primary contact
        }
    }
}