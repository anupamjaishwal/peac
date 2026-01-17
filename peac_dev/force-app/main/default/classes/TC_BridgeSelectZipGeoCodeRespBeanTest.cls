@isTest
public class TC_BridgeSelectZipGeoCodeRespBeanTest {
    @TestSetup static void setup () {
         // Setup test data
        // Create a unique UserName
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='DataAdmin'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/New_York',
         UserName=uniqueUserName);

        System.runAs(u) {
              // The following code runs as user 'u'
              System.debug('Current User: ' + UserInfo.getUserName());
              System.debug('Current Profile: ' + UserInfo.getProfileId());
          } 
        SL_SCTestData.createBridgeWareSetting();
        
        Account act = new Account ();
        act.Name = 'TestAspire1';
        act.BillingCity = 'Minneapolis';
        act.BillingCountryCode = 'US';
        act.BillingPostalCode = '55401';
        act.BillingStateCode = 'MN';
        act.BillingStreet = '411 Washington Ave N';
        act.Phone = '2225551234';
        act.Business_State__c = 'MN';
        act.Business_Type__C = 'Corporation';
        act.Business_City__c = 'test';
        act.Business_Zip__c = '11111';
        act.Business_Country__c = 'US';
        
        Schema.DescribeSObjectResult d = Schema.SObjectType.Account;
        Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName ();
        act.RecordTypeId = rtMapByName.get ('End User Account').getRecordTypeId ();
        insert act;
        
        Marlin_Configuration__c config = new Marlin_Configuration__c ();
        config.Static_Standard_Asset_Account_Id__c = act.Id;
        insert config;
        // add validation fields: Term, Commencement Date, Invoicing Due Day, Gross Contract, Gross Finance, Invoice Description, Payment Frequency, Billing Cycle, Gross Finance
        // Federal Tax Id, Business Phone, Purchase Options, # of Payments, Payment Amount, Contract Type, Account Business Street, Account Business City, Account Business Zip/Postal Code, Account Business Zip/Postal Code
        Opportunity opp = new Opportunity ();
        opp.accountId = act.Id;
        opp.amount = 1000;
        opp.name = 'Aspire Test Opportunity 1';
        opp.StageName = 'Ready for Booking';
        Date today = Date.today ();
        opp.CloseDate = today;
        opp.Facility_Code__c = '2.03';
        
        SL_SCTestData.createOpportunitiesAndAssets(act.Id, 1, 1);
        
        /* Just added Test.isRunningTest () to exclude validations on test
        // new fields
        opp.Funding_Booking_Loan_Completed_Date__c = today;
        opp.Terms__c = 12;
        opp.Commencement_Date__c = Date.today ();
        opp.Invoicing_Due_Day__c = 5;
        opp.Equipment_Cost__c = 30000;
        opp.Gross_Contract__c = 20000;
        opp.Gross_Finance__c = 10000;
        opp.Invoice_Description__c = 'test';
        opp.Payment_Frequency__c = 'Annually';
        opp.Billing_Cycle__c = 'January';
        opp.Funding_Booking_Lease_Completed_Date__c = Date.today ();
        opp.Tax_ID__c = '111221212';
        opp.Business_Phone__c = '1112221212';
        opp.Purchase_Options__c = 'FMV';
        opp.of_Payments__c = 12;
        opp.Payment_Amount__c = 5000;
        opp.Contract_Type__c = 'Conditional Sales';
        opp.Account_Business_Street__c = 'test';
        opp.Account_Business_City__c = 'test';
        opp.Account_Business_Zip_Postal_Code__c = '11111';*/
        Test.startTest();
        insert opp;
        
        
        
        Approved_Offer__c offer = new Approved_Offer__c ();
        offer.Opportunity__c = opp.Id;
        insert offer;
        
        Loan_Contract__c contract = new Loan_Contract__c ();
        contract.Opportunity__c = opp.Id;
        contract.Name = '500-123456-003';
        insert contract;
        
        opp.Selected_Approved_Offer__c = offer.Id;
        update opp;
        Test.stopTest();
        
