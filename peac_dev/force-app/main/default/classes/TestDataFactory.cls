@isTest
public class TestDataFactory {
    public static Lead createTestLead(){
        Lead l=new Lead(FirstName='John',LastName='Doe',Company='JohnDoe Inc',Email='john@doe.com', Guarantor_Address_Line1__c='123 Main St', 
                        Guarantor_Address_Line2__c='Suite 400',Guarantor_City__c='New York', Guarantor_State__c='NY',Guarantor_Zip__c='21345', 
                        phone='8888888888',Guarantor_Last_Name__c='SSmith',Guarantor_First_Name__c='JJohn',Date_of_Birth__c=System.today()-365,
                       Guarantor_email__c='john@does.com',Guarantor_phone__c='7777777777', LeadSource = 'Outbound Call Campaign',
                       Guarantor2_Last_Name__c='SSSmith',Guarantor2_First_Name__c='JJJohn', Tax_ID__c='123456789', Lead_Type__c = 'End User',
                        //Dealer_name__c='Doe',Dealer_phone__c='1231231334',Dealer_email__c='doe@john.com',
                        //Equipment_Type__c='ATM',Equipment_Address_Line_1__c='123 Main St',Equipment_City__c='Equip City',Equipment_State__c='NY',Equipment_Zipcode__c='12345',
                       Guarantor2_email__c='john@doess.com',Guarantor2_phone__c='7777777779', recordTypeId='01261000000X2LGAA0',
                       Business_Address_Line1__c = '123 test', Business_City__c = 'Testing', Business_State__c = 'MN', 
                       Business_Zip__c = '33223', CountryCode = 'US');
        insert l;
        return l;
    }
    
    public static Account createTestAccount(){
        Account ac=new Account(Name='Test', CCAN__c='123456', Tax_ID__c='123435678');
        insert ac;
        return ac;
    }
    
    public static Contact createTestContact(ID acctId){
        Contact c=new Contact(FirstName='John', LastName='Smith', AccountId=acctId, phone='888-999-8889', Email='test@test.com');
        insert c;
        return c;
    }
    
    public static Opportunity createTestOpp(ID acctId){
        Opportunity o=new Opportunity(Name='Test opp',CloseDate=System.today()+30, stagename='Quote', 
                        AccountId=acctId,State_Tax_Code__c='MN',Tax_City__c='WOODBURY',Tax_ID__c='622666666',
                                      Tax_County__c = 'WASHINGTON', Tax_Exempt__c='Yes', Amount=33, Billing_Cycle__c='December',
                                      Recurring__c='Recurring Only', Meter_Account__c = 'DLR');
        insert o;
        return o;
    }
    
