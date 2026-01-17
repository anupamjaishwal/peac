@isTest
public class SL_InsuranceTriggerHandlerTest {
    @isTest
    static void activeInsurance() {
        SL_SCTestData.createAccountAndContracts(1,5);
        Account acc = SL_SCTestData.testAccounts[0];
        List<Contract__c> contracts = SL_SCTestData.testContracts;
        Date aMonthFromToday = Date.valueOf(Date.today() + 30);
        Test.startTest();
        SL_SCTestData.createInsurancesAndContractAssets(5, 1);
        List<Insurance__c> insurances = SL_SCTestData.testInsurances;
        contracts[2].Insurance_Status__c = '20A';
        contracts[2].Insurance__c = insurances[2].Id;
        contracts[3].Insurance_Status__c = '20A';
        contracts[3].Insurance__c = insurances[3].Id;
        contracts[4].Insurance_Status__c = '20A';
        contracts[4].Insurance__c = insurances[4].Id;
        update contracts;
        insurances[0].Account_Level__c = true;
        insurances[0].Expiration_Date__c = aMonthFromToday;
        insurances[0].Customer__c = acc.Id;
        insurances[2].Expiration_Date__c = aMonthFromToday;
        insurances[3].Expiration_Date__c = aMonthFromToday;
        insurances[3].Cancel_Date__c = aMonthFromToday;
        insurances[4].Cancel_Date__c = aMonthFromToday;
        List<Database.SaveResult> insuranceResults = Database.update(insurances, false);
        Test.stopTest();
        Account accAfter = [SELECT Id, Active_Insurance__c FROM Account LIMIT 1];
        if(insuranceResults[2].getErrors().size()>0){
            System.Assert.areEqual('This insurance policy must be updated in Infolease 10', insuranceResults[2].getErrors()[0].getMessage(), 'only Cancel Date is editable for IL 10 OR C');
            System.Assert.areEqual('This insurance policy must be updated in Infolease 10', insuranceResults[3].getErrors()[0].getMessage(), 'only Cancel Date is editable for IL 10 OR C');
        }
        System.Assert.areEqual(accAfter.Active_Insurance__c, insurances[0].Id);
        List<Insurance__c> insurancesAfter = [SELECT Id, Cancel_Date__c, Expiration_Date__c FROM Insurance__c];
        System.Assert.areEqual(aMonthFromToday, insurancesAfter[4].Cancel_Date__c, 'Cancel Date must be editable for IL 10 OR C');
    }
    @isTest
    static void syncInsurances() {
        SL_SCTestData.createAccountAndContracts(1,3);
        Account acc = SL_SCTestData.testAccounts[0];
        SL_SCTestData.createInsurancesAndContractAssets(3, 1);
        List<Contract__c> contracts = new List<Contract__c>();
        List<Contract_Asset__c> assets = [SELECT Id, Insurance__c, Contract__c FROM Contract_Asset__c];
        for(Contract_Asset__c asset : assets){
            Contract__c c = new Contract__c(Id = asset.Contract__c,
                Customer__c = acc.Id, Insurance__c = asset.Insurance__c);
            contracts.add(c);
        }
        update contracts;
        List<Insurance__c> insurances = [SELECT Id, Account_Level__c, Expiration_Date__c FROM Insurance__c];
        insurances[1].Insurance_Id__c = String.valueOf(insurances[1].Id);
        insurances[2].Insurance_Id__c = String.valueOf(insurances[2].Id);
        update insurances;
        Test.startTest();
        insurances[0].Customer__c = acc.Id;
        insurances[0].Insurance_Id__c = String.valueOf(insurances[0].Id);
        insurances[0].Carrier__c = 'Carrier Name to test';
        insurances[0].Property_Damage_Coverage__c = 2000;
        insurances[0].Save_at_Account_Level__c = true;
        update insurances;
        Test.stopTest();
        List<Insurance__c> insurancesAfter = [SELECT Id, Carrier__c, Property_Damage_Coverage__c, Insurance_Id__c FROM Insurance__c WHERE Titled_Vehicles__c = FALSE];
        System.assertEquals(2000, insurancesAfter[0].Property_Damage_Coverage__c);
        System.assertEquals(2000, insurancesAfter[1].Property_Damage_Coverage__c);
        System.assertEquals(2000, insurancesAfter[2].Property_Damage_Coverage__c);
        System.assertEquals('Carrier Name to test', insurancesAfter[0].Carrier__c);
        System.assertEquals('Carrier Name to test', insurancesAfter[1].Carrier__c);
        System.assertEquals('Carrier Name to test', insurancesAfter[2].Carrier__c);
        System.assert(insurancesAfter[0].Id == insurancesAfter[0].Insurance_Id__c);
        System.assert(insurancesAfter[1].Id == insurancesAfter[1].Insurance_Id__c);
        System.assert(insurancesAfter[2].Id == insurancesAfter[2].Insurance_Id__c);
    }
    @isTest
    static void syncInsurances2() {
        SL_SCTestData.createAccountAndContracts(1,3);
        Account acc = SL_SCTestData.testAccounts[0];
        SL_SCTestData.createInsurancesAndContractAssets(3, 1);
        List<Contract__c> contracts = new List<Contract__c>();
        List<Contract_Asset__c> assets = [SELECT Id, Insurance__c, Contract__c FROM Contract_Asset__c];
        for(Contract_Asset__c asset : assets){
            Contract__c c = new Contract__c(Id = asset.Contract__c,
                Customer__c = acc.Id, Insurance__c = asset.Insurance__c);
            contracts.add(c);
        }
        update contracts;
        List<Insurance__c> insurances = [SELECT Id, Account_Level__c, Expiration_Date__c FROM Insurance__c];
        insurances[1].Insurance_Id__c = String.valueOf(insurances[1].Id);
        insurances[2].Insurance_Id__c = String.valueOf(insurances[2].Id);
        update insurances;
        Test.startTest();
        Integer childContracts = [select count() from Contract__c WHERE Customer__c = : acc.Id AND Insurance__c = :insurances[0].Id AND Insurance__r.Titled_Vehicles__c = FALSE AND (NOT Status__c LIKE 'Disposed%')];
        System.assert(childContracts > 0);
        insurances[0].Customer__c = null;
        insurances[0].Insurance_Id__c = String.valueOf(insurances[0].Id);
        insurances[0].Carrier__c = 'Carrier Name to test';
        insurances[0].Property_Damage_Coverage__c = 2000;
        insurances[0].Save_at_Account_Level__c = true;
        update insurances;
        Test.stopTest();
        List<Insurance__c> insurancesAfter = [SELECT Id, Carrier__c, Property_Damage_Coverage__c, Insurance_Id__c FROM Insurance__c WHERE Titled_Vehicles__c = FALSE];
        System.assertEquals(2000, insurancesAfter[0].Property_Damage_Coverage__c);
        System.assertEquals(2000, insurancesAfter[1].Property_Damage_Coverage__c);
        System.assertEquals(2000, insurancesAfter[2].Property_Damage_Coverage__c);
        System.assertEquals('Carrier Name to test', insurancesAfter[0].Carrier__c);
        System.assertEquals('Carrier Name to test', insurancesAfter[1].Carrier__c);
        System.assertEquals('Carrier Name to test', insurancesAfter[2].Carrier__c);
        System.assert(insurancesAfter[0].Id == insurancesAfter[0].Insurance_Id__c);
        System.assert(insurancesAfter[1].Id == insurancesAfter[1].Insurance_Id__c);
        System.assert(insurancesAfter[2].Id == insurancesAfter[2].Insurance_Id__c);
    }

