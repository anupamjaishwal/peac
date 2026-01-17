public class TC_AutoCreateLoanPaymentRecords {
public static Set<Id> autoCreateLoanPaymentRecordsRanOppIds = new Set <Id> ();
    
    public static void autoCreateLoanPaymentRecords(Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
        
        Set <Id> oppIds = new Set <Id> ();
        
        for (Opportunity opp : newMap.values()) {
            if (opp.Loan_Record_Type__c && opp.StageName == 'Review for Booking' && oldMap.get(opp.Id).StageName == 'Docs In' && !autoCreateLoanPaymentRecordsRanOppIds.contains(opp.Id)) {
                oppIds.add(opp.Id);
                autoCreateLoanPaymentRecordsRanOppIds.add(opp.Id);
            }
        }
        
        if (!oppIds.isEmpty()) {
            
            //            Map <Id, Opportunity> oppMap = new Map <Id, Opportunity> ([SELECT Id, Account.Tax_ID__c, Primary_Broker__r.Dealer_Number__c, Contract__c, Origination_Fee__c, Loan_Amount__c, Loan_Points_Amount__c FROM Opportunity WHERE Id IN :oppIds]);
            Map <Id, Opportunity> oppMap = new Map <Id, Opportunity> ([SELECT Id, Account.Tax_ID__c, Contract__c, Origination_Fee__c, Loan_Amount__c, Loan_Points_Amount__c, (SELECT Id, Account__c, Account__r.Dealer_Number__c FROM Brokers1__r) FROM Opportunity WHERE Id IN :oppIds]);
            Map <Id, String> oppIdsToTaxIds = new Map <Id, String> ();
            //            Map <Id, String> oppIdsToDealerNumbers = new Map <Id, String> ();
            Map <Id, List <String>> oppIdsToDealerNumbers = new Map <Id, List <String>> ();
            Set <String> dealerNumberSet = new Set <String> ();
            
            for (Opportunity opp : oppMap.values()) {
                if (opp.Account.Tax_ID__c != null) oppIdsToTaxIds.put(opp.Id, opp.Account.Tax_ID__c.replaceAll('[^0-9]', ''));
                //                if (opp.Primary_Broker__r.Dealer_Number__c != null) oppIdsToDealerNumbers.put(opp.Id, opp.Primary_Broker__r.Dealer_Number__c.replaceAll('[^0-9]', ''));
                if (!opp.Brokers1__r.isEmpty()){
                    for (Broker__c b : opp.Brokers1__r){
                        if (b.Account__c != null && b.Account__r.Dealer_Number__c != null){
                            if (oppIdsToDealerNumbers.get(opp.Id) == null){
                                oppIdsToDealerNumbers.put(opp.Id, new List <String> {b.Account__r.Dealer_Number__c.replaceAll('[^0-9]', '')});
                            }else{
                                oppIdsToDealerNumbers.get(opp.Id).add(b.Account__r.Dealer_Number__c.replaceAll('[^0-9]', ''));
                            }
                            dealerNumberSet.add(b.Account__r.Dealer_Number__c.replaceAll('[^0-9]', ''));
                        }
                    }
                }
            }
            
            Boolean multiplePayeesFound;
            
            Id loanPaymentRecordTypeId = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Loan Payment').getRecordTypeId(); // would like to use getRecordTypesByDeveloperName instead, but that method isn't available in this API version used by this class.
            
            // Tax Ids
            
            Map <Id, Payment__c> oppIdsToTaxIdPayments = new Map <Id, Payment__c> ();
            
            if (!oppIdsToTaxIds.isEmpty()) {
                List <Payee__c> payeesByTaxIDs = [SELECT Id, Tax_ID_Nbr__c FROM Payee__c WHERE Tax_Id_Nbr_Digits__c IN :oppIdsToTaxIds.values()];
                
                if (!payeesByTaxIDs.isEmpty()) {
                    for (Id oppId : oppIdsToTaxIds.keySet()) {
                        multiplePayeesFound = false;
                        Integer i = 0;
                        
                        while (!multiplePayeesFound && i < payeesByTaxIDs.size()) {
                            
                            if (oppIdsToTaxIds.get(oppId) == payeesByTaxIDs[i].Tax_ID_Nbr__c.replaceAll('[^0-9]', '')) {
                                if (oppIdsToTaxIdPayments.get(oppId) == null) {
                                    //Need to make sure the fee is rounded to 2 decimal places for Solomon integration SAL-689
                                    Decimal lessOriginationFee = oppMap.get(oppId).Origination_Fee__c == 0 ? null : oppMap.get(oppId).Origination_Fee__c * oppMap.get(oppId).Loan_Amount__c * 0.01;
                                    if (lessOriginationFee != null) lessOriginationFee = lessOriginationFee.setScale(2, System.RoundingMode.HALF_UP);
                                    
                                    oppIdsToTaxIdPayments.put(oppId, new Payment__c(
                                        Payee__c = payeesByTaxIDs[i].Id,
                                        Loan_Amount__c = (oppMap.get(oppId).Loan_Amount__c == 0 ? null : oppMap.get(oppId).Loan_Amount__c),
                                        Payment_Status__c = 'Draft',
                                        Payment_Method__c = 'ACH',
                                        Invoice_Number__c = oppMap.get(oppId).Contract__c,
                                        Less_Origination_Fee__c = lessOriginationFee, //SAL-689
                                        Opportunity__c = oppId,
                                        RecordTypeId = loanPaymentRecordTypeId
                                    ));
                                } else {
                                    multiplePayeesFound = true;
                                    oppIdsToTaxIdPayments.remove(oppId);
                                }
                            }
                            i++;
                        }
                    }
                }
            }
            
            // Dealer Numbers
            
            Map <Id, Map <String, Payment__c>> oppIdsToDealerNumberPayments = new Map <Id, Map <String, Payment__c>> ();
            
            if (!oppIdsToDealerNumbers.isEmpty()) {
                List <Payee__c> payeesByDealerNumbers = [SELECT Id, Payee_ID__c FROM Payee__c WHERE Payee_ID_Digits__c IN :dealerNumberSet];
                
                if (!payeesByDealerNumbers.isEmpty()) {
                    for (Id oppId : oppIdsToDealerNumbers.keySet()) {
                        //Need to make sure the fee is rounded to 2 decimal places for Solomon integration SAL-689
                        Decimal lessOriginationFee = oppMap.get(oppId).Origination_Fee__c == 0 ? null : oppMap.get(oppId).Origination_Fee__c * oppMap.get(oppId).Loan_Amount__c * 0.01;
                        
                        for (String dealerNumberString : oppIdsToDealerNumbers.get(oppId)) {
                            
                            multiplePayeesFound = false;
                            Integer i = 0;
                            
                            while (!multiplePayeesFound && i < payeesByDealerNumbers.size()) {
                                
                                if (dealerNumberString == payeesByDealerNumbers[i].Payee_ID__c.replaceAll('[^0-9]', '') && oppMap.get(oppId).Loan_Points_Amount__c > 0) {
                                    if (oppIdsToDealerNumberPayments.get(oppId) == null) {
                                        
                                        if (lessOriginationFee != null) lessOriginationFee = lessOriginationFee.setScale(2, System.RoundingMode.HALF_UP);
                                        
                                        oppIdsToDealerNumberPayments.put(oppId, new Map<String, Payment__c>{
                                            dealerNumberString =>
                                                new Payment__c(
                                                    Payee__c = payeesByDealerNumbers[i].Id,
                                                    Plus_Commission__c = (oppMap.get(oppId).Loan_Points_Amount__c == 0 ? null : oppMap.get(oppId).Loan_Points_Amount__c),
                                                    Payment_Status__c = 'Draft',
                                                    Payment_Method__c = 'ACH',
                                                    Invoice_Number__c = oppMap.get(oppId).Contract__c,
                                                    //Less_Origination_Fee__c = lessOriginationFee, //SAL-689 // commented for SAL-1801
                                                    Opportunity__c = oppId,
                                                    RecordTypeId = loanPaymentRecordTypeId
                                                )
                                                });
                                    } else if (oppIdsToDealerNumberPayments.get(oppId).get(dealerNumberString) == null){
                                        oppIdsToDealerNumberPayments.get(oppId).put(dealerNumberString, new Payment__c(
                                            Payee__c = payeesByDealerNumbers[i].Id,
                                            Plus_Commission__c = (oppMap.get(oppId).Loan_Points_Amount__c == 0 ? null : oppMap.get(oppId).Loan_Points_Amount__c),
                                            Payment_Status__c = 'Draft',
                                            Payment_Method__c = 'ACH',
                                            Invoice_Number__c = oppMap.get(oppId).Contract__c,
                                            //Less_Origination_Fee__c = lessOriginationFee, //SAL-689 // commented for SAL-1801
                                            Opportunity__c = oppId,
                                            RecordTypeId = loanPaymentRecordTypeId
                                        ));
                                    } else {
                                        multiplePayeesFound = true;
                                        oppIdsToDealerNumberPayments.get(oppId).remove(dealerNumberString);
                                    }
                                }
                                i++;
                            }
                        }
                    }
                }
            }
            
            if (!(oppIdsToDealerNumberPayments.isEmpty() && oppIdsToTaxIdPayments.isEmpty())) {
                List <Payment__c> newPayments = new List <Payment__c> ();
                //                newPayments.addAll(oppIdsToDealerNumberPayments.values());
                for (Map <String, Payment__c> m : oppIdsToDealerNumberPayments.values()){
                    if (!m.isEmpty()) newPayments.addAll(m.values());
                }
                
                newPayments.addAll(oppIdsToTaxIdPayments.values());
                insert newPayments;
            }
        }
    }
    
}