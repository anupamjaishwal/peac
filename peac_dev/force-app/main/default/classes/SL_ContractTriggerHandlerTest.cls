@isTest
public class SL_ContractTriggerHandlerTest {
    static final String STAUMANN_DEALER = '800448.8168';
    static final String ARROW_DEALER = '303790.2330';
    static final String H_N_A_DEALER = '707523.1112';
    private static final String OEG_DEALER_PROFILE = 'OEG Dealer';
    private static final String USERNAME = 'Portal.SL.test.user@silverlinecrm.com';

    @isTest
    static void groupToWorkingCapitalD() {
        SL_SCTestData.createAccountAndContracts(3,1);
        User secondOwner = SL_SCTestData.createExtraUser(null);
        List<Contract__c> contracts = [SELECT Id, OwnerId FROM Contract__c];
        Id workingCLId = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName()
            .get('Working_Capital_Loan').getRecordTypeId();
        contracts[0].RecordTypeId = workingCLId;
        contracts[0].Current_Days_Delinquent__c = 1;
        contracts[2].RecordTypeId = workingCLId;
        contracts[2].Current_Days_Delinquent__c = 91;
        contracts[2].Status__c = 'Disposed - Charged Off';
        Test.startTest();
        update contracts;
        
        List<Contract__c> contractsAfter = [SELECT Collection_Group__c FROM Contract__c];
        System.assertEquals('Working Capital Delinquency', contractsAfter[0].Collection_Group__c);
        System.assert(contractsAfter[1].Collection_Group__c != 'Working Capital Delinquency');
        // verifying that the default Agent has been assigned
        System.Assert.areEqual(SL_SCTestData.testUser.Id, contracts[2].OwnerId);
        // SL-2871 Misael Romero
        contracts[2].Delinquency_Status_Code__c = '00';
        contracts[2].OwnerId = secondOwner.Id;
        update contracts[2];
        contractsAfter = [SELECT OwnerId FROM Contract__c];
        System.Assert.areEqual(secondOwner.Id, contracts[2].OwnerId);
        Test.stopTest();
    }
    @isTest
    static void groupToStaumann() {
        SL_SCTestData.createAccountAndContracts(2,1);
        Contract__c contract = [SELECT Id, Name, Contract_Balance_Remaining__c, 
            Delinquency_Status_Code__c, Facility_Code__c, Customer__c FROM Contract__c][0];
        Account staumannDealer = [SELECT Id, Dealer_Number__c FROM Account WHERE Id != :contract.Customer__c];
        staumannDealer.Dealer_Number__c = STAUMANN_DEALER;
        update staumannDealer;
        insert new Contract_Account_Role__c(Primary_Dealer__c=true,
            Contract__c = contract.Id, Account__c = staumannDealer.Id);
        contract.Delinquency_Status_Code__c = '01';
        Test.startTest();
        update contract;
        Test.stopTest();
        Contract__c actual = [SELECT Collection_Group__c FROM Contract__c WHERE Id =:contract.Id];
        System.assertEquals('Staumann', actual.Collection_Group__c);
    }
    @isTest
    static void groupToDialerFPD() {
        SL_SCTestData.createAccountAndContracts(36,1);
        List<Contract__c> contracts = SL_SCTestData.testContracts;
        contracts[0].Delinquency_Status_Code__c = '01';
        contracts[0].First_Payment_Default__c = true;
        // groupToDialerRegular
        contracts[1].Delinquency_Status_Code__c = '01';
        contracts[1].Contract_Balance_Remaining__c = 1200;
        // groupToDialerTeam
        contracts[2].Delinquency_Status_Code__c = '01';
        contracts[2].Contract_Balance_Remaining__c = 1201;
        // groupToDialerTCF
        // setGroupToDialerDoNot() was rendered unreachable due to the only factor being attributed to Dialer special, the facility_code__c == '2.27'
        contracts[3].Delinquency_Status_Code__c = '01';
        contracts[3].Facility_Code__c = '2.27';
        // groupTo31TV
        contracts[4].Delinquency_Status_Code__c = '31';
        contracts[4].Facility_Code__c = '2.27';
        contracts[4].Contract_Balance_Remaining__c = 1001;
        contracts[4].First_Payment_Default__c = false;
        contracts[4].Lessor_Code__c = '405';
        // setGroupTo31Regular
        contracts[5].Delinquency_Status_Code__c = '31';
        contracts[5].Facility_Code__c = '2.27';
        contracts[5].Contract_Balance_Remaining__c = 1001;
        contracts[5].First_Payment_Default__c = false;
        // setGroupTo31High
        contracts[6].Delinquency_Status_Code__c = '31';
        contracts[6].Facility_Code__c = '2.27';
        contracts[6].Contract_Balance_Remaining__c = 21000;
        contracts[6].First_Payment_Default__c = false;
        // setGroupTo31FirstPay
        contracts[7].Delinquency_Status_Code__c = '31';
        contracts[7].Facility_Code__c = '2.27';
        contracts[7].Contract_Balance_Remaining__c = 21000;
        contracts[7].First_Payment_Default__c = true;
        // setGroupTo31Syndication
        contracts[8].Delinquency_Status_Code__c = '31';
        contracts[8].Facility_Code__c = '2.27';
        contracts[8].Contract_Balance_Remaining__c = 21000;
        contracts[8].First_Payment_Default__c = true;
        contracts[8].Lessor_Code__c = '150';
        // setGroupTo31Varadero
        contracts[9].Delinquency_Status_Code__c = '31';
        contracts[9].Facility_Code__c = '2.99';
        contracts[9].Contract_Balance_Remaining__c = 21000;
        contracts[9].First_Payment_Default__c = true;
        contracts[9].Lessor_Code__c = '150';
        // setGroupTo31EOT
        contracts[10].Delinquency_Status_Code__c = '31';
        contracts[10].Facility_Code__c = '2.99';
        contracts[10].Contract_Balance_Remaining__c = 21000;
        contracts[10].First_Payment_Default__c = true;
        contracts[10].Lessor_Code__c = '001';
        contracts[10].Renewal_Status__c = 'A';
        // setGroupTo31EOT_not299
        contracts[11].Delinquency_Status_Code__c = '31';
        contracts[11].Facility_Code__c = '2.27';
        contracts[11].Contract_Balance_Remaining__c = 21000;
        contracts[11].First_Payment_Default__c = true;
        contracts[11].Lessor_Code__c = '001';
        contracts[11].Renewal_Status__c = 'A';
        // setGroupTo61Syndication
        contracts[12].Delinquency_Status_Code__c = '61';
        contracts[12].Facility_Code__c = '2.99';
        contracts[12].Contract_Balance_Remaining__c = 21000;
        contracts[12].First_Payment_Default__c = true;
        contracts[12].Lessor_Code__c = '160';
        contracts[12].Renewal_Status__c = 'A';
        // setGroupTo61
        contracts[13].Delinquency_Status_Code__c = '61';
        // setGroupTo61EOT
        contracts[14].Delinquency_Status_Code__c = '61';
        contracts[14].Facility_Code__c = '2.99';
        contracts[14].Contract_Balance_Remaining__c = 21000;
        contracts[14].First_Payment_Default__c = true;
        contracts[14].Lessor_Code__c = '001';
        contracts[14].Renewal_Status__c = 'E';
        // setGroupTo91Syndication
        contracts[15].Delinquency_Status_Code__c = '91';
        contracts[15].Facility_Code__c = '2.99';
        contracts[15].Contract_Balance_Remaining__c = 21000;
        contracts[15].First_Payment_Default__c = true;
        contracts[15].Lessor_Code__c = '150';
        contracts[15].Renewal_Status__c = 'E';
        // setGroupTo91plusEOT
        contracts[16].Delinquency_Status_Code__c = '91';
        contracts[16].Facility_Code__c = '2.99';
        contracts[16].Contract_Balance_Remaining__c = 21000;
        contracts[16].First_Payment_Default__c = true;
        contracts[16].Lessor_Code__c = '001';
        contracts[16].Renewal_Status__c = 'E';
        // setGroupTo91
        contracts[17].Delinquency_Status_Code__c = '91';
        contracts[17].Facility_Code__c = '2.99';
        contracts[17].Contract_Balance_Remaining__c = 21000;
        contracts[17].First_Payment_Default__c = true;
        contracts[17].Lessor_Code__c = '001';
        contracts[17].Renewal_Status__c = null;
        // setGroupTo91plusEOTHigher
        contracts[18].Delinquency_Status_Code__c = '151';
        contracts[18].Facility_Code__c = '2.99';
        contracts[18].Contract_Balance_Remaining__c = 21000;
        contracts[18].First_Payment_Default__c = true;
        contracts[18].Lessor_Code__c = '001';
        contracts[18].Renewal_Status__c = 'E';
        // setGroupToPreCharge
        contracts[19].Delinquency_Status_Code__c = '181';
        contracts[19].Facility_Code__c = '2.99';
        contracts[19].Contract_Balance_Remaining__c = 21000;
        contracts[19].First_Payment_Default__c = true;
        contracts[19].Lessor_Code__c = '150';
        contracts[19].Renewal_Status__c = null;
        // delinquencyToNull
        contracts[20].Delinquency_Status_Code__c = '151';
        update contracts[20];
        contracts[20].Delinquency_Status_Code__c = null;
        // XBS Dialer Regular
        contracts[21].Delinquency_Status_Code__c = '01';
        contracts[21].Lessor_Code__c = '111'; // Causes IsXBS__c to be true
        contracts[21].First_Payment_Default__c = false;
    
        // XBS Dialer First Payment Default
        contracts[22].Delinquency_Status_Code__c = '01';
        contracts[22].Lessor_Code__c = '113'; // Causes IsXBS__c to be true
        contracts[22].First_Payment_Default__c = true;
    
        // XBS 31 Regular
        contracts[23].Delinquency_Status_Code__c = '31';
        contracts[23].Lessor_Code__c = '211'; // Causes IsXBS__c to be true
        contracts[23].First_Payment_Default__c = false;
        contracts[23].Status__c = 'Active';
    
        // XBS 31 First Payment Default
        contracts[24].Delinquency_Status_Code__c = '31';
        contracts[24].Lessor_Code__c = '213'; // Causes IsXBS__c to be true
        contracts[24].First_Payment_Default__c = true;
        contracts[24].Status__c = 'Active';
    
        // XBS 31 EOT
        contracts[25].Delinquency_Status_Code__c = '31';
        contracts[25].Lessor_Code__c = '111'; // Causes IsXBS__c to be true
        contracts[25].Status__c = 'Renewal';
    
        // XBS 61
        contracts[26].Delinquency_Status_Code__c = '61';
        contracts[26].Lessor_Code__c = '113'; // Causes IsXBS__c to be true
        contracts[26].Status__c = 'Active';
    
        // XBS 61 EOT
        contracts[27].Delinquency_Status_Code__c = '61';
        contracts[27].Lessor_Code__c = '211'; // Causes IsXBS__c to be true
        contracts[27].Status__c = 'Renewal';
    
        // XBS 91
        contracts[28].Delinquency_Status_Code__c = '91';
        contracts[28].Lessor_Code__c = '213'; // Causes IsXBS__c to be true
        contracts[28].Status__c = 'Active';
    
        // XBS 91+ EOT
        contracts[29].Delinquency_Status_Code__c = '91';
        contracts[29].Lessor_Code__c = '111'; // Causes IsXBS__c to be true
        contracts[29].Status__c = 'Renewal';
    
        // XBS Pre-Charge Off
        contracts[30].Delinquency_Status_Code__c = '151';
        contracts[30].Lessor_Code__c = '113'; // Causes IsXBS__c to be true
        contracts[30].Status__c = 'Active';
        // ADR Dialer First Payment Default
        contracts[31].Delinquency_Status_Code__c = '01';
        contracts[31].Lessor_Code__c = '471'; // Causes IsXBS__c to be false
        contracts[31].Status__c = 'Active';
        contracts[31].First_Payment_Default__c = true;
        // ADR 31 First Payment Default
        contracts[32].Delinquency_Status_Code__c = '31';
        contracts[32].Lessor_Code__c = '471'; // Causes IsXBS__c to be false
        contracts[32].Status__c = 'Active';
        contracts[32].First_Payment_Default__c = true;
        // ADR 61
        contracts[33].Delinquency_Status_Code__c = '61';
        contracts[33].Lessor_Code__c = '471'; // Causes IsXBS__c to be false
        contracts[33].Status__c = 'Active';
        // ADR 91
        contracts[34].Delinquency_Status_Code__c = '91';
        contracts[34].Lessor_Code__c = '471'; // Causes IsXBS__c to be false
        contracts[34].Status__c = 'Active';
        // ADR Pre-Charge Off
        contracts[35].Delinquency_Status_Code__c = '121';
        contracts[35].Lessor_Code__c = '471'; // Causes IsXBS__c to be false
        contracts[35].Status__c = 'Active';
        Test.startTest();
        update contracts;
        Test.stopTest();
        List<Contract__c> actual = [SELECT Collection_Group__c FROM Contract__c];
        System.Assert.areEqual('Dialer First Payment Default', actual[0].Collection_Group__c);
        System.Assert.areEqual('Dialer Regular', actual[1].Collection_Group__c);// groupToDialerRegular
        System.Assert.areEqual('Dialer Team Assigned', actual[2].Collection_Group__c);// groupToDialerTeam
        System.Assert.areEqual('Dialer TCF', actual[3].Collection_Group__c);// groupToDialerTCF
        System.Assert.areEqual('Titled Vehicles', actual[4].Collection_Group__c);// groupTo31TV
        System.Assert.areEqual('31 Regular', actual[5].Collection_Group__c);// setGroupTo31Regular
        System.Assert.areEqual('31 High Balance', actual[6].Collection_Group__c);// setGroupTo31High
        System.Assert.areEqual('31 First Payment Default', actual[7].Collection_Group__c);// setGroupTo31FirstPay
        System.Assert.areEqual('31 Syndication', actual[8].Collection_Group__c);// setGroupTo31Syndication
        System.Assert.areEqual('31 Varadero', actual[9].Collection_Group__c);// setGroupTo31Varadero
        System.Assert.areEqual('31 EOT', actual[10].Collection_Group__c);// setGroupTo31EOT
        System.Assert.areEqual('31 EOT', actual[11].Collection_Group__c);// setGroupTo31EOT_not299
        System.Assert.areEqual('61 Syndication', actual[12].Collection_Group__c);// setGroupTo61Syndication
        System.Assert.areEqual('61', actual[13].Collection_Group__c);// setGroupTo61
        System.Assert.areEqual('61 EOT', actual[14].Collection_Group__c);// setGroupTo61EOT
        System.Assert.areEqual('91 Syndication', actual[15].Collection_Group__c);// setGroupTo91Syndication
        System.Assert.areEqual('91+ EOT', actual[16].Collection_Group__c);// setGroupTo91plusEOT
        System.Assert.areEqual('91', actual[17].Collection_Group__c);// setGroupTo91
        System.Assert.areEqual('121 Regular', actual[18].Collection_Group__c);// setGroupTo91plusEOTHigher
        System.Assert.areEqual('Pre-Charge Off', actual[19].Collection_Group__c);// setGroupToPreCharge
        System.Assert.areEqual(null, actual[20].Collection_Group__c);// delinquencyToNull
        System.Assert.areEqual('XBS Dialer Regular', actual[21].Collection_Group__c);
        System.Assert.areEqual('XBS Dialer First Payment Default', actual[22].Collection_Group__c);
        System.Assert.areEqual('XBS 31 Regular', actual[23].Collection_Group__c);
        System.Assert.areEqual('XBS 31 First Payment Default', actual[24].Collection_Group__c);
        System.Assert.areEqual('XBS 31 EOT', actual[25].Collection_Group__c);
        System.Assert.areEqual('XBS 61', actual[26].Collection_Group__c);
        System.Assert.areEqual('XBS 61 EOT', actual[27].Collection_Group__c);
        System.Assert.areEqual('XBS 91', actual[28].Collection_Group__c);
        System.Assert.areEqual('XBS 91+ EOT', actual[29].Collection_Group__c);
        System.Assert.areEqual('XBS Pre-Charge Off', actual[30].Collection_Group__c);
        System.Assert.areEqual('ADR Dialer First Payment Default', actual[31].Collection_Group__c);
        System.Assert.areEqual('ADR 31 First Payment Default', actual[32].Collection_Group__c);
        System.Assert.areEqual('ADR 61', actual[33].Collection_Group__c);
        System.Assert.areEqual('ADR 91', actual[34].Collection_Group__c);
        System.Assert.areEqual('ADR Pre-Charge Off', actual[35].Collection_Group__c);
    }
    @isTest
    static void groupToDialerSpecial() {
        SL_SCTestData.createAccountAndContracts(2,1);
        Contract__c contract = [SELECT Id, Name, Contract_Balance_Remaining__c, 
            Delinquency_Status_Code__c, Facility_Code__c, Customer__c FROM Contract__c][0];
        contract.Delinquency_Status_Code__c = '01';
        contract.Contract_Balance_Remaining__c = 1200;
        Account arrowDealer = [SELECT Id, Dealer_Number__c FROM Account WHERE Id != :contract.Customer__c];
        arrowDealer.Dealer_Number__c = ARROW_DEALER;
        update arrowDealer;
        insert new Contract_Account_Role__c(Primary_Dealer__c=true,
            Contract__c = contract.Id, Account__c = arrowDealer.Id);
        Test.startTest();
        update contract;
        Test.stopTest();
        Contract__c actual = [SELECT Collection_Group__c FROM Contract__c WHERE Id =:contract.Id];
        System.assertEquals('Dialer Special', actual.Collection_Group__c);
    }
    @isTest
    static void groupToDialerSpecial2() {
        SL_SCTestData.createAccountAndContracts(2,1);
        Contract__c contract = [SELECT Id, Name, Contract_Balance_Remaining__c, 
            Delinquency_Status_Code__c, Facility_Code__c, Customer__c FROM Contract__c][0];
        contract.Delinquency_Status_Code__c = '01';
        contract.Contract_Balance_Remaining__c = 1200;
        Account hnaDealer = [SELECT Id, Dealer_Number__c FROM Account WHERE Id != :contract.Customer__c];
        hnaDealer.Dealer_Number__c = H_N_A_DEALER;
        update hnaDealer;
        insert new Contract_Account_Role__c(Primary_Dealer__c=true,
            Contract__c = contract.Id, Account__c = hnaDealer.Id);
        Test.startTest();
        update contract;
        Test.stopTest();
        Contract__c actual = [SELECT Collection_Group__c FROM Contract__c WHERE Id =:contract.Id];
        System.assertEquals('Dialer Special', actual.Collection_Group__c);
    }
    
