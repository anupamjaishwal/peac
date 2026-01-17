@isTest
public class TC_NewDealerRampupNotificationTest {

    @TestSetup
    public static void testSetup(){
            ORE__c o = new ORE__c(Bypass__c = true);
            insert o; 
                        
             String username = 'standardusertest123@northteq.com';
        
            Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
            User u = new User(Alias = 'testuser', Email = 'sfdc@peacsolutions.com', EmailEncodingKey='UTF-8',
                    LastName = 'portal', FirstName = 'loan', LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US', ProfileId = p.Id,Personnel_Number__c = 'Test', TimeZoneSidKey = 'America/Los_Angeles',Username = username, Doc_Fee_Exception_Approver__c = true);
            insert u;
            
            List<Account> accountList = new List<Account>();
            
            Account dealerAccount = new Account (
                Name = 'TC_CreditDecisionTriggerTest Dealer Account1'
                , RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId()
                , Business_Address__c = 'Test Address', Business_City__c = 'Test City', Business_State__c = 'MN', Business_Zip__c = '11111'
                , Account_EU_FS_SIC_Description__c = '8661'
                , Preferred_Dealer_Level__c = '3'
                , Dealer_Number__c = '855331.7239'
                ,Equipment_Type__c = 'A/V (General)'
                ,Account_Months_In_Business__c = 12
                , Account_Dealer_Status__c = 'Watch List'
            );
            accountList.add(dealerAccount);
            
            Account a = new Account(Name='Test');
            accountList.add(a);
            Test.startTest();  
            system.runAs(u){
                
                insert accountList;
                
                Contact dc = new Contact (
                    AccountId = accountList[0].Id, 
                    FirstName = 'dealer test1', 
                    LastName = 'dealer contact1', 
                    Phone='1234555555',
                    Email = 'testdealer1234@test.com'
                );
                insert dc;
                
                AccountContactRelation r = [SELECT Id FROM AccountContactRelation WHERE ContactId = :dc.Id LIMIT 1];
                r.Roles = 'Primary Contact';
                update r;
                
            }
    }
    @IsTest
    public static void AutoCreateLoanPaymentRecordsTest1(){
          
       Account dealerAccount = [SELECT Id, Name, Account_Dealer_Status__c, Dealer_Number__c FROM Account WHERE Name = 'TC_CreditDecisionTriggerTest Dealer Account1'];
            Account acc = [SELECT Id FROM Account WHERE Name = 'Test'];
            
            user u = [SELECT Id FROM USer WHERE UserName = 'standardusertest123@northteq.com'];
            Opportunity opp = new Opportunity();
            system.runAs(u){
                opp = new Opportunity(
                    Name = 'TC_CreditDecisionTriggerTest9'
                    , StageName = 'Funding'
                    , CloseDate = Date.today()
                    , Last_Date_Scorex_Retrieved__c = Date.today()
                    , RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Express Funding').getRecordTypeId()
                    , AccountId = acc.Id
                    , Application__c = 'TestApplicationNumber9'
                    , Loan_Ready_To_Doc__c = 'Yes'
                    , Lessor__c = 201
                    , Origination_Fee__c = 0
                    , Months_Verified__c = 12
                    , Account_Business_City__c = 'TestD'
                    , Account_Business_Country__c = 'TestD2'
                    , Account_Business_State_Province__c = 'CA'
                    , Account_Business_Street__c ='TestD4'
                    , Account_Business_Street2__c = 'TestD5'
                    , Account_Business_Zip_Postal_Code__c = 'TestD6'
                    , Portal_User_ID__c = 'UDA-'
                    , Branch__c = 'IFP - Indirect Funding Pl'
                    , Opportunity_Status__c = 'Funding - Incomplete'
                    ,Loan_Points_Amount__c = 4
                    ,Tax_ID__c = '123456789'
                    , Credit_Stips_Completed_Date__c = Date.today()
                );
                insert opp;
            }
            Dealer__c dealer = new Dealer__c(
                Opportunity__c = opp.Id
                , Dealer__c = dealerAccount.Id
            );
            
            insert dealer;
            Account oldacc = new Account();
            oldacc.Id = dealerAccount.Id;
            oldacc.Account_Dealer_Status__c = 'Watch List';
            Map<Id, Account> oldMap = new Map<Id, Account>{oldacc.Id => oldacc};
            
            
            Account newacc = new Account();
            newAcc.Id = dealerAccount.Id;
            NewAcc.Account_Dealer_Status__c = 'On Hold';
            Map<Id, Account> newMap = new Map<Id, Account>{NewAcc.Id => NewAcc};
           
            test.startTest();
            TC_NewDealerRampupNotification.newDealerRampupNotification(oldMap,newMap);
            test.stopTest();
              
        }
    
    
}