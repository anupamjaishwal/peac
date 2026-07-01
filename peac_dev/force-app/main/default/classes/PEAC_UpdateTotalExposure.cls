/************************************************************************************************************************
 @Description: Update the Total Exposure from Opportunity to other following objects Like Account
 @Author: Rajesh Kumar(LTIMindtree)
 @Created Date: 12/30/2025
 @User Story:SAL-5831
*************************************************************************************************************************/

public without sharing class PEAC_UpdateTotalExposure {
    
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method will be called when the Total Exposure will be updated on opportunity
    @User Story:SAL-5831	 
    @Created Date:12/30/2025   
    **************************************************************************************************************/
  
    public static void updateTotalExposureOnAccount(Map<Id,SObject> newMap ,Map<Id,SObject> oldMap)
    {
        Map<Id,Account> accountIdTotalExpMap = new Map<Id,Account>();//Initialise map of account Id and Account
        for(SObject opp:newMap.values())
        {
            Opportunity oppObj = (Opportunity)opp;//Typecast sobject to new opportunity
            Opportunity oppOldObj = (Opportunity)oldMap.get(opp.Id);//Typecast sobject to old opportunity
            //Add values into the map only if below condidtions met 
            if(oppObj.Total_Exposure__c != oppOldObj.Total_Exposure__c &&  !oppObj.Loan_Record_Type__c && oppObj.AccountId !=null )
            {
                account acc = new account(Id = oppObj.AccountId, Total_Exposure__c = oppObj.Total_Exposure__c);// Initialising new account with id and Total Exposure
                accountIdTotalExpMap.put(oppObj.AccountId,acc);// Adding the account id as key and account as value
            }

        }
        // update list of accounts if map is not empty
        if (!accountIdTotalExpMap.isEmpty()) {
            Update accountIdTotalExpMap.Values(); //DML operation on account
        }
        accountIdTotalExpMap.clear();//clear the map from heap memory
    }
    
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method will be called when the Total Exposure will be updated on Account
    @User Story:SAL-5831	 
    @Created Date:12/30/2025   
    **************************************************************************************************************/
  
    public static void updateTotalExposureOnGuidance(Map<Id,Account> newMap ,Map<Id,Account> oldMap)
    {
    	Map<Id,Decimal> accountExposureAmountMap = new Map<Id,Decimal>();
        For(Account acc:newMap.values())
        {
            if(acc.Total_Exposure__c != oldMap.get(acc.Id).Total_Exposure__c)
            {
                if(acc.Infolease_Group_Code__c != null && !accountExposureAmountMap.containsKey(acc.Infolease_Group_Code__c)){
                    accountExposureAmountMap.put(acc.Infolease_Group_Code__c, acc.Total_Exposure__c);
                }
                else{
                    accountExposureAmountMap.put(acc.Id, acc.Total_Exposure__c);
                }
            }
        }
        if(!accountExposureAmountMap.isEmpty())
        {
            updateGuidanceTotalExposure(accountExposureAmountMap );
        }
        
        
    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method is a subset of updateTotalExposureOnGuidance method
    @User Story:SAL-5831	 
    @Created Date:12/30/2025
    **************************************************************************************************************/
  	public static void updateGuidanceTotalExposure(Map<Id,Decimal> accountIdTotalExpMap)
    {
        List<Guidance_Line_Amount__c> GLAList = new List<Guidance_Line_Amount__c>();
        GLAList = [SELECT Id,Total_Exposure_Amount__c,account__c,Account__r.Infolease_Group_Code__c
                     FROM Guidance_Line_Amount__c WHERE 
                    (Account__c IN :accountIdTotalExpMap.keySet() OR Account__r.Infolease_Group_Code__c IN:accountIdTotalExpMap.keySet()) 
                    AND Active__c = true];
        for(Guidance_Line_Amount__c gla:GLAList)
        {
            if(gla.Account__r.Infolease_Group_Code__c != null && accountIdTotalExpMap.containsKey(gla.Account__r.Infolease_Group_Code__c))
            {
                gla.Total_Exposure_Amount__c = accountIdTotalExpMap.get(gla.Account__r.Infolease_Group_Code__c);
            }
            else if(gla.account__c != null && accountIdTotalExpMap.containsKey(gla.Account__c))
            
            {
                gla.Total_Exposure_Amount__c = accountIdTotalExpMap.get(gla.Account__c);
            }
            
        }
        if(!GLAList.isEmpty())
        {
            update GLAList;
        }
        GLAList.clear();   
        
    }
    

}