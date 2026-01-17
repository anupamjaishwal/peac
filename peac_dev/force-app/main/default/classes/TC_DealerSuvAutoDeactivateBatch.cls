public class TC_DealerSuvAutoDeactivateBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    // Dealer & Surveillance Record Auto-Inactivation batch process
    // https://marlinbusiness.atlassian.net/browse/SAL-1588

    //Class was updated and reactivated per SAL-2239
    
    public static Date yearAgo = Date.today ().addYears(-1); // more than a year old, not inclusive
    
    // think about creating enums for the next 7
    public static Final String ACTIVE = 'Active';
    public static Final String ONEX_EXCEPTION = '1x Exception';
    public static Final String WATCH_LIST = 'Watch List';
    public static Final String INACTIVE = 'Inactive';
    public static Final String WATCH_INACTIVE = 'Watch Inactive';
    public static Final String IN_PROCESS = 'In Process';
    public static Final String IN_QUEUE = 'In Queue';
    public static Final STring COMPLETED = 'Completed';
    
    public static Set <String> entryDealerAccountStatuses = new Set <String> {ACTIVE, WATCH_LIST};
    public static Set <String> incompleteSuvStatuses = new Set <String> {IN_PROCESS, IN_QUEUE};

	public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('Starting');
        String query = 'SELECT Id, Account_Dealer_Status__c, Date_Dealer_Approved_Most_Recent__c, Waiting_To_Be_Sent_To_Bridgeware__c, (SELECT Id, Account_Dealer_Last_App__c, Waiting_To_Be_Sent_To_Bridgeware__c FROM ChildAccounts ORDER BY Account_Dealer_Last_App__c DESC LIMIT 1) FROM Account WHERE RecordType.Name = \'Dealer Account\' AND Account_Dealer_Status__c IN :entryDealerAccountStatuses AND Apps_Submitted_Since_Last_Approved__c = FALSE AND Date_Dealer_Approved_Most_Recent__c < :yearAgo';
        return Database.getQueryLocator(query);
    }
    
    public void execute (Database.BatchableContext bc, List<Account> accs) {
        Map<Id, Account> accUpdateMap = new Map<Id, Account>();
        System.debug('accs: ' + accs);
        for (Account acc : accs) {
            if(acc.Account_Dealer_Status__c == ACTIVE){
                if(acc.ChildAccounts.size() > 0) {
                    if(acc.ChildAccounts[0].Account_Dealer_Last_App__c < acc.Date_Dealer_Approved_Most_Recent__c || acc.ChildAccounts[0].Account_Dealer_Last_App__c == null){
                        if(accUpdateMap.get(acc.Id) == null){
                            accUpdateMap.put(acc.Id, new Account(Id=acc.Id, Account_Dealer_Status__c = INACTIVE, Waiting_To_Be_Sent_To_Bridgeware__c = true));
                        }
                    }
                }else {
                    if(accUpdateMap.get(acc.Id) == null){
                        accUpdateMap.put(acc.Id, new Account(Id=acc.Id, Account_Dealer_Status__c = INACTIVE, Waiting_To_Be_Sent_To_Bridgeware__c = true));
                    }
                }
            }
            else if(acc.Account_Dealer_Status__c == WATCH_LIST){
                if(acc.ChildAccounts.size() > 0) {
                    if(acc.ChildAccounts[0].Account_Dealer_Last_App__c < acc.Date_Dealer_Approved_Most_Recent__c || acc.ChildAccounts[0].Account_Dealer_Last_App__c == null){
                        if(accUpdateMap.get(acc.Id) == null){
                            accUpdateMap.put(acc.Id, new Account(Id=acc.Id, Account_Dealer_Status__c = WATCH_INACTIVE, Waiting_To_Be_Sent_To_Bridgeware__c = true));
                        }
                    }
                }else {
                    if(accUpdateMap.get(acc.Id) == null){
                        accUpdateMap.put(acc.Id, new Account(Id=acc.Id, Account_Dealer_Status__c = WATCH_INACTIVE, Waiting_To_Be_Sent_To_Bridgeware__c = true));
                    }
                }
            }
        }

        if (!accUpdateMap.values().isEmpty ()) update accUpdateMap.values();
    }
    
    public void finish(Database.BatchableContext bc) {
        System.debug('Finished Dealer & Surveillance Record Auto-Inactivation batch process');
        if(!Test.isRunningTest()){
            Id jobId = Database.executeBatch(new TC_DealerAccountSendToBWBatch(), 1);
        }
    }
    
}