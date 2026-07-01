/**************************************************************************************************************
@Author: Chalapati Murru (LTIMindtree)
@Description: This class is used for InfoLease API call.
@User Story: SAL-5692 Expo: Opportunity Refactor
@Created Date: Jan-30-2026
**************************************************************************************************************/
public with sharing class PEAC_BWInfoLeaseUtility implements Database.AllowsCallouts{
    
	public static void sendToBridgeware(Id oppId, Map<Id, String> accountMap) {
        //Get Opportunity and Related data and build Wrapper to use in further logic
        PEAC_BWInfoLeaseDataWrapper dataWrap = PEAC_BWInfoLeaseValidations.buildDataWrapper(oppId);
        //InfoLease Required Data Validations
        PEAC_BWInfoLeaseValidations.validateOppData(dataWrap);
        //Enqueue the InfoLease API to run in future context
        System.enqueueJob(new PEAC_InvokeInfoLeaseQueueable(dataWrap, accountMap));
    }
    
    /**********************************************************************************************************************
    @Author: Chalapati Murru (LTIMindtree)
    @Description: This class is used to enqueue the InfoLease API call to run in future context
    @User Story: SAL-5692 Expo: Opportunity Refactor
    @Created Date: Jan-30-2026
    **********************************************************************************************************************/
    public class PEAC_InvokeInfoLeaseQueueable implements Queueable,Database.AllowsCallouts {
        private PEAC_BWInfoLeaseDataWrapper dataWrap;
        private Map<Id, String> accountMap;
        
        public PEAC_InvokeInfoLeaseQueueable(PEAC_BWInfoLeaseDataWrapper dataWrap, Map<Id, String> accountMap) {
            this.dataWrap = dataWrap;
            this.accountMap = accountMap;
        }
        
        public void execute(QueueableContext qc) {
            TC_BridgewareBookContractRequestBean bean = createRequest (this.dataWrap, this.accountMap );
            TC_BridgewareBookContractRequestUCI uci = new TC_BridgewareBookContractRequestUCI ();
            uci.setAssetCount (this.dataWrap.opp.Number_of_Assets__c);//SAL-5692 Expo: Opportunity Refactor
            uci.setAppNumber (this.dataWrap.opp.Application__c);//SAL-5692 Expo: Opportunity Refactor
            uci.setUciConfig (bean.getUciConfig ());
            uci.setUciRecord (bean.toUCIString());
            uci.setUciKey (this.dataWrap.opp.Id); 
            System.debug(LoggingLevel.ERROR, 'Book to IL Request: ' + uci);
            TC_BridgewareService service = new TC_BridgewareServiceImpl();
            TC_BridgewareBookContractRespBean response = service.bookContract(uci);
            System.debug(LoggingLevel.ERROR, 'Book to IL Response: ' + response);
            List<Opportunity> opps = [SELECT Id, Opportunity_Booked_Date__c, Booked_Amount__c, Equipment_Cost__c,Number_of_Assets__c FROM Opportunity WHERE Id =: this.dataWrap.opp.Id];
            //opps[0].Booked_to_External_System_User__c = System.UserInfo.getUserId();
            
            if (response.statusMessage == 'Success' && String.isNotEmpty(response.contractNbr)
               	&& (opps[0].Number_of_Assets__c < Integer.valueOf(System.Label.PEAC_ILSendAssetLimit))) {
                if (opps.size () > 0) {
                    Opportunity opp = opps[0];
                    opp.Contract__c = response.contractNbr;
                    //PEAC_IL_Notification__e evt = new PEAC_IL_Notification__e(Record_Id__c = this.dataWrap.opp.Id, Title__c = 'Success!', Variant__c = 'success', Message__c = 'Contract '+opp.Contract__c+' created in InfoLease.');
                    //EventBus.publish(evt);
                    
                    opp.Application_Status__c = 'Booked';
                    opp.StageName = 'Funded/Booked';
                    if(opp.Opportunity_Booked_Date__c == null){
                        opp.Opportunity_Booked_Date__c = System.now();
                    }
                    if(opp.Booked_Amount__c == null){
                        opp.Booked_Amount__c = opp.Equipment_Cost__c;
                    }
                    opp.Booked_to_External_System_Date__c = System.now();
                    opp.Booked_to_External_System_User__c = System.UserInfo.getUserId();
                    opp.Book_to_InfoLease_Error__c = null;
                    try {
                        update opp;
                    }catch (Exception e) {
                        update new Opportunity(Id = opp.Id, Contract__c = response.contractNbr,Booked_to_External_System_Date__c = System.now(),
                                               Booked_to_External_System_User__c = System.UserInfo.getUserId(),Book_to_InfoLease_Error__c = e.getMessage());
                    }
                }
            }else if(response.statusMessage == 'Success'){//We dont get ContractNumber from IL
                //PEAC_IL_Notification__e evt = new PEAC_IL_Notification__e(Record_Id__c = this.dataWrap.opp.Id, Title__c = 'Success!', Variant__c = 'success', Message__c = 'The Opportunity has been submitted to IL, and you will be notified once it has been booked!');
                //EventBus.publish(evt);
                update new Opportunity(Id = opps[0].Id, Booked_to_External_System_User__c = System.UserInfo.getUserId(), Book_to_InfoLease_Error__c = null);
            }else if(response.statusMessage == 'Failed'){
                update new Opportunity(Id = opps[0].Id, Booked_to_External_System_User__c = System.UserInfo.getUserId(), Book_to_InfoLease_Error__c = response.responseMessageDesc);
            }
            //return response;
        }
    }
    
    public static TC_BridgewareBookContractRequestBean createRequest(PEAC_BWInfoLeaseDataWrapper dataWrap, Map<Id, String> accountMap) {
        buildRapportMap();
        TC_BridgewareBookContractRequestBean bean = new TC_BridgewareBookContractRequestBean();
        bean.setUciConfig(TC_BridgewareUtility.getInstance().getServiceSettings().UCI_Config__c);
        List<TC_BridgewareBookContractRequestBean.RelatedParty> relatedParties = new List<TC_BridgewareBookContractRequestBean.RelatedParty>();
        
        //2018-09-28 TC - If IFP or Franchise, set some variables that are used for IFP or Franchise scenarios
        String altGuarantorCode;
        String updateDealerCode;
        Integer looper;
        Boolean isWholesaleHealthcare = dataWrap.opp.RecordType.Name.contains('Wholesale') || dataWrap.opp.Owner.Profile.Name.contains('HC BD');
        
        TC_DealerTreatment dealerTreatment = new TC_DealerTreatment (dataWrap.opp);
        if (dealerTreatment.sendBrokerAsDealer) {
            altGuarantorCode = '04';
            updateDealerCode = dataWrap.primaryBorkerList[dataWrap.primaryBorkerList.size()-1].Broker_Dealer_Number__c;// looks like the looper logic is grabbing the last one
        } else if (dealerTreatment.sendFranchisorAsDealer) {
            altGuarantorCode = '07';
            updateDealerCode = dataWrap.franchisorList[dataWrap.franchisorList.size()-1].Franchisor_Number__c;// looks like the looper logic is grabbing the last one
        } else {
            if (!dataWrap.dealerList.isEmpty()) updateDealerCode = dataWrap.dealerList[dataWrap.dealerList.size ()-1].Dealer__r.Dealer_Number__c;// looks like the looper logic is grabbing the last one
        }
        // Set related parties from Guarantor Object
        for (Guarantor__c g : dataWrap.guarantorList) {
            List<String> contractPointersPrinGuarantorCodes = new List<String>();
            List<String> principalGuarantorRecords = new List<String>();
            String guarCode = 'Guarantor';
            if (g.RecordType.Name == 'Corporate'){
                guarCode = 'Corporate Guaranty';
            } else {
                if (g.RP_PRIN_GUAR_CODE__c == 'Principal')
                    guarCode = 'Principal';
            }
            contractPointersPrinGuarantorCodes.add(transRapport('RP_PRIN_GUAR_CODE', guarCode));
            String contactCcan = g.Contact__r.Contact_CCAN__c;
            String ccan = g.Account__r.CCAN__c;
            if (g.RecordType.Name == 'Corporate') {
                if (ccan == null) {
                    ccan = accountMap.get(g.Account__r.Id);
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
        if(dealerTreatment.sendFranchisorAsDealer || dealerTreatment.sendBrokerAsDealer) {
            String dealerCodeAsCCAN;
            for (Dealer__c d : dataWrap.dealerList) {
                List<String> contractPointersPrinGuarantorCodes = new List<String>();
                List<String> principalGuarantorRecords = new List<String>();
                dealerCodeAsCCAN = d.Dealer__r.CCAN__c;
                if (dealerCodeAsCCAN == null) {
                    dealerCodeAsCCAN = accountMap.get(d.Dealer__r.Id);
                }
                contractPointersPrinGuarantorCodes.add(altGuarantorCode);
                principalGuarantorRecords.add(dealerCodeAsCCAN);
                TC_BridgewareBookContractRequestBean.RelatedParty rp = new TC_BridgewareBookContractRequestBean.RelatedParty();
                rp.setContractPointersPrinGuarantorCodes(contractPointersPrinGuarantorCodes);
                rp.setPrincipalGuarantorRecords(principalGuarantorRecords);
                relatedParties.add(rp);
            }
        }
        if (dataWrap.guarantorList.isEmpty()) {
            TC_BridgewareBookContractRequestBean.RelatedParty rp = new TC_BridgewareBookContractRequestBean.RelatedParty();
            relatedParties.add(rp);
        }
        dataWrap.guarantorList.clear();
        //dataWrap.dealerList.clear();
        bean.setRelatedParties(relatedParties);
        
        TC_BridgewareBookContractRequestBean.Contract c = new TC_BridgewareBookContractRequestBean.Contract();
        c.setActivationDate(dataWrap.opp.Commencement_Date__c);
        c.setDailyInterest(null);
        c.setDaysInYear(null);
        List<String> rateVarianceCd = null;
        c.setRateVarianceCd(rateVarianceCd);
        List<Date> rateVarDate = null;
        c.setRateVarDate(rateVarDate);
        List<Decimal> rateVariance = null;
        c.setRateVariance(rateVariance);
        c.setBaseRateCode(null);
        c.setDownPayment(dataWrap.opp.Down_Payment__c);
        c.setPurchaseOption(transRapport('PUR.OPTION', dataWrap.opp.Purchase_Options__c));
        List<String> approvingAuthority = new List<String>();
        approvingAuthority.add(dataWrap.opp.Approving_Authority__c);
        c.setApprovingAuthority(approvingAuthority);
        c.setArAddress1(dataWrap.opp.Account_Billing_Street__c);
        c.setArAddress2(dataWrap.opp.Account_Billing_Street2__c);
        c.setArAttention(dataWrap.opp.Billing_Attention_To__c);
        c.setArCity(dataWrap.opp.Account_Billing_City__c);
        c.setArName(dataWrap.opp.Account.Name);
        c.setArState(dataWrap.opp.Account_Billing_State_Province__c);
        c.setArZip(dataWrap.opp.Account_Billing_Zip_Postal_Code__c);
        List<String> contractBillingCycle = new List<String>();
        if (dataWrap.opp.Billing_Cycle__c != null) {
            contractBillingCycle.add(dataWrap.opp.Billing_Cycle__c.contains('January') ? '1' : '0');
            contractBillingCycle.add(dataWrap.opp.Billing_Cycle__c.contains('February') ? '1' : '0');
            contractBillingCycle.add(dataWrap.opp.Billing_Cycle__c.contains('March') ? '1' : '0');
            contractBillingCycle.add(dataWrap.opp.Billing_Cycle__c.contains('April') ? '1' : '0');
            contractBillingCycle.add(dataWrap.opp.Billing_Cycle__c.contains('May') ? '1' : '0');
            contractBillingCycle.add(dataWrap.opp.Billing_Cycle__c.contains('June') ? '1' : '0');
            contractBillingCycle.add(dataWrap.opp.Billing_Cycle__c.contains('July') ? '1' : '0');
            contractBillingCycle.add(dataWrap.opp.Billing_Cycle__c.contains('August') ? '1' : '0');
            contractBillingCycle.add(dataWrap.opp.Billing_Cycle__c.contains('September') ? '1' : '0');
            contractBillingCycle.add(dataWrap.opp.Billing_Cycle__c.contains('October') ? '1' : '0');
            contractBillingCycle.add(dataWrap.opp.Billing_Cycle__c.contains('November') ? '1' : '0');
            contractBillingCycle.add(dataWrap.opp.Billing_Cycle__c.contains('December') ? '1' : '0');
        }
        c.setContractBillingCycle(contractBillingCycle);
        c.setBookingDate(dataWrap.opp.Opportunity_Booked_Date__c == null ? null : Date.newinstance(dataWrap.opp.Opportunity_Booked_Date__c.year(), dataWrap.opp.Opportunity_Booked_Date__c.month(), dataWrap.opp.Opportunity_Booked_Date__c.day()));
        c.setBranch(transRapport('Branch', dataWrap.opp.Branch__c));
        c.setBrokerBookMethod(dataWrap.opp.Broker_Book_Method__c);
        c.setBrokerCode(dataWrap.opp.Broker_Code__c);
        c.setBrokerFees(dataWrap.opp.Broker_Fees__c);
        c.setBrokerTaxMethod(dataWrap.opp.Broker_Tax_Method__c);
        c.setContactFaxPhone(dataWrap.opp.Primary_Contact_Fax__c == null ? null : dataWrap.opp.Primary_Contact_Fax__c.replaceAll('\\D', ''));
        c.setContractNumber(dataWrap.opp.CCAN__c + '+');
        c.setContractPayment(dataWrap.opp.Payment_Amount__c);
        c.setContractTerm(dataWrap.opp.Terms__c == null ? null : Integer.valueOf(dataWrap.opp.Terms__c));
        c.setCreditAccountingName(dataWrap.opp.Billing_Contact__r.FirstName + ' ' + dataWrap.opp.Billing_Contact__r.LastName);
        // https://marlinbusiness.atlassian.net/browse/SAL-926
        //c.setCreditAccountingPhone(dataWrap.opp.Billing_Contact__r.Phone == null ? null : dataWrap.opp.Billing_Contact__r.Phone.replaceAll('\\D', ''));
        c.setCreditAccountingPhone(dataWrap.opp.Business_Phone__c == null ? null : dataWrap.opp.Business_Phone__c.replaceAll('\\D', ''));
        c.setCreditApplicationNumber(dataWrap.opp.Application__c);
        c.setCustomerAddress1(dataWrap.opp.Account_Business_Street__c);
        c.setCustomerAddress2(dataWrap.opp.Account_Business_Street2__c);
        c.setCustomerCity(dataWrap.opp.Account_Business_City__c);
        c.setCustomerCreditAccountNumber(dataWrap.opp.CCAN__c == null ? null : Integer.valueOf(dataWrap.opp.CCAN__c));
        c.setDoingBusinessAs(dataWrap.opp.DBA_Override__c);
        c.setCustomerName(dataWrap.opp.Account.Name);
        c.setCustomerState(dataWrap.opp.Account_Business_State_Province__c);
        c.setCustomerZip(dataWrap.opp.Account_Business_Zip_Postal_Code__c);
        
        // 2018-09-27 Based on logic from line 479 setting the updateDealerCode variable, set the dealer code to the correct code
        c.setDealerCode(updateDealerCode);
        c.setEndingPymtsInAdvance(dataWrap.opp.of_ending_payments__c == null ? null : Integer.valueOf(dataWrap.opp.of_ending_payments__c));
        c.setGrossEquipmentCost(dataWrap.opp.Equipment_Cost__c);
        c.setFedIDSocSec(dataWrap.opp.Tax_ID__c);
        c.setFirstFeeDate(dataWrap.opp.Broker_First_Fee_Date__c);
        c.setFirstPaymentAmount(dataWrap.opp.First_Payment_Amount__c);
        c.setFirstPaymentDate(dataWrap.opp.First_Payment_Date__c);
        c.setGracePeriod((Integer) dataWrap.opp.Grace_Period__c);
        c.setGrossContract(dataWrap.opp.Gross_Contract__c);
        c.setGrossFinance(dataWrap.opp.Gross_Finance__c);
        c.setIncomeMethod(dataWrap.opp.Income_Method__c);
        c.setIncomeStartDate(dataWrap.opp.Income_Start_Date__c);
        c.setInterimRents(dataWrap.opp.Interim_Rent__c);
        c.setLeadInvDays((Integer) dataWrap.opp.Lead_Invoice_Days__c);
        c.setInvoiceDueDay((Integer) dataWrap.opp.Invoicing_Due_Day__c);
        c.setInvoiceCode(dataWrap.opp.Invoice_Code__c);
        c.setInvoiceDescrip(dataWrap.opp.Invoice_Description__c);
        c.setLateChargeExempt(dataWrap.opp.Late_Charge_Exempt__c);
        c.setLateChargeRate(dataWrap.opp.Late_Charge_Rate__c != null ? dataWrap.opp.Late_Charge_Rate__c * 1000 : dataWrap.opp.Late_Charge_Rate__c);
        c.setContractType(dataWrap.opp.Contract_Type__c);
        c.setLessor(dataWrap.opp.Lessor__c == null ? null : Integer.valueOf(dataWrap.opp.Lessor__c));
        c.setMinLateCharge(dataWrap.opp.Minimum_Late_Charge__c);
        List<Integer> marketingRepPcts = new List<Integer>();
        marketingRepPcts.add((Integer) dataWrap.opp.Marketing_Rep_Percentage__c);
        c.setMarketingRepPcts(marketingRepPcts);
        List<String> mrktngRepRegion = new List<String>();
        mrktngRepRegion.add(dataWrap.opp.Region__c);
        c.setMrktngRepRegion(mrktngRepRegion);
        List<String> marketingRep = new List<String>();
        marketingRep.add(dataWrap.opp.Marketing_Rep_Code__c);
        c.setMarketingRep(marketingRep);
        c.setMunicipalLease(dataWrap.opp.Municipal_Lease__c);
        c.setContactEmail(dataWrap.opp.Billing_Contact__r.Email);
        c.setNumberOfUnits((Integer) dataWrap.opp.Number_of_Units__c);
        c.setOffice(dataWrap.opp.Office__c);
        c.setProductLine(dataWrap.opp.Product_Line__c);
        c.setProgramType(dataWrap.opp.Program_Type__c);
        c.setPromotion(dataWrap.opp.Promotion__c);
        c.setPurchaseOrderNumber(dataWrap.opp.PO_Number__c);
        c.setPaymentOption(dataWrap.opp.Payment_Option__c);
        c.setPaymentsInAdvance(dataWrap.opp.Ending_Pymts_in_Advance__c);
        c.setPymtsInArrears(dataWrap.opp.Payments_In_Arrears__c);
        c.setPymtsUpFront(dataWrap.opp.of_beginning_payments__c == null ? null : Integer.valueOf(dataWrap.opp.of_beginning_payments__c));
        c.setQuoteBuyout(dataWrap.opp.Quote_Buyout__c);
        c.setRegion(dataWrap.opp.Region__c);
        c.setOutOfBalance(dataWrap.opp.Out_of_Balance__c);
        c.setRemitToCode(dataWrap.opp.Remit_to_Window__c);
        c.setResidual(dataWrap.opp.Residual__c);
        c.setResidualCode(dataWrap.opp.Residual_Method__c);
        c.setRequiredSignature(dataWrap.opp.Primary_Contact__r.FirstName + ' ' + dataWrap.opp.Primary_Contact__r.LastName);
        // c.setReqPhone(dataWrap.opp.Primary_Contact__r.Phone == null ? null : dataWrap.opp.Primary_Contact__r.Phone.replaceAll('\\D', ''));
        c.setReqPhone(dataWrap.opp.Business_Phone__c == null ? null : dataWrap.opp.Business_Phone__c.replaceAll('\\D', ''));
        c.setSaleleasebackCode(dataWrap.opp.Sales_Leaseback__c);
        c.setSecurityDeposit(dataWrap.opp.Security_Deposit__c);
        //SAL-3430 Null Check
        if(dataWrap.opp.Recurring__c != null){
            if (dataWrap.opp.Recurring__c.equals('Recurring Only') || dataWrap.opp.Recurring__c.equals('One-Time & Recurring')) {
                c.setBankCode(dataWrap.opp.Bank_Code__c);
                c.setAcctNumber(dataWrap.opp.Bank_Account_Number__c);
                c.setAcctType(dataWrap.opp.Bank_Account_Type__c);
                c.setBankNumber(dataWrap.opp.Bank_Number__c);
            }
        }else{//Added for requirement change on SAL-3073
            c.setBankCode(dataWrap.opp.Bank_Code__c);
            c.setAcctNumber(dataWrap.opp.Bank_Account_Number__c);
            c.setAcctType(dataWrap.opp.Bank_Account_Type__c);
            c.setBankNumber(dataWrap.opp.Bank_Number__c);
        }
        c.setUserAlphaField10(dataWrap.opp.ACH_Miscs__c);
        c.setUserAlphaField7(dataWrap.opp.SLG__c); // Updated as per SAL-4836 
        c.setUserAlphaField8(dataWrap.opp.Renewal_Length__c);//SAL-4799- changed UM_Alpha_Field8__c to Renewal_Length__c
        c.setUserAlphaField3(dataWrap.opp.Reprint_Invoice__c);
        c.setUserComments(dataWrap.opp.Security_Comments__c);
        c.setUserTable1(dataWrap.opp.Facility_Code__c);
        c.setUserAmt1(dataWrap.opp.NPV_for_Profit__c);
        c.setUserCode(dataWrap.opp.Orig_Lease_Received__c);
        c.setUseTaxResponsibility(dataWrap.opp.Use_Tax_Responsibility__c);
        
        List<Integer> variablePaymentsDates = new List<Integer>();
        List<Decimal> variablePaymentAmounts = new List<Decimal>();
        
        for (Variable_Payment__c vp : dataWrap.variablePayList) {
            variablePaymentsDates.add((Integer) vp.of_payments__c);
            variablePaymentAmounts.add(vp.Payment_Amount__c);
        }
        c.setVariablePaymentsDates(variablePaymentsDates);
        c.setVariablePymtCode(dataWrap.opp.Variable_Payment__c);
        c.setVariablePaymentAmounts(variablePaymentAmounts);
        c.setAddlEmail(dataWrap.opp.Primary_Contact__r.Email);
        c.setGlLink(dataWrap.opp.GL_Link__c);
        c.setInvoiceFormat(dataWrap.opp.Invoice_Format__c);
        c.setMMRMetered(dataWrap.opp.Metered__c);
        c.setMeterAccount(dataWrap.opp.Meter_Account__c);
        //Begin: SAL-6343
        Boolean hasDealer = !dataWrap.dealerList.isEmpty();
        Boolean hasPO = !dataWrap.purchaseOrderList.isEmpty();
        c.setPrimeContract(hasDealer ? dataWrap.dealerList[0]?.Dealer__r.Dealer_Number__c : '');
        c.setDeliveryOrder(hasPO ? dataWrap.purchaseOrderList[0]?.Customer_PO_Number__c : '');
        c.setOrderDate(hasPO ? dataWrap.purchaseOrderList[0]?.Delivery_Order_Date__c : null);
        //c.setRequisitionNum((!dataWrap.contractList.isEmpty()) ? dataWrap.contractList[0]?.Requisition_Purchase_Req_No__c : '');
        c.setRequisitionNum('');
        c.setItemNum(hasPO ? dataWrap.purchaseOrderList[0]?.Item_Number__c : '');
        c.setIssuedName(hasPO ? dataWrap.purchaseOrderList[0]?.Issued_By__r.Name : '');
        c.setIssuedAddr1(hasPO ? dataWrap.purchaseOrderList[0]?.Issued_By_Address_1__c : '');
        c.setIssuedAddr2(hasPO ? dataWrap.purchaseOrderList[0]?.Issued_By_Address_2__c : '');
        c.setIssuedCity(hasPO ? dataWrap.purchaseOrderList[0]?.Issued_By_City__c : '');
        c.setIssuedState(hasPO ? dataWrap.purchaseOrderList[0]?.Issued_By_State__c : '');
        c.setIssuedZip(hasPO ? dataWrap.purchaseOrderList[0]?.Issued_By_Zip__c : null);
        c.setAdminName(hasPO ? dataWrap.purchaseOrderList[0]?.Administered_By__r.Name : '');
        c.setAdminAddr1(hasPO ? dataWrap.purchaseOrderList[0]?.Administered_By_Address_1__c : '');
        c.setAdminAddr2(hasPO ? dataWrap.purchaseOrderList[0]?.Administered_By_Address_2__c : '');
        c.setAdminCity(hasPO ? dataWrap.purchaseOrderList[0]?.Administered_By_City__c : '');
        c.setAdminState(hasPO ? dataWrap.purchaseOrderList[0]?.Administered_By_State__c : '');
        c.setAdminZip(hasPO ? dataWrap.purchaseOrderList[0]?.Administered_By_Zip__c : null);
        c.setPaymentsName(hasPO ? dataWrap.purchaseOrderList[0]?.Payment_Made_By__r.Name : '');
        c.setPaymentsAddr1(hasPO ? dataWrap.purchaseOrderList[0]?.Payment_Made_By_Address_1__c : '');
        c.setPaymentsAddr2(hasPO ? dataWrap.purchaseOrderList[0]?.Payment_Made_By_Address_2__c : '');
        c.setPaymentsCity(hasPO ? dataWrap.purchaseOrderList[0]?.Payment_Made_By_City__c : '');
        c.setPaymentsState(hasPO ? dataWrap.purchaseOrderList[0]?.Payment_Made_By_State__c : '');
        c.setPaymentsZip(hasPO ? dataWrap.purchaseOrderList[0]?.Payment_Made_By_Zip__c : null);
        c.setContractorName(hasDealer ? dataWrap.dealerList[0]?.Dealer__r.Name : '');
        c.setContractorAddr1(hasDealer ? dataWrap.dealerList[0]?.Dealer__r.Business_Address__c : '');
        c.setContractorAddr2(hasDealer ? dataWrap.dealerList[0]?.Dealer__r.Business_Address2__c : '');
        c.setContractorCity(hasDealer ? dataWrap.dealerList[0]?.Dealer__r.Business_City__c : '');
        c.setContractorState(hasDealer ? dataWrap.dealerList[0]?.Dealer__r.Business_State__c : '');
        c.setContractorZip(hasDealer ? dataWrap.dealerList[0]?.Dealer__r.Business_Zip__c : '');
        //End: SAL-6343
        bean.setContract(c);
        //dataWrap.opp = new Opportunity(Id = dataWrap?.opp?.Id);
        
        List<TC_BridgewareBookContractRequestBean.ContractBlendedIncome> contractBlendedIncomes = new List<TC_BridgewareBookContractRequestBean.ContractBlendedIncome>();
        
        for (Blended_Income_Item__c bii : dataWrap.blendedIncomeItemList) {
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
        
        if (dataWrap.blendedIncomeItemList.isEmpty()) {
            TC_BridgewareBookContractRequestBean.ContractBlendedIncome cbi = new TC_BridgewareBookContractRequestBean.ContractBlendedIncome();
            contractBlendedIncomes.add(cbi);
        }
        bean.setContractBlendedIncomes(contractBlendedIncomes);
        dataWrap.blendedIncomeItemList.clear();
        
        List<TC_BridgewareBookContractRequestBean.Asset> assets = new List<TC_BridgewareBookContractRequestBean.Asset>();
        Map<String,PopulateBonusDep__mdt> PopulateBonusDeps = PopulateBonusDep__mdt.getAll();
        Map<string, String> bounsDepMap = new Map<String, String>();
        for(PopulateBonusDep__mdt pbd : PopulateBonusDeps.values()){
            bounsDepMap.put(pbd.MasterLabel, pbd.Bonus_Depreciation_Code__c);
        }
        String yr = String.valueOf(system.today().year());
        Map<Id, List<Meter_Type__c>> assetIds = new Map<Id, List<Meter_Type__c>>();
        for (Asset__c asst : dataWrap.assetList) {
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
        
        for (Asset__c asst : dataWrap.assetList) {
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
            // SAL-7087 Rajesh Kumar Set for OL Contract
            a.setBeginDeprDate(TC_UCIStringHelper.monthYearValue(asst.Operating_Begin_Depreciation_Date__c));
            a.setOperLeaseBasis(asst.Operating_Depreciation_Basis__c);
            //a.setOperDeprLife((Integer) asst.Oper_Depr_LIM__c);//Existing
            a.setOperDeprLife((Integer) asst.Operating_Depreciation_Life__c);
            a.setOperDeprMethod(asst.Operating_Depreciation_Method__c);
            //End for OL Contract
            a.setSalvageValue(asst.Salvage_Value__c);
            a.setUpfrontTaxZipCode(asst.Equipment_Zip__c);
            //new fields for SAL-4946
            //a.setCustomerRef(asst.Customer_Reference__c);
            //a.setDeptLocation(asst.Department_Location__c);
            //SAL-7196
            Boolean isVA = dataWrap.opp.Originating_Business__c == PEAC_ConstantClass.OPPORTUNITY_ORIGINATING_BUSINESS_VA_PEAC;
			a.setCustomerRef(isVA ? asst.Customer_PO_Number__c : asst.Customer_Reference__c);
            a.setDeptLocation(isVA ? asst.Store_Number__c : asst.Department_Location__c);
            a.setDealerResidual(asst.Dealer_Residual__c);
            a.setAssetCostPercent(asst.Asset_Cost_Percent__c);//SAL-6693
            a.setAssetName(asst.Name);//SAL-6343
            a.setAssetAliasName(asst.Alias_Name__c);//SAL-6343
            a.setAssetClassification(asst.Asset_Classification__c == 'Hard'?'1':asst.Asset_Classification__c == 'Soft'?'2':'');//SAL-6343
            //a.setAssetClassification(asst.Asset_Classification__c);//SAL-6343
            a.setAssetRentalAmount(asst.Rental_Amount_fml__c);//SAL-6343
            
            if(assetIds.containsKey(asst.Id)){
                a.meterTypes = new List<TC_BridgewareBookContractRequestBean.AUMT>();
                if(assetIds.get(asst.Id).size() > 0){
                    for(Meter_Type__c meter : assetIds.get(asst.Id)){
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
            assets.add(a);
        }
        //Remove list size() to isEmpty()- Rajesh Kumar(LTIMindtree)
        if (assetIds.isEmpty()) {
            TC_BridgewareBookContractRequestBean.Asset a = new TC_BridgewareBookContractRequestBean.Asset();
            assets.add(a);
        }
        bean.setAssets(assets);
        dataWrap.assetList.clear();
        assetIds.clear();
        TC_BridgewareBookContractRequestBean.Dealer d = new TC_BridgewareBookContractRequestBean.Dealer();
        //d.setDealer('dealer');
        //d.setDealerDesc('dealerDesc');
        //d.setDealerFundDate(System.Today());
        //d.setDealerInvoiceNo('dealerInvoiceNo');
        //d.setDealerListPrice(2.00);
        //d.setSpecialGLcode('specialGLcode');
        bean.setDealer(d);
        List<TC_BridgewareBookContractRequestBean.ContractMiscBillable> contractMiscBillables = new List<TC_BridgewareBookContractRequestBean.ContractMiscBillable>();
        
        for (Miscellaneous_Billable_Item__c mbi : dataWrap.miscBillableItemList) {
            TC_BridgewareBookContractRequestBean.ContractMiscBillable cmb = new TC_BridgewareBookContractRequestBean.ContractMiscBillable();
            cmb.setAmountType(mbi.Misc_Amount_Type__c);
            cmb.setFutureBill(mbi.Future_Bill_Misc_Type__c);
            cmb.setFinalDate(TC_UCIStringHelper.monthYearValue(mbi.Final_Payment_Date__c));
            cmb.setFirstDate(TC_UCIStringHelper.monthYearValue(mbi.First_Payment_Date__c)); // SAL 868
            cmb.setIncInRent(mbi.Included_in_Rental__c);
            cmb.setAmount(mbi.Amount__c);
            cmb.setDisp(mbi.CB_Disp__c);
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
        if (dataWrap.miscBillableItemList.IsEmpty()) {
            TC_BridgewareBookContractRequestBean.ContractMiscBillable cmb = new TC_BridgewareBookContractRequestBean.ContractMiscBillable();
            contractMiscBillables.add(cmb);
        }
        bean.setContractMiscBillables(contractMiscBillables);
        dataWrap.miscBillableItemList.clear();
        
        List<TC_BridgewareBookContractRequestBean.ContractMiscInvoice> contractMiscInvoices = new List<TC_BridgewareBookContractRequestBean.ContractMiscInvoice>();
        for (Miscellaneous_Invoice_Item__c mii : dataWrap.miscInvoiceItemList) {
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
            contractMiscInvoices.add(cmi);
        }
        if (dataWrap.miscInvoiceItemList.isEmpty()) {
            TC_BridgewareBookContractRequestBean.ContractMiscInvoice cmi = new TC_BridgewareBookContractRequestBean.ContractMiscInvoice();
            contractMiscInvoices.add(cmi);
        }
        bean.setContractMiscInvoices(contractMiscInvoices);
        dataWrap.miscInvoiceItemList.clear();
        return bean;
    }
    
    private static Map<String,String> rapportMaps = new Map<String,String>();
    private static void buildRapportMap(){
        rapportMaps.Clear();
        for(MARLIN_Rapport_Mapping__mdt rapportMap:[SELECT MasterLabel, Rapport_Value__c, Field_Name__c FROM MARLIN_Rapport_Mapping__mdt]){
            rapportMaps.put(rapportMap.Field_Name__c + '__' + rapportMap.MasterLabel, rapportMap.Rapport_Value__c);
        }
    }
    
    private static String transRapport(String fieldName, Object argVal) {
        return argVal != null ? rapportMaps.Get(fieldName + '__' + String.valueof(argVal)) : '';
    }
    public class TC_BridgewareUtilityException extends Exception {}
}