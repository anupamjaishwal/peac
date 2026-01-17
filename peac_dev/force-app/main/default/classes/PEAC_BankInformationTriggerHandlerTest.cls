@isTest
private class PEAC_BankInformationTriggerHandlerTest {

    @isTest
    static void testInsertUpdateDelete_BankInfo() {
        // Setup using utility class
        Account acc = PEAC_BankInfoStatementDataFactoryTest.createAccount();
        Opportunity opp = PEAC_BankInfoStatementDataFactoryTest.createOpportunity(acc.Id);
        Financial__c fin = PEAC_BankInfoStatementDataFactoryTest.createFinancial(opp.Id);

        // Insert
        Financial_Bank_Information__c bank = PEAC_BankInfoStatementDataFactoryTest.createBankInfo(fin.Id);

        // Update
        bank.Bank_Account_Number_No_Masking__c = 'UPDATED123';
        update bank;

        // Delete
        delete bank;
    }

    @isTest
    static void testBulkInsertUpdateDelete_BankInfo() {
        Account acc = PEAC_BankInfoStatementDataFactoryTest.createAccount();
        Opportunity opp = PEAC_BankInfoStatementDataFactoryTest.createOpportunity(acc.Id);
        Financial__c fin = PEAC_BankInfoStatementDataFactoryTest.createFinancial(opp.Id);

        List<Financial_Bank_Information__c> bankList = new List<Financial_Bank_Information__c>();
        for (Integer i = 0; i < 5; i++) {
            bankList.add(new Financial_Bank_Information__c(
                Name = 'Bank Info ' + i,
                Financial__c = fin.Id,
                Bank_Account_Number_No_Masking__c = 'ACC' + i
            ));
        }
        insert bankList;

        for (Financial_Bank_Information__c bank : bankList) {
            bank.Bank_Account_Number_No_Masking__c += '_X';
        }
        update bankList;

        delete bankList;
    }
}