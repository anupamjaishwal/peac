/************************************************************************************************************
*@Author: Rajesh Kumar(LTIMindtree)
@Description:This class is used to generate case center number
@Created Date:06/05/2025
@User Story:SAL-5449
 ************************************************************************************************************/
public with sharing class PEAC_AutoCaseCenterNumber {
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description:Function call if retrieval of auto-generated number is not on opportunity create.
    @Parameters:Set of opportunity ids
    @Return: Map of opportunity id and Autonumber(Integer)
    **************************************************************************************************************/
    public static Map<Id, String> retrieveAutoNumber(Set<Id> oppIdSet) {
        List<Case_Center_Auto_Number__c> autoNumberList = new List<Case_Center_Auto_Number__c>();//Initialise the case center autonumber instance as list       
        for (Id oppId : oppIdSet) {
            autoNumberList.add(new Case_Center_Auto_Number__c(Opportunity__c = oppId));// add into list to be inserted
        }
        insert autoNumberList;// insert the list

        List<Case_Center_Auto_Number__c> autoNumberQueryList = new List<Case_Center_Auto_Number__c>([
                SELECT Id, Name, Opportunity__c
                FROM Case_Center_Auto_Number__c
                WHERE Opportunity__c IN: oppIdSet
        ]);// get the inserted records with autonumber 

        Map<Id, String> oppIdAutoNumberMap = new Map<Id, String>();// Initialise the map for return
        for (Case_Center_Auto_Number__c autoNumber : autoNumberQueryList) {
            oppIdAutoNumberMap.put(autoNumber.Opportunity__c, autoNumber.Name);// map the opp id with generated auto number
        }
        delete autoNumberList;//delete the records after autonumber generation

        return oppIdAutoNumberMap;

    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description:This method is called to get Case center number on opportunity
    @Parameters:Set of opportunity ids
    @Return: None
    **************************************************************************************************************/
   
    public static void updateOppAppNumber (Set <Id> oppIds) {
        Set<Id> updatedOppIdSet = New Set<Id>();
        List <Opportunity> updateList = new List <Opportunity> (); //Initialise the opportunity to update case center number
        updateList = [SELECT ID,CaseCenter__c FROM Opportunity WHERE ID IN: oppIds AND CaseCenter__c = NULL];
        
        for(Opportunity opp: updateList)
        {
            updatedOppIdSet.add(opp.Id);
        }
        if(!updatedOppIdSet.isEmpty())
        {
            Map<Id, String> appNums = retrieveAutoNumber(updatedOppIdSet);// get the created autonumbers in map
            for(Opportunity opp: updateList)
            {
                if(appNums.get(opp.Id) != null)
                {
                    opp.CaseCenter__c = String.valueOf(appNums.get(opp.Id));//assign the case center number
                }
            }
            if (!updateList.isEmpty())
            {
                update updateList;//update the oppotunities
            }

        }
    }
 
}