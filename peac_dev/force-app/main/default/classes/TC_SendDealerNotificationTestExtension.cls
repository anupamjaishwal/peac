@IsTest
public class TC_SendDealerNotificationTestExtension {
    @TestSetup
        static void setup() {
        ORE__c setting = new ORE__c();
        setting.StageBypass__c = true;
        insert setting;
        }        
            
    @IsTest
    public static void docsInNotificationTest(){

         String username = 'standardusertest1235@peacsolutions.com';
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        
        User u = new User(Alias = 'testuser', Email = 'sfdc@peacsolutions.com', EmailEncodingKey='UTF-8',
                LastName = 'portal', FirstName = 'loan', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = p.Id,Personnel_Number__c = 'Test', TimeZoneSidKey = 'America/Los_Angeles',Username = username, Doc_Fee_Exception_Approver__c = true);
        insert u;
        
        // User u = [SELECT Id FROM User WHERE Username = 'standardusertest123@northteq.com'];
        
        
     
           
        list<Account> RampNotAccount = new list<Account>();
        
        Account acc2 = new Account();
        acc2.Name = 'Test2';
        acc2.RecordTypeId = [SELECT Id FROM RecordType WHERE Name='End User Account' LIMIT 1].Id;
        acc2.Tax_ID__c = '213234345';
        acc2.Funded__c = True;
        RampNotAccount.add(acc2);
        
        
        
            
        Account acc3 = new Account();
        acc3.Name = 'Test3';
        acc3.RecordTypeId = [SELECT Id FROM RecordType WHERE Name='Dealer Account' LIMIT 1].Id;
        acc3.Account_Dealer_Status__c = 'Active';
        acc3.Points__c = '1';    
        RampNotAccount.add(acc3);
            
        Account b = new Account();
        b.Name = 'broker';
        b.Business_Phone__c = '5558888888';
        b.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker Account').getRecordTypeId();
        b.Submitted__c = true;
        b.Approved__c = true;
        b.Declined__c = true;
        b.More_Info__c = true;
        b.Docs_In__c = true;
        b.Docs_Out__c = true;
        b.Docs_Out_Contracts__c = false;
        b.Funded__c = true;

        RampNotAccount.add(b); 
        
        Test.startTest();   
        insert RampNotAccount;
        
        
        
            Opportunity opp1 = new Opportunity();
            opp1.Name = 'testopp1';
            opp1.RecordType = [SELECT Id FROM RecordType WHERE Name = 'Loan Funding' LIMIT 1];
            opp1.AccountId = RampNotAccount[0].Id;
            opp1.StageName = 'Funding (Loan)';
            opp1.Portal_User_ID__c = 'PUDA-' ;
            opp1.Branch__c = 'IFP - Indirect Funding Pl';
          //  opp1.Opportunity_Status__c = 'Funding - Incomplete';
            opp1.Points__c = 9;
            opp1.Account_Business_City__c = 'Test';
            opp1.Account_Business_Country__c = 'Test2';
            opp1.Account_Business_State_Province__c = 'PA';
            opp1.Account_Business_Street__c ='Test4';
            opp1.Account_Business_Street2__c = 'Test5';
            opp1.Account_Business_Zip_Postal_Code__c = 'Test6';
            opp1.Credit_Stips_Completed_Date__c = Date.today();
          //  opp1.SFP_Tier_2_Status__c = NULL;
           // opp1.Portal_App_Completed__c = TRUE;
          //  opp1.Application_Status__c = 'More Info';
            opp1.CloseDate = Date.today() + 10;
        
            
        System.runAs(u) {   
            try {
                insert opp1;
                //opportunity TestOpp6 =[select id, name, Loan_Record_Type__c from opportunity where ID=: opp1.Id];
              //system.debug('=====recordType'+ TestOpp6.Loan_Record_Type__c);  
            } catch (Exception e) {
            }
            
            }
            Opportunity opp2 = new Opportunity();
            opp2.Id = opp1.Id;
            opp2.StageName = 'Docs In';
            //opp2.RecordType = [SELECT Id FROM RecordType WHERE Name = 'Loan Funding' LIMIT 1];
            opp2.AccountId = RampNotAccount[0].Id;
            opp2.Branch__c = 'IFP - Indirect Funding Pl';
            opp2.Account_Business_City__c = 'Test';
            opp2.Account_Business_Country__c = 'Test2';
            opp2.Account_Business_State_Province__c = 'PA';
            opp2.Account_Business_Street__c ='Test4';
            opp2.Account_Business_Street2__c = 'Test5';
            opp2.Account_Business_Zip_Postal_Code__c = 'Test6';
            opp2.Portal_User_ID__c = 'PUDA-' ;
            opp2.Credit_Stips_Completed_Date__c = Date.today();
          //  opp2.Purchase_Options__c =  '1.00 Out' ;
        //    opp2.Contract_Type__c = 'CS';   
             try {
        update opp2;
                 // opportunity TestOpp47 =[select id, name, Loan_Record_Type__c from opportunity where ID=: opp2.Id];
                // system.debug('=====recordType'+ TestOpp47.Loan_Record_Type__c);
            
        } catch (Exception e) {
        }
            
           
           Test.stopTest(); 
                
        Dealer__c dealer1 = new Dealer__c();
        
        dealer1.Opportunity__c = opp1.Id;
        dealer1.Dealer__c = RampNotAccount[1].Id;
        dealer1.Primary_Dealer__c = false;
        dealer1.Funded__c = True;
        try{
        insert dealer1;
        }catch(exception e){} 
           
        Broker__c broker = new Broker__c();
        broker.Account__c = [Select id from account where name = 'broker' LIMIT 1].Id;
        broker.Opportunity__c = opp2.Id;
        
        try{
        insert broker;  
        }catch(exception e){}  
        
            
        Map<Id, Opportunity> filteredNewMap = new Map<Id, Opportunity>(); 
        Opportunity oldopp = opp1;
        filteredNewMap.put(opp1.id, oldopp);
        
        Map<Id, Opportunity> sfNewMap = new Map<Id, Opportunity>();
        sfNewMap.put(opp2.id, opp2);
        TC_SendDealerNotification.docsInNotification(filteredNewMap,sfNewMap);
       
    }
    
}