    public static User createTestUser(){
        Id profileId=[select id, name from profile where name='System Administrator'].id;
        String orgId = UserInfo.getOrganizationId();  
        String dateString =   
        String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');  
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));  
        String uniqueName = orgId + dateString + randomInt;  
        User u=new User(FirstName='Test Owner',LastName='Test Id', email = uniqueName + '@sfdc' + orgId + '.org',  
            Username = uniqueName + '@sfdc' + orgId + '.org',  
            EmailEncodingKey = 'ISO-8859-1',  
            Alias = uniqueName.substring(18, 23),  
            TimeZoneSidKey = 'America/Los_Angeles',  
            LocaleSidKey = 'en_US',  
            LanguageLocaleKey = 'en_US',  
            ProfileId = profileId, Personnel_Number__c = '0415');
        insert u;
        return u;
    }
    
    public static TC_GDSScoreReqRespBean createGDSScoreReqResBean(){
        
        TC_GDSScoreReqRespBean bean=new TC_GDSScoreReqRespBean();
        bean.wsFields=new Webservice_Field__c(BizCityMatch__c=1);
        bean.scoreReq=new Gds_Score__c();
        return bean;
    }
    
    public static String createGDSScoreReqResXMLResponse(){
        
       String body='<?xml version="1.0" encoding="UTF-8"?>';
        	body+='<root><APPLICATIONDATA_APPLICATIONDATE>2022-01-01</APPLICATIONDATA_APPLICATIONDATE>';
        	body+='<RESPONSEDATA_EBFILENUMBER>12345</RESPONSEDATA_EBFILENUMBER>';
        	body+='<RESPONSEDATA_DBPASSWORD>12345</RESPONSEDATA_DBPASSWORD>';
            body+='<RESPONSEDATA_DNBDVPACKET_APPLICANT><RESPONSEDATA_DNBDVPACKET_SBRILEASESCORE>1234</RESPONSEDATA_DNBDVPACKET_SBRILEASESCORE><RESPONSEDATA_DNBDVPACKET_COMMERCIALCREDITSCORE>1234</RESPONSEDATA_DNBDVPACKET_COMMERCIALCREDITSCORE></RESPONSEDATA_DNBDVPACKET_APPLICANT>';
        	body+='<RESPONSEDATA_DNBDVPACKET_DEALER><RESPONSEDATA_DNBDVPACKET_SBRILEASESCORE>1234</RESPONSEDATA_DNBDVPACKET_SBRILEASESCORE><RESPONSEDATA_DNBDVPACKET_COMMERCIALCREDITSCORE>1234</RESPONSEDATA_DNBDVPACKET_COMMERCIALCREDITSCORE></RESPONSEDATA_DNBDVPACKET_DEALER>';
        	body+='<RESPONSEDATA_DNBDVPACKET_BV><RESPONSEDATA_DNBDVPACKET_SBRILEASESCORE>1234</RESPONSEDATA_DNBDVPACKET_SBRILEASESCORE><RESPONSEDATA_DNBDVPACKET_COMMERCIALCREDITSCORE>1234</RESPONSEDATA_DNBDVPACKET_COMMERCIALCREDITSCORE></RESPONSEDATA_DNBDVPACKET_BV>';
        	body+='<ExtractFields><UD_VERIFY_SLF>12345</UD_VERIFY_SLF><UD_SOFTWARE_STIP>12345</UD_SOFTWARE_STIP><UD_MUNICIPAL_ADDENDUM>12345</UD_MUNICIPAL_ADDENDUM><UD_CORP_RES_LESSEE_PO>12345</UD_CORP_RES_LESSEE_PO><UD_EQUIPMENT_APPROVAL>12345</UD_EQUIPMENT_APPROVAL>';
        	body+='<UD_PROOF_OF_BUS_LOC>12345</UD_PROOF_OF_BUS_LOC><UD_RESIDUAL_STIP>12345</UD_RESIDUAL_STIP><UD_OWNER_TO_SIGN>John</UD_OWNER_TO_SIGN><UD_UCC_FILING_SEARCH>Search</UD_UCC_FILING_SEARCH>';
        	body+='<UD_TECERT>12345</UD_TECERT><UD_PATRIOT_STIP>12345</UD_PATRIOT_STIP><UD_VENDOR_APPROVAL_OUTPUT>12345</UD_VENDOR_APPROVAL_OUTPUT><UD_PG_REQUIRED>12345</UD_PG_REQUIRED><UD_PROOF_OF_OWNERSHIP>12345</UD_PROOF_OF_OWNERSHIP>';
        	body+='<UD_ACH_GUAR>12345</UD_ACH_GUAR><UD_PROOF_OF_EQUIP_LOC>12345</UD_PROOF_OF_EQUIP_LOC><UD_AUTH_SIGNER_TRACK_BUS>12345</UD_AUTH_SIGNER_TRACK_BUS><UD_SALE_LEASEBACK_DOC>12345</UD_SALE_LEASEBACK_DOC><UD_SALE_LEASEBACK_DOC>12345</UD_SALE_LEASEBACK_DOC>';
        	body+='<UD_PG_FRAUD_ALERT>12345</UD_PG_FRAUD_ALERT><UD_COPY_OF_DRIVER_LICENSE>12345</UD_COPY_OF_DRIVER_LICENSE><UD_CUST_VER_PROC_REQ>12345</UD_CUST_VER_PROC_REQ><UD_VERIFY_BANK_INFO>12345</UD_VERIFY_BANK_INFO><LOAN_AMOUNT>12345</LOAN_AMOUNT><Total_Exposure_Amount>12345</Total_Exposure_Amount>';
        	body+='<UD_ACTIVE_CONT_PAST_31>12345</UD_ACTIVE_CONT_PAST_31><DispContPymtsMade>12345</DispContPymtsMade><ActiveContPymtsMade>12345</ActiveContPymtsMade><UD_MIN_CONFIRM_TIB>12345</UD_MIN_CONFIRM_TIB><UD_MIN_BANK_INFO>12345</UD_MIN_BANK_INFO><UD_MIN_PERSONAL_INFO>12345</UD_MIN_PERSONAL_INFO><UD_MIN_PERSONAL_INFO>12345</UD_MIN_PERSONAL_INFO>';
        	body+='<MODEL_NAME>12345</MODEL_NAME><UNDERLYING_MODEL>12345</UNDERLYING_MODEL><UD_EXP_OVER_150K>12345</UD_EXP_OVER_150K><UD_MONTHS_VERIFIED_DE_IN>12345</UD_MONTHS_VERIFIED_DE_IN>';	
        	body+='<UD_EXIST_CUST_OUTPUT>12345</UD_EXIST_CUST_OUTPUT><UD_SFP_MODEL_OUTPUT>12345</UD_SFP_MODEL_OUTPUT><UD_PYMTS_UPFRONT>12345</UD_PYMTS_UPFRONT><LESSOR>12345</LESSOR><UD_APPROVED_REASON>12345</UD_APPROVED_REASON><UD_CREDIT_ANALYST>12345</UD_CREDIT_ANALYST><UD_CO_REC_DEC>12345</UD_CO_REC_DEC>';
        	body+='<UD_APP_STATUS>12345</UD_APP_STATUS><UD_SS_CREDIT_BOX>12345</UD_SS_CREDIT_BOX><UD_EVER_AUTO_MORE_INFO>12345</UD_EVER_AUTO_MORE_INFO><UD_TAX_EXEMPT_DATE_OUTPUT>12345</UD_TAX_EXEMPT_DATE_OUTPUT><UD_MAX_TERM>12345</UD_MAX_TERM><UD_REJECT_REASON>12345</UD_REJECT_REASON><PUR_OPTION>12345</PUR_OPTION>';
        	body+='<UD_DLR_PREFERRED>12345</UD_DLR_PREFERRED><UD_DLR_CLASSIFICATION>12345</UD_DLR_CLASSIFICATION><SICCODE_preference_input>12345</SICCODE_preference_input><SICCODE>12345</SICCODE><UD_MIN_MISC_NOTES>12345</UD_MIN_MISC_NOTES>';	
        	body+='</ExtractFields>';
        	body+='<UD_OFAC_HIT>12345</UD_OFAC_HIT><UD_OFAC_PERFORMED>12345</UD_OFAC_PERFORMED><UD_OFACRESULT>12345</UD_OFACRESULT><SICCODELOOKUP>12345</SICCODELOOKUP>';
        	body+='<ScorecardSummary>';
        	body+='<RawScore>12345</RawScore><FinalScore>12345</FinalScore><FinalDecision_Comment>12345</FinalDecision_Comment><Signal_Count>12345</Signal_Count><Rule_Count>12345</Rule_Count><RNS_description>12345</RNS_description><businessrule_description>12345</businessrule_description><DLG_RiskGrade>12345</DLG_RiskGrade><RBP_RiskGrade3>12345</RBP_RiskGrade3>';	
        	body+='</ScorecardSummary>';	
        	body+='<RESPONSEDATA_PAYNET_APPLICANT><RESPONSEDATA_PAYNET_MAXORIGRECEIVABLEAMT>12345</RESPONSEDATA_PAYNET_MAXORIGRECEIVABLEAMT><RESPONSEDATA_DNBDVPACKET_SBRILEASESCORE>12345</RESPONSEDATA_DNBDVPACKET_SBRILEASESCORE>';
        	body+='</RESPONSEDATA_PAYNET_APPLICANT>';
        	body+='<Data_Warehouse><DWH_GetDataForCreditScoring><FastTrak_IAD_Eligible>12345</FastTrak_IAD_Eligible></DWH_GetDataForCreditScoring><DWH_GetDataForFraud>12345</DWH_GetDataForFraud>';
        	body+='</Data_Warehouse>';
        	body+='<RESPONSEDATA_SCORES><DWH_GetDataForCreditScoring><FastTrak_IAD_Eligible>12345</FastTrak_IAD_Eligible></DWH_GetDataForCreditScoring><DWH_GetDataForFraud>12345</DWH_GetDataForFraud>';
        	body+='</RESPONSEDATA_SCORES>';
        	body+='<EQUIPCODELOOKUP><RestrictedEquip>12345</RestrictedEquip>';
        	body+='</EQUIPCODELOOKUP>';
        	body+='<MONTHS_IN_BUSINESS>12345</MONTHS_IN_BUSINESS><UD_QUICK_TRACK>12345</UD_QUICK_TRACK><DLR_ONHOLD_INDICATOR>12345</DLR_ONHOLD_INDICATOR><UD_BANK_STATEMENT>12345</UD_BANK_STATEMENT><UD_CREDIT_DOCPACK>12345</UD_CREDIT_DOCPACK><UD_DUE_DILIGENCE>12345</UD_DUE_DILIGENCE><UD_VER_SSN>12345</UD_VER_SSN>';
        	body+='<UD_VER_TAXID>12345</UD_VER_TAXID><UD_VER_LEGALSTRUCTURE>12345</UD_VER_LEGALSTRUCTURE><High_Risk_5_Deals>12345</High_Risk_5_Deals><FraudReviewFlag>12345</FraudReviewFlag>';
        	body+='<EmailageResults><PrimaryContact_Emailage_Result>12345</PrimaryContact_Emailage_Result><PrimaryContact_Emailage_Timestamp>12345</PrimaryContact_Emailage_Timestamp><PG1_Emailage_Timestamp>12345</PG1_Emailage_Timestamp><PG1_Emailage_Result>12345</PG1_Emailage_Result><PG2_Emailage_Result>12345</PG2_Emailage_Result><PG2_Emailage_Timestamp>12345</PG2_Emailage_Timestamp>';
        	body+='</EmailageResults>';
        	body+='<CCG><CCG_MarlinScore>12345</CCG_MarlinScore><CCG_BusinessRules>12345</CCG_BusinessRules><CCG_RNS>12345</CCG_RNS>';
        	body+='</CCG>';
        	body+='</root>';
        return body;
    }
    
    public static Account createAspireAccount(){
        Account acc = new Account (
            Name = 'test', 
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId()
        );
        insert acc;
        return acc;
    }
    
    public static Opportunity createAspireOpportunity(Account acc){
        Opportunity opp =new Opportunity(
            AccountId = acc.Id,
            Resubmitted_to_Credit__c = true,
            Credit_Decision__c = false,
            CloseDate = date.today()+100,
            Probability = 80,
            Deferral_Payments__c = '30 days',
            StageName = 'test',
            Ready_to_Doc__c = 'No',
            Loan_Points_Amount__c = 15,
            RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Express Decision'][0].Id,
            Name = 'test',
            Tax_State__c = 'MN',
            Tax_County__c = 'WASHINGTON',
            Tax_City__c = 'WOODBURY',
            Amount = 123.45
        );
        insert opp;
        return opp;
    }
    
    public static TC_ASPIRE__Account__c createTCAspireAccount(Account acc, String accid){
        TC_ASPIRE__Account__c aspireAcc = new TC_ASPIRE__Account__c(TC_ASPIRE__LastName__c = 'AAA',TC_ASPIRE__AccountId__c = accid.substring(0, 15), TC_ASPIRE__RecordId__c = acc.Id, TC_ASPIRE__AccountType__c='Individual');
        insert aspireAcc;
        return aspireAcc;
    }

    public static List<Account> testAccounts = new List<Account>();
    public static List<Opportunity> testOpportunities = new List<Opportunity>();
    public static List<Asset__c> testAssets = new List<Asset__c>();

    public static void prepareAccounts(Integer numberOfAccount, Id recordTypeId, String accountBranch) {
        User u = SL_SCTestData.createTestUser();
        SL_SCTestData.createContractCriteria(u);
        SL_SCTestData.createBridgeWareSetting();
        
        Test.setMock(HttpCalloutMock.class, new TC_BWcreateCustomerCalloutMockImpl ());

        Integer existingAccounts = 0;
        List<Account> accounts = new List<Account>();
        for(Integer i = 1; i <=numberOfAccount; i++){
            Integer n = existingAccounts + i;
            Account acc = new Account (Name = (String.valueOf(n) + ' test Customer'), 
            RecordTypeId = recordTypeId,
            Business_Phone__c = String.valueOf(1234567890 + n).left(10),
            tax_ID__c = String.valueOf(111000000 + n),
            Dealer_Number__c = String.valueOf(111000000 + n).left(18),
            CCID__c = String.valueOf(1234567890 + n).right(7),
            CCAN__c = String.valueOf(1234567890 + n).right(10),
            Account_Branch__c = accountBranch);
            accounts.add(acc);
        }
        // insert accounts;
        testAccounts.addAll(accounts);

        // Integer existingContacts = 0;
        // List<Contact> contacts = new List<Contact>();
        // List<Contract__c> contracts = new List<Contract__c>();
        // for(Integer i = 0; i <numberOfAccount; i++){
        //     Integer uniqueNumber = existingContacts + i;
        //     Contact c = new Contact (AccountId = accounts[i].Id, FirstName = 'test' + uniqueNumber,
        //          LastName = 'testbeni' + uniqueNumber, OtherStreet = 'test', OtherCity = 'test', 
        //          OtherStateCode = 'MN', OtherPostalCode = String.valueOf(11111 + uniqueNumber).left(5), Title = 'title' + uniqueNumber, 
        //          SSN__c = String.valueOf(111111111 + uniqueNumber).left(9), BirthDate = Date.today ());
        //     contacts.add(c);
        // }
        // insert contacts;
        // testContacts.addAll(contacts);
    }
}