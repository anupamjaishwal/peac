/*
* @author : sfdcdev, Tamarack Consulting, Inc.
* @date : 02/15/2018
* @description: http://docs.bridgewaretamarack.apiary.io
*
* © Copyright 2003 - 2018 Tamarack Consulting, Inc.  All Rights Reserved.
* 
*/

public with sharing class TC_BridgewareBookContractRequestBean {
    
    public String toUCIString() {
        String uciRecord = '';
        Integer counter = 0;
        IL10_Flag__c il10Setting = IL10_Flag__c.getValues('GeneralSetting');
        Boolean isIL10 = il10Setting.use_IL10__c; // booking always to IL10 regardless of record
        
        for (RelatedParty rp : relatedParties) {
            if (counter > 0)
                uciRecord += TC_UCIStringHelper.fieldSeparator;
            
            uciRecord += rp.toUCIString();
            counter++;
        }
        
        if (contract != null)
            uciRecord += TC_UCIStringHelper.fieldSeparator + contract.toUCIString();
        
        for (ContractBlendedIncome cbi : contractBlendedIncomes)
            uciRecord += TC_UCIStringHelper.fieldSeparator + cbi.toUCIString();
        if(isIL10){
                //AS|DE|AUMT|AUMTR|AUMT|AUMTR|AUMT|AUMTR|AS|DE|AUMT|AUMTR|AUMT|AUMTR|AUMT|AUMTR|AS|DE|AUMT|AUMTR|AUMT|AUMTR|AUMT|AUMTR
            for (Asset a : assets){
                uciRecord += TC_UCIStringHelper.fieldSeparator + a.toUCIString();
                if (dealer != null)
                    uciRecord += TC_UCIStringHelper.fieldSeparator + dealer.toUCIString();
                if(a.meterTypes != null){
                    for(AUMT meterType : a.meterTypes){
                        uciRecord += TC_UCIStringHelper.fieldSeparator + meterType.toUCIString();
                    //}
                    //for(AUMT meterType : a.meterTypes){
                        uciRecord += TC_UCIStringHelper.fieldSeparator + meterType.AUMTR.toUCIString();
                    }
                }
            }
        }else{
            for(Asset a : assets){
                uciRecord += TC_UCIStringHelper.fieldSeparator + a.toUCIString();
            }
            if(dealer != null){
                uciRecord += TC_UCIStringHelper.fieldSeparator + dealer.toUCIString();
            }
        }
        for (ContractMiscBillable cmb : contractMiscBillables)
            uciRecord += TC_UCIStringHelper.fieldSeparator + cmb.toUCIString();
        
        for (ContractMiscInvoice cmi : contractMiscInvoices)
            uciRecord += TC_UCIStringHelper.fieldSeparator + cmi.toUCIString();
        
        //uciRecord += TC_UCIStringHelper.fieldSeparator + 'EHL';
        system.debug('uciRecord:'+uciRecord);
        return uciRecord;
    }
    
    private String uciConfig;
    private List<RelatedParty> relatedParties;
    private Contract contract;
    private List<ContractBlendedIncome> contractBlendedIncomes;
    private List<Asset> assets;
    private Dealer dealer;
    private List<ContractMiscBillable> contractMiscBillables;
    private List<ContractMiscInvoice> contractMiscInvoices;

    public String getUciConfig() {
        return uciConfig;
    }

    public void setUciConfig(String uciConfig) {
        this.uciConfig = uciConfig;
    }

    public List<RelatedParty> getRelatedParties() {
        return relatedParties;
    }

    public void setRelatedParties(List<RelatedParty> relatedParties) {
        this.relatedParties = relatedParties;
    }

    public Contract getContract() {
        return contract;
    }

    public void setContract(Contract contract) {
        this.contract = contract;
    }

    public List<ContractBlendedIncome> getContractBlendedIncomes() {
        return contractBlendedIncomes;
    }

    public void setContractBlendedIncomes(List<ContractBlendedIncome> contractBlendedIncomes) {
        this.contractBlendedIncomes = contractBlendedIncomes;
    }

    public List<Asset> getAssets() {
        return assets;
    }

    public void setAssets(List<Asset> assets) {
        this.assets = assets;
    }

    public Dealer getDealer() {
        return dealer;
    }

    public void setDealer(Dealer dealer) {
        this.dealer = dealer;
    }

    public List<ContractMiscBillable> getContractMiscBillables() {
        return contractMiscBillables;
    }

    public void setContractMiscBillables(List<ContractMiscBillable> contractMiscBillables) {
        this.contractMiscBillables = contractMiscBillables;
    }

    public List<ContractMiscInvoice> getContractMiscInvoices() {
        return contractMiscInvoices;
    }

    public void setContractMiscInvoices(List<ContractMiscInvoice> contractMiscInvoices) {
        this.contractMiscInvoices = contractMiscInvoices;
    }
      
    public class RelatedParty {
        private List<String> contractPointersPrinGuarantorCodes;
        private List<String> principalGuarantorRecords;
        
        public List<String> getContractPointersPrinGuarantorCodes() {
            return contractPointersPrinGuarantorCodes;
        }
        public void setContractPointersPrinGuarantorCodes(List<String> contractPointersPrinGuarantorCodes) {
            this.contractPointersPrinGuarantorCodes = contractPointersPrinGuarantorCodes;
        }
        public List<String> getPrincipalGuarantorRecords() {
            return principalGuarantorRecords;
        }
        public void setPrincipalGuarantorRecords(List<String> principalGuarantorRecords) {
            this.principalGuarantorRecords = principalGuarantorRecords;
        }
        public String toUCIString() {
            return 'RP' + TC_UCIStringHelper.value(contractPointersPrinGuarantorCodes) + TC_UCIStringHelper.value(principalGuarantorRecords);
        }
    }

    public class Contract {
        public String toUCIString() {
            IL10_Flag__c il10Setting = IL10_Flag__c.getValues('GeneralSetting');
            Boolean isIL10 = il10Setting.use_IL10__c; // booking always to IL10 regardless of record
            return 'CO'
                    + TC_UCIStringHelper.value(activationDate)
                    + TC_UCIStringHelper.value(dailyInterest)
                    + TC_UCIStringHelper.value(daysInYear)
                    + TC_UCIStringHelper.value(rateVarianceCd)
                    + TC_UCIStringHelper.value(rateVarDate)
                    + TC_UCIStringHelper.value(rateVariance)
                    + TC_UCIStringHelper.value(baseRateCode)
                    + TC_UCIStringHelper.value(downPayment)
                    + TC_UCIStringHelper.value(purchaseOption)
                    + TC_UCIStringHelper.value(approvingAuthority)
                    + TC_UCIStringHelper.value(arAddress1)
                    + TC_UCIStringHelper.value(arAddress2)
                    + TC_UCIStringHelper.value(arAttention)
                    + TC_UCIStringHelper.value(arCity)
                    + TC_UCIStringHelper.value(arName)
                    + TC_UCIStringHelper.value(arState)
                    + TC_UCIStringHelper.value(arZip)
                    + TC_UCIStringHelper.value(bankCode)
                    + TC_UCIStringHelper.value(contractBillingCycle)
                    + TC_UCIStringHelper.value(bookingDate)
                    + TC_UCIStringHelper.value(branch)
                    + TC_UCIStringHelper.value(brokerBookMethod)
                    + TC_UCIStringHelper.value(brokerCode)
                    + TC_UCIStringHelper.value(brokerFees)
                    + TC_UCIStringHelper.value(brokerTaxMethod)
                    + TC_UCIStringHelper.value(contactFaxPhone)
                    + TC_UCIStringHelper.value(contractNumber)
                    + TC_UCIStringHelper.value(contractPayment)
                    + TC_UCIStringHelper.value(contractTerm)
                    + TC_UCIStringHelper.value(creditAccountingName)
                    + TC_UCIStringHelper.value(creditAccountingPhone)
                    + TC_UCIStringHelper.value(creditApplicationNumber)
                    + TC_UCIStringHelper.value(customerAddress1)
                    + TC_UCIStringHelper.value(customerAddress2)
                    + TC_UCIStringHelper.value(customerCity)
                    + TC_UCIStringHelper.value(customerCreditAccountNumber)
                    + TC_UCIStringHelper.value(doingBusinessAs)
                    + TC_UCIStringHelper.value(customerName)
                    + TC_UCIStringHelper.value(customerState)
                    + TC_UCIStringHelper.value(customerZip)
                    + TC_UCIStringHelper.value(dealerCode)
                    + TC_UCIStringHelper.value(endingPymtsInAdvance)
                    + TC_UCIStringHelper.value(grossEquipmentCost)
                    + TC_UCIStringHelper.value(fedIDSocSecNum)
                    + TC_UCIStringHelper.value(firstFeeDate)
                    + TC_UCIStringHelper.value(firstPaymentAmount)
                    + TC_UCIStringHelper.value(firstPaymentDate)
                    + TC_UCIStringHelper.value(gracePeriod)
                    + TC_UCIStringHelper.value(grossContract)
                    + TC_UCIStringHelper.value(grossFinance)
                    + TC_UCIStringHelper.value(incomeMethod)
                    + TC_UCIStringHelper.value(incomeStartDate)
                    + TC_UCIStringHelper.value(interimRents)
                    + TC_UCIStringHelper.value(leadInvDays)
                    + TC_UCIStringHelper.value(invoiceDueDay)
                    + TC_UCIStringHelper.value(invoiceCode)
                    + TC_UCIStringHelper.value(invoiceDescrip)
                    + TC_UCIStringHelper.value(lateChargeExempt)
                    + TC_UCIStringHelper.value(lateChargeRate)
                    + TC_UCIStringHelper.value(contractType)
                    + TC_UCIStringHelper.value(lessor)
                    + TC_UCIStringHelper.value(minLateCharge)
                    + TC_UCIStringHelper.value(marketingRepPcts)
                    + TC_UCIStringHelper.value(mrktngRepRegion)
                    + TC_UCIStringHelper.value(marketingRep)
                    + TC_UCIStringHelper.value(municipalLease)
                    + TC_UCIStringHelper.value(contactEmail)
                    + TC_UCIStringHelper.value(numberOfUnits)
                    + TC_UCIStringHelper.value(office)
                    + TC_UCIStringHelper.value(productLine)
                    + TC_UCIStringHelper.value(programType)
                    + TC_UCIStringHelper.value(promotion)
                    + TC_UCIStringHelper.value(purchaseOrderNumber)
                    + TC_UCIStringHelper.value(paymentOption)
                    + TC_UCIStringHelper.value(paymentsInAdvance)
                    + TC_UCIStringHelper.value(pymtsInArrears)
                    + TC_UCIStringHelper.value(pymtsUpFront)
                    + TC_UCIStringHelper.value(quoteBuyout)
                    + TC_UCIStringHelper.value(region)
                    + TC_UCIStringHelper.value(outOfBalance)
                    + TC_UCIStringHelper.value(remitToCode)
                    + TC_UCIStringHelper.value(residual)
                    + TC_UCIStringHelper.value(residualCode)
                    + TC_UCIStringHelper.value(requiredSignature)
                    + TC_UCIStringHelper.value(reqPhone)
                    + TC_UCIStringHelper.value(saleleasebackCode)
                    + TC_UCIStringHelper.value(securityDeposit)
                    + TC_UCIStringHelper.value(acctNumber)
                    + TC_UCIStringHelper.value(acctType)
                    + TC_UCIStringHelper.value(bankNumber)
                    + TC_UCIStringHelper.value(userAlphaField10)
                    + TC_UCIStringHelper.value(userAlphaField7)
                    + TC_UCIStringHelper.value(userAlphaField8)
                    + TC_UCIStringHelper.value(userAlphaField3)
                    + TC_UCIStringHelper.value(userComments)
                    + TC_UCIStringHelper.value(userTable1)
                    + TC_UCIStringHelper.value(userAmt1)
                    + TC_UCIStringHelper.value(userCode)
                    + TC_UCIStringHelper.value(useTaxResponsibility)
                    + TC_UCIStringHelper.value(variablePaymentsDates)
                    + TC_UCIStringHelper.value(variablePymtCode)
                    + TC_UCIStringHelper.value(variablePaymentAmounts)
                    + TC_UCIStringHelper.value(addlEmail)
                    + TC_UCIStringHelper.value(glLink)
                    + (isIL10? TC_UCIStringHelper.value(invoiceFormat)
                    + TC_UCIStringHelper.value(privateLabel)
                    + TC_UCIStringHelper.value(whiteLabel): '')
                    + TC_UCIStringHelper.value(MMRMetered)
                    + TC_UCIStringHelper.value(MeterAccount);
        }
        
        private String contractNumber;
        private Decimal remainingBalance;
        private String invoiceDescription;
        private Date commencementDate;
        private Date terminationDate;
        private boolean recurringACHFlag;
        private Decimal pastDueAmount;
        private Date pastDueDate;
        private Decimal currentDueAmount;
        private Date currentDueDate;
    
        public String getContractNumber() {
            return contractNumber;
        }
    
        public void setContractNumber(String contractNumber) {
            this.contractNumber = contractNumber;
        }
    
        public Decimal getRemainingBalance() {
            return remainingBalance;
        }
    
        public void setRemainingBalance(Decimal remainingBalance) {
            this.remainingBalance = remainingBalance;
        }
    
        public String getInvoiceDescription() {
            return invoiceDescription;
        }
    
        public void setInvoiceDescription(String invoiceDescription) {
            this.invoiceDescription = invoiceDescription;
        }
    
        public Date getCommencementDate() {
            return commencementDate;
        }
    
        public void setCommencementDate(Date commencementDate) {
            this.commencementDate = commencementDate;
        }
    
        public Date getTerminationDate() {
            return terminationDate;
        }
    
        public void setTerminationDate(Date terminationDate) {
            this.terminationDate = terminationDate;
        }
    
        public boolean getRecurringACHFlag() {
            return recurringACHFlag;
        }
    
        public void setRecurringACHFlag(boolean recurringACHFlag) {
            this.recurringACHFlag = recurringACHFlag;
        }
    
        public Decimal getPastDueAmount() {
            return pastDueAmount;
        }
    
        public void setPastDueAmount(Decimal pastDueAmount) {
            this.pastDueAmount = pastDueAmount;
        }
    
        public Date getPastDueDate() {
            return pastDueDate;
        }
    
        public void setPastDueDate(Date pastDueDate) {
            this.pastDueDate = pastDueDate;
        }
    
        public Decimal getCurrentDueAmount() {
            return currentDueAmount;
        }
    
        public void setCurrentDueAmount(Decimal currentDueAmount) {
            this.currentDueAmount = currentDueAmount;
        }
    
        public Date getCurrentDueDate() {
            return currentDueDate;
        }
    
        public void setCurrentDueDate(Date currentDueDate) {
            this.currentDueDate = currentDueDate;
        }

        private Date activationDate;
        private Decimal dailyInterest;
        private integer daysInYear;
        private List<String> rateVarianceCd;
        private List<Date> rateVarDate;
        private List<Decimal> rateVariance;
        private String baseRateCode;
        private Decimal downPayment;
        private String purchaseOption;
        private List<String> approvingAuthority;
        private String arAddress1;
        private String arAddress2;
        private String arAttention;
        private String arCity;
        private String arName;
        private String arState;
        private String arZip;
        private String bankCode;
        private List<String> contractBillingCycle;
        private Date bookingDate;
        private String branch;
        private String brokerBookMethod;
        private String brokerCode;
        private Decimal brokerFees;
        private String brokerTaxMethod;
        private String contactFaxPhone;
        private Decimal contractPayment;
        private integer contractTerm;
        private String creditAccountingName;
        private String creditAccountingPhone;
        private String creditApplicationNumber;
        private String customerAddress1;
        private String customerAddress2;
        private String customerCity;
        private integer customerCreditAccountNumber;
        private String doingBusinessAs;
        private String customerName;
        private String customerState;
        private String customerZip;
        private String dealerCode;
        private integer endingPymtsInAdvance;
        private Decimal grossEquipmentCost;
        private String fedIDSocSecNum;
        private Date firstFeeDate;
        private Decimal firstPaymentAmount;
        private Date firstPaymentDate;
        private integer gracePeriod;
        private Decimal grossContract;
        private Decimal grossFinance;
        private String incomeMethod;
        private Date incomeStartDate;
        private Decimal interimRents;
        private integer leadInvDays;
        private integer invoiceDueDay;
        private String invoiceCode;
        private String invoiceDescrip;
        private boolean lateChargeExempt;
        private Decimal lateChargeRate;
        private String contractType;
        private integer lessor;
        private Decimal minLateCharge;
        private List<Integer> marketingRepPcts;
        private List<String> mrktngRepRegion;
        private List<String> marketingRep;
        private boolean municipalLease;
        private String contactEmail;
        private integer numberOfUnits;
        private String office;
        private String productLine;
        private String programType;
        private String promotion;
        private String purchaseOrderNumber;
        private String paymentOption;
        private Decimal paymentsInAdvance;
        private boolean pymtsInArrears;
        private integer pymtsUpFront;
        private String quoteBuyout;
        private String region;
        private boolean outOfBalance;
        private String remitToCode;
        private Decimal residual;
        private String residualCode;
        private String requiredSignature;
        private String reqPhone;
        private boolean saleleasebackCode;
        private Decimal securityDeposit;
        private String acctNumber;
        private String acctType;
        private String bankNumber;
        private String userAlphaField10;
        private boolean userAlphaField7;
        private String userAlphaField8;
        private String userAlphaField3;
        private String userComments;
        private String userTable1;
        private Decimal userAmt1;
        private String userCode;
        private String useTaxResponsibility;
        private List<Integer> variablePaymentsDates;
        private boolean variablePymtCode;
        private List<Decimal> variablePaymentAmounts;
        private String addlEmail;
        private String glLink;
        private String invoiceFormat;
        private String privateLabel;
        private String whiteLabel;
        private String MMRMetered;
        private String MeterAccount;
        
    
        public Date getActivationDate() {
            return activationDate;
        }
    
        public void setActivationDate(Date activationDate) {
            this.activationDate = activationDate;
        }
    
        public Decimal getDailyInterest() {
            return dailyInterest;
        }
    
        public void setDailyInterest(Decimal dailyInterest) {
            this.dailyInterest = dailyInterest;
        }
    
        public integer getDaysInYear() {
            return daysInYear;
        }
    
        public void setDaysInYear(integer daysInYear) {
            this.daysInYear = daysInYear;
        }
    
        public List<String> getRateVarianceCd() {
            return rateVarianceCd;
        }
    
        public void setRateVarianceCd(List<String> rateVarianceCd) {
            this.rateVarianceCd = rateVarianceCd;
        }
    
        public List<Date> getRateVarDate() {
            return rateVarDate;
        }
    
        public void setRateVarDate(List<Date> rateVarDate) {
            this.rateVarDate = rateVarDate;
        }
    
        public List<Decimal> getRateVariance() {
            return rateVariance;
        }
    
        public void setRateVariance(List<Decimal> rateVariance) {
            this.rateVariance = rateVariance;
        }
    
        public String getBaseRateCode() {
            return baseRateCode;
        }
    
        public void setBaseRateCode(String baseRateCode) {
            this.baseRateCode = baseRateCode;
        }
    
        public Decimal getDownPayment() {
            return downPayment;
        }
    
        public void setDownPayment(Decimal downPayment) {
            this.downPayment = downPayment;
        }
    
        public String getPurchaseOption() {
            return purchaseOption;
        }
    
        public void setPurchaseOption(String purchaseOption) {
            this.purchaseOption = purchaseOption;
        }
    
        public List<String> getApprovingAuthority() {
            return approvingAuthority;
        }
    
        public void setApprovingAuthority(List<String> approvingAuthority) {
            this.approvingAuthority = approvingAuthority;
        }
    
        public String getArAddress1() {
            return arAddress1;
        }
    
        public void setArAddress1(String arAddress1) {
            this.arAddress1 = arAddress1;
        }
    
        public String getArAddress2() {
            return arAddress2;
        }
    
        public void setArAddress2(String arAddress2) {
            this.arAddress2 = arAddress2;
        }
    
        public String getArAttention() {
            return arAttention;
        }
    
        public void setArAttention(String arAttention) {
            this.arAttention = arAttention;
        }
    
        public String getArCity() {
            return arCity;
        }
    
        public void setArCity(String arCity) {
            this.arCity = arCity;
        }
    
        public String getArName() {
            return arName;
        }
    
        public void setArName(String arName) {
            this.arName = arName;
        }
    
        public String getArState() {
            return arState;
        }
    
        public void setArState(String arState) {
            this.arState = arState;
        }
    
        public String getArZip() {
            return arZip;
        }
    
        public void setArZip(String arZip) {
            this.arZip = arZip;
        }
    
        public String getBankCode() {
            return bankCode;
        }
    
        public void setBankCode(String bankCode) {
            this.bankCode = bankCode;
        }
    
        public List<String> getContractBillingCycle() {
            return contractBillingCycle;
        }
    
        public void setContractBillingCycle(List<String> contractBillingCycle) {
            this.contractBillingCycle = contractBillingCycle;
        }
    
        public Date getBookingDate() {
            return bookingDate;
        }
    
        public void setBookingDate(Date bookingDate) {
            this.bookingDate = bookingDate;
        }
    
        public String getBranch() {
            return branch;
        }
    
        public void setBranch(String branch) {
            this.branch = branch;
        }
    
        public String getBrokerBookMethod() {
            return brokerBookMethod;
        }
    
        public void setBrokerBookMethod(String brokerBookMethod) {
            this.brokerBookMethod = brokerBookMethod;
        }
    
        public String getBrokerCode() {
            return brokerCode;
        }
    
        public void setBrokerCode(String brokerCode) {
            this.brokerCode = brokerCode;
        }
    
        public Decimal getBrokerFees() {
            return brokerFees;
        }
    
        public void setBrokerFees(Decimal brokerFees) {
            this.brokerFees = brokerFees;
        }
    
        public String getBrokerTaxMethod() {
            return brokerTaxMethod;
        }
    
        public void setBrokerTaxMethod(String brokerTaxMethod) {
            this.brokerTaxMethod = brokerTaxMethod;
        }
    
        public String getContactFaxPhone() {
            return contactFaxPhone;
        }
    
        public void setContactFaxPhone(String contactFaxPhone) {
            this.contactFaxPhone = contactFaxPhone;
        }
    
        public Decimal getContractPayment() {
            return contractPayment;
        }
    
        public void setContractPayment(Decimal contractPayment) {
            this.contractPayment = contractPayment;
        }
    
        public integer getContractTerm() {
            return contractTerm;
        }
    
        public void setContractTerm(integer contractTerm) {
            this.contractTerm = contractTerm;
        }
    
        public String getCreditAccountingName() {
            return creditAccountingName;
        }
    
        public void setCreditAccountingName(String creditAccountingName) {
            this.creditAccountingName = creditAccountingName;
        }
    
        public String getCreditAccountingPhone() {
            return creditAccountingPhone;
        }
    
        public void setCreditAccountingPhone(String creditAccountingPhone) {
            this.creditAccountingPhone = creditAccountingPhone;
        }
    
        public String getCreditApplicationNumber() {
            return creditApplicationNumber;
        }
    
        public void setCreditApplicationNumber(String creditApplicationNumber) {
            this.creditApplicationNumber = creditApplicationNumber;
        }
    
        public String getCustomerAddress1() {
            return customerAddress1;
        }
    
        public void setCustomerAddress1(String customerAddress1) {
            this.customerAddress1 = customerAddress1;
        }
    
        public String getCustomerAddress2() {
            return customerAddress2;
        }
    
        public void setCustomerAddress2(String customerAddress2) {
            this.customerAddress2 = customerAddress2;
        }
    
        public String getCustomerCity() {
            return customerCity;
        }
    
        public void setCustomerCity(String customerCity) {
            this.customerCity = customerCity;
        }
    
        public integer getCustomerCreditAccountNumber() {
            return customerCreditAccountNumber;
        }
    
        public void setCustomerCreditAccountNumber(integer customerCreditAccountNumber) {
            this.customerCreditAccountNumber = customerCreditAccountNumber;
        }
    
        public String getDoingBusinessAs() {
            return doingBusinessAs;
        }
    
        public void setDoingBusinessAs(String doingBusinessAs) {
            this.doingBusinessAs = doingBusinessAs;
        }
    
        public String getCustomerName() {
            return customerName;
        }
    
        public void setCustomerName(String customerName) {
            this.customerName = customerName;
        }
    
        public String getCustomerState() {
            return customerState;
        }
    
        public void setCustomerState(String customerState) {
            this.customerState = customerState;
        }
    
        public String getCustomerZip() {
            return customerZip;
        }
    
        public void setCustomerZip(String customerZip) {
            this.customerZip = customerZip;
        }
    
        public String getDealerCode() {
            return dealerCode;
        }
    
        public void setDealerCode(String dealerCode) {
            this.dealerCode = dealerCode;
        }
    
        public integer getEndingPymtsInAdvance() {
            return endingPymtsInAdvance;
        }
    
        public void setEndingPymtsInAdvance(integer endingPymtsInAdvance) {
            this.endingPymtsInAdvance = endingPymtsInAdvance;
        }
    
        public Decimal getGrossEquipmentCost() {
            return grossEquipmentCost;
        }
    
        public void setGrossEquipmentCost(Decimal grossEquipmentCost) {
            this.grossEquipmentCost = grossEquipmentCost;
        }
    
        public String getFedIDSocSec() {
            return fedIDSocSecNum;
        }
    
        public void setFedIDSocSec(String fedIDSocSec) {
            this.fedIDSocSecNum = fedIDSocSec;
        }
    
        public Date getFirstFeeDate() {
            return firstFeeDate;
        }
    
        public void setFirstFeeDate(Date firstFeeDate) {
            this.firstFeeDate = firstFeeDate;
        }
    
        public Decimal getFirstPaymentAmount() {
            return firstPaymentAmount;
        }
    
        public void setFirstPaymentAmount(Decimal firstPaymentAmount) {
            this.firstPaymentAmount = firstPaymentAmount;
        }
    
        public Date getFirstPaymentDate() {
            return firstPaymentDate;
        }
    
        public void setFirstPaymentDate(Date firstPaymentDate) {
            this.firstPaymentDate = firstPaymentDate;
        }
    
        public integer getGracePeriod() {
            return gracePeriod;
        }
    
        public void setGracePeriod(integer gracePeriod) {
            this.gracePeriod = gracePeriod;
        }
    
        public Decimal getGrossContract() {
            return grossContract;
        }
    
        public void setGrossContract(Decimal grossContract) {
            this.grossContract = grossContract;
        }
    
        public Decimal getGrossFinance() {
            return grossFinance;
        }
    
        public void setGrossFinance(Decimal grossFinance) {
            this.grossFinance = grossFinance;
        }
    
        public String getIncomeMethod() {
            return incomeMethod;
        }
    
        public void setIncomeMethod(String incomeMethod) {
            this.incomeMethod = incomeMethod;
        }
    
        public Date getIncomeStartDate() {
            return incomeStartDate;
        }
    
        public void setIncomeStartDate(Date incomeStartDate) {
            this.incomeStartDate = incomeStartDate;
        }
    
        public Decimal getInterimRents() {
            return interimRents;
        }
    
        public void setInterimRents(Decimal interimRents) {
            this.interimRents = interimRents;
        }
    
        public integer getLeadInvDays() {
            return leadInvDays;
        }
    
        public void setLeadInvDays(integer leadInvDays) {
            this.leadInvDays = leadInvDays;
        }
    
        public integer getInvoiceDueDay() {
            return invoiceDueDay;
        }
    
        public void setInvoiceDueDay(integer invoiceDueDay) {
            this.invoiceDueDay = invoiceDueDay;
        }
    
        public String getInvoiceCode() {
            return invoiceCode;
        }
    
        public void setInvoiceCode(String invoiceCode) {
            this.invoiceCode = invoiceCode;
        }
    
        public String getInvoiceDescrip() {
            return invoiceDescrip;
        }
    
        public void setInvoiceDescrip(String invoiceDescrip) {
            this.invoiceDescrip = invoiceDescrip;
        }
    
        public boolean getLateChargeExempt() {
            return lateChargeExempt;
        }
    
        public void setLateChargeExempt(boolean lateChargeExempt) {
            this.lateChargeExempt = lateChargeExempt;
        }
    
        public Decimal getLateChargeRate() {
            return lateChargeRate;
        }
    
        public void setLateChargeRate(Decimal lateChargeRate) {
            this.lateChargeRate = lateChargeRate;
        }
    
        public String getContractType() {
            return contractType;
        }
    
        public void setContractType(String contractType) {
            this.contractType = contractType;
        }
    
        public integer getLessor() {
            return lessor;
        }
    
        public void setLessor(integer lessor) {
            this.lessor = lessor;
        }
    
        public Decimal getMinLateCharge() {
            return minLateCharge;
        }
    
        public void setMinLateCharge(Decimal minLateCharge) {
            this.minLateCharge = minLateCharge;
        }
    
        public List<Integer> getMarketingRepPcts() {
            return marketingRepPcts;
        }
    
        public void setMarketingRepPcts(List<Integer> marketingRepPcts) {
            this.marketingRepPcts = marketingRepPcts;
        }
    
        public List<String> getMrktngRepRegion() {
            return mrktngRepRegion;
        }
    
        public void setMrktngRepRegion(List<String> mrktngRepRegion) {
            this.mrktngRepRegion = mrktngRepRegion;
        }
    
        public List<String> getMarketingRep() {
            return marketingRep;
        }
    
        public void setMarketingRep(List<String> marketingRep) {
            this.marketingRep = marketingRep;
        }
    
        public boolean getMunicipalLease() {
            return municipalLease;
        }
    
        public void setMunicipalLease(boolean municipalLease) {
            this.municipalLease = municipalLease;
        }
    
        public String getContactEmail() {
            return contactEmail;
        }
    
        public void setContactEmail(String contactEmail) {
            this.contactEmail = contactEmail;
        }
    
        public integer getNumberOfUnits() {
            return numberOfUnits;
        }
    
        public void setNumberOfUnits(integer numberOfUnits) {
            this.numberOfUnits = numberOfUnits;
        }
    
        public String getOffice() {
            return office;
        }
    
        public void setOffice(String office) {
            this.office = office;
        }
    
        public String getProductLine() {
            return productLine;
        }
    
        public void setProductLine(String productLine) {
            this.productLine = productLine;
        }
    
        public String getProgramType() {
            return programType;
        }
    
        public void setProgramType(String programType) {
            this.programType = programType;
        }
    
        public String getPromotion() {
            return promotion;
        }
    
        public void setPromotion(String promotion) {
            this.promotion = promotion;
        }
    
        public String getPurchaseOrderNumber() {
            return purchaseOrderNumber;
        }
    
        public void setPurchaseOrderNumber(String purchaseOrderNumber) {
            this.purchaseOrderNumber = purchaseOrderNumber;
        }
    
        public String getPaymentOption() {
            return paymentOption;
        }
    
        public void setPaymentOption(String paymentOption) {
            this.paymentOption = paymentOption;
        }
    
        public Decimal getPaymentsInAdvance() {
            return paymentsInAdvance;
        }
    
        public void setPaymentsInAdvance(Decimal paymentsInAdvance) {
            this.paymentsInAdvance = paymentsInAdvance;
        }
    
        public boolean getPymtsInArrears() {
            return pymtsInArrears;
        }
    
        public void setPymtsInArrears(boolean pymtsInArrears) {
            this.pymtsInArrears = pymtsInArrears;
        }
    
        public integer getPymtsUpFront() {
            return pymtsUpFront;
        }
    
        public void setPymtsUpFront(integer pymtsUpFront) {
            this.pymtsUpFront = pymtsUpFront;
        }
    
        public String getQuoteBuyout() {
            return quoteBuyout;
        }
    
        public void setQuoteBuyout(String quoteBuyout) {
            this.quoteBuyout = quoteBuyout;
        }
    
        public String getRegion() {
            return region;
        }
    
        public void setRegion(String region) {
            this.region = region;
        }
    
        public boolean getOutOfBalance() {
            return outOfBalance;
        }
    
        public void setOutOfBalance(boolean outOfBalance) {
            this.outOfBalance = outOfBalance;
        }
    
        public String getRemitToCode() {
            return remitToCode;
        }
    
        public void setRemitToCode(String remitToCode) {
            this.remitToCode = remitToCode;
        }
    
        public Decimal getResidual() {
            return residual;
        }
    
        public void setResidual(Decimal residual) {
            this.residual = residual;
        }
    
        public String getResidualCode() {
            return residualCode;
        }
    
        public void setResidualCode(String residualCode) {
            this.residualCode = residualCode;
        }
    
        public String getRequiredSignature() {
            return requiredSignature;
        }
    
        public void setRequiredSignature(String requiredSignature) {
            this.requiredSignature = requiredSignature;
        }
    
        public String getReqPhone() {
            return reqPhone;
        }
    
        public void setReqPhone(String reqPhone) {
            this.reqPhone = reqPhone;
        }
    
        public boolean getSaleleasebackCode() {
            return saleleasebackCode;
        }
    
        public void setSaleleasebackCode(boolean saleleasebackCode) {
            this.saleleasebackCode = saleleasebackCode;
        }
    
        public Decimal getSecurityDeposit() {
            return securityDeposit;
        }
    
        public void setSecurityDeposit(Decimal securityDeposit) {
            this.securityDeposit = securityDeposit;
        }
    
        public String getAcctNumber() {
            return acctNumber;
        }
    
        public void setAcctNumber(String acctNumber) {
            this.acctNumber = acctNumber;
        }
    
        public String getAcctType() {
            return acctType;
        }
    
        public void setAcctType(String acctType) {
            this.acctType = acctType;
        }
    
        public String getBankNumber() {
            return bankNumber;
        }
    
        public void setBankNumber(String bankNumber) {
            this.bankNumber = bankNumber;
        }
    
        public String getUserAlphaField10() {
            return userAlphaField10;
        }
    
        public void setUserAlphaField10(String userAlphaField10) {
            this.userAlphaField10 = userAlphaField10;
        }
    
        public boolean getUserAlphaField7() {
            return userAlphaField7;
        }
    
        public void setUserAlphaField7(boolean userAlphaField7) {
            this.userAlphaField7 = userAlphaField7;
        }
    
        public String getUserAlphaField8() {
            return userAlphaField8;
        }
    
        public void setUserAlphaField8(String userAlphaField8) {
            this.userAlphaField8 = userAlphaField8;
        }
    
        public String getUserAlphaField3() {
            return userAlphaField3;
        }
    
        public void setUserAlphaField3(String userAlphaField3) {
            this.userAlphaField3 = userAlphaField3;
        }
    
        public String getUserComments() {
            return userComments;
        }
    
        public void setUserComments(String userComments) {
            this.userComments = userComments;
        }
    
        public String getUserTable1() {
            return userTable1;
        }
    
        public void setUserTable1(String userTable1) {
            this.userTable1 = userTable1;
        }
    
        public Decimal getUserAmt1() {
            return userAmt1;
        }
    
        public void setUserAmt1(Decimal userAmt1) {
            this.userAmt1 = userAmt1;
        }
    
        public String getUserCode() {
            return userCode;
        }
    
        public void setUserCode(String userCode) {
            this.userCode = userCode;
        }
    
        public String getUseTaxResponsibility() {
            return useTaxResponsibility;
        }
    
        public void setUseTaxResponsibility(String useTaxResponsibility) {
            this.useTaxResponsibility = useTaxResponsibility;
        }
    
        public List<Integer> getVariablePaymentsDates() {
            return variablePaymentsDates;
        }
    
        public void setVariablePaymentsDates(List<Integer> variablePaymentsDates) {
            this.variablePaymentsDates = variablePaymentsDates;
        }
    
        public boolean getVariablePymtCode() {
            return variablePymtCode;
        }
    
        public void setVariablePymtCode(boolean variablePymtCode) {
            this.variablePymtCode = variablePymtCode;
        }
    
        public List<Decimal> getVariablePaymentAmounts() {
            return variablePaymentAmounts;
        }
    
        public void setVariablePaymentAmounts(List<Decimal> variablePaymentAmounts) {
            this.variablePaymentAmounts = variablePaymentAmounts;
        }
    
        public String getAddlEmail() {
            return addlEmail;
        }
    
        public void setAddlEmail(String addlEmail) {
            this.addlEmail = addlEmail;
        }
    
        public String getGlLink() {
            return glLink;
        }
    
        public void setGlLink(String glLink) {
            this.glLink = glLink;
        }
        
        public string getInvoiceFormat(){
            return invoiceFormat;
        }
        public void setInvoiceFormat(String invFor){
            this.invoiceFormat = invFor;
        }
        
        public string getprivateLabel(){
            return privateLabel;
        }
        public void setprivateLabel(String privateLabel){
            this.privateLabel = privateLabel;
        }
        
        public string getwhiteLabel(){
            return whiteLabel;
        }
        public void setwhiteLabel(String whiteLabel){
            this.whiteLabel = whiteLabel;
        }
        
        public String getMMRMetered() {
            return MMRMetered;
        }
    
        public void setMMRMetered(String MMRM) {
            this.MMRMetered = MMRM;
        }
        
       public String getMeterAccount() {
            return MeterAccount;
        }
    
        public void setMeterAccount(String MeterAccount) {
            this.MeterAccount = MeterAccount;
        }
        
        
    }
    
    public class ContractBlendedIncome {
        public String toUCIString() {
            return 'CBL'
                    + TC_UCIStringHelper.value(includeInQuote)
                    + TC_UCIStringHelper.value(amount)
                    + TC_UCIStringHelper.value(beginDate)
                    + TC_UCIStringHelper.value(bookingDate)
                    + TC_UCIStringHelper.value(calculatedRate)
                    + TC_UCIStringHelper.value(code)
                    + TC_UCIStringHelper.value(dealerManfCode)
                    + TC_UCIStringHelper.value(incContRate)
                    + TC_UCIStringHelper.value(incomeMethod)
                    + TC_UCIStringHelper.value(taxCalculationMethod)
                    + TC_UCIStringHelper.value(term)
                    + TC_UCIStringHelper.value(timing);
        }
        
        private boolean includeInQuote;
        private Decimal amount;
        private Date beginDate;
        private Date bookingDate;
        private Decimal calculatedRate;
        private String code;
        private String dealerManfCode;
        private boolean incContRate;
        private String incomeMethod;
        private String taxCalculationMethod;
        private integer term;
        private String timing;
    
        public boolean getIncludeInQuote() {
            return includeInQuote;
        }
    
        public void setIncludeInQuote(boolean includeInQuote) {
            this.includeInQuote = includeInQuote;
        }
    
        public Decimal getAmount() {
            return amount;
        }
    
        public void setAmount(Decimal amount) {
            this.amount = amount;
        }
    
        public Date getBeginDate() {
            return beginDate;
        }
    
        public void setBeginDate(Date beginDate) {
            this.beginDate = beginDate;
        }
    
        public Date getBookingDate() {
            return bookingDate;
        }
    
        public void setBookingDate(Date bookingDate) {
            this.bookingDate = bookingDate;
        }
    
        public Decimal getCalculatedRate() {
            return calculatedRate;
        }
    
        public void setCalculatedRate(Decimal calculatedRate) {
            this.calculatedRate = calculatedRate;
        }
    
        public String getCode() {
            return code;
        }
    
        public void setCode(String code) {
            this.code = code;
        }
    
        public String getDealerManfCode() {
            return dealerManfCode;
        }
    
        public void setDealerManfCode(String dealerManfCode) {
            this.dealerManfCode = dealerManfCode;
        }
    
        public boolean getIncContRate() {
            return incContRate;
        }
    
        public void setIncContRate(boolean incContRate) {
            this.incContRate = incContRate;
        }
    
        public String getIncomeMethod() {
            return incomeMethod;
        }
    
        public void setIncomeMethod(String incomeMethod) {
            this.incomeMethod = incomeMethod;
        }
    
        public String getTaxCalculationMethod() {
            return taxCalculationMethod;
        }
    
        public void setTaxCalculationMethod(String taxCalculationMethod) {
            this.taxCalculationMethod = taxCalculationMethod;
        }
    
        public integer getTerm() {
            return term;
        }
    
        public void setTerm(integer term) {
            this.term = term;
        }
    
        public String getTiming() {
            return timing;
        }
    
        public void setTiming(String timing) {
            this.timing = timing;
        }
    }
    
    public class Asset {
        public String toUCIString() {
            IL10_Flag__c il10Setting = IL10_Flag__c.getValues('GeneralSetting');
            Boolean isIL10 = il10Setting.use_IL10__c; // booking always to IL10 regardless of record
            return 'AS'
                    + TC_UCIStringHelper.value(assetUser3Alphanum1)
                    + TC_UCIStringHelper.value(assetUser3Table1)
                    + TC_UCIStringHelper.value(assetUserDef)
                    + TC_UCIStringHelper.value(assetUserField3)
                    + TC_UCIStringHelper.value(assetUserField4)
                    + TC_UCIStringHelper.value(assetUserField5)
                    + TC_UCIStringHelper.value(assetUserField6)
                    + TC_UCIStringHelper.value(assetUserField7)
                    + TC_UCIStringHelper.value(lcCityTaxCode)
                    + TC_UCIStringHelper.value(lcCntyTaxCode)
                    + TC_UCIStringHelper.value(lcStateTaxCd)
                    + TC_UCIStringHelper.value(miscCityTaxCd)
                    + TC_UCIStringHelper.value(miscCntyTaxCd)
                    + TC_UCIStringHelper.value(miscStTaxCode)
                    + TC_UCIStringHelper.value(yearofManuf)
                    + TC_UCIStringHelper.value(originalCost)
                    + TC_UCIStringHelper.value(salesProfit)
                    + TC_UCIStringHelper.value(vehicleMake)
                    + TC_UCIStringHelper.value(aceDeprBasis)
                    + TC_UCIStringHelper.value(detailedAssetDescription)
                    + TC_UCIStringHelper.value(adsClassLIM)
                    + TC_UCIStringHelper.value(amtDeprBasis)
                    + TC_UCIStringHelper.value(recourseAmt)
                    + TC_UCIStringHelper.value(recourseCode)
                    + TC_UCIStringHelper.value(recourseComments)
                    + TC_UCIStringHelper.value(recoursePct)
                    + TC_UCIStringHelper.value(recourseTerm)
                    + TC_UCIStringHelper.value(assetStatus)
                    /* as per SAL-4549 not for IL10 */
                    + (!isIL10?
                     TC_UCIStringHelper.value(rate)
                   + TC_UCIStringHelper.value(estReadingsAllowed)
                   + TC_UCIStringHelper.value(billingCycle)
                   + TC_UCIStringHelper.value(contractedCycle)
                   + TC_UCIStringHelper.value(contractedThruDate)
                   + TC_UCIStringHelper.value(numUnitsUsedCTD)
                   + TC_UCIStringHelper.value(dlrInvNum)
                   + TC_UCIStringHelper.value(dlrReadDt)
                   + TC_UCIStringHelper.value(readingDates)
                   + TC_UCIStringHelper.value(readingMethods)
                   + TC_UCIStringHelper.value(readingsinUnits)
                   + TC_UCIStringHelper.value(serviceDates)
                   + TC_UCIStringHelper.value(numServiceUnitsMade)
                   + TC_UCIStringHelper.value(usageQuantity)
                   : '')
                    + TC_UCIStringHelper.value(assetUserTable1)
                    + TC_UCIStringHelper.value(fedBeginDeprDate)
                    + (isIL10? TC_UCIStringHelper.value(bonusdepr): '')
                    + TC_UCIStringHelper.value(calcACEDepr)
                    + TC_UCIStringHelper.value(calcAMTDepr)
                    + TC_UCIStringHelper.value(taxDeprBasis)
                    + TC_UCIStringHelper.value(cityCode)
                    + TC_UCIStringHelper.value(cityTaxCode)
                    + TC_UCIStringHelper.value(cityTaxPct)
                    + TC_UCIStringHelper.value(countyCode)
                    + TC_UCIStringHelper.value(countyTaxCode)
                    + TC_UCIStringHelper.value(countyTaxPct)
                    + TC_UCIStringHelper.value(assetAddr1)
                    + TC_UCIStringHelper.value(assetAddr2)
                    + TC_UCIStringHelper.value(assetCity)
                    + TC_UCIStringHelper.value(assetCode)
                    + TC_UCIStringHelper.value(equipmentCost)
                    + TC_UCIStringHelper.value(assetDesc)
                    + TC_UCIStringHelper.value(discount)
                    + TC_UCIStringHelper.value(listPrice)
                    + TC_UCIStringHelper.value(assetState)
                    + TC_UCIStringHelper.value(assetZip)
                    + TC_UCIStringHelper.value(fedCalcBasis)
                    + TC_UCIStringHelper.value(fedConvention)
                    + TC_UCIStringHelper.value(deprPercentages)
                    + TC_UCIStringHelper.value(federalLife)
                    + (isIL10? TC_UCIStringHelper.value(ManagerResidual): '')
                    + TC_UCIStringHelper.value(manufacturer)
                    + TC_UCIStringHelper.value(model)
                    + TC_UCIStringHelper.value(maxCityPerInv)
                    + TC_UCIStringHelper.value(maxCityTax)
                    + TC_UCIStringHelper.value(maxCntyPerInv)
                    + TC_UCIStringHelper.value(maxCntyTax)
                    + TC_UCIStringHelper.value(maxStateTax)
                    + TC_UCIStringHelper.value(newUsedCode)
                    + TC_UCIStringHelper.value(propTaxStatus)
                    + TC_UCIStringHelper.value(purchaseOption)
                    + TC_UCIStringHelper.value(renewalOption)
                    + TC_UCIStringHelper.value(quantity)
                    + TC_UCIStringHelper.value(residualPercent)
                    + TC_UCIStringHelper.value(residualAmount)
                    + TC_UCIStringHelper.value(federalMethod)
                    + TC_UCIStringHelper.value(serialNumber)
                    + TC_UCIStringHelper.value(stateBeginDeprDate)
                    + TC_UCIStringHelper.value(stateDeprBasis)
                    + TC_UCIStringHelper.value(stateLife)
                    + TC_UCIStringHelper.value(stateMethod)
                    + TC_UCIStringHelper.value(stateCode)
                    + TC_UCIStringHelper.value(stateTaxCode)
                    + TC_UCIStringHelper.value(stateTaxPct)
                    + TC_UCIStringHelper.value(cityTransTaxPct)
                    + TC_UCIStringHelper.value(cntyTransTaxPct)
                    + TC_UCIStringHelper.value(upfrontTaxBasis)
                    + TC_UCIStringHelper.value(upfrontTaxCityCode)
                    + TC_UCIStringHelper.value(upfrontTaxCityAmt)
                    + TC_UCIStringHelper.value(upfrontTaxCntyCode)
                    + TC_UCIStringHelper.value(upfrontTaxCntyAmt)
                    + TC_UCIStringHelper.value(upfrontTaxFinanced)
                    + TC_UCIStringHelper.value(upfrontTaxRespCode)
                    + TC_UCIStringHelper.value(upfrontTaxStateCode)
                    + TC_UCIStringHelper.value(upfrontTaxStateAmt)
                    + TC_UCIStringHelper.value(taxCode)
                    + TC_UCIStringHelper.value(upfrontTaxTCityAmt)
                    + TC_UCIStringHelper.value(upfrontTaxTCntyAmt)
                    + TC_UCIStringHelper.value(beginDeprDate)
                    + TC_UCIStringHelper.value(operLeaseBasis)
                    + TC_UCIStringHelper.value(operDeprLife)
                    + TC_UCIStringHelper.value(operDeprMethod)
                    + TC_UCIStringHelper.value(salvageValue)
                    + TC_UCIStringHelper.value(upfrontTaxZipCode)
                    + TC_UCIStringHelper.value(CustomerRef)
                    + TC_UCIStringHelper.value(DeptLocation)
                    + TC_UCIStringHelper.value(DealerResidual);
            
        }
        
        private String assetUser3Alphanum1;
        private String assetUser3Table1;
        private List<String> assetUserDef;
        private String assetUserField3;
        private String assetUserField4;
        private String assetUserField5;
        private String assetUserField6;
        private String assetUserField7;
        private String lcCityTaxCode;
        private String lcCntyTaxCode;
        private String lcStateTaxCd;
        private String miscCityTaxCd;
        private String miscCntyTaxCd;
        private String miscStTaxCode;
        private String yearofManuf;
        private Decimal originalCost;
        private Decimal salesProfit;
        private String vehicleMake;
        private Decimal aceDeprBasis;
        private String detailedAssetDescription;
        private integer adsClassLIM;
        private Decimal amtDeprBasis;
        private Decimal recourseAmt;
        private String recourseCode;
        private String recourseComments;
        private Decimal recoursePct;
        private integer recourseTerm;
        private String assetStatus;
        private List<Decimal> rate;
        private boolean estReadingsAllowed;
        private List<String> billingCycle;
        private List<String> contractedCycle;
        private List<String> contractedThruDate;
        private List<Decimal> numUnitsUsedCTD;
        private List<String> dlrInvNum;
        private List<Date> dlrReadDt;
        private List<Date> readingDates;
        private List<String> readingMethods;
        private List<Decimal> readingsinUnits;
        private List<Date> serviceDates;
        private List<Decimal> numServiceUnitsMade;
        private List<Decimal> usageQuantity;
        private String assetUserTable1;
        private Date fedBeginDeprDate;
        private boolean calcACEDepr;
        private boolean calcAMTDepr;
        private Decimal taxDeprBasis;
        private String cityCode;
        private String cityTaxCode;
        private Decimal cityTaxPct;
        private String countyCode;
        private String countyTaxCode;
        private Decimal countyTaxPct;
        private String assetAddr1;
        private String assetAddr2;
        private String assetCity;
        private String assetCode;
        private Decimal equipmentCost;
        private String assetDesc;
        private Decimal discount;
        private Decimal listPrice;
        private String assetState;
        private String assetZip;
        private Decimal fedCalcBasis;
        private integer fedConvention;
        private Decimal deprPercentages;
        private integer federalLife;
        private integer ManagerResidual;
        private String manufacturer;
        private String model;
        private Decimal maxCityPerInv;
        private Decimal maxCityTax;
        private Decimal maxCntyPerInv;
        private Decimal maxCntyTax;
        private Decimal maxStateTax;
        private String newUsedCode;
        private String propTaxStatus;
        private String purchaseOption;
        private String renewalOption;
        private integer quantity;
        private Decimal residualPercent;
        private Decimal residualAmount;
        private String federalMethod;
        private String serialNumber;
        private String stateBeginDeprDate;
        private Decimal stateDeprBasis;
        private integer stateLife;
        private integer stateMethod;
        private String stateCode;
        private String stateTaxCode;
        private Decimal stateTaxPct;
        private Decimal cityTransTaxPct;
        private Decimal cntyTransTaxPct;
        private Decimal upfrontTaxBasis;
        private String upfrontTaxCityCode;
        private Decimal upfrontTaxCityAmt;
        private String upfrontTaxCntyCode;
        private Decimal upfrontTaxCntyAmt;
        private boolean upfrontTaxFinanced;
        private String upfrontTaxRespCode;
        private String upfrontTaxStateCode;
        private Decimal upfrontTaxStateAmt;
        private String taxCode;
        private Decimal upfrontTaxTCityAmt;
        private Decimal upfrontTaxTCntyAmt;
        private String beginDeprDate;
        private String bonusdepr;
        private Decimal operLeaseBasis;
        private integer operDeprLife;
        private String operDeprMethod;
        private Decimal salvageValue;
        private String upfrontTaxZipCode;
        private String CustomerRef;
        private String DeptLocation;
        private Decimal DealerResidual;
        
        public List<AUMT> meterTypes;
    
        public String getAssetUser3Alphanum1() {
            return assetUser3Alphanum1;
        }
    
        public void setAssetUser3Alphanum1(String assetUser3Alphanum1) {
            this.assetUser3Alphanum1 = assetUser3Alphanum1;
        }
    
        public String getAssetUser3Table1() {
            return assetUser3Table1;
        }
    
        public void setAssetUser3Table1(String assetUser3Table1) {
            this.assetUser3Table1 = assetUser3Table1;
        }
    
        public List<String> getAssetUserDef() {
            return assetUserDef;
        }
    
        public void setAssetUserDef(List<String> assetUserDef) {
            this.assetUserDef = assetUserDef;
        }
    
        public String getAssetUserField3() {
            return assetUserField3;
        }
    
        public void setAssetUserField3(String assetUserField3) {
            this.assetUserField3 = assetUserField3;
        }
    
        public String getAssetUserField4() {
            return assetUserField4;
        }
    
        public void setAssetUserField4(String assetUserField4) {
            this.assetUserField4 = assetUserField4;
        }
    
        public String getAssetUserField5() {
            return assetUserField5;
        }
    
        public void setAssetUserField5(String assetUserField5) {
            this.assetUserField5 = assetUserField5;
        }
    
        public String getAssetUserField6() {
            return assetUserField6;
        }
    
        public void setAssetUserField6(String assetUserField6) {
            this.assetUserField6 = assetUserField6;
        }
    
        public String getAssetUserField7() {
            return assetUserField7;
        }
    
        public void setAssetUserField7(String assetUserField7) {
            this.assetUserField7 = assetUserField7;
        }
    
        public String getLcCityTaxCode() {
            return lcCityTaxCode;
        }
    
        public void setLcCityTaxCode(String lcCityTaxCode) {
            this.lcCityTaxCode = lcCityTaxCode;
        }
    
        public String getLcCntyTaxCode() {
            return lcCntyTaxCode;
        }
    
        public void setLcCntyTaxCode(String lcCntyTaxCode) {
            this.lcCntyTaxCode = lcCntyTaxCode;
        }
    
        public String getLcStateTaxCd() {
            return lcStateTaxCd;
        }
    
        public void setLcStateTaxCd(String lcStateTaxCd) {
            this.lcStateTaxCd = lcStateTaxCd;
        }
    
        public String getMiscCityTaxCd() {
            return miscCityTaxCd;
        }
    
        public void setMiscCityTaxCd(String miscCityTaxCd) {
            this.miscCityTaxCd = miscCityTaxCd;
        }
    
        public String getMiscCntyTaxCd() {
            return miscCntyTaxCd;
        }
    
        public void setMiscCntyTaxCd(String miscCntyTaxCd) {
            this.miscCntyTaxCd = miscCntyTaxCd;
        }
    
        public String getMiscStTaxCode() {
            return miscStTaxCode;
        }
    
        public void setMiscStTaxCode(String miscStTaxCode) {
            this.miscStTaxCode = miscStTaxCode;
        }
    
        public String getYearofManuf() {
            return yearofManuf;
        }
    
        public void setYearofManuf(String yearofManuf) {
            this.yearofManuf = yearofManuf;
        }
    
        public Decimal getOriginalCost() {
            return originalCost;
        }
    
        public void setOriginalCost(Decimal originalCost) {
            this.originalCost = originalCost;
        }
    
        public Decimal getSalesProfit() {
            return salesProfit;
        }
    
        public void setSalesProfit(Decimal salesProfit) {
            this.salesProfit = salesProfit;
        }
    
        public String getVehicleMake() {
            return vehicleMake;
        }
    
        public void setVehicleMake(String vehicleMake) {
            this.vehicleMake = vehicleMake;
        }
    
        public Decimal getAceDeprBasis() {
            return aceDeprBasis;
        }
    
        public void setAceDeprBasis(Decimal aceDeprBasis) {
            this.aceDeprBasis = aceDeprBasis;
        }
    
        public String getDetailedAssetDescription() {
            return detailedAssetDescription;
        }
    
        public void setDetailedAssetDescription(String detailedAssetDescription) {
            this.detailedAssetDescription = detailedAssetDescription;
        }
    
        public integer getAdsClassLIM() {
            return adsClassLIM;
        }
    
        public void setAdsClassLIM(integer adsClassLIM) {
            this.adsClassLIM = adsClassLIM;
        }
    
        public Decimal getAmtDeprBasis() {
            return amtDeprBasis;
        }
    
        public void setAmtDeprBasis(Decimal amtDeprBasis) {
            this.amtDeprBasis = amtDeprBasis;
        }
    
        public Decimal getRecourseAmt() {
            return recourseAmt;
        }
    
        public void setRecourseAmt(Decimal recourseAmt) {
            this.recourseAmt = recourseAmt;
        }
    
        public String getRecourseCode() {
            return recourseCode;
        }
    
        public void setRecourseCode(String recourseCode) {
            this.recourseCode = recourseCode;
        }
    
        public String getRecourseComments() {
            return recourseComments;
        }
    
        public void setRecourseComments(String recourseComments) {
            this.recourseComments = recourseComments;
        }
    
        public Decimal getRecoursePct() {
            return recoursePct;
        }
    
        public void setRecoursePct(Decimal recoursePct) {
            this.recoursePct = recoursePct;
        }
    
        public integer getRecourseTerm() {
            return recourseTerm;
        }
    
        public void setRecourseTerm(integer recourseTerm) {
            this.recourseTerm = recourseTerm;
        }
    
        public String getAssetStatus() {
            return assetStatus;
        }
    
        public void setAssetStatus(String assetStatus) {
            this.assetStatus = assetStatus;
        }
    
        public List<Decimal> getRate() {
            return rate;
        }
    
        public void setRate(List<Decimal> rate) {
            this.rate = rate;
        }
    
        public boolean getEstReadingsAllowed() {
            return estReadingsAllowed;
        }
    
        public void setEstReadingsAllowed(boolean estReadingsAllowed) {
            this.estReadingsAllowed = estReadingsAllowed;
        }
    
        public List<String> getBillingCycle() {
            return billingCycle;
        }
    
        public void setBillingCycle(List<String> billingCycle) {
            this.billingCycle = billingCycle;
        }
    
        public List<String> getContractedCycle() {
            return contractedCycle;
        }
    
        public void setContractedCycle(List<String> contractedCycle) {
            this.contractedCycle = contractedCycle;
        }
    
        public List<String> getContractedThruDate() {
            return contractedThruDate;
        }
    
        public void setContractedThruDate(List<String> contractedThruDate) {
            this.contractedThruDate = contractedThruDate;
        }
    
        public List<Decimal> getNumUnitsUsedCTD() {
            return numUnitsUsedCTD;
        }
    
        public void setNumUnitsUsedCTD(List<Decimal> numUnitsUsedCTD) {
            this.numUnitsUsedCTD = numUnitsUsedCTD;
        }
    
        public List<String> getDlrInvNum() {
            return dlrInvNum;
        }
    
        public void setDlrInvNum(List<String> dlrInvNum) {
            this.dlrInvNum = dlrInvNum;
        }
    
        public List<Date> getDlrReadDt() {
            return dlrReadDt;
        }
    
        public void setDlrReadDt(List<Date> dlrReadDt) {
            this.dlrReadDt = dlrReadDt;
        }
    
        public List<Date> getReadingDates() {
            return readingDates;
        }
    
        public void setReadingDates(List<Date> readingDates) {
            this.readingDates = readingDates;
        }
    
        public List<String> getReadingMethods() {
            return readingMethods;
        }
    
        public void setReadingMethods(List<String> readingMethods) {
            this.readingMethods = readingMethods;
        }
    
        public List<Decimal> getReadingsinUnits() {
            return readingsinUnits;
        }
    
        public void setReadingsinUnits(List<Decimal> readingsinUnits) {
            this.readingsinUnits = readingsinUnits;
        }
    
        public List<Date> getServiceDates() {
            return serviceDates;
        }
    
        public void setServiceDates(List<Date> serviceDates) {
            this.serviceDates = serviceDates;
        }
    
        public List<Decimal> getNumServiceUnitsMade() {
            return numServiceUnitsMade;
        }
    
        public void setNumServiceUnitsMade(List<Decimal> numServiceUnitsMade) {
            this.numServiceUnitsMade = numServiceUnitsMade;
        }
    
        public List<Decimal> getUsageQuantity() {
            return usageQuantity;
        }
    
        public void setUsageQuantity(List<Decimal> usageQuantity) {
            this.usageQuantity = usageQuantity;
        }
    
        public String getAssetUserTable1() {
            return assetUserTable1;
        }
    
        public void setAssetUserTable1(String assetUserTable1) {
            this.assetUserTable1 = assetUserTable1;
        }
    
        public Date getFedBeginDeprDate() {
            return fedBeginDeprDate;
        }
    
        public void setFedBeginDeprDate(Date fedBeginDeprDate) {
            this.fedBeginDeprDate = fedBeginDeprDate;
        }
    
        public boolean getCalcACEDepr() {
            return calcACEDepr;
        }
    
        public void setCalcACEDepr(boolean calcACEDepr) {
            this.calcACEDepr = calcACEDepr;
        }
    
        public boolean getCalcAMTDepr() {
            return calcAMTDepr;
        }
    
        public void setCalcAMTDepr(boolean calcAMTDepr) {
            this.calcAMTDepr = calcAMTDepr;
        }
    
        public Decimal getTaxDeprBasis() {
            return taxDeprBasis;
        }
    
        public void setTaxDeprBasis(Decimal taxDeprBasis) {
            this.taxDeprBasis = taxDeprBasis;
        }
    
        public String getCityCode() {
            return cityCode;
        }
    
        public void setCityCode(String cityCode) {
            this.cityCode = cityCode;
        }
    
        public String getCityTaxCode() {
            return cityTaxCode;
        }
    
        public void setCityTaxCode(String cityTaxCode) {
            this.cityTaxCode = cityTaxCode;
        }
    
        public Decimal getCityTaxPct() {
            return cityTaxPct;
        }
    
        public void setCityTaxPct(Decimal cityTaxPct) {
            this.cityTaxPct = cityTaxPct;
        }
    
        public String getCountyCode() {
            return countyCode;
        }
    
        public void setCountyCode(String countyCode) {
            this.countyCode = countyCode;
        }
    
        public String getCountyTaxCode() {
            return countyTaxCode;
        }
    
        public void setCountyTaxCode(String countyTaxCode) {
            this.countyTaxCode = countyTaxCode;
        }
    
        public Decimal getCountyTaxPct() {
            return countyTaxPct;
        }
    
        public void setCountyTaxPct(Decimal countyTaxPct) {
            this.countyTaxPct = countyTaxPct;
        }
    
        public String getAssetAddr1() {
            return assetAddr1;
        }
    
        public void setAssetAddr1(String assetAddr1) {
            this.assetAddr1 = assetAddr1;
        }
    
        public String getAssetAddr2() {
            return assetAddr2;
        }
    
        public void setAssetAddr2(String assetAddr2) {
            this.assetAddr2 = assetAddr2;
        }
    
        public String getAssetCity() {
            return assetCity;
        }
    
        public void setAssetCity(String assetCity) {
            this.assetCity = assetCity;
        }
    
        public String getAssetCode() {
            return assetCode;
        }
    
        public void setAssetCode(String assetCode) {
            this.assetCode = assetCode;
        }
    
        public Decimal getEquipmentCost() {
            return equipmentCost;
        }
    
        public void setEquipmentCost(Decimal equipmentCost) {
            this.equipmentCost = equipmentCost;
        }
    
        public String getAssetDesc() {
            return assetDesc;
        }
    
        public void setAssetDesc(String assetDesc) {
            this.assetDesc = assetDesc;
        }
    
        public Decimal getDiscount() {
            return discount;
        }
    
        public void setDiscount(Decimal discount) {
            this.discount = discount;
        }
    
        public Decimal getListPrice() {
            return listPrice;
        }
    
        public void setListPrice(Decimal listPrice) {
            this.listPrice = listPrice;
        }
    
        public String getAssetState() {
            return assetState;
        }
    
        public void setAssetState(String assetState) {
            this.assetState = assetState;
        }
    
        public String getAssetZip() {
            return assetZip;
        }
    
        public void setAssetZip(String assetZip) {
            this.assetZip = assetZip;
        }
    
        public Decimal getFedCalcBasis() {
            return fedCalcBasis;
        }
    
        public void setFedCalcBasis(Decimal fedCalcBasis) {
            this.fedCalcBasis = fedCalcBasis;
        }
    
        public integer getFedConvention() {
            return fedConvention;
        }
    
        public void setFedConvention(integer fedConvention) {
            this.fedConvention = fedConvention;
        }
    
        public Decimal getDeprPercentages() {
            return deprPercentages;
        }
    
        public void setDeprPercentages(Decimal deprPercentages) {
            this.deprPercentages = deprPercentages;
        }
    
        public integer getFederalLife() {
            return federalLife;
        }
    
        public void setFederalLife(integer federalLife) {
            this.federalLife = federalLife;
        }
        
        public integer getManagerResidual() {
            return ManagerResidual;
        }
        public void setManagerResidual(integer mr) {
            this.ManagerResidual = mr;
        }
    
        public String getManufacturer() {
            return manufacturer;
        }
    
        public void setManufacturer(String manufacturer) {
            this.manufacturer = manufacturer;
        }
    
        public String getModel() {
            return model;
        }
    
        public void setModel(String model) {
            this.model = model;
        }
    
        public Decimal getMaxCityPerInv() {
            return maxCityPerInv;
        }
    
        public void setMaxCityPerInv(Decimal maxCityPerInv) {
            this.maxCityPerInv = maxCityPerInv;
        }
    
        public Decimal getMaxCityTax() {
            return maxCityTax;
        }
    
        public void setMaxCityTax(Decimal maxCityTax) {
            this.maxCityTax = maxCityTax;
        }
    
        public Decimal getMaxCntyPerInv() {
            return maxCntyPerInv;
        }
    
        public void setMaxCntyPerInv(Decimal maxCntyPerInv) {
            this.maxCntyPerInv = maxCntyPerInv;
        }
    
        public Decimal getMaxCntyTax() {
            return maxCntyTax;
        }
    
        public void setMaxCntyTax(Decimal maxCntyTax) {
            this.maxCntyTax = maxCntyTax;
        }
    
        public Decimal getMaxStateTax() {
            return maxStateTax;
        }
    
        public void setMaxStateTax(Decimal maxStateTax) {
            this.maxStateTax = maxStateTax;
        }
    
        public String getNewUsedCode() {
            return newUsedCode;
        }
    
        public void setNewUsedCode(String newUsedCode) {
            this.newUsedCode = newUsedCode;
        }
    
        public String getPropTaxStatus() {
            return propTaxStatus;
        }
    
        public void setPropTaxStatus(String propTaxStatus) {
            this.propTaxStatus = propTaxStatus;
        }
    
        public String getPurchaseOption() {
            return purchaseOption;
        }
    
        public void setPurchaseOption(String purchaseOption) {
            this.purchaseOption = purchaseOption;
        }
    
        public String getRenewalOption() {
            return renewalOption;
        }
    
        public void setRenewalOption(String renewalOption) {
            this.renewalOption = renewalOption;
        }
    
        public integer getQuantity() {
            return quantity;
        }
    
        public void setQuantity(integer quantity) {
            this.quantity = quantity;
        }
    
        public Decimal getResidualPercent() {
            return residualPercent;
        }
    
        public void setResidualPercent(Decimal residualPercent) {
            this.residualPercent = residualPercent;
        }
    
        public Decimal getResidualAmount() {
            return residualAmount;
        }
    
        public void setResidualAmount(Decimal residualAmount) {
            this.residualAmount = residualAmount;
        }
    
        public String getFederalMethod() {
            return federalMethod;
        }
    
        public void setFederalMethod(String federalMethod) {
            this.federalMethod = federalMethod;
        }
    
        public String getSerialNumber() {
            return serialNumber;
        }
    
        public void setSerialNumber(String serialNumber) {
            this.serialNumber = serialNumber;
        }
    
        public String getStateBeginDeprDate() {
            return stateBeginDeprDate;
        }
    
        public void setStateBeginDeprDate(String stateBeginDeprDate) {
            this.stateBeginDeprDate = stateBeginDeprDate;
        }
    
        public Decimal getStateDeprBasis() {
            return stateDeprBasis;
        }
    
        public void setStateDeprBasis(Decimal stateDeprBasis) {
            this.stateDeprBasis = stateDeprBasis;
        }
    
        public integer getStateLife() {
            return stateLife;
        }
    
        public void setStateLife(integer stateLife) {
            this.stateLife = stateLife;
        }
    
        public integer getStateMethod() {
            return stateMethod;
        }
    
        public void setStateMethod(integer stateMethod) {
            this.stateMethod = stateMethod;
        }
    
        public String getStateCode() {
            return stateCode;
        }
    
        public void setStateCode(String stateCode) {
            this.stateCode = stateCode;
        }
    
        public String getStateTaxCode() {
            return stateTaxCode;
        }
    
        public void setStateTaxCode(String stateTaxCode) {
            this.stateTaxCode = stateTaxCode;
        }
    
        public Decimal getStateTaxPct() {
            return stateTaxPct;
        }
    
        public void setStateTaxPct(Decimal stateTaxPct) {
            this.stateTaxPct = stateTaxPct;
        }
    
        public Decimal getCityTransTaxPct() {
            return cityTransTaxPct;
        }
    
        public void setCityTransTaxPct(Decimal cityTransTaxPct) {
            this.cityTransTaxPct = cityTransTaxPct;
        }
    
        public Decimal getCntyTransTaxPct() {
            return cntyTransTaxPct;
        }
    
        public void setCntyTransTaxPct(Decimal cntyTransTaxPct) {
            this.cntyTransTaxPct = cntyTransTaxPct;
        }
    
        public Decimal getUpfrontTaxBasis() {
            return upfrontTaxBasis;
        }
    
        public void setUpfrontTaxBasis(Decimal upfrontTaxBasis) {
            this.upfrontTaxBasis = upfrontTaxBasis;
        }
    
        public String getUpfrontTaxCityCode() {
            return upfrontTaxCityCode;
        }
    
        public void setUpfrontTaxCityCode(String upfrontTaxCityCode) {
            this.upfrontTaxCityCode = upfrontTaxCityCode;
        }
    
        public Decimal getUpfrontTaxCityAmt() {
            return upfrontTaxCityAmt;
        }
    
        public void setUpfrontTaxCityAmt(Decimal upfrontTaxCityAmt) {
            this.upfrontTaxCityAmt = upfrontTaxCityAmt;
        }
    
        public String getUpfrontTaxCntyCode() {
            return upfrontTaxCntyCode;
        }
    
        public void setUpfrontTaxCntyCode(String upfrontTaxCntyCode) {
            this.upfrontTaxCntyCode = upfrontTaxCntyCode;
        }
    
        public Decimal getUpfrontTaxCntyAmt() {
            return upfrontTaxCntyAmt;
        }
    
        public void setUpfrontTaxCntyAmt(Decimal upfrontTaxCntyAmt) {
            this.upfrontTaxCntyAmt = upfrontTaxCntyAmt;
        }
    
        public boolean getUpfrontTaxFinanced() {
            return upfrontTaxFinanced;
        }
    
        public void setUpfrontTaxFinanced(boolean upfrontTaxFinanced) {
            this.upfrontTaxFinanced = upfrontTaxFinanced;
        }
    
        public String getUpfrontTaxRespCode() {
            return upfrontTaxRespCode;
        }
    
        public void setUpfrontTaxRespCode(String upfrontTaxRespCode) {
            this.upfrontTaxRespCode = upfrontTaxRespCode;
        }
    
        public String getUpfrontTaxStateCode() {
            return upfrontTaxStateCode;
        }
    
        public void setUpfrontTaxStateCode(String upfrontTaxStateCode) {
            this.upfrontTaxStateCode = upfrontTaxStateCode;
        }
    
        public Decimal getUpfrontTaxStateAmt() {
            return upfrontTaxStateAmt;
        }
    
        public void setUpfrontTaxStateAmt(Decimal upfrontTaxStateAmt) {
            this.upfrontTaxStateAmt = upfrontTaxStateAmt;
        }
    
        public String getTaxCode() {
            return taxCode;
        }
    
        public void setTaxCode(String taxCode) {
            this.taxCode = taxCode;
        }
    
        public Decimal getUpfrontTaxTCityAmt() {
            return upfrontTaxTCityAmt;
        }
    
        public void setUpfrontTaxTCityAmt(Decimal upfrontTaxTCityAmt) {
            this.upfrontTaxTCityAmt = upfrontTaxTCityAmt;
        }
    
        public Decimal getUpfrontTaxTCntyAmt() {
            return upfrontTaxTCntyAmt;
        }
    
        public void setUpfrontTaxTCntyAmt(Decimal upfrontTaxTCntyAmt) {
            this.upfrontTaxTCntyAmt = upfrontTaxTCntyAmt;
        }
    
        public String getBeginDeprDate() {
            return beginDeprDate;
        }
    
        public void setBeginDeprDate(String beginDeprDate) {
            this.beginDeprDate = beginDeprDate;
        }
        
        public String getbonusdepr() {
            return bonusdepr;
        }
    
        public void setbonusdepr(String bonusdpr) {
            this.bonusdepr = bonusdpr;
        }
    
        public Decimal getOperLeaseBasis() {
            return operLeaseBasis;
        }
    
        public void setOperLeaseBasis(Decimal operLeaseBasis) {
            this.operLeaseBasis = operLeaseBasis;
        }
    
        public integer getOperDeprLife() {
            return operDeprLife;
        }
    
        public void setOperDeprLife(integer operDeprLife) {
            this.operDeprLife = operDeprLife;
        }
    
        public String getOperDeprMethod() {
            return operDeprMethod;
        }
    
        public void setOperDeprMethod(String operDeprMethod) {
            this.operDeprMethod = operDeprMethod;
        }
    
        public Decimal getSalvageValue() {
            return salvageValue;
        }
    
        public void setSalvageValue(Decimal salvageValue) {
            this.salvageValue = salvageValue;
        }
    
        public String getUpfrontTaxZipCode() {
            return upfrontTaxZipCode;
        }
    
        public void setUpfrontTaxZipCode(String upfrontTaxZipCode) {
            this.upfrontTaxZipCode = upfrontTaxZipCode;
        }
        
        public String getCustomerRef() {
            return CustomerRef;
        }
    
        public void setCustomerRef(String CustomerRef) {
            this.CustomerRef = CustomerRef;
        }
        
        public String getDeptLocation() {
            return DeptLocation;
        }
    
        public void setDeptLocation(String DeptLocation) {
            this.DeptLocation = DeptLocation;
        }
        
        public Decimal getDealerResidual() {
            return DealerResidual;
        }
    
        public void setDealerResidual(Decimal DResidual) {
            this.DealerResidual = DResidual;
        }
 
    }
    
    public class Dealer {
        public String toUCIString() {
            return 'DE'
                    + TC_UCIStringHelper.value(dealer)
                    + TC_UCIStringHelper.value(dealerDesc)
                    + TC_UCIStringHelper.value(dealerFundDate)
                    + TC_UCIStringHelper.value(dealerInvoiceNo)
                    + TC_UCIStringHelper.value(dealerListPrice)
                    + TC_UCIStringHelper.value(specialGLcode);
        }
        
        private String dealer;
        private String dealerDesc;
        private Date dealerFundDate;
        private String dealerInvoiceNo;
        private Decimal dealerListPrice;
        private String specialGLcode;
    
        public String getDealer() {
            return dealer;
        }
    
        public void setDealer(String dealer) {
            this.dealer = dealer;
        }
    
        public String getDealerDesc() {
            return dealerDesc;
        }
    
        public void setDealerDesc(String dealerDesc) {
            this.dealerDesc = dealerDesc;
        }
    
        public Date getDealerFundDate() {
            return dealerFundDate;
        }
    
        public void setDealerFundDate(Date dealerFundDate) {
            this.dealerFundDate = dealerFundDate;
        }
    
        public String getDealerInvoiceNo() {
            return dealerInvoiceNo;
        }
    
        public void setDealerInvoiceNo(String dealerInvoiceNo) {
            this.dealerInvoiceNo = dealerInvoiceNo;
        }
    
        public Decimal getDealerListPrice() {
            return dealerListPrice;
        }
    
        public void setDealerListPrice(Decimal dealerListPrice) {
            this.dealerListPrice = dealerListPrice;
        }
    
        public String getSpecialGLcode() {
            return specialGLcode;
        }
    
        public void setSpecialGLcode(String specialGLcode) {
            this.specialGLcode = specialGLcode;
        }
    }
    
   // MeterType changes
    public class AUMT {
        
        public String toUCIString() {
            return 'AUMT'
            + TC_UCIStringHelper.value(meterType)
            + TC_UCIStringHelper.value(meterBillingCycle)
            + TC_UCIStringHelper.value(meterContrThruDate)
            + TC_UCIStringHelper.value(meterCTDUnits)
            + TC_UCIStringHelper.value(meterDateEntered)
            + TC_UCIStringHelper.value(meterMinChargeDealer)
            + TC_UCIStringHelper.value(meterMinChargeDealerPer)
            + TC_UCIStringHelper.value(meterMinChargebycode)
            + TC_UCIStringHelper.value(meterMinChargeAmt)
            + TC_UCIStringHelper.value(meterModel)
            + TC_UCIStringHelper.value(meterOverageCycle)
            + TC_UCIStringHelper.value(meterReadingCycle)
            + TC_UCIStringHelper.value(meterReadingComments)
            + TC_UCIStringHelper.value(meterReadingDates)
            + TC_UCIStringHelper.value(meterReadingMethods)
            + TC_UCIStringHelper.value(meterReading)
            + TC_UCIStringHelper.value(meterSerialNumber)
            + TC_UCIStringHelper.value(meterserviceDates)
            + TC_UCIStringHelper.value(meterserviceUnits)    
            + TC_UCIStringHelper.value(meterUsageAdj);         
        }
        
        private string meterType;
        private List<string> meterBillingCycle;
        private string meterContrThruDate;
        private Decimal meterCTDUnits;
        private string meterDateEntered;
        private string meterMinChargeDealer;
        private string meterMinChargeDealerPer;
        private string meterMinChargebycode;
        private string meterMinChargeAmt;
        private string meterModel;
        private List<string> meterOverageCycle;
        private List<string> meterReadingCycle;
        private string meterReadingComments;
        private Date meterReadingDates;
        private String meterReadingMethods;
        private Decimal meterReading;
        private string meterSerialNumber;
        private string meterserviceDates;
        private string meterserviceUnits;
        private string meterUsageAdj;
        public AUMTRCls AUMTR; 
        
        public void setmeterType(String meterTyp) {
            this.meterType = meterTyp;
        }
    
        public String getmeterType() {
            return meterType;
        }
        
        public void setmeterBillingCycle(List<String> BillingCycle) {
            this.meterBillingCycle = BillingCycle;
        }
    
        public List<String> getmeterBillingCycle() {
            return meterBillingCycle;
        }
        
        public void setmeterContrThruDate(String ContrThruDate) {
            this.meterContrThruDate = ContrThruDate;
        }
    
        public String getmeterContrThruDate() {
            return meterContrThruDate;
        }
        
        public void setmeterCTDUnits(Decimal CTDUnits) {
            this.meterCTDUnits = CTDUnits;
        }
    
        public Decimal getmeterCTDUnits() {
            return meterCTDUnits;
        }
        
        public void setmeterDateEntered(String DateEntered) {
            this.meterDateEntered = DateEntered;
        }
    
        public String getmeterDateEntered() {
            return meterDateEntered;
        }
        
        public void setmeterMinChargeDealer(String MinChargeDealer) {
            this.meterMinChargeDealer = MinChargeDealer;
        }
    
        public String getmeterMinChargeDealer() {
            return meterMinChargeDealer;
        }
        
        public void setmeterMinChargeDealerPer(String MinChargeDealerPer) {
            this.meterMinChargeDealerPer = MinChargeDealerPer;
        }
    
        public String getmeterMinChargeDealerPer() {
            return meterMinChargeDealerPer;
        }
        
        public void setmeterMinChargebycode(String MinChargebycode) {
            this.meterMinChargebycode = MinChargebycode;
        }
    
        public String getmeterMinChargebycode() {
            return meterMinChargebycode;
        }
        
        public void setmeterMinChargeAmt(String MinChargeAmt) {
            this.meterMinChargeAmt = MinChargeAmt;
        }
    
        public String getmeterMinChargeAmt() {
            return meterMinChargeAmt;
        }
        
        public void setmeterModel(String Model) {
            this.meterModel = Model;
        }
    
        public String getmeterModel() {
            return meterModel;
        }
        
        public void setmeterOverageCycle(List<String> OverageCycle) {
            this.meterOverageCycle = OverageCycle;
        }
    
        public List<String> getmeterOverageCycle() {
            return meterOverageCycle;
        }
        
        public void setmeterReadingCycle(List<String> ReadingCycle) {
            this.meterReadingCycle = ReadingCycle;
        }
    
        public List<String> getmeterReadingCycle() {
            return meterReadingCycle;
        }
        
        public void setmeterReadingComments(String ReadingComments) {
            this.meterReadingComments = ReadingComments;
        }
    
        public String getmeterReadingComments() {
            return meterReadingComments;
        }
        
        public void setmeterReadingDates(Date ReadingDates) {
            this.meterReadingDates = ReadingDates;
        }
    
        public Date getmeterReadingDates() {
            return meterReadingDates;
        }
        
        public void setmeterReadingMethods(String ReadingMethods) {
            this.meterReadingMethods = ReadingMethods;
        }
    
        public String getmeterReadingMethods() {
            return meterReadingMethods;
        }
        
        public void setmeterReading(Decimal Reading) {
            this.meterReading = Reading;
        }
    
        public Decimal getmeterReading() {
            return meterReading;
        }
        
        public void setmeterSerialNumber(String SerialNumber) {
            this.meterSerialNumber = SerialNumber;
        }
    
        public String getmeterSerialNumber() {
            return meterSerialNumber;
        }
        
        public void setmeterserviceDates(String serviceDates) {
            this.meterserviceDates = serviceDates;
        }
    
        public String getmeterserviceDates() {
            return meterserviceDates;
        }
        
        public void setmeterserviceUnits(String serviceUnits) {
            this.meterserviceUnits = serviceUnits;
        }
    
        public String getmeterserviceUnits() {
            return meterserviceUnits;
        }
        
        public void setmeterUsageAdj(String UsageAdj) {
            this.meterUsageAdj = UsageAdj;
        }
    
        public String getmeterUsageAdj() {
            return meterUsageAdj;
        }
    }
    
    public class AUMTRCls {
        public String toUCIString() {
            return 'AUMTR'
            + TC_UCIStringHelper.value(AUMTRmeterType)
            + TC_UCIStringHelper.value(meterOverageDealer)
            + TC_UCIStringHelper.value(meterOverageDealerPerc)
            + TC_UCIStringHelper.value(meterOveragePayCode)
            + TC_UCIStringHelper.value(meterOverageRates)    
            + TC_UCIStringHelper.value(meterOverageUnits);
            
        }
        
        private string AUMTRmeterType;
        private string meterOverageDealer;
        private Decimal meterOverageDealerPerc;
        private string meterOveragePayCode;
        private Decimal meterOverageRates;
        private Decimal meterOverageUnits;
        
   
        public void setAUMTRmeterType(String AUMTRType) {
            this.AUMTRmeterType = AUMTRType;
        }
    
        public String getAUMTRmeterType() {
            return AUMTRmeterType;
        }
        
        public void setmeterOverageDealer(String OverageDealer) {
            this.meterOverageDealer = OverageDealer;
        }
    
        public String getmeterOverageDealer() {
            return meterOverageDealer;
        }
        
        public void setmeterOverageDealerPerc(Decimal OverageDealerPerc) {
            this.meterOverageDealerPerc = OverageDealerPerc;
        }
    
        public Decimal getmeterOverageDealerPerc() {
            return meterOverageDealerPerc;
        }
        
        public void setmeterOveragePayCode(String OveragePayCode) {
            this.meterOveragePayCode = OveragePayCode;
        }
    
        public String getmeterOveragePayCode() {
            return meterOveragePayCode;
        }
        
        public void setmeterOverageRates(Decimal OverageRates) {
            this.meterOverageRates = OverageRates;
        }
    
        public Decimal getmeterOverageRates() {
            return meterOverageRates;
        }
        
        public void setmeterOverageUnits(Decimal OverageUnits) {
            this.meterOverageUnits = OverageUnits;
        }
    
        public Decimal getmeterOverageUnits() {
            return meterOverageUnits;
        }
    }
    
    
    public class ContractMiscBillable {
        public String toUCIString() {
            IL10_Flag__c il10Setting = IL10_Flag__c.getValues('GeneralSetting');
            Boolean isIL10 = il10Setting.use_IL10__c; // booking always to IL10 regardless of record
            return 'MB'
                    + TC_UCIStringHelper.value(amountType)
                    + TC_UCIStringHelper.value(futureBill)
                    + TC_UCIStringHelper.value(finalDate)
                    + TC_UCIStringHelper.value(firstDate)
                    + TC_UCIStringHelper.value(incInRent)
                    + TC_UCIStringHelper.value(amount)
                    + TC_UCIStringHelper.value(disp)
                    + TC_UCIStringHelper.value(cycle)
                    + TC_UCIStringHelper.value(cmbDate)
                    + TC_UCIStringHelper.value(cmbDesc)
                    + TC_UCIStringHelper.value(glCode)
                    + TC_UCIStringHelper.value(payable)
                    + (isIL10? TC_UCIStringHelper.value(PassThrough): '')
                    + TC_UCIStringHelper.value(taxable)
                    + TC_UCIStringHelper.value(vendor)
                    + (isIL10? TC_UCIStringHelper.value(PaymentType): '')
                    + (isIL10? TC_UCIStringHelper.value(PassThroughPercentage): '');
        }
        
        private String amountType;
        private boolean futureBill;
        private String finalDate;
        private String firstDate;
        private boolean incInRent;
        private Decimal amount;
        private boolean disp;
        //private String cycle;
        private List<String> cycle;
        private String cmbDate;
        private String cmbDesc;
        private String glCode;
        private integer payable;
        private String PassThrough;
        private boolean taxable;
        private String vendor;
        private String PaymentType;
        private String PassThroughPercentage;
        
    
        public String getAmountType() {
            return amountType;
        }
    
        public void setAmountType(String amountType) {
            this.amountType = amountType;
        }
    
        public boolean getFutureBill() {
            return futureBill;
        }
    
        public void setFutureBill(boolean futureBill) {
            this.futureBill = futureBill;
        }
    
        public String getFinalDate() {
            return finalDate;
        }
    
        public void setFinalDate(String finalDate) {
            this.finalDate = finalDate;
        }
    
        public String getFirstDate() {
            return firstDate;
        }
    
        public void setFirstDate(String firstDate) {
            this.firstDate = firstDate;
        }
    
        public boolean getIncInRent() {
            return incInRent;
        }
    
        public void setIncInRent(boolean incInRent) {
            this.incInRent = incInRent;
        }
    
        public Decimal getAmount() {
            return amount;
        }
    
        public void setAmount(Decimal amount) {
            this.amount = amount;
        }
    
        public boolean getDisp() {
            return disp;
        }
    
        public void setDisp(boolean disp) {
            this.disp = disp;
        }
    
        /*public String getCycle() {
            return cycle;
        }
    
        public void setCycle(String cycle) {
            this.cycle = cycle;
        }*/
        // using deal cycle now
        public void setCycle(List<String> cycle) {
            this.cycle = cycle;
        }
        public List <String> getCycle() {
            return cycle;
        }
    
        public String getCmbDate() {
            return cmbDate;
        }
    
        public void setCmbDate(String cmbDate) {
            this.cmbDate = cmbDate;
        }
    
        public String getCmbDesc() {
            return cmbDesc;
        }
    
        public void setCmbDesc(String cmbDesc) {
            this.cmbDesc = cmbDesc;
        }
    
        public String getGlCode() {
            return glCode;
        }
    
        public void setGlCode(String glCode) {
            this.glCode = glCode;
        }
    
        public integer getPayable() {
            return payable;
        }
    
        public void setPayable(integer payable) {
            this.payable = payable;
        }
        
        public String getPassThrough() {
            return PassThrough;
        }
    
        public void setPassThrough(String pt) {
            this.PassThrough = pt;
        }
    
        public boolean getTaxable() {
            return taxable;
        }
    
        public void setTaxable(boolean taxable) {
            this.taxable = taxable;
        }
    
        public String getVendor() {
            return vendor;
        }
    
        public void setVendor(String vendor) {
            this.vendor = vendor;
        }
        
        public String getPaymentType() {
            return PaymentType;
        }
        
        
        public void setPaymentType(String pt) {
            this.PaymentType = pt;
        }
        
        public String getPassThroughPercentage() {
            return PassThroughPercentage;
        }
    
        public void setPassThroughPercentage(String pt) {
            this.PassThroughPercentage = pt;
        }
    }
    
    public class ContractMiscInvoice {
        IL10_Flag__c il10Setting = IL10_Flag__c.getValues('GeneralSetting');
        Boolean isIL10 = il10Setting.use_IL10__c; // booking always to IL10 regardless of record
        public String toUCIString() {
            return 'MI'
                    + TC_UCIStringHelper.value(incInRent)
                    + TC_UCIStringHelper.value(amount)
                    + TC_UCIStringHelper.value(disp)
                    + TC_UCIStringHelper.value(cmiDate)
                    + TC_UCIStringHelper.value(cmiDesc)
                    + TC_UCIStringHelper.value(glCode)
                    + TC_UCIStringHelper.value(payable)
                    + TC_UCIStringHelper.value(taxable)
                    + TC_UCIStringHelper.value(vendor)
                    + TC_UCIStringHelper.value(InterimPercentage)
                    + (isIL10? TC_UCIStringHelper.value(PassThrough): '')// SAL-6006 Misael Romero
                    /*+ (isIL10? TC_UCIStringHelper.value(PaymentType): '')
                    + (isIL10? TC_UCIStringHelper.value(PassThroughPercentage): '')*/;
        }
        
        private boolean incInRent;
        private Decimal amount;
        private boolean disp;
        private String cmiDate;
        private String cmiDesc;
        private String glCode;
        private integer payable;
        private boolean taxable;
        private String vendor;
        private Decimal InterimPercentage;
        private String PassThrough;
        // private String PaymentType;
        // private String PassThroughPercentage;
    
        public boolean getIncInRent() {
            return incInRent;
        }
    
        public void setIncInRent(boolean incInRent) {
            this.incInRent = incInRent;
        }
    
        public Decimal getAmount() {
            return amount;
        }
    
        public void setAmount(Decimal amount) {
            this.amount = amount;
        }
    
        public boolean getDisp() {
            return disp;
        }
    
        public void setDisp(boolean disp) {
            this.disp = disp;
        }
    
        public String getCmiDate() {
            return cmiDate;
        }
    
        public void setCmiDate(String cmiDate) {
            this.cmiDate = cmiDate;
        }
    
        public String getCmiDesc() {
            return cmiDesc;
        }
    
        public void setCmiDesc(String cmiDesc) {
            this.cmiDesc = cmiDesc;
        }
    
        public String getGlCode() {
            return glCode;
        }
    
        public void setGlCode(String glCode) {
            this.glCode = glCode;
        }
    
        public integer getPayable() {
            return payable;
        }
    
        public void setPayable(integer payable) {
            this.payable = payable;
        }
    
        public boolean getTaxable() {
            return taxable;
        }
    
        public void setTaxable(boolean taxable) {
            this.taxable = taxable;
        }
    
        public String getVendor() {
            return vendor;
        }
    
        public void setVendor(String vendor) {
            this.vendor = vendor;
        }
        
        public Decimal getInterimPercentage() {
            return InterimPercentage;
        }
    
        public void setInterimPercentage(Decimal IP) {
            this.InterimPercentage = IP;
        }
        public String getPassThrough() {// SAL-6006 Misael Romero
            return PassThrough;
        }
        public void setPassThrough(String pt) {
            this.PassThrough = pt;
        }
        // public String getPaymentType() {
        //     return PaymentType;
        // }
        // public void setPaymentType(String pt) {
        //     this.PaymentType = pt;
        // }
        
        // public String getPassThroughPercentage() {
        //     return PassThroughPercentage;
        // }
    
        // public void setPassThroughPercentage(String pt) {
        //     this.PassThroughPercentage = pt;
        // }
    }
    
    
        
}