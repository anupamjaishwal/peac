@isTest
public class PEAC_TestDataFactory {

    public static final String ONBASE_FAKE_RESPONSE_JSON = '{"DocPopUrl": "http://testsite.com/file/001.log"}';
    public static final String ONBASE_FAKE_RESPONSE_JSON_KEYWORDS = '"[{\"Id\":58,\"Name\":\"Application #\",\"CurrentValue\":null,\"UpdatedValue\":null,\"DataType\":\"Numeric9\",\"DataLength\":9,\"KeyGroupName\":null},{\"Id\":54,\"Name\":\"CCAN #\",\"CurrentValue\":null,\"UpdatedValue\":null,\"DataType\":\"Numeric9\",\"DataLength\":9,\"KeyGroupName\":null},{\"Id\":1,\"Name\":\"Name\",\"CurrentValue\":null,\"UpdatedValue\":null,\"DataType\":\"AlphaNumeric\",\"DataLength\":50,\"KeyGroupName\":null},{\"Id\":102,\"Name\":\"Contract #\",\"CurrentValue\":null,\"UpdatedValue\":null,\"DataType\":\"AlphaNumeric\",\"DataLength\":15,\"KeyGroupName\":null},{\"Id\":14,\"Name\":\"Booking Date\",\"CurrentValue\":null,\"UpdatedValue\":null,\"DataType\":\"Date\",\"DataLength\":27,\"KeyGroupName\":null},{\"Id\":53,\"Name\":\"Lease Amount\",\"CurrentValue\":null,\"UpdatedValue\":null,\"DataType\":\"Currency\",\"DataLength\":22,\"KeyGroupName\":null},{\"Id\":104,\"Name\":\"Dealer #\",\"CurrentValue\":null,\"UpdatedValue\":null,\"DataType\":\"AlphaNumeric\",\"DataLength\":10,\"KeyGroupName\":null},{\"Id\":109,\"Name\":\"DBA Name\",\"CurrentValue\":null,\"UpdatedValue\":null,\"DataType\":\"AlphaNumeric\",\"DataLength\":150,\"KeyGroupName\":null},{\"Id\":110,\"Name\":\"Fed ID #\",\"CurrentValue\":null,\"UpdatedValue\":null,\"DataType\":\"AlphaNumeric\",\"DataLength\":40,\"KeyGroupName\":null},{\"Id\":111,\"Name\":\"Status\",\"CurrentValue\":null,\"UpdatedValue\":null,\"DataType\":\"AlphaNumeric\",\"DataLength\":30,\"KeyGroupName\":null},{\"Id\":108,\"Name\":\"Submission Date\",\"CurrentValue\":null,\"UpdatedValue\":null,\"DataType\":\"Date\",\"DataLength\":27,\"KeyGroupName\":null}]"';
    public static final String FAKE_RESPONSE_JSON_DEFAULT = '{"Id":58,"Name":"Application #","CurrentValue":null,"UpdatedValue":null,"DataType":"Numeric9","DataLength":9,"KeyGroupName":null}';
    public static User testUser = null;
    public static List<Account> testAccounts = new List<Account>();
    public static List<Contact> testContacts = new List<Contact>();
    public static List<Contract__c> testContracts = new List<Contract__c>();
    public static List<Contract_Attachment__c> testCAttachments = new List<Contract_Attachment__c>();
    public static List<Opportunity> testOpportunities = new List<Opportunity>();
    public static List<Asset__c> testAssets = new List<Asset__c>();
    public static List<Insurance__c> testInsurances = new List<Insurance__c>();
    public static List<Contract_Asset__c> testCAssets = new List<Contract_Asset__c>();
    public static List<Invoice__c> testInvoices = new List<Invoice__c>();
    public static Datetime testNow;
    public static final Id DEALER_ACC = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer_Vendor').getRecordTypeId();
    public static Id dealerAccountId;
    public static final String OEG_DEALER_PROFILE = 'OEG Dealer';
    public static final String MANUFACTURER_NAME = 'Testing Manufacturer';
    public static Id manufacturerId = null;
    public static Id servicesAdminId = null;
    public static Id testDupeId = null;

