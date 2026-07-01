@IsTest
public class NT_QuoteScreenUtilTest {

    @TestSetup
    static void setup() {
        // Get the Dealer Account record type
        RecordType dealerRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Dealer Account' LIMIT 1];
        
        Account dealer = new Account(
            Name = 'Test Dealer',
            RecordTypeId = dealerRT.Id
        );
        insert dealer;

        Program__c prog1 = new Program__c(Name = 'Program 1', Program_Code__c = 'PRG1');
        Program__c prog2 = new Program__c(Name = 'Program 2', Program_Code__c = 'PRG2');
        insert new List<Program__c>{ prog1, prog2 };

        Account_Program__c ap1 = new Account_Program__c(Account__c = dealer.Id, Program__c = prog1.Id);
        insert ap1;
        // prog2 intentionally not linked to this dealer
    }

    @IsTest
    static void testGetDealerPrograms_returnsLinkedPrograms() {
        Account dealer = [SELECT Id FROM Account WHERE Name = 'Test Dealer' LIMIT 1];

        NT_QuoteScreenUtil.GetDealerProgramsRequest req = new NT_QuoteScreenUtil.GetDealerProgramsRequest();
        req.dealerAccountId = dealer.Id;

        Test.startTest();
        List<List<Program__c>> results = NT_QuoteScreenUtil.getDealerPrograms(
            new List<NT_QuoteScreenUtil.GetDealerProgramsRequest>{ req }
        );
        Test.stopTest();

        Assert.areEqual(1, results.size());
        Assert.areEqual(1, results[0].size(), 'Only programs linked via Account_Program__c should be returned');
        Assert.areEqual('PRG1', results[0][0].Program_Code__c);
    }

    @IsTest
    static void testGetDealerPrograms_blankAccountId_returnsEmpty() {
        NT_QuoteScreenUtil.GetDealerProgramsRequest req = new NT_QuoteScreenUtil.GetDealerProgramsRequest();
        req.dealerAccountId = '';

        Test.startTest();
        List<List<Program__c>> results = NT_QuoteScreenUtil.getDealerPrograms(
            new List<NT_QuoteScreenUtil.GetDealerProgramsRequest>{ req }
        );
        Test.stopTest();

        Assert.areEqual(1, results.size());
        Assert.areEqual(0, results[0].size(), 'Blank accountId should return empty list');
    }

    @IsTest
    static void testGetDealerPrograms_noLinkedPrograms_returnsEmpty() {
        RecordType dealerRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Dealer Account' LIMIT 1];
        
        Account otherDealer = new Account(
            Name = 'Other Dealer',
            RecordTypeId = dealerRT.Id
        );
        insert otherDealer;

        NT_QuoteScreenUtil.GetDealerProgramsRequest req = new NT_QuoteScreenUtil.GetDealerProgramsRequest();
        req.dealerAccountId = otherDealer.Id;

        Test.startTest();
        List<List<Program__c>> results = NT_QuoteScreenUtil.getDealerPrograms(
            new List<NT_QuoteScreenUtil.GetDealerProgramsRequest>{ req }
        );
        Test.stopTest();

        Assert.areEqual(1, results.size());
        Assert.areEqual(0, results[0].size(), 'Dealer with no Account_Program__c records should return empty list');
    }
}