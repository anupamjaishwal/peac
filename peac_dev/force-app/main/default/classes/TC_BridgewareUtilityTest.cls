@isTest
/**
 * Test class to cover TC_BridgewareUtility
 * Created by: Northteq
 */
public class TC_BridgewareUtilityTest {
    @TestSetup
    static void makeData(){
        Tax_Rules_Settings__c settings = new Tax_Rules_Settings__c();
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
        
        Rate__c rate = new Rate__c();
        rate.State__c = 'MN';
        rate.County__c = 'WASHINGTON';
        rate.City__c = 'WOODBURY';
        rate.State_Code__c = '24';
        rate.County_Code__c = '163';
        rate.City_Code__c = '1740';
        rate.Rate_Code__c = '001';
        rate.State_Tax_Rate__c = 0.01;
        rate.County_Tax_Rate__c = 0.01;
        rate.County_Transit_Tax_Rate__c = 0.01;
        rate.City_Tax_Rate__c = 0.01;
        rate.City_Transit_Tax_Rate__c = 0.01;
        insert rate;
        
        TCRE__Rule_Config__c conf = new TCRE__Rule_Config__c();
        conf.TCRE__SObject_Name__c = 'Opportunity';
        conf.TCRE__Priority__c = 1;
        insert conf;
        
        TCRE__Rule_Condition__c cond1 = new TCRE__Rule_Condition__c();
        cond1.TCRE__Field_Name__c = 'StageName';
        cond1.TCRE__Operator__c = '=';
        cond1.TCRE__Value__c = 'test';
        cond1.TCRE__Rule_Config__c = conf.Id;
        insert cond1;

        TCRE__Rule_Condition__c cond2 = new TCRE__Rule_Condition__c();
        cond2.TCRE__Field_Name__c = 'CreatedDate';
        cond2.TCRE__Operator__c = '>';
        cond2.TCRE__Value__c = '12/12/2010';
        cond2.TCRE__Rule_Config__c = conf.Id;
        insert cond2;
        
        TCRE__Rule_Condition__c cond3 = new TCRE__Rule_Condition__c();
        cond3.TCRE__Field_Name__c = 'Amount';
        cond3.TCRE__Operator__c = '<';
        cond3.TCRE__Value__c = '234.56';
        cond3.TCRE__Rule_Config__c = conf.Id;
        insert cond3;
        
        Tax_Rule__c tr = new Tax_Rule__c();
        tr.Rule_Config__c = conf.Id;
        tr.State__c = 'MN';
        tr.Tax_Basis_Field__c = 'Amount';
        tr.Rate_Code_to_Use__c = '001';
        tr.Description__c = 'Description';
        tr.Tax_type__c = 'Regular';
        tr.State_Rate_Code_to_Use__c = '001';
        tr.County_Rate_Code_to_Use__c = '001';
        tr.TCounty_Rate_Code_to_Use__c = '001';
        tr.City_Rate_Code_to_Use__c = '001';
        tr.TCity_Rate_Code_to_Use__c = '001';
        insert tr;
        ORE__c oc = new ORE__c(Bypass__c = true);

		insert oc;
        SL_SCTestData.createBridgeWareSetting();

        Test.startTest();
        Account ac=TestDataFactory.createTestAccount();
        //ac.RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Franchisor Account').getRecordTypeId();
        //update ac;
        Opportunity o=TestDataFactory.createTestOpp(ac.Id);
        Account bracct=new Account(Name='Broker Acc',recordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker Account').getRecordTypeId());
        Account fracct=new Account(Name='Franchise Acc',recordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Franchisor Account').getRecordTypeId());
        List<Account> accs = new List<Account>{bracct, fracct};
        insert accs;
        //Account bracc = [SELECT Id, CCAN__c FROM Account WHERE Name = 'Broker Acc' LIMIT 1];
        //Account fracc = [SELECT Id, CCAN__c FROM Account WHERE Name = 'Franchise Acc' LIMIT 1];
		Broker__c b = new Broker__c(Opportunity__c=o.Id,Account__c=bracct.Id);
        Franchisor__c fr = new Franchisor__c(Opportunity__c=o.Id, Franchisor__c=fracct.Id);
        Asset__c ast = new Asset__c(Opportunity__c=o.Id, Usage_Billing_Cycle__c='TBD');
        Miscellaneous_Invoice_Item__c mi=new Miscellaneous_Invoice_Item__c(Opportunity__c=o.Id,GL_Code__c='0000 - NOT ON FILE',Taxable__c=false);
        Miscellaneous_Billable_Item__c mis=new Miscellaneous_Billable_Item__c(Opportunity__c=o.Id,Misc_GL_Code__c='0000 - NOT ON FILE', First_Payment_Date__c=Date.Today());
        insert mis;
        Test.stopTest();
        insert ast;
        insert fr;
        insert b;
        insert mi;
    }
    @isTest 
    public static void testCreateRequest(){
        
        Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];
        Account ac = [SELECT Id, CCAN__c FROM Account WHERE Name = 'Test' LIMIT 1];
        Map<Id, String>amap=new Map<Id, String>();
        amap.put(ac.Id, ac.CCAN__c);
        
        Guarantor__c g=new Guarantor__c(Account__c=ac.Id,Opportunity__c=o.Id);
        Variable_Payment__c p=new Variable_Payment__c(Opportunity__c=o.Id,Payment_Amount__c=1);
        Blended_Income_Item__c c=new Blended_Income_Item__c(Opportunity__c=o.Id,Blended_Income_Amount__c=3);
        Test.startTest();
        insert p;
        insert g;
        insert c;
        
       	TC_BridgewareUtility u = TC_BridgewareUtility.getInstance();
        u.getServiceSettings();
        u.logError('This is test');
        u.logInfo('This is test');
        Test.stopTest();
        TC_BridgewareBookContractRequestBean bean = TC_BridgewareUtility.createRequest(o.Id,amap);
        System.assert(bean != null, 'null was returned.');
    }
    
    @isTest
    public static void testCallout(){        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Account acc = [SELECT Id, CCAN__c FROM Account WHERE Name = 'Test' LIMIT 1];
        Map<Id, String> amap = new Map<Id, String>();
        amap.put(acc.Id, acc.CCAN__c);
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        TC_BridgewareUtility.sendToBridgeware(opp.Id);
        System.assert(opp != null, 'opp is not null.');
        Test.stopTest();
    }

    @isTest
    public static void testTransState(){
        TC_BridgewareUtility.transState('');
        String state = TC_BridgewareUtility.transState('Minnesota');
        System.assert(state == 'MN', 'State was ' + state);
    }

    @isTest
    public static void testCreateQueryString(){
        Set<String> queryFields = new Set<String>{'Id', 'Name'};
        String objectType = 'Account';
        String keyField = 'Name';
        String key = 'Test';
        String query = TC_BridgewareUtility.createQueryString(queryFields, objectType, keyField, key);
        List<Account> a = Database.query(query);

        System.assert(a.size() > 0, 'a size was ' + a.size());
    }

    @isTest
    public static void testGetTaxJurisdictions(){
        TC_BridgewareSelectZipGeoCodeRespBean bean = new TC_BridgewareSelectZipGeoCodeRespBean();
        TC_BridgewareSelectZipGeoCodeRespBean.UniDataZipGeoCodeContentData uniData = new TC_BridgewareSelectZipGeoCodeRespBean.UniDataZipGeoCodeContentData();
        TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipState uniDataVtZipState = new TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipState();
        uniDataVtZipState.setCode('test');
        uniDataVtZipState.setDescription('test');
        TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipCounty uniDataVtZipCounty = new TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipCounty();
        uniDataVtZipCounty.setCode('test');
        uniDataVtZipCounty.setDescription('test');
        TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipCity uniDataVtZipCity = new TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipCity();
        uniDataVtZipCity.setCode('test');
        uniDataVtZipCity.setDescription('test');
        TC_BridgewareSelectZipGeoCodeRespBean.UniDataTaxType uniDataVtTaxType = new TC_BridgewareSelectZipGeoCodeRespBean.UniDataTaxType();
        uniDataVtTaxType.setCode('test');
        uniDataVtTaxType.setDescription('test');
        uniDataVtTaxType.setStateTaxRate(1);
        uniDataVtTaxType.setCountyTaxRate(1);
        uniDataVtTaxType.setCountyTransTaxRate(1);
        uniDataVtTaxType.setCityTaxRate(1);
        uniDataVtTaxType.setCityTransTaxRate(1);

        uniDataVtZipCity.setTaxTypeList(new List<TC_BridgewareSelectZipGeoCodeRespBean.UniDataTaxType>{uniDataVtTaxType});
        uniDataVtZipCounty.setVtZipCityList(new List<TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipCity>{uniDataVtZipCity});
        uniDataVtZipState.setVtZipCountyList(new List<TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipCounty>{uniDataVtZipCounty});
        uniData.setVtZipStateList(new List<TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipState>{uniDataVtZipState});
        bean.setContentData(uniData);

        List<TC_BridgewareTaxJurisdiction> j = TC_BridgewareUtility.getTaxJurisdictions(bean);

        System.assert(j.size() > 0, 'There are no TC_BridgewareTaxJurisdiction records returned');
    }

    static testMethod void testTC_BridgewareTaxJurisdiction(){
        TC_BridgewareTaxJurisdiction j = new TC_BridgewareTaxJurisdiction();
        j.city = 'test';
        j.cityCode = 'test';
        j.county = 'test';
        j.countyCode = 'test';
        j.state = 'test';
        j.stateCode = 'test';
        j.zip = 'test';
        j.rateCodeDescription = 'test';
        j.rateCode = 'test';
        j.stateTaxRate = 1;
        j.countyTaxRate = 1;
        j.countyTransTaxRate = 1;
        j.cityTaxRate = 1;
        j.cityTransTaxRate = 1;
        j.zipUpdated = true;
    }
    
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success", "message":"Mocked response"}');
            res.setStatusCode(200);
            return res;
        }
    }
}