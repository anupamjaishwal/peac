@isTest
public class PEAC_BankInfoStatementDataFactoryTest {

    public static Account createAccount() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        return acc;
    }

    public static Opportunity createOpportunity(Id accountId) {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(7),
            AccountId = accountId,
            OwnerId = UserInfo.getUserId()
        );
        insert opp;
        return opp;
    }

    public static Financial__c createFinancial(Id oppId) {
        Financial__c fin = new Financial__c(Opportunity__c = oppId);
        insert fin;
        return fin;
    }

    public static Financial_Bank_Information__c createBankInfo(Id financialId) {
        Financial_Bank_Information__c bank = new Financial_Bank_Information__c(
            Name = 'Test Bank Info',
            Financial__c = financialId,
            Bank_Account_Number_No_Masking__c = '1234567890'
        );
        insert bank;
        return bank;
    }

    public static Bank_Statement__c createBankStatement(Id bankInfoId) {
        Bank_Statement__c bs = new Bank_Statement__c(
            Bank_Information__c = bankInfoId
        );
        insert bs;
        return bs;
    }
}