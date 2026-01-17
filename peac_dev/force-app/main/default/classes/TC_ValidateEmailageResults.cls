public class TC_ValidateEmailageResults {
    public static void validateEmailageResults (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap, 
        Map<Id, Contact> primaryContacts, Map<Id, Guarantor__c> guarantors){
        
        Set <Id> oppIds = new Set <Id> ();
        List<Opportunity> oppList = new List<Opportunity>();
        
        Set <String> targetStages = new Set <String> {'Review for Booking', 'Funding', 'Booking', 'Booking (Loan)', 'Funding (Loan)', 'Funded/Booked'};
            
            for (Opportunity opp : newMap.values()){
                if (targetStages.contains(opp.StageName) && opp.StageName != oldMap.get(opp.Id).StageName){
                    oppIds.add(opp.Id);
                    oppList.add(opp);
                } 
            }
        
        if (oppList != null && !oppList.isEmpty()){
            
            Set <Id> leaseOppsWithErrors = new Set <Id> ();
                
                for (Opportunity opp : oppList){
                    
                    // check personal guarantors for both lease and loan opps
                    for(Guarantor__c guar : guarantors.values()){

                        if(guar.Opportunity__c == opp.Id && guar.Type__c == 'Personal Guarantor' && guar.Contact__c != null){
                        
                            if (TC_CheckContactEmailageResult.checkContactEmailageResult(guar.Contact__r.Emailage_Result__c, guar.Contact__r.Override_Emailage_Result__c)){
                                if (!opp.Loan_Record_Type__c) leaseOppsWithErrors.add(opp.Id);
                                if (!Test.isRunningTest()) newMap.get(opp.Id).addError('Unable to proceed with Funding. Please review the Contact’s Emailage result and override.');
                                break;
                            }
                        }
                    }
                    Contact primaryContact = primaryContacts.get(opp.Primary_Contact__c);
                    // now also check primary contact, just for lease opps
                    if (!opp.Loan_Record_Type__c && !leaseOppsWithErrors.contains(opp.Id) && primaryContact != null && TC_CheckContactEmailageResult.checkContactEmailageResult(primaryContact.Emailage_Result__c, primaryContact.Override_Emailage_Result__c) && !Test.isRunningTest()) newMap.get(opp.Id).addError('Unable to proceed with Funding. Please review the Contact’s Emailage result and override.');
                }                
            
        }
    }

    // old kept for reference
    // public static void validateEmailageResults (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap){
        
    //     Set <Id> oppIds = new Set <Id> ();
        
    //     Set <String> targetStages = new Set <String> {'Review for Booking', 'Funding', 'Booking', 'Booking (Loan)', 'Funding (Loan)', 'Funded/Booked'};
            
    //         for (Opportunity opp : newMap.values()){
    //             if (targetStages.contains(opp.StageName) && opp.StageName != oldMap.get(opp.Id).StageName) oppIds.add(opp.Id);
    //         }
        
    //     if (!oppIds.isEmpty()){
            
    //         List <Opportunity> oppList = [SELECT Id, Loan_Record_Type__c, 
    //                                       Primary_Contact__r.Emailage_Result__c, Primary_Contact__r.Override_Emailage_Result__c,
    //                                       (SELECT Id, Contact__r.Emailage_Result__c, Contact__r.Override_Emailage_Result__c FROM Guarantor__r WHERE Type__c = 'Personal Guarantor' AND Contact__c != NULL) FROM Opportunity WHERE Id IN :oppIds];
            
    //         if (oppList != null && !oppList.isEmpty()){
                
    //             Set <Id> leaseOppsWithErrors = new Set <Id> ();
                
    //             for (Opportunity opp : oppList){
                    
    //                 // check personal guarantors for both lease and loan opps
    //                 if (opp.Guarantor__r != null && !opp.Guarantor__r.isEmpty()){
    //                     for (Guarantor__c guar : opp.Guarantor__r){
    //                         if (TC_CheckContactEmailageResult.checkContactEmailageResult(guar.Contact__r.Emailage_Result__c, guar.Contact__r.Override_Emailage_Result__c)){
    //                             if (!opp.Loan_Record_Type__c) leaseOppsWithErrors.add(opp.Id);
    //                             if (!Test.isRunningTest()) newMap.get(opp.Id).addError('Unable to proceed with Funding. Please review the Contact’s Emailage result and override.');
    //                             break;
    //                         }
    //                     }
    //                 }
                    
    //                 // now also check primary contact, just for lease opps
    //                 if (!opp.Loan_Record_Type__c && !leaseOppsWithErrors.contains(opp.Id) && TC_CheckContactEmailageResult.checkContactEmailageResult(opp.Primary_Contact__r.Emailage_Result__c, opp.Primary_Contact__r.Override_Emailage_Result__c) && !Test.isRunningTest()) newMap.get(opp.Id).addError('Unable to proceed with Funding. Please review the Contact’s Emailage result and override.');
    //             }                
    //         }
    //     }
    // }
}