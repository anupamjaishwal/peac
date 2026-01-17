@isTest
public class AccountQuoteControllerTest {

    // SAL-2602 Increased test coverage due to webservice performance improvements
    @TestSetup
    static void setup() {

        String username = 'standardusertest123@northteq.com';

        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User u = new User(Alias = 'testuser', Email = 'sfdc@northteq.com', EmailEncodingKey='UTF-8',
                LastName = 'testing', FirstName = 'user', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles',
                Username = username, Doc_Fee_Exception_Approver__c = true);
        insert u;

        Account acc = new Account (Name = 'STATIC ACCOUNT FOR RATE CARDS',
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Franchisee Account').getRecordTypeId(),
                Business_Address__c = 'test', Business_City__c = 'test', Business_State__c = 'MN', Business_Zip__c = '11111');
        insert acc;

        TCRE__Rule_Config__c conf = new TCRE__Rule_Config__c();
        conf.TCRE__Priority__c = 1;
        conf.TCRE__SObject_Name__c = 'Opportunity';
        insert conf;

        TCRE__Rule_Condition__c cond = new TCRE__Rule_Condition__c();
        cond.TCRE__Rule_Config__c = conf.Id;
        cond.TCRE__Field_Name__c = 'Equipment_Cost__c';
        cond.TCRE__Operator__c = '>';
        cond.TCRE__Value__c = '50000';
        insert cond;

        RateCard__c rc = new RateCard__c();
        rc.Name = 'Mtest';
        rc.Entry_Criteria__c = conf.Id;
        insert rc;

        Rate_Card_Column__c col = new Rate_Card_Column__c();
        col.Rate_Card__c = rc.Id;
        col.Column_Criteria__c = conf.Id;
        col.Name = '36';
        insert col;

        Rate_Card_Row__c row = new Rate_Card_Row__c();
        row.Rate_Card__c = rc.Id;
        row.Row_Criteria__c = conf.Id;
        insert row;

        Rate_Card_Rate__c rate = new Rate_Card_Rate__c();
        rate.Rate_Card_Row__c = row.Id;
        rate.Rate_Card_Column__c = col.Id;
        rate.Rate__c = 1;
        insert rate;

        RateCard__c rc2 = new RateCard__c();
        rc2.Name = 'Mtest2';
        rc2.Entry_Criteria__c = conf.Id;
        insert rc2;

        Rate_Card_Column__c col2 = new Rate_Card_Column__c();
        col2.Rate_Card__c = rc2.Id;
        col2.Column_Criteria__c = conf.Id;
        col2.Name = '48';
        insert col2;

        Rate_Card_Row__c row2 = new Rate_Card_Row__c();
        row2.Rate_Card__c = rc2.Id;
        row2.Row_Criteria__c = conf.Id;
        insert row2;

        Rate_Card_Rate__c rate2 = new Rate_Card_Rate__c();
        rate2.Rate_Card_Row__c = row2.Id;
        rate2.Rate_Card_Column__c = col2.Id;
        rate2.Rate__c = 2;
        insert rate2;
    }

    public static TestMethod void test1(){

        User u = [SELECT Id FROM User WHERE Username = 'standardusertest123@northteq.com'];

        System.runAs(u) {
            Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId();
            Account acc = new Account();
            acc.Name = 'Test';
            acc.Account_Dealer_Status__c = '1-time Need Profile Unused';
            acc.Risk_Based_Pricing__c = true;
            acc.RecordTypeId = devRecordTypeId;
            insert acc;
            Lead objLead = new Lead();
            objLead.Related_Dealer__c = acc.Id;
            objLead.LastName = 'test';
            objLead.Company = 'testing';
            insert objLead;
            AccountQuoteController.getAccountRecord(acc.Id);
            AccountQuoteController.callWebserviceGetXMLResponse(acc.Id, 55005,objLead.Id );
            AccountQuoteController.getPortalCustCreditExpAndAutoPG(acc.Id, objLead.Id);
        }
    }
}