        Asset__c a = new Asset__c ();
        a.Opportunity__c = opp.Id;
        a.Equipment_City__c = 'Seattle';
        //Test.startTest ();
        //insert a;
        //Test.stopTest();
        
        
    }
    @isTest static void testSelectZipGeoCode() {
        
        // Implement test code
        Test.setMock(HttpCalloutMock.class, new TC_BridgewareSelectZipGeoCalloutMockImpl ());
        TC_BridgewareService service = new TC_BridgewareServiceImpl ();
        
        Test.startTest();
        
        TC_BridgewareSelectZipGeoCodeRequestBean bean = new TC_BridgewareSelectZipGeoCodeRequestBean ();
        bean.setZipCode ('55125');
        bean.getZipCode ();
        bean.getTaxCode ();
        bean.getRequestUserId ();
        
        TC_BridgewareSelectZipGeoCodeRespBean respbean = service.selectZipGeoCode(bean);
        
        TC_BridgewareSelectZipGeoCodeRespBean.ContentHeader contentHeader = respbean.getContentHeader();
        contentHeader.setContentVersion(contentHeader.getContentVersion());
        contentHeader.setStatus(contentHeader.getStatus());
        
        TC_BridgewareSelectZipGeoCodeRespBean.UniDataZipGeoCodeContentData uniDataZipGeoCodeContentData = respbean.getContentData();

        if (uniDataZipGeoCodeContentData != null) {
            TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipState[] uniDataVtZipStateList = uniDataZipGeoCodeContentData.getVtZipStateList();
            
            if (uniDataVtZipStateList != null) {
                TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipState uniDataVtZipState = null;
                
                for (integer i = 0; i < uniDataVtZipStateList.size(); i++) {
                    uniDataVtZipState = uniDataVtZipStateList[i];
                    System.debug('uniDataVtZipState.description: ' + uniDataVtZipState.getDescription());
                    System.debug('uniDataVtZipState.code: ' + uniDataVtZipState.getCode());
                    uniDataVtZipState.setDescription(uniDataVtZipState.getDescription());
                    uniDataVtZipState.setCode(uniDataVtZipState.getCode());
                    
                    TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipCounty[] uniDataVtZipCountyList = uniDataVtZipState.getVtZipCountyList();
                    
                    if (uniDataVtZipCountyList != null) {
                        TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipCounty uniDataVtZipCounty = null;
                        
                        for (integer j = 0; j < uniDataVtZipCountyList.size(); j++) {
                            uniDataVtZipCounty = uniDataVtZipCountyList[j];
                            System.debug('uniDataVtZipCounty.description: ' + uniDataVtZipCounty.getDescription());
                            System.debug('uniDataVtZipCounty.code: ' + uniDataVtZipCounty.getCode());
                            uniDataVtZipCounty.setDescription(uniDataVtZipCounty.getDescription());
                            uniDataVtZipCounty.setCode(uniDataVtZipCounty.getCode());
                            
                            TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipCity[] uniDataVtZipCityList = uniDataVtZipCounty.getVtZipCityList();
                            
                            if (uniDataVtZipCityList != null) {
                                TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipCity uniDataVtZipCity = null;
                                
                                for (integer k = 0; k < uniDataVtZipCityList.size(); k++) {
                                    uniDataVtZipCity = uniDataVtZipCityList[k];
                                    System.debug('uniDataVtZipCity.description: ' + uniDataVtZipCity.getDescription());
                                    System.debug('uniDataVtZipCity.code: ' + uniDataVtZipCity.getCode());
                                    uniDataVtZipCity.setDescription(uniDataVtZipCity.getDescription());
                                    uniDataVtZipCity.setCode(uniDataVtZipCity.getCode());
                                    
                                    TC_BridgewareSelectZipGeoCodeRespBean.UniDataTaxType[] uniDataTaxTypeList = uniDataVtZipCity.getTaxTypeList();
                                    
                                    if (uniDataTaxTypeList != null) {
                                        TC_BridgewareSelectZipGeoCodeRespBean.UniDataTaxType uniDataTaxType = null;
                                        
                                        for (integer l = 0; l < uniDataTaxTypeList.size(); l++) {
                                            uniDataTaxType = uniDataTaxTypeList[l];
                                            System.debug('uniDataTaxType.description: ' + uniDataTaxType.getDescription());
                                            System.debug('uniDataTaxType.code: ' + uniDataTaxType.getCode());
                                            System.debug('uniDataTaxType.getStateTaxRate(): ' + uniDataTaxType.getStateTaxRate());
                                            System.debug('uniDataTaxType.getCountyTaxRate(): ' + uniDataTaxType.getCountyTaxRate());
                                            System.debug('uniDataTaxType.getCountyTransTaxRate(): ' + uniDataTaxType.getCountyTransTaxRate());
                                            System.debug('uniDataTaxType.getCityTaxRate(): ' + uniDataTaxType.getCityTaxRate());
                                            System.debug('uniDataTaxType.getCityTransTaxRate(): ' + uniDataTaxType.getCityTransTaxRate());
                                            uniDataTaxType.setDescription(uniDataTaxType.getDescription());
                                            uniDataTaxType.setCode(uniDataTaxType.getCode());
                                            uniDataTaxType.setStateTaxRate(uniDataTaxType.getStateTaxRate());
                                            uniDataTaxType.setCountyTaxRate(uniDataTaxType.getCountyTaxRate());
                                            uniDataTaxType.setCountyTransTaxRate(uniDataTaxType.getCountyTransTaxRate());
                                            uniDataTaxType.setCityTaxRate(uniDataTaxType.getCityTaxRate());
                                            uniDataTaxType.setCityTransTaxRate(uniDataTaxType.getCityTransTaxRate());
                                        }
                                    }                                       
                                }
                            }
                        }
                    }
                }
            }
        }
        
        //TO DO add more assertions
        System.assert(bean != null);
        System.assertNotEquals(null, respbean);
        Asset__c theAsset = [SELECT Id FROM Asset__c LIMIT 1];
        TC_BridgewareSelectZipGeoCodeCtrl.getCurrentValues (theAsset.Id);
        Test.stopTest();
    }

    @isTest static void testSelectZipGeoCode2() {
        
        // Implement test code
        Test.setMock(HttpCalloutMock.class, new TC_BridgewareSelectZipGeoCalloutMockImpl ());
        TC_BridgewareService service = new TC_BridgewareServiceImpl ();
        
        Test.startTest();
        TC_BridgewareUtility.selectZipGeoCode ('55125', null, null);
        Test.stopTest();
    }


}