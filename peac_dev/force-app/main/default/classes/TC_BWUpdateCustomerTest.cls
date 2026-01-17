/**
 * Created by jhber on 3/6/2019.
 */

@isTest
public with sharing class TC_BWUpdateCustomerTest {

    @TestSetup static void setup () {
        // Setup test data
        SL_SCTestData.createBridgeWareSetting();

        Account act = new Account ();
        act.name = 'Update Test1';
        act.Phone = '2225551234';
        act.CCAN__c = '12345';
        act.Business_Phone__c = '5854567890';
        act.Sic = 'SICTest001';
        insert act;
    }

    @isTest
    static void testUpdate() {
        List<Account> acc = [SELECT Id, Name, CCAN__c, Business_Phone__c, Phone FROM Account];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TC_BWcreateCustomerCalloutMockImpl ());
        TC_BWUpdateCustomerCtrl.updateCustomer(acc);
        SL_InfoleaseAssetRequestWrapper coverageWrapper = new SL_InfoleaseAssetRequestWrapper();
        Test.stopTest();
    }
}