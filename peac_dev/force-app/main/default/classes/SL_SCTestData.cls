@isTest
public class SL_SCTestData {
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

    public static User createTestUser(){
        return SL_SCTestData.createTestUser(null);
    }

    public static User createTestUser(Id customProfileId){
        if(SL_SCTestData.testUser == null){
            User u1 = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
            System.runAs(u1){
                SL_Trigger.getConfiguration();
            }
            Id profileId = null;
            if(customProfileId == null){
                Profile p = [SELECT Id FROM Profile WHERE Name = 'Services Admin'];
                profileId = p.Id;
                servicesAdminId = p.Id;
            }else{
                profileId = customProfileId;
            }
            Id roleId = [SELECT Id FROM UserRole WHERE DeveloperName ='System_Admin'].Id;
            User u = new User(Alias = 'testuser', Email = 'marlinbusiness@peacsolutions.com', EmailEncodingKey='UTF-8',
                    LastName = 'testing', FirstName = 'user', LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US', ProfileId = profileId, UserRoleId = roleId, TimeZoneSidKey = 'America/Los_Angeles',
                    Username = 'service.admin.test.user@silverlinecrm.com', Doc_Fee_Exception_Approver__c = true,
                    Personnel_Number__c = '0321');
            insert u;
            SL_SCTestData.testUser = u;
        }
        return SL_SCTestData.testUser;
    }

    public static User createExtraUser(Id customProfileId){
        Id profileId = null;
        if(customProfileId == null){
            if(servicesAdminId == null){
                Profile p = [SELECT Id FROM Profile WHERE Name = 'Services Admin'];
                servicesAdminId = p.Id;
            }
            profileId = servicesAdminId;
        }else{
            profileId = customProfileId;
        }
        String uniqueNumber = String.valueOf(System.currentTimeMillis());
        User u = new User(Alias = 'testuser', Email = 'marlinbusiness@peacsolutions.com', EmailEncodingKey='UTF-8',
                LastName = 'testing', FirstName = 'user', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = profileId, TimeZoneSidKey = 'America/Los_Angeles',
                Username = 'service.admin.test.user' + uniqueNumber + '@silverlinecrm.com', Doc_Fee_Exception_Approver__c = true,
                Personnel_Number__c = '0321');
        insert u;
        return u;
    }

    public static User createDPUser(Id accId){
        Profile portalProfileCTI = [SELECT Id, UserLicense.Name
            FROM Profile WHERE Name = 'CT&I Dealer' AND UserLicense.Name = 'Partner Community' LIMIT 1];
        User u = SL_SCTestData.testUser;
        u.Id = null;
        u.Email = 'test.partner.user.upsertContactForApp@email.box';
        u.Username = 'test.partner.user.upsertContactForApp20230817@email.box';
        u.ProfileId = portalProfileCTI.Id;
        u.CommunityNickname = 'upsertContactForApp20230817';
        u.ContactId = SL_SCTestData.testContacts[0].Id;
        Id userId = Site.createExternalUser(u, accId);// it is null, currently it doesn't actually create it
        u.Id = userId;
        return u;
    }

