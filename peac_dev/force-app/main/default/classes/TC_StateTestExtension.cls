@isTest
public class TC_StateTestExtension {
    
   @TestSetup
    static void setup() {
        ORE__c o = new ORE__c(Bypass__c = true);
        insert o;  
        
        Account acc = new Account();
        acc.Name = 'TestAccount';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
        acc.Business_Type__c ='Proprietorship';
        
        insert acc;
        

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
        
        Opportunity opp1 = new Opportunity();
        opp1.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('HKF Quote').getRecordTypeId();
        opp1.Name = 'Test California';
        opp1.AccountId = acc.Id;
        opp1.StageName = 'Decision';
        opp1.Primary_Source__c = 'Customer Inbound - Call';
        opp1.CloseDate = System.today();
        opp1.Account_Business_City__c = 'Test';
        opp1.Account_Business_Country__c = 'Test2';
        opp1.Account_Business_State_Province__c = 'PA';
        opp1.Account_Business_Street__c ='Test4';
        opp1.Account_Business_Street2__c = 'Test5';
        opp1.Account_Business_Zip_Postal_Code__c = 'Test6';
        opp1.Equipment_Cost__c = 10;
        opp1.Branch__c ='IFP - Indirect Funding Pl';
        opp1.Yield__c = 10;
        opp1.Terms__c = 12;
        opp1.amount = 1000;
        opp1.Tax_ID__c = '213123245';
        opp1.Application_Status__c = 'Automatically Approved';
       // opp1.Purchase_Options__c = '1.00 Out';
        opp1.Purchase_Options__c = 'FMV';
        opp1.Contract_Type__c = 'IN';
        opp1.Payment_Amount__c = 50;

        oppRec.add (opp1);
        
        
        Opportunity oppNorthDakota = new Opportunity();
        oppNorthDakota.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('HKF Quote').getRecordTypeId();
        oppNorthDakota.Name = 'Test NorthDakota';
        oppNorthDakota.AccountId = acc.Id;
        oppNorthDakota.StageName = 'Decision';
        oppNorthDakota.Primary_Source__c = 'Customer Inbound - Call';
        oppNorthDakota.CloseDate = System.today();
        oppNorthDakota.Account_Business_City__c = 'Test';
        oppNorthDakota.Account_Business_Country__c = 'Test2';
        oppNorthDakota.Account_Business_State_Province__c = 'PA';
        oppNorthDakota.Account_Business_Street__c ='Test4';
        oppNorthDakota.Account_Business_Street2__c = 'Test5';
        oppNorthDakota.Account_Business_Zip_Postal_Code__c = 'Test6';
        oppNorthDakota.Equipment_Cost__c = 40000;
        oppNorthDakota.Branch__c ='IFP - Indirect Funding Pl';
        oppNorthDakota.Yield__c = 10;
        oppNorthDakota.Terms__c = 10;
        oppNorthDakota.amount = 40000;
        oppNorthDakota.Tax_ID__c = '213123245';
        oppNorthDakota.Application_Status__c = 'Automatically Approved';
       // opp1.Purchase_Options__c = '1.00 Out';
        oppNorthDakota.Purchase_Options__c = 'FMV';
        oppNorthDakota.Contract_Type__c = 'IN';
        oppNorthDakota.Payment_Amount__c = 50;

        oppRec.add (oppNorthDakota);
        
        Test.startTest();
        insert oppRec;
        oppNorthDakota.Account_Business_State_Province__c = 'NM';
        update oppNorthDakota;
        //oppNorthDakota.Equipment_Cost__c = 100000;
        //update oppNorthDakota;
        
        List<Approved_Offer__c> AORec = new list<Approved_Offer__c>();
        
        Approved_Offer__c offer = new Approved_Offer__c ();
        offer.Opportunity__c = opp.Id;
        offer.Offer_Amount__c = 1200;
        offer.Max_Rate__c = 1.0;
        offer.Term__c = 12;
        offer.Selected_Offer_Amount__c = 10;
        
        AORec.add (offer);
        
        Approved_Offer__c offerNorthDakota = new Approved_Offer__c ();
        offerNorthDakota.Opportunity__c = oppNorthDakota.Id;
        offerNorthDakota.Offer_Amount__c = 40000;
        offerNorthDakota.Max_Rate__c = 1.0;
        offerNorthDakota.Term__c = 10;
        offerNorthDakota.Selected_Offer_Amount__c = 40000;
        
        AORec.add (offerNorthDakota);
        insert AORec;
        
        opp.Selected_Approved_Offer__c = offer.Id;
        update opp;
        
        oppNorthDakota.Selected_Approved_Offer__c = offerNorthDakota.Id;
        update oppNorthDakota;
        Test.stopTest();
    }
    
     @IsTest
    static void testForNorthDakota() {

        Opportunity o = [SELECT Id, Name, StageName,Account_Business_State_Province__c,Business_Type__c,Equipment_Cost__c,Branch__c,Terms__c,Max_Rate__c,Yield__c,Loan_Amount__c,Purchase_Options__c,AccountId  FROM Opportunity WHERE Name = 'Test NorthDakota'];
        //o.Account_Business_State_Province__c = 'NM';
        //update o;
        system.debug('===inside northdakota'+ o.Loan_Amount__c);
        Account acc = [SELECT ID,Name,RecordTypeId, Business_State__c,Business_Type__c from Account Where Name = 'TestAccount'];
            
        Test.startTest();
        TC_StateRules.northDakota(o, acc);
        TC_StateRules.stateFinder(o.id);
         o.Account_Business_State_Province__c = 'NY';
        update o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'NE';
        update o;
        TC_StateRules.stateFinder(o.id);
         o.Account_Business_State_Province__c = 'NJ';
        update o;
        TC_StateRules.stateFinder(o.id);
         o.Account_Business_State_Province__c = 'FL';
        update o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'TX';
        update o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'MI';
        update o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'CO';
        update o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'OK';
        update o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'NV';
        update o;
        TC_StateRules.stateFinder(o.id);
       
        Test.stopTest();
    }
    
    @IsTest
    static void stateFinder() {
        Test.startTest();
        Opportunity o = [SELECT Id, Name, StageName,Account_Business_State_Province__c,Business_Type__c,Equipment_Cost__c,Branch__c,Terms__c,Max_Rate__c,Yield__c,Loan_Amount__c,Purchase_Options__c,AccountId  FROM Opportunity WHERE Name = 'Test NorthDakota'];
        system.debug('===inside northdakota'+ o.Loan_Amount__c);
        Account acc = [SELECT ID,Name,RecordTypeId, Business_State__c,Business_Type__c from Account Where Name = 'TestAccount'];
        o.Account_Business_State_Province__c = 'OR';
        update o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'MT';
        update o;
        TC_StateRules.stateFinder(o.id);
        acc.Business_Type__c = 'Proprietorship';
        o.Equipment_Cost__c = 5000;
        
        TC_StateRules.delaware(o, acc);
        TC_StateRules.northDakota(o, acc);
        Test.stopTest();
    }

}