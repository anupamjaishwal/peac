public class TC_LeaseOpportunityDocsInStageValidation {
public static void leaseOpportunityDocsInStageValidation (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
        
        Set <Id> oppIds = new Set <Id> ();
        //        Id leaseOpportunityRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Lease Opportunity').getRecordTypeId();
        
        for (Opportunity opp : newMap.values()){
            if (opp.Loan_Record_Type__c == false && opp.StageName == 'Funding' && (oldMap == null || oldMap.get(opp.Id).StageName != 'Funding')) oppIds.add(opp.Id);
        }
        
        if (!oppIds.isEmpty()){
            Map <Id, Opportunity> oppMap = new Map <Id, Opportunity> ([SELECT Id,
                                                                       
                                                                       (SELECT Id, Dealer__c, Dealer__r.RecordTypeId, Dealer__r.RecordType.Name, Dealer__r.Account_Dealer_Status__c FROM Brokers__r),
                                                                       (SELECT Id, Account__c, Account__r.RecordTypeId, Account__r.RecordType.Name, Account__r.Account_Dealer_Status__c FROM Brokers1__r),
                                                                       (SELECT Id, Franchisor__c, Franchisor__r.RecordTypeId, Franchisor__r.RecordType.Name, Franchisor__r.Account_Dealer_Status__c FROM Franchisors__r)
                                                                       
                                                                       FROM Opportunity WHERE Id IN :oppIds]);
            
            if (!oppMap.isEmpty()){
                Set <Id> oppIdErrorSet = new Set <Id> ();
                //                Set <Id> accRecordTypeIds = new Set <Id> {Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId(), Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker Account').getRecordTypeId(), Schema.SObjectType.Account.getRecordTypeInfosByName().get('Franchisor Account').getRecordTypeId()};
                //Removing 'Need Signed Agreement' and 'Need Signed Agreement – Svc Based' from the forbidden statuses per SAL-2904                
                //Added 'Pre-Qualified' per SAL-3213 
                Set <String> accDealerStatusStrings = new Set <String>{
                    'Pending', '1-time Reject Used', 'Cut-off', 'Duplicate Dealer', 'Equipment Info Requested', 'OOB', 'Rejected', 'Vendor Profile Requested', 'On Hold', 'More Info Requested', 'Pre-Qualified'
                };
                    
                    for (Opportunity opp : oppMap.values()){
                        Boolean errorFound = false;
                        
                        for (Dealer__c dealer : opp.Brokers__r){
                            if (dealer.Dealer__c != null && dealer.Dealer__r.RecordTypeId != null && (dealer.Dealer__r.RecordType.Name.contains('Dealer') || dealer.Dealer__r.RecordType.Name.contains('Broker') || dealer.Dealer__r.RecordType.Name.contains('Franchisor')) && accDealerStatusStrings.contains(dealer.Dealer__r.Account_Dealer_Status__c)){
                                oppIdErrorSet.add(opp.Id);
                                errorFound = true;
                                break;
                            }
                        }
                        
                        if (!errorFound){
                            for (Broker__c broker : opp.Brokers1__r){
                                if (broker.Account__c != null && broker.Account__r.RecordTypeId != null && (broker.Account__r.RecordType.Name.contains('Dealer') || broker.Account__r.RecordType.Name.contains('Broker') || broker.Account__r.RecordType.Name.contains('Franchisor')) && accDealerStatusStrings.contains(broker.Account__r.Account_Dealer_Status__c)){
                                    oppIdErrorSet.add(opp.Id);
                                    errorFound = true;
                                    break;
                                }
                            }
                        }
                        
                        if (!errorFound){
                            for (Franchisor__c franchisor : opp.Franchisors__r){
                                if (franchisor.Franchisor__c != null && franchisor.Franchisor__r.RecordTypeId != null && (franchisor.Franchisor__r.RecordType.Name.contains('Dealer') || franchisor.Franchisor__r.RecordType.Name.contains('Broker') || franchisor.Franchisor__r.RecordType.Name.contains('Franchisor')) && accDealerStatusStrings.contains(franchisor.Franchisor__r.Account_Dealer_Status__c)){
                                    oppIdErrorSet.add(opp.Id);
                                    break;
                                }
                            }
                        }
                    }
                
                if (!oppIdErrorSet.isEmpty()) {
                    for (Id oppId : oppIdErrorSet) {
                        newMap.get(oppId).addError('Opportunity cannot move to Funding stage; 1 or more related Dealers/Brokers/Franchisors have a restricted value in Dealer Status.');
                    }
                }
            }
        }
    }
}