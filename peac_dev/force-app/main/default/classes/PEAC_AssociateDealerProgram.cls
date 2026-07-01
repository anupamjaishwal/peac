/************************************************************************************************************************
 @Description: Associate the program from account program
 @Author: Rajesh Kumar(LTM)
 @Created Date: 06/29/2026
 @User Story: SAL-6998
 ************************************************************************************************************************/
public without sharing class PEAC_AssociateDealerProgram {
    public static Map<Id,Id> OppAccountIdMap =  new Map<Id,Id>();
    public static Map<Id,Id> accountProgramIdMap = new Map<Id,Id>();
	/**************************************************************************************************************
    @Author:Rajesh Kumar(LTM)
    @Description: This method will be called from DealerTriggerhanlder to associate program
    @User Story:SAL-6998	 
    @Param:New Map of opportunity id with record and old map of opportunity id with record 
    @Created Date:06/29/2026  
    **************************************************************************************************************/
  
    public static void associateProgram(List<Dealer__c> dealerList)
    {
        set<Id> dealerAccountIdSet = new set<Id>();
        List<Account> accountProgramList = new List<Account>();
        for(Dealer__c dealer: dealerList)
       	{
           if(dealer.opportunity__c !=null && dealer.Dealer__c !=null && dealer.Program__c == null && dealer.Primary_Dealer__c)
           {
              dealerAccountIdSet.add(dealer.Dealer__c); 
           }
       	}
        if(!dealerAccountIdSet.isEmpty()){
          	Map<Id,Id> accountProgramIdSet = new Map<Id,Id>();
            List<Opportunity> oppList = new List<Opportunity>();
            accountProgramList =[SELECT ID,(SELECT ID,Program__c FROM Account_Programs__r ORDER BY Createddate DESC LIMIT 1) FROM ACCOUNT WHERE ID IN:dealerAccountIdSet];  
            for(Account acc: accountProgramList)
            {
                if(acc.Account_Programs__r !=null)
                {
                 	accountProgramIdSet.put(acc.Id,acc.Account_Programs__r[0].Program__c);   
                }
                
            }
            for(Dealer__c dealer: dealerList)
            {
                if(dealer.Dealer__c !=null && accountProgramIdSet.containsKey(dealer.Dealer__c) && dealer.Primary_Dealer__c)
                {
                 	Opportunity opp = new Opportunity();
                    opp.Id = dealer.Opportunity__c;
                    opp.Program_Lookup__c = accountProgramIdSet.get(dealer.Dealer__c);
                    dealer.Program__c = accountProgramIdSet.get(dealer.Dealer__c);
                    //oppList.add(opp); 
                    
                }
            }
            if(!oppList.isEmpty())
            {
                update oppList;
            }
        }
        
         
    }
    
    /**************************************************************************************************************
     @Description: Update program when Primary Dealer changes
    **************************************************************************************************************/
    public static void updateDealerProgram(Map<Id, Opportunity> newMap,
                                           Map<Id, Opportunity> oldMap) {

        Map<Id, Id> changedDealerMap = new Map<Id, Id>();

        for (Opportunity opp : newMap.values()) {
            Opportunity oldOpp = oldMap.get(opp.Id);

            if (opp.Primary_Dealer__c != oldOpp.Primary_Dealer__c) {
                changedDealerMap.put(opp.Id, opp.Primary_Dealer__c);
                if(opp.Primary_Dealer__c == null)
                {
                   opp.Program_Lookup__c = null; 
                }
            }
        }

        if (changedDealerMap.isEmpty()) {
            return;
        }

        getDealerProgram(changedDealerMap.values());

        for (Opportunity opp : newMap.values()) {
            if (oppAccountIdMap.containsKey(opp.Id)) {
                Id dealerAccId = oppAccountIdMap.get(opp.Id);

                if (accountProgramIdMap.containsKey(dealerAccId)) {
                    opp.Program_Lookup__c = accountProgramIdMap.get(dealerAccId);
                }
            }
        }
    }
    public static void getDealerProgram(List<Id> dealerIdList)
    {
    	OppAccountIdMap.clear();
        List<Dealer__c> dealerList = new List<Dealer__c>();  
        
        dealerList = [SELECT ID,dealer__c,Opportunity__c FROM Dealer__c WHERE Id IN:dealerIdList AND Primary_Dealer__c = True];
        for(Dealer__c dealer: dealerList)
        {
         	OppAccountIdMap.Put(dealer.Opportunity__c,dealer.Dealer__c);   
        }
        getProramBasedOnAccount(OppAccountIdMap.Values());
    }
    public Static void getProramBasedOnAccount(List<Id> dealerAccountIdList)
    {
    	accountProgramIdMap.clear();
        List<Account> accountProgramList = new List<Account>();	
        accountProgramList = [SELECT ID,(SELECT ID,Program__c FROM Account_Programs__r ) FROM ACCOUNT WHERE ID IN:dealerAccountIdList];  
        for(Account acc: accountProgramList)
        {
            if(acc.Account_Programs__r !=null && !acc.Account_Programs__r.isEmpty() && acc.Account_Programs__r.Size() == 1)
            {
                accountProgramIdMap.put(acc.Id,acc.Account_Programs__r[0].Program__c);   
            }
            
        }    
        //return accountProgramIdSet;
    }
}