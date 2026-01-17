@isTest
private class PEAC_BankStatementTriggerHandlerTest {

    @isTest
    static void testInsertUpdateDelete_BankStatement() {
        // Setup using utility class
        Account acc = PEAC_BankInfoStatementDataFactoryTest.createAccount();
        Opportunity opp = PEAC_BankInfoStatementDataFactoryTest.createOpportunity(acc.Id);
        Financial__c fin = PEAC_BankInfoStatementDataFactoryTest.createFinancial(opp.Id);
        Financial_Bank_Information__c bank = PEAC_BankInfoStatementDataFactoryTest.createBankInfo(fin.Id);

        // Insert
        Bank_Statement__c stmt = PEAC_BankInfoStatementDataFactoryTest.createBankStatement(bank.Id);

        // Update
        stmt.Amount_of_Deposits__c = 100;
        update stmt;

        // Delete
        delete stmt;
    }

    @isTest
    static void testBulkInsertUpdateDelete_BankStatement() {
        Account acc = PEAC_BankInfoStatementDataFactoryTest.createAccount();
        Opportunity opp = PEAC_BankInfoStatementDataFactoryTest.createOpportunity(acc.Id);
        Financial__c fin = PEAC_BankInfoStatementDataFactoryTest.createFinancial(opp.Id);
        Financial_Bank_Information__c bank = PEAC_BankInfoStatementDataFactoryTest.createBankInfo(fin.Id);

        List<Bank_Statement__c> stmtList = new List<Bank_Statement__c>();
        for (Integer i = 0; i < 5; i++) {
            stmtList.add(new Bank_Statement__c(
                Amount_of_Deposits__c = 100,
                Bank_Information__c = bank.Id
            ));
        }
        insert stmtList;

        for (Bank_Statement__c stmt : stmtList) {
            stmt.Amount_of_Deposits__c = 100;
        }
        update stmtList;

        delete stmtList;
    }
}