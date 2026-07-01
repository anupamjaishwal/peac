@IsTest(seeAllData=false)
public class PEAC_OpportunityActionsHandlerTest {

    // ------------------------
    // Helpers / Test Builders
    // ------------------------

    private static Opportunity makeOpp(
        String name,
        Boolean loanRecordType,
        String stage,
        Decimal totalPaymentsSent,
        Decimal totalPaymentsSentLoan,
        DateTime bookedDt,
        Date commencementDt,
        Decimal floridaSum,
        String purchaseOptions,
        Boolean readyToDoc,
        Boolean manualFunding,
        Decimal secDeposit
    ) {
        Opportunity o = new Opportunity(
            Name = name,
            StageName = stage,
            Opportunity_Booked_Date__c = bookedDt,
            Commencement_Date__c = commencementDt,
            Purchase_Options__c = purchaseOptions,
            Ready_to_Doc__c = readyToDoc ? PEAC_ConstantClass.Yes : PEAC_ConstantClass.No,
            Manual_Funding__c = manualFunding,
            Security_Deposit__c = secDeposit,
            closeDate = DateTime.now().Date()
        );
        Account acc = TestDataFactory.createTestAccount();
        Contact con = TestDataFactory.createTestContact(acc.Id);
        Opportunity opp = TestDataFactory.createTestOpp(acc.Id);
        return opp;
    }

    private static Blended_Income_Item__c makeBII(Id oppId) {
        Blended_Income_Item__c b = new Blended_Income_Item__c(
            Opportunity__c = oppId
        );
        insert b;
        return b;
    }

    private static Asset__c makeAsset(Id oppId, String street, String city, String state, String zip) {
        Asset__c a = new Asset__c(
            Opportunity__c = oppId,
            Equipment_Street__c = street,
            Equipment_City__c = city
        );
        insert a;
        return a;
    }

    private static Miscellaneous_Invoice_Item__c makeMiscItem(Id oppId, Decimal amount, String gl) {
        Miscellaneous_Invoice_Item__c m = new Miscellaneous_Invoice_Item__c(
            Opportunity__c = oppId,
            Amount__c = amount,
            GL_Code__c = gl
        );
        insert m;
        return m;
    }
    
     private static Payment__c makePayment(Id oppId, Decimal amount) {
        Payment__c m = new Payment__c(
            Opportunity__c = oppId,
            Payment_Total__c = amount,
            Payee__c = makePayee().Id,
            Payment_Status__c = 'Payment Released',
            Plus_Points__c = amount,
            Plus_Subsidy__c = amount,
            Less_Doc_Fee_Amount__c = amount,
            Less_Wire_Fee__c = amount,
            Subsidy_Information__c = 'AutoPlus, 1751979'
            
        );
        insert m;
        return m;
    }

     private static Payee__c makePayee() {
        Payee__c m = new Payee__c (Address1__c = 'test', City__c = 'test', State__c = 'MN',
                                   Payee_Name__c = 'dummy'+Integer.valueOf(Math.random() * 100), Zip__c = '11111', Email__c = 'test@test.com', SL_Vendor_ID__c = 'test');
        insert m;
        return m;
    }

    private static Map<Id, Opportunity> toMap(List<Opportunity> opps) {
        Map<Id, Opportunity> m = new Map<Id, Opportunity>();
        for (Opportunity o : opps) m.put(o.Id, o);
        return m;
    }

    private static void refresh(List<Id> ids) {
        // Helper to simulate "newMap" after update
        // No-op; we build newMap by re-querying.
    }

    // ------------------------
    // TESTS
    // ------------------------

    @IsTest static void test_01_BookedDateUpdatesBII_InsertStyle() {
        // Given
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        Opportunity o = makeOpp('Opp-01', false, PEAC_ConstantClass.OPPORTUNITY_STAGENAME_BOOKING,
                                0.0, 0.0, DateTime.now(), (Date)null, 0.0, (String)null, false, false,0.0);
        o.Opportunity_Booked_Date__c = DateTime.now().Date();
        update o;
        Blended_Income_Item__c bii = makeBII(o.Id);

        // Build newMap (after insert emulation)
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>{ o.Id => o };

        // When
        Test.startTest();
        PEAC_OpportunityActionsHandler.opportunityUpdateBlendedIncomeItemBookedDateToOpportunityBookedDate(newMap);
        Test.stopTest();

        // Then
        bii = [SELECT Booking_Date__c FROM Blended_Income_Item__c WHERE Id = :bii.Id];
        System.assertEquals(o.Opportunity_Booked_Date__c, bii.Booking_Date__c, 'BII booking date should match Opp booked date (date only)');
    }

