/*
* @author : sfdcdev, Tamarack Consulting, Inc.
* @date : 02/15/2018
* @description: http://docs.bridgewaretamarack.apiary.io
*
* © Copyright 2003 - 2018 Tamarack Consulting, Inc.  All Rights Reserved.
* 
*/

public with sharing class TC_BridgewareUtility implements Database.AllowsCallouts{
    private static Bridgeware_Service_Setting__c setting;
    private static TC_BridgewareUtility util;
    private static Map <String, Tax_Jurisdiction_Mapping__mdt> taxJurisdictionMap = new Map <String, Tax_Jurisdiction_Mapping__mdt>();
    private TC_BridgewareUtility() {}
    
    public static TC_BridgewareUtility getInstance () {
        if (util == null) util = new TC_BridgewareUtility ();
        return util;
    }
    
    public Bridgeware_Service_Setting__c getServiceSettings () {
        setting = Bridgeware_Service_Setting__c.getInstance();
        if (setting == null) setting = new Bridgeware_Service_Setting__c();
        
        return setting;
    }
    
    public void logInfo (String log) {
        if (getServiceSettings().Enable_Debug_Log__c)
            System.debug(LoggingLevel.INFO, '---INFO---> \n' + log );
    }
    
    public void logError (String log) {
        if (getServiceSettings().Enable_Debug_Log__c)
            System.debug(LoggingLevel.ERROR, '---ERROR----> \n' + log );
    }
    
    public static TC_BridgewareBookContractRespBean sendToBridgeware (Id oppId) {
        
        Map<Id, String> emptyMap = new Map<Id, String>();
        return sendToBridgeware(oppId, emptyMap);
    }
    
    public static TC_BridgewareBookContractRespBean sendToBridgeware(Id oppId, Map<Id, String> accountMap) {
        TC_BridgewareService service = new TC_BridgewareServiceImpl();
        
        TC_BridgewareBookContractRequestBean bean = createRequest (oppId, accountMap );
        
        TC_BridgewareBookContractRequestUCI uci = new TC_BridgewareBookContractRequestUCI ();
        uci.setUciConfig (bean.getUciConfig ());
        uci.setUciRecord (bean.toUCIString());
        uci.setUciKey (oppId);
        
        TC_BridgewareBookContractRespBean response = service.bookContract(uci);
        if (response.statusMessage == 'Success' && String.isNotEmpty(response.contractNbr)) {
            List<Opportunity> opps = [SELECT Id, Opportunity_Booked_Date__c, Booked_Amount__c, Equipment_Cost__c, Gross_Finance__c From Opportunity Where Id =: oppId];
            
            if (opps.size () > 0) {
                Opportunity opp = opps[0];
                opp.Contract__c = response.contractNbr;
                opp.Application_Status__c = 'Booked';
                //opp.StageName = 'Funded/Booked';
                if(opp.Opportunity_Booked_Date__c == null){
                    opp.Opportunity_Booked_Date__c = System.now();
                }
                if(opp.Booked_Amount__c == null){
                    opp.Booked_Amount__c = opp.Equipment_Cost__c;
                }
                opp.Booked_to_External_System_Date__c = System.now();
                opp.Booked_to_External_System_User__c = System.UserInfo.getUserId();
                try {
                    update opp;
                }
                catch (Exception e) {
                    update new Opportunity(Id = opp.Id, Contract__c = response.contractNbr,
                                           Booked_to_External_System_Date__c = System.now(),
                                           Booked_to_External_System_User__c = System.UserInfo.getUserId(),
                                           Book_to_InfoLease_Error__c = e.getMessage()
                                          );
                }
            }
        }
        
        return response;
    }
    
    public static TC_BridgewareBookContractRequestBean createRequest(Id oppId, Map<Id, String> accountMap) {
        Opportunity opp = [SELECT
                           (SELECT Name,
                            RP_PRIN_GUAR_CODE__c,
                            Account__r.CCAN__c,
                            Contact__r.SSN__c,
                            Contact__r.Contact_CCAN__c,
                            Account__r.Name,
                            Account__r.Id,
                            RecordType.Name
                            FROM Guarantor__r),
                           Valid_Interim_Rent__c,
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
                          // Verbal_Contact_Number__c, //updated as per SAL- 4971
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
                           (SELECT of_payments__c,
                            Payment_Amount__c
                            FROM Variable_Payments__r
                            ORDER BY Name ASC),
                           (SELECT
                            Include_in_Quote__c,
                            Blended_Income_Amount__c,
                            Begin_Date__c,
                            Booking_Date__c,
                            Calculated_Rate__c,
                            Blended_Income_Code__c,
                            Dealer_Code__c,
                            Inc_Blended_Yield__c,
                            Income_Method__c,
                            Income_Tax_Method__c,
                            Term__c,
                            Timing__c,
                            Name
                            FROM Blended_Income_Items__r),
                           (SELECT
                            Tax_Date_Time__c,
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
                            Dealer_Residual__c
                            FROM Assets__r ORDER BY Cost__c DESC),
                           (SELECT
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
                            FROM Miscellaneous_Billable_Items__r),
                           (SELECT
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
                            FROM Miscellaneous_Invoice_Items__r),
                           (SELECT
                            Dealer__r.Dealer_Number__c, Dealer__r.CCAN__c, Primary_Dealer__c, Dealer__r.Business_Phone__c,
                            Dealer__r.Private_Label__c, Dealer__r.White_Label__c
                            FROM Brokers__r WHERE Primary_Dealer__c = True Order by CreatedDate ASC LIMIT 1
                           ),
                           (SELECT
                            Account__r.Dealer_Number__c,
                            Account__r.CCAN__c,
                            Broker_Dealer_Number__c,
                            Primary_Broker__c
                            FROM Brokers1__r
                            WHERE Primary_Broker__c = true
                           ),
                           (SELECT
                            Franchisor__r.Dealer_Number__c,
                            Franchisor_Number__c
                            FROM Franchisors__r
                           ),
                           Booked_to_External_System_Date__c,
                           Booked_to_External_System_User__c,
                           Late_Charge_Exempt__c,
                           Loan_Record_Type__c,
                           RecordType.Name,
                           Owner.Profile.Name
                           FROM Opportunity
                           WHERE Id = :oppId];
        
        
        if (opp.Booked_to_External_System_Date__c != null && opp.Booked_to_External_System_User__c != null)
            throw new TC_BridgewareUtilityException ('This Opportunity has been booked to InfoLease already.');
        
        IL10_Flag__c il10Setting = IL10_Flag__c.getValues('GeneralSetting');
        Boolean isIL10 = il10Setting.use_IL10__c; // booking always to IL10 regardless of record
        List <String> missingFields = new List <String> ();
        
        // older ones
        if (opp.Terms__c == null || opp.Terms__c == 0) missingFields.add ('Term' );
        if (opp.Income_Method__c == null) missingFields.add ('Income Method');
        if (opp.Commencement_Date__c == null) missingFields.add ('Commencement Date' );
        if (opp.Invoicing_Due_Day__c == null) missingFields.add ('Invoicing Due Day');
        if (opp.Gross_Contract__c == null || opp.Gross_Contract__c == 0) missingFields.add ('Gross Contract');
        if (opp.Gross_Finance__c == null || opp.Gross_Finance__c ==0) missingFields.add ('Gross Finance');
        if (opp.Invoice_Description__c == null) missingFields.add ('Invoice Description');
        if (opp.Remit_to_Window__c == null) missingFields.add ('Remit to Window');
        if (opp.Payment_Frequency__c == null) missingFields.add ('Payment Frequency' );
        if (opp.Billing_Cycle__c == null) missingFields.add ('Billing Cycle' );
        if (opp.Quote_Buyout__c == null) missingFields.add ('Quote Buyout' );
        //JAH SAL-753 Removed check on 20% rule.
        //if (opp.Payment_Frequency__c == 'Monthly' && opp.First_Payment_Amount__c > opp.Equipment_Cost__c * 0.20) missingFields.add (Label.TC_SubmitToInfoLeaseError_FirstPaymentExceedEQCost );
        //if (opp.Gross_Finance__c >= opp.Equipment_Cost__c/2) missingFields.add (Label.TC_SubmitToInfoLeaseError_GrossFinanceExceedEqCost); // commented out for: https://gitlab.com/tamarack/marlin/issues/620
        if (opp.Invoice_Code__c == null ) missingFields.add ('Invoice Code' );
        if (opp.Invoice_Code__c == 'S' && (opp.Bank_Code__c == null || opp.Bank_Number__c == null || opp.Bank_Account_Number__c == null || opp.Bank_Account_Type__c  == null)) missingFields.add (Label.TC_SubmitToInfoLeaseError_InvoiceCodeSup);
        if (opp.Invoice_Code__c != 'S' && (opp.Bank_Code__c != null || opp.Bank_Number__c != null || opp.Bank_Account_Number__c != null || opp.Bank_Account_Type__c != null)) missingFields.add (Label.TC_SubmitToInfoLeaseError_InvoiceCodeNotSup);
        if (opp.Funding_Booking_Lease_Completed_Date__c == null) missingFields.add (Label.TC_Funding_Booking_Checklist_Required );
        Account dealerAccount = opp.Primary_Dealer__r?.Dealer__r;
        Boolean isPreferredDealer = dealerAccount?.Preferred_Dealer_Level__c != null;
        Decimal percentageToPEAC = dealerAccount?.Interim_Rent_PEAC_Percentage__c != null?
                                dealerAccount.Interim_Rent_PEAC_Percentage__c: 0;
        Decimal leasePaymentInterimRent = (opp.Lease_Payment_Interim_Rent__c != null? opp.Lease_Payment_Interim_Rent__c: 0).setScale(2);
        if ((!opp.Valid_Interim_Rent__c && !isPreferredDealer)
            || (!opp.Valid_Interim_Rent__c
            && !(isPreferredDealer && leasePaymentInterimRent == opp.Sum_Misc_Invoice_Interim_Rent__c.setScale(2) 
            && (leasePaymentInterimRent * (percentageToPEAC/100)).setScale(2) == opp.Sum_Blended_Interim_Rent__c.setScale(2)))){
            missingFields.add (Label.TC_SubmitToInfoLeaseError_IntRentMismatch );
        } 
        
        if (opp.Payment_Option__c == null) missingFields.add ('Payment Option' );
        
        if (isIL10 && opp.Invoice_Format__c == null) missingFields.add ('Invoice Format' );
        
        
        
        // July 23 ones: https://gitlab.com/tamarack/marlin/issues/164
        
        
        if (opp.Tax_ID__c == null) missingFields.add ('Federal Tax Id');
        if (opp.Business_Phone__c  == null) missingFields.add ('Business Phone');
        if (opp.Equipment_Cost__c  == null || opp.Equipment_Cost__c  == 0) missingFields.add ('Equipment Cost' );
        if (opp.Purchase_Options__c == null) missingFields.add ('Purchase Options');
        if (opp.of_Payments__c == null || opp.of_Payments__c == 0) missingFields.add ('# of Payments');
        if (opp.Payment_Amount__c == null || opp.Payment_Amount__c == 0) missingFields.add ('Payment Amount' );
        if (opp.Purchase_Options__c != 'Customer Owned' && opp.Residual__c == null) missingFields.add ('Residual Amount');
        if (opp.Residual_Method__c  == null) missingFields.add ('Residual Method' );
        if (opp.Payment_Option__c == null) missingFields.add ('Payment Option' );
        if (opp.Lead_Invoice_Days__c  == null || opp.Lead_Invoice_Days__c  == 0) missingFields.add ('Lead Invoice Days' );
        if (opp.Late_Charge_Rate__c == null || opp.Late_Charge_Rate__c == 0) missingFields.add ('Late Charge Rate' );
        if (opp.Grace_Period__c == null) missingFields.add ('Grace Period' );
        if (opp.Contract_Type__c == null) missingFields.add ('Contract Type');
        
        if (opp.Account_Business_Street__c == null) missingFields.add ('Account Business Street' );
        if (opp.Account_Business_City__c == null) missingFields.add ('Account Business City' );
        if (opp.Account_Business_State_Province__c == null) missingFields.add ('Account Business Zip/Postal Code' );
        if (opp.Account_Business_Zip_Postal_Code__c == null) missingFields.add ('Account Business Zip/Postal Code' );
        if (opp.Account_Billing_Street__c == null) missingFields.add ('Account Billing Street' );
        if (opp.Account_Billing_City__c == null) missingFields.add ('Account Billing City' );
        if (opp.Account_Billing_State_Province__c == null) missingFields.add ('Account Billing State/Province' );
        if (opp.Account_Billing_Zip_Postal_Code__c == null) missingFields.add ('Account Billing Zip/Postal Code');
        if (opp.Primary_Contact__c == null) missingFields.add ('Primary Contact');
        if (opp.Billing_Attention_To__c == null) missingFields.add ('Attention To' );
        if (opp.Billing_Contact__c == null) missingFields.add ('Billing Contact');
        //if (opp.Contract__c == null) missingFields.add ('Contract #');
        if (opp.Opportunity_Booked_Date__c == null) missingFields.add ('Opportunity Booked Date');
        if (opp.Loan_Record_Type__c == false && opp.First_Payment_Date__c == null) missingFields.add ('First Payment Date'); // SAL 405
        if (opp.Number_of_Units__c == null || opp.Number_of_Units__c ==0) missingFields.add ('# of Units');
        // remove for branch to platform
        //if(opp.Marlin_Business_Group__c == 'IFP' && opp.Brokers1__r.size() == 0) missingFields.add ('Need to add a Broker for IFP opportunities');
        //if(opp.Marlin_Business_Group__c == 'Franchise' && opp.Franchisors__r.size() == 0) missingFields.add ('Need to add a Franchisor for Franchise opportunities');
        
        // Added on 12/11 for Gitlab item 769
        if(opp.Opportunity_Booked_Date__c != null && opp.Opportunity_Booked_Date__c.date() > Datetime.now().date()) missingFields.add ('Booking Date cannot be greater than todays date.');
        
        //Added for 2.2, SAL-440 JAH
        if(opp.Facility_Code__c == null && opp.Orig_Lease_Received__c == null) missingFields.add ('Facility Code or Orig Lease Received must be completed before booking.');
        // SAL-730: Block Opportunities From Moving to Funding per Purchase Option    
        // If Purchase Option = Customer Owned, no Asset may have Residual > $0.    
        // If Purchase Option != Customer Owned, all Assets with Cost > $0 must also have Residual > $0.    
        Boolean customerOwnedPurchaseOption = opp.Purchase_Options__c == 'Customer Owned';    
        List<String> customerOwnedErrorList = new List<String>();
        List<String> purOption26ErrorList = new List<String>();
        List<string> assetZeroCostErrorList = new List <String>();
        //SAL-4735 Adding Validations for Meter Types
        List<String> AssetIdentifiers = new List<String>();
        for (Asset__c asset : opp.Assets__r) {
           
            AssetIdentifiers.add(asset.Id);
            List <String> errors = new List <String> ();
            if (String.isNotEmpty(asset.IL_Upfront_Tax_Code__c) && (asset.Upfront_Tax_Method__c  == null || asset.Responsibility_Code__c == null || asset.Upfront_State_Tax_Amount__c == null || asset.Upfront_County_Transit_Tax_Amount__c == null || asset.Upfront_County_Tax_Amount__c == null || asset.Upfront_City_Transit_Tax_Amount__c  == null || asset.Upfront_City_Tax_Amount__c  == null || asset.Total_Upfront_Tax_Amount__c  == null || asset.Total_Upfront_Tax_Amount__c == 0)) errors.add (Label.TC_SubmitToInfoLeaseError_AssetUpfrontTax);
            if (asset.Tax_Date_Time__c == null) errors.add ('Tax Matrix needs to be generated before booking');
            TC_RequiredFieldHelper.assetEnterBookingStage (asset, errors);
            if (!errors.isEmpty ()) missingFields.add ('Asset ' + asset.Name + ': ' + errors);
            
            if (!customerOwnedPurchaseOption && opp.Purchase_Options__c != '26-Rental-No' && asset.Cost__c > 0 && (asset.Residual_Amount__c == null || asset.Residual_Amount__c <= 0)) customerOwnedErrorList.add(asset.Name);

            if (opp.Contract_Type__c == 'TL' && opp.Purchase_Options__c == '26-Rental-No' && asset.Cost__c > 0 && asset.Residual_Amount__c != null && asset.Residual_Amount__c != 0){
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
        
        for (Miscellaneous_Billable_Item__c mbi : opp.Miscellaneous_Billable_Items__r) {
            List <String> errors = new List <String> ();
            if (mbi.Due_Date__c == null) errors.add ('Due Date');
            if (mbi.Misc_Item_Description__c == null) errors.add ('Description');
            if (mbi.Billing_Cycle__c <> opp.Payment_Frequency__c) errors.add('Billing Cycle mismatch');
            if (mbi.First_Payment_Date__c == null) errors.add('First Payment Date');
            if (!errors.isEmpty ()) missingFields.add ('Misc Billable Item ' + mbi.Name + ': ' + errors);
        }
        
        for (Miscellaneous_Invoice_Item__c  mii : opp.Miscellaneous_Invoice_Items__r) {
            List <String> errors = new List <String> ();
            if (mii.Due_Date__c == null) errors.add ('Due Date');
            if (mii.Description__c  == null) errors.add ('Description');
            if (!errors.isEmpty ()) missingFields.add ('Misc Invoice Item ' + mii.Name + ': ' + errors);
        }
        
        for (Blended_Income_Item__c bii : opp.Blended_Income_Items__r) {
            List <String> errors = new List <String> ();
            if (bii.Blended_Income_Amount__c  == null || bii.Blended_Income_Amount__c  ==0) errors.add ('Amount');
            
            //issue 501
            //https://gitlab.com/tamarack/marlin/issues/501
            if (bii.Begin_Date__c != opp.Commencement_Date__c) errors.add('Blended Income Begin Date is not equal to the Commencement Date');
            
            
            if (!errors.isEmpty ()) missingFields.add ('Blended Income Item ' + bii.Name + ': ' + errors);
        }
        
        // check for primary dealer: https://marlinbusiness.atlassian.net/browse/SAL-1007
        
        Dealer__c primaryDealer = new Dealer__c();
        
        for (Dealer__c dealer : opp.Brokers__r) {
            if (dealer.Primary_Dealer__c){
                primaryDealer = dealer;
                break;
            }
        }
        // system.debug ('#$#$#$ right before');
        TC_DealerTreatment dealerTreatment = new TC_DealerTreatment (opp); // new
        
        
        if (!missingFields.isEmpty () && !Test.isRunningTest()) throw new TC_BridgewareUtilityException (missingFields + ' required when submitting to InfoLease');
        //if (asset.IL_Upfront_Tax_Code__c  != null && (asset.Upfront_Tax_Paid_To__c == null || asset.Upfront_Tax_Method__c  == null || asset.Responsibility_Code__c == null || asset.Upfront_State_Tax_Amount__c == null || asset.Upfront_County_Transit_Tax_Amount__c == null || asset.Upfront_County_Tax_Amount__c == null || asset.Upfront_City_Transit_Tax_Amount__c  == null || asset.Upfront_City_Tax_Amount__c  == null || asset.Total_Upfront_Tax_Amount__c  == null || asset.Total_Upfront_Tax_Amount__c == 0)) errors.add (Label.TC_Booking_AssetUpfrontTax);
        //
        buildRapportMap();
        
        TC_BridgewareBookContractRequestBean bean = new TC_BridgewareBookContractRequestBean();
        bean.setUciConfig(TC_BridgewareUtility.getInstance().getServiceSettings().UCI_Config__c);
        
        List<TC_BridgewareBookContractRequestBean.RelatedParty> relatedParties = new List<TC_BridgewareBookContractRequestBean.RelatedParty>();
        
        //2018-09-28 TC - If IFP or Franchise, set some variables that are used for IFP or Franchise scenarios
        String altGuarantorCode;
        String updateDealerCode;
        integer looper;
        Boolean isWholesaleHealthcare = opp.RecordType.Name.contains('Wholesale') || opp.Owner.Profile.Name.contains('HC BD');
        
        // branch to platform effort, replaces 557 - 608. Send broker as dealer if broker exists, send franchisor as dealer if it exists
        // else send dealer as dealer
        // system.debug ('mbmbmbm dealerTreatment:' + dealerTreatment);
        
        if (dealerTreatment.sendBrokerAsDealer) {
            altGuarantorCode = '04';
            updateDealerCode = opp.Brokers1__r[opp.Brokers1__r.size()-1].Broker_Dealer_Number__c;// looks like the looper logic is grabbing the last one
            // system.debug ('mbmbmbm 04 updateDealerCode:' + updateDealerCode);
            // system.debug ('mbmbmbm opp.Brokers1__r' + opp.Brokers1__r);
        } else if (dealerTreatment.sendFranchisorAsDealer) {
            altGuarantorCode = '07';
            updateDealerCode = opp.Franchisors__r[opp.Franchisors__r.size()-1].Franchisor_Number__c;// looks like the looper logic is grabbing the last one
            // system.debug ('mbmbmbm opp.Franchisors__r: ' + opp.Franchisors__r);
            // system.debug ('mbmbmbm 07 updateDealerCode:' + updateDealerCode);
        } else {
            if (!opp.Brokers__r.isEmpty()) updateDealerCode = opp.Brokers__r[opp.Brokers__r.size ()-1].Dealer__r.Dealer_Number__c;// looks like the looper logic is grabbing the last one
            // system.debug ('mbmbmbm updateDealerCode:' + updateDealerCode);
        }
        
        /*
//If IFP, set the guar code to 04, set the dealer code to the broker, and set the ccan for guarantors to dealer code without a period
if(opp.Marlin_Business_Group__c == 'IFP'){
//Set Guarantor Code for IFP Scenario
altGuarantorCode = '04';
if (opp.Brokers1__r.size() > 0) {

looper = 0;
for(Broker__c b : opp.Brokers1__r) {
if(looper == 0) {
updateDealerCode = b.Broker_Dealer_Number__c;
}
looper = looper + 1;
}
}

//If franchise, set the guar code to 07, set the dealer code to the Franchisor, and set the ccan for guarantors to dealer code without a period
} else if(opp.Marlin_Business_Group__c == 'Franchise') {
//Set Guarantor Code for Franchise Scenario
altGuarantorCode = '07';

//Set Dealer Code for Franchise Scenario
if (opp.Franchisors__r.size() > 0) {
looper = 0;
for(Franchisor__c f : opp.Franchisors__r) {
if(looper == 0) {
//c.setDealerCode(f.Franchisor_Number__c);
updateDealerCode = f.Franchisor_Number__c;
}
looper = looper + 1;
}
}

// If not franchise or IFP, set dealer code to the related primary dealer,
// for some reason the relationship name is brokers but its actually dealers
} else {
for (Dealer__c d : opp.Brokers__r) {
if (d.Primary_Dealer__c) {
updateDealerCode = d.Dealer__r.Dealer_Number__c;
}
}

if (isWholesaleHealthcare && opp.Brokers1__r.size() > 0) {
looper = 0;

for (Broker__c b : opp.Brokers1__r) {
if (looper == 0)
updateDealerCode = b.Broker_Dealer_Number__c;

looper = looper + 1;
}
}
}*/
        
        // Set related parties from Guarantor Object
        for (Guarantor__c g : opp.Guarantor__r) {
            List<String> contractPointersPrinGuarantorCodes = new List<String>();
            List<String> principalGuarantorRecords = new List<String>();
            /*  RP_PRIN_GUAR_CODE Rapport Mapping
Guarantor  02
Corporate Guaranty  03
Principal  01
Brokers Vendor  04
Franchisors Vendor  07
*/
            
            String guarCode = 'Guarantor';
            if (g.RecordType.Name == 'Corporate'){
                guarCode = 'Corporate Guaranty';
            } else {
                if (g.RP_PRIN_GUAR_CODE__c == 'Principal')
                    guarCode = 'Principal';
            }
            
            //contractPointersPrinGuarantorCodes.add(transRapport('RP_PRIN_GUAR_CODE', (g.RecordType.Name == 'Corporate' ? 'Corporate Guaranty' : 'Guarantor')));
            contractPointersPrinGuarantorCodes.add(transRapport('RP_PRIN_GUAR_CODE', guarCode));
            String contactCcan = g.Contact__r.Contact_CCAN__c;
            // system.debug('guarantor: ' + String.valueOf(g));
            // system.debug('guarantor.Contact__c: ' + String.valueOf(g.Contact__c));
            // system.debug('guarantor.Contact__r: ' + String.valueOf(g.Contact__r));
            // system.debug('accountMap.get(g.Contact__c): ' + accountMap.get(g.Contact__c));
            // system.debug('accountMap: ' + accountMap);
            // insert new Integration_Log__c(Request_Message__c = 'temp debug log', Response_Message__c = 'guarantor: ' + String.valueOf(g)
            // +' guarantor.Contact__c: ' + String.valueOf(g.Contact__c)
            // +' guarantor.Contact__r: ' + String.valueOf(g.Contact__r));
            String ccan = g.Account__r.CCAN__c;
            if (g.RecordType.Name == 'Corporate') {
                if (ccan == null) {
                    // system.debug('Account was new, no CCAN: ' + g.Account__r.Name + ' / ' + ccan);
                    ccan = accountMap.get(g.Account__r.Id);
                    // system.debug('New CCAN: ' + ccan);
                }
            }else{
                if(contactCcan == null){
                    contactCcan = accountMap.get(g.Contact__c);
                    while (contactCcan != null && contactCcan.startsWith('0')){
                        contactCcan = contactCcan.removeStart('0');
                    }
                }
            }      
            principalGuarantorRecords.add(g.RecordType.Name == 'Corporate' ? ccan : (contactCcan != null ? contactCcan : ''));
            
            TC_BridgewareBookContractRequestBean.RelatedParty rp = new TC_BridgewareBookContractRequestBean.RelatedParty();
            rp.setContractPointersPrinGuarantorCodes(contractPointersPrinGuarantorCodes);
            rp.setPrincipalGuarantorRecords(principalGuarantorRecords);
            relatedParties.add(rp);
        }
        
        // 2018-09-27 -- Add related parties - for Franchise and IFP scenarios. CCAN is the dealer number without a period
        
        // branch to platform
        //if((opp.Marlin_Business_Group__c == 'IFP' || opp.Marlin_Business_Group__c == 'Franchise') && !(isWholesaleHealthcare && opp.Brokers1__r.size() > 0)) {
        if(dealerTreatment.sendFranchisorAsDealer || dealerTreatment.sendBrokerAsDealer) {
            
            String dealerCodeAsCCAN;
            for (Dealer__c d : opp.Brokers__r) {
                List<String> contractPointersPrinGuarantorCodes = new List<String>();
                List<String> principalGuarantorRecords = new List<String>();
                
                dealerCodeAsCCAN = d.Dealer__r.CCAN__c;
                // system.debug ('before dealerCodeAsCCAN:' + dealerCodeAsCCAN);
                if (dealerCodeAsCCAN == null) {
                    dealerCodeAsCCAN = accountMap.get(d.Dealer__r.Id);
                }
                // system.debug ('#$#$#$$ dealerCodeAsCCAN: ' + dealerCodeAsCCAN);
                
                contractPointersPrinGuarantorCodes.add(altGuarantorCode);
                principalGuarantorRecords.add(dealerCodeAsCCAN);
                TC_BridgewareBookContractRequestBean.RelatedParty rp = new TC_BridgewareBookContractRequestBean.RelatedParty();
                rp.setContractPointersPrinGuarantorCodes(contractPointersPrinGuarantorCodes);
                rp.setPrincipalGuarantorRecords(principalGuarantorRecords);
                relatedParties.add(rp);
            }
        }
        
        
        if (opp.Guarantor__r.size() == 0) {
            TC_BridgewareBookContractRequestBean.RelatedParty rp = new TC_BridgewareBookContractRequestBean.RelatedParty();
            relatedParties.add(rp);
        }
        // system.debug ('#$#$#$$ relatedParties: ' + relatedParties);
        bean.setRelatedParties(relatedParties);
        
        TC_BridgewareBookContractRequestBean.Contract c = new TC_BridgewareBookContractRequestBean.Contract();
        c.setActivationDate(opp.Commencement_Date__c);
        c.setDailyInterest(null);
        c.setDaysInYear(null);
        List<String> rateVarianceCd = null;
        c.setRateVarianceCd(rateVarianceCd);
        List<Date> rateVarDate = null;
        c.setRateVarDate(rateVarDate);
        List<Decimal> rateVariance = null;
        c.setRateVariance(rateVariance);
        c.setBaseRateCode(null);
        c.setDownPayment(opp.Down_Payment__c);
        c.setPurchaseOption(transRapport('PUR.OPTION', opp.Purchase_Options__c));
        List<String> approvingAuthority = new List<String>();
        approvingAuthority.add(opp.Approving_Authority__c);
        c.setApprovingAuthority(approvingAuthority);
        c.setArAddress1(opp.Account_Billing_Street__c);
        c.setArAddress2(opp.Account_Billing_Street2__c);
        c.setArAttention(opp.Billing_Attention_To__c);
        c.setArCity(opp.Account_Billing_City__c);
        c.setArName(opp.Account.Name);
        c.setArState(opp.Account_Billing_State_Province__c);
        c.setArZip(opp.Account_Billing_Zip_Postal_Code__c);
        List<String> contractBillingCycle = new List<String>();
        if (opp.Billing_Cycle__c != null) {
            contractBillingCycle.add(opp.Billing_Cycle__c.contains('January') ? '1' : '0');
            contractBillingCycle.add(opp.Billing_Cycle__c.contains('February') ? '1' : '0');
            contractBillingCycle.add(opp.Billing_Cycle__c.contains('March') ? '1' : '0');
            contractBillingCycle.add(opp.Billing_Cycle__c.contains('April') ? '1' : '0');
            contractBillingCycle.add(opp.Billing_Cycle__c.contains('May') ? '1' : '0');
            contractBillingCycle.add(opp.Billing_Cycle__c.contains('June') ? '1' : '0');
            contractBillingCycle.add(opp.Billing_Cycle__c.contains('July') ? '1' : '0');
            contractBillingCycle.add(opp.Billing_Cycle__c.contains('August') ? '1' : '0');
            contractBillingCycle.add(opp.Billing_Cycle__c.contains('September') ? '1' : '0');
            contractBillingCycle.add(opp.Billing_Cycle__c.contains('October') ? '1' : '0');
            contractBillingCycle.add(opp.Billing_Cycle__c.contains('November') ? '1' : '0');
            contractBillingCycle.add(opp.Billing_Cycle__c.contains('December') ? '1' : '0');
        }
        c.setContractBillingCycle(contractBillingCycle);
        c.setBookingDate(opp.Opportunity_Booked_Date__c == null ? null : Date.newinstance(opp.Opportunity_Booked_Date__c.year(), opp.Opportunity_Booked_Date__c.month(), opp.Opportunity_Booked_Date__c.day()));
        c.setBranch(transRapport('Branch', opp.Branch__c));
        c.setBrokerBookMethod(opp.Broker_Book_Method__c);
        c.setBrokerCode(opp.Broker_Code__c);
        c.setBrokerFees(opp.Broker_Fees__c);
        c.setBrokerTaxMethod(opp.Broker_Tax_Method__c);
        c.setContactFaxPhone(opp.Primary_Contact_Fax__c == null ? null : opp.Primary_Contact_Fax__c.replaceAll('\\D', ''));
        c.setContractNumber(opp.CCAN__c + '+');
        c.setContractPayment(opp.Payment_Amount__c);
        c.setContractTerm(opp.Terms__c == null ? null : Integer.valueOf(opp.Terms__c));
        c.setCreditAccountingName(opp.Billing_Contact__r.FirstName + ' ' + opp.Billing_Contact__r.LastName);
        // https://marlinbusiness.atlassian.net/browse/SAL-926
        //c.setCreditAccountingPhone(opp.Billing_Contact__r.Phone == null ? null : opp.Billing_Contact__r.Phone.replaceAll('\\D', ''));
        c.setCreditAccountingPhone(opp.Business_Phone__c == null ? null : opp.Business_Phone__c.replaceAll('\\D', ''));
        c.setCreditApplicationNumber(opp.Application__c);
        c.setCustomerAddress1(opp.Account_Business_Street__c);
        c.setCustomerAddress2(opp.Account_Business_Street2__c);
        c.setCustomerCity(opp.Account_Business_City__c);
        c.setCustomerCreditAccountNumber(opp.CCAN__c == null ? null : Integer.valueOf(opp.CCAN__c));
        c.setDoingBusinessAs(opp.DBA_Override__c);
        c.setCustomerName(opp.Account.Name);
        c.setCustomerState(opp.Account_Business_State_Province__c);
        c.setCustomerZip(opp.Account_Business_Zip_Postal_Code__c);
        
        // 2018-09-27 Based on logic from line 479 setting the updateDealerCode variable, set the dealer code to the correct code
        c.setDealerCode(updateDealerCode);
        
        c.setEndingPymtsInAdvance(opp.of_ending_payments__c == null ? null : Integer.valueOf(opp.of_ending_payments__c));
        c.setGrossEquipmentCost(opp.Equipment_Cost__c);
        c.setFedIDSocSec(opp.Tax_ID__c);
        c.setFirstFeeDate(opp.Broker_First_Fee_Date__c);
        c.setFirstPaymentAmount(opp.First_Payment_Amount__c);
        c.setFirstPaymentDate(opp.First_Payment_Date__c);
        c.setGracePeriod((Integer) opp.Grace_Period__c);
        c.setGrossContract(opp.Gross_Contract__c);
        c.setGrossFinance(opp.Gross_Finance__c);
        c.setIncomeMethod(opp.Income_Method__c);
        c.setIncomeStartDate(opp.Income_Start_Date__c);
        c.setInterimRents(opp.Interim_Rent__c);
        c.setLeadInvDays((Integer) opp.Lead_Invoice_Days__c);
        c.setInvoiceDueDay((Integer) opp.Invoicing_Due_Day__c);
        c.setInvoiceCode(opp.Invoice_Code__c);
        c.setInvoiceDescrip(opp.Invoice_Description__c);
        c.setLateChargeExempt(opp.Late_Charge_Exempt__c);
        c.setLateChargeRate(opp.Late_Charge_Rate__c != null ? opp.Late_Charge_Rate__c * 1000 : opp.Late_Charge_Rate__c);
        c.setContractType(opp.Contract_Type__c);
        c.setLessor(opp.Lessor__c == null ? null : Integer.valueOf(opp.Lessor__c));
        c.setMinLateCharge(opp.Minimum_Late_Charge__c);
        List<Integer> marketingRepPcts = new List<Integer>();
        marketingRepPcts.add((Integer) opp.Marketing_Rep_Percentage__c);
        c.setMarketingRepPcts(marketingRepPcts);
        List<String> mrktngRepRegion = new List<String>();
        mrktngRepRegion.add(opp.Region__c);
        c.setMrktngRepRegion(mrktngRepRegion);
        List<String> marketingRep = new List<String>();
        marketingRep.add(opp.Marketing_Rep_Code__c);
        c.setMarketingRep(marketingRep);
        c.setMunicipalLease(opp.Municipal_Lease__c);
        c.setContactEmail(opp.Billing_Contact__r.Email);
        c.setNumberOfUnits((Integer) opp.Number_of_Units__c);
        c.setOffice(opp.Office__c);
        c.setProductLine(opp.Product_Line__c);
        c.setProgramType(opp.Program_Type__c);
        c.setPromotion(opp.Promotion__c);
        c.setPurchaseOrderNumber(opp.PO_Number__c);
        c.setPaymentOption(opp.Payment_Option__c);
        c.setPaymentsInAdvance(opp.Ending_Pymts_in_Advance__c);
        c.setPymtsInArrears(opp.Payments_In_Arrears__c);
        c.setPymtsUpFront(opp.of_beginning_payments__c == null ? null : Integer.valueOf(opp.of_beginning_payments__c));
        c.setQuoteBuyout(opp.Quote_Buyout__c);
        c.setRegion(opp.Region__c);
        c.setOutOfBalance(opp.Out_of_Balance__c);
        c.setRemitToCode(opp.Remit_to_Window__c);
        c.setResidual(opp.Residual__c);
        c.setResidualCode(opp.Residual_Method__c);
        c.setRequiredSignature(opp.Primary_Contact__r.FirstName + ' ' + opp.Primary_Contact__r.LastName);
        // https://marlinbusiness.atlassian.net/browse/SAL-926
        // c.setReqPhone(opp.Primary_Contact__r.Phone == null ? null : opp.Primary_Contact__r.Phone.replaceAll('\\D', ''));
        c.setReqPhone(opp.Business_Phone__c == null ? null : opp.Business_Phone__c.replaceAll('\\D', ''));
        c.setSaleleasebackCode(opp.Sales_Leaseback__c);
        c.setSecurityDeposit(opp.Security_Deposit__c);
        //SAL-3430 Null Check
        if(opp.Recurring__c != null){
            //SAL-3073. Only send ACH information if the Recurring? picklist is set to "Recurring Only" or "One-Time & Recurring" JAH
            if (opp.Recurring__c.equals('Recurring Only') || opp.Recurring__c.equals('One-Time & Recurring')) {
                c.setBankCode(opp.Bank_Code__c);
                c.setAcctNumber(opp.Bank_Account_Number__c);
                c.setAcctType(opp.Bank_Account_Type__c);
                c.setBankNumber(opp.Bank_Number__c);
            }
        }else{//Added for requirement change on SAL-3073
            c.setBankCode(opp.Bank_Code__c);
            c.setAcctNumber(opp.Bank_Account_Number__c);
            c.setAcctType(opp.Bank_Account_Type__c);
            c.setBankNumber(opp.Bank_Number__c);
        }
        c.setUserAlphaField10(opp.ACH_Miscs__c);
        c.setUserAlphaField7(opp.SLG__c); // Updated as per SAL-4836 
        c.setUserAlphaField8(opp.Renewal_Length__c);//SAL-4799- changed UM_Alpha_Field8__c to Renewal_Length__c
        c.setUserAlphaField3(opp.Reprint_Invoice__c);
        c.setUserComments(opp.Security_Comments__c);
        c.setUserTable1(opp.Facility_Code__c);
        c.setUserAmt1(opp.NPV_for_Profit__c);
        c.setUserCode(opp.Orig_Lease_Received__c);
        c.setUseTaxResponsibility(opp.Use_Tax_Responsibility__c);
        
        List<Integer> variablePaymentsDates = new List<Integer>();
        List<Decimal> variablePaymentAmounts = new List<Decimal>();
        
        for (Variable_Payment__c vp : opp.Variable_Payments__r) {
            variablePaymentsDates.add((Integer) vp.of_payments__c);
            variablePaymentAmounts.add(vp.Payment_Amount__c);
        }
        
        c.setVariablePaymentsDates(variablePaymentsDates);
        c.setVariablePymtCode(opp.Variable_Payment__c);
        c.setVariablePaymentAmounts(variablePaymentAmounts);
        c.setAddlEmail(opp.Primary_Contact__r.Email);
        c.setGlLink(opp.GL_Link__c);
        c.setInvoiceFormat(opp.Invoice_Format__c);
        /* if(opp.CPC__c = TRUE){
c.setInvoiceFormat('ASSET');
} else {
c.setInvoiceFormat('STAND');
}*/
        // commented code as per SAL-4865
       /* if(primaryDealer.Id != null){
            if(primaryDealer.Dealer__r.Private_Label__c){
                c.setprivateLabel('Y');
            }else if(primaryDealer.Dealer__r.White_Label__c){
                c.setwhiteLabel('Y');
            }
        }*/
        c.setMMRMetered(opp.Metered__c);
        c.setMeterAccount(opp.Meter_Account__c);
        bean.setContract(c);
        
        List<TC_BridgewareBookContractRequestBean.ContractBlendedIncome> contractBlendedIncomes = new List<TC_BridgewareBookContractRequestBean.ContractBlendedIncome>();
        
        for (Blended_Income_Item__c bii : opp.Blended_Income_Items__r) {
            TC_BridgewareBookContractRequestBean.ContractBlendedIncome cbi = new TC_BridgewareBookContractRequestBean.ContractBlendedIncome();
            cbi.setIncludeInQuote(bii.Include_in_Quote__c);
            cbi.setAmount(bii.Blended_Income_Amount__c);
            cbi.setBeginDate(bii.Begin_Date__c);
            cbi.setBookingDate(bii.Booking_Date__c);
            cbi.setCalculatedRate(bii.Calculated_Rate__c);
            cbi.setCode(bii.Blended_Income_Code__c);
            cbi.setDealerManfCode(bii.Dealer_Code__c);
            cbi.setIncContRate(bii.Inc_Blended_Yield__c);
            cbi.setIncomeMethod(bii.Income_Method__c);
            cbi.setTaxCalculationMethod(bii.Income_Tax_Method__c);
            cbi.setTerm((Integer) bii.Term__c);
            cbi.setTiming(bii.Timing__c);
            contractBlendedIncomes.add(cbi);
        }
        
        if (opp.Blended_Income_Items__r.size() == 0) {
            TC_BridgewareBookContractRequestBean.ContractBlendedIncome cbi = new TC_BridgewareBookContractRequestBean.ContractBlendedIncome();
            contractBlendedIncomes.add(cbi);
        }
        
        bean.setContractBlendedIncomes(contractBlendedIncomes);
        
        List<TC_BridgewareBookContractRequestBean.Asset> assets = new List<TC_BridgewareBookContractRequestBean.Asset>();
        Map<String,PopulateBonusDep__mdt> PopulateBonusDeps = PopulateBonusDep__mdt.getAll();
        Map<string, String> bounsDepMap = new Map<String, String>();
        for(PopulateBonusDep__mdt pbd : PopulateBonusDeps.values()){
            bounsDepMap.put(pbd.MasterLabel, pbd.Bonus_Depreciation_Code__c);
        }
        String yr = String.valueOf(system.today().year());
        Map<Id, List<Meter_Type__c>> assetIds = new Map<Id, List<Meter_Type__c>>();
        for (Asset__c asst : opp.Assets__r) {
            assetIds.put(asst.Id, new List<Meter_Type__c>());
        }
        for(Meter_Type__c meter : [SELECT Id, Account__c, Asset__c, Billing_Cycle__c, Dealer__c, Existing_Units__c, 
                                   Initial_Reading_Date__c, Meter_Rate_Type_Code__c, Meter_Reading__c,Meter_Type__c,Usage_Rate__c, Overage_Cycle__c, Overage_Percentage__c, 
                                   Pay_Code__c, Read_Cycle__c, Usage_Allowance__c, Model__c, 
                                   Serial_Number__c, Account__r.Dealer_Number__c  FROM Meter_Type__c WHERE Asset__c IN :assetIds.keySet()]){
                                       
                                       if(!assetIds.containsKey(meter.Asset__c)){
                                           assetIds.put(meter.Asset__c, new List<Meter_Type__c>());
                                       }
                                       assetIds.get(meter.Asset__c).add(meter);
                                   }
        
        for (Asset__c asst : opp.Assets__r) {
            // List<Meter_Type__c> meterTypes = assetIds.get(asst.Id);
            //  for(Integer i=0; i < meterTypes.size(); i++){
            String vehicleMake = asst.Vehicle_Make__c == 'Other' ? asst.Other_Vehicle_Make__c : asst.Vehicle_Make__c;
            String assetDescription = asst.Description__c != null? asst.Description__c.left(40): asst.Description__c;
            TC_BridgewareBookContractRequestBean.Asset a = new TC_BridgewareBookContractRequestBean.Asset();
            asst.Bonus_Depreciation__c = bounsDepMap.containsKey(yr) ? bounsDepMap.get(yr) : '';
            a.setAssetUser3Alphanum1(null);
            a.setAssetUser3Table1(null);
            List<String> assetUserDef = null;
            a.setAssetUserDef(assetUserDef);
            a.setAssetUserField3(asst.PTAX_Admin_Fee_CD__c);
            a.setAssetUserField4(asst.Vehicle_Type__c);
            a.setAssetUserField5(asst.Mileage__c);
            a.setAssetUserField6(asst.Owner_Operator__c);
            a.setAssetUserField7(asst.Sleeper_Day_Cab__c);
            a.setLcCityTaxCode(asst.LC_City_Tax_Code__c);
            a.setLcCntyTaxCode(asst.LC_County_Tax_Code__c);
            a.setLcStateTaxCd(asst.LC_State_Tax_Code__c);
            a.setMiscCityTaxCd(asst.Misc_City_Tax_Code__c);
            a.setMiscCntyTaxCd(asst.Misc_County_Tax_Code__c);
            a.setMiscStTaxCode(asst.Misc_State_Tax_Code__c);
            a.setYearofManuf(asst.Vehicle_year__c);
            a.setOriginalCost(asst.Orig_Cost__c);
            a.setSalesProfit(asst.Sales_Profit__c);
            a.setVehicleMake(vehicleMake != null? vehicleMake.left(15): vehicleMake);
            a.setAceDeprBasis(asst.ACE_Depreciation_Basis__c);
            a.setDetailedAssetDescription(asst.Asset_Description__c);
            a.setAdsClassLIM((Integer) asst.ADS_Class_Life_in_Months__c);
            a.setAmtDeprBasis(asst.AMT_Depreciation_Basis__c);
            a.setRecourseAmt(asst.Recourse_Amount__c);
            a.setRecourseCode(asst.Recourse_Code__c);
            a.setRecourseComments(asst.Recourse_Comments__c);
            a.setRecoursePct(asst.Recourse_Percent__c);
            a.setRecourseTerm((Integer) asst.Recourse_Term__c);
            a.setAssetStatus(asst.Asset_Status__c);
            List<Decimal> rate = new List<Decimal>();
            rate.add(asst.Usage_Additional_Rate__c);            
            a.setAssetUserTable1(asst.Usage_User_Table__c);
            a.setFedBeginDeprDate(asst.Begin_Depreciation_Date__c);
            a.setbonusdepr(asst.Bonus_Depreciation__c);
            a.setCalcACEDepr(asst.Calculate_ACE_Depr__c);
            a.setCalcAMTDepr(asst.Calculate_AMT__c);
            a.setTaxDeprBasis(asst.Depreciation_Basis__c);
            a.setCityCode(asst.City_Code__c);
            a.setCityTaxCode(asst.City_Tax_Code__c);
            if (asst.City_Tax_Code__c == '028') a.setCityTaxPct(asst.City_Tax_Percentage__c); // 028
            a.setCountyCode(asst.County_Code__c);
            a.setCountyTaxCode(asst.County_Tax_Code__c);
            if (asst.County_Tax_Code__c == '028') a.setCountyTaxPct(asst.County_Tax_Percentage__c); // 028
            a.setAssetAddr1(asst.Equipment_Street__c);
            a.setAssetAddr2(asst.Equipment_Address_2__c);
            a.setAssetCity(asst.Equipment_City__c);
            // added equipment code/cat logic
            // https://marlinbusiness.atlassian.net/browse/SAL-1622
            a.setAssetCode(transRapport('Equipment_Code', TC_Asset.getMostGranularAssetCode (asst)));
            a.setEquipmentCost(asst.Cost__c);
            a.setAssetDesc(assetDescription);
            a.setDiscount(asst.Equipment_Discount__c);
            a.setListPrice(asst.List_Price__c);
            a.setAssetState(asst.Equipment_State__c);
            a.setAssetZip(asst.Equipment_Zip__c);
            a.setFedCalcBasis(asst.Federal_Calculation_Basis__c);
            a.setFedConvention(asst.Federal_Convention__c == null ? null : Integer.valueOf(asst.Federal_Convention__c));
            //SAL-1430 JAH Updating how depreciation is set
            // a.setDeprPercentages(c.getContractType() == 'TL' ? 100 : null);
            a.setDeprPercentages(asst.Federal_Method__c == '28' ? 100 : null);
            a.setFederalLife((Integer) asst.Federal_Life__c);
            a.setManagerResidual((Integer) asst.Manager_Residual__c);
            a.setManufacturer(asst.Manufacturer__r.Dealer_Number__c);// SAL-4968 Replace with Asset Account dealer number
            a.setModel(asst.Model__c);
            a.setMaxCityPerInv(null);
            a.setMaxCityTax(null);
            a.setMaxCntyPerInv(null);
            a.setMaxCntyTax(null);
            a.setMaxStateTax(null);
            a.setNewUsedCode(transRapport('new_uaed', asst.New_Used__c));
            a.setPropTaxStatus(asst.Property_Status__c);
            a.setPurchaseOption(transRapport('PUR.OPTION', asst.Purchase_Options__c));
            a.setRenewalOption(asst.Renewal_Option__c);
            a.setQuantity(asst.Quantity__c == null ? null : Integer.valueOf(asst.Quantity__c));
            a.setResidualPercent(asst.Residual_Percentage__c);
            a.setResidualAmount(asst.Residual_Amount__c);
            a.setFederalMethod(asst.Federal_Method__c);
            a.setSerialNumber(asst.Serial_Number__c);
            a.setStateBeginDeprDate(TC_UCIStringHelper.monthYearValue(asst.State_Begin_Depreciation_Date__c));
            a.setStateDeprBasis(asst.State_Depreciation_Basis__c);
            a.setStateLife((Integer) asst.State_Life_in_Months__c);
            a.setStateMethod(asst.State_Method__c == null ? null : Integer.valueOf(asst.State_Method__c));
            a.setStateCode(asst.State_Code__c);
            a.setStateTaxCode(asst.State_Tax_Code__c);
            if (asst.State_Tax_Code__c == '028') a.setStateTaxPct(asst.State_Tax_Percentage__c); // 028
            if (asst.City_Tax_Code__c == '028') a.setCityTransTaxPct(asst.City_Transit_Tax_Percentage__c);// 028
            if (asst.County_Tax_Code__c == '028') a.setCntyTransTaxPct(asst.County_Transit_Tax_Percentage__c);// 028
            
            // make change here
            //a.setUpfrontTaxBasis(String.isEmpty(asst.IL_Upfront_Tax_Code__c) ? null : asst.Total_Cost__c);
            a.setUpfrontTaxBasis(String.isEmpty(asst.IL_Upfront_Tax_Code__c) ? null : asst.Upfront_Tax_Basis__c);
            a.setUpfrontTaxCityCode(String.isEmpty(asst.IL_Upfront_Tax_Code__c) ? null : asst.Upfront_City_Location_Code__c);
            a.setUpfrontTaxCityAmt(asst.Upfront_City_Tax_Amount__c);
            a.setUpfrontTaxCntyCode(asst.Upfront_County_Location_Code__c);
            a.setUpfrontTaxCntyAmt(asst.Upfront_County_Tax_Amount__c);
            a.setUpfrontTaxFinanced(asst.Financed_Trigger__c);
            a.setUpfrontTaxRespCode(asst.Upfront_Responsibility_Code__c);
            a.setUpfrontTaxStateCode(asst.Upfront_State_Location_Code__c);
            a.setUpfrontTaxStateAmt(asst.Upfront_State_Tax_Amount__c);
            a.setTaxCode(asst.IL_Upfront_Tax_Code__c);
            a.setUpfrontTaxTCityAmt(asst.Upfront_City_Transit_Tax_Amount__c);
            a.setUpfrontTaxTCntyAmt(asst.Upfront_County_Transit_Tax_Amount__c);
            a.setBeginDeprDate(null);
            a.setOperLeaseBasis(null);
            a.setOperDeprLife((Integer) asst.Oper_Depr_LIM__c);
            a.setOperDeprMethod(null);
            a.setSalvageValue(asst.Salvage_Value__c);
            a.setUpfrontTaxZipCode(asst.Equipment_Zip__c);
            //new fields for SAL-4946
            a.setCustomerRef(asst.Customer_Reference__c);
            a.setDeptLocation(asst.Department_Location__c);
            a.setDealerResidual(asst.Dealer_Residual__c);
            
            system.debug(asst.ID+'assetIds.get:'+assetIds);
            if(assetIds.containsKey(asst.Id)){
                a.meterTypes = new List<TC_BridgewareBookContractRequestBean.AUMT>();
                system.debug('assetIds.get:'+assetIds.get(asst.Id).size());
                if(assetIds.get(asst.Id).size() > 0){
                    for(Meter_Type__c meter : assetIds.get(asst.Id)){
                        system.debug('meter:'+meter);
                        TC_BridgewareBookContractRequestBean.AUMT aumt = new TC_BridgewareBookContractRequestBean.AUMT();
                        aumt.setmeterType(meter.Meter_Type__c);
                        // varun
                        List<String> OverageCycles = new List<String>();
                        if (meter.Overage_Cycle__c != null) {
                            OverageCycles.add(meter.Overage_Cycle__c.contains('January') ? '1' : '0');
                            OverageCycles.add(meter.Overage_Cycle__c.contains('February') ? '1' : '0');
                            OverageCycles.add(meter.Overage_Cycle__c.contains('March') ? '1' : '0');
                            OverageCycles.add(meter.Overage_Cycle__c.contains('April') ? '1' : '0');
                            OverageCycles.add(meter.Overage_Cycle__c.contains('May') ? '1' : '0');
                            OverageCycles.add(meter.Overage_Cycle__c.contains('June') ? '1' : '0');
                            OverageCycles.add(meter.Overage_Cycle__c.contains('July') ? '1' : '0');
                            OverageCycles.add(meter.Overage_Cycle__c.contains('August') ? '1' : '0');
                            OverageCycles.add(meter.Overage_Cycle__c.contains('September') ? '1' : '0');
                            OverageCycles.add(meter.Overage_Cycle__c.contains('October') ? '1' : '0');
                            OverageCycles.add(meter.Overage_Cycle__c.contains('November') ? '1' : '0');
                            OverageCycles.add(meter.Overage_Cycle__c.contains('December') ? '1' : '0');
                        }
                        aumt.setmeterBillingCycle(OverageCycles);
                        
                        //aumt.setmeterBillingCycle(meter.Overage_Cycle__c);
                        aumt.setmeterContrThruDate(null);
                        aumt.setmeterCTDUnits(meter.Existing_Units__c);
                        aumt.setmeterDateEntered(null);
                        aumt.setmeterMinChargeDealer(null);
                        aumt.setmeterMinChargeDealerPer(null);
                        aumt.setmeterMinChargebycode(null);
                        aumt.setmeterMinChargeAmt(null);
                        aumt.setmeterModel(meter.Model__c);
                        //varun
                        List<String> meterBillingCycles = new List<String>();
                        if (meter.Billing_Cycle__c != null) {
                            meterBillingCycles.add(meter.Billing_Cycle__c.contains('January') ? '1' : '0');
                            meterBillingCycles.add(meter.Billing_Cycle__c.contains('February') ? '1' : '0');
                            meterBillingCycles.add(meter.Billing_Cycle__c.contains('March') ? '1' : '0');
                            meterBillingCycles.add(meter.Billing_Cycle__c.contains('April') ? '1' : '0');
                            meterBillingCycles.add(meter.Billing_Cycle__c.contains('May') ? '1' : '0');
                            meterBillingCycles.add(meter.Billing_Cycle__c.contains('June') ? '1' : '0');
                            meterBillingCycles.add(meter.Billing_Cycle__c.contains('July') ? '1' : '0');
                            meterBillingCycles.add(meter.Billing_Cycle__c.contains('August') ? '1' : '0');
                            meterBillingCycles.add(meter.Billing_Cycle__c.contains('September') ? '1' : '0');
                            meterBillingCycles.add(meter.Billing_Cycle__c.contains('October') ? '1' : '0');
                            meterBillingCycles.add(meter.Billing_Cycle__c.contains('November') ? '1' : '0');
                            meterBillingCycles.add(meter.Billing_Cycle__c.contains('December') ? '1' : '0');
                        }
                        aumt.setmeterOverageCycle(meterBillingCycles);
                        
                        //aumt.setmeterOverageCycle(meter.Billing_Cycle__c);
                        //varun
                        List<String> readCycles = new List<String>();
                        if (meter.Read_Cycle__c != null) {
                            readCycles.add(meter.Read_Cycle__c.contains('January') ? '1' : '0');
                            readCycles.add(meter.Read_Cycle__c.contains('February') ? '1' : '0');
                            readCycles.add(meter.Read_Cycle__c.contains('March') ? '1' : '0');
                            readCycles.add(meter.Read_Cycle__c.contains('April') ? '1' : '0');
                            readCycles.add(meter.Read_Cycle__c.contains('May') ? '1' : '0');
                            readCycles.add(meter.Read_Cycle__c.contains('June') ? '1' : '0');
                            readCycles.add(meter.Read_Cycle__c.contains('July') ? '1' : '0');
                            readCycles.add(meter.Read_Cycle__c.contains('August') ? '1' : '0');
                            readCycles.add(meter.Read_Cycle__c.contains('September') ? '1' : '0');
                            readCycles.add(meter.Read_Cycle__c.contains('October') ? '1' : '0');
                            readCycles.add(meter.Read_Cycle__c.contains('November') ? '1' : '0');
                            readCycles.add(meter.Read_Cycle__c.contains('December') ? '1' : '0');
                        }
                        aumt.setmeterReadingCycle(readCycles);
                        //aumt.setmeterReadingCycle(meter.Read_Cycle__c);
                        aumt.setmeterReadingComments(null);
                        aumt.setmeterReadingDates(meter.Initial_Reading_Date__c);
                        aumt.setmeterReadingMethods('I');
                        aumt.setmeterReading(meter.Meter_Reading__c);
                        aumt.setmeterSerialNumber(meter.Serial_Number__c);
                        aumt.setmeterserviceDates(null);
                        aumt.setmeterserviceUnits(null);
                        aumt.setmeterUsageAdj(null);
                        
                        //set aumtr
                        TC_BridgewareBookContractRequestBean.AUMTRCls aumtr = new TC_BridgewareBookContractRequestBean.AUMTRCls();
                        aumtr.setAUMTRmeterType(meter.Meter_Rate_Type_Code__c);
                        aumtr.setmeterOverageDealer(meter.Account__r.Dealer_Number__c);
                        aumtr.setmeterOverageDealerPerc(meter.Overage_Percentage__c);
                        aumtr.setmeterOveragePayCode('1');
                        aumtr.setmeterOverageRates(meter.Usage_Rate__c);
                        aumtr.setmeterOverageUnits(meter.Usage_Allowance__c);
                        
                        aumt.AUMTR = aumtr;
                        system.debug('aumt:'+aumt);
                        a.meterTypes.add(aumt);
                    }
                }else{
                    TC_BridgewareBookContractRequestBean.AUMT aumt = new TC_BridgewareBookContractRequestBean.AUMT();
                    TC_BridgewareBookContractRequestBean.AUMTRCls aumtr = new TC_BridgewareBookContractRequestBean.AUMTRCls();
                    aumt.AUMTR = aumtr;
                    a.meterTypes.add(aumt);
                }
                
            }
            system.debug('a:'+a);
            assets.add(a);
        }
        //Remove list size() to isEmpty()- Rajesh Kumar(LTIMindtree)
        if (assetIds.isEmpty()) {
            TC_BridgewareBookContractRequestBean.Asset a = new TC_BridgewareBookContractRequestBean.Asset();
            assets.add(a);
        }
        system.debug('assets::'+assets);
        bean.setAssets(assets);
        
        TC_BridgewareBookContractRequestBean.Dealer d = new TC_BridgewareBookContractRequestBean.Dealer();
        //d.setDealer('dealer');
        //d.setDealerDesc('dealerDesc');
        //d.setDealerFundDate(System.Today());
        //d.setDealerInvoiceNo('dealerInvoiceNo');
        //d.setDealerListPrice(2.00);
        //d.setSpecialGLcode('specialGLcode');
        bean.setDealer(d);
        
        // Meter Type section fields
        
        // List<TC_BridgewareBookContractRequestBean.MeterType> meterType = new List<TC_BridgewareBookContractRequestBean.MeterType>();
        
        List<TC_BridgewareBookContractRequestBean.ContractMiscBillable> contractMiscBillables = new List<TC_BridgewareBookContractRequestBean.ContractMiscBillable>();
        
        for (Miscellaneous_Billable_Item__c mbi : opp.Miscellaneous_Billable_Items__r) {
            TC_BridgewareBookContractRequestBean.ContractMiscBillable cmb = new TC_BridgewareBookContractRequestBean.ContractMiscBillable();
            cmb.setAmountType(mbi.Misc_Amount_Type__c);
            cmb.setFutureBill(mbi.Future_Bill_Misc_Type__c);
            cmb.setFinalDate(TC_UCIStringHelper.monthYearValue(mbi.Final_Payment_Date__c));
            
            cmb.setFirstDate(TC_UCIStringHelper.monthYearValue(mbi.First_Payment_Date__c)); // SAL 868
            
            cmb.setIncInRent(mbi.Included_in_Rental__c);
            cmb.setAmount(mbi.Amount__c);
            cmb.setDisp(mbi.CB_Disp__c);
            //            cmb.setCycle(mbi.Billing_Cycle__c);
            
            //            cmb.setCycle(contractBillingCycle); // set as opportunity's billing cycle as referenced here: https://marlinbusiness.atlassian.net/browse/SAL-653
            
            if (mbi.Billing_Cycle__c != null && mbi.First_Payment_Date__c != null) {
                if (mbi.Billing_Cycle__c == 'Variable'){
                    cmb.setCycle(contractBillingCycle); // set as opportunity's billing cycle if frequency is variable: https://marlinbusiness.atlassian.net/browse/SAL-868
                    
                }else{
                    
                    // In this branch what we do is calculate the billing cycle based on the Billing_Cycle__c and First_Payment_Date__c fields on the Misc Billable Item object.
                    
                    Set <Integer> monthIntegerSet = new Set <Integer> ();
                    Integer rollingInteger = mbi.First_Payment_Date__c.month();
                    monthIntegerSet.add(rollingInteger);
                    
                    Integer step = new Map <String, Integer>{
                        'Monthly' => 1,
                            'Quarterly' => 3,
                            'Annually' => 12,
                            'Weekly' => 1,
                            'Daily' => 1
                            }.get(mbi.Billing_Cycle__c);
                    
                    if (step != null) {
                        
                        while (!monthIntegerSet.contains(Math.mod(rollingInteger + step, 12) == 0 ? 12 : Math.mod(rollingInteger + step, 12))) {
                            rollingInteger = Math.mod(rollingInteger + step, 12) == 0 ? 12 : Math.mod(rollingInteger + step, 12);
                            monthIntegerSet.add(rollingInteger);
                        }
                        
                        List<String> billingCycle = new List<String>();
                        
                        for (Integer i=1; i<13; i++){
                            billingCycle.add(monthIntegerSet.contains(i) ? '1' : '0');
                        }
                        
                        cmb.setCycle(billingCycle);
                    }
                }
            }
            
            cmb.setCmbDate(TC_UCIStringHelper.monthYearValue(mbi.Due_Date__c));
            cmb.setCmbDesc(mbi.Misc_Item_Description__c);
            cmb.setGlCode(transRapport('GL_CODE', mbi.Misc_GL_Code__c));
            cmb.setPayable(mbi.Pay_Code__c == null ? null : Integer.valueOf(mbi.Pay_Code__c));
            cmb.setPassThrough(mbi.PassThrough__c ? '1':'');
            cmb.setTaxable(mbi.Misc_Tax__c);
            cmb.setVendor(mbi.Dealer_Code__c);
            cmb.setPaymentType(mbi.PaymentType__c ? '01':'');
            cmb.setPassThroughPercentage(mbi.PassThroughPercentage__c <> null ? String.valueof(mbi.PassThroughPercentage__c) : '');
            contractMiscBillables.add(cmb);
        }
        
        if (opp.Miscellaneous_Billable_Items__r.size() == 0) {
            TC_BridgewareBookContractRequestBean.ContractMiscBillable cmb = new TC_BridgewareBookContractRequestBean.ContractMiscBillable();
            contractMiscBillables.add(cmb);
        }
        
        bean.setContractMiscBillables(contractMiscBillables);
        
        List<TC_BridgewareBookContractRequestBean.ContractMiscInvoice> contractMiscInvoices = new List<TC_BridgewareBookContractRequestBean.ContractMiscInvoice>();
        
        for (Miscellaneous_Invoice_Item__c mii : opp.Miscellaneous_Invoice_Items__r) {
            TC_BridgewareBookContractRequestBean.ContractMiscInvoice cmi = new TC_BridgewareBookContractRequestBean.ContractMiscInvoice();
            cmi.setIncInRent(mii.Include_in_Rent__c);
            cmi.setAmount(mii.Amount__c);
            cmi.setDisp(mii.MIDisp__c);
            cmi.setCmiDate(TC_UCIStringHelper.monthYearValue(mii.Due_Date__c));
            cmi.setCmiDesc(mii.Description__c);
            cmi.setGlCode(transRapport('GL_CODE', mii.GL_Code__c));
            cmi.setPayable(mii.Pay_Code__c == null ? null : Integer.valueOf(mii.Pay_Code__c));
            cmi.setTaxable(mii.Taxable__c);
            cmi.setVendor(mii.Dealer_Code__c);
            cmi.setInterimPercentage(mii.Interim_Percentage__c != null ? mii.Interim_Percentage__c * 1000 : mii.Interim_Percentage__c);
            cmi.setPassThrough(mii.PassThrough__c ? '1':'');// SAL-6006 Misael Romero
            // cmi.setPaymentType(mii.PaymentType__c ? '01':'');
            // cmi.setPassThroughPercentage(mii.PassThroughPercentage__c <> null ? String.valueof(mii.PassThroughPercentage__c) : '');
            contractMiscInvoices.add(cmi);
        }
        
        if (opp.Miscellaneous_Invoice_Items__r.size() == 0) {
            TC_BridgewareBookContractRequestBean.ContractMiscInvoice cmi = new TC_BridgewareBookContractRequestBean.ContractMiscInvoice();
            contractMiscInvoices.add(cmi);
        }
        
        bean.setContractMiscInvoices(contractMiscInvoices);
        // system.debug ('>>>>> req: ' + contractMiscBillables);//contractMiscBillables
        return bean;
    }
    
    public static TC_BridgewareSelectZipGeoCodeRespBean selectZipGeoCode(String zipCode, String taxCode, String requestUserId) {
        TC_BridgewareService service = new TC_BridgewareServiceImpl ();
        
        TC_BridgewareSelectZipGeoCodeRequestBean bean = new TC_BridgewareSelectZipGeoCodeRequestBean ();
        bean.setZipCode (zipCode);
        bean.setTaxCode (taxCode);
        bean.setRequestUserId (requestUserId);
        // system.debug (bean);
        
        TC_BridgewareSelectZipGeoCodeRespBean response = service.selectZipGeoCode (bean);
        
        return response;
    }
    
    public static List<TC_BridgewareTaxJurisdiction> getTaxJurisdictions(TC_BridgewareSelectZipGeoCodeRespBean selectZipGeoCodeResp) {
        List<TC_BridgewareTaxJurisdiction> taxJurisdictionList = new List<TC_BridgewareTaxJurisdiction>();
        List<TC_BridgewareTaxJurisdiction> rateList = new List<TC_BridgewareTaxJurisdiction>();
        Map<String,TC_BridgewareTaxJurisdiction> rateMap = new Map<String,TC_BridgewareTaxJurisdiction>();
        
        if (selectZipGeoCodeResp.getContentData() != null) {
            TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipState[] uniDataVtZipStateList = selectZipGeoCodeResp.getContentData().getVtZipStateList();
            
            if (uniDataVtZipStateList != null) {
                for (TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipState uniDataVtZipState : uniDataVtZipStateList) {
                    // system.debug('uniDataVtZipState.description: ' + uniDataVtZipState.getDescription());
                    // system.debug('uniDataVtZipState.code: ' + uniDataVtZipState.getCode());
                    
                    String state = uniDataVtZipState.getDescription();
                    String stateCode = uniDataVtZipState.getCode();
                    
                    TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipCounty[] uniDataVtZipCountyList = uniDataVtZipState.getVtZipCountyList();
                    
                    if (uniDataVtZipCountyList != null) {
                        for (TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipCounty uniDataVtZipCounty : uniDataVtZipCountyList) {
                            // system.debug('uniDataVtZipCounty.description: ' + uniDataVtZipCounty.getDescription());
                            // system.debug('uniDataVtZipCounty.code: ' + uniDataVtZipCounty.getCode());
                            
                            String county = uniDataVtZipCounty.getDescription();
                            String countyCode = uniDataVtZipCounty.getCode();
                            
                            TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipCity[] uniDataVtZipCityList = uniDataVtZipCounty.getVtZipCityList();
                            
                            if (uniDataVtZipCityList != null) {
                                for (TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipCity uniDataVtZipCity : uniDataVtZipCityList) {
                                    // system.debug('uniDataVtZipCity.description: ' + uniDataVtZipCity.getDescription());
                                    // system.debug('uniDataVtZipCity.code: ' + uniDataVtZipCity.getCode());
                                    
                                    String city = uniDataVtZipCity.getDescription();
                                    String cityCode = uniDataVtZipCity.getCode();
                                    
                                    TC_BridgewareTaxJurisdiction taxJurisdiction = new TC_BridgewareTaxJurisdiction();
                                    taxJurisdiction.city = city;
                                    taxJurisdiction.county = county;
                                    taxJurisdiction.state = state;
                                    taxJurisdiction.cityCode = cityCode;
                                    taxJurisdiction.countyCode = countyCode;
                                    taxJurisdiction.stateCode = stateCode;
                                    taxJurisdictionList.add(taxJurisdiction);
                                    
                                    TC_BridgewareSelectZipGeoCodeRespBean.UniDataTaxType[] uniDataTaxTypeList = uniDataVtZipCity.getTaxTypeList();
                                    
                                    if (uniDataTaxTypeList != null) {
                                        for (TC_BridgewareSelectZipGeoCodeRespBean.UniDataTaxType uniDataTaxType : uniDataTaxTypeList) {
                                            // system.debug('uniDataTaxType.description: ' + uniDataTaxType.getDescription());
                                            // system.debug('uniDataTaxType.code: ' + uniDataTaxType.getCode());
                                            // system.debug('uniDataTaxType.getStateTaxRate(): ' + uniDataTaxType.getStateTaxRate());
                                            // system.debug('uniDataTaxType.getCountyTaxRate(): ' + uniDataTaxType.getCountyTaxRate());
                                            // system.debug('uniDataTaxType.getCountyTransTaxRate(): ' + uniDataTaxType.getCountyTransTaxRate());
                                            // system.debug('uniDataTaxType.getCityTaxRate(): ' + uniDataTaxType.getCityTaxRate());
                                            // system.debug('uniDataTaxType.getCityTransTaxRate(): ' + uniDataTaxType.getCityTransTaxRate());
                                            System.debug('city node '+uniDataTaxType);
                                            TC_BridgewareTaxJurisdiction rate = new TC_BridgewareTaxJurisdiction();
                                            rate.city = city;
                                            System.debug('City: '+rate.city);
                                            rate.county = county;
                                            rate.state = state;
                                            rate.cityCode = cityCode;
                                            rate.countyCode = countyCode;
                                            rate.stateCode = stateCode;
                                            rate.rateCodeDescription = uniDataTaxType.getDescription();
                                            rate.rateCode = uniDataTaxType.getCode();
                                            rate.stateTaxRate = uniDataTaxType.getStateTaxRate();
                                            rate.countyTaxRate = uniDataTaxType.getCountyTaxRate();
                                            rate.countyTransTaxRate = uniDataTaxType.getCountyTransTaxRate();
                                            rate.cityTaxRate = uniDataTaxType.getCityTaxRate();
                                            rate.cityTransTaxRate = uniDataTaxType.getCityTransTaxRate();
                                            String mapKey = city+rate.rateCode;
                                            rateMap.put(mapKey,rate);
                                            //rateList.add(rate);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        for(TC_BridgewareTaxJurisdiction testRate : rateMap.Values()){
            System.debug('mapped Rates: '+testRate);
            rateList.add(testRate);
        }
        
        saveRates(rateList);
        
        return taxJurisdictionList;
    }
    
    private static void saveRates(List<TC_BridgewareTaxJurisdiction> rateList) {
        Bridgeware_Service_Setting__c settings = TC_BridgewareUtility.getInstance().getServiceSettings();
        List<SObject> ratesToInsert = new List<SObject>();
        List<SObject> ratesToUpdate = new List<SObject>();
        Set<Id> rateIdsToUpdate = new Set<Id>();
        
        for (TC_BridgewareTaxJurisdiction taxJurisdiction : rateList) {
            String rateQuery = createQueryString(new Set<String>{'Id'}, settings.Rate_Object__c, null, null);
            rateQuery += ' WHERE ' + settings.Rate_City_Field__c + ' = \'' + String.escapeSingleQuotes(taxJurisdiction.city) + '\'';
            rateQuery += ' AND ' + settings.Rate_County_Field__c + ' = \'' + String.escapeSingleQuotes(taxJurisdiction.county) + '\'';
            rateQuery += ' AND ' + settings.Rate_State_Field__c + ' = \'' + String.escapeSingleQuotes(taxJurisdiction.state) + '\'';
            rateQuery += ' AND ' + settings.Rate_Code_Field__c + ' = \'' + String.escapeSingleQuotes(taxJurisdiction.rateCode) + '\'';
            rateQuery += ' AND ' + settings.Rate_City_Code_Field__c + ' = \'' + String.escapeSingleQuotes(taxJurisdiction.cityCode) + '\'';
            rateQuery += ' AND ' + settings.Rate_County_Code_Field__c + ' = \'' + String.escapeSingleQuotes(taxJurisdiction.countyCode) + '\'';
            rateQuery += ' AND ' + settings.Rate_State_Code_Field__c + ' = \'' + String.escapeSingleQuotes(taxJurisdiction.stateCode) + '\'';
            // system.debug('rateQuery ' + rateQuery);
            List<SObject> rates = Database.query(rateQuery);
            
            SObject rate = Schema.getGlobalDescribe().get(settings.Rate_Object__c).newSObject();
            
            if (rates.size() > 0)
                rate.Id = rates[0].Id;
            
            if (String.isNotEmpty(settings.Rate_City_Field__c))
                rate.put(settings.Rate_City_Field__c, taxJurisdiction.city);
            
            if (String.isNotEmpty(settings.Rate_City_Code_Field__c))
                rate.put(settings.Rate_City_Code_Field__c, taxJurisdiction.cityCode);
            
            if (String.isNotEmpty(settings.Rate_County_Field__c))
                rate.put(settings.Rate_County_Field__c, taxJurisdiction.county);
            
            if (String.isNotEmpty(settings.Rate_County_Code_Field__c))
                rate.put(settings.Rate_County_Code_Field__c, taxJurisdiction.countyCode);
            
            if (String.isNotEmpty(settings.Rate_State_Field__c))
                rate.put(settings.Rate_State_Field__c, taxJurisdiction.state);
            
            if (String.isNotEmpty(settings.Rate_State_Code_Field__c))
                rate.put(settings.Rate_State_Code_Field__c, taxJurisdiction.stateCode);
            
            if (String.isNotEmpty(settings.Rate_Code_Description_Field__c))
                rate.put(settings.Rate_Code_Description_Field__c, taxJurisdiction.rateCodeDescription);
            
            if (String.isNotEmpty(settings.Rate_Code_Field__c))
                rate.put(settings.Rate_Code_Field__c, taxJurisdiction.rateCode);
            
            if (String.isNotEmpty(settings.State_Tax_Rate_Field__c))
                rate.put(settings.State_Tax_Rate_Field__c, taxJurisdiction.stateTaxRate);
            
            if (String.isNotEmpty(settings.County_Tax_Rate_Field__c))
                rate.put(settings.County_Tax_Rate_Field__c, taxJurisdiction.countyTaxRate);
            
            if (String.isNotEmpty(settings.TCounty_Tax_Rate_Field__c))
                rate.put(settings.TCounty_Tax_Rate_Field__c, taxJurisdiction.countyTransTaxRate);
            
            if (String.isNotEmpty(settings.City_Tax_Rate_Field__c))
                rate.put(settings.City_Tax_Rate_Field__c, taxJurisdiction.cityTaxRate);
            
            if (String.isNotEmpty(settings.TCity_Tax_Rate_Field__c))
                rate.put(settings.TCity_Tax_Rate_Field__c, taxJurisdiction.cityTransTaxRate);
            
            if (rate.Id == null)
                ratesToInsert.add(rate);
            else if (!rateIdsToUpdate.contains(rate.Id)) {
                ratesToUpdate.add(rate);
                rateIdsToUpdate.add(rate.Id);
            }
        }
        
        if (ratesToInsert.size() > 0)
            insert ratesToInsert;
        
        if (ratesToUpdate.size() > 0)
            update ratesToUpdate;
    }
    
    public static String createQueryString(Set<String> queryFields, String objectType, String keyField, String key) {
        String query = 'SELECT ';
        Integer counter = 1;
        
        for (String field : queryFields) {
            query += field;
            
            if (counter < queryFields.size())
                query += ', ';
            
            counter++;
        }
        
        query += ' FROM ' + objectType;
        
        if (keyField != null && key != null)
            query += ' WHERE '+ keyField + ' = \'' + key + '\'';
        
        return query;
    }
    
    public static Tax_Jurisdiction_Mapping__mdt getTaxJurisdictionMapping (String objectType) {
        Tax_Jurisdiction_Mapping__mdt mapping = null;
        mapping = taxJurisdictionMap.get (objectType);
        
        if (mapping == null) {
            try {
                mapping = [
                    SELECT City_Field__r.QualifiedApiName,
                    County_Field__r.QualifiedApiName,
                    State_Field__r.QualifiedApiName,
                    Zip_Field__r.QualifiedApiName,
                    City_Code_Field__r.QualifiedApiName,
                    County_Code_Field__r.QualifiedApiName,
                    State_Code_Field__r.QualifiedApiName,
                    Zip_Updated_Field__r.QualifiedApiName
                    FROM Tax_Jurisdiction_Mapping__mdt
                    WHERE Object__r.QualifiedApiName = :objectType
                ];
                
                taxJurisdictionMap.put (objectType, mapping);
            }
            catch (Exception e) {
                throw new TC_BridgewareUtilityException('Tax Jurisdiction Mapping is not set up for Object ' + objectType + '.');
            }
        }
        
        return mapping;
    }
    
    // reduce CPU time by replacing this function with assetTriggerHandler.setZipUpdatedFlag
    // public static void setZipUpdatedFlag (List <SObject> newList, Map <Id, SObject> oldMap) {
    //     String objectType = String.valueOf (newList[0].getSobjectType ());
    //     Tax_Jurisdiction_Mapping__mdt mapping = getTaxJurisdictionMapping (objectType);
    //     String zipField = mapping.Zip_Field__r.QualifiedApiName;
        
    //     for (SObject obj : newList) {
    //         if ((obj.get (zipField) != null && String.isNotEmpty((String) obj.get (zipField)))
    //             && (oldMap == null || obj.get (zipField) != oldMap.get (obj.Id).get (zipField))
    //            ) {
    //                obj.put(mapping.Zip_Updated_Field__r.QualifiedApiName, true);
    //                selectZipGeoCode (obj.Id, (String) obj.get (zipField));
    //            }
    //     }
    // }
    
    @future(callout=true)
    public static void selectZipGeoCode (String recordId, String zip) {
        TC_BridgewareSelectZipGeoCodeCtrl.search(recordId, zip);
    }
    
    Private Static Map<String,String> rapportMaps = new Map<String,String>();
    
    Private Static void buildRapportMap(){
        rapportMaps.Clear();
        
        for (MARLIN_Rapport_Mapping__mdt rapportMap:[Select MasterLabel, Rapport_Value__c, Field_Name__c from MARLIN_Rapport_Mapping__mdt])
        {
            rapportMaps.put(rapportMap.Field_Name__c + '__' + rapportMap.MasterLabel, rapportMap.Rapport_Value__c);
        }
        // system.debug('Rapport Transform Map: ' + rapportMaps);
    }
    
    Private static String transRapport(String fieldName, Object argVal) {
        // system.debug('Rapport Transform call: ' + fieldName + '::' + argVal );
        if(argVal != null) {
            // system.debug('rapportMaps-- '+rapportMaps.Get(fieldName + '__' + String.valueof(argVal)));
            return rapportMaps.Get(fieldName + '__' + String.valueof(argVal));
        }
        
        return '';
    }
    
    private static Map <String,String> stateMap;
    
    private static void buildStateMap () {
        if (stateMap == null) {
            stateMap = new Map <String,String> ();
            
            for (State_Mapping__mdt sm : [SELECT MasterLabel, DeveloperName FROM State_Mapping__mdt])
                stateMap.put (sm.MasterLabel.toUpperCase(), sm.DeveloperName);
        }
        
        // system.debug('State Transform Map: ' + stateMap);
    }
    
    public static String transState (String stateName) {
        buildStateMap ();
        
        if (String.isNotEmpty (stateName)) {
            return stateMap.get (stateName.toUpperCase ());
        }
        
        return '';
    }
    
    public class TC_BridgewareUtilityException extends Exception {}
}