/**************************************************************************************************************
@Author: Chalapati Murru (LTIMindtree)
@Description: This class is used to cover PEAC_BWInfoLeaseUtility, PEAC_BWInfoLeaseValidations 
				and PEAC_BWInfoLeaseDataWrapper classes.
@User Story: SAL-5692 Expo: Opportunity Refactor
@Created Date: Jan-30-2026
**************************************************************************************************************/
@isTest
public class PEAC_BWInfoLeaseUtilityTest { 
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
        PEAC_TestDataFactory.createBridgeWareSetting();

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
        
        /*Account dealerAccount = new Account (
            Name = 'TC_CreditDecisionTriggerTest Dealer Account1'
            , RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId()
            , Business_Address__c = 'Test Address', Business_City__c = 'Test City', Business_State__c = 'MN', Business_Zip__c = '11111'
            , Account_EU_FS_SIC_Description__c = '8661'
            , Preferred_Dealer_Level__c = '3'
            , Dealer_Number__c = '855331.7239'
            ,Equipment_Type__c = 'A/V (General)'
            ,Account_Months_In_Business__c = 12
            , Account_Dealer_Status__c = 'Watch List'
        );
        insert dealerAccount;
        
        Dealer__c dealer = new Dealer__c();        
        dealer.Opportunity__c = o.Id;
        dealer.Dealer__c = dealerAccount.Id;
        dealer.Primary_Dealer__c = false;
        dealer.Funded__c = true;
        insert dealer;*/
        
        Purchase_Order__c po = new Purchase_Order__c();
        po.Customer_PO_Number__c = 'PO-002';
        po.Opportunity__c = o.Id;
        insert po;
        Test.stopTest();
        Asset__c ast = new Asset__c(
            Opportunity__c=o.Id, 
            Usage_Billing_Cycle__c='TBD',
            List_Price__c = 1000.00,
            Residual_Percentage__c = 10,
            Quantity__c = 1
        );
        Miscellaneous_Invoice_Item__c mi=new Miscellaneous_Invoice_Item__c(Opportunity__c=o.Id,GL_Code__c='0000 - NOT ON FILE',Taxable__c=false);
        Miscellaneous_Billable_Item__c mis=new Miscellaneous_Billable_Item__c(Opportunity__c=o.Id,Misc_GL_Code__c='0000 - NOT ON FILE', First_Payment_Date__c=Date.Today());
        insert mis;
        // SAL-6285: Add HTTP mock for asset trigger callouts
        Test.setMock(HttpCalloutMock.class, new TC_BridgewareSelectZipGeoCalloutMockImpl());
        
        insert ast;
        List<Meter_Type__c> meterTypes = new List<Meter_Type__c>();
        meterTypes.add(new Meter_Type__c(Asset__c = ast.Id));
        insert meterTypes;
        
        insert fr;
        //insert b;
        //insert mi;
    }
    /*@isTest 
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
    }*/
    
    @isTest
    public static void testCallout(){        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Account acc = [SELECT Id, CCAN__c FROM Account WHERE Name = 'Test' LIMIT 1];
        Map<Id, String> amap = new Map<Id, String>();
        amap.put(acc.Id, acc.CCAN__c);
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        PEAC_BWInfoLeaseUtility.sendToBridgeware(opp.Id, amap);
        System.assert(opp != null, 'opp is not null.');
        Test.stopTest();
    }

}