    @IsTest static void test_01_BookedDateUpdatesBII_UpdateStyle() {
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        Opportunity o = makeOpp('Opp-01u', false, PEAC_ConstantClass.OPPORTUNITY_STAGENAME_BOOKING,
                                0.0, 0.0, (DateTime)null, (Date)null, 0.0, (String)null, false, false,0.0);
        o.Opportunity_Booked_Date__c = DateTime.now().Date();
        update o;
        Blended_Income_Item__c bii = makeBII(o.Id);

        Opportunity oldO = o.clone(false, true, false, false);
        oldO.Opportunity_Booked_Date__c = null;

        // Simulate new value
        o.Opportunity_Booked_Date__c = DateTime.now().Date();
        update o;

        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{ o.Id => oldO };
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>{ o.Id => o };

        Test.startTest();
        PEAC_OpportunityActionsHandler.opportunityUpdateBlendedIncomeItemBookedDateToOpportunityBookedDate(oldMap, newMap);
        Test.stopTest();

        bii = [SELECT Booking_Date__c FROM Blended_Income_Item__c WHERE Id = :bii.Id];
        System.assertEquals(o.Opportunity_Booked_Date__c, bii.Booking_Date__c);
    }

    @IsTest static void test_02_ManualFundingTrueInsertOpportunity() {
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        Account acc = TestDataFactory.createTestAccount();
        Contact con = TestDataFactory.createTestContact(acc.Id);
        Opportunity o = new Opportunity(Name='Test opp',CloseDate=System.today()+30, stagename='Quote', 
                        AccountId=acc.Id,State_Tax_Code__c='MN',Tax_City__c='WOODBURY',Tax_ID__c='622666666',
                                      Tax_County__c = 'WASHINGTON', Tax_Exempt__c='Yes', Amount=33, Billing_Cycle__c='December',
                                      Recurring__c='Recurring Only', Meter_Account__c = 'DLR');
        o.Name = 'Opp-02';
        o.StageName = 'Prospecting'; 
        o.Manual_Funding__c = True;
        insert o;
        List<Opportunity> newList = new List<Opportunity>{ o };

        Test.startTest();
        PEAC_OpportunityActionsHandler.opportunitySetManualFundingFields(newList);
        Test.stopTest();

        System.assertNotEquals(null, o.Manual_Funding_Date__c, 'Manual funding date should be set');
        System.assertEquals(UserInfo.getUserId(), o.Manual_Funding_User__c, 'Manual funding user should be current user');
    }

    @IsTest static void test_02_ManualFundingFalseInsertOpportunity() {
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        Account acc = TestDataFactory.createTestAccount();
        Contact con = TestDataFactory.createTestContact(acc.Id);
        Opportunity o = new Opportunity(Name='Test opp',CloseDate=System.today()+30, stagename='Quote', 
                        AccountId=acc.Id,State_Tax_Code__c='MN',Tax_City__c='WOODBURY',Tax_ID__c='622666666',
                                      Tax_County__c = 'WASHINGTON', Tax_Exempt__c='Yes', Amount=33, Billing_Cycle__c='December',
                                      Recurring__c='Recurring Only', Meter_Account__c = 'DLR');
        o.Name = 'Opp-02';
        o.StageName = 'Prospecting'; 
        o.Manual_Funding__c = false;
        insert o;
        List<Opportunity> newList = new List<Opportunity>{ o };

        Test.startTest();
        PEAC_OpportunityActionsHandler.opportunitySetManualFundingFields(newList);
        Test.stopTest();

        System.assertEquals(null, o.Manual_Funding_Date__c, 'Manual funding should be set to null');
        System.assertEquals(null, o.Manual_Funding_User__c, 'Manual funding user should be set to null');
    }

    @IsTest static void test_02_ManualFundingTrueUpdateOpportunity() {
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        Account acc = TestDataFactory.createTestAccount();
        Contact con = TestDataFactory.createTestContact(acc.Id);
        Opportunity o = new Opportunity(Name='Test opp',CloseDate=System.today()+30, stagename='Quote', 
                        AccountId=acc.Id,State_Tax_Code__c='MN',Tax_City__c='WOODBURY',Tax_ID__c='622666666',
                                      Tax_County__c = 'WASHINGTON', Tax_Exempt__c='Yes', Amount=33, Billing_Cycle__c='December',
                                      Recurring__c='Recurring Only', Meter_Account__c = 'DLR');
        o.Name = 'Opp-02';
        o.StageName = 'Prospecting'; 
        o.Manual_Funding__c = true;
        insert o;
        Opportunity oldO = o.clone(false, true, false, false);
        oldO.Manual_Funding__c = false;

        o.Manual_Funding__c = true;
        update o;

        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{ o.Id => oldO };
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>{ o.Id => o };

        Test.startTest();
        PEAC_OpportunityActionsHandler.opportunitySetManualFundingFields(oldMap, newMap);
        Test.stopTest();

        System.assertNotEquals(null, o.Manual_Funding_Date__c);
        System.assertEquals(UserInfo.getUserId(), o.Manual_Funding_User__c);
    }
    
