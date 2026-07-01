/**************************************************************************************************************
@Author: Chalapati Murru (LTIMindtree)
@Description: This class is used to check all the validations during Info Lease API call.
@User Story: SAL-5692 Expo: Opportunity Refactor
@Created Date: Jan-30-2026
**************************************************************************************************************/
public class PEAC_BWInfoLeaseValidations {
    
    public static void validateOppData(PEAC_BWInfoLeaseDataWrapper dataWrap){
        //SAL-7082: Start - Manish
        if (PEAC_ValidateOpportunityBookToInfolease.validateOpportunityForBookToInfoleaseProcess(dataWrap.opp.Id))
            throw new TC_BridgewareUtilityException (System.Label.Infolease_In_Progress_Button_Message);
        //SAL-7082: END - Manish
        if (dataWrap.opp.Booked_to_External_System_Date__c != null && dataWrap.opp.Booked_to_External_System_User__c != null)
            throw new TC_BridgewareUtilityException ('This Opportunity has been booked to InfoLease already.');
        
        IL10_Flag__c il10Setting = IL10_Flag__c.getValues('GeneralSetting');
        Boolean isIL10 = il10Setting.use_IL10__c; // booking always to IL10 regardless of record
        List <String> missingFields = new List <String> ();
        
        // older ones
        if (dataWrap.opp.Terms__c == null || dataWrap.opp.Terms__c == 0) missingFields.add ('Term' );
        if (dataWrap.opp.Income_Method__c == null) missingFields.add ('Income Method');
        if (dataWrap.opp.Commencement_Date__c == null) missingFields.add ('Commencement Date' );
        if (dataWrap.opp.Invoicing_Due_Day__c == null) missingFields.add ('Invoicing Due Day');
        if (dataWrap.opp.Gross_Contract__c == null || dataWrap.opp.Gross_Contract__c == 0) missingFields.add ('Gross Contract');
        if (dataWrap.opp.Gross_Finance__c == null || dataWrap.opp.Gross_Finance__c ==0) missingFields.add ('Gross Finance');
        if (dataWrap.opp.Invoice_Description__c == null) missingFields.add ('Invoice Description');
        if (dataWrap.opp.Remit_to_Window__c == null) missingFields.add ('Remit to Window');
        if (dataWrap.opp.Payment_Frequency__c == null) missingFields.add ('Payment Frequency' );
        if (dataWrap.opp.Billing_Cycle__c == null) missingFields.add ('Billing Cycle' );
        if (dataWrap.opp.Quote_Buyout__c == null) missingFields.add ('Quote Buyout' );
        //JAH SAL-753 Removed check on 20% rule.
        //if (dataWrap.opp.Payment_Frequency__c == 'Monthly' && dataWrap.opp.First_Payment_Amount__c > dataWrap.opp.Equipment_Cost__c * 0.20) missingFields.add (Label.TC_SubmitToInfoLeaseError_FirstPaymentExceedEQCost );
        //if (dataWrap.opp.Gross_Finance__c >= dataWrap.opp.Equipment_Cost__c/2) missingFields.add (Label.TC_SubmitToInfoLeaseError_GrossFinanceExceedEqCost); // commented out for: https://gitlab.com/tamarack/marlin/issues/620
        if (dataWrap.opp.Invoice_Code__c == null ) missingFields.add ('Invoice Code' );
        if (dataWrap.opp.Invoice_Code__c == 'S' && (dataWrap.opp.Bank_Code__c == null || dataWrap.opp.Bank_Number__c == null || dataWrap.opp.Bank_Account_Number__c == null || dataWrap.opp.Bank_Account_Type__c  == null)) missingFields.add (Label.TC_SubmitToInfoLeaseError_InvoiceCodeSup);
        if (dataWrap.opp.Invoice_Code__c != 'S' && (dataWrap.opp.Bank_Code__c != null || dataWrap.opp.Bank_Number__c != null || dataWrap.opp.Bank_Account_Number__c != null || dataWrap.opp.Bank_Account_Type__c != null)) missingFields.add (Label.TC_SubmitToInfoLeaseError_InvoiceCodeNotSup);
        if (dataWrap.opp.Funding_Booking_Lease_Completed_Date__c == null) missingFields.add (Label.TC_Funding_Booking_Checklist_Required );
        Account dealerAccount = dataWrap.opp.Primary_Dealer__r?.Dealer__r;
        Boolean isPreferredDealer = dealerAccount?.Preferred_Dealer_Level__c != null;
        Decimal percentageToPEAC = dealerAccount?.Interim_Rent_PEAC_Percentage__c != null?
                                dealerAccount.Interim_Rent_PEAC_Percentage__c: 0;
        Decimal leasePaymentInterimRent = (dataWrap.opp.Lease_Payment_Interim_Rent__c != null? dataWrap.opp.Lease_Payment_Interim_Rent__c: 0).setScale(2);
        if ((!dataWrap.opp.Valid_Interim_Rent__c && !isPreferredDealer)
            || (!dataWrap.opp.Valid_Interim_Rent__c
            && !(isPreferredDealer && leasePaymentInterimRent == dataWrap.opp.Sum_Misc_Invoice_Interim_Rent__c.setScale(2) 
            && (leasePaymentInterimRent * (percentageToPEAC/100)).setScale(2) == dataWrap.opp.Sum_Blended_Interim_Rent__c.setScale(2)))){
            missingFields.add (Label.TC_SubmitToInfoLeaseError_IntRentMismatch );
        } 
        if (dataWrap.opp.Payment_Option__c == null) missingFields.add ('Payment Option' );
        if (isIL10 && dataWrap.opp.Invoice_Format__c == null) missingFields.add ('Invoice Format' );
        if (dataWrap.opp.Tax_ID__c == null) missingFields.add ('Federal Tax Id');
        if (dataWrap.opp.Business_Phone__c  == null) missingFields.add ('Business Phone');
        if (dataWrap.opp.Equipment_Cost__c  == null || dataWrap.opp.Equipment_Cost__c  == 0) missingFields.add ('Equipment Cost' );
        if (dataWrap.opp.Purchase_Options__c == null) missingFields.add ('Purchase Options');
        if (dataWrap.opp.of_Payments__c == null || dataWrap.opp.of_Payments__c == 0) missingFields.add ('# of Payments');
        if (dataWrap.opp.Payment_Amount__c == null || dataWrap.opp.Payment_Amount__c == 0) missingFields.add ('Payment Amount' );
        if (dataWrap.opp.Purchase_Options__c != 'Customer Owned' && dataWrap.opp.Residual__c == null) missingFields.add ('Residual Amount');
        if (dataWrap.opp.Residual_Method__c  == null) missingFields.add ('Residual Method' );
        if (dataWrap.opp.Payment_Option__c == null) missingFields.add ('Payment Option' );
        if (dataWrap.opp.Lead_Invoice_Days__c  == null || dataWrap.opp.Lead_Invoice_Days__c  == 0) missingFields.add ('Lead Invoice Days' );
        if (dataWrap.opp.Late_Charge_Rate__c == null || dataWrap.opp.Late_Charge_Rate__c == 0) missingFields.add ('Late Charge Rate' );
        if (dataWrap.opp.Grace_Period__c == null) missingFields.add ('Grace Period' );
        if (dataWrap.opp.Contract_Type__c == null) missingFields.add ('Contract Type');
        
        if (dataWrap.opp.Account_Business_Street__c == null) missingFields.add ('Account Business Street' );
        if (dataWrap.opp.Account_Business_City__c == null) missingFields.add ('Account Business City' );
        if (dataWrap.opp.Account_Business_State_Province__c == null) missingFields.add ('Account Business Zip/Postal Code' );
        if (dataWrap.opp.Account_Business_Zip_Postal_Code__c == null) missingFields.add ('Account Business Zip/Postal Code' );
        if (dataWrap.opp.Account_Billing_Street__c == null) missingFields.add ('Account Billing Street' );
        if (dataWrap.opp.Account_Billing_City__c == null) missingFields.add ('Account Billing City' );
        if (dataWrap.opp.Account_Billing_State_Province__c == null) missingFields.add ('Account Billing State/Province' );
        if (dataWrap.opp.Account_Billing_Zip_Postal_Code__c == null) missingFields.add ('Account Billing Zip/Postal Code');
        if (dataWrap.opp.Primary_Contact__c == null) missingFields.add ('Primary Contact');
        if (dataWrap.opp.Billing_Attention_To__c == null) missingFields.add ('Attention To' );
        if (dataWrap.opp.Billing_Contact__c == null) missingFields.add ('Billing Contact');
        //if (dataWrap.opp.Contract__c == null) missingFields.add ('Contract #');
        if (dataWrap.opp.Opportunity_Booked_Date__c == null) missingFields.add ('Opportunity Booked Date');
        if (dataWrap.opp.Loan_Record_Type__c == false && dataWrap.opp.First_Payment_Date__c == null) missingFields.add ('First Payment Date'); // SAL 405
        if (dataWrap.opp.Number_of_Units__c == null || dataWrap.opp.Number_of_Units__c ==0) missingFields.add ('# of Units');
        // remove for branch to platform
        //if(dataWrap.opp.Marlin_Business_Group__c == 'IFP' && dataWrap.opp.Brokers1__r.size() == 0) missingFields.add ('Need to add a Broker for IFP opportunities');
        //if(dataWrap.opp.Marlin_Business_Group__c == 'Franchise' && dataWrap.opp.Franchisors__r.size() == 0) missingFields.add ('Need to add a Franchisor for Franchise opportunities');
        
        // Added on 12/11 for Gitlab item 769
        if(dataWrap.opp.Opportunity_Booked_Date__c != null && dataWrap.opp.Opportunity_Booked_Date__c.date() > Datetime.now().date()) missingFields.add ('Booking Date cannot be greater than todays date.');
        
        //Added for 2.2, SAL-440 JAH
        if(dataWrap.opp.Facility_Code__c == null && dataWrap.opp.Orig_Lease_Received__c == null) missingFields.add ('Facility Code or Orig Lease Received must be completed before booking.');
 
        Boolean customerOwnedPurchaseOption = dataWrap.opp.Purchase_Options__c == 'Customer Owned';    
        List<String> customerOwnedErrorList = new List<String>();
        List<String> purOption26ErrorList = new List<String>();
        List<string> assetZeroCostErrorList = new List <String>();
        List<String> skipResidAmtPurOptnsList = new List<String>{'Customer Owned','26-Rental-No','1.00 Out'};//SAL-6125 & SAL-5284
        List<String> AssetIdentifiers = new List<String>();
        for (Asset__c asset : dataWrap.assetList) {
           
            AssetIdentifiers.add(asset.Id);
            List <String> errors = new List <String> ();
            if (String.isNotEmpty(asset.IL_Upfront_Tax_Code__c) && (asset.Upfront_Tax_Method__c  == null || asset.Responsibility_Code__c == null || asset.Upfront_State_Tax_Amount__c == null || asset.Upfront_County_Transit_Tax_Amount__c == null || asset.Upfront_County_Tax_Amount__c == null || asset.Upfront_City_Transit_Tax_Amount__c  == null || asset.Upfront_City_Tax_Amount__c  == null || asset.Total_Upfront_Tax_Amount__c  == null || asset.Total_Upfront_Tax_Amount__c == 0)) errors.add (Label.TC_SubmitToInfoLeaseError_AssetUpfrontTax);
            if (asset.Tax_Date_Time__c == null && !PEAC_ConstantClass.ASSET_EQUIPMENT_STATE_NON_US_STATES.Equals(asset.Equipment_State__c)) errors.add ('Tax Matrix needs to be generated before booking');
            TC_RequiredFieldHelper.assetEnterBookingStage (asset, errors);
            if (!errors.isEmpty ()) missingFields.add ('Asset ' + asset.Name + ': ' + errors);
            
            //SAL-6125 & SAL-5284
            if (!skipResidAmtPurOptnsList.contains(dataWrap.opp.Purchase_Options__c) && asset.Cost__c > 0 && (asset.Residual_Amount__c == null || asset.Residual_Amount__c <= 0)) customerOwnedErrorList.add(asset.Name);
			//Added OL-Operating Lease (Rajesh LTM)
			if (PEAC_ConstantClass.TRUE_AND_OPERATING_LEASE.Contains(dataWrap.opp.Contract_Type__c) && dataWrap.opp.Purchase_Options__c == '26-Rental-No' && asset.Cost__c > 0 && asset.Residual_Amount__c != null && asset.Residual_Amount__c != 0){
                purOption26ErrorList.add(asset.Name);  // SAL - 4677
            }
            if (asset.Cost__c==0 && asset.Residual_Amount__c !=0 && asset.Residual_Amount__c != null) assetZeroCostErrorList.add(asset.name); // Sal -5284  
            if (customerOwnedPurchaseOption && asset.Residual_Amount__c > 0) customerOwnedErrorList.add(asset.Name);    
        }    
        
        if (!assetZeroCostErrorList.isEmpty()){
            missingFields.add('Asset Cost is Zero, the residual amount must be zero['+string.join(assetZeroCostErrorList,',')+']');// SAL - 5284
        }

        if (!customerOwnedErrorList.isEmpty()) {    
            String errorString = customerOwnedPurchaseOption ? 'Customer Owned purchase options must not have residual [' : 'This purchase option requires residual in the funding and booking stage [';    
            missingFields.add(errorString + String.join(customerOwnedErrorList, ', ') + ']');
        }
        if (!purOption26ErrorList.isEmpty()) {
            missingFields.add('26-Rental-No This purchase option\'s residual is not 0.00 and contract type is TL [' + String.join(purOption26ErrorList, ', ') + ']'); // SAL - 4677
        }
        List<Meter_Type__c> MeterTypes = new List<Meter_Type__c>();
            MeterTypes = [Select ID, Asset__c, Existing_Units__c, Initial_Reading_Date__c,Billing_Cycle__c, Usage_Rate__c, Meter_Type__c, Usage_Allowance__c, Overage_Percentage__c, Pay_Code__c, Meter_Rate_Type_Code__c, Account__c, Overage_Cycle__c, Read_Cycle__c FROM Meter_Type__c WHERE Asset__c IN :AssetIdentifiers];
        if(MeterTypes.size()>0){
            for(Meter_Type__c mt:MeterTypes){
                List<String> errors = new List<String>();
                if(mt.Asset__c==null||mt.Existing_Units__c==null||mt.Initial_Reading_Date__c==null||mt.Billing_Cycle__c==null||mt.Usage_Rate__c==null||mt.Meter_Type__c==null||mt.Usage_Allowance__c==null||mt.Overage_Percentage__c==null||mt.Pay_Code__c==null||mt.Meter_Rate_Type_Code__c==null||mt.Account__c==null||mt.Read_Cycle__c==null){
                    errors.add('One or more Meter Type records has missing information. Please review any Meter Type records and make sure all fields are populated');
                }
                if (!errors.isEmpty ()) missingFields.add('Meter Type : '+errors);
            }
        }
        
        for (Miscellaneous_Billable_Item__c mbi : dataWrap.miscBillableItemList) {
            List <String> errors = new List <String> ();
            if (mbi.Due_Date__c == null) errors.add ('Due Date');
            if (mbi.Misc_Item_Description__c == null) errors.add ('Description');
            if (mbi.Billing_Cycle__c <> dataWrap.opp.Payment_Frequency__c) errors.add('Billing Cycle mismatch');
            if (mbi.First_Payment_Date__c == null) errors.add('First Payment Date');
            if (!errors.isEmpty ()) missingFields.add ('Misc Billable Item ' + mbi.Name + ': ' + errors);
        }
        
        for (Miscellaneous_Invoice_Item__c  mii : dataWrap.miscInvoiceItemList) {
            List <String> errors = new List <String> ();
            if (mii.Due_Date__c == null) errors.add ('Due Date');
            if (mii.Description__c  == null) errors.add ('Description');
            if (!errors.isEmpty ()) missingFields.add ('Misc Invoice Item ' + mii.Name + ': ' + errors);
        }
        
        for (Blended_Income_Item__c bii : dataWrap.blendedIncomeItemList) {
            List <String> errors = new List <String> ();
            if (bii.Blended_Income_Amount__c  == null || bii.Blended_Income_Amount__c  ==0) errors.add ('Amount');
            if (bii.Begin_Date__c != dataWrap.opp.Commencement_Date__c) errors.add('Blended Income Begin Date is not equal to the Commencement Date');
            if (!errors.isEmpty ()) missingFields.add ('Blended Income Item ' + bii.Name + ': ' + errors);
        }
        
        Dealer__c primaryDealer = new Dealer__c();
        
        for (Dealer__c dealer : dataWrap.dealerList) {
            if (dealer.Primary_Dealer__c){
                primaryDealer = dealer;
                break;
            }
        }
        if (!missingFields.isEmpty () && !Test.isRunningTest()) throw new TC_BridgewareUtilityException (missingFields + ' required when submitting to InfoLease');
    }

