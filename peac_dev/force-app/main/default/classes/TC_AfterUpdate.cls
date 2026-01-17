public class TC_AfterUpdate {
    public static void afterUpdate(Map <Id, Opportunity> triggerNewMap, Map <Id, Opportunity> triggerOldMap) {
        //moved to TC_OpportunityTriggerHandler    
        //TC_CreateUpdateVariablePaymentRecord.createUpdateVariablePaymentRecord(triggerNewMap.values(), triggerOldMap);
        //TC_GenerateTrustLink.generateTrustLink(triggerNewMap, triggerOldMap);
        TC_SubmitToAspire.submitToAspire (triggerNewMap.values ());
        TC_BookToInfoLease.bookToInfoLease (triggerNewMap.values ());
        
        // Set <Id> oppIds = new Set <Id> ();
        Set <Id> oppIdsPropertyTaxStatus = new Set <Id> ();
        Set <Id> oppIdsContractType = new Set <Id> ();
        
        for (Opportunity opp : triggerNewMap.values ()) {
            // if (triggerOldMap.get (opp.Id).Payment_Amount__c != opp.Payment_Amount__c || triggerOldMap.get (opp.Id).of_Payments__c != opp.of_Payments__c || triggerOldMap.get (opp.Id).X_Rate_Factor__c != opp.X_Rate_Factor__c)
            //     oppIds.add (opp.Id);
            
            if (triggerOldMap.get (opp.Id).Purchase_Options__c != opp.Purchase_Options__c && opp.Purchase_Options__c != 'Customer Owned')
                oppIdsPropertyTaxStatus.add (opp.Id);
            
            if (triggerOldMap.get (opp.Id).Contract_Type__c != opp.Contract_Type__c && opp.Contract_Type__c != 'Rental Lease')
                oppIdsContractType.add (opp.Id);
            
            if (String.isEmpty (triggerOldMap.get (opp.Id).Application__c) && String.isNotEmpty (opp.Application__c)) {
                if (opp.RECORDTYPE.DEVELOPERNAME != 'Funding_Stream_Opportunity')
                    MARLIN_OnBaseCallout.sendRapportAttachmentToOnBase (opp.Id,True);
            }
        }
        
        if (oppIdsPropertyTaxStatus.size () > 0) {
            List <Asset__c> assets = [SELECT Property_Tax_Status_Per_State__c,
                                      State_Tax_Code__c,
                                      LC_State_Tax_Code__c,
                                      Misc_State_Tax_Code__c,
                                      County_Tax_Code__c,
                                      LC_County_Tax_Code__c,
                                      Misc_County_Tax_Code__c,
                                      City_Tax_Code__c,
                                      LC_City_Tax_Code__c,
                                      Misc_City_Tax_Code__c,
                                      Upfront_Tax_Code__c,
                                      Opportunity_Contract_Type__c
                                      FROM Asset__c
                                      WHERE Opportunity__c IN :oppIdsPropertyTaxStatus
                                     ];
            
            for (Asset__c a : assets) {
                a.Property_Status__c = a.Property_Tax_Status_Per_State__c;
                
                if (a.State_Tax_Code__c == '050' || a.LC_State_Tax_Code__c == '050' || a.Misc_State_Tax_Code__c == '050' || a.County_Tax_Code__c == '050' || a.LC_County_Tax_Code__c == '050' || a.Misc_County_Tax_Code__c == '050' || a.City_Tax_Code__c == '050' || a.LC_City_Tax_Code__c == '050' || a.Misc_City_Tax_Code__c == '050'|| a.Upfront_Tax_Code__c == '050') {
                    a.State_Tax_Code__c = null; a.LC_State_Tax_Code__c = null; a.Misc_State_Tax_Code__c = null; a.County_Tax_Code__c = null; a.LC_County_Tax_Code__c = null; a.Misc_County_Tax_Code__c = null; a.City_Tax_Code__c = null; a.LC_City_Tax_Code__c = null; a.Misc_City_Tax_Code__c = null; a.Upfront_Tax_Code__c = null;
                }
            }
            
            update assets;
        }
        
        if (oppIdsContractType.size () > 0) {
            List <Asset__c> assets = [SELECT State_Tax_Code__c,
                                      LC_State_Tax_Code__c,
                                      Misc_State_Tax_Code__c,
                                      County_Tax_Code__c,
                                      LC_County_Tax_Code__c,
                                      Misc_County_Tax_Code__c,
                                      City_Tax_Code__c,
                                      LC_City_Tax_Code__c,
                                      Misc_City_Tax_Code__c,
                                      Upfront_Tax_Code__c,
                                      Opportunity_Contract_Type__c
                                      FROM Asset__c
                                      WHERE Opportunity__c IN :oppIdsContractType
                                     ];
            
            for (Asset__c a : assets) {
                if (a.State_Tax_Code__c == '050' || a.LC_State_Tax_Code__c == '050' || a.Misc_State_Tax_Code__c == '050' || a.County_Tax_Code__c == '050' || a.LC_County_Tax_Code__c == '050' || a.Misc_County_Tax_Code__c == '050'|| a.City_Tax_Code__c == '050' || a.LC_City_Tax_Code__c == '050' || a.Misc_City_Tax_Code__c == '050' || a.Upfront_Tax_Code__c == '050') {
                    a.State_Tax_Code__c = null; a.LC_State_Tax_Code__c = null; a.Misc_State_Tax_Code__c = null; a.County_Tax_Code__c = null; a.LC_County_Tax_Code__c = null; a.Misc_County_Tax_Code__c = null; a.City_Tax_Code__c = null; a.LC_City_Tax_Code__c = null; a.Misc_City_Tax_Code__c = null; a.Upfront_Tax_Code__c = null;
                }
            }
            
            update assets;
        }
        
        // TC_CalculateAssetRentalAmt.calculateAssetRentalAmount (oppIds);
    }
}