    public static List<Opportunity> createOpportunities(Id accountId, Integer numberOfOpportunities){
        List<Opportunity> opps = new List<Opportunity>();
        for(Integer i = 1; i <=numberOfOpportunities; i++){
            Opportunity opp = new Opportunity (AccountId = accountId, Actual_Annual_Revenue__c = 3, Actual_Average_Daily_Balance__c = 4,
                                               Annual_Revenue__c = 2, Appeal_Information_Provided__c = 'Additional Bank Reference', Application_Status__c = 'Manually Approved',
                                               Approved_Amount__c = 1000, Approved_Document_Delivery_Method__c = 'DocuSign Only', Average_Daily_Balance__c = 5,
                                               Billing_Attention_To__c = 'Accounts Payable', Broker_Book_Method__c = 'F',
                                               Broker_Tax_Method__c = 'F', Business_Phone__c = '1234567898', CaseCenter__c = '321' + i,
                                               CloseDate = Date.today(), Contract_Status__c = 'Active', Custom_Stipulation__c = 'A1', 
                                               Decision_Date__c = Datetime.now(), Docs_Out_Dollar__c = 13, Document_Delivery_Method__c = 'DocuSign',
                                               Equip_Code1__c = 'Air Compressors', Equipment_Cost__c = 1201,
                                               Equipment_Description__c = 'equipment 1', Final_Product_Loc__c = '1 stnarnia',
                                               Funded_Amount__c = 14, Funded_Term__c = 15, Gross_Finance__c = -1201, Income_Method__c = 'E', Invoice_Code__c = 'A',
                                               Invoice_Description__c = 'equipment 1', Late_Charge_Rate__c = 15, Lead_Invoice_Days__c = 22, Loan_Purpose__c = 'Other',
                                               Loan_Score__c = 6, Oppt_FS_Use_Of_Funds__c = 'testing purposes',
                                               Name = 'test Opp ' + i, StageName = 'Application',Payment_Amount__c=1,
                                               RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('CVG Booking').getRecordTypeId(),
                                               Primary_Source__c = 'LendingTree');
            opps.add(opp);
        }
        insert opps;
        testOpportunities = opps;
        return opps;
    }
    
    public static List<Asset__c> createAssets(Id accountId, List<Opportunity> opps, Integer numberOfAssetsPerOpp){
        List<Asset__c> assets = new List<Asset__c>();
        for(Integer i = 0; i <opps.size(); i++){
            for(Integer j = 1; j <=numberOfAssetsPerOpp; j++){
                String textIndex = String.valueOf(j);
                Asset__c asset = new Asset__c (Opportunity__c = opps[i].Id, List_Price__c = 3000,
                                               Description__c = 'test asset desc ' + textIndex, Quantity__c = 1,
                                               Equipment_Code__c = 'ATM', Property_Status__c = '11', County_Tax_Code__c = '001',
                                               State_Tax_Code__c = '001', City_Tax_Code__c = '001', Equipment_Street__c = '1 st', 
                                               Equipment_City__c = 'narnia ' + textIndex, Equipment_State__c = 'CO', Equipment_Zip__c = '03210',
                                               Equipment_Location_City__c = 'city ' + textIndex, Equipment_Location_County__c = 'test county',
                                               Equipment_Location_State__c = 'COLORADO', Manufacturer__c = manufacturerId );//SAL-4968
                //Equipment_Location_State__c = 'COLORADO' );
                assets.add(asset);
            }
        }
        insert assets;
        return assets;
    }
    