    @isTest
    static void insurance() {
        SL_SCTestData.createAccountAndContracts(7,1);
        SL_SCTestData.createInsurancesAndContractAssets(6, 3);
        Insurance__c insurance = SL_SCTestData.testInsurances[0];
        List<Contract__c> contracts = SL_SCTestData.testContracts;
        List<Contract_Asset__c> assets = SL_SCTestData.testCAssets;
        Account theDealer = SL_SCTestData.testAccounts[6];
        assets[0].Titled_Asset__c = null;
        assets[1].Titled_Asset__c = 'N';
        assets[2].Titled_Asset__c = 'Y';
        assets[0].Insurance__c = null;
        assets[1].Insurance__c = null;
        assets[2].Insurance__c = null;
        // Warehouse test cases
        assets[6].Asset_Code__c = '014.004';
        assets[6].Asset_State__c = 'KY';
        assets[9].Asset_Code__c = '014.004';
        assets[9].Asset_State__c = 'MA';
        assets[12].Asset_Code__c = '014.004';
        assets[12].Asset_State__c = 'CT';
        assets[12].Residual_Amount__c = 750;
        assets[15].Asset_Code__c = '014.004';
        assets[15].Asset_State__c = 'CT';
        update assets;
        theDealer.Business_State__c = 'UT';
        update theDealer;
        insert new Contract_Account_Role__c(Contract__c = contracts[2].Id, Account__c = theDealer.Id, Primary_Dealer__c = true);
        contracts[0].Insurance__c = insurance.Id;
        contracts[1].Letter_of_intent_received__c = Date.newInstance(2023, 2, 2);
        contracts[2].Letter_of_intent_received__c = Date.newInstance(2023, 2, 2);
        contracts[3].Letter_of_intent_received__c = Date.newInstance(2023, 2, 2);
        contracts[4].Letter_of_intent_received__c = Date.newInstance(2023, 2, 2);
        contracts[5].Letter_of_intent_received__c = Date.newInstance(2023, 2, 2);
        Test.startTest();
        update contracts;
        Test.stopTest();
        List<Contract_Asset__c> assetsUpdated = [SELECT Id, Insurance__c, Contract__c, Titled_Asset__c FROM Contract_Asset__c WHERE Insurance__c = :insurance.Id];
        List<Contract__c> contractsAfter = [SELECT Id, Recommended_Warehouse__c, Dealer_Recommended_Warehouse__c FROM Contract__c];
        System.assertEquals(2, assetsUpdated.size());
        System.assertEquals('Omni', contractsAfter[1].Recommended_Warehouse__c);
        System.assertEquals('Omni', contractsAfter[1].Dealer_Recommended_Warehouse__c);
        System.assertEquals('Copex NC', contractsAfter[2].Recommended_Warehouse__c);
        System.assertEquals('EBU CA', contractsAfter[2].Dealer_Recommended_Warehouse__c);
        System.assertEquals('Copex RI', contractsAfter[3].Recommended_Warehouse__c);
        System.assertEquals('Mars NJ', contractsAfter[4].Recommended_Warehouse__c);
        System.assertEquals('RSI CT', contractsAfter[5].Recommended_Warehouse__c);
    }
    
