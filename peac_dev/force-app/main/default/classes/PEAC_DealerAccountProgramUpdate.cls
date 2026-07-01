/************************************************************************************************************************
 @Description: Trigger the Account Program creation or deletion from Account insert or program Type updates
 @Author: Rajesh Kumar(LTM)
 @Created Date: 05/27/2026
 @User Story: SAL-7201
 ************************************************************************************************************************/

public without sharing class PEAC_DealerAccountProgramUpdate {
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTM)
    @Description: This method will be called from TC_Accounttriggerhandler to Trigger the T Value
					calculation when app is approved
    @User Story:SAL-7201	 
    @Param:New Map of Account id with record and old map of Account id with record 
    @Created Date:05/27/2026   
    **************************************************************************************************************/
  	public static void checkDealerAccountAndUpdateProgram(Map <Id, Account> oldMap, Map <Id, Account> newMap){
        
        Map<Id, Set<String>> dealerAccIdWithDealerProgramMap = new Map<Id, Set<String>>();
        Map<Id, Set<String>> removedProgramMap = new Map<Id, Set<String>>();
        
        for(Account acc: newMap.values()){
            if(acc.Type == 'D' && (acc.Account_Dealer_Program__c != Null && oldMap == Null)||
               oldMap != Null && acc.Account_Dealer_Program__c != oldMap.get(acc.Id).Account_Dealer_Program__c ){
                   
                   Set<String> oldSet = new Set<String>(oldMap != Null && oldMap.get(acc.Id).Account_Dealer_Program__c != null ? oldMap.get(acc.Id).Account_Dealer_Program__c.split(';') : new String[]{});
                   Set<String> newSet = new Set<String>(acc.Account_Dealer_Program__c != null ? acc.Account_Dealer_Program__c.split(';') : new String[]{});
                   
                   // Added values
                   Set<String> addedProgramSet = new Set<String>(newSet);
                   //addedProgramSet.removeAll(oldSet);
                   
                   // Removed values
                   Set<String> removedProgramSet = new Set<String>(oldSet);
                   removedProgramSet.removeAll(newSet);
                   dealerAccIdWithDealerProgramMap.put(acc.Id, addedProgramSet);
                   removedProgramMap.put(acc.Id, removedProgramSet);

               }
        }
        if(!dealerAccIdWithDealerProgramMap.isEmpty() || !removedProgramMap.isEmpty()){
            //Insert and delete Account Program
            createOrDeleteAccountPrograms(dealerAccIdWithDealerProgramMap,removedProgramMap);
        }
    }
    
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTM)
    @Description: This method is called from mrthod checkDealerAccountAndUpdateProgram to create and delete
					account program records
	@User Story:SAL-7201		 
    @Param:New Map of account id and set of program
    @Created Date:05/27/2026   
    **************************************************************************************************************/
  
    public static void createOrDeleteAccountPrograms(Map<Id, Set<String>> dealerAccIdWithDealerProgramMap,Map<Id, Set<String>> removedProgramMap)
    {
        Map<Id, List<Account_Program__c>> relatedAccountProgramsMap = getAllRelatedAccountPrograms(dealerAccIdWithDealerProgramMap.KeySet());
        Set<String> ProgramNameSet = new Set<String>();
        for (Set<String> programName : dealerAccIdWithDealerProgramMap.values()) {
            ProgramNameSet.addAll(programName);
        }
        Map<String,Program__c> programsMap = checkProgramsArePresent(ProgramNameSet);
        List<Account_Program__c> tobeInsertedList = New List<Account_Program__c>();
        List<Account_Program__c> tobeDeletedList = New List<Account_Program__c>();
        for(Id accId: dealerAccIdWithDealerProgramMap.Keyset())  
        {
            if(relatedAccountProgramsMap.containsKey(accId))
            {
                for(Account_Program__c accProgram: relatedAccountProgramsMap.Get(accId))
                {
                    if(dealerAccIdWithDealerProgramMap.get(accId).Contains(accProgram.Program__r.Program_Code__c))
                    {
                        dealerAccIdWithDealerProgramMap.get(accId).remove(accProgram.Program__r.Program_Code__c);
                    }
                    if(removedProgramMap.get(accId).Contains(accProgram.Program__r.Program_Code__c) && accProgram.Created_From_System__c)
                    {
                        tobeDeletedList.add(accProgram);
                    }
                }
            }
            if(!dealerAccIdWithDealerProgramMap.get(accId).isEmpty())
                {
                 	for(String programCode : dealerAccIdWithDealerProgramMap.get(accId))
                    {
                        if(programsMap.get(programCode) !=Null && programsMap.get(programCode).Program_Code__c != null)
                        {
                         	Account_Program__c accProgram = new Account_Program__c();
                            accProgram.Account__c = accId;
                            accProgram.Program__c = programsMap.get(programCode).Id;
                            accProgram.Created_From_System__c = True;
                            tobeInsertedList.add(accProgram);   
                        }
                        
                    }
                }
        }
        
        if(!tobeInsertedList.isEmpty())
        {
            insert tobeInsertedList;
        }
        if(!tobeDeletedList.isEmpty())
        {
            delete tobeDeletedList;
        }
        
    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTM)
    @Description: Get the list of program based on program code
    @User Story:SAL-7102	 
    @Param:New Set of program code
    @Created Date:05/27/2026   
    **************************************************************************************************************/
  
    public static Map<String,Program__c> checkProgramsArePresent(Set<String> accountDealerPrograms) {
        List<Program__c> programList = New List<Program__c>();
        Map<String,Program__c> programCodeProgramMap = New Map<String,Program__c>();
        programList = [SELECT Id, Name,Program_Code__c FROM Program__c WHERE Program_Code__c IN :accountDealerPrograms];
        for(Program__c programRec: programList)
        {
            programCodeProgramMap.put(programRec.Program_Code__c,programRec);
        }
        return programCodeProgramMap;
    }
     /**************************************************************************************************************
    @Author:Rajesh Kumar(LTM)
    @Description: Get the map of dealer id with account program based on dealer Ids
    @User Story:SAL-7102	 
    @Param:New Set of dealer Ids
    @Created Date:05/27/2026   
    **************************************************************************************************************/
  
    public static Map<Id, List<Account_Program__c>> getAllRelatedAccountPrograms(Set<Id> dealerAccountIdsSet){
        Map<Id, List<Account_Program__c>> accountProgramMap = new Map<Id, List<Account_Program__c>>();
        if (dealerAccountIdsSet == null || dealerAccountIdsSet.isEmpty()) {
            return accountProgramMap;
        }
        for (Account_Program__c accProg : [SELECT Id, Name, Account__c, Program__c,Created_From_System__c,Program__r.Program_Code__c
                                           FROM Account_Program__c
                                           WHERE Account__c IN :dealerAccountIdsSet ])
        {
            if (!accountProgramMap.containsKey(accProg.Account__c)) {
                accountProgramMap.put(accProg.Account__c, new List<Account_Program__c>());
            }
            accountProgramMap.get(accProg.Account__c).add(accProg);
        }
        return accountProgramMap;
    }
    
    
}