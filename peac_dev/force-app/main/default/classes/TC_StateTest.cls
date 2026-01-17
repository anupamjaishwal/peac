@isTest
public class TC_StateTest {
    
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
        opp1.Opportunity_Document_Template__c = 'Lease';

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
    static void testForCalifornia() {

        Opportunity o = [SELECT Id, Name, StageName,Account_Business_State_Province__c,Business_Type__c,Equipment_Cost__c,Branch__c,Terms__c,Max_Rate__c,Yield__c,Loan_Amount__c,Purchase_Options__c,AccountId  FROM Opportunity WHERE Name = 'Test California'];
        Account acc = [SELECT ID,Name,RecordTypeId, Business_State__c,Business_Type__c from Account Where Name = 'TestAccount'];
            
        Test.startTest();
        TC_StateRules.california(o);
        o.Purchase_Options__c = '1.00 Out';
        o.Opportunity_Document_Template__c = 'Lease';
        update o;
        TC_StateRules.california(o);
        Test.stopTest();
    }
    
    @IsTest
    static void testFornewmexvirginia() {

        Opportunity o = [SELECT Id, Name, StageName,Account_Business_State_Province__c,Business_Type__c,Equipment_Cost__c,Branch__c,Terms__c,Max_Rate__c,Yield__c,Loan_Amount__c,Purchase_Options__c,AccountId  FROM Opportunity WHERE Name = 'Test California'];
        o.Account_Business_State_Province__c = 'NM';
        update o;
        Account acc = [SELECT ID,Name,RecordTypeId, Business_State__c,Business_Type__c from Account Where Name = 'TestAccount'];
        
        TC_StateRules.newmexico(o);
        TC_StateRules.virginia(o);
        o.Account_Business_State_Province__c = 'RI';
        update o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'CA';
        update o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'VT';
        update o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'AL';
        update o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'MS';
        update o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'VA';
        update o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'CT';
        update o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'MN';
        update o;
        TC_StateRules.stateFinder(o.id);
        Test.startTest();
        o.Account_Business_State_Province__c = 'GA';
        update o;
        TC_StateRules.stateFinder(o.id);
         o.Account_Business_State_Province__c = 'ND';
        update o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'AK';
        update o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'OK';
        update o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'CO';
        update o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'NV';
        update o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'DE';
        o.Equipment_Cost__c = 120000;
        acc.Business_Type__c = 'Corporation';
        update acc;
        update o;
        TC_StateRules.stateFinder(o.id);
        o.Equipment_Cost__c = 10001;
        update o;
        TC_StateRules.newmexico(o);
        TC_StateRules.virginia(o);
        TC_StateRules.minnesota(o, acc);
        Test.stopTest();
    }
    
    @IsTest
    static void testForNorthDakota() {

        Opportunity o = [SELECT Id, Name, StageName,Account_Business_State_Province__c,Business_Type__c,Equipment_Cost__c,Branch__c,Terms__c,Max_Rate__c,Yield__c,Loan_Amount__c,Purchase_Options__c,AccountId  FROM Opportunity WHERE Name = 'Test NorthDakota'];
        Account acc = [SELECT ID,Name,RecordTypeId, Business_State__c,Business_Type__c from Account Where Name = 'TestAccount'];
        Approved_Offer__c NorthDok = [SELECT ID,Max_Rate__c from Approved_Offer__c Where Opportunity__c =: o.id];    
        Test.startTest();
        TC_StateRules.northDakota(o, acc);
        NorthDok.Max_Rate__c = 2.0;
        o.Yield__c = 39;
        update NorthDok;
        update o;
        TC_StateRules.northDakota(o, acc);
        o.Equipment_Cost__c = 5000;
        update o;
        TC_StateRules.northDakota(o, acc);
        //o.Purchase_Options__c = null;
        o.Purchase_Options__c = '1.00 Out';
        o.Opportunity_Document_Template__c = 'Lease';
        update o;
        TC_StateRules.northDakota(o, acc);
        Test.stopTest();
    }
    