    public static List<Account> createAccount(Integer numberOfAccount) {
        //User u = SL_SCTestData.createTestUser();
        User u = createTestUser(null, false);
        SL_SCTestData.createContractCriteria(u);
        SL_SCTestData.createBridgeWareSetting();
        SL_SCTestData.createFieldTrackUserExclusion();
        System.debug('Number of SOQL queries used: ' + Limits.getQueries());
        Test.setMock(HttpCalloutMock.class, new TC_BWcreateCustomerCalloutMockImpl ());
        
        Campaign testCampaign = new Campaign(Name = 'Customer', isActive = true);
        insert testCampaign;
        System.debug('Number of SOQL queries used: ' + Limits.getQueries());
        Integer existingAccounts = testAccounts.size();
        List<Account> accounts = new List<Account>();
        for(Integer i = 1; i <=numberOfAccount; i++){
            Integer n = existingAccounts + i;
            Account acc = new Account (Name = (String.valueOf(n) + ' test Customer'), 
                                       RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId(),
                                       Business_Phone__c = String.valueOf(1234567890 + n).left(10), tax_ID__c = String.valueOf(111000000 + n),
                                       Dealer_Number__c = String.valueOf(111000000 + n).left(18), CCID__c = String.valueOf(1234567890 + n).right(7),
                                       CCAN__c = String.valueOf(1234567890 + n).right(10), Account_EU_FS_SIC_Description__c = '0100',
                                       Business_Address__c = '03210239 test str', Account_Billing_Street__c = '03210239 test str',
                                       Business_City__c = '03210239 test city', Account_Billing_City__c = '03210239 test city',
                                       Business_State__c = 'CO', Account_Billing_State_Province__c = 'CO',
                                       Business_Zip__c = '03210', Account_Billing_Zip_Postal_Code__c = '03210', CurrentCampaign__c = testCampaign.Id);
            accounts.add(acc);
        }
        insert accounts;
        testAccounts.addAll(accounts);
        System.debug('Number of SOQL queries used: ' + Limits.getQueries());
        return testAccounts;
    }

    public static List<Contact> createContacts(List<Account> accounts, Integer numberOfContact) {
        List<Contact> contacts = new List<Contact>();
        for(Integer k=0; k< accounts.size(); k++){
            for(Integer i = 0; i <numberOfContact; i++){
                Integer uniqueNumber = i;
                Contact c = new Contact (AccountId = accounts[i].Id, FirstName = 'test' + uniqueNumber,
                                         LastName = 'testbeni' + uniqueNumber, OtherStreet = 'test', OtherCity = 'test', 
                                         OtherStateCode = 'MN', OtherPostalCode = String.valueOf(11111 + uniqueNumber).left(5), Title = 'title' + uniqueNumber, 
                                         SSN__c = String.valueOf(111111111 + uniqueNumber).left(9), BirthDate = Date.today (),
                                         Email = 'test@email' + String.valueOf(11111 + uniqueNumber) + '.com', Validity_Verify__Status__c = 'Valid',
                                         Phone = String.valueOf(1111111111 + uniqueNumber).right(10));
                contacts.add(c);
            }
        }
        insert contacts;
        return contacts;
    }

    public static List<Contract__c> createContract(List<Account> accounts, Integer numberOfContracts) {
        List<Contract__c> contracts = new List<Contract__c>();
        for(Integer k=0; k< accounts.size(); k++){
            for(Integer j = 0; j <=numberOfContracts; j++){
                Integer IntrandomNumber = Integer.valueof((Math.random() * 10000000));
                Integer n =  j;
                Contract__c contract = new Contract__c (Customer__c = accounts[j].Id, Status__c = 'Active', Is_Active__c = true,
                                                        Name = '401-' + String.valueOf(IntrandomNumber).right(7) + '-' + String.valueOf(n).right(3), application_number__c = '1234567890',
                                                        Delinquency_Status_Code__c = '00', Infolease_Environment__c = '10');
                contracts.add(contract);
            }
        }
        insert contracts;
        return contracts;
    }
 
    public static Contract_Criteria__c createContractCriteria(User u){
        Contract_Criteria__c contractCriteria = Contract_Criteria__c.getOrgDefaults();
        if(contractCriteria.Default_Agent_Id__c == null){
            contractCriteria = new Contract_Criteria__c(Maximum_Balance_CBR__c = 1200, Maximum_CBR_XBS_ADR__c=1200, Default_Agent_Id__c = u.Id);
            insert contractCriteria;
        }
        return contractCriteria;
    }

    public static User createTestUser(Id customProfileId, Boolean createUserOrNot){
            Id profileId = null;
            if(customProfileId == null){
                Profile p = [SELECT Id FROM Profile WHERE Name = 'Services Admin'];
                profileId = p.Id;
                servicesAdminId = p.Id;
            }else{
                profileId = customProfileId;
            }
            User u = new User(Alias = 'testuser', Email = 'marlinbusiness@peacsolutions.com', EmailEncodingKey='UTF-8',
                    LastName = 'testing', FirstName = 'user', LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US', ProfileId = profileId, TimeZoneSidKey = 'America/Los_Angeles',
                    Username = 'service.admin.test.user@silverlinecrm.com', Doc_Fee_Exception_Approver__c = true,
                    Personnel_Number__c = '0321');
            insert u;
        return u;
    }