    @isTest
    static void activeInsurance() {
        SL_SCTestData.createAccountAndContracts(1,2);
        Account acc = SL_SCTestData.testAccounts[0];
        Contract__c contract = SL_SCTestData.testContracts[0];
        SL_SCTestData.createInsurancesAndContractAssets(2, 1);
        List<Insurance__c> insurances = SL_SCTestData.testInsurances;
        insurances[0].Account_Level__c = true;
        insurances[0].Expiration_Date__c = Date.valueOf(Date.today() + 30);
        update insurances;
        Test.startTest();
        contract.Insurance__c = insurances[0].Id;
        contract.Payment_Arrangement__c = true;
        update contract;
        Contract__c newContract = new Contract__c (Customer__c = acc.Id,
                    Status__c = 'Active',
                    Name = ( '783210'), application_number__c = '1234567890',
                    Delinquency_Status_Code__c = '00');
        insert newContract;
        Contract__c contract3 = new Contract__c (Customer__c = acc.Id,
            Status__c = 'Active',
            Name = ( '883210'), application_number__c = '1234567890',
            Delinquency_Status_Code__c = '00', Payment_Arrangement__c = true);
        insert contract3;
        Test.stopTest();
        Account accAfter = [SELECT Id, Active_Insurance__c, Payment_Arrangement__c, Payment_Arrangement_Contract__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(accAfter.Active_Insurance__c, insurances[0].Id);
        System.assertEquals(accAfter.Payment_Arrangement__c, contract3.Payment_Arrangement__c);
        System.assertEquals(accAfter.Payment_Arrangement_Contract__c, contract3.Id);
    }

    @isTest
    static void deleteCMB() {
        SL_SCTestData.createAccountAndContracts(1,2);
        Account acc = SL_SCTestData.testAccounts[0];
        List<Contract__c> contracts = SL_SCTestData.testContracts;
        List<Contract_Misc_Billable__c> allCMBs = new List<Contract_Misc_Billable__c>{
            new Contract_Misc_Billable__c(Contract__c = contracts[0].Id, Misc_Key__c = '3999999'),
            new Contract_Misc_Billable__c(Contract__c = contracts[0].Id, Misc_Key__c = '4000000')
        };
        insert allCMBs;
        Test.startTest();
        delete contracts[1];
        contracts[0].Infolease_Environment__c = 'C';
        update contracts[0];
        Test.stopTest();
        List<Contract_Misc_Billable__c> cmbsAfter = [SELECT Id, Misc_Key__c FROM Contract_Misc_Billable__c];
        System.Assert.areEqual(1, cmbsAfter.size(), 'the 3999999 one must be deleted ');
        System.Assert.areEqual('4000000', cmbsAfter[0].Misc_Key__c, 'The IL10 CMB have over 4 million in the misc key');
    }

    @isTest
    static void dealerUpdate_TC() {
        Test.startTest();
        SL_SCTestData.createAccountAndContracts(1,1);
        List<Account> acc = [SELECT Id FROM Account];
        TC_BWUpdateCustomerCtrl.updateCustomer(acc);
        Test.stopTest();
        Integer actual = [SELECT COUNT() FROM Account];
        System.assertEquals(1, actual);
        Integer actualContract = [SELECT COUNT() FROM Contract__c];
        System.assertEquals(1, actualContract);
    }
}