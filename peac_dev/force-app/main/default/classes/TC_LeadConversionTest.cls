@IsTest
public class TC_LeadConversionTest {
    @TestSetup
    static void makeData(){

        Bridgeware_Service_Setting__c setting = new Bridgeware_Service_Setting__c ();
        setting.Enable_Debug_Log__c = true;
        setting.Mock_Callout__c = true;
        setting.Mock_Endpoint__c = 'https://private-b2bb6-bridgewaretamarack.apiary-mock.com/';
        setting.SetupOwnerId = UserInfo.getOrganizationId ();
        setting.Config_Name__c = 'TEST';
        insert setting;
        Test.startTest();
        Account ac = TestDataFactory.createTestAccount();
        TestDataFactory.createTestContact(ac.Id);
        TestDataFactory.createTestOpp(ac.Id);
        Test.stopTest();
    }
    @IsTest
    public static void test1(){

        Account ac = [SELECT Id FROM Account LIMIT 1];
        Contact c = [SELECT Id, FirstName, LastName, Email FROM Contact LIMIT 1];
        Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];
        Lead l = TestDataFactory.createTestLead();
        l.Guarantor_First_Name__c = c.FirstName;
        l.Guarantor_Last_Name__c = c.LastName;
        l.Guarantor_email__c = c.Email;
        Map<ID, Lead>newMap=new Map<ID, Lead>();
        Map<ID, Lead>oldMap=new Map<ID, Lead>();
        oldMap.put(l.Id, l);
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(l.id);
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TC_BridgewareSelectZipGeoCalloutMockImpl ());

        try{
            Database.LeadConvertResult lcr = Database.convertLead(lc);
            System.debug('Lead is Converted!');
        }
        catch(Exception e){
            System.debug('Conversion Error: ' + e.getMessage());
            System.debug(e.getStackTraceString());
        }
        Test.stopTest();
        newMap.put(l.Id, l);

        try{
            TC_LeadConversion.attachExtraObjects(oldMap, newMap);}
        catch(Exception e){
            System.debug('Conversion Error: ' + e.getMessage());
            System.debug(e.getStackTraceString());
        }
        
    }    

    @IsTest
    static void test2(){
        ORE__c ore = new ORE__c(Bypass__c = true);
        insert ore;

        Account ac = [SELECT Id, Dealer_Number__c FROM Account LIMIT 1];
        Contact c = [SELECT Id, FirstName, LastName, Email FROM Contact LIMIT 1];
        Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];
        Lead l = TestDataFactory.createTestLead();
        l.Guarantor_First_Name__c = c.FirstName;
        l.Guarantor_Last_Name__c = c.LastName;
        l.Guarantor_email__c = c.Email;
        l.Dealer_name__c='Doe';
        l.Dealer_phone__c='1231231334';
        l.Dealer_email__c='doe@john.com';
        l.Equipment_Type__c='ATM';
        l.Equipment_Address_Line_1__c='123 Main St';
        l.Equipment_City__c='Equip City';
        l.Equipment_State__c='NY';
        l.Equipment_Zipcode__c='12345';

        User u=TestDataFactory.createTestUser();

        TC_LeadConversion.concatenateAddressFields(l, 0);
        TC_LeadConversion.concatenateAddressFields(l, 1);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TC_BridgewareSelectZipGeoCalloutMockImpl ());

        try{
            TC_LeadConversion.attachExtraObjects(l,ac.Id, c.Id,o.Id, u.Id);
            }
        catch(Exception e){
            System.debug('Conversion Error: ' + e.getMessage());
            System.debug(e.getStackTraceString());
        }
        test.stopTest();

        TC_LeadConversion.boost();
    }

}