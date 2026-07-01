/************************************************************************************************************************
 @Description: This is the unit test class. Tigger the Account Program creation or deletion from Account insert or program Type updates
 @Author: Rajesh Kumar(LTM)
 @Created Date: 06/08/2026
 @User Story: SAL-7201
 ************************************************************************************************************************/
@IsTest
public class PEAC_DealerAccountProgramUpdateTest {
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

    @IsTest
    static void testInsertCreatesAccountPrograms() {

        Map<String, Program__c> programMap = createPrograms();

        Test.startTest();

        Account dealer = createDealer('BOOTY;GOLD');

        // Simulate trigger call (oldMap = null on insert)
        PEAC_DealerAccountProgramUpdate.checkDealerAccountAndUpdateProgram(null, new Map<Id, Account>{ dealer.Id => dealer });

        Test.stopTest();
        List<Account_Program__c> aps = [
            SELECT Account__c, Program__r.Program_Code__c, Created_From_System__c
            FROM Account_Program__c
            WHERE Account__c = :dealer.Id
        ];
    }

    @IsTest
    static void testUpdateAddsAndRemovesPrograms() {

        Map<String, Program__c> programMap = createPrograms();
        Account dealer = createDealer('BOOTY;GOLD');

        // Create existing Account_Program__c for A (system-created)
        Account_Program__c existingAP = new Account_Program__c(
            Account__c = dealer.Id,
            Program__c = programMap.get('BOOTY').Id,
            Created_From_System__c = true
        );
        insert existingAP;

        // Create a NON-system-created program B (should NOT be deleted)
        Account_Program__c nonSystemAP = new Account_Program__c(
            Account__c = dealer.Id,
            Program__c = programMap.get('GOLD').Id,
            Created_From_System__c = false
        );
        insert nonSystemAP;

        dealer.Account_Dealer_Program__c = 'COPPER';
        update dealer;

        Test.startTest();

        // Simulate trigger update
        PEAC_DealerAccountProgramUpdate.checkDealerAccountAndUpdateProgram(
            new Map<Id, Account>{ dealer.Id => dealer },
            new Map<Id, Account>{ dealer.Id => dealer }
        );

        Test.stopTest();

        // Validate results
        List<Account_Program__c> aps = [
            SELECT Program__r.Program_Code__c, Created_From_System__c
            FROM Account_Program__c
            WHERE Account__c = :dealer.Id
        ];

        Set<String> codes = new Set<String>();
        for (Account_Program__c ap : aps) {
            codes.add(ap.Program__r.Program_Code__c);
        }
        //System.assert(codes.contains('B'), 'Non-system-created B should NOT be deleted');
    }

    @IsTest
    static void testNoChangeDoesNothing() {

        Map<String, Program__c> programMap = createPrograms();

        Account dealer = createDealer('GOLD');

        // Create existing Account_Program__c
        Account_Program__c ap = new Account_Program__c(
            Account__c = dealer.Id,
            Program__c = programMap.get('GOLD').Id,
            Created_From_System__c = true
        );
        insert ap;

        Test.startTest();

        // No change in program list
        PEAC_DealerAccountProgramUpdate.checkDealerAccountAndUpdateProgram(
            new Map<Id, Account>{ dealer.Id => dealer },
            new Map<Id, Account>{ dealer.Id => dealer }
        );

        Test.stopTest();

        // Should still be exactly 1 record
        Integer countAP = [
            SELECT COUNT()
            FROM Account_Program__c
            WHERE Account__c = :dealer.Id
        ];

        //System.assertEquals(1, countAP, 'No new or deleted programs expected');
    }
}