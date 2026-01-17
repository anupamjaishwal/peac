/*
* @author : sfdcdev, Tamarack Consulting, Inc.
* @date : 02/15/2018
* @description: http://docs.bridgewaretamarack.apiary.io
*
* © Copyright 2003 - 2018 Tamarack Consulting, Inc.  All Rights Reserved.
* 
*/

@isTest
private class TC_BridgewareServiceTest {

    @TestSetup static void setup () {
         // Setup test data
        // Create a unique UserName
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='DataAdmin'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/New_York',
         UserName=uniqueUserName);

        System.runAs(u) {
              // The following code runs as user 'u'
              System.debug('Current User: ' + UserInfo.getUserName());
              System.debug('Current Profile: ' + UserInfo.getProfileId());
          } 
        SL_SCTestData.createBridgeWareSetting();
        
        Account act = new Account ();
        act.Name = 'TestAspire1';
        act.BillingCity = 'Minneapolis';
        act.BillingCountryCode = 'US';
        act.BillingPostalCode = '55401';
        act.BillingStateCode = 'MN';
        act.BillingStreet = '411 Washington Ave N';
        act.Phone = '2225551234';
        act.Business_State__c = 'MN';
        act.Business_Type__C = 'Corporation';
        act.Business_City__c = 'test';
        act.Business_Zip__c = '11111';
        act.Business_Country__c = 'US';
        
        Schema.DescribeSObjectResult d = Schema.SObjectType.Account;
        Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName ();
        act.RecordTypeId = rtMapByName.get ('End User Account').getRecordTypeId ();
        insert act;
        
        Marlin_Configuration__c config = new Marlin_Configuration__c ();
        config.Static_Standard_Asset_Account_Id__c = act.Id;
        insert config;
        // add validation fields: Term, Commencement Date, Invoicing Due Day, Gross Contract, Gross Finance, Invoice Description, Payment Frequency, Billing Cycle, Gross Finance
        // Federal Tax Id, Business Phone, Purchase Options, # of Payments, Payment Amount, Contract Type, Account Business Street, Account Business City, Account Business Zip/Postal Code, Account Business Zip/Postal Code
        Opportunity opp = new Opportunity ();
        opp.accountId = act.Id;
        opp.amount = 1000;
        opp.name = 'Aspire Test Opportunity 1';
        opp.StageName = 'Ready for Booking';
        Date today = Date.today ();
        opp.CloseDate = today;
        opp.Facility_Code__c = '2.03';
        
        SL_SCTestData.createOpportunitiesAndAssets(act.Id, 1, 1);
        
        /* Just added Test.isRunningTest () to exclude validations on test
        // new fields
        opp.Funding_Booking_Loan_Completed_Date__c = today;
        opp.Terms__c = 12;
        opp.Commencement_Date__c = Date.today ();
        opp.Invoicing_Due_Day__c = 5;
        opp.Equipment_Cost__c = 30000;
        opp.Gross_Contract__c = 20000;
        opp.Gross_Finance__c = 10000;
        opp.Invoice_Description__c = 'test';
        opp.Payment_Frequency__c = 'Annually';
        opp.Billing_Cycle__c = 'January';
        opp.Funding_Booking_Lease_Completed_Date__c = Date.today ();
        opp.Tax_ID__c = '111221212';
        opp.Business_Phone__c = '1112221212';
        opp.Purchase_Options__c = 'FMV';
        opp.of_Payments__c = 12;
        opp.Payment_Amount__c = 5000;
        opp.Contract_Type__c = 'Conditional Sales';
        opp.Account_Business_Street__c = 'test';
        opp.Account_Business_City__c = 'test';
        opp.Account_Business_Zip_Postal_Code__c = '11111';*/
        Test.startTest();
        insert opp;
        
        
        
        Approved_Offer__c offer = new Approved_Offer__c ();
        offer.Opportunity__c = opp.Id;
        insert offer;
        
        Loan_Contract__c contract = new Loan_Contract__c ();
        contract.Opportunity__c = opp.Id;
        contract.Name = '500-123456-003';
        insert contract;
        
        opp.Selected_Approved_Offer__c = offer.Id;
        update opp;
        Test.stopTest();
        