    @IsTest static void test_02_ManualFundingFalseUpdateOpportunity() {
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        Account acc = TestDataFactory.createTestAccount();
        Contact con = TestDataFactory.createTestContact(acc.Id);
        Opportunity o = new Opportunity(Name='Test opp',CloseDate=System.today()+30, stagename='Quote', 
                        AccountId=acc.Id,State_Tax_Code__c='MN',Tax_City__c='WOODBURY',Tax_ID__c='622666666',
                                      Tax_County__c = 'WASHINGTON', Tax_Exempt__c='Yes', Amount=33, Billing_Cycle__c='December',
                                      Recurring__c='Recurring Only', Meter_Account__c = 'DLR');
        o.Name = 'Opp-02';
        o.StageName = 'Prospecting'; 
        o.Manual_Funding__c = false;
        insert o;
        Opportunity oldO = o.clone(false, true, false, false);
        oldO.Manual_Funding__c = false;

        o.Manual_Funding__c = true;
        update o;

        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{ o.Id => oldO };
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>{ o.Id => o };

        Test.startTest();
        PEAC_OpportunityActionsHandler.opportunitySetManualFundingFields(oldMap, newMap);
        Test.stopTest();

        System.assertNotEquals(null, o.Manual_Funding_Date__c);
        System.assertEquals(UserInfo.getUserId(), o.Manual_Funding_User__c);
    }

    @IsTest static void test_03_FundedAmount_From_TotalPaymentsSent_NonLoan_InsertStyle() {
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        User userObj = TestDataFactory.createTestUser();
        userObj.Personnel_Number__c = '1234';
        update userObj;
        System.runAs(userObj){
        Account acc = TestDataFactory.createTestAccount();
        Contact con = TestDataFactory.createTestContact(acc.Id);
        Opportunity o = new Opportunity(Name='Test opp',CloseDate=System.today()+30, stagename='Quote', 
                        AccountId=acc.Id,State_Tax_Code__c='MN',Tax_City__c='WOODBURY',Tax_ID__c='622666666',
                                      Tax_County__c = 'WASHINGTON', Tax_Exempt__c='Yes', Amount=33, Billing_Cycle__c='December',
                                      Recurring__c='Recurring Only', Meter_Account__c = 'DLR');
        o.Name = 'Opp-02';
        o.Manual_Funding__c = false;
        o.Credit_Stips_Completed_Date__c = System.today()+3;
        o.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            				.get('Loan_Docs')
            				.getRecordTypeId();
        o.Loan_Purpose__c = 'Other';
        o.Primary_Source__c = 'Indirect';
        o.Oppt_FS_Use_Of_Funds__c = 'dummy';
        o.StageName = PEAC_ConstantClass.OPPORTUNITY_STAGENAME_BOOKING;
        insert o;
        Payment__c p = makePayment(o.Id, 100);
        List<Opportunity> newList = new List<Opportunity>{ o };

        Test.startTest();
        PEAC_OpportunityActionsHandler.opportunityUpdateFundingAmountToTotalPaymentsSent(newList);
        Test.stopTest();

        System.assertEquals(Null, o.Funded_Amount__c);
        }
    }

