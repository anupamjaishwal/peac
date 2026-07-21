/**************************************************************************************************************
@Author: Chalapati Murru (LTIMindtree)
@Description: This class is used to cover PEAC_OpportunityValidationUtil
@User Story: SAL-7102 Expo: Opportunity Validation
@Created Date: 12-May-2026
**************************************************************************************************************/
@IsTest
public class PEAC_OpportunityValidationUtilTest {
	
    @TestSetup
    static void makeData(){
        Account acc = new Account (
            Name = 'test', Account_Dealer_Status__c = 'Ineligible',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId()
        );
        insert acc;

        Account dealer = new Account(
            Name = 'dealer',Account_Dealer_Status__c = 'Ineligible',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId()
        );
        insert dealer;
        
        Contact c = new Contact (
            AccountId = acc.Id, 
            FirstName = 'test', 
            LastName = 'contact', 
            MailingStreet = 'test', 
            MailingCity = 'test', 
            MailingStateCode = 'MN', 
            MailingPostalCode = '11111', 
            MailingCountry='United States', 
            Phone='5555555555',
            Title = 'title', 
            SSN__c = '111111111', 
            BirthDate = Date.today (), 
            Email = 'test123@test.com'
        );
        insert c;

        Opportunity opp = new Opportunity(
            AccountId = acc.Id,
            StageName = 'test',
            CloseDate = date.today () + 10,
            Name = 'test'
        );
        Test.startTest();
        insert opp;
        Test.stopTest();
        Dealer__c d = new Dealer__c(Opportunity__c = opp.Id, Dealer__c = dealer.Id, Primary_Dealer__c = false);
        insert d;
        
    }
    
    /*@IsTest
    public static void readyToDocValidationErrorTest(){
        Opportunity opp = [SELECT Id, Ready_to_Doc__c FROM Opportunity LIMIT 1];
		
        Test.startTest();
        opp.Ready_to_Doc__c = 'Yes';
        //opp.Application_Status__c = 'Approved';
        update opp;
        Test.stopTest();
    }*/
    
    @IsTest
    public static void readyToDocValidtnErrorTest(){
        
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, StageName FROM Opportunity LIMIT 1]);
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();
        
        for(Id key : oldMap.keyset()){
            Opportunity o = new Opportunity(
                Id = key, 
                StageName = 'Docs Out',
                Docs_In__c = Date.Today(),
                Ready_to_Doc__c = 'Yes');
            newMap.put(key, o);
        }
        Test.startTest();
        try{
            PEAC_OpportunityValidationUtil.readyToDocValidationError(newMap.values(), oldMap);
        }
        catch (DmlException e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }
        catch (Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }
        Test.stopTest();
     }
}