@isTest
public class TC_LGTNExistingOppPayOffCTRLTest {
    @isTest public static void setupTestRecords () {
        Account dealer = new Account (Name = 'dealer', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId(), Equipment_Type__c = 'A/V (General)');
        insert dealer;
        Payee__c payee = new Payee__c (Dealer__c = dealer.Id, Address1__c = 'test', City__c = 'test', State__c = 'MN', Zip__c = '11111', Email__c = 'test@test.com', SL_Vendor_ID__c = 'test');
        insert payee;
        
        Account acc = new Account (Name = 'test', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Franchisee Account').getRecordTypeId());
        insert acc;
        Opportunity opp = new Opportunity (Name = 'checklistTest', StageName = 'test', CloseDate = Date.today () + 10, AccountId = acc.Id, Primary_Source__c = 'Direct Mail', Stipulations__c = 'Municipal addendum');
        Test.startTest();
        insert opp;
        
        Payment__c payment = new Payment__c (Payment_Status__c = 'Ready to Send', Opportunity__c = opp.Id, Payee__c = payee.Id);
        insert payment; 
        
        Payoff__c payoff = new Payoff__c (Opportunity__c = opp.Id, Payoff_Amount__c = 100);
        insert payoff;
        
        
        TC_LGTNExistingOppPayOffCTRL.grabPayOffs (payment.Id,opp.Id);
        TC_LGTNExistingOppPayOffCTRL.savePayOffs (JSON.serialize (new List <Payoff__c> {payoff}),payment.Id);
        TC_LGTNExistingOppPayOffCTRL.grabOppInfo (payment.Id);
		Test.stopTest();
        
    }
    
    
}