    @IsTest
    static void testAdvanceStageWithoutClearing1() {

        Opportunity o = [SELECT Id, Name, StageName,Account_Business_State_Province__c,Business_Type__c,Equipment_Cost__c,Branch__c,Terms__c,Max_Rate__c,Yield__c,Loan_Amount__c,Purchase_Options__c,AccountId  FROM Opportunity WHERE Name = 'Test Opportunity'];
        Account acc = [SELECT ID,Name,RecordTypeId, Business_State__c,Business_Type__c from Account Where Name = 'TestAccount'];
        o.Account_Business_State_Province__c = 'RI';
        update o;
        Test.startTest();
        TC_StateRules.stateFinder(o.id);
        o.Purchase_Options__c = null;
        update o;
        Approved_Offer__c off = [SELECT ID,Max_Rate__c from Approved_Offer__c Where Opportunity__c =: o.id];   
        off.Max_Rate__c = 2;
        update off;
        o = [SELECT Id, Name, StageName,Account_Business_State_Province__c,Business_Type__c,Equipment_Cost__c,Branch__c,Terms__c,Max_Rate__c,Yield__c,Loan_Amount__c,Purchase_Options__c,AccountId  FROM Opportunity WHERE Name = 'Test Opportunity'];
        o.Equipment_Cost__c = 100;
        update o;
        TC_StateRules.oregon(o);
        TC_StateRules.montana(o);
        TC_StateRules.newYork(o,acc);
        TC_StateRules.nebraska(o, acc);
        TC_StateRules.newJersey(o, acc);
        TC_StateRules.florida(o);
        TC_StateRules.texas(o);
        TC_StateRules.michigan(o);
        o.Terms__c = 25;
        update o;
        TC_StateRules.texas(o);
        
        Test.stopTest();
    }
    
    @IsTest
    static void testFornewjersey() {
        Test.startTest();
        Opportunity o = [SELECT Id, Name, StageName,Account_Business_State_Province__c,Business_Type__c,Equipment_Cost__c,Branch__c,Terms__c,Max_Rate__c,Yield__c,Loan_Amount__c,Purchase_Options__c,AccountId  FROM Opportunity WHERE Name = 'Test California'];
        o.Account_Business_State_Province__c = 'NJ';
        o.Equipment_Cost__c=60000;
        update o;
        Account acc = [SELECT ID,Name,RecordTypeId, Business_State__c,Business_Type__c from Account Where Name = 'TestAccount'];
             acc.Business_Type__c = 'Proprietorship';
        update acc;
        TC_StateRules.newJersey(o,acc);
        TC_StateRules.florida(o);
        o.Equipment_Cost__c=100;
        update o;
        TC_StateRules.nebraska(o,acc);
        TC_StateRules.newYork(o,acc);
        TC_StateRules.florida(o);
        TC_StateRules.oregon(o);
         TC_StateRules.montana(o);
        
        Approved_Offer__c offerNorthDakota = new Approved_Offer__c ();
        offerNorthDakota.Opportunity__c = o.Id;
        offerNorthDakota.Offer_Amount__c = 40000;
        offerNorthDakota.Max_Rate__c = 4.0;
        offerNorthDakota.Term__c = 10;
        offerNorthDakota.Selected_Offer_Amount__c = 40000;
        insert offerNorthDakota;
        
        o.Selected_Approved_Offer__c = offerNorthDakota.Id;
         o.Yield__c = 89;
        update o;
        update o;
        TC_StateRules.oklahoma(o);
        TC_StateRules.colorado(o);
        
        o.Branch__c = 'HKF Horizon Keystone Fin';
        o.Terms__c = 10;
        o.Yield__c = 1;
        o.Purchase_Options__c='Customer Owned'; 
        offerNorthDakota.Max_Rate__c=1;
        update offerNorthDakota;
        update o;
        TC_StateRules.michigan(o);
        TC_StateRules.nevada(o);
          TC_StateRules.texas(o);
        o.Account_Business_State_Province__c = 'OR';
        update o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'MT';
        update o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'NY';
        update o;
        TC_StateRules.stateFinder(o.id);
        
        
    }
    
    @IsTest
    static void stateFinder(){
        Opportunity o = [SELECT Id, Name, StageName,Account_Business_State_Province__c,Business_Type__c,Equipment_Cost__c,Branch__c,Terms__c,Max_Rate__c,Yield__c,Loan_Amount__c,Purchase_Options__c,AccountId  FROM Opportunity WHERE Name = 'Test California'];
        o.Account_Business_State_Province__c = 'NJ';
        o.Equipment_Cost__c=60000;
        update o;
        Test.startTest();
        o.Account_Business_State_Province__c = 'NJ';
        update o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'NE';
        update o;
        TC_StateRules.stateFinder(o.id);
        Test.stopTest();
    }