      public static void createAccountAndContracts(Integer numberOfAccount, Integer numberOfContracts) {
        User u = createTestUser(null, false);
          SL_SCTestData.testUser = u;
        System.runAs(u){
            SL_SCTestData.createContractCriteria(u);
            SL_SCTestData.createBridgeWareSetting();
            SL_SCTestData.createFieldTrackUserExclusion();
            
            Test.setMock(HttpCalloutMock.class, new TC_BWcreateCustomerCalloutMockImpl ());

            Campaign testCampaign = new Campaign(Name = 'Customer', isActive = true);
            insert testCampaign;
            Integer existingAccounts = testAccounts.size();
            List<Account> accounts = new List<Account>();
            Id endUserId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
            for(Integer i = 1; i <=numberOfAccount; i++){
                Integer n = existingAccounts + i;
                accounts.add(prepareAccount(n, endUserId, testCampaign.Id));
            }
            insert accounts;
            SL_SCTestData.testAccounts.addAll(accounts);

            Integer existingContracts = testContracts.size();
            Integer existingContacts = testContacts.size();
            List<Contact> contacts = new List<Contact>();
            List<Contract__c> contracts = new List<Contract__c>();
            for(Integer i = 0; i <numberOfAccount; i++){
                Integer uniqueNumber = existingContacts + i;
                contacts.add(prepareContact(uniqueNumber, accounts[i].Id));

                for(Integer j = 1; j <=numberOfContracts; j++){
                    Integer IntrandomNumber = Integer.valueof((Math.random() * 10000000));
                    Integer n = existingContracts + i + j;
                    Contract__c contract = new Contract__c (Customer__c = accounts[i].Id, Status__c = 'Active', Is_Active__c = true,
                        Name = '401-' + String.valueOf(IntrandomNumber).right(7) + '-' + String.valueOf(n).right(3), application_number__c = '1234567890',
                        Delinquency_Status_Code__c = '00', Infolease_Environment__c = '10');
                    contracts.add(contract);
                }
            }
            insert contacts;
            testContacts.addAll(contacts);
            insert contracts;
            testContracts.addAll(contracts);
        }
    }

    public static void createAccountAndContractsWithoutUser(Integer numberOfAccount, Integer numberOfContracts, User u) {
        SL_SCTestData.createContractCriteria(u);
        SL_SCTestData.createBridgeWareSetting();
        SL_SCTestData.createFieldTrackUserExclusion();
        
        Test.setMock(HttpCalloutMock.class, new TC_BWcreateCustomerCalloutMockImpl ());
        
        Campaign testCampaign = new Campaign(Name = 'Customer', isActive = true);
        insert testCampaign;
        Integer existingAccounts = testAccounts.size();
        List<Account> accounts = new List<Account>();
        Id endUserId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
        for(Integer i = 1; i <=numberOfAccount; i++){
            Integer n = existingAccounts + i;
            accounts.add(prepareAccount(n, endUserId, testCampaign.Id));
        }
        insert accounts;
        SL_SCTestData.testAccounts.addAll(accounts);
        
        Integer existingContracts = testContracts.size();
        Integer existingContacts = testContacts.size();
        List<Contact> contacts = new List<Contact>();
        List<Contract__c> contracts = new List<Contract__c>();
        for(Integer i = 0; i <numberOfAccount; i++){
            Integer uniqueNumber = existingContacts + i;
            contacts.add(prepareContact(uniqueNumber, accounts[i].Id));
            
            for(Integer j = 1; j <=numberOfContracts; j++){
                Integer IntrandomNumber = Integer.valueof((Math.random() * 10000000));
                Integer n = existingContracts + i + j;
                Contract__c contract = new Contract__c (Customer__c = accounts[i].Id, Status__c = 'Active', Is_Active__c = true,
                                                        Name = '401-' + String.valueOf(IntrandomNumber).right(7) + '-' + String.valueOf(n).right(3), application_number__c = '1234567890',
                                                        Delinquency_Status_Code__c = '00', Infolease_Environment__c = '10');
                contracts.add(contract);
            }
        }
        insert contacts;
        testContacts.addAll(contacts);
        insert contracts;
        testContracts.addAll(contracts);
    }
	

