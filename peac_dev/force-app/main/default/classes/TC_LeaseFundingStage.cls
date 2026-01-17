public class TC_LeaseFundingStage {
public static void leaseFundingStage (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
        
        Id LEASE_RT_ID = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Lease Payment').getRecordTypeId();
        Id LOAN_RT_ID = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Loan Payment').getRecordTypeId();

        String defaultXbsPayeeId = null;
        LIst<XBS_Payee__mdt> xbsPayees = [SELECT PayeeId__c FROM XBS_Payee__mdt WHERE Label = 'PayeeId'];
        if(xbsPayees.size() > 0){
            defaultXbsPayeeId = xbsPayees[0].PayeeId__c;
        }
        Set <Id> fundingLeaseIds = new Set <Id> ();
        
        for (Opportunity opp : newMap.values ()) {
            if (opp.StageName != oldMap.get (opp.Id).StageName && opp.StageName == 'Funding' && !opp.Loan_Record_Type__c) {
                fundingLeaseIds.add (opp.Id);
            }
        }
        if (!fundingLeaseIds.isEmpty ()) {
            Map <String, Dealer__c> dealers = new Map <String, Dealer__c> ();
            Map <Id, Set<String>> oppPayeeMap = new Map <Id, Set<String>> ();
            
            // for (Opportunity opp : [SELECT Id, (SELECT Payee__r.Payee_ID__c FROM Payments__r) FROM Opportunity WHERE Id IN :fundingLeaseIds]) {
            //     Set<String> payeeSet = new Set<String> ();
            //     oppPayeeMap.put (opp.Id, payeeSet);
                
            //     for (Payment__c p : opp.Payments__r)
            //         payeeSet.add (p.Payee__r.Payee_ID__c);
            // }
            
            for (Dealer__c dealer : [SELECT Id, Dealer__r.Dealer_Number__c, Opportunity__c, Opportunity__r.Equipment_Cost__c, Opportunity__r.Equipment_Cost_w_o_Tax__c, Opportunity__r.Loan_Record_Type__c FROM Dealer__c WHERE Opportunity__c IN :fundingLeaseIds AND Primary_Dealer__c = true AND Dealer__r.Dealer_Number__c != null]) {
                if (oppPayeeMap.get (dealer.Opportunity__c) == null || !oppPayeeMap.get (dealer.Opportunity__c).contains (dealer.Dealer__r.Dealer_Number__c.replace ('.','')))
                    dealers.put (dealer.Dealer__r.Dealer_Number__c.contains ('.') ? dealer.Dealer__r.Dealer_Number__c.replace ('.','') : dealer.Dealer__r.Dealer_Number__c, dealer);
            }
            
            if (dealers.size() == 1) {
                Map <String, Payee__c> payees = new Map <String, Payee__c> ();
                Map <String, Payment__c> payments = new Map <String, Payment__c> ();
                Boolean multiplePayments = false;
                List<Payment__c> existingPayments = [SELECT Id, Payee__c FROM Payment__c WHERE Opportunity__c IN :fundingLeaseIds ];
                Map <ID, Payment__c> existingPaymentsPayeesMap = new Map <ID, Payment__c> ();
                for (Payment__c payment : existingPayments) {
                    existingPaymentsPayeesMap.put (payment.Payee__c, payment);
                }
                
                for (Payee__c payee : [SELECT Id, Payee_ID__c, Default_Pay_Type__c 
                    FROM Payee__c WHERE (Payee_ID__c IN :dealers.keySet() OR Id = :defaultXbsPayeeId) AND Active__c = TRUE 
                        AND (NOT Payee_Name__c LIKE '%Not Use%') ORDER BY CreatedDate DESC]) {
                    Dealer__c theDealer = null;
                    Boolean isXBSOpp; 
                    isXBSOpp= newMap.get(dealers.values()[0].Opportunity__c) != null && newMap.get(dealers.values()[0].Opportunity__c).Program__c != null
                        && newMap.get(dealers.values()[0].Opportunity__c).Program__c.Contains('XBS');
                    if(isXBSOpp &&  payee.Id == defaultXbsPayeeId){
                            theDealer = dealers.values()[0];
                            if(payments.containsKey(payee.Payee_ID__c)) multiplePayments = true;
                    }else{
                        if(payments.containsKey(payee.Payee_ID__c)){
                            multiplePayments = true;
                        }
                        if(!isXBSOpp){
                        theDealer = dealers.get(payee.Payee_ID__c);
                    }
                    }
                    if(theDealer != null && !existingPaymentsPayeesMap.containsKey(payee.Id)){
                        payments.put (payee.Payee_ID__c, new Payment__c (Payee__c = payee.Id, 
                            Payment_Method__c = payee.Default_Pay_Type__c, 
                            Amount_Financed__c = theDealer.Opportunity__r.Equipment_Cost_w_o_Tax__c, 
                            RecordTypeId = theDealer.Opportunity__r.Loan_Record_Type__c ? LOAN_RT_ID : LEASE_RT_ID, 
                            Opportunity__c = theDealer.Opportunity__c));
                    }
                }

                if (!payments.isEmpty () && !multiplePayments) {
                    insert payments.values ();
                }    
            }
        }
    }
}