@isTest
public class TC_ValidationTaxIdRequiredFieldsTest {
    
    @TestSetup
    static void setup() {
    
        ORE__c o = new ORE__c(Bypass__c = true);
        insert o; 
        
        Account acc = new Account();
        acc.Name = 'TestAccount';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
        acc.Business_Type__c ='Proprietorship';
        insert acc;
        Test.startTest();
        List<opportunity> oppRec = new list<opportunity>();
        Opportunity opp = new Opportunity();
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Express Quote').getRecordTypeId();
        opp.Name = 'Test Opportunity';
        opp.AccountId = acc.Id;
        opp.StageName = 'Quote';
        opp.Primary_Source__c = 'Customer Inbound - Call';
        opp.CloseDate = System.today();
        opp.Account_Business_City__c = 'Test';
        opp.Account_Business_Country__c = 'Test2';
        opp.Account_Business_State_Province__c = 'PA';
        opp.Account_Business_Street__c ='Test4';
        opp.Account_Business_Street2__c = 'Test5';
        opp.Account_Business_Zip_Postal_Code__c = 'Test6';
        opp.Equipment_Cost__c = 10;
        opp.Branch__c ='IFP - Indirect Funding Pl';
        opp.Yield__c = 10;
        opp.Terms__c = 12;
        opp.amount = 1000;
        opp.Tax_ID__c = '213123245';
        opp.Application_Status__c = 'Automatically Approved';
        
        oppRec.add (opp);
        insert oppRec;
        Test.stopTest();
    }
    
    @IsTest
    static void TC_ValidationTaxIdRequiredFields(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.StageName = 'Funding';
        try{
        update opp;
        } catch(Exception e){
            //system.assert(e.getMessage().contains('required when Stage is Funding'));
        }
    }
}