    public static void createBridgeWareSetting(){
        List<Bridgeware_Service_Setting__c> existingBWSettings = [SELECT Id FROM Bridgeware_Service_Setting__c];
        if(existingBWSettings.size() == 0){
            Bridgeware_Service_Setting__c setting = new Bridgeware_Service_Setting__c();
            setting.Enable_Debug_Log__c = true;
            setting.Mock_Callout__c = true;
            setting.Mock_Endpoint__c = 'https://private-b2bb6-bridgewaretamarack.apiary-mock.com/';
            setting.SetupOwnerId = UserInfo.getOrganizationId ();
            setting.Config_Name__c = 'TEST';
            setting.Mock_Callout_createCustomer__c = 'https://private-b2bb6-bridgewaretamarack.apiary-mock.com/';
            setting.IL10_Url__c = 'https://devbwapi.marlincorp.com:9191/IL10BWUAT/subroutine/NITRO.API.INTERPRETER';
            setting.IL10_Username__c = 'testUser';
            setting.IL10_Password__c = 'testPass';
            setting.IL10_Uci_Url__c = 'https://devbwapi.marlincorp.com:9191/IL10_DB_ACCT/subroutine/BW.INSERT.UCI.CONTRACT';
            setting.IL10_Zip_Url__c = 'https://devbwapi.marlincorp.com:9191/IL10_DB_ACCT/subroutine/BW.SELECT.ZIP.GEO.CODE';
            setting.IL9_Osg_Url__c = 'https://MarlinBillPayCSR.osgtest.com';
            setting.IL10_Osg_Url__c = 'https://paymentsconnect.csruat.billbridge.com';
            setting.IL10_Osg_ApiKey__c = 'EV-8P8mSNatFCmu49nI8L0ZgmGoI11ck';
            insert setting;
        }
        createIL10FlagSetting();
    }

   
    public static void createIL10FlagSetting(){
        List<IL10_Flag__c> existingBWSettings = [SELECT Id FROM IL10_Flag__c];
        if(existingBWSettings.size() == 0){
            IL10_Flag__c setting = new IL10_Flag__c ();
            setting.Name = 'GeneralSetting';
            setting.use_IL10__c = true;
            insert setting;
        }
    }
    public static Account prepareAccount(Integer n, Id recordTypeId, Id campaignId){
        Account acc = new Account (Name = (String.valueOf(n) + ' test Customer'), RecordTypeId = recordTypeId,
            Business_Phone__c = String.valueOf(1234567890 + n).left(10), tax_ID__c = String.valueOf(111000000 + n),
            CCID__c = String.valueOf(1234567890 + n).right(7), CCAN__c = String.valueOf(1234567890 + n).right(10), 
            Account_EU_FS_SIC_Description__c = '0100', Business_Address__c = '03210239 test str', Account_Billing_Street__c = '03210239 test str',
            Business_City__c = '03210239 test city', Account_Billing_City__c = '03210239 test city',
            Business_State__c = 'CO', Account_Billing_State_Province__c = 'CO', Business_Zip__c = '03210', 
            Account_Billing_Zip_Postal_Code__c = '03210', CurrentCampaign__c = campaignId, 
            Dealer_Number__c = '040105.' + String.valueOf(1000 + n).right(4));
        return acc;
    }
    public static Contact prepareContact(Integer uniqueNumber, Id accountId){
        Contact c = new Contact (AccountId = accountId, FirstName = 'test' + uniqueNumber,
                 LastName = 'testbeni' + uniqueNumber, OtherStreet = 'test', OtherCity = 'test', 
                 OtherStateCode = 'MN', OtherPostalCode = String.valueOf(11111 + uniqueNumber).left(5), Title = 'title' + uniqueNumber, 
                 SSN__c = String.valueOf(111111111 + uniqueNumber).left(9), BirthDate = Date.today (),
                 Email = 'test@email' + String.valueOf(11111 + uniqueNumber) + '.com', Validity_Verify__Status__c = 'Valid',
                 Phone = String.valueOf(1111111111 + uniqueNumber).right(10));
        return c;
    }
}