    public static void createBridgeWareSetting(){
        if(testUser != null){
            System.runAs(testUser){
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
        }
    }

    public static void createFieldTrackUserExclusion(){// SAL-5468
        insert new List<ExcludeUsersFromFieldTracking__c>{
            new ExcludeUsersFromFieldTracking__c(Type__c = 'Profile', Name = 'System Administrator'),
            new ExcludeUsersFromFieldTracking__c(Type__c = 'Profile', Name = 'Services Admin')
        };
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

    public static void createTaxRulesSetting() {
        Tax_Rules_Settings__c settings = Tax_Rules_Settings__c.getOrgDefaults();
        if(settings.Id == null){
            settings = new Tax_Rules_Settings__c();
            settings.Parent_Object__c = 'Opportunity';
            settings.Rate_Object__c = 'Rate__c';
            settings.Rate_State_Field__c = 'State__c';
            settings.Rate_County_Field__c = 'County__c';
            settings.Rate_City_Field__c = 'City__c';
            settings.Rate_Code_Field__c = 'Rate_Code__c';
            settings.State_Tax_Rate_Field__c = 'State_Tax_Rate__c';
            settings.County_Tax_Rate_Field__c = 'County_Tax_Rate__c';
            settings.TCounty_Tax_Rate_Field__c = 'County_Transit_Tax_Rate__c';
            settings.City_Tax_Rate_Field__c = 'City_Tax_Rate__c';
            settings.TCity_Tax_Rate_Field__c = 'City_Transit_Tax_Rate__c';
            settings.Tax_Parent_Object_Field__c = 'Opportunity__c';
            settings.Parent_Generate_Tax_Matrix_Message_Field__c = 'Description';
            settings.Parent_Tax_Calculation_Begin_Field__c = 'Last_Tax_Calculation_Begin__c';
            settings.Parent_Tax_Calculation_Complete_Field__c = 'Last_Tax_Calculation_Complete__c';
            settings.Parent_Tax_Calculation_Successful_Field__c = 'Last_Tax_Calculation_Successful__c';
            settings.Parent_Tax_Calculation_Error_Field__c = 'Last_Tax_Calculation_Error_Details__c';
            settings.Parent_Tax_Calculation_In_Progress_Field__c = 'Is_Tax_Calculation_In_Progress__c';
            settings.Tax_Calculation_Completion_Alert_Seconds__c = 90;
            insert settings;
        }
    }

    public static void createDnBCredentials(){
        DnB_Credentials__c existingDnBCredentials = DnB_Credentials__c.getOrgDefaults();
        if(existingDnBCredentials == null){
            DnB_Credentials__c setting = new DnB_Credentials__c();
            setting.Consumer_Key__c = 'testConsumerKey';
            setting.Consumer_Secret__c = 'testConsumerSecret';
            setting.URL__c = 'https://plus.dnb.com/';
            insert setting;
        }
    }

    public static void createOnBaseCredentials(){
        OnBase_Credentials__c existingOnBaseCredentials = OnBase_Credentials__c.getOrgDefaults();
        system.debug('existingOnBaseCredentials null?: ' + existingOnBaseCredentials == null);
        
        // if(existingOnBaseCredentials == null){
            system.debug('Add_Document__c: ' + existingOnBaseCredentials.Add_Document__c);
            insert new OnBase_Credentials__c (Add_Document__c = 'test'
            , App_Server_Url__c = 'test' , Data_Source__c = 'tet' , Gateway_Url__c = 'test'
            , Initialization_Vector__c = '123456789asdfghj' , Password__c = 'te'
            , Secret_Key__c = '123456789asdfghj123456789asdfghj', Username__c = 'test',
            Retrieve_Documents__c = '/api/customquery/documents', Keywords_For_DocTypes__c = '/api/documenttypes/keywords');
        // }
    }

    public static void createContractCriteria(User u){
        Contract_Criteria__c contractCriteria = Contract_Criteria__c.getOrgDefaults();
        if(contractCriteria.Default_Agent_Id__c == null){
            System.runAs(u){
                insert new Contract_Criteria__c(Maximum_Balance_CBR__c = 1200, Maximum_CBR_XBS_ADR__c=1200, Default_Agent_Id__c = u.Id);
            }
        }
    }

    public static void createAccountAndContracts(Integer numberOfAccount, Integer numberOfContracts) {
        User u = createTestUser();
        System.runAs(u){
            createContractCriteria(u);
            createBridgeWareSetting();
            createFieldTrackUserExclusion();
            
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
            testAccounts.addAll(accounts);

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

    public static void createInsurancesAndContractAssets(Integer numberOfInsurances, Integer numberOfContractAssets) {
        List<Contract__c> contracts = testContracts;
        if(contracts.size() > 0){
            System.runAs(testUser){
                List<Insurance__c> insurances = new List<Insurance__c>();
                for(Integer i = 0; i <numberOfInsurances; i++){
                    // it has autonumber
                    Insurance__c ins = new Insurance__c (Titled_Vehicles__c = false, Insurance_Id__c = contracts[i].Name + '*001',
                        Infolease_Environment__c = '10');
                    insurances.add(ins);
                }
                insert insurances;
                testInsurances = insurances;
                
                List<Contract_Asset__c> assets = new List<Contract_Asset__c>();
                for(Integer i = 0; i <numberOfInsurances; i++){
                    
                    for(Integer j = 1; j <=numberOfContractAssets; j++){
                        Contract_Asset__c asset = new Contract_Asset__c (Insurance__c = insurances[i].Id,
                            Contract__c = contracts[i].Id, Asset_Number__c = '08260318' + String.valueOf(i) + String.valueOf(j),
                            Asset_Cost__c = 430);
                        assets.add(asset);
                    }
                }
                insert assets;
                testCAssets = assets;
            }
        }
    }

    public static void updateCAssetsWithLocation(Integer numberOfLocations, Integer contractAssetStartIndex){
        System.runAs(testUser){
            String ServProvRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Service Provider').getRecordTypeId();
            List<Schema.Location> locations = new List<Schema.Location>();
            for(Integer i = 0; i <numberOfLocations; i++){
                testAccounts[i].Name = 'Service Provider ' + String.valueOf(i);
                testAccounts[i].RecordTypeId = ServProvRecordTypeID;
                testAccounts[i].Waiting_To_Be_Sent_To_Bridgeware__c = true;
                Schema.Location location1 = new Schema.Location(Name = 'Location ' + String.valueOf(i), Service_Provider__c = testAccounts[i].Id,
                    Is_Active__c = true, Address_1__c = '04300620 test street ' + String.valueOf(i), City__c = 'Test City ' + String.valueOf(i),
                    State__c = 'AZ', Zip__c = '4300' + String.valueOf(i));
                locations.add(location1);
            }
            update testAccounts;
            insert locations;
            for(Integer i = 0; i <numberOfLocations; i++){
                testCAssets[i + contractAssetStartIndex].Location__c = locations[i].Id;
            }
            update testCAssets;
        }
    }

    public static List<County__c> createCounties(){
        
        List<County__c> testCounties = new List<County__c>{
            new County__c(Name = 'Tulare County', State__c = 'CA'),
            new County__c(Name = 'Yolo County', State__c = 'CA'),
            new County__c(Name = 'Apache County', State__c = 'AZ'),
            new County__c(Name = 'Graham County', State__c = 'AZ')
        };
        System.runAs(testUser){
            insert testCounties;
        }
        return testCounties;        
    }

    public static void createInvoices(Id customerId, Id contractId, Integer numberOfInvoices, Boolean isMigrated) {
        List<Contract__c> contracts = testContracts;
        System.runAs(testUser){
            List<Invoice__c> invoices = new List<Invoice__c>();
            for(Integer j = 1; j <=numberOfInvoices; j++){
                Invoice__c theInvoice = new Invoice__c (Customer__c = customerId, Contract__c = contractId,
                    Name = '08260318' + String.valueOf(j), Migrated__c = (isMigrated? '001': null));
                invoices.add(theInvoice);
            }
            insert invoices;
            testInvoices = invoices;
        }
    }

    public static void createContractAttachment(Id contractId){
        System.runAs(testUser){
            Contract_Attachment__c catt = new Contract_Attachment__c(Name = '', 
                Type_Group__c = 'Titled Vehicles', Type__c = 'Title',
                Status__c = 'Booked', Contract__c = contractId);
            insert catt;
            testCAttachments.add(catt);
        }
    }

    public static List<Opportunity> createOpportunities(Id accountId, Integer numberOfOpportunities){
        List<Opportunity> opps = new List<Opportunity>();
        System.runAs(testUser){
            if(testOpportunities.size() == 0){
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
            }else{
                opps = testOpportunities;
            }
        }
        return opps;
    }
    public static void createOpportunitiesAndAssets(Id accountId, Integer numberOfOpportunities, Integer numberOfAssets){
        if(testOpportunities.size() == 0){
            List<Opportunity> opps = createOpportunities(accountId, numberOfOpportunities);
            List<Asset__c> assets = new List<Asset__c>();
            for(Integer i = 0; i <numberOfOpportunities; i++){
                
                for(Integer j = 1; j <=numberOfAssets; j++){
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
            System.runAs(testUser){
                insert assets;
                testAssets = assets;
            }
        }
    }
    
    public static void createPortalContracts(Integer numberOfContracts,Account acc, User u) {
        createContractCriteria(u);
        createBridgeWareSetting();
        
        Test.setMock(HttpCalloutMock.class, new TC_BWcreateCustomerCalloutMockImpl ());

        Integer existingContracts = testContracts.size();
        Integer existingContacts = testContacts.size();
        List<Contact> contacts = new List<Contact>();
        List<Contract__c> contracts = new List<Contract__c>();
        for(Integer i = 0; i <numberOfContracts; i++){
            Integer uniqueNumber = existingContacts + i;
            Contact c = new Contact (AccountId = acc.Id, FirstName = 'test' + uniqueNumber,
                 LastName = 'testbeni' + uniqueNumber, OtherStreet = 'test', OtherCity = 'test', 
                 OtherStateCode = 'MN', OtherPostalCode = String.valueOf(11111 + uniqueNumber).left(5), Title = 'title' + uniqueNumber, 
                 SSN__c = String.valueOf(111111111 + uniqueNumber).left(9), BirthDate = Date.today (),
                 Email = 'test@email' + String.valueOf(11111 + uniqueNumber) + '.com', Validity_Verify__Status__c = 'Valid');
            contacts.add(c);

                Contract__c contract = new Contract__c (Customer__c = acc.Id, Status__c = 'Active',
                    Name = '401-' + String.valueOf(1111111 + i).right(7) + '-210', application_number__c = '1234567890',
                    Delinquency_Status_Code__c = '00', Infolease_Environment__c = '10', dealer_Name__c = acc.Id);
                contracts.add(contract);
            
        }
        System.runAs(testUser){
            insert contacts;
            testContacts.addAll(contacts);
            insert contracts;
        }
        testContracts.addAll(contracts);
    }

    public static User createDPDataForUser(Account portalAccount){
        String portalUserName = 'Portal.SL.test.user'+generateRandomString()+'@silverlinecrm.com';
        portalAccount.RecordTypeId = SL_SCTestData.DEALER_ACC;
        portalAccount.Waiting_To_Be_Sent_To_Bridgeware__c = true; // contradictory name for a flag that actually stops the call
        UPDATE portalAccount;
        SL_SCTestData.dealerAccountId = portalAccount.Id;
        Contact portalContact = new contact(LastName = 'portalContact', FirstName = 'Test', AccountId = portalAccount.Id);
        INSERT portalContact;
        Id OegProfileId = [SELECT Id, Name FROM Profile WHERE Name = :OEG_DEALER_PROFILE].Id;
        User u = prepareDPUser(portalContact.Id, OegProfileId, portalUserName);
        INSERT u;
        return u;
    }

    public static User prepareDPUser(Id contactId, Id profileId, String portalUserName){
        User u = new User(Alias = 'testuser', Email = 'marlinbusiness@peacsolutions.com', EmailEncodingKey='UTF-8',
                LastName = 'testing', FirstName = 'user', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = profileId, TimeZoneSidKey = 'America/Los_Angeles',
                Username = portalUserName, Doc_Fee_Exception_Approver__c = true, PortalRole = 'Manager', ContactId = contactId,
                IsPrmSuperUser = true, SuperUser__c = true);
        return u;
    }

    public static List<User> createDPUsers(Integer numberOfAccount, Integer numberOfUsers){
        User u = createTestUser();
        createContractCriteria(u);
        createBridgeWareSetting();
        createFieldTrackUserExclusion();
        
        Test.setMock(HttpCalloutMock.class, new TC_BWcreateCustomerCalloutMockImpl ());

        // Campaign testCampaign = new Campaign(Name = 'Customer', isActive = true);
        // insert testCampaign;
        Integer existingAccounts = testAccounts.size();
        List<Account> accounts = new List<Account>();
        for(Integer i = 1; i <=numberOfAccount; i++){
            Integer n = existingAccounts + i;
            accounts.add(prepareAccount(n, SL_SCTestData.DEALER_ACC, null));
        }
        insert accounts;
        testAccounts.addAll(accounts);

        Integer existingContacts = testContacts.size();
        List<Contact> contacts = new List<Contact>();
        List<User> dpUsers = new List<User>();
        for(Integer i = 0; i <numberOfAccount; i++){
            for(Integer j = 0; j < numberOfUsers; j++){
                Integer uniqueNumber = existingContacts + i + j;
                contacts.add(prepareContact(uniqueNumber, accounts[i].Id));
            }
        }
        insert contacts;
        testContacts.addAll(contacts);
        Id OegProfileId = [SELECT Id, Name FROM Profile WHERE Name = :OEG_DEALER_PROFILE].Id;
        for(Integer i = 0; i <numberOfAccount; i++){
            for(Integer j = 0; j < numberOfUsers; j++){
                String portalUserName = 'Portal.SL.test.user'+generateRandomString()+'@silverlinecrm.com';
                dpUsers.add(prepareDPUser(contacts[i + j].Id, OegProfileId, portalUserName));
            }
        }
        insert dpUsers;
        return dpUsers;
    }

    public static void prepareFundingOpportunity(){
        prepareFundingOpportunity(true);
    }
    public static void prepareFundingOpportunity(Boolean setStageAsFunding){
        ORE__c o = new ORE__c(Bypass__c = true);
        insert o;
        Marlin_Configuration__c config = new Marlin_Configuration__c(Loan_Salary_Amount__c = 231, Lease_Salary_Amount__c = 71, Loan_Operating_Expense_Amount__c = 27, Lease_Operating_Expense_Amount__c = 0);
        insert config;
        list<Profile> cmsProfiles = [SELECT Id FROM Profile WHERE Name ='CMS'];
        User u = SL_SCTestData.createTestUser(cmsProfiles[0].Id);
        //Id loanOppId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan Opportunity').getRecordTypeId();
        Id dealerVendorId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer_Vendor').getRecordTypeId();
        SL_SCTestData.createAccountAndContracts(6, 1);
        List<Account> accounts = SL_SCTestData.testAccounts;
        List<Contact> contacts = SL_SCTestData.testContacts;
        SL_SCTestData.createOpportunitiesAndAssets(accounts[0].Id, 3, 1);
        List<Opportunity> opps = SL_SCTestData.testOpportunities;
        accounts[4].Preferred_Dealer_Level__c = '1';
        accounts[4].RecordTypeId = dealerVendorId;
        accounts[4].Waiting_To_Be_Sent_To_Bridgeware__c = true; // contradictory name for a flag that actually stops the call
        // accounts[4].Account_Dealer_Status__c = 'Approved';
        update accounts[4];
        insert new List<OpportunityContactRole>{new OpportunityContactRole(Role = 'Primary Contact', OpportunityId = opps[0].Id, ContactId = contacts[1].Id ),
            new OpportunityContactRole(Role = 'Dealer Primary Contact', OpportunityId = opps[0].Id, ContactId = contacts[2].Id),
            new OpportunityContactRole(Role = 'Billing Contact', OpportunityId = opps[2].Id, ContactId = contacts[3].Id),
            new OpportunityContactRole(Role = 'Dealer Primary Contact', OpportunityId = opps[2].Id, ContactId = contacts[4].Id),
            new OpportunityContactRole(Role = 'Primary Contact', OpportunityId = opps[2].Id, ContactId = contacts[5].Id)};     
        Test.startTest();
        insert new Dealer__c(Opportunity__c = opps[2].Id, Primary_Dealer__c = true, Dealer__c = accounts[4].Id);
        User theAdmin = TestDataFactory.createTestUser();
            Payee__c payee = new Payee__c(Dealer__c =accounts[4].Id, Contact__c = contacts[4].Id, Payee_ID__c	= '111000005', 
                Active__c = true, SL_Vendor_ID__c ='900-090-ASD', Payee_Name__c = 'Test Payee' );
            insert payee;
        if(setStageAsFunding){
            System.runAs(theAdmin){
                opps[2] = setFieldValuesForFunding(opps[2], u, theAdmin);
                update opps[2];
            }
        }
        Test.stopTest();
    }

    public static Opportunity setFieldValuesForFunding(Opportunity opp, User u, User theAdmin){
        opp.StageName = 'Funding';
        opp.Opportunity_Status__c = 'Funding - In Process';
        opp.Payment_Amount__c = 301;
        opp.of_Payments__c = 10;
        opp.Lessor__c = 410;
        opp.Credit_Stips_Completed_Date__c = Datetime.now();
        opp.Business_Phone__c = '0321091611';
        opp.Assign_To_CMS_User__c = u.Id;
        opp.Docs_Out__c = Datetime.now();
        opp.Docs_In__c = Datetime.now();
        opp.P_O_Issued__c = Datetime.now();
        opp.OwnerId = theAdmin.Id;
        opp.Opportunity_Installed_Date__c = Date.today();
        opp.Portal_User_ID__c = 'UDA-';
        return opp;
    }

    public static Decimal calculateInterimDaysToCheck(Opportunity opp){
        Integer currentDayOfMonth = Date.today().day();
        List<Integer> availablePaymentDays = new List<Integer>{1, 5, 8, 10, 15, 20, 25};
        Integer previousDay = 1;
        Integer firstPaymentDay = 25;
        for(Integer theDay :availablePaymentDays){
            if(currentDayOfMonth > previousDay && currentDayOfMonth < theDay){
                firstPaymentDay = theDay;
            }
            previousDay = theDay;
        }
        Decimal interimDaysToCheck = firstPaymentDay - currentDayOfMonth;
        if(interimDaysToCheck < 1){
            opp.First_Payment_Date__c = Date.newInstance(Date.today().year(), Date.today().addMonths(1).month(), 1);
        }else{
            opp.First_Payment_Date__c = Date.today().addDays(Integer.valueOf(interimDaysToCheck));
        }
        return interimDaysToCheck;
    }

    public static void createExternalHierarchy(){
        createAccountAndContracts(3, 1);
        List<Account> theAccounts = testAccounts;
        List<Account> portalAccounts = new List<Account>{ theAccounts[1], theAccounts[2] };
        createOpportunitiesAndAssets(theAccounts[0].Id, 1, 1);
        Test.startTest();
        System.runAs(testUser){
            User parentUser = createDPDataForUser(portalAccounts[0]);
            User childUser = createDPDataForUser(portalAccounts[1]);
        }
        ExternalAccountHierarchy parentHierarchy = new ExternalAccountHierarchy (HierarchyType = 'Partner', 
            Name = 'Test parent 1', AccountId = portalAccounts[0].Id, IsActive = true);
        insert parentHierarchy;
        ExternalAccountHierarchy childHierarchy = new ExternalAccountHierarchy (HierarchyType = 'Partner', 
            Name = 'Test child 1', AccountId = portalAccounts[1].Id, ParentId = parentHierarchy.Id, IsActive = true);
        insert childHierarchy;
        Test.stopTest();
    }

    public static void createEmailTemplates(Id runningUser){
        List<EmailTemplate> testTemplates = new List<EmailTemplate>();
        testTemplates.add(new EmailTemplate(DeveloperName = 'SalesSubmitted', name = 'SalesSubmitted', FolderId = runningUser, TemplateType = 'text', isActive = true));
        testTemplates.add(new EmailTemplate(DeveloperName = 'SalesApproved', name = 'SalesApproved', FolderId = runningUser, TemplateType = 'text', isActive = true));
        testTemplates.add(new EmailTemplate(DeveloperName = 'SalesDecline', name = 'SalesDecline', FolderId = runningUser, TemplateType = 'text', isActive = true));
        testTemplates.add(new EmailTemplate(DeveloperName = 'SalesPending', name = 'SalesPending', FolderId = runningUser, TemplateType = 'text', isActive = true));
        insert testTemplates;
    }

    public static Account setManufacturerData(Account manufacturerAccount){
        manufacturerAccount.recordtypeid = DEALER_ACC;
        manufacturerAccount.name = 'Test Manufacturer';
        manufacturerAccount.Type = 'M';
        manufacturerAccount.Dealer_Number__c = '009903.0000';
        manufacturerAccount.Business_Phone__c = '0099030000';
        return manufacturerAccount;
    }
    /************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)     
@Description: createFirstManufacturer method
************************************************************************************/
    public static List<Account> createFirstManufacturer(Boolean toBeCreated )
    {
        List<Account> acclist = new List<Account>();
        Account acc = new Account();
        setManufacturerData(acc);
        acclist.add(acc);
        if(toBeCreated)
        {
         insert acclist;   
        }
        return acclist;
        
    }
/************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)     
@Description: createManufacturer method
************************************************************************************/   
    public static List<Account> createManufacturer(Integer numberOfManufacturer, Boolean toBeCreated )
    {
        createFirstManufacturer(True);
       	List<Account> acclist = new List<Account>();
        for(Integer i = 0; i <numberOfManufacturer; i++){
          	Account acc = new Account();
            acc.recordtypeid = DEALER_ACC;
            acc.name = MANUFACTURER_NAME+i;
            acc.Type = 'M';
            acclist.add(acc);
        }
        if(toBeCreated)
        {
         insert acclist;   
        }
        return acclist;
    }


    
    public static String generateRandomString() {

        Integer len = 4;    
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz1234567890';    
        String randStr = '';    
        while (randStr.length() < len) {    
           Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());    
           randStr += chars.substring(idx, idx+1);    
        }    
             return randStr;    
    }
}