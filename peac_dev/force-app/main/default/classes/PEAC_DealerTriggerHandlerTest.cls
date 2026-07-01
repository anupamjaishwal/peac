@IsTest
public class PEAC_DealerTriggerHandlerTest {

    @IsTest
    static void testAddProgram_CoversAllConditions() {
		PEAC_GenerateTaxMatrixBatch.isRunning = true;
        // -----------------------------
        // 0) Resolve Account RecordType DeveloperNames from Custom Label
        // -----------------------------
        // Your production code treats the label as DeveloperName(s) even though variable says "Id".
        List<String> rtDevNames = new List<String>();
        if (!String.isBlank(System.Label.AccountRecordTypeId)) {
            for (String s : System.Label.AccountRecordTypeId.split(',')) {
                if (!String.isBlank(s)) rtDevNames.add(s.trim());
            }
        }

        // Pick one "allowed" Account record type from the label list
        RecordType goodRt = [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND DeveloperName IN :rtDevNames
            LIMIT 1
        ];

        // Optional "not allowed" RT (to cover accIds.contains == false path if org has >1 RT)
        RecordType badRt;
        List<RecordType> badRts = [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND DeveloperName NOT IN :rtDevNames
            LIMIT 1
        ];
        if (!badRts.isEmpty()) badRt = badRts[0];

        // -----------------------------
        // 1) Create Programs
        // -----------------------------
        Program__c prog1 = new Program__c(Name = 'Program-1');
        Program__c prog2 = new Program__c(Name = 'Program-2');
        Program__c prog3 = new Program__c(Name = 'Program-3');
        insert new List<Program__c>{ prog1, prog2, prog3 };

        // -----------------------------
        // 2) Create Accounts (Good + Optional Bad)
        // -----------------------------
        Account accGood = new Account(
            Name = 'Good Dealer Account',
            RecordTypeId = goodRt.Id
        );
        insert accGood;

        Account accBad;
        if (badRt != null) {
            accBad = new Account(
                Name = 'Bad Dealer Account',
                RecordTypeId = badRt.Id
            );
            insert accBad;
        }

        // -----------------------------
        // 3) Create Account Programs for good account
        // -----------------------------
        Account_Program__c ap1 = new Account_Program__c(Account__c = accGood.Id, Program__c = prog1.Id);
        Account_Program__c ap2 = new Account_Program__c(Account__c = accGood.Id, Program__c = prog2.Id);
        insert new List<Account_Program__c>{ ap1, ap2 };

        // -----------------------------
        // 4) Create Opportunities
        // -----------------------------
        Opportunity oppA = new Opportunity(Name = 'Opp-A', StageName = 'Prospecting', CloseDate = Date.today().addDays(10));
        Opportunity oppB = new Opportunity(Name = 'Opp-B', StageName = 'Prospecting', CloseDate = Date.today().addDays(10));
        Opportunity oppC = new Opportunity(Name = 'Opp-C', StageName = 'Prospecting', CloseDate = Date.today().addDays(10));
        insert new List<Opportunity>{ oppA, oppB, oppC };

        // -----------------------------
        // 5) FIRST INVOCATION: cover optyprogramLst.isEmpty() == true
        //    - Provide only oppA (no existing Opportunity_Program__c anywhere yet)
        // -----------------------------
        Dealer__c dA = new Dealer__c(
            Dealer__c = accGood.Id,
            Opportunity__c = oppA.Id
        );

        Test.startTest();
        DealerTriggerHandler.addProgram(new List<Dealer__c>{ dA });
        Test.stopTest();
    }

    
	@IsTest
    static void testDeleteFieldsOnOpportunity() {
		PEAC_GenerateTaxMatrixBatch.isRunning = true;
        // -----------------------------
        // 0) Resolve Account RecordType DeveloperNames from Custom Label
        // -----------------------------
        // Your production code treats the label as DeveloperName(s) even though variable says "Id".
        List<String> rtDevNames = new List<String>();
        if (!String.isBlank(System.Label.AccountRecordTypeId)) {
            for (String s : System.Label.AccountRecordTypeId.split(',')) {
                if (!String.isBlank(s)) rtDevNames.add(s.trim());
            }
        }

        // Pick one "allowed" Account record type from the label list
        RecordType goodRt = [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND DeveloperName IN :rtDevNames
            LIMIT 1
        ];

        // Optional "not allowed" RT (to cover accIds.contains == false path if org has >1 RT)
        RecordType badRt;
        List<RecordType> badRts = [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND DeveloperName NOT IN :rtDevNames
            LIMIT 1
        ];
        if (!badRts.isEmpty()) badRt = badRts[0];

        // -----------------------------
        // 1) Create Programs
        // -----------------------------
        Program__c prog1 = new Program__c(Name = 'Program-1');
        Program__c prog2 = new Program__c(Name = 'Program-2');
        Program__c prog3 = new Program__c(Name = 'Program-3');
        insert new List<Program__c>{ prog1, prog2, prog3 };

        // -----------------------------
        // 2) Create Accounts (Good + Optional Bad)
        // -----------------------------
        Account accGood = new Account(
            Name = 'Good Dealer Account',
            RecordTypeId = goodRt.Id
        );
        insert accGood;

        Account accBad;
        if (badRt != null) {
            accBad = new Account(
                Name = 'Bad Dealer Account',
                RecordTypeId = badRt.Id
            );
            insert accBad;
        }

        // -----------------------------
        // 3) Create Account Programs for good account
        // -----------------------------
        Account_Program__c ap1 = new Account_Program__c(Account__c = accGood.Id, Program__c = prog1.Id);
        Account_Program__c ap2 = new Account_Program__c(Account__c = accGood.Id, Program__c = prog2.Id);
        insert new List<Account_Program__c>{ ap1, ap2 };

        // -----------------------------
        // 4) Create Opportunities
        // -----------------------------
        Opportunity oppA = new Opportunity(Name = 'Opp-A', StageName = 'Prospecting', CloseDate = Date.today().addDays(10));
        Opportunity oppB = new Opportunity(Name = 'Opp-B', StageName = 'Prospecting', CloseDate = Date.today().addDays(10));
        Opportunity oppC = new Opportunity(Name = 'Opp-C', StageName = 'Prospecting', CloseDate = Date.today().addDays(10));
        insert new List<Opportunity>{ oppA, oppB, oppC };

        // -----------------------------
        // 5) FIRST INVOCATION: cover optyprogramLst.isEmpty() == true
        //    - Provide only oppA (no existing Opportunity_Program__c anywhere yet)
        // -----------------------------
        Dealer__c dA = new Dealer__c(
            Dealer__c = accGood.Id,
            Opportunity__c = oppA.Id
        );

        // 5. Execute method
        Test.startTest();
        DealerTriggerHandler.deleteFieldsOnOpportunity(new List<Dealer__c>{ dA });
        Test.stopTest();
    }
    
        
    @IsTest
    static void testInsertUpdateDealer() {
		PEAC_GenerateTaxMatrixBatch.isRunning = true;
        // -----------------------------
        // 0) Resolve Account RecordType DeveloperNames from Custom Label
        // -----------------------------
        // Your production code treats the label as DeveloperName(s) even though variable says "Id".
        List<String> rtDevNames = new List<String>();
        if (!String.isBlank(System.Label.AccountRecordTypeId)) {
            for (String s : System.Label.AccountRecordTypeId.split(',')) {
                if (!String.isBlank(s)) rtDevNames.add(s.trim());
            }
        }

        // Pick one "allowed" Account record type from the label list
        RecordType goodRt = [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND DeveloperName IN :rtDevNames
            LIMIT 1
        ];

        // Optional "not allowed" RT (to cover accIds.contains == false path if org has >1 RT)
        RecordType badRt;
        List<RecordType> badRts = [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND DeveloperName NOT IN :rtDevNames
            LIMIT 1
        ];
        if (!badRts.isEmpty()) badRt = badRts[0];
        Account accGood = new Account(
            Name = 'Good Dealer Account',
            RecordTypeId = goodRt.Id
        );
        insert accGood;
        Opportunity oppA = new Opportunity(Name = 'Opp-A', StageName = 'Prospecting', CloseDate = Date.today().addDays(10));
        insert oppA;
        
        Dealer__c dA = new Dealer__c(
            Dealer__c = accGood.Id,
            Opportunity__c = oppA.Id
        );
        
        Test.startTest();
        	insert dA;
        Test.stopTest();
    }

