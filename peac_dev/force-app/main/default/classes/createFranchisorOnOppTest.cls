@isTest

Public class createFranchisorOnOppTest
{
   
    
    @isTest
    static void createFranchisorTest()
    {
    
        Account accfranchisor = new Account();
         Account acc = new Account();
          Opportunity opty = new Opportunity();
        RecordType accfranchisorrectype = [select id from RecordType where DeveloperName = 'Franchisor'];
        if(accfranchisorrectype <> null)
        {
            
            accfranchisor.RecordTypeId = accfranchisorrectype.id;
            accfranchisor.Name = 'Test franchisor acc';
            
            if(accfranchisor <> null)
            {
            insert accfranchisor ;
            }
           
        }
        
        RecordType accrectypeid = [select id from RecordType where DeveloperName = 'Franchisee'];
        if(accrectypeid <> null)
        {
           
            acc.RecordTypeId = accrectypeid.id;
            acc.Name = 'Test franchisee acc';
            acc.Franchisor_Account__c = accfranchisor.id;
            
            if(acc <> null)
            {
            insert acc;
            }
           
        }
        
       
        
        

        //RecordType optyrectypeid = [select id from RecordType where name = 'Franchise Opportunity'];
        //if(optyrectypeid <> null)
        //{
           
            //opty.RecordTypeId = optyrectypeid.id;
            opty.Name = 'Testing Trigger Opportunity';
            opty.AccountId = acc.id;
            opty.StageName = 'Quote';
            opty.CloseDate = system.today() + 10;
            opty.Tax_ID__c='111221232';
            opty.Business_Phone__c='9490771803';
            if(opty <> null)
            {
                Test.startTest();
                insert opty;
                insert new Franchisor__c (Opportunity__c = opty.Id, Franchisor__c = accfranchisor.Id);
                Test.stopTest();
            }
            
            
            
        //}
    }
    
}