    @IsTest
    static void testStateValidations(){

        Opportunity o = [SELECT Id, AccountId, Purchase_Options__c, Max_Rate__c, Yield__c, Branch__c, Equipment_Cost__c, Loan_Amount__c FROM Opportunity WHERE Name='Test NorthDakota' LIMIT 1];
        Account a = [SELECT Id, Business_Type__c FROM Account WHERE Id =:o.AccountId LIMIT 1];

        System.debug('sr result: ' + TC_StateRules.rhodeIsland(o));
        System.debug('sr result: ' + TC_StateRules.alabama(o));
        System.debug('sr result: ' + TC_StateRules.mississippi(o));
        System.debug('sr result: ' + TC_StateRules.connecticut(o));
        System.debug('sr result: ' + TC_StateRules.alaska(o));
        System.debug('sr result: ' + TC_StateRules.georgia(o, a));
        System.debug('sr result: ' + TC_StateRules.vermont(o, a));
        o.Equipment_Cost__c = 2999;
        a.Business_Type__c = 'Proprietorship';
        System.debug('sr result: ' + TC_StateRules.georgia(o, a));
        o.Equipment_Cost__c = 90000;
        o.Yield__c = 22;
        System.debug('sr result: ' + TC_StateRules.rhodeIsland(o));
        o.Yield__c = 20;
        o.Branch__c = 'HKF Horizon Keystone Fin';
        o.Terms__c = 24;
        System.debug('sr result: ' + TC_StateRules.rhodeIsland(o));
        o.Branch__c = 'IFP - Indirect Funding Pl';
        o.Equipment_Cost__c = 1000;
        System.debug('sr result: ' + TC_StateRules.rhodeIsland(o));
        

    }
    
     @IsTest
    static void testRhodeIsland() {

        Opportunity o = [SELECT Id, Name, StageName,Account_Business_State_Province__c,Business_Type__c,Equipment_Cost__c,Branch__c,Terms__c,Max_Rate__c,Yield__c,Loan_Amount__c,Purchase_Options__c,AccountId  FROM Opportunity WHERE Name = 'Test California'];
        o.Account_Business_State_Province__c = 'NE';
        update o;
        Account acc = [SELECT ID,Name,RecordTypeId, Business_State__c,Business_Type__c from Account Where Name = 'TestAccount'];
            
        Test.startTest();
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'MI';
        update o;
         TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'FL';
        update o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'TX';
        update o;
        TC_StateRules.stateFinder(o.id);
        Test.stopTest();
    }
    
    @IsTest
    static void stateFinder1() {
        Test.startTest();
        Opportunity o = [SELECT Id, Name, StageName,Loan_Record_Type__c,Account_Business_State_Province__c,Business_Type__c,Equipment_Cost__c,Branch__c,Terms__c,Max_Rate__c,Yield__c,Loan_Amount__c,Purchase_Options__c,AccountId  FROM Opportunity WHERE Name = 'Test California'];
        TC_StateRules.isRunTest = true;
        o.Account_Business_State_Province__c = 'CA';
        TC_StateRules.opportunityFortest = o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'VT';
        TC_StateRules.opportunityFortest = o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'AL';
        TC_StateRules.opportunityFortest = o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'MS';
        TC_StateRules.opportunityFortest = o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'NM';
        TC_StateRules.opportunityFortest = o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'VA';
        TC_StateRules.opportunityFortest = o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'CT';
        TC_StateRules.opportunityFortest = o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'MN';
        TC_StateRules.opportunityFortest = o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'DE';
        TC_StateRules.opportunityFortest = o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'GA';
        TC_StateRules.opportunityFortest = o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'ND';
        TC_StateRules.opportunityFortest = o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'AK';
        TC_StateRules.opportunityFortest = o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'OR';
        TC_StateRules.opportunityFortest = o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'MT';
        TC_StateRules.opportunityFortest = o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'NY';
        TC_StateRules.opportunityFortest = o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'NE';
        TC_StateRules.opportunityFortest = o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'NJ';
        TC_StateRules.opportunityFortest = o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'FL';
        TC_StateRules.opportunityFortest = o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'TX';
        TC_StateRules.opportunityFortest = o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'RI';
        TC_StateRules.opportunityFortest = o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'MI';
        TC_StateRules.opportunityFortest = o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'OK';
        TC_StateRules.opportunityFortest = o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'CO';
        TC_StateRules.opportunityFortest = o;
        TC_StateRules.stateFinder(o.id);
        o.Account_Business_State_Province__c = 'NV';
        TC_StateRules.opportunityFortest = o;
        TC_StateRules.stateFinder(o.id);
        Test.stopTest();
    }

}