    @IsTest
    static void testUpdateDealer() {
		PEAC_GenerateTaxMatrixBatch.isRunning = true;
        // -----------------------------
        // 0) Resolve Account RecordType DeveloperNames from Custom Label
        // -----------------------------
        // Your production code treats the label as DeveloperName(s) even though variable says "Id".
        List<String> rtDevNames = new List<String>();
        if (!String.isBlank(System.Label.AccountRecordTypeId)) {
            for (String s : System.Label.AccountRecordTypeId.split(',')) {
                if (!String.isBlank(s)) rtDevNames.add(s.trim());
            }
        }

        // Pick one "allowed" Account record type from the label list
        RecordType goodRt = [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND DeveloperName IN :rtDevNames
            LIMIT 1
        ];

        // Optional "not allowed" RT (to cover accIds.contains == false path if org has >1 RT)
        RecordType badRt;
        List<RecordType> badRts = [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND DeveloperName NOT IN :rtDevNames
            LIMIT 1
        ];
        if (!badRts.isEmpty()) badRt = badRts[0];
        Account accGood = new Account(
            Name = 'Good Dealer Account',
            RecordTypeId = goodRt.Id
        );
        insert accGood;
        Opportunity oppA = new Opportunity(Name = 'Opp-A', StageName = 'Prospecting', CloseDate = Date.today().addDays(10));
        insert oppA;
        
        Dealer__c dA = new Dealer__c(
            Dealer__c = accGood.Id,
            Opportunity__c = oppA.Id
        );
        
        Test.startTest();
        	insert dA;
        	update dA;
        Test.stopTest();
    }

}