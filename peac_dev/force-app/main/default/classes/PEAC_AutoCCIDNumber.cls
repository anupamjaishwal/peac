/************************************************************************************************************
*@Author: Rajesh Kumar(LTIMindtree)
@Description:This class is used to generate CCID number
@Created Date:06/05/2025
@User Story:SAL-5449
 ************************************************************************************************************/
public with sharing class PEAC_AutoCCIDNumber {
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description:Create CCID number for new account.
    @Parameters:Set of account ids
    @Return: Map of account id and Auto number(Integer)
    **************************************************************************************************************/
    public static void  createCCID(Map<Id,SObject> newMap) {
        Set<Id> endUserAccountIdSet = New Set<Id>();
        for(SObject obj : newMap.values()){
            Account acc= (Account)obj;
            endUserAccountIdSet.add(acc.id);
            
        }
        if(!endUserAccountIdSet.isEmpty())
        {
            updateCCIDNumber(endUserAccountIdSet);
        }
    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description:Function call if retrieval of auto-generated number is not on ACCount create.
    @Parameters:Set of account ids
    @Return: Map of account id and Auto number(Integer)
    **************************************************************************************************************/
    public static Map<Id, String> retrieveAutoNumber(Set<Id> accIdSet) {
        List<CCID_Auto_Number__c> autoNumberList = new List<CCID_Auto_Number__c>();//Initialise the case center autonumber instance as list       
        for (Id accId : accIdSet) {
            autoNumberList.add(new CCID_Auto_Number__c(Account__c = accId));// add into list to be inserted
        }
        insert autoNumberList;// insert the list

        List<CCID_Auto_Number__c> autoNumberQueryList = new List<CCID_Auto_Number__c>([
                SELECT Id, Name, Account__c
                FROM CCID_Auto_Number__c
                WHERE Account__c IN: accIdSet
        ]);// get the inserted records with autonumber 

        Map<Id, String> accIdAutoNumberMap = new Map<Id, String>();// Initialise the map for return
        for (CCID_Auto_Number__c autoNumber : autoNumberQueryList) {
            accIdAutoNumberMap.put(autoNumber.Account__c, autoNumber.Name.left(7));// map the opp id with generated auto number
        }
        delete autoNumberList;//delete the records after autonumber generation

        return accIdAutoNumberMap;

    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description:This method is called to get CCID number on Account
    @Parameters:Set of account ids
    @Return: None
    **************************************************************************************************************/
   
    public static void updateCCIDNumber (Set <Id> accIdSet) {
        Set<Id> updatedAccIDSet = New Set<Id>();
        List <Account> updateList = new List <Account> (); //Initialise the Account to update CCID number
        updateList = [SELECT ID,CCID__c FROM Account WHERE ID IN: accIdSet AND CCID__c = NULL];
        for(Account acc: updateList)
        {
            updatedAccIDSet.add(acc.Id);
        }
        if(!updatedAccIDSet.isEmpty())
        {
            Map<Id, String> appNums = retrieveAutoNumber(updatedAccIDSet);// get the created autonumbers in map
            for(Account acc: updateList)
            {
                if(appNums.get(acc.Id) != null)
                {
                    acc.CCID__c = String.valueOf(appNums.get(acc.Id));//assign the CCID number
                }
            }
            if (!updateList.isEmpty())
            {
                update updateList;//update the account
            }
        }
        
    }
 
}