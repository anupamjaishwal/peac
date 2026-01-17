/**
 * Created by corycafferty on 2019-07-23.
 */

// this code was made more complex because the dealer surveillances were determined to not be independent of eachother under the same account

public class TC_DealerSurveillanceBatch implements Database.Batchable<SObject> {
	
    public static Date todayDate = Date.today();
    public static DealerReviewer reviewer = new DealerReviewer ();
     
    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('>>> Start TC_DealerSurveillanceBatch');
        
        String query = 'SELECT Id, Account__c, Account__r.X1_app_in_the_last_12_months__c, Account__r.Actual_Vs_Projected_Loss__c, Account__r.Account_Percentage31__c, Account__r.Account_Total_CBR__c, Account__r.X1_app_in_the_last_24_months__c, Account__r.Portfolio_Review_Threshold__c, Account__r.Account_Dealer_LTD_Volume__c, Account__r.Surveillances_Incomplete__c from Dealer_Surveillance__c WHERE Next_Scheduled_Review__c = TODAY';
        return Database.getQueryLocator(query);
    }
    
    public void execute (Database.BatchableContext bc, List<Dealer_Surveillance__c> suvs) {
        
        List <Account> accounts = new List <Account> ();
        if (!suvs.isEmpty ()) {
            Set <Id> accIds = new Set <Id> ();
            
            for (Dealer_Surveillance__c suv :suvs) {
                accIds.add (suv.Account__c);
            }
            accounts = new List <Account> ([SELECT Id, X1_app_in_the_last_12_months__c, Actual_Vs_Projected_Loss__c, Account_Percentage31__c, Account_Total_CBR__c, X1_app_in_the_last_24_months__c, Portfolio_Review_Threshold__c, Account_Dealer_LTD_Volume__c, Net_Investment__c , Account_Actual_Projected_Loss__c , Account_Total_Past_Due_Percentage__c, (SELECT Id, Status__c FROM Dealer_Surveillances__r) FROM Account WHERE Id IN :accIds]);
        }
        
        Id informaticaUserId = [SELECT Id FROM User WHERE FirstName = 'User' AND LastName = 'Informatica'][0].Id;
        
        Map <Id, Boolean> allCompleted = new Map <Id, Boolean> ();
        List <Dealer_Surveillance__c> insertList = new List <Dealer_Surveillance__c> ();
		List <Dealer_Surveillance__c> updateList = new List <Dealer_Surveillance__c> ();
        
        if (!accounts.isEmpty ()) {

            // new getting model results
            Map <Id, String> reviewResults = reviewer.review (accounts);
            
            // need to see if sibling records are incomplete, need query out of the batch to get latest records
            for (Account acc : accounts) {
                
                Boolean allSUVSCompleted = true;
                
                
                if (!acc.Dealer_Surveillances__r.isEmpty()) {
                    for (Dealer_Surveillance__c suv : acc.Dealer_Surveillances__r) {
                        if (suv.Status__c != 'Completed') allSUVSCompleted = false;
                    }
                }
                allCompleted.put (acc.id, allSUVSCompleted);
                
                String model = reviewResults.get (acc.Id);
                
                if (allSUVSCompleted) {
                    // new model logic
                    
                    
                    /*
                    if ((acc.X1_app_in_the_last_12_months__c > 0 && acc.Actual_Vs_Projected_Loss__c <= 150 && acc.Account_Percentage31__c <= 3 && acc.Account_Total_CBR__c <= 750000)
                        || (acc.X1_app_in_the_last_24_months__c > 0 && acc.Account_Total_CBR__c <= 250000)) {
                        suvs.add (new Dealer_Surveillance__c (Account__c = acc.Id
                                                             , Status__c = 'Completed'
                                                             , Review_Date__c = todayDate
                                                             , Assigned_To__c = informaticaUserId
                                                             , Recommended_Action__c = 'Approved'
                                                             , Additional_Review_Comments__c = 'Meets acceptable criteria, auto-approved.'
                                                             , Recommended_Next_Review__c = '12 mos'
                                                             , Next_Scheduled_Review__c = todayDate.addYears(1)
                                                             , Review_Type__c = 'Scheduled Review'
                                                             , Waiting_To_Be_Sent_To_Bridgeware__c = true
                                                             , Created_via_Batch__c = true));
					} else {
                        suvs.add (new Dealer_Surveillance__c (Account__c = acc.Id
                                                             , Status__c = 'In Process'
                                                             , Review_Type__c = 'Scheduled Review'
                                                             , Waiting_To_Be_Sent_To_Bridgeware__c = true
                                                             , Created_via_Batch__c = true));
                            
					}*/
                    
                    
                    if (String.isBlank (model)) {
                        // no model match
                        suvs.add (new Dealer_Surveillance__c (Account__c = acc.Id
                                                             , Status__c = 'In Process'
                                                             , Review_Type__c = 'Scheduled Review'
                                                             , Waiting_To_Be_Sent_To_Bridgeware__c = true
                                                             , Created_via_Batch__c = true
                                                             , Dealer_Surveillance__c = 'Scheduled Review'));
                    } else {
                        // model match
						suvs.add (new Dealer_Surveillance__c (Account__c = acc.Id
                                                             , Status__c = 'Completed'
                                                             , Completed_By_Auto_Process__c = true
                                                             , Review_Date__c = todayDate
                                                             , Assigned_To__c = informaticaUserId
                                                             , Recommended_Action__c = 'Approved'
                                                             , Additional_Review_Comments__c = 'Meets acceptable criteria, auto-approved.'
                                                             , Recommended_Next_Review__c = '12 mos'
                                                             , Next_Scheduled_Review__c = todayDate.addYears(1)
                                                             , Review_Type__c = 'Scheduled Review'
                                                             , Waiting_To_Be_Sent_To_Bridgeware__c = true
                                                             , Created_via_Batch__c = true
                                                             , Model_Hit__c = reviewer.getModelIdByName (model)
                                                             , Dealer_Surveillance__c = 'Scheduled Review'));                        
                    }
                    
                } else {
                    // update today's in process ones to complete if they hit a threshhold
                    /*for (Dealer_Surveillance__c suv : acc.Dealer_Surveillances__r) {
                        if (suv.Next_Scheduled_Review__c == todayDate && suv.Review_Type__c == 'Scheduled Review') {
                            updateList.add (new Dealer_Surveillance__c (Id = suv.Id
                                                                        , Status__c = 'Completed'
                                                                        , Waiting_To_Be_Sent_To_Bridgeware__c = true
																		, Model_Hit__c = reviewer.getModelIdByName (model)));
                        }
                    }*/
                    
                }
            }
            
            for (Dealer_Surveillance__c suv : suvs) {
                // all siblings have complete suvs
                if (allCompleted != null && allCompleted.get (suv.Account__c) == true) {
                    System.debug ('????? all completed');
                    
                    
                    
                    
                    /*
                    if ((suv.Account__c != null && suv.Account__r.X1_app_in_the_last_12_months__c > 0 && suv.Account__r.Actual_Vs_Projected_Loss__c <= 150 && suv.Account__r.Account_Percentage31__c <= 3 && suv.Account__r.Account_Total_CBR__c <= 750000)
                        || (suv.Account__c != null && suv.Account__r.X1_app_in_the_last_24_months__c > 0 && suv.Account__r.Account_Total_CBR__c <= 250000)) {
                        insertList.add (new Dealer_Surveillance__c (Account__c = suv.Account__c
                                                             , Status__c = 'Completed'
                                                             , Review_Date__c = todayDate
                                                             , Assigned_To__c = informaticaUserId
                                                             , Recommended_Action__c = 'Approved'
                                                             , Additional_Review_Comments__c = 'Meets acceptable criteria, auto-approved.'
                                                             , Recommended_Next_Review__c = '12 mos'
                                                             , Next_Scheduled_Review__c = todayDate.addYears(1)
                                                             , Review_Type__c = 'Scheduled Review'
                                                             , Waiting_To_Be_Sent_To_Bridgeware__c = true
                                                             , Created_via_Batch__c = true));
					} else {
                        insertList.add (new Dealer_Surveillance__c (Account__c = suv.Account__c
                                                             , Status__c = 'In Process'
                                                             , Review_Type__c = 'Scheduled Review'
                                                             , Waiting_To_Be_Sent_To_Bridgeware__c = true
                                                             , Created_via_Batch__c = true));
                            
					}*/
                    
                    
                    String model = reviewResults.get (suv.Account__c);
                    
                    System.debug ('?????  model:' + model + ' ' + reviewer.getModelIdByName (model));
                    
                    if (String.isBlank (model)) {
                        // no model match
                        insertList.add (new Dealer_Surveillance__c (Account__c = suv.Account__c
                                                             , Status__c = 'In Process'
                                                             , Review_Type__c = 'Scheduled Review'
                                                             , Waiting_To_Be_Sent_To_Bridgeware__c = true
                                                             , Created_via_Batch__c = true
                                                             , Dealer_Surveillance__c = 'Scheduled Review'));
                    } else {
                        // model match
                        insertList.add (new Dealer_Surveillance__c (Account__c = suv.Account__c
                                                             , Status__c = 'Completed'
                                                             , Completed_By_Auto_Process__c = true
                                                             , Review_Date__c = todayDate
                                                             , Assigned_To__c = informaticaUserId
                                                             , Recommended_Action__c = 'Approved'
                                                             , Additional_Review_Comments__c = 'Meets acceptable criteria, auto-approved.'
                                                             , Recommended_Next_Review__c = '12 mos'
                                                             , Next_Scheduled_Review__c = todayDate.addYears(1)
                                                             , Review_Type__c = 'Scheduled Review'
                                                             , Waiting_To_Be_Sent_To_Bridgeware__c = true
                                                             , Created_via_Batch__c = true
                                                             , Model_Hit__c = reviewer.getModelIdByName (model)
                                                             , Dealer_Surveillance__c = 'Scheduled Review'));
                    }
                    
                    
                    // old
                    allCompleted.put (suv.Account__c, false);
                } else {
                    // update today's in process ones to complete if they hit a threshhold
                    /*for (Dealer_Surveillance__c suv : acc.Dealer_Surveillances__r) {
                        if (suv.Next_Scheduled_Review__c == todayDate && suv.Review_Type__c == 'Scheduled Review') {
                            updateList.add (new Dealer_Surveillance__c (Id = suv.Id
                                                                        , Status__c = 'Completed'
                                                                        , Waiting_To_Be_Sent_To_Bridgeware__c = true
																		, Model_Hit__c = reviewer.getModelIdByName (model)));
                        }
                    }*/
                }
            }
            if (!insertList.isEmpty ()) insert insertList;
        }
    } 

    public void finish(Database.BatchableContext bc) {
        System.debug('>>> finish TC_DealerSurveillanceBatch');
    }
    
    /* old dealer surv code
    public static Date todayDate = Date.today();
     
    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('>>> Start TC_DealerSurveillanceBatch');
        
        String query = 'SELECT Id, Account__c, Account__r.X1_app_in_the_last_12_months__c, Account__r.Actual_Vs_Projected_Loss__c, Account__r.Account_Percentage31__c, Account__r.Account_Total_CBR__c, Account__r.X1_app_in_the_last_24_months__c, Account__r.Portfolio_Review_Threshold__c, Account__r.Account_Dealer_LTD_Volume__c, Account__r.Surveillances_Incomplete__c from Dealer_Surveillance__c WHERE Next_Scheduled_Review__c = TODAY';
        return Database.getQueryLocator(query);
    }
    
    public void execute (Database.BatchableContext bc, List<Dealer_Surveillance__c> suvs) {
        
        List <Account> accounts = new List <Account> ();
        if (!suvs.isEmpty ()) {
            Set <Id> accIds = new Set <Id> ();
            
            for (Dealer_Surveillance__c suv :suvs) {
                accIds.add (suv.Account__c);
            }
            accounts = new List <Account> ([SELECT Id, X1_app_in_the_last_12_months__c, Actual_Vs_Projected_Loss__c, Account_Percentage31__c, Account_Total_CBR__c, X1_app_in_the_last_24_months__c, Portfolio_Review_Threshold__c, Account_Dealer_LTD_Volume__c, (SELECT Id, Status__c FROM Dealer_Surveillances__r) FROM Account WHERE Id IN :accIds]);
        }
        
        Id informaticaUserId = [SELECT Id FROM User WHERE FirstName = 'User' AND LastName = 'Informatica'][0].Id;
        
        Map <Id, Boolean> allCompleted = new Map <Id, Boolean> ();
        List <Dealer_Surveillance__c> insertList = new List <Dealer_Surveillance__c> ();

        if (!accounts.isEmpty ()) {
            //List <Dealer_Surveillance__c> suvs = new List <Dealer_Surveillance__c> ();
            
            
            // need to see if sibling records are incomplete, need query out of the batch to get latest records
            for (Account acc : accounts) {
                
                Boolean allSUVSCompleted = true;
                
                
                if (!acc.Dealer_Surveillances__r.isEmpty()) {
                    for (Dealer_Surveillance__c suv : acc.Dealer_Surveillances__r) {
                        if (suv.Status__c != 'Completed') allSUVSCompleted = false;
                    }
                }
                allCompleted.put (acc.id, allSUVSCompleted);
                
                
                if (allSUVSCompleted) {
                    // new logic
                    if ((acc.X1_app_in_the_last_12_months__c > 0 && acc.Actual_Vs_Projected_Loss__c <= 150 && acc.Account_Percentage31__c <= 3 && acc.Account_Total_CBR__c <= 750000)
                        || (acc.X1_app_in_the_last_24_months__c > 0 && acc.Account_Total_CBR__c <= 250000)) {
                        suvs.add (new Dealer_Surveillance__c (Account__c = acc.Id
                                                             , Status__c = 'Completed'
                                                             , Review_Date__c = todayDate
                                                             , Assigned_To__c = informaticaUserId
                                                             , Recommended_Action__c = 'Approved'
                                                             , Additional_Review_Comments__c = 'Meets acceptable criteria, auto-approved.'
                                                             , Recommended_Next_Review__c = '12 mos'
                                                             , Next_Scheduled_Review__c = todayDate.addYears(1)
                                                             , Review_Type__c = 'Scheduled Review'
                                                             , Waiting_To_Be_Sent_To_Bridgeware__c = true
                                                             , Created_via_Batch__c = true));
					} else {
                        suvs.add (new Dealer_Surveillance__c (Account__c = acc.Id
                                                             , Status__c = 'In Process'
                                                             , Review_Type__c = 'Scheduled Review'
                                                             , Waiting_To_Be_Sent_To_Bridgeware__c = true
                                                             , Created_via_Batch__c = true));
                            
					}
                    
                }
            }
            
            for (Dealer_Surveillance__c suv : suvs) {
                // all siblings don't have incomplete suvs
                if (allCompleted != null && allCompleted.get (suv.Account__c) == true) {
                    if ((suv.Account__c != null && suv.Account__r.X1_app_in_the_last_12_months__c > 0 && suv.Account__r.Actual_Vs_Projected_Loss__c <= 150 && suv.Account__r.Account_Percentage31__c <= 3 && suv.Account__r.Account_Total_CBR__c <= 750000)
                        || (suv.Account__c != null && suv.Account__r.X1_app_in_the_last_24_months__c > 0 && suv.Account__r.Account_Total_CBR__c <= 250000)) {
                        insertList.add (new Dealer_Surveillance__c (Account__c = suv.Account__c
                                                             , Status__c = 'Completed'
                                                             , Review_Date__c = todayDate
                                                             , Assigned_To__c = informaticaUserId
                                                             , Recommended_Action__c = 'Approved'
                                                             , Additional_Review_Comments__c = 'Meets acceptable criteria, auto-approved.'
                                                             , Recommended_Next_Review__c = '12 mos'
                                                             , Next_Scheduled_Review__c = todayDate.addYears(1)
                                                             , Review_Type__c = 'Scheduled Review'
                                                             , Waiting_To_Be_Sent_To_Bridgeware__c = true
                                                             , Created_via_Batch__c = true));
					} else {
                        insertList.add (new Dealer_Surveillance__c (Account__c = suv.Account__c
                                                             , Status__c = 'In Process'
                                                             , Review_Type__c = 'Scheduled Review'
                                                             , Waiting_To_Be_Sent_To_Bridgeware__c = true
                                                             , Created_via_Batch__c = true));
                            
					}
                    allCompleted.put (suv.Account__c, false);
                }
            }
            if (!insertList.isEmpty ()) insert insertList;
        }
    } 

    public void finish(Database.BatchableContext bc) {
        System.debug('>>> finish TC_DealerSurveillanceBatch');
    }*/
     
    
    


}