public class TC_CheckAssociatedDealersAreApproved {
public static void checkAssociatedDealersAreApproved(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap, 
    Map<Id, Dealer__c> dealers, Map<Id, Broker__c> brokers, Map<Id, Franchisor__c> franchisors) {
        
        
        // andrew add
        
        List <Opportunity> submittedToCMS = new List <Opportunity> ();
        
        for (Opportunity opp : newMap.values ()) {
            if (!opp.Loan_Record_Type__c && ((opp.Docs_In__c != null && oldMap.get (opp.Id).Docs_In__c == null
                 && (opp.Branch__c == 'OEG/NATIONAL'
                     || opp.Branch__c == 'OEG - Major Accounts'
                     || opp.Branch__c == 'Office Equip Group-OEG'
                     || opp.Branch__c == 'IFP - Indirect Funding Pl'))
                || (opp.Ready_to_Doc__c == 'Yes' && oldMap.get (opp.Id).Ready_to_Doc__c != 'Yes'))) {
                    submittedToCMS.add (opp);
                }
        }
        
        if (submittedToCMS.isEmpty ()) return;
        // end andrew add
        
        // Defines all the values which mean Approved
        // Added 'Need Signed Agreement – Svc Based' to approved values per SAL-2904
        Map<String, String> definedApprovedValues = new Map<String, String>{
            'Approved' => 'Approved',
                'Active' => 'Active',
                'Existing EU only' => 'Existing EU only',
                '1-time Need Profile Unused' => '1-time Need Profile Unused',
                '1-time Reject Unused' => '1-time Reject Unused',
                'Watch List' => 'Watch List',
                'Need Signed Agreement' => 'Need Signed Agreement',
                '1x Exception' => '1x Exception',
                'Need Signed Agreement – Svc Based' => 'Need Signed Agreement – Svc Based'
                };
                    
                    // Get every dealer and broker associated with the opportunities in newMap
                    Map<String, List<Dealer__c>> oppDealerMap = new Map<String, List<Dealer__c>>();
        Map<String, List<Broker__c>> oppBrokerMap = new Map<String, List<Broker__c>>();
        Map<String, List<Franchisor__c>> oppFranchisorMap = new Map<String, List<Franchisor__c>>();
        for (Opportunity opp : newMap.values()) {
            List<Dealer__c> dealersPerOpp = new List<Dealer__c>();
            List<Broker__c> brokersPerOpp = new List<Broker__c>();
            List<Franchisor__c> franchisorsPerOpp = new List<Franchisor__c>();
            for(Dealer__c dealer : dealers.values()){
                if(dealer.Opportunity__c == opp.Id){
                    dealersPerOpp.add(dealer);
                }
            }
            for(Broker__c broker : brokers.values()){
                if(broker.Opportunity__c == opp.Id){
                    brokersPerOpp.add(broker);
                }
            }
            for(Franchisor__c franchisor : franchisors.values()){
                if(franchisor.Opportunity__c == opp.Id){
                    franchisorsPerOpp.add(franchisor);
                }
            }
            oppDealerMap.put(opp.Id, dealersPerOpp);
            oppBrokerMap.put(opp.Id, brokersPerOpp);
            oppFranchisorMap.put(opp.Id , franchisorsPerOpp);
        }
        System.debug('oppDealerMapOOO'+oppDealerMap);
        
        for (Opportunity opp : submittedToCMS) {
            
                System.debug('Call check Test');
                System.debug('Call check????////'+opp.Docs_In__c );
                System.debug('Call Branch????////'+opp.Branch__c );
                switch on opp.Branch__c {
                    when 'OEG/NATIONAL' {
                        System.debug('Call check nmnmnmn');
                        if (opp.Docs_In__c <> null) {
                            if(oppDealerMap.containsKey(opp.Id)){
                                for (Dealer__c dealer : oppDealerMap.get(opp.Id)) {
                                    if (definedApprovedValues.get(dealer.Dealer__r.Account_Dealer_Status__c) == null) {
                                        System.debug('Call check2');
                                        opp.addError('All dealers must be approved!');
                                    }
                                }
                            }
                        }
                    }
                    
                    when 'OEG - Major Accounts' {
                        if (opp.Docs_In__c <> null) {
                            if(oppDealerMap.containsKey(opp.Id)){
                                for (Dealer__c dealer : oppDealerMap.get(opp.Id)) {
                                    if (definedApprovedValues.get(dealer.Dealer__r.Account_Dealer_Status__c) == null) {
                                        System.debug('Call check2');
                                        opp.addError('All dealers must be approved!');
                                    }
                                }
                            }
                        }
                    }
                    when'Office Equip Group-OEG'{
                        if (opp.Docs_In__c <> null) {
                            if(oppDealerMap.containsKey(opp.Id)){
                                for (Dealer__c dealer : oppDealerMap.get(opp.Id)) {
                                    if (definedApprovedValues.get(dealer.Dealer__r.Account_Dealer_Status__c) == null) {
                                        opp.addError('All dealers must be approved!');
                                    }
                                }
                            }
                        }
                    }
                    
                    when 'IFP - Indirect Funding Pl' {
                        if (opp.Docs_In__c <> null) {
                            if(oppDealerMap.containsKey(opp.Id)){
                                for (Dealer__c dealer : oppDealerMap.get(opp.Id)) {
                                    if (definedApprovedValues.get(dealer.Dealer__r.Account_Dealer_Status__c) == null) {
                                        opp.addError('All dealers must be approved!');
                                    }
                                }
                            }
                            if(oppBrokerMap.containsKey(opp.Id)){
                                for (Broker__c broker : oppBrokerMap.get(opp.Id)) {
                                    if (definedApprovedValues.get(broker.Account__r.Account_Dealer_Status__c) == null) {
                                        opp.addError('All brokers must be approved!');
                                    }
                                }
                            }
                        }
                    }
                    when 'Franchise' {
                        if (opp.Ready_to_Doc__c == 'Yes' && !opp.Program_Type__c.contains('Loan')) {
                            System.debug('Call check Test2222');
                            if(oppDealerMap.containsKey(opp.Id)){
                                for (Dealer__c dealer : oppDealerMap.get(opp.Id)) {
                                    if (definedApprovedValues.get(dealer.Dealer__r.Account_Dealer_Status__c) == null) {
                                        opp.addError('All dealers must be approved!');
                                    }
                                }
                            }
                            if(oppFranchisorMap.containsKey(opp.Id)){
                                for (Franchisor__c Fran : oppFranchisorMap.get(opp.Id)) {
                                    if (definedApprovedValues.get(Fran.Franchisor__r.Account_Dealer_Status__c) == null) {
                                        opp.addError('All Franchisors must be approved!');
                                    }
                                }
                            }
                        }
                    }
                    when else {
                        if (opp.Ready_to_Doc__c == 'Yes') {
                            if(oppDealerMap.containsKey(opp.Id)){
                                for (Dealer__c dealer : oppDealerMap.get(opp.Id)) {
                                    if (definedApprovedValues.get(dealer.Dealer__r.Account_Dealer_Status__c) == null) {
                                        opp.addError('All dealers must be approved!');
                                    }
                                }
                            }
                        }
                    }
                    
                }
        }
    }
}