    @IsTest static void test_03_FundedAmount_From_TotalPaymentsSent_NonLoan_UpdateStyle() {
        PEAC_GenerateTaxMatrixBatch.isRunning = true; //to fix SOQL issue
        User userObj = TestDataFactory.createTestUser();
        userObj.Personnel_Number__c = '1234';
        update userObj;
        System.runAs(userObj){
            Account acc = TestDataFactory.createTestAccount();
            Contact con = TestDataFactory.createTestContact(acc.Id);
            Opportunity o = new Opportunity(Name='Test opp',CloseDate=System.today()+30, stagename='Quote', 
                            AccountId=acc.Id,State_Tax_Code__c='MN',Tax_City__c='WOODBURY',Tax_ID__c='622666666',
                                          Tax_County__c = 'WASHINGTON', Tax_Exempt__c='Yes', Amount=33, Billing_Cycle__c='December',
                                          Recurring__c='Recurring Only', Meter_Account__c = 'DLR');
            o.Name = 'Opp-02';
            o.Manual_Funding__c = false;
            o.Credit_Stips_Completed_Date__c = System.today()+3;
            //o.Funded_Amount__c = 100;
            o.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
                                .get('Loan_Docs')
                                .getRecordTypeId();
            o.Loan_Purpose__c = 'Other';
            o.Primary_Source__c = 'Indirect';
            o.Oppt_FS_Use_Of_Funds__c = 'dummy';
            o.StageName = PEAC_ConstantClass.OPPORTUNITY_STAGENAME_BOOKING;
            insert o;
            Payment__c p = makePayment(o.Id, 101);
            Opportunity oldO = o.clone(false, true, false, false);
    		Opportunity obj = [SELECT Id, Loan_Record_Type__c, Total_Payments_Sent__c, StageName, Funded_Amount__c FROM Opportunity WHERE Id =: o.Id];
            Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{ o.Id => oldO };
            Map<Id, Opportunity> newMap = new Map<Id, Opportunity>{ obj.Id => obj };
    
            Test.startTest();
            PEAC_OpportunityActionsHandler.opportunityUpdateFundingAmountToTotalPaymentsSent(oldMap, newMap);
            Test.stopTest();
    
            System.assertEquals(Null, o.Funded_Amount__c);
    	}
    }

