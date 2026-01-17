@isTest
public class xct_SolomonPayeeTest {
    @isTest static void PayeeTriggersTest() {
        System.debug ('<<<<< PayeeTriggersTest');
        // Test data setup
        // Create an account with an opportunity, and then try to delete it
        Payee__c payee = new Payee__c(Payee_Name__c='Test Payee', State__c='OH',Address1__c='100 Test St.', City__c='Test City',Email__c='Test@Test.com',Zip__c = '45840');
        payee.Remittance_State__c = 'OH';
        payee.Remittance_City__c = 'Test City';
        payee.Remittance_Address1__c = '100 Test St.';
        payee.Remittance_Name__c = 'Test Payee';
        payee.Remittance_Zip__c = '45840';
        payee.Tax_ID_type__c = 'SSN';
        payee.X1099__c = false;        
        payee.Tax_ID_Nbr__c = '666666666';

        
        Account acct = new Account(Name='Test Account',Business_Phone__c='1234567890' );
        insert acct;
        

        Opportunity opp = new Opportunity(Name='Test Opportunity',
                                       StageName='Quote Pending',
                                       ForecastCategoryName='Pipeline',
                                       CloseDate=System.today().addMonths(1),
                                       AccountId=acct.Id); 
        insert opp;
        
        Contact ct = new Contact(FirstName='test2', LastName='TEST',AccountId=acct.Id);
        insert ct;


        
        payee.Contact__c = ct.Id;
        payee.Dealer__c = acct.Id;
        
        // Perform test
        Test.startTest();
            System.debug ('<<<<< right before insert');
            Database.SaveResult iresult = Database.insert(payee, false);
            System.debug ('<<<<< iresult: ' + iresult);
            payee.Remittance_Address1__c = '101 Test St.';
            payee.Tax_ID_type__c = 'EIN';

            payee.Tax_ID_Nbr__c = '6666666666';
            Database.SaveResult uresult = Database.update(payee, false);
            
            payee.SL_Vendor_ID__c = '123456';
            update payee;
            payee.update__c = true; 
            update payee;
            
            try {
                delete payee;
            }
            catch(Exception e){}
            // Payee__c[] payees = [SELECT Id from Payee__c WHERE Payee_Name__c = 'Test Payee'];

            // Database.DeleteResult[] dresult = Database.delete(payees, false);
         System.assert(iresult.isSuccess());
         System.assert(uresult.isSuccess());
        // Verify 
        // In this case the deletion should have been stopped by the trigger,
        // so verify that we got back an error.
        //for(Database.DeleteResult dr : dresult ) {
            //System.assert(!dr.isSuccess());
        //}
        Test.stopTest();
       
    }
    
}