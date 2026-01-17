@isTest
public class TestUpdateOpportunityWithRapportFields {
    
    
    @isTest
    static void updOpportunity()
    {
        String accntid = '';
        RecordType accrectypeid = [select id from RecordType where DeveloperName = 'End_User'];
        if(accrectypeid <> null)
        {
            Account acc = new Account();
            acc.RecordTypeId = accrectypeid.id;
            acc.Name = 'Test Account';
            
            if(acc <> null)
            {
            insert acc;
            }
            accntid = acc.id;
        }

        RecordType optyrectypeid = [select id, Name from RecordType where Name LIKE '%Express%' LIMIT 1];
        if(optyrectypeid <> null)
        {
            Opportunity opty = new Opportunity();
            opty.RecordTypeId = optyrectypeid.id;
            opty.Name = 'Testing Trigger Opportunity';
            opty.AccountId = accntid;
            opty.StageName = 'Quote';
            opty.CloseDate = system.today() + 10;
            
            if(opty <> null)
            {
                insert opty;
            }
            
            Opportunity opp = new Opportunity();
            opp.Sales_Comments__c = 'Testing Trigger Putting Comments';
            opp.Purchase_Options__c = 'Customer Owned';
            opp.Id = opty.Id;
            
            if (opp <> null)
            {
                Test.startTest();
                update opp;
                Test.stopTest();
            }
        }
    }
    
}