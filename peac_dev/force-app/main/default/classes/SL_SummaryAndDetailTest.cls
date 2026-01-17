@isTest
public with sharing class SL_SummaryAndDetailTest {
    @TestSetup
    static void createSettingAndSuch(){
        SL_SCTestData.createBridgeWareSetting();
    }
    
    @isTest
    public static void getOpenItems() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        Contract__c contract = SL_SCTestData.testContracts[0];
        Test.startTest();
        SL_SummaryAndDetail.getOpenItems(contract.Id);
        SL_SummaryAndDetail.getWaiverCodes();
        SL_SummaryAndDetail.sendWaiverByOiKey('', '25076384', '', '', '', '', '', '', '', false);
        SL_SummaryAndDetail.getDetailByOiKey('25076384', false);
        SL_SummaryAndDetail.getPaymentHistory(contract.Id, false);
        SL_SummaryAndDetail.getDetailByPymtKey('25076384', false);
        Test.stopTest();
        System.assert(true);
    }
    
    @isTest
    public static void getValidQB() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        Contract__c contract = SL_SCTestData.testContracts[0];
        contract.Renewal_Status__c = 'A';
        update contract;
        String result = '', result2 = '';
        Test.startTest();
        result = SL_SummaryAndDetail.requestByContractNumber(contract.Id, 'getValidQB', '');
        System.assert(result.contains('"value": "37"'));
        System.assert(result.contains('"value": "40"'));
        System.assert(result.contains('"value": "41"'));
    
        // getValidQBXerox
        contract.Renewal_Status__c = 'A';
        contract.Lessor_Code__c = '111';
        contract.Contract_Type__c = 'TL';
        contract.Quote_Buyout__c = '02';
        update contract;
        result2 = SL_SummaryAndDetail.requestByContractNumber(contract.Id, 'getValidQB', '');
        Test.stopTest();
        System.Assert.isTrue(result2.contains('"value": "82"'), 'must bring one of the Xerox buyout types');
    }
    @isTest
    public static void getValidQBforE() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[0].Id, 1, 1);
        Opportunity theOpp = SL_SCTestData.testOpportunities[0];
        Contract__c contract = SL_SCTestData.testContracts[0];
        contract.Renewal_Status__c = 'E';
        contract.Opportunity__c = theOpp.Id;
        update contract;
        theOpp.Purchase_Options__c = 'Assigned Residual';
        String result = '', result2 = '';
        Test.startTest();
        update theOpp;
        result = SL_SummaryAndDetail.requestByContractNumber(contract.Id, 'getValidQB', '');
        result2 = SL_SummaryAndDetail.requestByContractNumber(contract.Id, 'getPurchaseOption', '');
        Test.stopTest();
        System.assert(result.contains('"value": "1"'));
        System.assert(result.contains('"value": "20"'));
        System.assert(result.contains('"value": "21"'));
        System.assert(result.contains('"value": "6"'));
        System.assert(result.contains('"value": "22"'));
        System.assert(result.contains('"value": "26"'));
        System.assert(result.contains('"value": "44"'));
        System.assert(result.contains('"value": "45"'));
        System.assert(result.contains('"value": "46"'));
        System.assert(result.contains('"value": "47"'));
        Assert.areEqual('{"oppPurchaseOpt": "Assigned Residual"}', result2);
    }
    @isTest
    public static void saveQB() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        Contract__c contract = SL_SCTestData.testContracts[0];
        contract.Renewal_Status__c = 'A';
        update contract;
        String result = '';
        Test.startTest();
        result = SL_SummaryAndDetail.requestByContractNumber(contract.Id, 'saveQB', '40');
        Test.stopTest();
        Contract__c after = [SELECT Quote_Buyout_Types__c FROM Contract__c WHERE Id = :contract.Id];
        System.assert(result == 'success');
        System.assertEquals('40', after.Quote_Buyout_Types__c);
    }
    @isTest
    public static void getBuyoutQuotes() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        Contract__c contract = SL_SCTestData.testContracts[0];
        Test.startTest();
        SL_SummaryAndDetail.requestByContractNumber(contract.Id, 'buyoutQuotes');
        Test.stopTest();
        System.assert(true);
    }
    @isTest
    public static void createBuyout() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        Contract__c contract = SL_SCTestData.testContracts[0];
        contract.Quote_Buyout_Types__c = '1';
        SL_SCTestData.createInsurancesAndContractAssets(1, 1);
        update contract;
        Test.startTest();
        SL_SummaryAndDetail.requestByContractNumber(contract.Id, 'createBuyout', '1');
        SL_SummaryAndDetail.requestByContractNumber(contract.Id, 'createInsurance', ', "InsurType": "02"');
        SL_SummaryAndDetail.requestByContractNumber(contract.Id, '', null);
        SL_SummaryAndDetail.requestByContractNumber(contract.Id, 'createBuyout', '{"BuyoutType": "1", "Assets": ["' + SL_SCTestData.testCAssets[0].Asset_Number__c + '"]}');
        SL_SummaryAndDetail.requestByContractNumber(contract.Id, 'getUserProfile', '');
        String packageName = 'POC Contracts W Address 3 email';
        Loop__DDP__c ddp = new Loop__DDP__c(Name=packageName, Loop__Object_Name__c = 'Contract_Asset__c');
        insert ddp;
        Loop__DDP_Integration_Option__c delivOpt = new Loop__DDP_Integration_Option__c(Name='My Delivery Option', Loop__DDP__c=ddp.Id);
        insert delivOpt;
        SL_SummaryAndDetail.requestByContractNumber(contract.Id, 'generateRAs');
        String result2 = '', result3 = '';
        List<Contract_Asset__c> moreAssets = new List<Contract_Asset__c>();
        for(Integer i = 0; i < 201; i++){
            moreAssets.add(new Contract_Asset__c(Contract__c = contract.Id, Asset_Cost__c = 500, Serial_Number__c = 'test201' + String.valueOf(i)));
        }
        insert moreAssets;
        result2 = SL_SummaryAndDetail.requestByContractNumber(contract.Id, 'createBuyoutDP', '1');
        result3 = SL_SummaryAndDetail.requestByContractNumber(contract.Id, 'createBuyout', '1');
        Test.stopTest();
        System.Assert.areEqual('{"response": {"Response": {"Success": "false", "Errors": ["This contract contains large number of assets, Please reach out to your PEAC Lease Admin to generate Buyout"]}}}', result2);
        System.Assert.areEqual('{"response": {"Response": {"Success": "false", "Errors": ["This Contract contains large number of assets, Please generate Buyouts in Infolease"]}}}', result3);
    }

    @isTest
    public static void deleteExternalCMBillable() {
        Test.startTest();
        SL_SummaryAndDetail.deleteExternalCMBillable('25076384');
        Test.stopTest();
        System.assert(true);
    }

    @isTest
    public static void coverInfoleaseUtils() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        SL_SCTestData.createInsurancesAndContractAssets(1, 1);
        Account account = SL_SCTestData.testAccounts[0];
        Contract__c contract = SL_SCTestData.testContracts[0];
        Insurance__c insurance = SL_SCTestData.testInsurances[0];
        Contract_Asset__c asset = SL_SCTestData.testCAssets[0];
        Test.startTest();
        SL_InfoleaseUtils.updateRecordWithSynced(account.Id);
        SL_InfoleaseUtils.updateRecordWithSynced(contract.Id);
        SL_InfoleaseUtils.updateRecordWithSynced(insurance.Id);
        SL_InfoleaseUtils.updateRecordWithSynced(asset.Id);
        SL_InfoleaseUtils.updateRecordWithError(account.Id);
        SL_InfoleaseUtils.updateRecordWithError(contract.Id);
        SL_InfoleaseUtils.updateRecordWithError(insurance.Id);
        SL_InfoleaseUtils.updateRecordWithError(asset.Id);
        Test.stopTest();
        System.assert(true);
    }

    @isTest
    public static void coverInfoleaseLoggingUtils(){
        SL_InfoleaseUtils util = SL_InfoleaseUtils.getInstance();

        Bridgeware_Service_Setting__c setting = util.getServiceSettings();
        setting.Upsert_Logs__c = false;
        upsert setting;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SL_InfoleaseContractUpdateMock ());
        SL_InfoleaseLoggingUtils.addLog('InfoLease Generate Buyout Quote', '',  'req.getBody()', 'JSONResponse', 'errorMessage', false, 0);
        SL_InfoleaseLoggingUtils.flush();
        Test.stopTest();
        System.assert(true);

    }
    
    @isTest
    public static void creatBuyoutV2Test(){
        SL_SCTestData.createAccountAndContracts(9, 1);
        String result1, result2, result3, result4, result5, result6, result7, result8, result9;
        Contract__c contract = SL_SCTestData.testContracts[0];
        contract.Quote_Buyout__c = '07';
        contract.Renewal_Status__c = null;
        update contract;
        List<Account> dealerAccounts = SL_SCTestData.testAccounts;
        dealerAccounts[6].RecordTypeId = SL_SCTestData.DEALER_ACC;
        dealerAccounts[6].Penalty_for_Buyout__c = 0;
        dealerAccounts[7].RecordTypeId = SL_SCTestData.DEALER_ACC;
        dealerAccounts[7].Penalty_for_Buyout__c = 3;
        dealerAccounts[7].Days_of_Intent__c = 4;
        dealerAccounts[8].RecordTypeId = SL_SCTestData.DEALER_ACC;
        dealerAccounts[8].Penalty_for_Buyout__c = 0;
        dealerAccounts[8].Days_of_Intent__c = 4;
        update dealerAccounts;
        Test.startTest();
        result5 = SL_SummaryAndDetail.buyoutCreationV2(contract.Id);
        contract.Renewal_Status__c = 'E';
        update contract;
        result6 = SL_SummaryAndDetail.buyoutCreationV2(contract.Id);
        contract.Renewal_Status__c = null;
        contract.Branch_Code__c = '00004';
        contract.Term_Date__c = Date.today().addDays(-181);
        update contract;
        result7 = SL_SummaryAndDetail.buyoutCreationV2(contract.Id);
        contract.Term_Date__c = Date.today().addDays(-2);
        update contract;
        result8 = SL_SummaryAndDetail.buyoutCreationV2(contract.Id);
        contract.Branch_Code__c = '00001';
        contract.Renewal_Status__c = 'A';
        update contract;
        result9 = SL_SummaryAndDetail.buyoutCreationV2(contract.Id);
        List<Contract__c> contractsX = SL_SCTestData.testContracts;
        contractsX[1].Quote_Buyout__c = '18';
        contractsX[1].Lessor_Code__c = '113';
        contractsX[1].Contract_Type__c = 'CS';
        contractsX[1].Dealer_Name__c = dealerAccounts[6].Id;
        contractsX[2].Quote_Buyout__c = '02';
        contractsX[2].Lessor_Code__c = '211';
        contractsX[2].Contract_Type__c = 'TL';
        contractsX[2].Renewal_Status__c = 'A';
        contractsX[3].Quote_Buyout__c = '04';
        contractsX[3].Lessor_Code__c = '213';
        contractsX[3].Term_Date__c = Date.today().addDays(5);
        contractsX[3].Dealer_Name__c = dealerAccounts[7].Id;
        contractsX[3].Contract_Type__c = 'TL';
        contractsX[4].Quote_Buyout__c = '05';
        contractsX[4].Lessor_Code__c = '103';
        contractsX[4].Term_Date__c = Date.today();
        contractsX[4].Dealer_Name__c = dealerAccounts[8].Id;
        update contractsX;
        result1 = SL_SummaryAndDetail.buyoutCreationV2(contractsX[1].Id);
        result2 = SL_SummaryAndDetail.buyoutCreationV2(contractsX[2].Id);
        result3 = SL_SummaryAndDetail.buyoutCreationV2(contractsX[3].Id);
        result4 = SL_SummaryAndDetail.buyoutCreationV2(contractsX[4].Id);
        Test.stopTest();
        System.Assert.areEqual('{"quoteBuyouts": "73;78"}', result1);
        System.Assert.areEqual('{"quoteBuyouts": "82;81;80;79"}', result2);
        System.Assert.areEqual('{"quoteBuyouts": "73;76;78;72"}', result3);
        System.Assert.areEqual('{"quoteBuyouts": "73;76;78;70"}', result4);
        
        System.Assert.areEqual('{"quoteBuyouts": "1;6"}', result5, 'for Renewal null and any other branch buyouts must be 1;6');
        System.Assert.areEqual('{"quoteBuyouts": "39;6"}', result6, 'for Renewal Status E and any other branch buyouts must be 39;6');
        System.Assert.areEqual('{"quoteBuyouts": "1;6;35"}', result7, 'for Renewal Status null AND branch 00004 AND term Date is 180 or more days ago AND no TUR penalty on the dealer: buyouts must be 1;6;35');
        System.Assert.areEqual('{"quoteBuyouts": "1;6;35"}', result8, 'for Renewal Status null AND branch 00004 AND term Date is less than 180 days ago: buyouts must be 1;6;35');
        System.Assert.areEqual('{"quoteBuyouts": "38;10"}', result9, 'for Renewal Status A AND branch 00001: buyouts must be 38;10');
    }
    @isTest
    public static void creatBuyoutV2TestBranch(){
        SL_SCTestData.createAccountAndContracts(4, 1);
        // List<Account> dealerAccounts = SL_SCTestData.testAccounts;
        // dealerAccounts[3].RecordTypeId = SL_SCTestData.DEALER_ACC;
        // dealerAccounts[3].TUR_Penalty__c = 'Yes'; // as per DP-1133 this is not possible anymore
        // update dealerAccounts[3];
        List<Contract__c> contracts = SL_SCTestData.testContracts;
        contracts[0].Quote_Buyout__c = '07';
        contracts[0].Branch_Code__c = '00004';
        contracts[0].Renewal_Status__c = 'A';
        contracts[1].Quote_Buyout__c = '07';
        contracts[1].Branch_Code__c = '00044';
        contracts[1].Renewal_Status__c = 'E';
        // contracts[2].Quote_Buyout__c = '07';
        // contracts[2].Branch_Code__c = '00040';
        // contracts[2].Term_Date__c = Date.today().addDays(-181);
        // contracts[2].Dealer_Name__c = dealerAccounts[3].Id;
        contracts[3].Quote_Buyout__c = '03';
        update contracts;
        String result1, result2, result3, result4;
        Test.startTest();
        result1 = SL_SummaryAndDetail.buyoutCreationV2(contracts[0].Id);
        result2 = SL_SummaryAndDetail.buyoutCreationV2(contracts[1].Id);
        result4 = SL_SummaryAndDetail.buyoutCreationV2(contracts[3].Id);
        Test.stopTest();
        System.Assert.areEqual('{"quoteBuyouts": "38;10;37"}', result1, 'for Branch Codes 00004, 00040 or 00044 AND Renewal status A buyouts must be 38;10;37');
        System.Assert.areEqual('{"quoteBuyouts": "39;6;35"}', result2, 'for Branch Codes 00004, 00040 or 00044 AND Renewal status E buyouts must be 39;6;35');
        //System.Assert.areEqual('{"quoteBuyouts": "1;6;36"}', result3, 'for Renewal Status null AND branch 00040 AND term Date is 180 or more days ago AND TUR penalty on the dealer is YES: buyouts must be 1;6;36');
        System.Assert.areEqual('{"errmessage":"To process your request, please contact customer service at buyouts@peacsolutions.com. Thank you"}', result4, 'for not accepted buyout quotes no buyouts can be created');
    }
    @isTest
    public Static void contractBlockTest(){
        SL_SCTestData.createAccountAndContracts(1, 1);
        Contract__c contract = SL_SCTestData.testContracts[0];
        contract.Quote_Buyout__c = '04';
        update contract;
        Test.startTest();
        SL_SummaryAndDetail.toggleLockContract(contract.Id, true);
        Test.stopTest();
    }
        
    @isTest
    public static void JsonReplacement(){
        String jsonMock = '{"Response":{"Quotes":[{"QuoteType":"1","QuoteTypeDesc":"Test"},{"QuoteType":"06","QuoteTypeDesc":"Test"},{"QuoteType":"35","QuoteTypeDesc":"Test"}]}}';
        Test.startTest();
        String testFunc = SL_SummaryAndDetail.BuyoutReplacement(jsonMock);
        Test.stopTest();
    }
    @isTest
    static void printPdf() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        Test.startTest();
        Contract__c contract = SL_SCTestData.testContracts[0];
        //ApexPages.currentPage().getParameters().put('rows', '[{"key":"ReceivableBalance","label":"Receivable Balance","value":"28394.80","isLink":false,"isCherwell":false,"isCheck":false,"isCurrency":true,"isChecked":false,"isPlain":false,"rows":[{"value":"28394.80","QuoteSeq":"10"},{"value":"28394.80","QuoteSeq":"11"}]},{"key":"Residual","label":"Residual","value":"0.00","isLink":false,"isCherwell":false,"isCheck":false,"isCurrency":true,"isChecked":false,"isPlain":false,"rows":[{"value":"0.00","QuoteSeq":"10"},{"value":"0.00","QuoteSeq":"11"}]},{"key":"SalesTax","label":"Sales Tax","value":"0.00","isLink":false,"isCherwell":false,"isCheck":false,"isCurrency":true,"isChecked":false,"isPlain":false,"rows":[{"value":"0.00","QuoteSeq":"10"},{"value":"0.00","QuoteSeq":"11"}]},{"key":"LateCharges","label":"Late Charges","value":"0.00","isLink":false,"isCherwell":false,"isCheck":false,"isCurrency":true,"isChecked":false,"isPlain":false,"rows":[{"value":"0.00","QuoteSeq":"10"},{"value":"0.00","QuoteSeq":"11"}]},{"key":"AlwaysZero","label":"Early Termination Fee","value":"0","isLink":false,"isCherwell":false,"isCheck":false,"isCurrency":true,"isChecked":false,"isPlain":false,"rows":[{"value":"0","QuoteSeq":"10"},{"value":"0","QuoteSeq":"11"}]},{"key":"SecurityDeposit","label":"Security Deposit","value":"0.00","isLink":false,"isCherwell":false,"isCheck":false,"isCurrency":true,"isChecked":false,"isPlain":false,"rows":[{"value":"0.00","QuoteSeq":"10"},{"value":"0","QuoteSeq":"11"}]},{"key":"EndingDeposit","label":"Ending Deposit","value":"0","isLink":false,"isCherwell":false,"isCheck":false,"isCurrency":true,"isChecked":false,"isPlain":false,"rows":[{"value":"0","QuoteSeq":"10"},{"value":"0","QuoteSeq":"11"}]},{"key":"MiscTotalServiceContract","label":"Service Pass Through","value":"0","isLink":false,"isCherwell":false,"isCheck":false,"isCurrency":true,"isChecked":false,"isPlain":false,"rows":[{"value":"0","QuoteSeq":"10"},{"value":"0","QuoteSeq":"11"}]},{"key":"MiscTotalSumPropertyTax","label":"Property Tax","value":0,"isLink":false,"isCherwell":false,"isCheck":false,"isCurrency":true,"isChecked":false,"isPlain":false,"rows":[{"value":0,"QuoteSeq":"10"},{"value":0,"QuoteSeq":"11"}]},{"key":"MiscTotalSumInsurance","label":"Insurance","value":137.15,"isLink":false,"isCherwell":false,"isCheck":false,"isCurrency":true,"isChecked":false,"isPlain":false,"rows":[{"value":137.15,"QuoteSeq":"10"},{"value":137.15,"QuoteSeq":"11"}]},{"key":"MiscTotalSumOther","label":"Other Lease Charges","value":0,"isLink":false,"isCherwell":false,"isCheck":false,"isCurrency":true,"isChecked":false,"isPlain":false,"rows":[{"value":0,"QuoteSeq":"10"},{"value":0,"QuoteSeq":"11"}]},{"key":"TotalBuyout","label":"Total Buyout","value":"28531.95","isLink":false,"isCherwell":false,"isCheck":false,"isCurrency":true,"isChecked":false,"isPlain":false,"rows":[{"value":"28531.95","QuoteSeq":"10"},{"value":"28531.95","QuoteSeq":"11"}],"totals":"font-weight: var(--lwc-fontWeightBold, 700);"}]');
        //ApexPages.currentPage().getParameters().put('recId', contract.Id);
        
        //ApexPages.currentPage().getParameters().put('action', 'buyout');
        //SL_SummaryAndDetail ctrl = new SL_SummaryAndDetail();
        SL_SummaryAndDetail.getBuyout(contract.Id);
        SL_SummaryAndDetail.sendBuyout(contract.Id,'[{"key":"ReceivableBalance","label":"Receivable Balance","value":"28394.80","isLink":false,"isCherwell":false,"isCheck":false,"isCurrency":true,"isChecked":false,"isPlain":false,"rows":[{"value":"28394.80","QuoteSeq":"10"},{"value":"28394.80","QuoteSeq":"11"}]},{"key":"Residual","label":"Residual","value":"0.00","isLink":false,"isCherwell":false,"isCheck":false,"isCurrency":true,"isChecked":false,"isPlain":false,"rows":[{"value":"0.00","QuoteSeq":"10"},{"value":"0.00","QuoteSeq":"11"}]},{"key":"SalesTax","label":"Sales Tax","value":"0.00","isLink":false,"isCherwell":false,"isCheck":false,"isCurrency":true,"isChecked":false,"isPlain":false,"rows":[{"value":"0.00","QuoteSeq":"10"},{"value":"0.00","QuoteSeq":"11"}]},{"key":"LateCharges","label":"Late Charges","value":"0.00","isLink":false,"isCherwell":false,"isCheck":false,"isCurrency":true,"isChecked":false,"isPlain":false,"rows":[{"value":"0.00","QuoteSeq":"10"},{"value":"0.00","QuoteSeq":"11"}]},{"key":"AlwaysZero","label":"Early Termination Fee","value":"0","isLink":false,"isCherwell":false,"isCheck":false,"isCurrency":true,"isChecked":false,"isPlain":false,"rows":[{"value":"0","QuoteSeq":"10"},{"value":"0","QuoteSeq":"11"}]},{"key":"SecurityDeposit","label":"Security Deposit","value":"0.00","isLink":false,"isCherwell":false,"isCheck":false,"isCurrency":true,"isChecked":false,"isPlain":false,"rows":[{"value":"0.00","QuoteSeq":"10"},{"value":"0","QuoteSeq":"11"}]},{"key":"EndingDeposit","label":"Ending Deposit","value":"0","isLink":false,"isCherwell":false,"isCheck":false,"isCurrency":true,"isChecked":false,"isPlain":false,"rows":[{"value":"0","QuoteSeq":"10"},{"value":"0","QuoteSeq":"11"}]},{"key":"MiscTotalServiceContract","label":"Service Pass Through","value":"0","isLink":false,"isCherwell":false,"isCheck":false,"isCurrency":true,"isChecked":false,"isPlain":false,"rows":[{"value":"0","QuoteSeq":"10"},{"value":"0","QuoteSeq":"11"}]},{"key":"MiscTotalSumPropertyTax","label":"Property Tax","value":0,"isLink":false,"isCherwell":false,"isCheck":false,"isCurrency":true,"isChecked":false,"isPlain":false,"rows":[{"value":0,"QuoteSeq":"10"},{"value":0,"QuoteSeq":"11"}]},{"key":"MiscTotalSumInsurance","label":"Insurance","value":137.15,"isLink":false,"isCherwell":false,"isCheck":false,"isCurrency":true,"isChecked":false,"isPlain":false,"rows":[{"value":137.15,"QuoteSeq":"10"},{"value":137.15,"QuoteSeq":"11"}]},{"key":"MiscTotalSumOther","label":"Other Lease Charges","value":0,"isLink":false,"isCherwell":false,"isCheck":false,"isCurrency":true,"isChecked":false,"isPlain":false,"rows":[{"value":0,"QuoteSeq":"10"},{"value":0,"QuoteSeq":"11"}]},{"key":"TotalBuyout","label":"Total Buyout","value":"28531.95","isLink":false,"isCherwell":false,"isCheck":false,"isCurrency":true,"isChecked":false,"isPlain":false,"rows":[{"value":"28531.95","QuoteSeq":"10"},{"value":"28531.95","QuoteSeq":"11"}],"totals":"font-weight: var(--lwc-fontWeightBold, 700);"}]');
        SL_SummaryAndDetail.getContract(contract.Id);
        insert new List<Buyout__c>{new Buyout__c(Name = 'test buyout1', Buyout_Type__c = '6', Quote_Sequence__c = '1', 
            	Receivable_Balance__c = 920.0, Total_Buyout__c = 920.1, Most_Recent__c = true, Contract__c = contract.Id),
            new Buyout__c(Name = 'test buyout1', Buyout_Type__c = '6', Quote_Sequence__c = '1', 
                Receivable_Balance__c = 920.0, Total_Buyout__c = 920.1, Most_Recent__c = true, Contract__c = contract.Id)};
        String response = SL_SummaryAndDetail.sendBuyoutCreationEmail(contract.Id, new List<String>{'Testemail@test.com'});
        
        Test.stopTest();
        System.Assert.AreEqual('email(s) sent', response, 'Expecting a sucessfull response');
    }
    @isTest
    static void updateOpportunity() {
        SL_SCTestData.createAccountAndContracts(2, 1);
        User serviceAdmin = SL_SCTestData.testUser;
        System.runAs(serviceAdmin){
            SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[0].Id, 1, 1);
            Test.startTest();
            try{
                SL_SummaryAndDetail.updateOpportunity(SL_SCTestData.testOpportunities[0].Id);
            }catch(Exception ex){
    
            }
            
            Test.stopTest();
        }
        
        
    }
    
    @isTest
        static void phoneNumberTest(){
            Account testAcc = new Account();
            testAcc.DUNS__c = '000000000';
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SL_DnBCalloutTest.dnBMock());
            List<Account> testList = SL_SummaryAndDetail.getPhoneNumber(new List<Account>{testAcc});
            Test.stopTest();
    }
}