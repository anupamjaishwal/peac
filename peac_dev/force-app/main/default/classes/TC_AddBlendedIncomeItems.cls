public class TC_AddBlendedIncomeItems {
    public static Marlin_Configuration__c config = Marlin_Configuration__c.getOrgDefaults ();
    public static void addBlendedIncomeItems(Map <Id, Opportunity> newMap, Set<Id> oppsMovedToBooking, Map<Id, List<Blended_Income_Item__c>> blendedIncomeItems,
        Set<Id> oppsChangedInterimRent, Map <Id, Dealer__c> dealers) {
        
        Set <Id> oppIds = new Set <Id> ();
        Map <String, Blended_Income_Item__c> upsertBII = new Map <String, Blended_Income_Item__c> ();
        List<Blended_Income_Item__c> biisToDelete = new List<Blended_Income_Item__c>();
        for(Opportunity opp : newMap.values ()) {
            if(!opp.Loan_Record_Type__c && opp.StageName == 'Booking' && (oppsMovedToBooking.contains(opp.Id) || oppsChangedInterimRent.contains(opp.Id))
                && opp.Lessor__c != null && !TC_RecursiveTriggerHelper.oppsAlreadyBiiAdded.contains(opp.Id)) {
                TC_RecursiveTriggerHelper.oppsAlreadyBiiAdded.add(opp.Id);
                Account dealerAccount = dealers.get(opp.Primary_Dealer__c)?.Dealer__r;
                Decimal percentageToDealer = dealerAccount?.Interim_Rent_Dealer_Percentage__c != null?
                                dealerAccount.Interim_Rent_Dealer_Percentage__c: 0;
                Decimal leasePaymentInterimRent = opp.Lease_Payment_Interim_Rent__c != null? opp.Lease_Payment_Interim_Rent__c: 0;
                Decimal interimRent = dealerAccount?.Preferred_Dealer_Level__c == null? opp.Interim_Rent__c: 
                    leasePaymentInterimRent * ((100 - percentageToDealer) / 100);
                TC_CheckAndCreateBlendedIncomeItems.checkAndCreateBlendedIncomeItems('0005', interimRent, opp.Id, upsertBII);
                Boolean isRentalLease = opp.Contract_Type__c.equalsIgnoreCase('RL');
                
                Integer salaryAmount = -Integer.valueOf(isRentalLease ? config.Loan_Salary_Amount__c : config.Lease_Salary_Amount__c);
                Integer oppAmount = -Integer.valueOf(isRentalLease ? config.Loan_Operating_Expense_Amount__c : config.Lease_Operating_Expense_Amount__c);
                
                //Update for GL Issue#784 JAH
                //Lessor not 409
                if (opp.Lessor__c != 409) {
                    TC_CheckAndCreateBlendedIncomeItems.checkAndCreateBlendedIncomeItems('0001', salaryAmount, opp.Id, upsertBII);                //IDC - Salaries
                    TC_CheckAndCreateBlendedIncomeItems.checkAndCreateBlendedIncomeItems('0002', oppAmount, opp.Id, upsertBII);                   //IDC - Operating Expenses
                    TC_CheckAndCreateBlendedIncomeItems.checkAndCreateBlendedIncomeItems('0003', opp.Broker_Fees__c != null ? -1 * opp.Broker_Fees__c : null, opp.Id, upsertBII);         //Broker Fees
                    TC_CheckAndCreateBlendedIncomeItems.checkAndCreateBlendedIncomeItems('0004', opp.Documentation_Fee__c , opp.Id, upsertBII);   //Doc Fees
                }
                // Lessor is 409
                else if (opp.Lessor__c == 409) {
                    TC_CheckAndCreateBlendedIncomeItems.checkAndCreateBlendedIncomeItems('0026', opp.Broker_Fees__c != null ? -1 * opp.Broker_Fees__c : null, opp.Id, upsertBII);         //Fran Loan Broker Fees
                    TC_CheckAndCreateBlendedIncomeItems.checkAndCreateBlendedIncomeItems('0027', salaryAmount, opp.Id, upsertBII);                        //Fran Loan DEF SAL
                    TC_CheckAndCreateBlendedIncomeItems.checkAndCreateBlendedIncomeItems('0028', oppAmount, opp.Id, upsertBII);                           //Fran Loan DEF Oper
                    TC_CheckAndCreateBlendedIncomeItems.checkAndCreateBlendedIncomeItems('0029', opp.Documentation_Fee__c , opp.Id, upsertBII);   //Fran Loan Doc Fee
                }

                List<Blended_Income_Item__c> existingBIIs = blendedIncomeItems.get(opp.Id);
                if(existingBIIs != null && existingBIIs.size() > 0){
                    
                    for(Blended_Income_Item__c existingBii :existingBIIs){
                        Boolean willDeleteBii = true;
                        for(Blended_Income_Item__c biiToUpsert : upsertBII.values()){
                            if(biiToUpsert.Opportunity__c == opp.Id){
                                if((existingBii.Generated_Code__c != null && existingBii.Generated_Code__c == biiToUpsert.Generated_Code__c)
                                || (existingBii.Blended_Income_Code__c == biiToUpsert.Blended_Income_Code__c 
                                && existingBii.Blended_Income_Amount__c == biiToUpsert.Blended_Income_Amount__c)){
                                    biiToUpsert.Id = existingBii.Id;
                                    willDeleteBii = false;
                                    break;
                                }
                            }
                        }
                        if(willDeleteBii && existingBii.Generated_Code__c != null){
                            biisToDelete.add(existingBii);
                        }
                    }
                }
            }
        }
        if(!upsertBII.isEmpty()){
            upsert upsertBII.values();
        }
        if(biisToDelete.size() > 0){
            delete biisToDelete;
        }
    }

    // old kept for reference
    // public static void addBlendedIncomeItems (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
        
    //     Set <Id> oppIds = new Set <Id> ();
        
    //     for (Opportunity opp : newMap.values ()) {
    //         if (!opp.Loan_Record_Type__c && opp.StageName == 'Booking' && opp.StageName != oldMap.get (opp.Id).StageName && opp.Lessor__c != null) {
    //             oppIds.add (opp.Id);
    //         }
    //     }
    //     if (!oppIds.isEmpty ()) {
    //         List <Blended_Income_Item__c> items = new List <Blended_Income_Item__c> ([SELECT Id, Opportunity__c, Blended_Income_Code__c FROM Blended_Income_Item__c WHERE Opportunity__c IN :oppIds]);
    //         Map <String, Blended_Income_Item__c> blendedIncomeItems = new Map <String, Blended_Income_Item__c> ();
            
    //         for (Blended_Income_Item__c bi : items) {
    //             if (bi.Blended_Income_Code__c != null) blendedIncomeItems.put (bi.Opportunity__c + '#' + bi.Blended_Income_Code__c, bi);
                
    //         }
            
    //         for (Opportunity opp : newMap.values ()) {
    //             if (opp.Lessor__c != null) {
    //                 TC_CheckAndCreateBlendedIncomeItems.checkAndCreateBlendedIncomeItems ('0005', opp.Interim_Rent__c , opp.Id, blendedIncomeItems);
    //                 Boolean isRentalLease = opp.Contract_Type__c.equalsIgnoreCase('RL');
                    
    //                 Integer salaryAmount = -Integer.valueOf(isRentalLease ? config.Loan_Salary_Amount__c : config.Lease_Salary_Amount__c);
    //                 Integer oppAmount = -Integer.valueOf(isRentalLease ? config.Loan_Operating_Expense_Amount__c : config.Lease_Operating_Expense_Amount__c);
                    
    //                 //Update for GL Issue#784 JAH
    //                 //Lessor not 409
    //                 if (opp.Lessor__c != 409) {
    //                     TC_CheckAndCreateBlendedIncomeItems.checkAndCreateBlendedIncomeItems ('0001', salaryAmount, opp.Id, blendedIncomeItems);                //IDC - Salaries
    //                     TC_CheckAndCreateBlendedIncomeItems.checkAndCreateBlendedIncomeItems ('0002', oppAmount, opp.Id, blendedIncomeItems);                   //IDC - Operating Expenses
    //                     TC_CheckAndCreateBlendedIncomeItems.checkAndCreateBlendedIncomeItems ('0003', opp.Broker_Fees__c != null ? -1 * opp.Broker_Fees__c : null, opp.Id, blendedIncomeItems);         //Broker Fees
    //                     TC_CheckAndCreateBlendedIncomeItems.checkAndCreateBlendedIncomeItems ('0004', opp.Documentation_Fee__c , opp.Id, blendedIncomeItems);   //Doc Fees
    //                 }
    //                 // Lessor is 409
    //                 else if (opp.Lessor__c == 409) {
    //                     TC_CheckAndCreateBlendedIncomeItems.checkAndCreateBlendedIncomeItems ('0026', opp.Broker_Fees__c != null ? -1 * opp.Broker_Fees__c : null, opp.Id, blendedIncomeItems);         //Fran Loan Broker Fees
    //                     TC_CheckAndCreateBlendedIncomeItems.checkAndCreateBlendedIncomeItems ('0027', salaryAmount, opp.Id, blendedIncomeItems);                        //Fran Loan DEF SAL
    //                     TC_CheckAndCreateBlendedIncomeItems.checkAndCreateBlendedIncomeItems ('0028', oppAmount, opp.Id, blendedIncomeItems);                           //Fran Loan DEF Oper
    //                     TC_CheckAndCreateBlendedIncomeItems.checkAndCreateBlendedIncomeItems ('0029', opp.Documentation_Fee__c , opp.Id, blendedIncomeItems);   //Fran Loan Doc Fee
    //                 }
    //             }
    //         }
            
            
            
    //         if (!blendedIncomeItems.isEmpty ()) upsert blendedIncomeItems.values ();
    //     }
    // }
    
}