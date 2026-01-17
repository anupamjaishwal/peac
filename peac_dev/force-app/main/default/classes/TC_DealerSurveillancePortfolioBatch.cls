public class TC_DealerSurveillancePortfolioBatch implements Database.Batchable<SObject> {
    
    public static Date todayDate = Date.today();
    
	public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Review_Date__c, Account__c, Account__r.X1_app_in_the_last_12_months__c, Account__r.Actual_Vs_Projected_Loss__c, Account__r.Account_Percentage31__c, Account__r.Account_Total_CBR__c, Account__r.X1_app_in_the_last_24_months__c, Account__r.Portfolio_Review_Threshold__c, Account__r.Last_Reviewed_Threshold__c, Account__r.Account_Dealer_LTD_Volume__c, Account__r.Surveillances_Incomplete__c from Dealer_Surveillance__c WHERE Next_Scheduled_Review__c = TODAY';
        return Database.getQueryLocator(query);
    }
    
    public void execute (Database.BatchableContext bc, List<Dealer_Surveillance__c> suvs) {
        List <Dealer_Surveillance__c> insertList = new List <Dealer_Surveillance__c> ();

        Set<Id> accIds = new Set<Id>();

        for(Dealer_Surveillance__c suv : suvs){
            accIds.add(suv.Account__c);
        }

        //Will use this map to find the date of the last portfolio review for the account
        Map<Id, Account> accounts = new Map<Id, Account> (
            [SELECT Id, Name, 
            (SELECT Id, Review_Date__c 
            FROM Dealer_Surveillances__r 
            WHERE Review_Type__c = 'Portfolio Threshold' 
            ORDER BY Review_Date__c DESC Limit 1) 
            FROM Account 
            WHERE Id IN :accIds]);
        
        for (Dealer_Surveillance__c suv : suvs) {
            if (suv.Account__r.Portfolio_Review_Threshold__c != null && 
                Decimal.valueOf (suv.Account__r.Portfolio_Review_Threshold__c.remove(',')) >= suv.Account__r.Account_Dealer_LTD_Volume__c) {

                    Boolean meetsLastThresholdCritera = false;
                    if(suv.Account__r.Last_Reviewed_Threshold__c == null){
                        meetsLastThresholdCritera = true;
                    }else if(Decimal.valueOf (suv.Account__r.Last_Reviewed_Threshold__c.remove(',')) <= Decimal.valueOf (suv.Account__r.Portfolio_Review_Threshold__c.remove(','))){
                        meetsLastThresholdCritera = true;
                    }
                    System.debug('Meets Last Threshold Criteria:' + meetsLastThresholdCritera);
                    System.debug('Is port reviews empty:' + accounts.get(suv.Account__c).Dealer_Surveillances__r.isEmpty());
                    System.debug('Portfolio reviews' + accounts.get(suv.Account__c).Dealer_Surveillances__r);

                    //Added criteria so a Surveillance object is only created if Last Review Threshold is <= new threshold and is the last review was at least 12 months ago for SAL-2923
                    if(meetsLastThresholdCritera &&
                    accounts.get(suv.Account__c).Dealer_Surveillances__r.isEmpty()){
                        insertList.add (new Dealer_Surveillance__c (Account__c = suv.Account__c
                                                          	, Review_Type__c = 'Portfolio Threshold'
                                                          	, Review_Date__c = todayDate
                                                          	, Status__c = 'In Queue'
                                                            , Waiting_To_Be_Sent_To_Bridgeware__c = true
                                                            , Created_via_Batch__c = true));
                    }else if (meetsLastThresholdCritera &&
                    accounts.get(suv.Account__c).Dealer_Surveillances__r[0].Review_Date__c <= todayDate.addMonths(-12)){
                        insertList.add (new Dealer_Surveillance__c (Account__c = suv.Account__c
                                                          	, Review_Type__c = 'Portfolio Threshold'
                                                          	, Review_Date__c = todayDate
                                                          	, Status__c = 'In Queue'
                                                            , Waiting_To_Be_Sent_To_Bridgeware__c = true
                                                            , Created_via_Batch__c = true));
                    }  
            }
        }
        
        if (!insertList.isEmpty()) insert insertList;
    }
    
    public void finish(Database.BatchableContext bc) {
        System.debug('>>> finish TC_DealerSurveillanceBatch');
    }

}