@isTest

Public class TestFirstAssetOnOpportunity
{

    @testSetup public static void setupTest () {
    
        Bridgeware_Service_Setting__c setting = new Bridgeware_Service_Setting__c ();
        setting.Enable_Debug_Log__c = true;
        setting.Mock_Callout__c = true;
        setting.Mock_Endpoint__c = 'https://private-b2bb6-bridgewaretamarack.apiary-mock.com/';
        setting.SetupOwnerId = UserInfo.getOrganizationId ();
        setting.Config_Name__c = 'TEST';
        insert setting;
        
        Test.setMock(HttpCalloutMock.class, new TC_BridgewareBookContractCalloutMockImpl ());
        
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

        //RecordType optyrectypeid = [select id from RecordType where DeveloperName = 'Franchise_Quote'];
        //if(optyrectypeid <> null)
        //{
            Opportunity opty = new Opportunity();
            //opty.RecordTypeId = optyrectypeid.id;
            opty.Name = 'Testing Trigger Opportunity Franchise';
            opty.AccountId = accntid;
            opty.StageName = 'Quote';
            opty.CloseDate = system.today() + 10;
            opty.Account_Business_City__c = 'city';
            opty.Account_Business_Street__c= 'street';
            opty.Account_Business_State_Province__c= 'IL';
            opty.Account_Business_Zip_Postal_Code__c= '678909';
           
            
            if(opty <> null)
            {
                insert opty;
            }
    
           //}
    }
    
    @isTest
    static void updOppMock() {
        
        	Opportunity opty = [SELECT id from opportunity][0];
       
            Asset__c newAsset = new Asset__c ();
            newAsset.Quantity__c = 5;
            newAsset.Opportunity__c = opty.id;
            newAsset.Equipment_Code__c = 'ATM';
            newAsset.Description__c = 'Testing';
            newAsset.Cost__c = 1234;
            newAsset.Equipment_Street__c = 'CMC Street';
            newAsset.Equipment_City__c = 'Chicago';
            newAsset.Equipment_State__c = 'IL';
            newAsset.Equipment_Zip__c = '60607';
            
            if (newAsset <> null)
            {
                Test.starttest();
	            Test.setMock(HttpCalloutMock.class, new TC_BridgewareBookContractCalloutMockImpl ());
                insert newAsset;        
                Test.stoptest();
            }
    }
    
    /*
    @isTest
    static void testAssertTrigger()
    {
            Opportunity opty = [SELECT id from opportunity][0];
            
            Asset__c newAsset = new Asset__c ();
            newAsset.Quantity__c = 5;
            newAsset.Opportunity__c = opty.id;
            newAsset.Equipment_Code__c = 'ATM';
            newAsset.Description__c = 'Testing';
            newAsset.Cost__c = 1234;
            newAsset.Equipment_Street__c = 'CMC Street';
            newAsset.Equipment_City__c = 'Chicago';
            newAsset.Equipment_State__c = 'IL';
            newAsset.Equipment_Zip__c = '60607';            
            
            if (newAsset <> null)
            {
                insert newAsset;
            }
            
            
            
            newAsset.Equipment_City__c = 'city';
            newAsset.Equipment_Street__c = 'street';
            newAsset.Equipment_State__c = 'IL';
            newAsset.Equipment_Zip__c ='387450';
            update newAsset;
            
            // split
            Test.setMock(HttpCalloutMock.class, new TC_BridgewareBookContractCalloutMockImpl ());
            Test.starttest();
            
            
            Asset__c newAsset1 = new Asset__c ();
            newAsset1.Quantity__c = 5;
            newAsset1.Opportunity__c = opty.id;
            newAsset1.Equipment_Code__c = 'ATM';
            newAsset1.Description__c = 'Testing';
            newAsset1.Cost__c = 1234;
            newAsset1.Equipment_Street__c = 'CMC Street';
            newAsset1.Equipment_City__c = 'Chicago';
            newAsset1.Equipment_State__c = 'IL';
            newAsset1.Equipment_Zip__c = '60607';            
            
            if (newAsset1 <> null)
            {
                insert newAsset1;
            }
            
          newAsset1.End_User_Billing_Address__c = true;
          delete newAsset1;
       
           Test.stoptest(); 
            
        }*/
    
    
}