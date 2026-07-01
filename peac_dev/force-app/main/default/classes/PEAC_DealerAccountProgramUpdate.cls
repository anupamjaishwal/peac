public class PEAC_DealerAccountProgramUpdate {

    public static void checkDealerAccountAndUpdateProgram(Map <Id, Account> oldMap, Map <Id, Account> newMap){
        
        Id dealerVendorRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer_Vendor').getRecordTypeId();
        Map<Id, Account> dealerAccountsWithDealerProgramMap = new Map<Id, Account>();
        Set<String> accountDealerPrograms = new Set<String>();
        for(Account acc: newMap.values()){
            if(acc.RecordTypeId == dealerVendorRtId && acc.Account_Dealer_Program__c != Null){
                dealerAccountsWithDealerProgramMap.put(acc.Id, acc);
                accountDealerPrograms.add(acc.Account_Dealer_Program__c);
            }
        }
        if(!dealerAccountsWithDealerProgramMap.isEmpty() && !accountDealerPrograms.isEmpty()){
			Map<Id, Program__c> programsMap = checkProgramsArePresent(accountDealerPrograms);
            if(!programsMap.isEmpty()){
                Map<Id, List<Account_Program__c>> relatedAccountPrograms = getAllRelatedAccountPrograms(dealerAccountsWithDealerProgramMap);
                for(Account acc : dealerAccountsWithDealerProgramMap.values()){
                    //System.debug(relatedAccountPrograms.get(acc.Id).Name);
                    if(relatedAccountPrograms.containskey(acc.Id)){
                        
                    }
                }
            }
        }
    }
    
    public static Map<Id, Program__c> checkProgramsArePresent(Set<String> accountDealerPrograms) {
        return new Map<Id, Program__c>([SELECT Id, Name FROM Program__c WHERE Name IN :accountDealerPrograms]);
    }
    
    public static Map<Id, List<Account_Program__c>> getAllRelatedAccountPrograms(Map<Id, Account> dealerAccountsWithDealerProgramMap){
        Map<Id, List<Account_Program__c>> accountProgramMap = new Map<Id, List<Account_Program__c>>();
        if (dealerAccountsWithDealerProgramMap == null || dealerAccountsWithDealerProgramMap.isEmpty()) {
            return accountProgramMap;
        }
        for (Account_Program__c accProg : [SELECT Id, Name, Account__c, Program__c
                                           FROM Account_Program__c
                                           WHERE Account__c IN :dealerAccountsWithDealerProgramMap.keySet()]) {
            if (!accountProgramMap.containsKey(accProg.Account__c)) {
                accountProgramMap.put(accProg.Account__c, new List<Account_Program__c>());
            }
            accountProgramMap.get(accProg.Account__c).add(accProg);
        }
        return accountProgramMap;
    }


}