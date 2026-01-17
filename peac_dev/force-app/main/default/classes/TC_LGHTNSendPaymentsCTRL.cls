public class TC_LGHTNSendPaymentsCTRL {
    
    @auraEnabled
    public static Integer sendPayments (Id recId) {
        
        // NOTE: recId can be an Opportunity or a Payment__c
        
        try {
            
            List <Payment__c> payments = new List <Payment__c> ();
            
            // begin: SAL-1509
            Id currentUserId = UserInfo.getUserId();
            User currentUser = [SELECT CMS_Credit_Authority_Lease__c, ProfileId, Profile.Name FROM User WHERE Id = :currentUserId LIMIT 1][0];
            Decimal CMSAuthorityLimit = currentUser.CMS_Credit_Authority_Lease__c;
            AuraHandledException ae_Authority = new AuraHandledException  ('Equipment Cost is greater than user\'s CMS Credit Authority (Lease).'); 
            ae_Authority.setMessage ('Equipment Cost is greater than user\'s CMS Credit Authority (Lease).');
            // end: SAL-1509
            
            Opportunity opp;
            // Asset logic check
            List <Asset__c> assets = new List <Asset__c> ();
            
            if (recId.getSObjectType () == Schema.Opportunity.getSObjectType ()) {

                assets = queryAssets (recId);

                payments = [SELECT Id, Payee__c FROM Payment__c WHERE Opportunity__c = :recId AND Payment_Status__c = 'Ready to Send'];
                
                // begin: SAL-1509
                opp = [SELECT Id, Equipment_Cost__c, Last_Funded_By__c, Loan_Record_Type__c, StageName FROM Opportunity WHERE Id = :recId LIMIT 1][0];  
                if (opp.Loan_Record_Type__c == false && currentUser.ProfileId != null && (currentUser.Profile.Name == 'CMS' || currentUser.Profile.Name == 'Partner Ambassador') && (CMSAuthorityLimit == null || (opp != null && opp.Equipment_Cost__c > CMSAuthorityLimit))) throw ae_Authority;
                // end: SAL-1509
                 
                // START: SAL-1664
                if(opp.Loan_Record_Type__c == false && opp.StageName != 'Funding'){
                    AuraHandledException ae = new AuraHandledException  ('Opportunity Stage is not Funding.'); 
                    ae.setMessage ('Opportunity Stage is not Funding.');
                    throw ae;
                }
                // END: SAL-1664
                
            } else {
                payments = [SELECT Id, Payee__c, Opportunity__c FROM Payment__c WHERE Id = :recId AND Payment_Status__c = 'Ready to Send'];
                
                // begin: SAL-1509
                Id oppId = payments[0].Opportunity__c;                
                opp = [SELECT Id, Equipment_Cost__c, Last_Funded_By__c, Loan_Record_Type__c, StageName FROM Opportunity WHERE Id = :oppId LIMIT 1][0];  
                
                if (opp.Loan_Record_Type__c == false && currentUser.ProfileId != null && (currentUser.Profile.Name == 'CMS' || currentUser.Profile.Name == 'Partner Ambassador') &&  (CMSAuthorityLimit == null || (opp != null && opp.Equipment_Cost__c > CMSAuthorityLimit))) throw ae_Authority;
                // end: SAL-1509
                
                // START: SAL-1664
                if(opp.Loan_Record_Type__c == false && opp.StageName != 'Funding'){
                    AuraHandledException ae = new AuraHandledException  ('Opportunity Stage is not Funding.'); 
                    ae.setMessage ('Opportunity Stage is not Funding.');
                    throw ae;
                }
                // END: SAL-1664

                assets = queryAssets (oppId);
            }

            // if equipment code label contains general sub category is required
            Map <String, String> labelMap = TC_PicklistUtil.getLabelMap(Asset__c.Equipment_Code__c);
            Map <String, String> subCatLabelMap = TC_PicklistUtil.getLabelMap(Asset__c.Equipment_Sub_Category__c);

            for (Asset__c asset : assets) {
                if (String.isEmpty(asset.Equipment_Code__c)) {
                    throwException ('Equipment Code is required on Asset: ' + asset.Name);
                } else if (labelMap.get (asset.Equipment_Code__c).containsIgnoreCase('general') && (String.isEmpty(asset.Equipment_Sub_Category__c) || subCatLabelMap.get (asset.Equipment_Sub_Category__c).containsIgnoreCase('general')) ) {
                    throwException (labelMap.get (asset.Equipment_Code__c) + ' equipment code requires a non General Sub Category on Asset: ' + asset.Name);
                }
            }
            
            if (payments != null && !payments.isEmpty ()) {
                Solomon.SendPayments (payments);
            } else {
                // no payments to send  
                AuraHandledException ae = new AuraHandledException  ('No payments are ready to send'); 
                ae.setMessage ('No payments are ready to send');
                throw ae;
            }
            
            List <Payment__c> updateList = new List <Payment__c> ();
            
            for (Payment__c payment : payments) {
                updateList.add (new Payment__c (Id = payment.Id
                                                , Payment_Status__c = 'Payment Sent'
                                                , Date_Sent_to_External_System__c = Datetime.now ()));
            }
            
            update updateList;
            
            // begin: SAL-1510
            if (opp.Last_Funded_By__c == null) update new Opportunity (Id = opp.Id, Last_Funded_By__c = currentUserId);
            // end: SAL-1510



            
            return payments.size ();
        } catch (Exception e) {
            AuraHandledException ae = new AuraHandledException  (e.getMessage ()); 
            ae.setMessage (e.getMessage ());
            throw ae;
        }
        
    }

    private static List <Asset__C> queryAssets (Id oppId) {
        return new List <Asset__C> ([SELECT Id, Name, Equipment_Code__c, Equipment_Sub_Category__c FROM Asset__C WHERE Opportunity__c = :oppId]);
    }

    @testvisible private static void throwException (String message) {
        AuraHandledException ae = new AuraHandledException  (message);
        ae.setMessage (message);
        throw ae;
    }
}