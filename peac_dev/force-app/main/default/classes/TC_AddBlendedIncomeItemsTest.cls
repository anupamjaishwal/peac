@isTest
public with sharing class TC_AddBlendedIncomeItemsTest {
    @testSetup
    static void setupMethod() {
        ORE__c o = new ORE__c(Bypass__c = true);
        insert o;
        Marlin_Configuration__c config = new Marlin_Configuration__c(Loan_Salary_Amount__c = 231, Lease_Salary_Amount__c = 71, Loan_Operating_Expense_Amount__c = 27, Lease_Operating_Expense_Amount__c = 0);
        insert config;
        PEAC_TestDataFactory.createBridgeWareSetting();
        List<Account> accounts = PEAC_TestDataFactory.createAccount(5);
        List<Contact> contacts = PEAC_TestDataFactory.createContacts(accounts, 1);
        List<Contract__c> contracts = PEAC_TestDataFactory.createContract(accounts, 1);
        List<Opportunity> testOpportunities = PEAC_TestDataFactory.createOpportunities(accounts[4].Id, 3);
        Test.startTest();
        Payee__c payee = new Payee__c(Dealer__c =accounts[0].Id, Contact__c = contacts[0].Id, Payee_ID__c	= '111000005',
                                      Active__c = true, SL_Vendor_ID__c ='900-090-ASD', Payee_Name__c = 'Test Payee', Address1__c = 'test',
                                      City__c = 'test', State__c = 'MN', Zip__c = '11111', Email__c = 'test@test.com',
                                      Remittance_Address1__c = '100 Test',Remittance_City__c='test',Remittance_Name__c='Test',Remittance_State__c='AB',Remittance_Zip__c='12300');
        insert payee;
        System.debug(LoggingLevel.INFO, 'Number of SOQL queries used: ' + Limits.getQueries());
        List<Asset__c> testAssets = PEAC_TestDataFactory.createAssets(accounts[4].Id, testOpportunities, 3);
        Test.stopTest();
    }
    
    
    @isTest
    static void lessor409() {
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        List<Opportunity> opps = [SELECT Id, Name, Account.Account_Billing_Street__c, StageName,
                                  Loan_Record_Type__c, Lessor__c, Lease_Payment_Interim_Rent__c, Interim_Rent__c, Contract_Type__c,
                                  Broker_Fees__c, Documentation_Fee__c,
                                  Primary_Dealer__r.Dealer__r.Interim_Rent_Dealer_Percentage__c, Primary_Dealer__r.Dealer__r.Preferred_Dealer_Level__c
                                  FROM Opportunity];
        Decimal interimDaysToCheck = 5;
        Map<Id, List<Blended_Income_Item__c>> blendedIncomeItems = new Map<Id, List<Blended_Income_Item__c>>();
        Blended_Income_Item__c newBII = new Blended_Income_Item__c (Blended_Income_Code__c = '0029', Blended_Income_Amount__c = 11,
                                                                    Opportunity__c = opps[2].Id, Generated_Code__c = '0029');
        
        Test.startTest();
        insert newBII;
        opps[2].StageName = 'Booking';
        opps[2].Opportunity_Status__c = 'Booking - In Process';
        opps[2].Account_Billing_Street__c = opps[2].Account.Account_Billing_Street__c;
        opps[2].Billing_Cycle__c = 'January;February';
        opps[2].Booking_Sheet_Generated__c = true;
        opps[2].Purchase_Options__c = 'FMV';
        opps[2].Contract_Type__c = 'TL';
        opps[2].Branch__c = 'Office Equip Group-OEG';
        opps[2].Terms__c = 60;
        opps[2].First_12_Months_Free__c = false;
        opps[2].Beginning_Maintenance_Fee_Amount__c  = 100;
        opps[2].Lessor__c = 409;
        opps[2].Contract_Type__c = 'RL';
        opps[2].Documentation_Fee__c = 11;
        Opportunity opp = opps[2];
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>{opp.Id=> opp};
            Set<Id> oppsMovedToBooking = new Set<Id>();
        oppsMovedToBooking.add(opp.Id);
        blendedIncomeItems.put(opp.Id, new List<Blended_Income_Item__c>{newBII});
        Set<Id> oppsChangedInterimRent = new Set<Id>();
        Map<Id, Dealer__c> dealers = new Map<Id, Dealer__c>{opp.Primary_Dealer__c => opp.Primary_Dealer__r};
            TC_AddBlendedIncomeItems.addBlendedIncomeItems(newMap, oppsMovedToBooking, blendedIncomeItems, oppsChangedInterimRent, dealers);
        Test.stopTest();
    }
    
    @isTest
    static void lessorNot409() {
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        List<Opportunity> opps = [SELECT Id, Name, Account.Account_Billing_Street__c, StageName,
                                  Loan_Record_Type__c, Lessor__c, Lease_Payment_Interim_Rent__c, Interim_Rent__c, Contract_Type__c,
                                  Broker_Fees__c, Documentation_Fee__c,
                                  Primary_Dealer__r.Dealer__r.Interim_Rent_Dealer_Percentage__c, Primary_Dealer__r.Dealer__r.Preferred_Dealer_Level__c
                                  FROM Opportunity];
        Decimal interimDaysToCheck = 5;
        Map<Id, List<Blended_Income_Item__c>> blendedIncomeItems = new Map<Id, List<Blended_Income_Item__c>>();
        Blended_Income_Item__c newBII = new Blended_Income_Item__c (Blended_Income_Code__c = '0004', Blended_Income_Amount__c = 11,
                                                                    Opportunity__c = opps[2].Id, Generated_Code__c = '0004');
        
        Test.startTest();
        
        insert newBII;
        opps[2].StageName = 'Booking';
        opps[2].Opportunity_Status__c = 'Booking - In Process';
        opps[2].Account_Billing_Street__c = opps[2].Account.Account_Billing_Street__c;
        opps[2].Billing_Cycle__c = 'January;February';
        opps[2].Booking_Sheet_Generated__c = true;
        opps[2].Purchase_Options__c = 'FMV';
        opps[2].Contract_Type__c = 'TL';
        opps[2].Branch__c = 'Office Equip Group-OEG';
        opps[2].Terms__c = 60;
        opps[2].First_12_Months_Free__c = false;
        opps[2].Beginning_Maintenance_Fee_Amount__c  = 100;
        opps[2].Lessor__c = 211;
        opps[2].Contract_Type__c = 'RL';
        opps[2].Documentation_Fee__c = 11;
        Opportunity opp = opps[2];
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>{opp.Id=> opp};
            Set<Id> oppsMovedToBooking = new Set<Id>();
        oppsMovedToBooking.add(opp.Id);
        blendedIncomeItems.put(opp.Id, new List<Blended_Income_Item__c>{newBII});
        Set<Id> oppsChangedInterimRent = new Set<Id>();
        Map<Id, Dealer__c> dealers = new Map<Id, Dealer__c>{opp.Primary_Dealer__c => opp.Primary_Dealer__r};
            TC_AddBlendedIncomeItems.addBlendedIncomeItems(newMap, oppsMovedToBooking, blendedIncomeItems, oppsChangedInterimRent, dealers);
        Test.stopTest();
    }
    
    
    @IsTest
    static void testCreateBlendedIncomeItemsFromPayments() {
        List<Opportunity> opps = [SELECT Id, Name, Account.Account_Billing_Street__c, StageName,
                                  Loan_Record_Type__c, Lessor__c, Lease_Payment_Interim_Rent__c, Interim_Rent__c, Contract_Type__c,
                                  Broker_Fees__c, Documentation_Fee__c,
                                  Primary_Dealer__r.Dealer__r.Interim_Rent_Dealer_Percentage__c, Primary_Dealer__r.Dealer__r.Preferred_Dealer_Level__c
                                  FROM Opportunity];
        
        Payee__c p = [SELECT Id FROM Payee__c WHERE Payee_Name__c = 'Test Payee' LIMIT 1];
        
        // Create Payment with Plus Subsidy
        Payment__c payment = new Payment__c(
            Opportunity__c = opps[0].Id,
            Plus_Subsidy__c = 250,
            Payee__c = p.Id
        );
        insert payment;
        
        Test.startTest();
        TC_AddBlendedIncomeItems.createBlendedIncomeItemsFromPayments(
            new Set<Id>{ opps[0].Id }
        );
        Test.stopTest();
    }
}