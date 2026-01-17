/**
 * Created by trohweder on 12/29/20.
 */

@IsTest
public with sharing class TC_DwhStoredProcedureApiTest {
    @TestSetup
    static void createTestData(){

        List<Account> accList = new List<Account>();

        Account acc = new Account(Name = 'test',
                            Tax_ID__c = '999999999',
                            CCAN__c = '999999999',
                            Business_City__c = 'Test',
                            Business_State__c = 'MN',
                            Business_Zip__c = '55421',
                            Business_Phone__c = '7778889999');
        accList.add(acc);

        Account dealer = new Account(Name = 'test',
                                    Dealer_Number__c = '13423412.1341234',
                RecordTypeId = [SELECT Id FROM RecordType WHERE Name LIKE '%Dealer%' LIMIT 1].Id);
        accList.add(dealer);
        insert accList;

        List<Contact> contacts = new List<Contact>();

        Contact pg1 = new Contact(
                FirstName = 'Todd',
                LastName = 'Test',
                Email = 'ttest@mailinator.com',
                Phone = '7777777777',
                SSN__c = '555999444',
                MailingCity = 'Test',
                MailingState = 'Minnesota',
                MailingStreet = 'Test Street',
                MailingPostalCode = '77789'
        );
        contacts.add(pg1);
        Contact pg2 = new Contact(
                FirstName = 'Ty',
                LastName = 'Test',
                Email = 'tytest@mailinator.com',
                Phone = '7777777778',
                SSN__c = '555999455',
                MailingCity = 'Test',
                MailingState = 'Minnesota',
                MailingStreet = 'Test Street',
                MailingPostalCode = '77789'
        );
        contacts.add(pg2);
        insert contacts;

        Test.startTest();
        RecordType rt2 = [SELECT Id,Name FROM RecordType WHERE SobjectType='Opportunity' AND Name LIKE '%Express Decision%' LIMIT 1];
        System.debug('Got Record');
        Opportunity op = new Opportunity();
        op.Name = 'Test Opp';
        op.RecordTypeId = rt2.Id;
        op.AccountId = acc.Id;
        op.Amount = 100;
        op.StageName = 'Quote';
        op.Primary_Source__c = 'Email';
        op.CloseDate = System.today() + 30;

        insert op;
        Test.stopTest();


    }

    @IsTest
    static void testDwhStoredProcedureApi(){
        Test.setMock(HttpCalloutMock.class, new TC_DwhStoredProcedureApiCalloutMock());

        Test.startTest();
        Account acc = [SELECT Id FROM Account WHERE Tax_ID__c = '999999999' LIMIT 1];

        TC_DwhStoredProcedureRespBean resp = new TC_DwhStoredProcedureRespBean();

        resp = TC_DwhStoredProcedureApi.getPortalCustCreditExp(acc.Id);
        Test.stopTest();

        System.assertEquals('1719232', resp.results[0].Customer_CCAN);
        System.assertEquals('0', resp.results[0].COVID_Restructure);

    }

    @IsTest
    static void testDwhStoredProcedureApiWithOpp(){
        //
        Test.setMock(HttpCalloutMock.class, new TC_DwhStoredProcedureApiCalloutMock());

        Test.startTest();
        Account acc = [SELECT Id FROM Account WHERE Tax_ID__c = '999999999' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];

        TC_DwhStoredProcedureRespBean resp = new TC_DwhStoredProcedureRespBean();

        resp = TC_DwhStoredProcedureApi.getPortalCustCreditExp(acc.Id, opp.Id);
        Test.stopTest();

        System.assertEquals('1719232', resp.results[0].Customer_CCAN);
        System.assertEquals('0', resp.results[0].COVID_Restructure);

    }

    @IsTest
    static void testDwhStoredProcedureFraudCall(){
        Test.setMock(HttpCalloutMock.class, new TC_DwhStoredProcedureFraudCalloutMock());
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        TC_DwhStoredProcedureRespBean resp = new TC_DwhStoredProcedureRespBean();

        resp = TC_DwhStoredProcedureApi.businessFraudQuery(opp.Id);
        System.debug('resp: ' + resp);
    }

    @IsTest
    static void testDwhStoredProcedurePGCall(){

        TC_DwhStoredProcedureRespBean resp = new TC_DwhStoredProcedureRespBean();

        Test.setMock(HttpCalloutMock.class, new TC_DwhStoredProcedurePgCalloutMock());

        Opportunity op = [SELECT Id FROM Opportunity LIMIT 1];

        resp = TC_DwhStoredProcedureApi.businessFraudQuery(op.Id);
        System.debug('resp: ' + resp);

        List<Contact> contacts = [SELECT Id FROM Contact];

        Guarantor__c g = new Guarantor__c(
                RecordTypeId = Schema.SObjectType.Guarantor__c.getRecordTypeInfosByName().get('Personal').getRecordTypeId(),
                Type__c='Personal Guarantor',
                Opportunity__c = op.Id,
                Contact__c = contacts[0].Id
        );
        Test.startTest();
        insert g;

        resp = TC_DwhStoredProcedureApi.businessFraudQuery(op.Id);
        System.debug('resp: ' + resp);

        Guarantor__c g2 = new Guarantor__c(
                RecordTypeId = Schema.SObjectType.Guarantor__c.getRecordTypeInfosByName().get('Personal').getRecordTypeId(),
                Type__c='Personal Guarantor',
                Opportunity__c = op.Id,
                Contact__c = contacts[1].Id
        );

        insert g2;
        Test.stopTest();


        resp = TC_DwhStoredProcedureApi.businessFraudQuery(op.Id);
        System.debug('resp: ' + resp);
    }

    @IsTest
    static void testWebserviceMapper(){
        TC_DwhStoredProcedureRespBean resp1 = new TC_DwhStoredProcedureRespBean();
        TC_DwhStoredProcedureRespBean resp2 = new TC_DwhStoredProcedureRespBean();

        Opportunity op = [SELECT Id FROM Opportunity LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new TC_DwhStoredProcedureFraudCalloutMock());

        resp1 = TC_DwhStoredProcedureApi.businessFraudQuery(op.Id);
        System.debug('resp2: ' + resp1);
        Webservice_Field__c wsf = new Webservice_Field__c(Opportunity__c=op.Id);
        insert wsf;

        Test.startTest();
        TC_DwhStoredProcedureMapper.mapBeansToWebserviceField(op.Id, resp1);
        Test.stopTest();

    }

    @IsTest
    static void testDwhStoredProcedureApiErrorCatch(){
        Test.startTest();
        TC_DwhStoredProcedureApi.getPortalCustCreditExp(null);
        TC_DwhStoredProcedureApi.getPortalCustCreditExp(null, null);
        TC_DwhStoredProcedureApi.businessFraudQuery(null);
        Test.stopTest();
    }

}