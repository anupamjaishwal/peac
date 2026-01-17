/**
 * Created by dsheen on 7/01/21.
 * Part of SAL-3040
 */
@IsTest
public with sharing class TC_SendDealerNotificationTest {

    @TestSetup
    public static void testSetup(){
        ORE__c o = new ORE__c(Bypass__c = true);
        insert o; 

        String username = 'standardusertest123@northteq.com';
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        List<User> adminUsers = new List<User>();
        User u = new User(Alias = 'testuser', Email = 'sfdc@northteq.com', EmailEncodingKey='UTF-8',
                LastName = 'portal', FirstName = 'loan', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = p.Id,Personnel_Number__c = 'Test', TimeZoneSidKey = 'America/Los_Angeles',Username = username, Doc_Fee_Exception_Approver__c = true);
        adminUsers.add(u);
        User secondOwner = u.clone(false,false,false);
        secondOwner.LastName = 'owner1';
        secondOwner.FirstName = 'second';
        secondOwner.Username = 'sysadmin.test05291031@peac.com';
        adminUsers.add(secondOwner);
        insert adminUsers;
        
        
       
        System.debug('Account Created');
        

        //insert c;
        System.debug('Contact Created');

        List<Account> accsToInsert = new List<Account>();
         Account a = new Account();
        a.Name = 'test';
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
        a.BillingStreet = 'alksjdf';
        a.BillingCity = 'asdfad';
        a.BillingState = 'Minnesota';
        a.BillingPostalCode = '66111';
        a.Waiting_To_Be_Sent_To_Bridgeware__c = true; // contradictory name for a flag that actually stops the call
        accsToInsert.add(a);
        //insert a;
        
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
        b.Waiting_To_Be_Sent_To_Bridgeware__c = true; // contradictory name for a flag that actually stops the call

        accsToInsert.add(b);
        
        Account dealerAccount = new Account();
        dealerAccount.Name = 'Test5';
        dealerAccount.RecordTypeId = [SELECT Id FROM RecordType WHERE Name='End User Account' LIMIT 1].Id;
        dealerAccount.Account_Dealer_Status__c = 'Watch List';
        dealerAccount.Account_Dealer_Status__c = 'Active';
        dealerAccount.Waiting_To_Be_Sent_To_Bridgeware__c = true; // contradictory name for a flag that actually stops the call
        
        accsToInsert.add(dealerAccount);
        
        Account acc3 = new Account();
        acc3.Name = 'Test3';
        acc3.RecordTypeId = [SELECT Id FROM RecordType WHERE Name='Dealer Account' LIMIT 1].Id;
        acc3.Account_Dealer_Status__c = 'Active';
        acc3.Business_Phone__c = '1011063611';
        acc3.Waiting_To_Be_Sent_To_Bridgeware__c = true; // contradictory name for a flag that actually stops the call
        accsToInsert.add(acc3);
        
          insert accsToInsert;
        System.debug('Broker Created');
        
        
      List<Contact> conList = new List<Contact>();
        Contact c = new Contact();
        c.FirstName = 'Bob';
        c.LastName = 'Johnson';
        c.AccountId = accsToInsert[0].id;//a.Id;
        c.Phone = '5555555555';
    conList.add(c);

        Contact c2 = new Contact();
        c2.FirstName = 'Carmen';
        c2.LastName = 'Contact';
        c2.AccountId = accsToInsert[1].Id;//b.Id;
        c2.Email = 'testing@mailinator.com';
        c2.Phone = '5555555555';
        c2.Receive_All_Notifications__c = true;
        conList.add(c2);
        insert conList;
        //insert c2;
        System.debug('Broker Contact Created');


        
        RecordType rt2 = [SELECT Id,Name FROM RecordType WHERE SobjectType='Opportunity' AND Name LIKE '%CVG%' LIMIT 1];
        Account acc = [Select Id from Account where Recordtype.Name = 'End User Account' Limit 1];
        System.debug('Got Record');
        Opportunity op = new Opportunity();
        op.Name = 'Test Opp';
        op.Portal_User_ID__c = 'PUDA-';
        op.RecordTypeId = rt2.Id;
        op.AccountId = acc.Id;//accsToInsert[1].Id;
        op.Amount = 100;
        op.StageName = 'Quote';
        op.CloseDate = System.today() + 30;
        op.Primary_Source__c = 'Email';
        op.Branch__c = 'IFP - Indirect Funding Pl';
        
        op.Portal_App_Completed__c = TRUE;
        op.Created_via_App_Wizard__c = True;
        op.Application__c = '2112357';
        op.SFP_Tier_2_Status__c = NULL;
        op.Application_Status__c = 'Manually Approved';
        op.Opportunity_Status__c = 'Application In Progress';
         
        System.runAs(u) {
        Test.startTest();
        insert op;
        
       
        Account accD = [Select Id from Account where Recordtype.Name = 'Dealer Account' Limit 1];
        Dealer__c dealer1 = new Dealer__c();
        
        dealer1.Opportunity__c = op.Id;
        dealer1.Dealer__c = accD.Id;//accsToInsert[2].Id;
        dealer1.Primary_Dealer__c = false;
            
        insert dealer1; 

       Account accB = [Select Id from Account where Recordtype.Name = 'Broker Account' Limit 1];
        
       Broker__c broker = new Broker__c();
       broker.Account__c = accB.Id;
       broker.Opportunity__c = op.Id;
        
       insert broker;
       System.debug('Broker Relationship Created');

        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.ContactId = c.Id;
        ocr.OpportunityId = op.Id;
        ocr.Role = 'Dealer Primary Contact';
        insert ocr;
            Test.stopTest();
         
        }
    }   
    

    @IsTest
    public static void sendEmails2(){
       
        
        Opportunity op = [SELECT Id, OwnerId,Application__c,Primary_Dealer__c FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        //Dealer__c dealerAcc = [SELECT Id FROM Dealer__c LIMIT 1];
       // op.Application__c = '510000349';
        //op.Primary_Dealer__c = dealerAcc.id;
       // update op;
        String username = 'standardusertest1234@northteq.com';

        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User u = new User(Alias = 'testuser', Email = 'sfdc@northteq.com', EmailEncodingKey='UTF-8',
                LastName = 'testing', FirstName = 'user', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles',
                Username = username, Doc_Fee_Exception_Approver__c = true);
        insert u;
        System.runAs(u) {
            op.Application__c = '510000349';
            op.ownerId = u.id;
           
            update op;
        
        Broker__c broker = [SELECT Id, Account__c FROM Broker__c WHERE Opportunity__c = :op.Id];
        EmailTemplate emailTemplate = [SELECT Id, Name FROM EmailTemplate WHERE Name = 'Docs Out w/ Contracts' LIMIT 1];
        
        Map <Id, Set<Id>> oppWithPrimaryDealer = new Map <Id, Set<Id>>();
        oppWithPrimaryDealer.put(op.Id, new Set<Id>{broker.Id});
        Id templateId = emailTemplate.Id;
        Map<Id, Id> opportunityOwnerIdsMap = new Map<Id, Id>();
        opportunityOwnerIdsMap.put(op.Id, op.OwnerId);
            
        //Test.startTest();
         TC_SendDealerNotification.sendEmails2(oppWithPrimaryDealer, templateId, opportunityOwnerIdsMap);
        //  
        
        
        op.Application_Status__c = 'Pending';
        update op;
        op.Application_Status__c = 'Manually Approved';
         Test.startTest();
        update op;
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        c.Email = 'Test@test.com';
        c.Receive_All_Notifications__c = true;
        update c;
        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.ContactId = c.Id;
        ocr.OpportunityId = op.Id;
        ocr.Role = 'Dealer Primary Contact';
        insert ocr;
        
        TC_SendDealerNotification.sendEmails2(oppWithPrimaryDealer, templateId, opportunityOwnerIdsMap);
        TC_SendDealerNotification.sendEmails2(oppWithPrimaryDealer, templateId, opportunityOwnerIdsMap,true); 
        Map <Id, Set<Id>> oppWithPrimaryDealer1 = new Map <Id, Set<Id>>();
        oppWithPrimaryDealer1.put(op.Id, new Set<Id>());
        delete broker;
        TC_SendDealerNotification.sendEmails2(oppWithPrimaryDealer1, templateId, opportunityOwnerIdsMap);
        
        TC_SendDealerNotification.sendEmails2(oppWithPrimaryDealer, templateId, opportunityOwnerIdsMap,true); 
        Account acc = [SELECT Id FROM account WHERE RecordType.Name = 'Dealer Account'];
        
        oppWithPrimaryDealer.put(op.Id, new Set<Id>{acc.Id});
        
        Dealer__c dealer1 = [SELECT Id, Dealer__c, Primary_Dealer__c FROM Dealer__c WHERE Opportunity__c = :op.Id];
        system.debug('op.Primary_Dealer__c:'+dealer1);
        insert new Contact(AccountId = dealer1.Dealer__c, Receive_All_Notifications__c = true, FirstName = 'test ccon', Lastname = 'testing', Email='test@test.com', Phone=  '5234567576');
        //dealer1.Opportunity__c = op.Id;
        //dealer1.Dealer__c = acc.Id;//accsToInsert[2].Id;
        dealer1.Primary_Dealer__c = true;
        //update dealer1; 
        TC_SendDealerNotification.sendEmails2(oppWithPrimaryDealer, templateId, opportunityOwnerIdsMap,true);
        Test.stopTest();
        
    }
    }
    
    @IsTest
    public static void submissionNotificationTest(){

        Opportunity op = [SELECT Id, OwnerId FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        Broker__c broker = [SELECT Id, Account__c FROM Broker__c WHERE Opportunity__c = :op.Id];
        EmailTemplate emailTemplate = [SELECT Id, Name FROM EmailTemplate WHERE Name = 'Docs Out w/ Contracts' LIMIT 1];
        
        Map <Id, Set<Id>> oppWithPrimaryDealer = new Map <Id, Set<Id>>();
        oppWithPrimaryDealer.put(op.Id, new Set<Id>{broker.Id});
        Id templateId = emailTemplate.Id;
        Map<Id, Id> opportunityOwnerIdsMap = new Map<Id, Id>();
        opportunityOwnerIdsMap.put(op.Id, op.OwnerId);
            
        Test.startTest();
        TC_SendDealerNotification.sendEmails2(oppWithPrimaryDealer, templateId, opportunityOwnerIdsMap);
        Test.stopTest();
    }
    
    @IsTest
    public static void declinedNotification(){

        Opportunity opp1 = [SELECT Id, OwnerId,Opportunity_Status__c, Name,Portal_User_ID__c, RecordTypeId, AccountId, Amount,StageName,CloseDate ,Primary_Source__c ,Branch__c,Portal_App_Completed__c ,Created_via_App_Wizard__c ,Application__c,
            Opportunity_Owner__c, SFP_Tier_2_Status__c ,Application_Status__c 
            FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        // Broker__c broker = [SELECT Id, Account__c FROM Broker__c WHERE Opportunity__c = :opp1.Id];
        // EmailTemplate emailTemplate = [SELECT Id, Name FROM EmailTemplate WHERE Name = 'Docs Out w/ Contracts' LIMIT 1];
        
        // Map <Id, Set<Id>> oppWithPrimaryDealer = new Map <Id, Set<Id>>();
        // oppWithPrimaryDealer.put(opp1.Id, new Set<Id>{broker.Id});
        // Id templateId = emailTemplate.Id;
        // Map<Id, Id> opportunityOwnerIdsMap = new Map<Id, Id>();
        // opportunityOwnerIdsMap.put(opp1.Id, opp1.OwnerId);
        
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>();  
        oldMap.put(opp1.id, opp1);
        user u1 = [SELECT Id, Profile.Name FROM User WHERE Name != 'loan portal' AND Profile.Name = 'System Administrator' and isActive = true LIMIT 1];
        Map<Id, Opportunity> sfNewMap = new Map<Id, Opportunity>();
        Opportunity opp2 = opp1.clone();
        opp2.Id = opp1.Id;
        opp2.OwnerId = u1.Id;
        opp2.Opportunity_Status__c = 'Suspicious activity - Declined';
        Formula.recalculateFormulas(new List<Opportunity>{opp2});
        sfNewMap.put(opp2.id, opp2);
            
        Test.startTest();
        TC_SendDealerNotification.declinedNotification(oldMap, sfNewMap);
        opp2.Branch__c = 'Broker';
        sfNewMap.put(opp2.id, opp2);
        TC_SendDealerNotification.declinedNotification(oldMap, sfNewMap);
        Test.stopTest();
    }
    
    
    @IsTest
    public static void inFundingNotificationTest(){


        List<Account> accounts = new List<Account>();
        Account acc2 = new Account();
        acc2.Name = 'Test2';
        acc2.RecordTypeId = [SELECT Id FROM RecordType WHERE Name='End User Account' LIMIT 1].Id;
        acc2.Account_Dealer_Status__c = 'Active';
        acc2.Tax_ID__c = '213234345';
        accounts.add(acc2);
        Account acc3 = new Account();
        acc3.Name = 'Test3';
        acc3.RecordTypeId = [SELECT Id FROM RecordType WHERE Name='Dealer Account' LIMIT 1].Id;
        acc3.Account_Dealer_Status__c = 'Active';
        acc3.Points__c = '1';
        acc3.In_Funding__c = true;   
        acc3.Docs_Out__c = true; 
        acc3.Business_Phone__c = '1011064211';
        accounts.add(acc3);
        insert accounts;
        User u = [SELECT Id FROM User WHERE Username = 'standardusertest123@northteq.com'];
        Test.startTest();
            Opportunity opp1 = new Opportunity();
            opp1.Name = 'testopp1';
            opp1.RecordType = [SELECT Id FROM RecordType WHERE Name = 'Express Funding' LIMIT 1];
            opp1.AccountId = accounts[0].Id;
            opp1.StageName = 'Funding';
            opp1.Portal_User_ID__c = 'PUDA-' ;
            opp1.Branch__c = 'IFP - Indirect Funding Pl';
            opp1.Opportunity_Status__c = 'Funding - Incomplete';
            opp1.Points__c = 9;
            opp1.Account_Business_City__c = 'Test';
            opp1.Account_Business_Country__c = 'Test2';
            opp1.Account_Business_State_Province__c = 'PA';
            opp1.Account_Business_Street__c ='Test4';
            opp1.Account_Business_Street2__c = 'Test5';
            opp1.Account_Business_Zip_Postal_Code__c = 'Test6';
            opp1.SFP_Tier_2_Status__c = NULL;
            opp1.Portal_App_Completed__c = TRUE;
            opp1.Application_Status__c = 'More Info';
            opp1.CloseDate = system.today().addDays(10);
            System.runAs(u) {
            insert opp1;
            }
            
        Dealer__c dealer1 = new Dealer__c();
        
        dealer1.Opportunity__c = opp1.Id;
        dealer1.Dealer__c = accounts[1].Id;
        dealer1.Primary_Dealer__c = false;
        dealer1.Funded__c = True;
           
        insert dealer1;
        opp1.Opportunity_Status__c  = 'Funding - In Process';
        
        opp1.Portal_User_ID__c = 'UDA-' ;
        opp1.Branch__c = 'Broker';
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>{opp1.Id => opp1}; 
        Opportunity oldOpp = new Opportunity();
        oldopp.Id = opp1.Id;
        oldopp.StageName = 'Funding';
        oldOpp.Opportunity_Status__c = 'Funding - Payment Acknowledge';
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{oldOpp.Id => oldOpp}; 
        
        TC_SendDealerNotification.inFundingNotification(oldMap,newMap);
        
        test.stopTest();
    }
    
    @IsTest
    public static void inFundingNotificationTest1(){

        List<Account> accounts = new List<Account>();
        Account acc2 = new Account();
        acc2.Name = 'Test2';
        acc2.RecordTypeId = [SELECT Id FROM RecordType WHERE Name='End User Account' LIMIT 1].Id;
        acc2.Account_Dealer_Status__c = 'Active';
        acc2.Tax_ID__c = '213234345';
        accounts.add(acc2);
        Account acc3 = new Account();
        acc3.Name = 'Test3';
        acc3.RecordTypeId = [SELECT Id FROM RecordType WHERE Name='Dealer Account' LIMIT 1].Id;
        acc3.Account_Dealer_Status__c = 'Active';
        acc3.Points__c = '1';
        acc3.In_Funding__c = true;   
        acc3.Docs_Out__c = true; 
        acc3.business_Phone__c = '1011064311';
        accounts.add(acc3);
        insert accounts;
        User u = [SELECT Id FROM User WHERE Username = 'standardusertest123@northteq.com'];
        Test.startTest();
            Opportunity opp1 = new Opportunity();
            opp1.Name = 'testopp1';
            opp1.RecordType = [SELECT Id FROM RecordType WHERE Name = 'Express Funding' LIMIT 1];
            opp1.AccountId = accounts[0].Id;
            opp1.StageName = 'Funding';
            opp1.Portal_User_ID__c = 'PUDA-' ;
            opp1.Branch__c = 'IFP - Indirect Funding Pl';
            opp1.Opportunity_Status__c = 'Funding - Incomplete';
            opp1.Points__c = 9;
            opp1.Account_Business_City__c = 'Test';
            opp1.Account_Business_Country__c = 'Test2';
            opp1.Account_Business_State_Province__c = 'PA';
            opp1.Account_Business_Street__c ='Test4';
            opp1.Account_Business_Street2__c = 'Test5';
            opp1.Account_Business_Zip_Postal_Code__c = 'Test6';
            opp1.SFP_Tier_2_Status__c = NULL;
            opp1.Portal_App_Completed__c = TRUE;
            opp1.Application_Status__c = 'More Info';
            opp1.CloseDate = system.today().addDays(10);
            System.runAs(u) {
            insert opp1;
            }
            
       
        
        Account accB = [Select Id from Account where Recordtype.Name = 'Broker Account' Limit 1];
        accb.In_Funding__c = true;
        update accb;
        Broker__c broker = new Broker__c();
        broker.Account__c = accB.Id;
        broker.Opportunity__c = opp1.Id;
        
        insert broker;
        opp1.Branch__c = 'IFP - Indirect Funding Pl';
        opp1.Opportunity_Status__c  = 'Funding - In Process';
        opp1.Portal_User_ID__c = 'PUDA-' ;
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>{opp1.Id => opp1}; 
        Opportunity oldOpp = new Opportunity();
        oldopp.Id = opp1.Id;
        oldopp.StageName = 'Funding';
        oldOpp.Opportunity_Status__c = 'Funding - Payment Acknowledge';
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{oldOpp.Id => oldOpp}; 
        TC_SendDealerNotification.inFundingNotification(oldMap,newMap);
        test.stopTest();
    }
    
     @IsTest
    public static void docsInNotification(){

        List<Account> accounts = new List<Account>();
        Account acc2 = new Account();
        acc2.Name = 'Test2';
        acc2.RecordTypeId = [SELECT Id FROM RecordType WHERE Name='End User Account' LIMIT 1].Id;
        acc2.Account_Dealer_Status__c = 'Active';
        acc2.Tax_ID__c = '213234345';
        accounts.add(acc2);
        Account acc3 = new Account();
        acc3.Name = 'Test3';
        acc3.RecordTypeId = [SELECT Id FROM RecordType WHERE Name='Dealer Account' LIMIT 1].Id;
        acc3.Account_Dealer_Status__c = 'Active';
        acc3.Points__c = '1';
        acc3.Docs_In__c = true;   
        acc3.Docs_Out__c = true;
        acc3.business_Phone__c = '1011064311';
        accounts.add(acc3);
        insert accounts;
        User u = [SELECT Id FROM User WHERE Username = 'standardusertest123@northteq.com'];
        Test.startTest();
            Opportunity opp1 = new Opportunity();
            opp1.Name = 'testopp1';
            opp1.RecordType = [SELECT Id FROM RecordType WHERE Name = 'Express Funding' LIMIT 1];
            opp1.AccountId = accounts[0].Id;
            opp1.StageName = 'Funding';
            opp1.Portal_User_ID__c = 'PUDA-' ;
            opp1.Branch__c = 'IFP - Indirect Funding Pl';
            opp1.Opportunity_Status__c = 'Funding - Incomplete';
            opp1.Points__c = 9;
            opp1.Account_Business_City__c = 'Test';
            opp1.Account_Business_Country__c = 'Test2';
            opp1.Account_Business_State_Province__c = 'PA';
            opp1.Account_Business_Street__c ='Test4';
            opp1.Account_Business_Street2__c = 'Test5';
            opp1.Account_Business_Zip_Postal_Code__c = 'Test6';
            opp1.SFP_Tier_2_Status__c = NULL;
            opp1.Portal_App_Completed__c = TRUE;
            opp1.Application_Status__c = 'More Info';
            opp1.CloseDate = system.today().addDays(10);
            System.runAs(u) {
            insert opp1;
            }
            
        Dealer__c dealer1 = new Dealer__c();
        
        dealer1.Opportunity__c = opp1.Id;
        dealer1.Dealer__c = accounts[1].Id;
        dealer1.Primary_Dealer__c = false;
        dealer1.Funded__c = True;
           
        insert dealer1;
        opp1.StageName  = 'Docs In';
        
        opp1.Portal_User_ID__c = 'UDA-' ;
        opp1.Branch__c = 'Broker';
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>{opp1.Id => opp1}; 
        Opportunity oldOpp = new Opportunity();
        oldopp.Id = opp1.Id;
        oldopp.StageName = 'Funding';
        oldOpp.Opportunity_Status__c = 'Funding - Payment Acknowledge';
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{oldOpp.Id => oldOpp}; 
        
        TC_SendDealerNotification.docsInNotification(oldMap,newMap);
        
        test.stopTest();
        
        
    }
    
     @IsTest
    public static void docsOutNotification(){

        List<Account> accounts = new List<Account>();
        Account acc2 = new Account();
        acc2.Name = 'Test2';
        acc2.RecordTypeId = [SELECT Id FROM RecordType WHERE Name='End User Account' LIMIT 1].Id;
        acc2.Account_Dealer_Status__c = 'Active';
        acc2.Tax_ID__c = '213234345';
        accounts.add(acc2);
        Account acc3 = new Account();
        acc3.Name = 'Test3';
        acc3.RecordTypeId = [SELECT Id FROM RecordType WHERE Name='Dealer Account' LIMIT 1].Id;
        acc3.Account_Dealer_Status__c = 'Active';
        acc3.Points__c = '1';
        acc3.Docs_In__c = true;   
        acc3.Docs_Out__c = true; 
        acc3.business_Phone__c = '1011064311';
        accounts.add(acc3);
        insert accounts;
        User u = [SELECT Id FROM User WHERE Username = 'standardusertest123@northteq.com'];
        Test.startTest();
            Opportunity opp1 = new Opportunity();
            opp1.Name = 'testopp1';
            opp1.RecordType = [SELECT Id FROM RecordType WHERE Name = 'Express Funding' LIMIT 1];
            opp1.AccountId = accounts[0].Id;
            opp1.StageName = 'Funding';
            opp1.Portal_User_ID__c = 'PUDA-' ;
            opp1.Branch__c = 'IFP - Indirect Funding Pl';
            opp1.Opportunity_Status__c = 'Funding - Incomplete';
            opp1.Points__c = 9;
            opp1.Account_Business_City__c = 'Test';
            opp1.Account_Business_Country__c = 'Test2';
            opp1.Account_Business_State_Province__c = 'PA';
            opp1.Account_Business_Street__c ='Test4';
            opp1.Account_Business_Street2__c = 'Test5';
            opp1.Account_Business_Zip_Postal_Code__c = 'Test6';
            opp1.SFP_Tier_2_Status__c = NULL;
            opp1.Portal_App_Completed__c = TRUE;
            opp1.Application_Status__c = 'More Info';
            opp1.CloseDate = system.today().addDays(10);
            System.runAs(u) {
            insert opp1;
            }
            
        Dealer__c dealer1 = new Dealer__c();
        
        dealer1.Opportunity__c = opp1.Id;
        dealer1.Dealer__c = accounts[1].Id;
        dealer1.Primary_Dealer__c = false;
        dealer1.Funded__c = True;
           
        insert dealer1;
        opp1.StageName  = 'Docs In';
        
        opp1.Portal_User_ID__c = 'UDA-' ;
        opp1.Branch__c = 'Broker';
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>{opp1.Id => opp1}; 
        Opportunity oldOpp = new Opportunity();
        oldopp.Id = opp1.Id;
        oldopp.StageName = 'Funding';
        oldOpp.Opportunity_Status__c = 'Funding - Payment Acknowledge';
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{oldOpp.Id => oldOpp}; 
        
        opp1.StageName  = 'Docs Out';
        newMap = new Map<Id, Opportunity>{opp1.Id => opp1}; 
        TC_SendDealerNotification.docsOutNotification(oldMap,newMap);
        test.stopTest();
        accounts[1].Docs_Out__c = false; 
        accounts[1].Docs_Out_Contracts__c = true;
        update accounts[1];
        TC_SendDealerNotification.docsOutNotification(oldMap,newMap);
        
    }
    
     @IsTest
    public static void inFundingNotificationDealerTest(){

        User u = [SELECT Id FROM User WHERE Username = 'standardusertest123@northteq.com'];
        
        System.runAs(u) {
           
        Account acc2 = new Account();
        acc2.Name = 'Test2';
        acc2.RecordTypeId = [SELECT Id FROM RecordType WHERE Name='End User Account' LIMIT 1].Id;
        acc2.Account_Dealer_Status__c = 'Active';
        acc2.Tax_ID__c = '213234345';
       // dealerList.add(acc2);
        Test.startTest();
            insert acc2;
        
        Opportunity opp1 = new Opportunity();
        opp1.Name = 'testopp1';
        opp1.RecordType = [SELECT Id FROM RecordType WHERE Name = 'Express Funding' LIMIT 1];
        opp1.AccountId = acc2.Id;
        opp1.StageName = 'Funding';
        opp1.Portal_User_ID__c = 'UDA-' ;
        opp1.Branch__c = 'SNAP (National Accounts)';
        opp1.Opportunity_Status__c = 'Funding - Incomplete';
       
       
        opp1.CloseDate = Date.today() + 10;
        
        insert opp1;
            
       Opportunity opp2 = new Opportunity();
            opp2.Id = opp1.Id;
            opp2.AccountId = acc2.Id;
            opp2.Portal_User_ID__c = 'UDA-' ;
            opp2.Branch__c = 'SNAP (National Accounts)';
            opp2.Opportunity_Status__c = 'Funding - In Process';
            
            update opp2;
            
            
            
        Map<Id, Opportunity> filteredNewMap = new Map<Id, Opportunity>(); 
        Opportunity oldopp = opp1;
        filteredNewMap.put(opp1.id, oldopp);
        
        Map<Id, Opportunity> sfNewMap = new Map<Id, Opportunity>();
        sfNewMap.put(opp2.id, opp2);
        TC_SendDealerNotification.inFundingNotification(filteredNewMap,sfNewMap);
            
        Test.stopTest();
    }
    }
    
    @IsTest
    public static void fundedNotificationTest(){
        Id dealerVendorId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer_Vendor').getRecordTypeId();
        Id expressFundingId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Express Funding').getRecordTypeId();
         User u = [SELECT Id FROM User WHERE Username = 'standardusertest123@northteq.com'];
         
        
        System.runAs(u) {
           
        list<Account> RampNotAccount = new list<Account>();
        sl_sctestdata.createAccountAndContracts(3, 1);
        List<Contact> conList = SL_SCTestData.testContacts;
        Account acc2 = SL_SCTestData.testAccounts[0];
        // acc2.Name = 'Test2';
        // acc2.RecordTypeId = [SELECT Id FROM RecordType WHERE Name='End User Account' LIMIT 1].Id;
        // acc2.Tax_ID__c = '213234345';
        // acc2.Funded__c = True;
        // RampNotAccount.add(acc2);
        
            
            
        Account acc3 = new Account();
        acc3.Name = 'Test3';
        acc3.RecordTypeId = dealerVendorId;
        acc3.Account_Dealer_Status__c = 'Active';
        acc3.Points__c = '1';    
        acc3.Business_Phone__c = '1011065511';
        RampNotAccount.add(acc3);
            
        
        
        Test.startTest();   
        insert RampNotAccount;
        
            Opportunity opp1 = [SELECT Id,StageName FROM Opportunity LIMIT 1];
        opp1.Name = 'testopp1';
        opp1.RecordTypeId = expressFundingId;
        opp1.AccountId = acc2.Id;
        opp1.StageName = 'Funding';
        opp1.Portal_User_ID__c = 'UDA-' ;
        opp1.Branch__c = 'IFP - Indirect Funding Pl';
        opp1.Opportunity_Status__c = 'Funding - Incomplete';
        opp1.Points__c = 9;
        opp1.Account_Business_City__c = 'Test';
        opp1.Account_Business_Country__c = 'Test2';
        opp1.Account_Business_State_Province__c = 'PA';
        opp1.Account_Business_Street__c ='Test4';
        opp1.Account_Business_Street2__c = 'Test5';
        opp1.Account_Business_Zip_Postal_Code__c = 'Test6';
        opp1.SFP_Tier_2_Status__c = NULL;
        opp1.CloseDate = Date.today() + 10;
        opp1.Lessor__c = 50;

            // update opp1;

            // opp1 = [SELECT Id,StageName FROM Opportunity LIMIT 1];
            // system.debug('opp1 after first update: ' + opp1);

        insert new List<OpportunityContactRole>{new OpportunityContactRole(Role = 'Dealer Primary Contact', OpportunityId = opp1.Id, ContactId = conList[0].Id ),
        new OpportunityContactRole(Role = 'Billing Contact', OpportunityId = opp1.Id, ContactId = conList[1].Id),
        new OpportunityContactRole(Role = 'Primary Contact', OpportunityId = opp1.Id, ContactId = conList[2].Id)};

            Opportunity opp2 = new Opportunity();
            opp2.Id = opp1.Id;
            opp2.AccountId = acc2.Id;
            opp2.Portal_User_ID__c = 'UDA-' ;
            opp2.Branch__c = 'IFP - Indirect Funding Pl';
            opp2.StageName = 'Booking';
            opp2.Account_Business_City__c = 'Test';
            opp2.Account_Business_Country__c = 'Test2';
            opp2.Account_Business_State_Province__c = 'PA';
            opp2.Account_Business_Street__c ='Test4';
            opp2.Account_Business_Street2__c = 'Test5';
            opp2.Account_Business_Zip_Postal_Code__c = 'Test6';
            opp2.Business_Phone__c = '9876543210';
            opp2.Billing_Cycle__c = 'January';
            opp2.Booking_Sheet_Generated__c = true;
            opp2.Contract_Type__c = 'TL';
            opp2.Equipment_Cost__c = 200;
            opp2.of_Payments__c = 10;
            opp2.Payment_Amount__c = 100;
            opp2.First_Payment_Amount__c = 2;
            opp2.Ending_Pymts_in_Advance__c = 3;
            opp2.X_Rate_Factor__c = 0.1;
            opp2.Purchase_Options__c = 'FMV';
            opp2.Tax_ID__c = '123456789';
            opp2.Terms__c = 12;
            
                //update opp2;
            
        Dealer__c dealer1 = new Dealer__c();
        
        dealer1.Opportunity__c = opp2.Id;
        dealer1.Dealer__c = RampNotAccount[0].Id;
        dealer1.Primary_Dealer__c = false;
        dealer1.Funded__c = True;
           
        insert dealer1; 
           
        Broker__c broker = new Broker__c();
        broker.Account__c = [Select id from account where name = 'broker' LIMIT 1].Id;
        broker.Opportunity__c = opp2.Id;
        
            
        insert broker;   
        
            
        Map<Id, Opportunity> filteredNewMap = new Map<Id, Opportunity>(); 
        Opportunity oldopp = opp1;
        filteredNewMap.put(opp1.id, oldopp);
        
        Map<Id, Opportunity> sfNewMap = new Map<Id, Opportunity>();
        sfNewMap.put(opp2.id, opp2);
        TC_SendDealerNotification.fundedNotification(filteredNewMap,sfNewMap);
        opp2.Branch__c = 'Broker';
        sfNewMap.put(opp2.id, opp2);
        TC_SendDealerNotification.fundedNotification(filteredNewMap,sfNewMap);
            Test.stopTest();
    }
    }    
        
    @IsTest
    public static void approvalNotificationTest2(){
        List<Opportunity> opps = [SELECT Id, Name, Application_Status__c, Primary_Dealer__c, Branch__c, Loan_Record_Type__c, No_of_Broker__c, 
            Portal_App_Completed__c, Opportunity_Owner__c, SFP_Tier_2_Status__c, Portal_User_ID__c, OwnerId FROM Opportunity];
        Opportunity opp1 = opps[0].clone(true, false, false, false);
        Map<Id, Opportunity> testOldMap = new Map<Id, Opportunity>();
        Map<Id, Opportunity> sfNewMap = new Map<Id, Opportunity>();
        Opportunity opp2 = opp1.clone(true, false, false, false);
        opp1.Application_Status__c = 'Pending';
        User secondOwner = [SELECT Id FROM User WHERE Username = 'sysadmin.test05291031@peac.com'];
        opp2.OwnerId = secondOwner.Id;
        update opp2;
        opp2 = [SELECT Id, Name, Application_Status__c, Primary_Dealer__c, Branch__c, Loan_Record_Type__c, No_of_Broker__c, 
            Portal_App_Completed__c, Opportunity_Owner__c, SFP_Tier_2_Status__c, Portal_User_ID__c, OwnerId 
            FROM Opportunity WHERE Id = :opp2.Id];
        opp2.SFP_Tier_2_Status__c = null; // 'Approved';
        opp2.Portal_App_Completed__c = true;
        Test.startTest();
        testOldMap.put(opp1.id, opp1);
        sfNewMap.put(opp2.id, opp2);
        TC_SendDealerNotification.approvalNotification(testOldMap, sfNewMap);
        opp2.Branch__c = null;//'IFP - Indirect Funding Pl';
        sfNewMap.put(opp2.id, opp2);
        TC_SendDealerNotification.approvalNotification(testOldMap, sfNewMap);
        TC_SendDealerNotification.scheduleApprovalNotification(testOldMap, sfNewMap);
        Test.stopTest();
    }
    /*@IsTest
    public static void approvalNotificationTest1(){
        Id dealerVendorId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer_Vendor').getRecordTypeId();
        String username = 'standardusertest1235@northteq.com';
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        
        User u = new User(Alias = 'testuser', Email = 'sfdc@northteq.com', EmailEncodingKey='UTF-8',
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
        acc2.Business_Phone__c = '0516031311';
        RampNotAccount.add(acc2);
        
            
            
        Account acc3 = new Account();
        acc3.Name = 'Test3';
        acc3.RecordTypeId = dealerVendorId;
        acc3.Account_Dealer_Status__c = 'Active';
        acc3.Points__c = '1';
        acc3.Business_Phone__c = '0516031322';
        RampNotAccount.add(acc3);
            
            
        Test.startTest();
        insert RampNotAccount;
        
            Opportunity opp1 = new Opportunity();
            opp1.Name = 'testopp1';
            opp1.RecordType = [SELECT Id FROM RecordType WHERE Name = 'Express Funding' LIMIT 1];
            opp1.AccountId = acc2.Id;
            opp1.StageName = 'Funding';
            opp1.Portal_User_ID__c = 'PUDA-' ;
            opp1.Branch__c = 'IFP - Indirect Funding Pl';
            opp1.Opportunity_Status__c = 'Funding - Incomplete';
            opp1.Points__c = 9;
            opp1.Account_Business_City__c = 'Test';
            opp1.Account_Business_Country__c = 'Test2';
            opp1.Account_Business_State_Province__c = 'PA';
            opp1.Account_Business_Street__c ='Test4';
            opp1.Account_Business_Street2__c = 'Test5';
            opp1.Account_Business_Zip_Postal_Code__c = 'Test6';
            opp1.SFP_Tier_2_Status__c = NULL;
            opp1.Portal_App_Completed__c = TRUE;
            opp1.Application_Status__c = 'More Info';
            
            
            opp1.CloseDate = Date.today() + 10;
            System.runAs(u) {   
            insert opp1;
            }
        Dealer__c dealer1 = new Dealer__c();
        
        dealer1.Opportunity__c = opp1.Id;
        dealer1.Dealer__c = RampNotAccount[1].Id;
        dealer1.Primary_Dealer__c = false;
        dealer1.Funded__c = True;
           
        
        insert dealer1; 
           
        Broker__c broker = new Broker__c();
        broker.Account__c = [Select id from account where name = 'broker' LIMIT 1].Id;
        broker.Opportunity__c = opp1.Id;
        
            
        insert broker;
        opp1 = [SELECT Id, Name, Application_Status__c, Primary_Dealer__c, Branch__c, Loan_Record_Type__c, No_of_Broker__c, Portal_App_Completed__c, Opportunity_Owner__c, SFP_Tier_2_Status__c, Portal_User_ID__c FROM Opportunity WHERE Id = :opp1.Id];
        
        Map<Id, Opportunity> filteredNewMap = new Map<Id, Opportunity>(); 
        Opportunity oldopp = opp1;
        filteredNewMap.put(oldopp.id, oldopp);
        
        Map<Id, Opportunity> sfNewMap = new Map<Id, Opportunity>();
        user u1 = [SELECT Id, Profile.Name FROM User WHERE Name != 'loan portal' AND Profile.Name = 'System Administrator' and isActive = true LIMIT 1];
        u1.Personnel_Number__c = 'test';
        update u1;
        dealer1.Primary_Dealer__c = true;
        update dealer1;
       
        Opportunity opp2 = [SELECT Id, Name, Application_Status__c, Primary_Dealer__c, Branch__c, Loan_Record_Type__c, No_of_Broker__c, Portal_App_Completed__c, Opportunity_Owner__c, SFP_Tier_2_Status__c, Portal_User_ID__c FROM Opportunity WHERE Id = :opp1.Id];
        opp2.OwnerId = u1.Id;
        opp2.Application_Status__c = 'Manually Approved';
        opp2.Branch__c = null;
        opp2.Primary_Dealer__c = dealer1.Id;
        opp2.Portal_App_Completed__c = true;
        Formula.recalculateFormulas(new List<Opportunity>{opp2});
        sfNewMap.put(opp2.id, opp2);
        TC_SendDealerNotification.approvalNotification(filteredNewMap,sfNewMap);
        opp2.Branch__c = 'IFP - Indirect Funding Pl';
        sfNewMap.put(opp2.id, opp2);
        TC_SendDealerNotification.approvalNotification(filteredNewMap,sfNewMap);
        Test.stopTest();
    }*/
    
    @IsTest
    public static void moreInfoNotification(){
        Opportunity op = [SELECT Id, OwnerId,Application__c,Primary_Dealer__c, Portal_User_ID__c, Opportunity_Owner__c, Branch__c FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        Opportunity op1 = [SELECT Id, OwnerId,Application__c,Primary_Dealer__c, Portal_User_ID__c, Opportunity_Owner__c, Branch__c FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        user u = [SELECT Id, Profile.Name FROM User WHERE Name != 'loan portal' AND Profile.Name = 'System Administrator' and isActive = true LIMIT 1];
        op1.OwnerId = u.Id;
        update op1;
        op1 = [SELECT Id, OwnerId,Application__c,Primary_Dealer__c, Portal_User_ID__c, Opportunity_Owner__c, Branch__c FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        op1.Portal_User_ID__c = 'PUDA-';
        op.Opportunity_Status__c = 'Credit - More Info Request';
        op1.Opportunity_Status__c = 'Credit - More Info Requested';
        
        Dealer__c d = [SELECT Id, Opportunity__c, Dealer__r.Partner_UDA_Notification__c, Dealer__c, Dealer__r.More_Info__c
                        FROM Dealer__c
                        WHERE Opportunity__c = :op1.Id];
                        update new account(Id= d.Dealer__c, More_Info__c = true);
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{op.Id => op};
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>{op1.Id => op1};
        Test.startTest();  
        TC_SendDealerNotification.moreInfoNotification(oldMap, newMap);
        op1.Branch__c = 'broker';
        TC_SendDealerNotification.moreInfoNotification(oldMap, newMap);
        Test.stopTest();
    }
  
}