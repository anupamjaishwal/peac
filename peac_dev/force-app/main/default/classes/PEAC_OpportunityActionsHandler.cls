public class PEAC_OpportunityActionsHandler {

    /*START: 1 - Booked Date is not null and Booked Date is changed */
    // After insert and before update
    public static void opportunityUpdateBlendedIncomeItemBookedDateToOpportunityBookedDate(Map <Id, Opportunity> newMap){
        Map<Id, Opportunity> eligibaleOpportunityMap = new Map<Id, Opportunity>();
        for(Opportunity opp : newMap.values()){
            if(!isBlank(opp.Opportunity_Booked_Date__c)){
                //eligibleOpportunityList.add(opp);
                eligibaleOpportunityMap.put(opp.Id, opp);
            }
        }

        if(!eligibaleOpportunityMap.isEmpty()){
			List<Blended_Income_Item__c> blendedIncomeItemList = getOpportunityRelatedBlendedIncomeItems(eligibaleOpportunityMap.keyset());
            if(!blendedIncomeItemList.isEmpty()){
                List<Blended_Income_Item__c> biisToBeUpdated = mapBlendedIncomeItemBookingDate(blendedIncomeItemList, eligibaleOpportunityMap);
                if(!biisToBeUpdated.isEmpty()){
                    update biisToBeUpdated;
                }
            }
        }
    }

    public static void opportunityUpdateBlendedIncomeItemBookedDateToOpportunityBookedDate(Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap){
        Set<Id> oppIds = new Set<Id>();
        List<Opportunity> eligibleOpportunityList = new List<Opportunity>();
        Map<Id, Opportunity> eligibaleOpportunityMap = new Map<Id, Opportunity>();
        for(Opportunity opp : newMap.values()){
            if(oldMap.get(opp.Id).Opportunity_Booked_Date__c != newMap.get(opp.Id).Opportunity_Booked_Date__c
                && !isBlank(opp.Opportunity_Booked_Date__c)){
                eligibleOpportunityList.add(opp);
                eligibaleOpportunityMap.put(opp.Id, opp);
            }
        }

        if(!eligibaleOpportunityMap.isEmpty()){
			List<Blended_Income_Item__c> blendedIncomeItemList = getOpportunityRelatedBlendedIncomeItems(eligibaleOpportunityMap.keyset());
            if(!blendedIncomeItemList.isEmpty()){
                List<Blended_Income_Item__c> biisToBeUpdated = mapBlendedIncomeItemBookingDate(blendedIncomeItemList, eligibaleOpportunityMap);
                if(!biisToBeUpdated.isEmpty()){
                    update biisToBeUpdated;
                }
            }
        }
    }

    public static List<Blended_Income_Item__c> getOpportunityRelatedBlendedIncomeItems(Set<Id> oppsIds){
    	List<Blended_Income_Item__c> biis = [SELECT Id, Opportunity__c, Booking_Date__c, Begin_Date__c
                    						 FROM Blended_Income_Item__c
                                             WHERE Opportunity__c IN :oppsIds];

        return biis;

    }
    
    public static List<Blended_Income_Item__c> mapBlendedIncomeItemBookingDate(List<Blended_Income_Item__c> biiList, Map<Id, Opportunity> opportunityMap){
        List<Blended_Income_Item__c> biisToBeUpdated = new List<Blended_Income_Item__c>();
        for(Blended_Income_Item__c bii : biiList){
            if(opportunityMap.containsKey(bii.Opportunity__c)){
                //bii.Booking_Date__c = opportunityMap.get(bii.Opportunity__c).Opportunity_Booked_Date__c;
                bii.Booking_Date__c = opportunityMap.get(bii.Opportunity__c).Opportunity_Booked_Date__c.date();
                biisToBeUpdated.add(bii);
            }
        }
        return biisToBeUpdated;
    }

    /*END: 1 - Booked Date is not null and Booked Date is changed */

    /*START: 2 - Manual Funding Is changed -> TC Opportunity - Set Manual Funding Fields Sub Flow */
    // Before insert and befor update
    public static void opportunitySetManualFundingFields(List<Opportunity> newList){
        for(Opportunity opp : newList){
            if(opp.Manual_Funding__c){
                opp.Manual_Funding_Date__c = Datetime.now();
                opp.Manual_Funding_User__c = UserInfo.getUserId();
            } else {
                opp.Manual_Funding_Date__c = Null;
                opp.Manual_Funding_User__c = Null;               
            }
        }
    }
    
    public static void opportunitySetManualFundingFields(Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap){
        for(Opportunity opp : newMap.values()){
            if(oldMap.get(opp.Id).Manual_Funding__c != newMap.get(opp.Id).Manual_Funding__c && opp.Manual_Funding__c){
                opp.Manual_Funding_Date__c = Datetime.now();
                opp.Manual_Funding_User__c = UserInfo.getUserId();
            } else {
                opp.Manual_Funding_Date__c = Null;
                opp.Manual_Funding_User__c = Null;               
            }
        }
    }
    /*END: 2 - Manual Funding Is changed -> TC Opportunity - Set Manual Funding Fields Sub Flow */

    /*START: 3 - Trigger Update to Funded Amount -> TC Opportunity - Update Funding Amount to Total Payments Sent Sub Flow */
    // before insert and before update
    public static void opportunityUpdateFundingAmountToTotalPaymentsSent(List<Opportunity> newList){
        for(Opportunity opp : newList){
            if(!opp.Loan_Record_Type__c){
                if (opp.StageName == PEAC_ConstantClass.OPPORTUNITY_STAGENAME_FUNDING
                    || opp.StageName == PEAC_ConstantClass.OPPORTUNITY_STAGENAME_BOOKING) {
                    opp.Funded_Amount__c = opp.Total_Payments_Sent__c;
                }
            }
        }
    }
    
    public static void opportunityUpdateFundingAmountToTotalPaymentsSent(Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
        for(Opportunity opp : newMap.values()){
            if(oldMap.get(opp.Id).Total_Payments_Sent__c != newMap.get(opp.Id).Total_Payments_Sent__c && !opp.Loan_Record_Type__c){
                if (opp.StageName == PEAC_ConstantClass.OPPORTUNITY_STAGENAME_FUNDING
                    || opp.StageName == PEAC_ConstantClass.OPPORTUNITY_STAGENAME_BOOKING) {
                    opp.Funded_Amount__c = opp.Total_Payments_Sent__c;
                }
            }
        }
    }
    /* END: 3 - Trigger Update to Funded Amount -> TC Opportunity - Update Funding Amount to Total Payments Sent Sub Flow */
    
    /* START: 4 - Trigger Multiple Address Check */
    // After insert and after update
    public static void opportunityValidateForMultipleAddressCheck(List<Opportunity> newList){
		Set<Id> oppIds = new Set<Id>();
        for (Opportunity opp : newList) {
            if(opp.StageName == PEAC_ConstantClass.OPPORTUNITY_STAGENAME_PROPOSAL
              && opp.Ready_to_Doc__c == PEAC_ConstantClass.Yes){
                oppIds.add(opp.Id);
            }
        }
        if (!oppIds.isEmpty()) {
            setMultipleAddressCheckbox(oppIds);
        }

    }

    public static void opportunityValidateForMultipleAddressCheck(Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap){
		Set<Id> oppIds = new Set<Id>();
        for (Opportunity opp : newMap.values()) {
            if(oldMap.get(opp.Id).StageName != newMap.get(opp.Id).StageName && opp.StageName == PEAC_ConstantClass.OPPORTUNITY_STAGENAME_PROPOSAL
               && opp.Ready_to_Doc__c == PEAC_ConstantClass.Yes){
                oppIds.add(opp.Id);
            }
        }
        
        if (!oppIds.isEmpty()) {
            setMultipleAddressCheckbox(oppIds);
        }

    }
    
    
    public static void setMultipleAddressCheckbox(Set<Id> opportunityIds) {
        if (opportunityIds == null) opportunityIds = new Set<Id>();
        opportunityIds.remove(null);
        if (opportunityIds.isEmpty()) return;
        
        // Prepare a set of distinct address tuples per Opportunity
        Map<Id, Set<String>> oppToAddressTuples = new Map<Id, Set<String>>();
        for (Id oppId : opportunityIds) oppToAddressTuples.put(oppId, new Set<String>());
        
        // Single SOQL: gather all related assets and the address components the Flow compares. 
        List<Asset__c> assets = [
            SELECT Id, Opportunity__c,
            Equipment_Street__c, Equipment_City__c,
            Equipment_State__c,  Equipment_Zip__c
            FROM Asset__c
            WHERE Opportunity__c IN :opportunityIds
        ];
        
        // Build a raw comparison key from the 4 components (no normalization).
        for (Asset__c a : assets) {
            Id oppId = a.Opportunity__c;
            if (!oppToAddressTuples.containsKey(oppId)) continue;
            String key =
                String.valueOf(a.Equipment_Street__c) + '|' +
                String.valueOf(a.Equipment_City__c)   + '|' +
                String.valueOf(a.Equipment_State__c)  + '|' +
                String.valueOf(a.Equipment_Zip__c);
            oppToAddressTuples.get(oppId).add(key);
        }
        
        // Build minimal Opportunity updates: true iff >1 distinct address tuple; else false.
        List<Opportunity> updates = new List<Opportunity>();
        for (Id oppId : oppToAddressTuples.keySet()) {
            Boolean multiple = oppToAddressTuples.get(oppId).size() > 1;
            updates.add(new Opportunity(
                Id = oppId,
                Multiple_Asset_Addresses__c = multiple
            ));
        }
        
        if (!updates.isEmpty()) {
            update updates; // single bulk DML
        }
    }
    
    
    /* END: 4 - Trigger Multiple Address Check */
    
    
    /*START: 5 - Trigger Update to Funded Amount Loan */
    // before insert and before update
    public static void opportunityUpdateFundedAmount(List<Opportunity> newList){
        for(Opportunity opp : newList){
            if(opp.Loan_Record_Type__c){
                opp.Funded_Amount__c = opp.Total_Payment_Sent_Loan__c;
            }
        }
    }
    
    public static void opportunityUpdateFundedAmount(Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap){
        for(Opportunity opp : newMap.values()){
            if( oldMap.get(opp.Id).Total_Payment_Sent_Loan__c != newMap.get(opp.Id).Total_Payment_Sent_Loan__c && opp.Loan_Record_Type__c){
                opp.Funded_Amount__c = opp.Total_Payment_Sent_Loan__c;
            }
        }
    }
    
    /*END: 5 - Trigger Update to Funded Amount Loan */
    
    /*START: 6 - Commencement Date Changes */
    // after insert and before update
    public static void opportunityCommencementDateChanges(Map <Id, Opportunity> newMap){
        Map<Id, Opportunity> eligibaleOpportunityMap = new Map<Id, Opportunity>();
        for(Opportunity opp : newMap.values()){
            if(opp.Number_of_Blended_Income_Items__c != Null && opp.Number_of_Blended_Income_Items__c > 0){
                eligibaleOpportunityMap.put(opp.Id, opp);
            }
        }

        if(!eligibaleOpportunityMap.isEmpty()){
			List<Blended_Income_Item__c> blendedIncomeItemList = getOpportunityRelatedBlendedIncomeItems(eligibaleOpportunityMap.keyset());
            if(!blendedIncomeItemList.isEmpty()){
                List<Blended_Income_Item__c> biisToBeUpdated = mapBlendedIncomeItemBeginDate(blendedIncomeItemList, eligibaleOpportunityMap);
                if(!biisToBeUpdated.isEmpty()){
                    update biisToBeUpdated;
                }
            }
        }
    }

    public static void opportunityCommencementDateChanges(Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap){
        Map<Id, Opportunity> eligibaleOpportunityMap = new Map<Id, Opportunity>();
        for(Opportunity opp : newMap.values()){
            if(oldMap.get(opp.Id).Commencement_Date__c != newMap.get(opp.Id).Commencement_Date__c
               && opp.Number_of_Blended_Income_Items__c != Null && opp.Number_of_Blended_Income_Items__c > 0){
                eligibaleOpportunityMap.put(opp.Id, opp);
            }
        }

        if(!eligibaleOpportunityMap.isEmpty()){
			List<Blended_Income_Item__c> blendedIncomeItemList = getOpportunityRelatedBlendedIncomeItems(eligibaleOpportunityMap.keyset());
            if(!blendedIncomeItemList.isEmpty()){
                List<Blended_Income_Item__c> biisToBeUpdated = mapBlendedIncomeItemBeginDate(blendedIncomeItemList, eligibaleOpportunityMap);
                if(!biisToBeUpdated.isEmpty()){
                    update biisToBeUpdated;
                }
            }
        }
    }
    
    public static List<Blended_Income_Item__c> mapBlendedIncomeItemBeginDate(List<Blended_Income_Item__c> biiList, Map<Id, Opportunity> opportunityMap){
        List<Blended_Income_Item__c> biisToBeUpdated = new List<Blended_Income_Item__c>();
        for(Blended_Income_Item__c bii : biiList){
            if(opportunityMap.containsKey(bii.Opportunity__c)){
                bii.Begin_Date__c = (Date)opportunityMap.get(bii.Opportunity__c).Commencement_Date__c;
                biisToBeUpdated.add(bii);
            }
        }
        return biisToBeUpdated;
    }
    /*END: 6 - Commencement Date Changes */
    
    /*START: 7 - Bank Account and Bank Routing entered with null bank code and type */
    // before insert and before update
    public static void opportunityUpdateBankCodeBankAccountType(List<Opportunity> newList){
        for(Opportunity opp : newList){
            //if((opp.Bank_Account_Number__c != Null OR opp.Bank_Number__c != Null) && (opp.Bank_Code__c == Null OR opp.Bank_Account_Type__c == Null)){
            if((!isBlank(opp.Bank_Account_Number__c) || !isBlank(opp.Bank_Number__c)) && (isBlank(opp.Bank_Code__c) || isBlank(opp.Bank_Account_Type__c))){  
            	opp.Bank_Account_Type__c = PEAC_ConstantClass.OPPORTUNITY_BANK_ACCOUNT_TYPE_CHECKINGS;
                opp.Bank_Code__c = PEAC_ConstantClass.OPPORTUNITY_BANK_CODE_100;
            }
        }  
    }
    /*END: 7 - Bank Account and Bank Routing entered with null bank code and type */

    /*START: 8 - Doc Fee (DISABLED with condition 8)*/
    /* This criteria has been depricated */
    /*END: 8 - Doc Fee (DISABLED with condition 8)*/


    /*START: 9 - Auto Create Fl Tax Misc Invoice */
    //Trigger.isAfter && Trigger.isInsert

    public static void autoCreateFiTaxMiscInvoice(List<Opportunity> newList){
        List<Opportunity> eligibleOpportunityList = new List<Opportunity>();
        for (Opportunity opp : newList) {
            // oldO is null in insert
            if (validateForAutoCreateFiTacMiscInvoice(opp, null, True)) {
				eligibleOpportunityList.add(opp);
            }
        }
        if(!eligibleOpportunityList.isEmpty()){
            createMiscellaneousInvoiceItem(eligibleOpportunityList);
        }
    }

    public static void autoCreateFiTaxMiscInvoice(Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap){
        List<Opportunity> eligibleOpportunityList = new List<Opportunity>();
        for (Opportunity opp : newMap.values()) {
            // oldO is null in insert
            if (validateForAutoCreateFiTacMiscInvoice(opp, oldMap.get(opp.Id), True)) {
				eligibleOpportunityList.add(opp);
            }
        }
        if(!eligibleOpportunityList.isEmpty()){
            createMiscellaneousInvoiceItem(eligibleOpportunityList);
        }
    }
    
    public static void createMiscellaneousInvoiceItem(List<Opportunity> opportunityList){
        List<Miscellaneous_Invoice_Item__c> miscellaneousInvoiceItemList = new List<Miscellaneous_Invoice_Item__c>();
        for(Opportunity opp : opportunityList){
            Miscellaneous_Invoice_Item__c mit = new Miscellaneous_Invoice_Item__c();
            mit.Amount__c = opp.Flordia_Doc_Stamp_Tax_Amount__c;
            mit.Opportunity__c = opp.Id;
            mit.GL_Code__c = '0019 - Fla Doc Stamp Tax'; //need to move to constant class
            miscellaneousInvoiceItemList.add(mit);
        }
        if(!miscellaneousInvoiceItemList.isEmpty()){
            insert miscellaneousInvoiceItemList;
            updateOpportunityFLDocStTaxMiscInvoiceLookUp(miscellaneousInvoiceItemList);
        }
    }

    /*this opportunity update has been designed on the basis that 1 opportunity will have 1 Miscellaneous_Invoice_Item__c.
     *It will be a 1:1 mapping*/
    public static void updateOpportunityFLDocStTaxMiscInvoiceLookUp(List<Miscellaneous_Invoice_Item__c> miscellaneousInvoiceItemList){
        Map<Id, Id> miiIdToOpportunityId = new Map<Id, Id>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        for(Miscellaneous_Invoice_Item__c mii : miscellaneousInvoiceItemList){
            if(mii.Opportunity__c != Null){
                miiIdToOpportunityId.put(mii.Id, mii.Opportunity__c);  
            }
        }
        if(!miiIdToOpportunityId.isEmpty()){
            for(Id key : miiIdToOpportunityId.keyset()){
                opportunityList.add(new Opportunity(Id=miiIdToOpportunityId.get(key), FL_Doc_St_Tax_Misc_Invoice__c=key));
            }
        }
        if(!opportunityList.isEmpty()){
            update opportunityList;
        }
    }
    
	public static Boolean validateForAutoCreateFiTacMiscInvoice(Opportunity o, Opportunity oldO, Boolean treatInsertAsChanged) {
        Boolean isInsert = (oldO == null);

        // ---------- ISCHANGED(...) emulation ----------
        // UPDATE: compare old vs new
        Boolean stageChanged        = (!isInsert) && (oldO.StageName != o.StageName);
        Boolean purchaseOptionsChg  = (!isInsert) && (oldO.Purchase_Options__c != o.Purchase_Options__c);
        Boolean miscInvoiceChanged  = (!isInsert) && (oldO.FL_Doc_St_Tax_Misc_Invoice__c != o.FL_Doc_St_Tax_Misc_Invoice__c);
        Boolean floridaSumChanged   = (!isInsert) && (oldO.Sum_of_Florida_Asset_Rental_Amounts__c != o.Sum_of_Florida_Asset_Rental_Amounts__c);

        // INSERT handling:
        // Option A: treat insert as "changed" (like PB initial-value behavior)
        // Option B: only consider changed if the field is set to a non-default value on insert
        Boolean insertStageChanged       = isInsert && (treatInsertAsChanged ? true : o.StageName != null);
        Boolean insertPurchaseOptionsChg = isInsert && (treatInsertAsChanged ? true : o.Purchase_Options__c != null);
        Boolean insertMiscInvoiceChanged = isInsert && (treatInsertAsChanged ? true : o.FL_Doc_St_Tax_Misc_Invoice__c != null); // will be false if you require ISBLANK later
        Boolean insertFloridaSumChanged  = isInsert && (treatInsertAsChanged ? true : o.Sum_of_Florida_Asset_Rental_Amounts__c != null);

        Boolean anyChanged = (isInsert)
            ? (insertStageChanged || insertPurchaseOptionsChg || insertMiscInvoiceChanged || insertFloridaSumChanged)
            : (stageChanged || purchaseOptionsChg || miscInvoiceChanged || floridaSumChanged);

        // ---------- The rest of your PB predicates ----------
        // TEXT(StageName) = "Booking"
        Boolean isBooking = (o.StageName == 'Booking');

        // ![Opportunity].Loan_Record_Type__c  (NOT checkbox)
        Boolean notLoanRecordType = (o.Loan_Record_Type__c != true);

        // !CONTAINS(TEXT(Purchase_Options__c), "FMV")
        String purchaseOptionsText = String.valueOf(o.Purchase_Options__c);
        Boolean doesNotContainFMV = isBlank(purchaseOptionsText) ? True : !purchaseOptionsText.contains('FMV');

        // TEXT(Purchase_Options__c) <> "Customer Owned"
        Boolean notCustomerOwned = (o.Purchase_Options__c != 'Customer Owned');

        // ISBLANK(FL_Doc_St_Tax_Misc_Invoice__c)
        Boolean miscInvoiceIsBlank = (o.FL_Doc_St_Tax_Misc_Invoice__c == null);

        // Sum_of_Florida_Asset_Rental_Amounts__c > 0 (null-safe)
        Decimal floridaSum = (o.Sum_of_Florida_Asset_Rental_Amounts__c == null)
                           ? 0
                           : o.Sum_of_Florida_Asset_Rental_Amounts__c;
        Boolean floridaSumPositive = (floridaSum > 0);

        return anyChanged
            && isBooking
            && notLoanRecordType
            && doesNotContainFMV
            && notCustomerOwned
            && miscInvoiceIsBlank
            && floridaSumPositive;
    }
    /*END: 9 - Auto Create Fl Tax Misc Invoice */


    /*START: 10 - Update FL Tax Misc Invoice */
    // Trigger.isAfter && Trigger.isInsert
    public static void opportunityUpdateFLTaxMiscInvoice(List<Opportunity> newList){
        Map<Id, Opportunity> eligibleOportunityMap = new Map<Id, Opportunity>();
        Set<Id> invoiceIds = new Set<Id>();
        for (Opportunity o : newList) {
            if (o.FL_Doc_St_Tax_Misc_Invoice__c != null) {
                invoiceIds.add(o.FL_Doc_St_Tax_Misc_Invoice__c);
            }
        }
        if(!invoiceIds.isEmpty()){
            Map<Id, Decimal> invoiceAmtById = getMiscellaneousInvoiceItem(invoiceIds);
            for(Opportunity opp : newList){
                if(validateUpdateFLTaxMiscInvoice(opp, null, invoiceAmtById)){
					eligibleOportunityMap.put(opp.Id, opp);
                }
                
            }
        }
        if(!eligibleOportunityMap.isEmpty()){
        	List<Miscellaneous_Invoice_Item__c> miscellaneousInvoiceItemList = getMiscellaneousInvoiceItemByOpportunity(eligibleOportunityMap.keyset());
            if(!miscellaneousInvoiceItemList.isEmpty()){
                for(Miscellaneous_Invoice_Item__c mit : miscellaneousInvoiceItemList){
                    // mit.Amount__c = eligibleOportunityMap.get(mit.Opportunity__c).Flordia_Doc_Stamp_Tax_Amount__c;
                    Opportunity o = eligibleOportunityMap.get(mit.Opportunity__c);// Misael Romero updated as per Varun request
                    if(mit.Id == o.FL_Doc_St_Tax_Misc_Invoice__c){
                        mit.Amount__c = o.Flordia_Doc_Stamp_Tax_Amount__c;
                    }
                }
            	update miscellaneousInvoiceItemList;
            }
        }
    }
    
    public static void opportunityUpdateFLTaxMiscInvoice(Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap){
        Map<Id, Opportunity> eligibleOportunityMap = new Map<Id, Opportunity>();
        List<Opportunity> eligibleOportunity = new List<Opportunity>();
        Set<Id> invoiceIds = new Set<Id>();
        for (Opportunity o : newMap.values()) {
            if (o.FL_Doc_St_Tax_Misc_Invoice__c != null) {
                invoiceIds.add(o.FL_Doc_St_Tax_Misc_Invoice__c);
            }
        }
        if(!invoiceIds.isEmpty()){
            Map<Id, Decimal> invoiceAmtById = getMiscellaneousInvoiceItem(invoiceIds);
            for(Opportunity opp : newMap.values()){
                if(validateUpdateFLTaxMiscInvoice(opp, oldMap.get(opp.Id), invoiceAmtById)){
					eligibleOportunityMap.put(opp.Id, opp);
                }
                
            }
        }
        if(!eligibleOportunityMap.isEmpty()){
        	List<Miscellaneous_Invoice_Item__c> miscellaneousInvoiceItemList = getMiscellaneousInvoiceItemByOpportunity(eligibleOportunityMap.keyset());
            if(!miscellaneousInvoiceItemList.isEmpty()){
                for(Miscellaneous_Invoice_Item__c mit : miscellaneousInvoiceItemList){
                    // mit.Amount__c = eligibleOportunityMap.get(mit.Opportunity__c).Flordia_Doc_Stamp_Tax_Amount__c;
                    Opportunity o = eligibleOportunityMap.get(mit.Opportunity__c);// Misael Romero updated as per Varun request
                    if(mit.Id == o.FL_Doc_St_Tax_Misc_Invoice__c){
                        mit.Amount__c = o.Flordia_Doc_Stamp_Tax_Amount__c;
                    }
                }
            	update miscellaneousInvoiceItemList;
            }
        }
    }

    public static Map<Id, Decimal> getMiscellaneousInvoiceItem(Set<Id> invoiceIds){
        Map<Id, Decimal> invoiceAmtById = new Map<Id, Decimal>();
        if (!invoiceIds.isEmpty()) {
            for (Miscellaneous_Invoice_Item__c mi : [
                SELECT Id, Amount__c
                FROM Miscellaneous_Invoice_Item__c
                WHERE Id IN :invoiceIds
            ]) {
                invoiceAmtById.put(mi.Id, mi.Amount__c);
            }
        }
        return invoiceAmtById;
    }
    
    public static List<Miscellaneous_Invoice_Item__c> getMiscellaneousInvoiceItemByOpportunity(Set<Id> opportunityIds){
        return [SELECT Id, Amount__c, Opportunity__c
				FROM Miscellaneous_Invoice_Item__c
                WHERE Opportunity__c IN :opportunityIds
               ];
    }


    public static Boolean validateUpdateFLTaxMiscInvoice( Opportunity o, Opportunity oldO, Map<Id, Decimal> invoiceAmtById) {
        // 1) !ISBLANK([Opportunity].FL_Doc_St_Tax_Misc_Invoice__c)
        final Id invoiceId = o.FL_Doc_St_Tax_Misc_Invoice__c;
        final Boolean invoiceNotBlank = (invoiceId != null);
        
        // 2) [Opportunity].FL_Doc_St_Tax_Misc_Invoice__c.Amount__c <> [Opportunity].Sum_of_Florida_Asset_Rental_Amounts__c
        //    Null-safe comparison: treat null as 0 only if that matches your business rule; here we compare raw values.
        Decimal invoiceAmount = null;
        if (invoiceNotBlank && invoiceAmtById != null) {
            invoiceAmount = invoiceAmtById.get(invoiceId);
        }
        final Decimal floridaSum = o.Sum_of_Florida_Asset_Rental_Amounts__c;
        final Boolean amountDiffers = (invoiceAmount != floridaSum);
        
        // 3) ISCHANGED([Opportunity].Sum_of_Florida_Asset_Rental_Amounts__c)
        final Boolean sumChanged = (oldO != null)
            && (oldO.Sum_of_Florida_Asset_Rental_Amounts__c != o.Sum_of_Florida_Asset_Rental_Amounts__c);
        
        // Final PB condition
        return invoiceNotBlank && amountDiffers && sumChanged;
    }

    /*END: 10 - Update FL Tax Misc Invoice */

    /*START: 11 - Clear Bank Code and and Bank Account Type*/
    // before insert and before update
    public static void opportunityClearBankCodeBankAccountType(List<Opportunity> newList){
        for(Opportunity opp : newList){
            if((!isBlank(opp.Bank_Code__c) || !isBlank(opp.Bank_Account_Type__c)) &&  isBlank(opp.Bank_Number__c)
            && isBlank(opp.Bank_Account_Number__c)){
                opp.Bank_Account_Type__c = Null;
                opp.Bank_Code__c = Null;
            }
        }
    }
    /*END: 11 - Clear Bank Code and and Bank Account Type*/


    /*START: 12 - Create Security Deposit Misc Invoice*/
    /*add future transaction to update Misc_Invoice_Sec_Deposit_Auto_Created__c = true */
    // After insert and before update
    public static void opportunityCreateSecurityDepositMiscInvoice(List<Opportunity> newList){
        List<Opportunity> eligibleOpportunities = new List<Opportunity>();
        Set<Id> eligibleOppIds = new Set<Id>();
        if(!newList.isEmpty()){
            for(Opportunity opp : newList){
                if(!opp.Loan_Record_Type__c&& !opp.Misc_Invoice_Sec_Deposit_Auto_Created__c && opp.StageName == PEAC_ConstantClass.OPPORTUNITY_STAGENAME_BOOKING
                   && opp.Security_Deposit__c != Null && opp.Security_Deposit__c > 0){
                       eligibleOpportunities.add(opp);
                       eligibleOppIds.add(opp.Id);
                   }
            }
            if(!eligibleOppIds.isEmpty()){
                markSecDepositMiscInvoiceCreatedFuture(eligibleOppIds);
            }
        }
    }

    public static void opportunityCreateSecurityDepositMiscInvoice(Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap){
        List<Opportunity> eligibleOpportunities = new List<Opportunity>();
        if(!newMap.values().isEmpty()){
            for(Opportunity opp : newMap.values()){
                if(!opp.Loan_Record_Type__c && !opp.Misc_Invoice_Sec_Deposit_Auto_Created__c && opp.StageName == PEAC_ConstantClass.OPPORTUNITY_STAGENAME_BOOKING
                   && opp.Security_Deposit__c != Null && opp.Security_Deposit__c > 0
                   && ((oldMap.get(opp.Id).Security_Deposit__c != newMap.get(opp.Id).Security_Deposit__c)
                       || oldMap.get(opp.Id).StageName != newMap.get(opp.Id).StageName)
                  ){
                    eligibleOpportunities.add(opp);
                      opp.Misc_Invoice_Sec_Deposit_Auto_Created__c = true;
                }
            }
            if(!eligibleOpportunities.isEmpty()){
                createSecurityDepositMiscInvoice(eligibleOpportunities);
            }
        }
    }
    
    public static void createSecurityDepositMiscInvoice(List<Opportunity> eligibleOpportunities){
        if (eligibleOpportunities == null || eligibleOpportunities.isEmpty()) return;

        // Accumulate unique, non-null Opp Ids
        Set<Id> oppIds = new Set<Id>();
        for (Opportunity opp : eligibleOpportunities) {
            if (opp != null && opp.Id != null) {
                oppIds.add(opp.Id);
            }
        }

        if (!oppIds.isEmpty()) {
            // Delegate to the @future method
            createSecurityDepositMiscInvoiceFuture(oppIds);
        }
    }

    // -----------------------------------------------------------------
    // Optional convenience overload: call this directly with Opp Ids
    // -----------------------------------------------------------------
    public static void createSecurityDepositMiscInvoice(Set<Id> opportunityIds) {
        if (opportunityIds == null) return;
        opportunityIds.remove(null);
        if (opportunityIds.isEmpty()) return;

        createSecurityDepositMiscInvoiceFuture(opportunityIds);
    }

    // -----------------------------------------------------------------
    // @future method: performs the actual DML asynchronously
    //   - Must be static
    //   - Accepts only primitives/collections of primitives (Set<Id> OK)
    // -----------------------------------------------------------------
    @future
    public static void createSecurityDepositMiscInvoiceFuture(Set<Id> opportunityIds) {
        if (opportunityIds == null) return;
        opportunityIds.remove(null);
        if (opportunityIds.isEmpty()) return;

        // Query minimal fields required for business rules (defensive):
        // If you need to re‑evaluate eligibility here, pull those fields.
        // Otherwise, just ensure Opp exists.
        List<Opportunity> opps = [
            SELECT Id, Misc_Invoice_Sec_Deposit_Auto_Created__c
            FROM Opportunity
            WHERE Id IN :opportunityIds
        ];
        if (opps.isEmpty()) return;

        List<Miscellaneous_Invoice_Item__c> toInsert = new List<Miscellaneous_Invoice_Item__c>();
        for (Opportunity o : opps) {
            Miscellaneous_Invoice_Item__c mi = new Miscellaneous_Invoice_Item__c(
                Opportunity__c = o.Id,
                GL_Code__c     = PEAC_ConstantClass.GL_CODE_0005_SECURITY_DEPOSIT
            );
            toInsert.add(mi);
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
    }

	@future
    public static void markSecDepositMiscInvoiceCreatedFuture(Set<Id> opportunityIds) {
        if (opportunityIds == null || opportunityIds.isEmpty()) return;

        // Clean up any nulls just in case
        opportunityIds.remove(null);
        if (opportunityIds.isEmpty()) return;

        // Build minimal update payloads (no extra fields)
        List<Opportunity> updates = new List<Opportunity>();
        for (Id oppId : opportunityIds) {
            updates.add(new Opportunity(
                Id = oppId,
                Misc_Invoice_Sec_Deposit_Auto_Created__c = true
            ));
        }

        // Bulk DML
        if (!updates.isEmpty()) {
            update updates;
        }
    }


    

    /*END: 12 - Create Security Deposit Misc Invoice*/


    /*START: 13, 14 - Move Loan to Funded/Booked*/
    // Trigger.isAfter && Trigger.isInsert
    public static void opportunityMoveLoantoFundedBooked(List<Opportunity> newList){
        List<Opportunity> eligibleOpportunityList = new List<Opportunity>();
        for(Opportunity opp : newList){
            if(validateOpportunityMoveLoantoFundedBooked(opp)){
                eligibleOpportunityList.add(new Opportunity(
                Id = opp.Id,
                StageName = 'Funded/Booked'
            ));

            }
        }
        if(!eligibleOpportunityList.isEmpty()){
            setBypass(true);
            /*for(Opportunity opp : eligibleOpportunityList){
                opp.StageName = 'Funded/Booked';
            }*/
            update eligibleOpportunityList;
            setBypass(false);
        }
    }
    

    /**
     * Toggle org-wide bypass using Hierarchy Custom Setting ORE__c.Bypass__c
     * Bulk-safe: executes a single upsert per call.
     */
    public static void setBypass(Boolean turnOn) {
        // Fetch org-defaults record (Hierarchy Custom Setting)
        ORE__c orgDefaults = ORE__c.getOrgDefaults();

        // If the record doesn't exist, create a stub; otherwise update.
        if (orgDefaults == null) {
            orgDefaults = new ORE__c();
        }
        orgDefaults.Bypass__c = turnOn;

        // Upsert the org defaults (single DML)
        upsert orgDefaults;
    }

    
	public static Boolean validateOpportunityMoveLoantoFundedBooked(Opportunity o) {
        // 1) Loan_Record_Type__c (checkbox) → must be true
        final Boolean loanRecordType = (o.Loan_Record_Type__c == true);

        // 2) No_Pymts_Released_or_Acknowledged__c > 0 (Decimal, null-safe)
        final Decimal releasedOrAck = (o.No_Pymts_Released_or_Acknowledged__c == null)
                                    ? 0
                                    : o.No_Pymts_Released_or_Acknowledged__c;
        final Boolean releasedPositive = (releasedOrAck > 0);

        // 3) No_Pymts_Not_Released_or_Acknowledged__c = 0 (Decimal, null-safe)
        final Decimal notReleasedOrAck = (o.No_Pymts_Not_Released_or_Acknowledged__c == null)
                                       ? 0
                                       : o.No_Pymts_Not_Released_or_Acknowledged__c;
        final Boolean notReleasedZero = (notReleasedOrAck == 0);

        // 4) Stage must be "Funding (Loan)"
        final Boolean isFundingLoan = (o.StageName == 'Funding (Loan)');

        // 5) $Setup.ORE__c.Bypass__c = false (Hierarchy Custom Setting)
        Boolean bypass = false;
        ORE__c orgDefaults = ORE__c.getOrgDefaults(); // adjust if List CS or CMDT
        if (orgDefaults != null && orgDefaults.Bypass__c != null) {
            bypass = orgDefaults.Bypass__c;
        }
        final Boolean notBypassed = (bypass == false);
        System.debug(o.StageName);
		System.debug(loanRecordType);
        System.debug(releasedPositive);
        System.debug(notReleasedZero);
        System.debug(isFundingLoan);
        return loanRecordType
            && releasedPositive
            && notReleasedZero
            && isFundingLoan;
            //&& notBypassed;

    }
    /*END: 13, 14 - Move Loan to Funded/Booked*/
 
    public static Boolean isBlank(String s) {
        return s == null || s.trim() == '';
    }

    public static Boolean isBlank(DateTime s) {
        return s == null;
    }

    public Boolean isChanged(Opportunity oldOpp, Object oldVal, Object newVal) {
        return oldOpp != null && (oldVal != newVal);
    }

}