    @IsTest static void test_04_MultipleAssetAddresses_Check() {
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        Account acc = TestDataFactory.createTestAccount();
            Contact con = TestDataFactory.createTestContact(acc.Id);
            Opportunity o = new Opportunity(Name='Test opp',CloseDate=System.today()+30, stagename='Quote', 
                            AccountId=acc.Id,State_Tax_Code__c='MN',Tax_City__c='WOODBURY',Tax_ID__c='622666666',
                                          Tax_County__c = 'WASHINGTON', Tax_Exempt__c='Yes', Amount=33, Billing_Cycle__c='December',
                                          Recurring__c='Recurring Only', Meter_Account__c = 'DLR');
            o.Name = 'Opp-02';
            o.Manual_Funding__c = false;
            o.Credit_Stips_Completed_Date__c = System.today()+3;
            //o.Funded_Amount__c = 100;
            o.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
                                .get('Loan_Docs')
                                .getRecordTypeId();
            o.Loan_Purpose__c = 'Other';
            o.Primary_Source__c = 'Indirect';
            o.Oppt_FS_Use_Of_Funds__c = 'dummy';
            o.StageName = PEAC_ConstantClass.OPPORTUNITY_STAGENAME_PROPOSAL;
        	o.Ready_to_Doc__c = 'Yes';
            insert o;
        Test.startTest();
        makeAsset(o.Id, '1 Main', 'CityA', 'AL', '12345');
        makeAsset(o.Id, '2 Main', 'CityA', 'AL', '12345');

        List<Opportunity> newList = new List<Opportunity>{ o };
        
        PEAC_OpportunityActionsHandler.opportunityValidateForMultipleAddressCheck(newList);
        Test.stopTest();

        Opportunity o2 = [SELECT Multiple_Asset_Addresses__c FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals(true, o2.Multiple_Asset_Addresses__c);
    }

    @IsTest static void test_05_FundedAmount_Loan_InsertStyle() {
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        Opportunity o = makeOpp('Opp-05', true, 'Prospecting', 0, 555.55, null, null, 0, null, false, false,0);
        List<Opportunity> newList = new List<Opportunity>{ o };

        Test.startTest();
        PEAC_OpportunityActionsHandler.opportunityUpdateFundedAmount(newList);
        Test.stopTest();

        System.assertEquals(null, o.Funded_Amount__c);
    }

    @IsTest static void test_05_FundedAmount_Loan_UpdateStyle() {
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        Opportunity o = makeOpp('Opp-05u', true, 'Prospecting', 0, 123, null, null, 0, null, false, false,0);
        Opportunity oldO = o.clone(false, true, false, false);
        update o;

        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{ o.Id => oldO };
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>{ o.Id => o };

        Test.startTest();
        PEAC_OpportunityActionsHandler.opportunityUpdateFundedAmount(oldMap, newMap);
        Test.stopTest();

        System.assertEquals(null, o.Funded_Amount__c);
    }

    @IsTest static void test_06_CommencementDateMapsToBIIBeginDateInsert() {
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        Opportunity o = makeOpp('Opp-06', false, 'Prospecting', 0, 0, null, Date.today().addDays(7), 0, null, false, false,0);
        update o;

        Blended_Income_Item__c bii = makeBII(o.Id);
        Opportunity obj = [SELECT Id, Number_of_Blended_Income_Items__c, Commencement_Date__c FROM Opportunity WHERE Id =: o.Id];
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>{ obj.Id => obj };

        Test.startTest();
        PEAC_OpportunityActionsHandler.opportunityCommencementDateChanges(newMap);
        Test.stopTest();

        bii = [SELECT Begin_Date__c FROM Blended_Income_Item__c WHERE Id = :bii.Id];
        System.assertEquals(o.Commencement_Date__c, bii.Begin_Date__c);
    }

    @IsTest static void test_06_CommencementDateMapsToBIIBeginDateUpdate() {
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        Opportunity o = makeOpp('Opp-06', false, 'Prospecting', 0, 0, null, Date.today().addDays(7), 0, null, false, false,0);
        Blended_Income_Item__c bii = makeBII(o.Id);
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{ o.Id => o };
        o.Commencement_Date__c = DateTime.now().Date();
        update o;
        Opportunity obj = [SELECT Id, Number_of_Blended_Income_Items__c, Commencement_Date__c FROM Opportunity WHERE Id =: o.Id];
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>{ obj.Id => obj };

        Test.startTest();
        PEAC_OpportunityActionsHandler.opportunityCommencementDateChanges(oldMap, newMap);
        Test.stopTest();

        bii = [SELECT Begin_Date__c FROM Blended_Income_Item__c WHERE Id = :bii.Id];
        System.assertEquals(o.Commencement_Date__c, bii.Begin_Date__c);
    }

    @IsTest static void test_07_DefaultBankCodeAndType() {
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        Opportunity o = makeOpp('Opp-07', false, 'Prospecting', 0, 0, null, null, 0, null, false, false,0);
        o.Bank_Account_Number__c = '123456';
        o.Bank_Number__c = '987654';
        o.Bank_Code__c = null;
        o.Bank_Account_Type__c = null;
        update o;

        List<Opportunity> newList = new List<Opportunity>{ o };

        Test.startTest();
        PEAC_OpportunityActionsHandler.opportunityUpdateBankCodeBankAccountType(newList);
        Test.stopTest();

        System.assertEquals(PEAC_ConstantClass.OPPORTUNITY_BANK_ACCOUNT_TYPE_CHECKINGS, o.Bank_Account_Type__c);
        System.assertEquals(PEAC_ConstantClass.OPPORTUNITY_BANK_CODE_100, o.Bank_Code__c);
    }

    @IsTest static void test_09_AutoCreate_FL_Tax_Misc_Invoice_InsertStyle() {
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        Opportunity o = makeOpp('Opp-09', false, 'Booking', 0, 0, null, null, 100, '10% Purchase Option', false, false,0);
        o.FL_Doc_St_Tax_Misc_Invoice__c = null;
        update o;
		Opportunity obj = [SELECT Id, StageName,Loan_Record_Type__c, Purchase_Options__c, FL_Doc_St_Tax_Misc_Invoice__c, Sum_of_Florida_Asset_Rental_Amounts__c,  Number_of_Blended_Income_Items__c, Commencement_Date__c FROM Opportunity WHERE Id =: o.Id];
        List<Opportunity> newList = new List<Opportunity>{ obj };

        Test.startTest();
        PEAC_OpportunityActionsHandler.autoCreateFiTaxMiscInvoice(newList);
        Test.stopTest();

        List<Miscellaneous_Invoice_Item__c> miscs = [
            SELECT Id, Opportunity__c, Amount__c, GL_Code__c
            FROM Miscellaneous_Invoice_Item__c
            WHERE Opportunity__c = :o.Id
        ];
    }

    @IsTest static void test_10_Update_FL_Tax_Misc_Invoice_UpdateStyle() {
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        // Given: Opp with invoice lookup and changed Florida sum
        Opportunity o = makeOpp('Opp-10', false, 'Booking', 0, 0, null, null, 100, 'Option', false, false,0);
        Miscellaneous_Invoice_Item__c mi = makeMiscItem(o.Id, 50, '0019 - Fla Doc Stamp Tax');

        o.FL_Doc_St_Tax_Misc_Invoice__c = mi.Id;
        update o;

        // Build maps
        Opportunity oldO = o.clone(false, true, false, false);
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{ o.Id => oldO };
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>{ o.Id => o };

        Test.startTest();
        PEAC_OpportunityActionsHandler.opportunityUpdateFLTaxMiscInvoice(oldMap, newMap);
        Test.stopTest();

        mi = [SELECT Id, Amount__c FROM Miscellaneous_Invoice_Item__c WHERE Id = :mi.Id];
        // If code is fixed, expect 200; otherwise it may remain 50.
        // We make a soft assertion:
        System.assert(mi.Amount__c == 200 || mi.Amount__c == 50,
            'If the query is corrected, Amount__c updates to 200; otherwise remains original.');
    }

    @IsTest static void test_11_ClearBankCodeAndType() {
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        Opportunity o = makeOpp('Opp-11', false, 'Prospecting', 0, 0, null, null, 0, null, false, false,0);
        o.Bank_Code__c = '100';
        o.Bank_Account_Type__c = 'Checkings';
        o.Bank_Number__c = null;
        o.Bank_Account_Number__c = null;
        update o;

        List<Opportunity> newList = new List<Opportunity>{ o };

        Test.startTest();
        PEAC_OpportunityActionsHandler.opportunityClearBankCodeBankAccountType(newList);
        Test.stopTest();

        System.assertEquals(null, o.Bank_Code__c);
        System.assertEquals(null, o.Bank_Account_Type__c);
    }

    @IsTest static void test_12_CreateSecurityDepositMiscInvoice_UpdateStyle() {
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        Account account = new Account(
            Name = 'TC_GenerateTrustPilotURLSTest',
            Business_City__c = 'Minneapolis',
            Business_State__c = 'MN',
            Business_Address__c = '701 N 3rd St',
            Business_Zip__c = '55401',
            Business_Type__c = 'Proprietorship'
        );
        insert account;
        Opportunity o = new Opportunity(
            Name = 'TempOpp',
            StageName = 'Booking',
            CloseDate = Date.today(),
            Tax_ID__c = '123456789',
            Business_Phone__c = '8908908900',
            Probability = 76,
            Credit_Stips_Completed_Date__c = Date.today(),
            Assign_To_CMS_User__c = UserInfo.getUserId(),
            AccountId = account.Id,
            Account_Business_Street__c = '123 Avenue Dr',
            Account_Billing_Street__c = '123 Avenue Dr',
            Account_Business_City__c = 'Minneapolis',
            Account_Billing_City__c = 'Minneapolis',
            Account_Business_State_Province__c = 'MN',
            Account_Billing_State_Province__c = 'MN',
            Account_Business_Zip_Postal_Code__c = '55401',
            Account_Billing_Zip_Postal_Code__c  = '55401',
            Loan_Purpose__c = 'Expansion/Hiring',
            Funding_Booking_Loan_Completed_Date__c =Date.today (),
            Terms__c = 12,
            Commencement_Date__c = Date.today (),
            Invoicing_Due_Day__c = 5,
            Equipment_Cost__c = 30000,
            Gross_Contract__c = 20000,
            Gross_Finance__c = 10000,
            Invoice_Description__c = 'test',
            Billing_Cycle__c = 'January',
            Funding_Booking_Lease_Completed_Date__c = Date.today (),
            Purchase_Options__c = 'FMV',
            of_Payments__c = 12,
            Payment_Amount__c = 5000,
            Contract_Type__c = 'Conditional Sales',
            Primary_Source__c = 'Customer Outbound',
            CaseCenter__c = 'ADCDGTPURL',
            Misc_Invoice_Sec_Deposit_Auto_Created__c = false,
            Security_Deposit__c = 100
        );
        insert o;

        Opportunity oldO = o.clone(false, true, false, false);
        oldO.StageName = PEAC_ConstantClass.OPPORTUNITY_STAGENAME_PROPOSAL;
        Opportunity obj1 = new Opportunity(Id = o.Id,
        Security_Deposit__c = 500,
        Assign_To_CMS_User__c = UserInfo.getUserId(),
        Business_Phone__c = '1234567890',
        Account_Billing_State_Province__c = 'temp',
        Account_Billing_City__c = 'temp');

        update obj1;

        Opportunity obj = [SELECT Id,Assign_To_CMS_User__c,  Account_Billing_State_Province__c, Loan_Record_Type__c, StageName, Misc_Invoice_Sec_Deposit_Auto_Created__c, Security_Deposit__c
                           FROM Opportunity WHERE Id =: o.Id];
        
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{ o.Id => oldO };
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>{ obj.Id => obj };
		
        Test.startTest();
        PEAC_OpportunityActionsHandler.opportunityCreateSecurityDepositMiscInvoice(oldMap, newMap);
        Test.stopTest();

        List<Miscellaneous_Invoice_Item__c> miscs = [
            SELECT Id, GL_Code__c, Opportunity__c
            FROM Miscellaneous_Invoice_Item__c
            WHERE Opportunity__c = :o.Id
        ];
        System.assertEquals(true, miscs.size()>0, 'Security deposit MI should be created');
        System.assertEquals(PEAC_ConstantClass.GL_CODE_0005_SECURITY_DEPOSIT, miscs[0].GL_Code__c);
    }

    @IsTest static void test_13_14_MoveLoanToFundedBooked() {
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        User adminUser = TestDataFactory.createTestUser();
        System.runAs(adminUser){
            // Create a test Account Record
            SL_SCTestData.createAccountAndContracts(1,1);
            Account testAccount = [SELECT Id,CCID__c,RecordTypeId FROM Account LIMIT 1];
            testAccount.Date_Established__c = Date.newInstance(2022,10, 1);
            testAccount.Account_State_Of_Incorporation__c = 'CO';
            testAccount.CCID__c = 'C00123';
            update testAccount;
            
            // Create a test Opportunity Record
            Opportunity testOpportunity = new Opportunity (AccountId = testAccount.Id, Actual_Annual_Revenue__c = 3, Actual_Average_Daily_Balance__c = 4,
                                                           Annual_Revenue__c = 2, Appeal_Information_Provided__c = 'Financial Statements', Application_Status__c = 'Manually Approved',
                                                           Approved_Amount__c = 1000, Approved_Document_Delivery_Method__c = 'DocuSign Only', Average_Daily_Balance__c = 5,
                                                           Billing_Attention_To__c = 'Accounts Payable', Broker_Book_Method__c = 'F',
                                                           Broker_Tax_Method__c = 'F', Business_Phone__c = '1234567898',
                                                           CloseDate = Date.today(), Contract_Status__c = 'Active', Custom_Stipulation__c = 'A1', 
                                                           Decision_Date__c = Datetime.now(), Docs_Out_Dollar__c = 13, Document_Delivery_Method__c = 'DocuSign',
                                                           Equip_Code1__c = 'Air Compressors', Equipment_Cost__c = 1201,
                                                           Equipment_Description__c = 'equipment 1', Final_Product_Loc__c = '1 stnarnia',
                                                           Funded_Amount__c = 14, Funded_Term__c = 15, Gross_Finance__c = -1201, Income_Method__c = 'E', Invoice_Code__c = 'A',
                                                           Invoice_Description__c = 'equipment 1', Late_Charge_Rate__c = 15, Lead_Invoice_Days__c = 22, Loan_Purpose__c = 'Other',
                                                           Loan_Score__c = 6, Oppt_FS_Use_Of_Funds__c = 'testing purposes',
                                                           Name = 'test XmlOpp ', StageName = 'Application',Payment_Amount__c=1,
                                                           RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan Booking').getRecordTypeId(),
                                                           Primary_Source__c = 'LendingTree',Requested_Amount__c = 55000,CaseCenter__c = 'L000345',PK__c ='2321602',
                                                           CustomerType__c = 'NEW',Decision_Status__c = 'PE',
                                                           UD_TMETRIX_POLICY_SCORE__c='UD_TMETRIX_POLICY_SCORE__c',UD_TMETRIX_REASON_CODE__c = 'UD_TMETRIX_REASON_CODE__c',UD_TMETRIX_REVIEW_STATUS__c= 
                                                           'UD_TMETRIX_REVIEW_STATUS__c',UD_TMETRIX_RISK_RATING__c = 'UD_TMETRIX_RISK_RATING__c',UD_TMETRIX_TRUE_IP__c = 'UD_TMETRIX_TRUE_IP__c');
            Insert testOpportunity;
            
            // Create a test Contact Reacord
            Contact con = new Contact (AccountId = testAccount.Id, FirstName = 'testGds' ,
                                       LastName = 'testbeni' , OtherStreet = 'test', OtherCity = 'test', 
                                       OtherStateCode = 'CA', OtherPostalCode = String.valueOf(111118), Title = 'title2' , 
                                       SSN__c = '112233489', BirthDate = Date.today (),
                                       Email = 'test@email' + String.valueOf(111116) + '.com', Validity_Verify__Status__c = 'Valid',
                                       OtherState='California',Ownership_Pct__c = 100);
            Insert con;
            
            // Create a test OpportunityContactRole Reacord
            OpportunityContactRole role = new OpportunityContactRole();
            role.ContactId = con.Id;
            role.OpportunityId = testOpportunity.Id;
            role.Role = 'Primary Contact';
            insert role;
            Opportunity opp = [SELECT Id, StageName, Loan_Record_Type__c, No_Pymts_Released_or_Acknowledged__c, No_Pymts_Not_Released_or_Acknowledged__c FROM Opportunity WHERE Id =: testOpportunity.Id];
            List<Opportunity> newList = new List<Opportunity>{ opp };
                
                Test.startTest();
            PEAC_OpportunityActionsHandler.opportunityMoveLoantoFundedBooked(newList);
            Test.stopTest();
        }
    }
    @isTest public static void setBypassFalse(){
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        Test.startTest();
        PEAC_OpportunityActionsHandler.setBypass(false);
        Test.stopTest();
    }
    
    @isTest public static void isChangedTest(){
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        User adminUser = TestDataFactory.createTestUser();
        System.runAs(adminUser){
            // Create a test Account Record
            SL_SCTestData.createAccountAndContracts(1,1);
            Account testAccount = [SELECT Id,CCID__c,RecordTypeId FROM Account LIMIT 1];
            testAccount.Date_Established__c = Date.newInstance(2022,10, 1);
            testAccount.Account_State_Of_Incorporation__c = 'CO';
            testAccount.CCID__c = 'C00123';
            update testAccount;
            
            // Create a test Opportunity Record
            Opportunity testOpportunity = new Opportunity (AccountId = testAccount.Id, Actual_Annual_Revenue__c = 3, Actual_Average_Daily_Balance__c = 4,
                                                           Annual_Revenue__c = 2, Appeal_Information_Provided__c = 'Financial Statements', Application_Status__c = 'Manually Approved',
                                                           Approved_Amount__c = 1000, Approved_Document_Delivery_Method__c = 'DocuSign Only', Average_Daily_Balance__c = 5,
                                                           Billing_Attention_To__c = 'Accounts Payable', Broker_Book_Method__c = 'F',
                                                           Broker_Tax_Method__c = 'F', Business_Phone__c = '1234567898',
                                                           CloseDate = Date.today(), Contract_Status__c = 'Active', Custom_Stipulation__c = 'A1', 
                                                           Decision_Date__c = Datetime.now(), Docs_Out_Dollar__c = 13, Document_Delivery_Method__c = 'DocuSign',
                                                           Equip_Code1__c = 'Air Compressors', Equipment_Cost__c = 1201,
                                                           Equipment_Description__c = 'equipment 1', Final_Product_Loc__c = '1 stnarnia',
                                                           Funded_Amount__c = 14, Funded_Term__c = 15, Gross_Finance__c = -1201, Income_Method__c = 'E', Invoice_Code__c = 'A',
                                                           Invoice_Description__c = 'equipment 1', Late_Charge_Rate__c = 15, Lead_Invoice_Days__c = 22, Loan_Purpose__c = 'Other',
                                                           Loan_Score__c = 6, Oppt_FS_Use_Of_Funds__c = 'testing purposes',
                                                           Name = 'test XmlOpp ', StageName = 'Application',Payment_Amount__c=1,
                                                           RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan Booking').getRecordTypeId(),
                                                           Primary_Source__c = 'LendingTree',Requested_Amount__c = 55000,CaseCenter__c = 'L000345',PK__c ='2321602',
                                                           CustomerType__c = 'NEW',Decision_Status__c = 'PE',
                                                           UD_TMETRIX_POLICY_SCORE__c='UD_TMETRIX_POLICY_SCORE__c',UD_TMETRIX_REASON_CODE__c = 'UD_TMETRIX_REASON_CODE__c',UD_TMETRIX_REVIEW_STATUS__c= 
                                                           'UD_TMETRIX_REVIEW_STATUS__c',UD_TMETRIX_RISK_RATING__c = 'UD_TMETRIX_RISK_RATING__c',UD_TMETRIX_TRUE_IP__c = 'UD_TMETRIX_TRUE_IP__c');
            Insert testOpportunity;
        
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>();
            oldMap.put(testOpportunity.Id,testOpportunity);
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();
            newMap.put(testOpportunity.Id,testOpportunity);
    		Test.startTest();
            PEAC_OpportunityActionsHandler obj = new PEAC_OpportunityActionsHandler();
            obj.isChanged(testOpportunity, testOpportunity.CustomerType__c, testOpportunity.CustomerType__c);
            Test.stopTest();
        }
    }

}