/********************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This class is used to update the Equipment Cost w/o Tax on Accounts.
@User Story:SAL-6483
@Created Date:February-03-2026 	    
*********************************************************************************************************************/

public without sharing class PEAC_EquipmentCostWOTax {

    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method will be called when the opportunity's equipment cost without tax field is updated.
                    Calling reference-TC_OpportunityTriggerHandler class
    @User Story:SAL-6483	
    @Param:Map of new opportunity and Old Opprtunity 
    @Created Date:February/5/2026   
    **************************************************************************************************************/
    /*
    public static void opportunityEquipCostWOTax(Map<Id,Opportunity> newMap, Map<Id,Opportunity> oldMap){
        Set<Id> allEndUserAccountsSet = new Set<Id>();
        for (Opportunity opp : newMap.values()) {
            if (opp.Equipment_Cost_w_o_Tax__c != oldMap.get(opp.Id).Equipment_Cost_w_o_Tax__c) {
                allEndUserAccountsSet.add(opp.AccountId);
            }
        }
        if(!allEndUserAccountsSet.isEmpty())
        {
           getAllEndUserAccounts(allEndUserAccountsSet,true);
           
        }
    }*/

    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method will be called from opportunityEquipCostWOTax to get all enduser account ids
    @User Story:SAL-6483	
    @Param:Set of account Ids and boolean to update account or not
    @Created Date:February/5/2026   
    **************************************************************************************************************/
    public static Set<Id> getAllEndUserAccounts(Set<Id> allEndUserAccountsSet, Boolean executeToUpdate)
    {
        List<Account> endUserList = new List<Account>();
        Set<Id> endUGroupCodeSet = new Set<Id>();
        endUserList = [SELECT Id, Infolease_Group_Code__c FROM Account WHERE Id IN :allEndUserAccountsSet];
        for(Account endUserAcc : endUserList)
        {
            if(endUserAcc.Infolease_Group_Code__c != null){
                endUGroupCodeSet.add(endUserAcc.Infolease_Group_Code__c);
            }
            endUGroupCodeSet.add(endUserAcc.id);
            
        }
        
        return endUGroupCodeSet;

    }
    /*
    public static Set<Id> getAllEndUserAccounts(Set<Id> allEndUserAccountsSet, Boolean executeToUpdate)
    {
        List<Account> endUserList = new List<Account>();
        Set<Id> endUserAccountsSet = new Set<Id>(); 
        Set<Id> endUGroupCodeSet = new Set<Id>();
        endUserList = [SELECT Id, Infolease_Group_Code__c FROM Account WHERE Id IN :allEndUserAccountsSet];
        System.debug(logginglevel.ERROR, 'oppIdSet...'+endUserList);
        for(Account endUserAcc : endUserList)
        {
            if(endUserAcc.Infolease_Group_Code__c != null){
                endUGroupCodeSet.add(endUserAcc.Infolease_Group_Code__c);
            }
            endUserAccountsSet.add(endUserAcc.id);
            
        }
        
        List<Account> allEndUserList = new List<Account>();
        allEndUserList = [SELECT Id FROM Account WHERE Infolease_Group_Code__c IN :endUGroupCodeSet];
        for(Account endUserAccount : allEndUserList)
        {
            endUserAccountsSet.add(endUserAccount.Id);
        }
        if(!endUserAccountsSet.isEmpty() && executeToUpdate)
        {
            updateEquipmentCostWOTax(endUserAccountsSet,true);
        }
        allEndUserList.clear();
        return endUserAccountsSet;

    }*/
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: Get total equipment cost without tax based on open opportunities for account and infolease group
                    code.
    @User Story:SAL-6483	
    @Param:Set of account Ids or infolease group code ids and boolean to update account or not
    @Created Date:February/5/2026   
    **************************************************************************************************************/
    /*
    public static Map<Id,Decimal> updateEquipmentCostWOTax(Set<Id> allEndUserAccountsSet, Boolean isToUpdate)
    {
        
        list<Opportunity> oppList = new list<Opportunity>();
        oppList = [SELECT Id, AccountId, Account.Infolease_Group_Code__c,Equipment_Cost_w_o_Tax__c 
                    FROM Opportunity WHERE AccountId IN :allEndUserAccountsSet AND 
                    (StageName !='Lost' OR Application_Status__c != 'Cancelled')];
        Map<Id,Decimal> endUserEquipCostMap = new Map<Id,Decimal>();
        for(Opportunity opp : oppList)
        {
            if(opp.Account.Infolease_Group_Code__c !=null)
            {
                if(!endUserEquipCostMap.containsKey(opp.Account.Infolease_Group_Code__c))
                {
                    endUserEquipCostMap.put(opp.Account.Infolease_Group_Code__c,0.00);
                }
                Decimal equipCost = endUserEquipCostMap.get(opp.Account.Infolease_Group_Code__c);
                equipCost += opp.Equipment_Cost_w_o_Tax__c;
                endUserEquipCostMap.put(opp.Account.Infolease_Group_Code__c,equipCost);
            }
            else
            {
                
                if(!endUserEquipCostMap.containsKey(opp.AccountId))
                {
                    endUserEquipCostMap.put(opp.AccountId,0.00);
                }
                Decimal equipCostOpp = endUserEquipCostMap.get(opp.AccountId);
                equipCostOpp += opp.Equipment_Cost_w_o_Tax__c;
                endUserEquipCostMap.put(opp.AccountId,equipCostOpp);
            }            
            
        }
        if(!endUserEquipCostMap.isEmpty()  && isToUpdate)
        {
            finalUpdateOnEndUserAccount(endUserEquipCostMap);
        }
        return endUserEquipCostMap;
    }*/

    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: Final list of accounts to be updated Equipment cost without tax
    @User Story:SAL-6483	
    @Param:Set of account Ids and boolean to update account or not
    @Created Date:February/5/2026   
    **************************************************************************************************************/
    /*
    public static void finalUpdateOnEndUserAccount(Map<Id,Decimal> endUserEquipCostMap){
        List<Account> endUserAccountList = new List<Account>();
        endUserAccountList = [SELECT ID,Infolease_Group_Code__c,Total_Equipment_Cost_w_o_Tax__c FROM ACCOUNT WHERE Infolease_Group_Code__c IN :endUserEquipCostMap.keySet()
                                OR ID IN:endUserEquipCostMap.keySet()];
        for(Account acc:endUserAccountList){
            if(acc.Infolease_Group_Code__c != null){
                acc.Total_Equipment_Cost_w_o_Tax__c = endUserEquipCostMap.get(acc.Infolease_Group_Code__c);
            }
            else{
                acc.Total_Equipment_Cost_w_o_Tax__c = endUserEquipCostMap.get(acc.Id);
            }
        }
        update endUserAccountList;

        endUserAccountList.clear();
    }*/
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method will be called when the  Total_Equipment_Cost_w_o_Tax__c will be updated on Account
    @User Story:SAL-5831	 
    @Created Date:February/5/2026   
    **************************************************************************************************************/
    /*public static void updateEquipmentCostWOTaxonGLA(Map<Id,Account> newMap, Map<Id,Account> oldMap)
    {
        Map<Id,Decimal> accountEquipmentCostMap = new Map<Id,Decimal>();
        For(Account acc:newMap.values())
        {
            if(acc.Total_Equipment_Cost_w_o_Tax__c != oldMap.get(acc.Id).Total_Equipment_Cost_w_o_Tax__c)
            {
                if(acc.Infolease_Group_Code__c != null && !accountEquipmentCostMap.containsKey(acc.Infolease_Group_Code__c)){
                    accountEquipmentCostMap.put(acc.Infolease_Group_Code__c, acc.Total_Equipment_Cost_w_o_Tax__c);
                }
                else{
                    accountEquipmentCostMap.put(acc.Id, acc.Total_Equipment_Cost_w_o_Tax__c);
                }
            }
        }
        if(!accountEquipmentCostMap.isEmpty())
        {
            updateGLATotalEquiCostWOTax(accountEquipmentCostMap );
        }

    }*/
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method will update total equipment cost without tax on GLA
    @User Story:SAL-5831	 
    @Created Date:February/5/2026   
    **************************************************************************************************************/
    /*public static void updateGLATotalEquiCostWOTax(Map<Id,Decimal> accountEquipmentCostMap )
    {
        List<Guidance_Line_Amount__c> GLAList = new List<Guidance_Line_Amount__c>();
        GLAList = [SELECT Id,Total_Equipment_Cost_w_o_Tax__c,account__c,Account__r.Infolease_Group_Code__c
                     FROM Guidance_Line_Amount__c WHERE 
                    (Account__c IN :accountEquipmentCostMap.keySet() OR Account__r.Infolease_Group_Code__c IN:accountEquipmentCostMap.keySet()) 
                    AND Active__c = true];
        for(Guidance_Line_Amount__c gla:GLAList)
        {
            if(gla.Account__r.Infolease_Group_Code__c != null && accountEquipmentCostMap.containsKey(gla.Account__r.Infolease_Group_Code__c))
            {
                gla.Total_Equipment_Cost_w_o_Tax__c = accountEquipmentCostMap.get(gla.Account__r.Infolease_Group_Code__c);
            }
            else if(gla.account__c != null && accountEquipmentCostMap.containsKey(gla.Account__c))
            
            {
                gla.Total_Equipment_Cost_w_o_Tax__c = accountEquipmentCostMap.get(gla.Account__c);
            }
            
        }
        if(!GLAList.isEmpty())
        {
            update GLAList;
        }
        GLAList.clear();        
            
    }
    */
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method will be called when the opportunity stage changes
    @User Story:SAL-5831	 
    @Created Date:February/5/2026   
    **************************************************************************************************************/
  
    public static void validateGuidanceAmount(Map<Id,Opportunity> newMap, Map<Id,Opportunity> oldMap)
    {
        Map<Id,Id> allEndUserAccountsMap = new Map<Id,Id>();
        Set<Id> accountIdSet = new Set<Id>();
        for (Opportunity opp : newMap.values()) {
            if (opp.StageName != oldMap.get(opp.Id).StageName && System.label.PEAC_Guidance_Amount_Validation_Stages.contains(opp.StageName) && !opp.Loan_Record_Type__c) {
                allEndUserAccountsMap.Put(opp.id,opp.AccountId);
                accountIdSet.add(opp.AccountId);
            }
        }

        if(!accountIdSet.isEmpty()) 
        {
            Map<Id,Account> accMap = getAccountDetails(accountIdSet);
            Set<String> endUserOrInfoLeaseGIdSet = getGuidanceAmounts(accountIdSet);

            if(!endUserOrInfoLeaseGIdSet.isEmpty()){
                for (Opportunity opp : newMap.values()) {
                    if(allEndUserAccountsMap.containsKey(opp.id) && (endUserOrInfoLeaseGIdSet.contains(opp.AccountId) || 
                                (accMap.get(opp.AccountId).Infolease_Group_Code__c !=null && endUserOrInfoLeaseGIdSet.contains(accMap.get(opp.AccountId).Infolease_Group_Code__c))))
                    {
                        opp.addError(label.PEAC_Guidance_Amount_Validation_Error);
                    }
                }     
            }
        }
        
    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method is called to display warming message on Opportunity and it's related records
    @User Story:SAL-6483	
    @Param:Set of account Ids
    @Created Date:February/5/2026   
    **************************************************************************************************************/
    
    public static Set<String> getGuidanceAmounts(Set<Id> allEndUserAccountsSet)
    {
        
        Set<String> endUserOrInfoLeaseGIdSet = new Set<String>();
        Set<Id> endUserAccountIdSet = getAllEndUserAccounts(allEndUserAccountsSet, false);
        
        List<Guidance_Line_Amount__c> allGLAList = new List<Guidance_Line_Amount__c>();
        allGLAList = [SELECT ID,Account__c,Remaining_Capacity__c,
                     Account__r.Infolease_Group_Code__c,Guidance_Amount__c,Infolease_Group_Code__c
                     FROM Guidance_Line_Amount__c WHERE (Account__c IN:endUserAccountIdSet OR
                     Account__r.Infolease_Group_Code__c IN :endUserAccountIdSet) AND Active__c = TRUE 
                     ORDER BY End_Date__c,Createddate DESC]; 
                            
        for(Guidance_Line_Amount__c gla:allGLAList)
        {
            if(gla.Account__r.Infolease_Group_Code__c !=null && gla.Remaining_Capacity__c < = 0 )
            {
                endUserOrInfoLeaseGIdSet.add(gla.Account__r.Infolease_Group_Code__c);
            }
            else if(gla.Account__c !=null && gla.Remaining_Capacity__c < = 0)
            {
                endUserOrInfoLeaseGIdSet.add(gla.Account__c);
            }
            system.debug('endUserOrInfoLeaseGIdSet....'+endUserOrInfoLeaseGIdSet);
            
        }
        return endUserOrInfoLeaseGIdSet;
    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: get map of accounts
    @User Story:SAL-6483	
    @Param:Set of account Ids
    @Created Date:February/5/2026   
    **************************************************************************************************************/
  
    public static Map<Id,Account> getAccountDetails(Set<Id> accIdSet)
    {
        Map<Id,Account> accMap = new Map<Id,Account>([SELECT ID,Infolease_Group_Code__c,Total_Equipment_Cost_w_o_Tax__c FROM ACCOUNT WHERE ID IN :accIdSet]);
        return accMap;

    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method is called to display warming message on Opportunity and it's related records
    @User Story:SAL-6483	
    @Param:Set of account Ids
    @Created Date:February/5/2026   
    **************************************************************************************************************/
    /*
    public static Set<String> getGuidanceAmounts(Set<Id> allEndUserAccountsSet)
    {
        
        Set<String> endUserOrInfoLeaseGIdSet = new Set<String>();
        Set<Id> endUserAccountIdSet = getAllEndUserAccounts(allEndUserAccountsSet, false);
        Map<Id,Decimal> accInfoLeaseIdMap = updateEquipmentCostWOTax(endUserAccountIdSet, false);
        
        List<Guidance_Line_Amount__c> allGLAList = new List<Guidance_Line_Amount__c>();
        allGLAList = [SELECT ID, Remaining_Amount_After_Equipment_WO_Tax__c,Account__c,
                     Account__r.Infolease_Group_Code__c,Guidance_Amount__c,Infolease_Group_Code__c
                     FROM Guidance_Line_Amount__c WHERE (Account__c IN:accInfoLeaseIdMap.keySet() OR
                     Account__r.Infolease_Group_Code__c IN :accInfoLeaseIdMap.keySet()) AND Active__c = TRUE 
                     ORDER BY End_Date__c,Createddate DESC]; 
                            
        for(Guidance_Line_Amount__c gla:allGLAList)
        {
            if(gla.Account__r.Infolease_Group_Code__c !=null &&  accInfoLeaseIdMap.containsKey(gla.Account__r.Infolease_Group_Code__c)
             && accInfoLeaseIdMap.get(gla.Account__r.Infolease_Group_Code__c) >= gla.Guidance_Amount__c )
            {
                endUserOrInfoLeaseGIdSet.add(gla.Account__r.Infolease_Group_Code__c);
            }
            else if(accInfoLeaseIdMap.containsKey(gla.Account__c)
             && accInfoLeaseIdMap.get(gla.Account__c) >= gla.Guidance_Amount__c )
             {
                endUserOrInfoLeaseGIdSet.add(gla.Account__c);
             }
            
        }
        return endUserOrInfoLeaseGIdSet;
    }*/
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method will be called when the Guidance Line amount record is created to updated Equipment 
                    cost without tax on Accounts
    @User Story:SAL-5831	 
    @Created Date:February/5/2026   
    **************************************************************************************************************/
    /*public static void updateEquipmentCost(Map<Id,Guidance_Line_Amount__c> newMap)
    {
        Set<Id> accountIdSet = new Set<Id>();
        for(Guidance_Line_Amount__c gla:newMap.values())
        {
            accountIdSet.add(gla.Account__c);
        }
        if(!accountIdSet.isEmpty())
        {
            PEAC_EquipmentCostWOTax.getAllEndUserAccounts(accountIdSet,true);
        }

    }*/
    
}