    public static PEAC_BWInfoLeaseDataWrapper buildDataWrapper(String oppId){
        PEAC_BWInfoLeaseDataWrapper dataWrapper = new PEAC_BWInfoLeaseDataWrapper();
        dataWrapper.variablePayList = [SELECT of_payments__c,Payment_Amount__c FROM Variable_Payment__c
                            WHERE Opportunity__c =: oppId ORDER BY Name ASC];

        dataWrapper.blendedIncomeItemList = [SELECT Include_in_Quote__c,Blended_Income_Amount__c,Begin_Date__c,Booking_Date__c,
                            Calculated_Rate__c,Blended_Income_Code__c,Dealer_Code__c,Inc_Blended_Yield__c,
                            Income_Method__c,
                            Income_Tax_Method__c,
                            Term__c,
                            Timing__c,
                            Name
                            FROM Blended_Income_Item__c WHERE Opportunity__c =:oppId];
       	
       	dataWrapper.assetList = [SELECT Tax_Date_Time__c,Customer_PO_Number__c,Store_Number__c,
                                 Operating_Depreciation_Method__c,
                                 Operating_Depreciation_Life__c,
                                 Operating_Depreciation_Basis__c,
                                 Operating_Begin_Depreciation_Date__c,
                            PTAX_Admin_Fee_CD__c,
                            Vehicle_Type__c,
                            Mileage__c,
                            Sleeper_Day_Cab__c,
                            LC_City_Tax_Code__c,
                            LC_County_Tax_Code__c,
                            LC_State_Tax_Code__c,
                            Misc_City_Tax_Code__c,
                            Misc_County_Tax_Code__c,
                            Misc_State_Tax_Code__c,
                            Owner_Operator__c,
                            Vehicle_year__c,
                            Cost__c,
                            Sales_Profit__c,
                            Vehicle_Make__c,
                            Other_Vehicle_Make__c,
                            ACE_Depreciation_Basis__c,
                            Asset_Description__c,
                            ADS_Class_Life_in_Months__c,
                            AMT_Depreciation_Basis__c,
                            Recourse_Amount__c,
                            Recourse_Code__c,
                            Recourse_Comments__c,
                            Recourse_Percent__c,
                            Recourse_Term__c,
                            Asset_Status__c,
                            Usage_Additional_Rate__c,
                            Estimate_Readings_Allowed__c,
                            Usage_Billing_Cycle__c,
                            Contracted_Cycle__c,
                            Contracted_Thru_Date__c,
                            Number_of_units_used_CTD__c,
                            Usage_Dealer_Invoice_Number__c,
                            Dealer_Read_Date__c,
                            Reading_Dates__c,
                            Reading_Method__c,
                            Reading_Units__c,
                            Service_Date__c,
                            of_service_units_made__c,
                            Additional_Copies__c,
                            Begin_Depreciation_Date__c,
                            Calculate_ACE_Depr__c,
                            Calculate_AMT__c,
                            Depreciation_Basis__c,
                            City_Code__c,
                            City_Tax_Code__c,
                            City_Tax_Percentage__c,
                            County_Code__c,
                            County_Tax_Code__c,
                            County_Tax_Percentage__c,
                            Equipment_Street__c,
                            Equipment_Address_2__c,
                            Equipment_City__c,
                            Equipment_Code__c,
                            Equipment_Sub_Category__c,
                            Description__c,
                            Equipment_Discount__c,
                            List_Price__c,
                            Equipment_State__c,
                            Equipment_Zip__c,
                            Federal_Calculation_Basis__c,
                            Federal_Convention__c,
                            Federal_Life__c,
                            Manager_Residual__c,
                            //SAL-4968
                            Manufacturer__r.Dealer_Number__c,
                            Model__c,
                            New_Used__c,
                            Property_Status__c,
                            Purchase_Options__c,
                            Renewal_Option__c,
                            Quantity__c,
                            Residual_Percentage__c,
                            Residual_Amount__c,
                            Federal_Method__c,
                            Serial_Number__c,
                            State_Begin_Depreciation_Date__c,
                            State_Depreciation_Basis__c,
                            State_Life_in_Months__c,
                            State_Method__c,
                            State_Code__c,
                            State_Tax_Code__c,
                            State_Tax_Percentage__c,
                            City_Transit_Tax_Percentage__c,
                            County_Transit_Tax_Percentage__c,
                            Total_Cost__c,
                            Upfront_City_Location_Code__c,
                            Upfront_City_Tax_Amount__c,
                            Upfront_County_Location_Code__c,
                            Upfront_County_Tax_Amount__c,
                            Financed_Trigger__c,
                            Upfront_Responsibility_Code__c,
                            Upfront_State_Location_Code__c,
                            Upfront_State_Tax_Amount__c,
                            IL_Upfront_Tax_Code__c,
                            Upfront_City_Transit_Tax_Amount__c,
                            Upfront_County_Transit_Tax_Amount__c,
                            Oper_Depr_LIM__c,
                            Salvage_Value__c,
                            Upfront_Tax_Paid_To__c,
                            End_User_Billing_Address__c,
                            Name,
                            Upfront_Tax_Method__c,
                            Responsibility_Code__c,
                            Total_Upfront_Tax_Amount__c,
                            Orig_Cost__c,
                            Usage_User_Table__c,
                            Upfront_Tax_Basis__c,
                            Equipment_Location_City__c,
                            Equipment_Location_County__c,
                            Equipment_Location_State__c,
                            Bonus_Depreciation__c, 
                            Customer_Reference__c,
                            Department_Location__c,
                            Dealer_Residual__c,
                            Asset_Cost_Percent__c,//SAL-6693
                            //Begin: SAL-6343
                            Alias_Name__c,
                            Asset_Classification__c,
                            Rental_Amount_fml__c
                            //End: SAL-6343
                            FROM Asset__c WHERE Opportunity__c =:oppId ORDER BY Cost__c DESC];
        
        dataWrapper.miscBillableItemList = [SELECT
                            Misc_Amount_Type__c,
                            Future_Bill_Misc_Type__c,
                            Final_Payment_Date__c,
                            First_Payment_Date__c,
                            Included_in_Rental__c,
                            Amount__c,
                            CB_Disp__c,
                            Billing_Cycle__c,
                            Due_Date__c,
                            Misc_Item_Description__c,
                            Misc_GL_Code__c,
                            Pay_Code__c,
                            Misc_Tax__c,
                            Dealer_Code__c,
                            Name,
                            PassThrough__c,
                            PaymentType__c,
                            PassThroughPercentage__c
                            FROM Miscellaneous_Billable_Item__c WHERE Opportunity__c =:Oppid];
        
        dataWrapper.miscInvoiceItemList = [SELECT
                            Include_in_Rent__c,
                            Amount__c,
                            MIDisp__c,
                            Due_Date__c,
                            Description__c,
                            GL_Code__c,
                            Pay_Code__c,
                            Taxable__c,
                            Dealer_Code__c,
                            Name, Interim_Percentage__c, PassThrough__c, PaymentType__c, PassThroughPercentage__c
                            FROM Miscellaneous_Invoice_Item__c WHERE Opportunity__c =:oppId];
        
        dataWrapper.dealerList = [SELECT Dealer__r.Dealer_Number__c, Dealer__r.CCAN__c, Primary_Dealer__c, Dealer__r.Business_Phone__c,
                            Dealer__r.Private_Label__c, Dealer__r.White_Label__c,
                            Dealer__r.Name,Dealer__r.Business_Address__c,Dealer__r.Business_Address2__c,Dealer__r.Business_City__c,Dealer__r.Business_State__c,Dealer__r.Business_Zip__c//SAL-6343
                            FROM Dealer__c WHERE Primary_Dealer__c = True AND Opportunity__c =:oppId Order by CreatedDate ASC LIMIT 1];
        
        dataWrapper.primaryBorkerList = [SELECT
                            Account__r.Dealer_Number__c,
                            Account__r.CCAN__c,
                            Broker_Dealer_Number__c,
                            Primary_Broker__c
                            FROM Broker__c
                            WHERE Primary_Broker__c = true AND Opportunity__c =:oppId];
		
        dataWrapper.franchisorList = [SELECT
                            Franchisor__r.Dealer_Number__c,
                            Franchisor_Number__c
                            FROM Franchisor__c WHERE Opportunity__c =:oppId];
                               
        dataWrapper.opp = [SELECT
                            Valid_Interim_Rent__c,Originating_Business__c,
                            Credit_Stips_Completed_Date__c,
                            Primary_Contact__c,
                            of_Payments__c ,
                            Business_Phone__c,
                            Marlin_Business_Group__c,
                            Funding_Booking_Lease_Completed_Date__c ,
                            Funding_Booking_Loan_Completed_Date__c,
                            Payment_Frequency__c,
                            Commencement_Date__c,
                            Down_Payment__c,
                            Purchase_Options__c,
                            Approving_Authority__c,
                            Account_Billing_Street__c,
                            Account_Billing_Street2__c,
                            Billing_Attention_To__c,
                            Account_Billing_City__c,
                            Account.Name,
                            Account_Billing_State_Province__c,
                            Account_Billing_Zip_Postal_Code__c,
                            Bank_Code__c,
                            Billing_Cycle__c,
                            Opportunity_Booked_Date__c,
                            Branch__c,
                            Broker_Book_Method__c,
                            Broker_Code__c,
                            Broker_Fees__c,
                            Broker_Tax_Method__c,
                            Primary_Contact_Fax__c,
                            Contract__c,
                            Payment_Amount__c,
                            Terms__c,
                            Primary_Contact__r.Name,
                            Primary_Contact__r.Phone,
                            Application__c,
                            Account_Business_Street__c,
                            Account_Business_Street2__c,
                            Account_Business_City__c,
                            CCAN__c,
                            Account.DBA__c,
                            Account_Business_State_Province__c,
                            Account_Business_Zip_Postal_Code__c,
                            Account.Dealer_Number__c,
                            of_ending_payments__c,
                            Equipment_Cost__c,
                            Tax_ID__c,
                            Broker_First_Fee_Date__c,
                            First_Payment_Amount__c,
                            First_Payment_Date__c,
                            Grace_Period__c,
                            Gross_Contract__c,
                            Gross_Finance__c,
                            Income_Method__c,
                            Income_Start_Date__c,
                            Interim_Rent__c,
                            Lead_Invoice_Days__c,
                            Invoicing_Due_Day__c,
                            Invoice_Code__c,
                            Invoice_Description__c,
                            Late_Charge_Rate__c,
                            Contract_Type__c,
                            Lessor__c,
                            Minimum_Late_Charge__c,
                            Marketing_Rep_Percentage__c,
                            Region__c,
                            Marketing_Rep_Code__c,
                            Municipal_Lease__c,
                            Primary_Contact_Email__c,
                            Number_of_Units__c,
                            Office__c,
                            Product_Line__c,
                            Program_Type__c,
                            Promotion__c,
                            PO_Number__c,
                            Payment_Option__c,
                            Ending_Pymts_in_Advance__c,
                            Payments_In_Arrears__c,
                            of_beginning_payments__c,
                            Quote_Buyout__c,
                            Out_of_Balance__c,
                            Remit_to_Window__c,
                            Residual__c,
                            Residual_Method__c,
                            Primary_Contact_Name__c,
                            Primary_Contact_Phone__c,
                            Sales_Leaseback__c,
                            Security_Deposit__c,
                            Recurring__c,
                            Bank_Account_Number__c,
                            Bank_Account_Type__c,
                            Bank_Number__c,
                            ACH_Miscs__c,
                            //Verbal_Contact_Number__c, //updated as per SAL- 4971
                            SLG__c,// updated as per SAL- 4971
                            Renewal_Length__c,//SAL-4799- changed UM_Alpha_Field8__c to Renewal_Length__c
                            Reprint_Invoice__c,
                            Security_Comments__c,
                            Facility_Code__c,
                            NPV_for_Profit__c,
                            Orig_Lease_Received__c,
                            Use_Tax_Responsibility__c,
                            Variable_Payment__c,
                            Primary_Contact__r.Email,
                            DBA_Override__c,
                            GL_Link__c,
                            Billing_Contact__r.FirstName,
                            Billing_Contact__r.LastName,
                            Billing_Contact__r.Email,
                            Billing_Contact__r.Phone,
                            Primary_Contact__r.FirstName,
                            Primary_Contact__r.LastName,
                            Invoice_Format__c, Blind_Contract__c,
                            CPC__c, Lease_Payment_Interim_Rent__c, Sum_Misc_Invoice_Interim_Rent__c, Sum_Blended_Interim_Rent__c, Metered__c, Meter_Account__c,
                            Primary_Dealer__r.Dealer__r.Preferred_Dealer_Level__c, Primary_Dealer__r.Dealer__r.Interim_Rent_PEAC_Percentage__c, 
                            Booked_to_External_System_Date__c,
                            Booked_to_External_System_User__c,
                            Late_Charge_Exempt__c,
                            Loan_Record_Type__c,
                            RecordType.Name,
                            Owner.Profile.Name,
                            Number_of_Assets__c
                            FROM Opportunity
                            WHERE Id = :oppId];
        //Begin: SAL-6343
        /*dataWrapper.contractList = [SELECT 
                            Id,Name,Requisition_Purchase_Req_No__c
                            FROM Contract__c WHERE Opportunity__c =:oppId ORDER BY CreatedDate DESC LIMIT 1];*/
        
        dataWrapper.purchaseOrderList = [SELECT Id,Name,Customer_PO_Number__c,Delivery_Order_Date__c,Item_Number__c,
                            Issued_By__r.Name,Issued_By_Address_1__c,Issued_By_Address_2__c,Issued_By_City__c,
                            Issued_By_State__c,Issued_By_Zip__c,Administered_By__r.Name,Administered_By_Address_1__c,
                            Administered_By_Address_2__c,Administered_By_City__c,Administered_By_State__c,
                            Administered_By_Zip__c,Payment_Made_By__r.Name,Payment_Made_By_Address_1__c,
                            Payment_Made_By_Address_2__c,Payment_Made_By_City__c,Payment_Made_By_State__c,
                            Payment_Made_By_Zip__c
                            FROM Purchase_Order__c WHERE Opportunity__c =:oppId AND RecordType.DeveloperName = 'Federal_Information' ORDER BY CreatedDate DESC LIMIT 1];
        //End: SAL-6343
        return dataWrapper;
    }
    
    public class TC_BridgewareUtilityException extends Exception {}
}