        Asset__c a = new Asset__c ();
        a.Opportunity__c = opp.Id;
        a.Equipment_City__c = 'Seattle';
        //Test.startTest ();
        //insert a;
        //Test.stopTest();
        
        
    }
    @isTest static void testBookContractBridgeware() {
        TC_BridgewareService service = new TC_BridgewareServiceImpl ();
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TC_BridgewareBookContractCalloutMockImpl ());
        TC_BridgewareUtility.sendToBridgeware (opp.Id);
        Test.stopTest ();
    }
    
    @isTest static void testBookContractInfoLease() {
        TC_BridgewareService service = new TC_BridgewareServiceImpl ();
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TC_BridgewareCreateCustCalloutMockImpl ());
        TC_BookToInfoLeaseCtrl.bookToInfoLease (opp.Id);
        Test.stopTest ();
    }
    
    @isTest static void testBookContractInfoLease2() {
        TC_BridgewareService service = new TC_BridgewareServiceImpl ();
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TC_BridgewareCreateCustCalloutMockImpl ());
        TC_BookToInfoLeaseCtrl.bookToInfoLease (opp.Id);
        TC_BookToInfoLeaseCtrl.validateSubmissionCriteria(opp.Id);
        TC_BookToInfoLeaseCtrl.updateSentDate (opp.Id);
        TC_BookToInfoLeaseCtrl.sendPartiesToInfoLeaseFromProcess(opp.Id);
        TC_BookToInfoLeaseCtrl.validateSubmissionCriteria(opp.Id);
        try {
            TC_BookToInfoLeaseCtrl.updateSentDate (opp.Id);
        } catch (Exception ex) {
            
        }
        Test.stopTest ();
    }
    
    @isTest static void testBookContract() {
        // Implement test code
        TC_BridgewareService service = new TC_BridgewareServiceImpl ();
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        
        try {
            TC_BookToInfoLeaseCtrl.bookToInfoLease (null);
        }
        catch (Exception e) {
        }
        
        TC_BridgewareBookContractRequestBean bean = new TC_BridgewareBookContractRequestBean ();
        bean.setUciConfig('Marlin Rapport UCI Layout');
        
        List<TC_BridgewareBookContractRequestBean.RelatedParty> relatedParties = new List<TC_BridgewareBookContractRequestBean.RelatedParty>();
        TC_BridgewareBookContractRequestBean.RelatedParty rp = new TC_BridgewareBookContractRequestBean.RelatedParty();
        List<String> contractPointersPrinGuarantorCodes = new List<String>();
        contractPointersPrinGuarantorCodes.add('A');
        contractPointersPrinGuarantorCodes.add('B');
        rp.setContractPointersPrinGuarantorCodes(contractPointersPrinGuarantorCodes);
        List<String> principalGuarantorRecords = new List<String>();
        principalGuarantorRecords.add('1');
        principalGuarantorRecords.add('2');
        rp.setPrincipalGuarantorRecords(principalGuarantorRecords);
        relatedParties.add(rp);
        bean.setRelatedParties(relatedParties);
        
        TC_BridgewareBookContractRequestBean.Contract c = new TC_BridgewareBookContractRequestBean.Contract();
        c.setContractNumber('contractNumber');
        c.setActivationDate(System.Today());
        c.setDailyInterest(2.00);    
        c.setDaysInYear(1);
        List<String> rateVarianceCd = new List<String>();
        rateVarianceCd.add('A');
        rateVarianceCd.add('B');
        c.setRateVarianceCd(rateVarianceCd);
        List<Date> rateVarDate = new List<Date>();
        rateVarDate.add(System.Today());
        rateVarDate.add(System.Today());
        c.setRateVarDate(rateVarDate);
        List<Decimal> rateVariance = new List<Decimal>();
        rateVariance.add(2.00);
        rateVariance.add(3.00);
        c.setRateVariance(rateVariance);
        c.setBaseRateCode('baseRateCode');
        c.setDownPayment(2.00);
        c.setPurchaseOption('purchaseOption');
        List<String> approvingAuthority = new List<String>();
        approvingAuthority.add('A');
        approvingAuthority.add('B');
        c.setApprovingAuthority(approvingAuthority);
        c.setArAddress1('arAddress1');
        c.setArAddress2('arAddress2');
        c.setArAttention('arAttention');
        c.setArCity('arCity');
        c.setArName('arName');
        c.setArState('arState');
        c.setArZip('arZip');
        c.setBankCode('bankCode');
        List<String> contractBillingCycle = new List<String>();
        contractBillingCycle.add('A');
        contractBillingCycle.add('B');
        c.setContractBillingCycle(contractBillingCycle);
        c.setBookingDate(System.Today());       
        c.setBranch('branch');
        c.setBrokerBookMethod('brokerBookMethod');
        c.setBrokerCode('brokerCode');
        c.setBrokerFees(2.00);
        c.setBrokerTaxMethod('brokerTaxMethod');
        c.setContactFaxPhone('contactFaxPhone');
        c.setContractPayment(2.00);
        c.setContractTerm(1);
        c.setCreditAccountingName('creditAccountingName');
        c.setCreditAccountingPhone('creditAccountingPhone');
        c.setCreditApplicationNumber('1');
        c.setCustomerAddress1('customerAddress1');      
        c.setCustomerAddress2('customerAddress2');
        c.setCustomerCity('customerCity');
        c.setCustomerCreditAccountNumber(1);
        c.setDoingBusinessAs('doingBusinessAs');
        c.setCustomerName('customerName');
        c.setCustomerState('customerState');
        c.setCustomerZip('customerZip');
        c.setDealerCode('dealerCode');
        c.setEndingPymtsInAdvance(1);
        c.setGrossEquipmentCost(2.00);
        c.setFedIDSocSec('fedIDSocSec');
        c.setFirstFeeDate(System.Today());
        c.setFirstPaymentAmount(2.00);
        c.setFirstPaymentDate(System.Today());
        c.setGracePeriod(1);
        c.setGrossContract(2.00);
        c.setGrossFinance(2.00);
        c.setIncomeMethod('incomeMethod');
        c.setIncomeStartDate(System.Today());
        c.setInterimRents(2.00);
        c.setLeadInvDays(1);
        c.setInvoiceDueDay(1);
        c.setInvoiceCode('invoiceCode');
        c.setInvoiceDescrip('invoiceDescrip');
        c.setLateChargeExempt(true);
        c.setLateChargeRate(2.00);
        c.setContractType('contractType');
        c.setLessor(1);
        c.setMinLateCharge(2.00);
        List<Integer> marketingRepPcts = new List<Integer>();
        marketingRepPcts.add(1);
        marketingRepPcts.add(2);
        c.setMarketingRepPcts(marketingRepPcts);
        List<String> mrktngRepRegion = new List<String>();
        mrktngRepRegion.add('A');
        mrktngRepRegion.add('B');
        c.setMrktngRepRegion(mrktngRepRegion);
        List<String> marketingRep = new List<String>();
        marketingRep.add('A');
        marketingRep.add('B');
        c.setMarketingRep(marketingRep);
        c.setMunicipalLease(true);
        c.setContactEmail('contactEmail');
        c.setNumberOfUnits(1);
        c.setOffice('office');
        c.setProductLine('productLine');
        c.setProgramType('programType');
        c.setPromotion('promotion');
        c.setPurchaseOrderNumber('purchaseOrderNumber');
        c.setPaymentOption('paymentOption');
        c.setPaymentsInAdvance(2.00);
        c.setPymtsInArrears(true);
        c.setPymtsUpFront(1);
        c.setQuoteBuyout('quoteBuyout');
        c.setRegion('region');
        c.setOutOfBalance(true);
        c.setRemitToCode('remitToCode');
        c.setResidual(2.00);
        c.setResidualCode('residualCode');
        c.setRequiredSignature('requiredSignature');
        c.setReqPhone('reqPhone');
        c.setSaleleasebackCode(true);
        c.setSecurityDeposit(2.00);
        c.setAcctNumber('acctNumber');
        c.setAcctType('acctType');
        c.setBankNumber('bankNumber');
        c.setUserAlphaField10('userAlphaField10');
        c.setUserAlphaField7(false);
        c.setUserAlphaField8('userAlphaField8');
        c.setUserAlphaField3('userAlphaField3');
        c.setUserComments('userComments');
        c.setUserTable1('userTable1');
        c.setUserAmt1(2.00);
        c.setUserCode('userCode');
        c.setUseTaxResponsibility('useTaxResponsibility');
        List<Integer> variablePaymentsDates = new List<Integer>();
        variablePaymentsDates.add(1);
        variablePaymentsDates.add(2);
        c.setVariablePaymentsDates(variablePaymentsDates);
        c.setVariablePymtCode(true);
        List<Decimal> variablePaymentAmounts = new List<Decimal>();
        variablePaymentAmounts.add(2.00);
        variablePaymentAmounts.add(3.00);
        c.setVariablePaymentAmounts(variablePaymentAmounts);
        bean.setContract(c);
        
        List<TC_BridgewareBookContractRequestBean.ContractBlendedIncome> contractBlendedIncomes = new List<TC_BridgewareBookContractRequestBean.ContractBlendedIncome>();
        TC_BridgewareBookContractRequestBean.ContractBlendedIncome cbi = new TC_BridgewareBookContractRequestBean.ContractBlendedIncome();
        cbi.setIncludeInQuote(true);
        cbi.setAmount(2.00);
        cbi.setBeginDate(System.Today());
        cbi.setBookingDate(System.Today());
        cbi.setCalculatedRate(2.00);
        cbi.setCode('code');
        cbi.setDealerManfCode('dealerManfCode');
        cbi.setIncContRate(true);
        cbi.setIncomeMethod('incomeMethod');
        cbi.setTaxCalculationMethod('taxCalculationMethod');
        cbi.setTerm(1);
        cbi.setTiming('timing');
        contractBlendedIncomes.add(cbi);
        bean.setContractBlendedIncomes(contractBlendedIncomes);
        
        List<TC_BridgewareBookContractRequestBean.Asset> assets = new List<TC_BridgewareBookContractRequestBean.Asset>();
        TC_BridgewareBookContractRequestBean.Asset a = new TC_BridgewareBookContractRequestBean.Asset();
        a.setAssetUser3Alphanum1('assetUser3Alphanum1');
        a.setAssetUser3Table1('assetUser3Table1');
        List<String> assetUserDef = new List<String>();
        assetUserDef.add('A');
        assetUserDef.add('B');
        a.setAssetUserDef(assetUserDef);
        a.setAssetUserField3('assetUserField3');
        a.setAssetUserField4('assetUserField4');
        a.setAssetUserField5('assetUserField5');
        a.setAssetUserField6('assetUserField6');
        a.setAssetUserField7('assetUserField7');
        a.setLcCityTaxCode('lcCityTaxCode');
        a.setLcCntyTaxCode('lcCntyTaxCode');
        a.setLcStateTaxCd('lcStateTaxCd');
        a.setMiscCityTaxCd('miscCityTaxCd');
        a.setMiscCntyTaxCd('miscCntyTaxCd');
        a.setMiscStTaxCode('miscStTaxCode');
        a.setYearofManuf('yearofManuf');
        a.setOriginalCost(2.00);
        a.setSalesProfit(2.00);
        a.setVehicleMake('vehicleMake') ;
        a.setAceDeprBasis(2.00);
        a.setDetailedAssetDescription('detailedAssetDescription');
        a.setAdsClassLIM(1);
        a.setAmtDeprBasis(2.00);
        a.setRecourseAmt(2.00);
        a.setRecourseCode('recourseCode');
        a.setRecourseComments('recourseComments');
        a.setRecoursePct(2.00);
        a.setRecourseTerm(1);
        a.setAssetStatus('assetStatus');
        List<Decimal> rate = new List<Decimal>();
        rate.add(2.00);
        rate.add(3.00);
        List<String> billingCycle = new List<String>();
        billingCycle.add('A');
        billingCycle.add('B');
        List<String> contractedCycle = new List<String>();
        contractedCycle.add('A');
        contractedCycle.add('B');
        List<String> contractedThruDate = new List<String>();
        contractedThruDate.add('12/2016');
        contractedThruDate.add('12/2016');
        List<Decimal> numUnitsUsedCTD = new List<Decimal>();
        numUnitsUsedCTD.add(2.00);
        numUnitsUsedCTD.add(3.00);
        List<String> dlrInvNum = new List<String>();
        dlrInvNum.add('A');
        dlrInvNum.add('B');
        List<Date> dlrReadDt = new List<Date>();
        dlrReadDt.add(System.Today());
        dlrReadDt.add(System.Today());
        List<Date> readingDates = new List<Date>();
        readingDates.add(System.Today());
        readingDates.add(System.Today());
        List<String> readingMethods = new List<String>();
        readingMethods.add('A');
        readingMethods.add('B');
        List<Decimal> readingsinUnits = new List<Decimal>();
        readingsinUnits.add(2.00);
        readingsinUnits.add(3.00);
        List<Date> serviceDates = new List<Date>();
        serviceDates.add(System.Today());
        serviceDates.add(System.Today());
        List<Decimal> numServiceUnitsMade = new List<Decimal>();
        numServiceUnitsMade.add(2.00);
        numServiceUnitsMade.add(3.00);
        List<Decimal> usageQuantity = new List<Decimal>();
        usageQuantity.add(2.00);
        usageQuantity.add(3.00);
        a.setAssetUserTable1('assetUserTable1');
        a.setFedBeginDeprDate(System.Today());
        a.setCalcACEDepr(true);
        a.setCalcAMTDepr(true);
        a.setTaxDeprBasis(2.00);
        a.setCityCode('cityCode');
        a.setCityTaxCode('cityTaxCode');
        a.setCityTaxPct(2.00);
        a.setCountyCode('countyCode');
        a.setCountyTaxCode('countyTaxCode');
        a.setCountyTaxPct(2.00);
        a.setAssetAddr1('assetAddr1');
        a.setAssetAddr2('assetAddr2');
        a.setAssetCity('assetCity');
        a.setAssetCode('assetCode');
        a.setEquipmentCost(2.00);
        a.setAssetDesc('assetDesc');
        a.setDiscount(2.00);
        a.setListPrice(2.00);
        a.setAssetState('assetState');
        a.setAssetZip('assetZip');
        a.setFedCalcBasis(2.00);
        a.setFedConvention(1);
        a.setFederalLife(1);
        a.setManufacturer('manufacturer');
        a.setModel('model');
        a.setMaxCityPerInv(2.00);
        a.setMaxCityTax(2.00);
        a.setMaxCntyPerInv(2.00);
        a.setMaxCntyTax(2.00);
        a.setMaxStateTax(2.00);
        a.setNewUsedCode('newUsedCode');
        a.setPropTaxStatus('propTaxStatus');
        a.setPurchaseOption('purchaseOption');
        a.setRenewalOption('renewalOption');
        a.setQuantity(1);
        a.setResidualPercent(2.00);
        a.setResidualAmount(2.00);
        a.setFederalMethod('federalMethod');
        a.setSerialNumber('serialNumber');
        a.setStateBeginDeprDate('12/2016');
        a.setStateDeprBasis(2.00);
        a.setStateLife(1);
        a.setStateMethod(1);
        a.setStateCode('stateCode');
        a.setStateTaxCode('stateTaxCode');
        a.setStateTaxPct(2.00);
        a.setCityTransTaxPct(2.00);
        a.setCntyTransTaxPct(2.00);
        a.setUpfrontTaxBasis(2.00);
        a.setUpfrontTaxCityCode('upfrontTaxCityCode');
        a.setUpfrontTaxCityAmt(2.00);
        a.setUpfrontTaxCntyCode('upfrontTaxCntyCode');
        a.setUpfrontTaxCntyAmt(2.00);
        a.setUpfrontTaxFinanced(true);
        a.setUpfrontTaxRespCode('upfrontTaxRespCode');
        a.setUpfrontTaxStateCode('upfrontTaxStateCode');
        a.setUpfrontTaxStateAmt(2.00);
        a.setTaxCode('taxCode');
        a.setUpfrontTaxTCityAmt(2.00);
        a.setUpfrontTaxTCntyAmt(2.00);
        a.setBeginDeprDate('12/2016');
        a.setOperLeaseBasis(2.00);
        a.setOperDeprLife(1);
        a.setOperDeprMethod('operDeprMethod');
        a.setSalvageValue(2.00);
        a.setUpfrontTaxZipCode('upfrontTaxZipCode');
        assets.add(a);
        bean.setAssets(assets);
        
        TC_BridgewareBookContractRequestBean.Dealer d = new TC_BridgewareBookContractRequestBean.Dealer();
        d.setDealer('dealer');
        d.setDealerDesc('dealerDesc');
        d.setDealerFundDate(System.Today());
        d.setDealerInvoiceNo('dealerInvoiceNo');
        d.setDealerListPrice(2.00);
        d.setSpecialGLcode('specialGLcode');
        bean.setDealer(d);
        
        List<TC_BridgewareBookContractRequestBean.ContractMiscBillable> contractMiscBillables = new List<TC_BridgewareBookContractRequestBean.ContractMiscBillable>();
        TC_BridgewareBookContractRequestBean.ContractMiscBillable cmb = new TC_BridgewareBookContractRequestBean.ContractMiscBillable();
        cmb.setAmountType('amountType');
        cmb.setFutureBill(true);
        cmb.setFinalDate('12/2016');
        cmb.setFirstDate('12/2016');
        cmb.setIncInRent(true);
        cmb.setAmount(2.00);
        cmb.setDisp(true);
        cmb.setCycle(new List <String> {'1','1','1','1','1','1','1','1','1','1','1','1'});
        cmb.setCmbDate('12/2016');
        cmb.setCmbDesc('cmbDesc');
        cmb.setGlCode('glCode');
        cmb.setPayable(1);
        cmb.setTaxable(true);
        cmb.setVendor('vendor');
        contractMiscBillables.add(cmb);
        bean.setContractMiscBillables(contractMiscBillables);
        
        List<TC_BridgewareBookContractRequestBean.ContractMiscInvoice> contractMiscInvoices = new List<TC_BridgewareBookContractRequestBean.ContractMiscInvoice>();
        TC_BridgewareBookContractRequestBean.ContractMiscInvoice cmi = new TC_BridgewareBookContractRequestBean.ContractMiscInvoice();
        cmi.setIncInRent(true);
        cmi.setAmount(2.00);
        cmi.setDisp(true);
        cmi.setCmiDate('12/2016');
        cmi.setCmiDesc('cmbDesc');
        cmi.setGlCode('glCode');
        cmi.setPayable(1);
        cmi.setTaxable(true);
        cmi.setVendor('vendor');
        contractMiscInvoices.add(cmi);
        bean.setContractMiscInvoices(contractMiscInvoices);
        
        TC_BridgewareBookContractRequestUCI uci = new TC_BridgewareBookContractRequestUCI ();
        uci.setUciConfig (bean.getUciConfig ());
        uci.setUciRecord (bean.toUCIString ());
        System.debug (uci);
        uci.getUciConfig ();
        uci.getUciRecord ();
        uci.getUciKey ();
        
        Test.startTest ();
        Test.setMock(HttpCalloutMock.class, new TC_BridgewareBookContractCalloutMockImpl ());
        TC_BridgewareBookContractRespBean respbean = service.bookContract (uci);
        
        //TO DO add more assertions
        System.assert(bean != null);
        System.assertNotEquals(null, respbean);
        Test.stopTest();
    }
    
    @isTest static void testBookContract2andAHalf() {
        // Implement test code
        
        TC_BridgewareService service = new TC_BridgewareServiceImpl ();
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TC_BridgewareBookContractCalloutMockImpl ());
        
        TC_BridgewareUtility.sendToBridgeware ([SELECT Id FROM Opportunity LIMIT 1].Id);
        Test.stopTest ();
    }
    @isTest static void testBookContract2() {
        // Implement test code
        
        TC_BridgewareService service = new TC_BridgewareServiceImpl ();
        
        
        
        TC_BridgewareBookContractRequestBean bean = new TC_BridgewareBookContractRequestBean ();
        bean.setUciConfig('Marlin Rapport UCI Layout');
        
        List<TC_BridgewareBookContractRequestBean.RelatedParty> relatedParties = new List<TC_BridgewareBookContractRequestBean.RelatedParty>();
        TC_BridgewareBookContractRequestBean.RelatedParty rp = new TC_BridgewareBookContractRequestBean.RelatedParty();
        List<String> contractPointersPrinGuarantorCodes = new List<String>();
        contractPointersPrinGuarantorCodes.add('02');
        rp.setContractPointersPrinGuarantorCodes(contractPointersPrinGuarantorCodes);
        List<String> principalGuarantorRecords = new List<String>();
        principalGuarantorRecords.add('293868471');
        rp.setPrincipalGuarantorRecords(principalGuarantorRecords);
        relatedParties.add(rp);
        
        rp = new TC_BridgewareBookContractRequestBean.RelatedParty();
        contractPointersPrinGuarantorCodes = new List<String>();
        contractPointersPrinGuarantorCodes.add('04');
        rp.setContractPointersPrinGuarantorCodes(contractPointersPrinGuarantorCodes);
        principalGuarantorRecords = new List<String>();
        principalGuarantorRecords.add('8005207647');
        rp.setPrincipalGuarantorRecords(principalGuarantorRecords);
        relatedParties.add(rp);
        
        bean.setRelatedParties(relatedParties);
        
        TC_BridgewareBookContractRequestBean.Contract c = new TC_BridgewareBookContractRequestBean.Contract();
        c.setContractNumber('1562489+');
        c.setActivationDate(System.Today());
        c.setDownPayment(0.00);
        c.setPurchaseOption('08');
        c.setArAddress1('1000 Fowler St');
        c.setArAttention('Accounts Payable');
        c.setArCity('Cortland');
        c.setArName('Leverage Brazilian Jiu Jitsu');
        c.setArState('OH');
        c.setArZip('44410');
        List<String> contractBillingCycle = new List<String>();
        contractBillingCycle.add('1');
        contractBillingCycle.add('1');
        contractBillingCycle.add('1');
        contractBillingCycle.add('1');
        contractBillingCycle.add('1');
        contractBillingCycle.add('1');
        contractBillingCycle.add('1');
        contractBillingCycle.add('1');
        contractBillingCycle.add('1');
        contractBillingCycle.add('1');
        contractBillingCycle.add('1');
        contractBillingCycle.add('1');
        c.setContractBillingCycle(contractBillingCycle);
        c.setBookingDate(System.Today());       
        c.setBranch('00020');
        c.setBrokerBookMethod('F');
        c.setBrokerCode('00002');
        c.setBrokerFees(959.60);
        c.setBrokerTaxMethod('F');
        c.setContractPayment(231.93);
        c.setContractTerm(48);
        c.setCreditAccountingName('Robert L Hileman');
        c.setCreditAccountingPhone('3303788070');
        c.setCreditApplicationNumber('Rapport 1173100');
        c.setCustomerAddress1('1000 Fowler St');
        c.setCustomerCity('Cortland');
        c.setCustomerCreditAccountNumber(1562489);
        c.setDoingBusinessAs('Leverage Brazilian Jiu Jitsu');
        c.setCustomerName('Robert L Hileman');
        c.setCustomerState('OH');
        c.setCustomerZip('44410');
        c.setDealerCode('954725.0425');
        c.setGrossEquipmentCost(8000.00);
        c.setFedIDSocSec('293868971');
        c.setFirstFeeDate(System.Today());
        c.setFirstPaymentAmount(231.93);
        c.setFirstPaymentDate(System.Today());
        c.setGracePeriod(0);
        c.setGrossContract(11132.64);
        c.setGrossFinance(3132.64);
        c.setInterimRents(0.00);
        c.setLeadInvDays(22);
        c.setInvoiceDueDay(15);
        c.setInvoiceCode('A');
        c.setInvoiceDescrip('Flexi-Connect Royal Blue Fitness Mats');
        c.setLateChargeExempt(false);
        c.setLateChargeRate(15000);
        c.setContractType('TL');
        c.setLessor(403);
        List<Integer> marketingRepPcts = new List<Integer>();
        marketingRepPcts.add(100);
        c.setMarketingRepPcts(marketingRepPcts);
        List<String> mrktngRepRegion = new List<String>();
        mrktngRepRegion.add('001');
        c.setMrktngRepRegion(mrktngRepRegion);
        List<String> marketingRep = new List<String>();
        marketingRep.add('1524');
        c.setMarketingRep(marketingRep);
        c.setMunicipalLease(false);
        c.setContactEmail(null);
        c.setNumberOfUnits(4);
        c.setOffice('0001');
        c.setProductLine('3272');
        c.setProgramType(null);
        c.setPromotion(null);
        c.setPurchaseOrderNumber(null);
        c.setPaymentOption('N');
        c.setPaymentsInAdvance(0.00);
        c.setPymtsInArrears(false);
        c.setPymtsUpFront(1);
        c.setQuoteBuyout('05');
        c.setRegion('001');
        c.setOutOfBalance(false);
        c.setRemitToCode('9001');
        c.setResidual(0.00);
        c.setResidualCode('E');
        c.setRequiredSignature('Robert L Hileman');
        c.setReqPhone('3303788070');
        c.setSaleleasebackCode(false);
        c.setSecurityDeposit(0.00);
        c.setAcctNumber(null);
        c.setAcctType(null);
        c.setBankNumber(null);
        c.setUserAlphaField10(null);
        c.setUserAlphaField7(null);
        c.setUserAlphaField8(null);
        c.setUserAlphaField3(null);
        c.setUserComments(null);
        c.setUserTable1('9.10');
        c.setUserAmt1(null);
        c.setUserCode(null);
        c.setUseTaxResponsibility('L');
        c.setVariablePaymentsDates(null);
        c.setVariablePymtCode(null);
        c.setVariablePaymentAmounts(null);
        bean.setContract(c);
        
        List<TC_BridgewareBookContractRequestBean.ContractBlendedIncome> contractBlendedIncomes = new List<TC_BridgewareBookContractRequestBean.ContractBlendedIncome>();
        TC_BridgewareBookContractRequestBean.ContractBlendedIncome cbi = new TC_BridgewareBookContractRequestBean.ContractBlendedIncome();
        cbi.setIncludeInQuote(false);
        cbi.setAmount(-211.00);
        cbi.setBeginDate(System.Today());
        cbi.setBookingDate(System.Today());
        cbi.setCode('0001');
        cbi.setIncContRate(true);
        cbi.setIncomeMethod('E');
        cbi.setTaxCalculationMethod('N');
        cbi.setTerm(48);
        cbi.setTiming('U');
        contractBlendedIncomes.add(cbi);
        
        cbi = new TC_BridgewareBookContractRequestBean.ContractBlendedIncome();
        cbi.setIncludeInQuote(false);
        cbi.setAmount(-34.00);
        cbi.setBeginDate(System.Today());
        cbi.setBookingDate(System.Today());
        cbi.setCode('0002');
        cbi.setIncContRate(true);
        cbi.setIncomeMethod('E');
        cbi.setTaxCalculationMethod('N');
        cbi.setTerm(48);
        cbi.setTiming('U');
        contractBlendedIncomes.add(cbi);
        
        cbi = new TC_BridgewareBookContractRequestBean.ContractBlendedIncome();
        cbi.setIncludeInQuote(false);
        cbi.setAmount(95.00);
        cbi.setBeginDate(System.Today());
        cbi.setBookingDate(System.Today());
        cbi.setCode('0004');
        cbi.setIncContRate(true);
        cbi.setIncomeMethod('E');
        cbi.setTaxCalculationMethod('N');
        cbi.setTerm(48);
        cbi.setTiming('U');
        contractBlendedIncomes.add(cbi);
        
        cbi = new TC_BridgewareBookContractRequestBean.ContractBlendedIncome();
        cbi.setIncludeInQuote(false);
        cbi.setAmount(-959.60);
        cbi.setBeginDate(System.Today());
        cbi.setBookingDate(System.Today());
        cbi.setCode('0003');
        cbi.setIncContRate(true);
        cbi.setIncomeMethod('E');
        cbi.setTaxCalculationMethod('N');
        cbi.setTerm(48);
        cbi.setTiming('U');
        contractBlendedIncomes.add(cbi);
        
        bean.setContractBlendedIncomes(contractBlendedIncomes);
        
        List<TC_BridgewareBookContractRequestBean.Asset> assets = new List<TC_BridgewareBookContractRequestBean.Asset>();
        TC_BridgewareBookContractRequestBean.Asset a = new TC_BridgewareBookContractRequestBean.Asset();
        a.setAssetUser3Alphanum1(null);
        a.setAssetUser3Table1(null);
        List<String> assetUserDef = new List<String>();
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        assetUserDef.add('');
        a.setAssetUserDef(assetUserDef);
        a.setAssetUserField3(null);
        a.setAssetUserField4(null);
        a.setAssetUserField5(null);
        a.setAssetUserField6(null);
        a.setAssetUserField7(null);
        a.setLcCityTaxCode('050');
        a.setLcCntyTaxCode('050');
        a.setLcStateTaxCd('050');
        a.setMiscCityTaxCd('050');
        a.setMiscCntyTaxCd('050');
        a.setMiscStTaxCode('050');
        a.setYearofManuf(null);
        a.setOriginalCost(8000.00);
        a.setSalesProfit(0.00);
        a.setVehicleMake(null);
        a.setAceDeprBasis(null);
        a.setDetailedAssetDescription(null);
        a.setAdsClassLIM(null);
        a.setAmtDeprBasis(null);
        a.setRecourseAmt(null);
        a.setRecourseCode(null);
        a.setRecourseComments(null);
        a.setRecoursePct(null);
        a.setRecourseTerm(null);
        a.setAssetStatus(null);
        a.setAssetUserTable1(null);
        a.setFedBeginDeprDate(System.Today());
        a.setCalcACEDepr(true);
        a.setCalcAMTDepr(true);
        a.setTaxDeprBasis(8000.00);
        a.setCityCode('4230');
        a.setCityTaxCode('050');
        a.setCityTaxPct(null);
        a.setCountyCode('155');
        a.setCountyTaxCode('050');
        a.setCountyTaxPct(null);
        a.setAssetAddr1('1000 Fowler St');
        a.setAssetCity('CORTLAND');
        a.setAssetCode('019.000');
        a.setEquipmentCost(8000.00);
        a.setAssetDesc('Flexi-Connect Royal Blue Fitness Mats');
        a.setDiscount(0.00);
        a.setListPrice(8000.00);
        a.setAssetState('OH');
        a.setAssetZip('44410');
        a.setFedCalcBasis(8000.00);
        a.setFedConvention(6);
        a.setDeprPercentages(c.getContractType() == 'TL' ? 100 : null);
        a.setFederalLife(60);
        a.setManufacturer(null);
        a.setModel(null);
        a.setMaxCityPerInv(null);
        a.setMaxCityTax(null);
        a.setMaxCntyPerInv(null);
        a.setMaxCntyTax(null);
        a.setMaxStateTax(null);
        a.setNewUsedCode('N');
        a.setPropTaxStatus('10');
        a.setPurchaseOption('08');
        a.setRenewalOption(null);
        a.setQuantity(4);
        a.setResidualPercent(null);
        a.setResidualAmount(null);
        a.setFederalMethod('28');
        a.setSerialNumber(null);
        a.setStateBeginDeprDate('12/2016');
        a.setStateDeprBasis(8000.00);
        a.setStateLife(60);
        a.setStateMethod(3);
        a.setStateCode('36');
        a.setStateTaxCode('050');
        a.setStateTaxPct(null);
        a.setCityTransTaxPct(null);
        a.setCntyTransTaxPct(null);
        a.setUpfrontTaxBasis(null);
        a.setUpfrontTaxCityCode(null);
        a.setUpfrontTaxCityAmt(null);
        a.setUpfrontTaxCntyCode(null);
        a.setUpfrontTaxCntyAmt(null);
        a.setUpfrontTaxFinanced(null);
        a.setUpfrontTaxRespCode(null);
        a.setUpfrontTaxStateCode(null);
        a.setUpfrontTaxStateAmt(null);
        a.setTaxCode(null);
        a.setUpfrontTaxTCityAmt(null);
        a.setUpfrontTaxTCntyAmt(null);
        a.setBeginDeprDate(null);
        a.setOperLeaseBasis(null);
        a.setOperDeprLife(null);
        a.setOperDeprMethod(null);
        a.setSalvageValue(null);
        a.setUpfrontTaxZipCode(null);
        assets.add(a);
        bean.setAssets(assets);
        
        TC_BridgewareBookContractRequestBean.Dealer d = new TC_BridgewareBookContractRequestBean.Dealer();
        bean.setDealer(d);
        
        List<TC_BridgewareBookContractRequestBean.ContractMiscBillable> contractMiscBillables = new List<TC_BridgewareBookContractRequestBean.ContractMiscBillable>();
        TC_BridgewareBookContractRequestBean.ContractMiscBillable cmb = new TC_BridgewareBookContractRequestBean.ContractMiscBillable();
        contractMiscBillables.add(cmb);
        bean.setContractMiscBillables(contractMiscBillables);
        
        List<TC_BridgewareBookContractRequestBean.ContractMiscInvoice> contractMiscInvoices = new List<TC_BridgewareBookContractRequestBean.ContractMiscInvoice>();
        TC_BridgewareBookContractRequestBean.ContractMiscInvoice cmi = new TC_BridgewareBookContractRequestBean.ContractMiscInvoice();
        cmi.setIncInRent(false);
        cmi.setAmount(95.00);
        cmi.setDisp(true);
        cmi.setCmiDate('02/2017');
        cmi.setCmiDesc('One-Time Documentation Fee');
        cmi.setGlCode('0003');
        cmi.setPayable(0);
        cmi.setTaxable(false);
        cmi.setVendor('954725.0425');
        contractMiscInvoices.add(cmi);
        bean.setContractMiscInvoices(contractMiscInvoices);
        
        TC_BridgewareBookContractRequestUCI uci = new TC_BridgewareBookContractRequestUCI ();
        uci.setUciConfig (bean.getUciConfig ());
        uci.setUciRecord (bean.toUCIString ());
        System.debug (uci);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TC_BridgewareBookContractCalloutMockImpl ());
        
        TC_BridgewareBookContractRespBean respbean = service.bookContract (uci);
        
        //TO DO add more assertions
        //System.assert(bean != null);
        //System.assertNotEquals(null, respbean);
        Test.stopTest();
    }
    
    // @isTest static void testBookContract3 () {
    //     Test.setMock(HttpCalloutMock.class, new TC_BridgewareBookContractCalloutMockImpl ());
    //     Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        
    //     Test.startTest ();
    //     opp.Assign_To_CMS_User__c = UserInfo.getUserId ();
    //     opp.Business_Phone__c = '3432343456';
    //     opp.Tax_ID__c = '234567653';
    //     opp.Account_Business_Street__c = '123';
    //     opp.Account_Billing_Street__c = '123'; 
    //     opp.Account_Business_City__c = '123';
    //     opp.Account_Billing_City__c = '123';
    //     opp.Account_Business_State_Province__c = 'WA';
    //     opp.Account_Billing_State_Province__c = 'WA'; 
    //     opp.Account_Business_Zip_Postal_Code__c = '123';
    //     opp.Account_Billing_Zip_Postal_Code__c = '123';
        
    //     Schema.DescribeSObjectResult d = Schema.SObjectType.Opportunity;
    //     Map <String, Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName ();
    //     opp.RecordTypeId = rtMapByName.get('Loan Booking').getRecordTypeId();
        
    //     opp.Funding_Booking_Loan_Completed_Date__c = System.today ();
    //     opp.StageName = 'Review for Booking';
    //     opp.Auto_Book_to_InfoLease__c = true;
    //     opp.CaseCenter__c = '2343254';
    //     opp.Loan_Purpose__c = 'Expansion';
    //     opp.Primary_Source__c = 'Trade Show';
        
    //     opp.Credit_Stips_Completed_Date__c = Date.today ();
    //     update opp;
    //     Test.stopTest ();
    // }
    
    @isTest static void testSelectZipGeoCode() {
        
        // Implement test code
        Test.setMock(HttpCalloutMock.class, new TC_BridgewareSelectZipGeoCalloutMockImpl ());
        TC_BridgewareService service = new TC_BridgewareServiceImpl ();
        
        Test.startTest();
        
        TC_BridgewareSelectZipGeoCodeRequestBean bean = new TC_BridgewareSelectZipGeoCodeRequestBean ();
        bean.setZipCode ('55125');
        bean.getZipCode ();
        bean.getTaxCode ();
        bean.getRequestUserId ();
        
        TC_BridgewareSelectZipGeoCodeRespBean respbean = service.selectZipGeoCode(bean);
        
        TC_BridgewareSelectZipGeoCodeRespBean.ContentHeader contentHeader = respbean.getContentHeader();
        contentHeader.setContentVersion(contentHeader.getContentVersion());
        contentHeader.setStatus(contentHeader.getStatus());
        
        TC_BridgewareSelectZipGeoCodeRespBean.UniDataZipGeoCodeContentData uniDataZipGeoCodeContentData = respbean.getContentData();

        if (uniDataZipGeoCodeContentData != null) {
            TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipState[] uniDataVtZipStateList = uniDataZipGeoCodeContentData.getVtZipStateList();
            
            if (uniDataVtZipStateList != null) {
                TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipState uniDataVtZipState = null;
                
                for (integer i = 0; i < uniDataVtZipStateList.size(); i++) {
                    uniDataVtZipState = uniDataVtZipStateList[i];
                    System.debug('uniDataVtZipState.description: ' + uniDataVtZipState.getDescription());
                    System.debug('uniDataVtZipState.code: ' + uniDataVtZipState.getCode());
                    uniDataVtZipState.setDescription(uniDataVtZipState.getDescription());
                    uniDataVtZipState.setCode(uniDataVtZipState.getCode());
                    
                    TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipCounty[] uniDataVtZipCountyList = uniDataVtZipState.getVtZipCountyList();
                    
                    if (uniDataVtZipCountyList != null) {
                        TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipCounty uniDataVtZipCounty = null;
                        
                        for (integer j = 0; j < uniDataVtZipCountyList.size(); j++) {
                            uniDataVtZipCounty = uniDataVtZipCountyList[j];
                            System.debug('uniDataVtZipCounty.description: ' + uniDataVtZipCounty.getDescription());
                            System.debug('uniDataVtZipCounty.code: ' + uniDataVtZipCounty.getCode());
                            uniDataVtZipCounty.setDescription(uniDataVtZipCounty.getDescription());
                            uniDataVtZipCounty.setCode(uniDataVtZipCounty.getCode());
                            
                            TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipCity[] uniDataVtZipCityList = uniDataVtZipCounty.getVtZipCityList();
                            
                            if (uniDataVtZipCityList != null) {
                                TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipCity uniDataVtZipCity = null;
                                
                                for (integer k = 0; k < uniDataVtZipCityList.size(); k++) {
                                    uniDataVtZipCity = uniDataVtZipCityList[k];
                                    System.debug('uniDataVtZipCity.description: ' + uniDataVtZipCity.getDescription());
                                    System.debug('uniDataVtZipCity.code: ' + uniDataVtZipCity.getCode());
                                    uniDataVtZipCity.setDescription(uniDataVtZipCity.getDescription());
                                    uniDataVtZipCity.setCode(uniDataVtZipCity.getCode());
                                    
                                    TC_BridgewareSelectZipGeoCodeRespBean.UniDataTaxType[] uniDataTaxTypeList = uniDataVtZipCity.getTaxTypeList();
                                    
                                    if (uniDataTaxTypeList != null) {
                                        TC_BridgewareSelectZipGeoCodeRespBean.UniDataTaxType uniDataTaxType = null;
                                        
                                        for (integer l = 0; l < uniDataTaxTypeList.size(); l++) {
                                            uniDataTaxType = uniDataTaxTypeList[l];
                                            System.debug('uniDataTaxType.description: ' + uniDataTaxType.getDescription());
                                            System.debug('uniDataTaxType.code: ' + uniDataTaxType.getCode());
                                            System.debug('uniDataTaxType.getStateTaxRate(): ' + uniDataTaxType.getStateTaxRate());
                                            System.debug('uniDataTaxType.getCountyTaxRate(): ' + uniDataTaxType.getCountyTaxRate());
                                            System.debug('uniDataTaxType.getCountyTransTaxRate(): ' + uniDataTaxType.getCountyTransTaxRate());
                                            System.debug('uniDataTaxType.getCityTaxRate(): ' + uniDataTaxType.getCityTaxRate());
                                            System.debug('uniDataTaxType.getCityTransTaxRate(): ' + uniDataTaxType.getCityTransTaxRate());
                                            uniDataTaxType.setDescription(uniDataTaxType.getDescription());
                                            uniDataTaxType.setCode(uniDataTaxType.getCode());
                                            uniDataTaxType.setStateTaxRate(uniDataTaxType.getStateTaxRate());
                                            uniDataTaxType.setCountyTaxRate(uniDataTaxType.getCountyTaxRate());
                                            uniDataTaxType.setCountyTransTaxRate(uniDataTaxType.getCountyTransTaxRate());
                                            uniDataTaxType.setCityTaxRate(uniDataTaxType.getCityTaxRate());
                                            uniDataTaxType.setCityTransTaxRate(uniDataTaxType.getCityTransTaxRate());
                                        }
                                    }                                       
                                }
                            }
                        }
                    }
                }
            }
        }
        
        //TO DO add more assertions
        System.assert(bean != null);
        System.assertNotEquals(null, respbean);
        Asset__c theAsset = [SELECT Id FROM Asset__c LIMIT 1];
        TC_BridgewareSelectZipGeoCodeCtrl.getCurrentValues (theAsset.Id);
        Test.stopTest();
    }

    @isTest static void testSelectZipGeoCode2() {
        
        // Implement test code
        Test.setMock(HttpCalloutMock.class, new TC_BridgewareSelectZipGeoCalloutMockImpl ());
        TC_BridgewareService service = new TC_BridgewareServiceImpl ();
        
        Test.startTest();
        TC_BridgewareUtility.selectZipGeoCode ('55125', null, null);
        Test.stopTest();
    }

    @isTest static void testSelectZipGeoCodeCtrl() {
        
        Test.setMock(HttpCalloutMock.class, new TC_BridgewareSelectZipGeoCalloutMockImpl ());
        //TC_BridgewareService service = new TC_BridgewareServiceImpl ();
        Test.startTest();
        Asset__c theAsset = [SELECT Id, Opportunity__r.Probability FROM Asset__c LIMIT 1];
        Decimal returnedProbability = TC_BridgewareSelectZipGeoCodeCtrl.getOpportunityProbability(theAsset.Id);
        TC_BridgewareSelectZipGeoCodeCtrl.search (theAsset.Id, '55125');
        Test.stopTest();
        System.Assert.areEqual(theAsset.Opportunity__r.Probability, returnedProbability, 'needs to obtain the Opp probability');
    }
}