    @isTest
    static void dataAdminExcemption() {
        SL_SCTestData.createAccountAndContracts(1,1);
        Account acc = SL_SCTestData.testAccounts[0];
        List<Contract__c> contracts = SL_SCTestData.testContracts;
        Date aMonthFromToday = Date.valueOf(Date.today() + 30);
        List<User> theDataAdmin = [SELECT Id, Name FROM User WHERE Name = 'User Informatica'];
        SL_SCTestData.createInsurancesAndContractAssets(1, 1);
        List<Insurance__c> insurances = SL_SCTestData.testInsurances;
        contracts[0].Insurance_Status__c = '20A';
        contracts[0].Insurance__c = insurances[0].Id;
        update contracts;
        Test.startTest();
        if(theDataAdmin.size() > 0){
            System.runAs(theDataAdmin[0]){
                insurances[0].Expiration_Date__c = aMonthFromToday;
                List<Database.SaveResult> insuranceResults = Database.update(insurances, false);
            }
        }
        Test.stopTest();
        List<Insurance__c> insurancesAfter = [SELECT Id, Cancel_Date__c, Expiration_Date__c FROM Insurance__c];
        System.Assert.areEqual(aMonthFromToday, insurancesAfter[0].Expiration_Date__c, 'fields must be editable for IL 10 OR C using DataAdmin profile');
    }
}