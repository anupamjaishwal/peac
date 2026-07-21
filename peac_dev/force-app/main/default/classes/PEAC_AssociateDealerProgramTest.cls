/************************************************************************************************************************
 @Description: This is the unit test class. Tigger the Program association on opportunity
 @Author: Rajesh Kumar(LTM)
 @Created Date: 07/01/2026
 @User Story: SAL-6998
 ************************************************************************************************************************/
@IsTest
public class PEAC_AssociateDealerProgramTest {
	// Utility: Create Program__c records
    private static Map<String, Program__c> createPrograms() {
        List<Program__c> programs = new List<Program__c>{
            new Program__c(Name='BOOTY', Program_Code__c='BOOTY'),
            new Program__c(Name='GOLD', Program_Code__c='GOLD'),
            new Program__c(Name='COPPER', Program_Code__c='COPPER')
        };
        insert programs;

        Map<String, Program__c> mapResult = new Map<String, Program__c>();
        for (Program__c p : programs) {
            mapResult.put(p.Program_Code__c, p);
        }
        return mapResult;
    }

    // Utility: Create a dealer account
    private static Account createDealer(String programs) {
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer_Vendor').getRecordTypeId();
        Account acc = new Account(
            Name = 'Dealer Test',
            Type = 'D',
            Account_Dealer_Program__c = programs,
            recordTypeId = recordTypeId
        );
        insert acc;
        return acc;
    }

    @testsetup
    static void testInsertCreatesAccountPrograms() {
		PEAC_TestDataFactory.createBridgeWareSetting();
        List<Account> accounts = PEAC_TestDataFactory.createAccount(1);
        List<Opportunity> testOpportunities = PEAC_TestDataFactory.createOpportunities(accounts[0].Id, 1);
        Test.startTest();
        Map<String, Program__c> programMap = createPrograms();

        Account dealer = createDealer('BOOTY');
        Test.StopTest();

        
    }
    @isTest
    static void createPrimaryDealer()
    {
        List<Opportunity> oppList = [SELECT ID FROM OPPORTUNITY LIMIT 1];
        List<Account> accList = [SELECT ID FROM ACCOUNT WHERE Type = 'D'];
        
        Dealer__c dealer = new Dealer__c(Dealer__c = accList[0].Id,
                                Opportunity__c = oppList[0].Id,
                                Primary_Dealer__c = True);
       	Insert dealer;
    }
    
    

}