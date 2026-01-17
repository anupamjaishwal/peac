@isTest
public class xct_SolomonPaymentTest {
    
    @isTest static void PaymentTest() {
        Marlin_Configuration__c config = Marlin_Configuration__c.getOrgDefaults ();
        config.Enable_Auto_Move_to_Booking__c = true;
        insert config;

        Gl_Code__c gl = new Gl_Code__c(GL_Name__c='Broker Fees Booking Clearing',Payment_Field_name__c='Points',Payment_Field_Source__c='Plus_Points__c',Payment_Type__c='Both',Type__c='+',SL_Account__c='133011');
        insert gl;
        
        Gl_Code__c gl2 = new Gl_Code__c(GL_Name__c='Accrued Broker Fee Program',Payment_Field_name__c='Points Pool',Payment_Field_Source__c='Less_Points_Pool__c',Payment_Type__c='Both',Type__c='-',SL_Account__c='232862');
        insert gl2;
            
        Account acc = new Account (Name = 'test', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Franchisee Account').getRecordTypeId(), Business_Address__c = 'test', Business_Phone__c = '1234567890');
        insert acc;
        
        Contact primary = new Contact (FirstName = 'test', LastName = 'test2', Email = 'test@test.com', AccountId = acc.Id);
        insert primary;
        
        Contact billing = new Contact (FirstName = 'test', LastName = 'test2', AccountId = acc.Id);
        insert billing;
        
        Account dealer = new Account (Name = 'dealer', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId() , Equipment_Type__c = 'A/V (General)');
        insert dealer;
        
        Id p = UserInfo.getProfileId();
        
        String uniqueUserName = 'dataadmin' + DateTime.now().getTime() + '@testorg.com';
        Test.startTest();
        User u = new User(Alias = 'dadmin', Email='dataadmin@testorg.com',EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',LocaleSidKey='en_US', ProfileId = p,TimeZoneSidKey='America/Los_Angeles',UserName=uniqueUserName);
        
        System.runAs(u) {
            
            Id rt2 = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Express Application').getRecordTypeId();
            Opportunity opp = new Opportunity (Name = 'checklistTest', StageName = 'Decision', CloseDate = Date.today () + 10, AccountId = acc.Id, Primary_Source__c = 'Direct Mail', RecordTypeId = rt2, Application_Status__c = 'Manually Approved', Application__c = 'test', Equipment_Cost__c = 5000, Equipment_Description__c = 'test', Payment_Amount__c = 5000, of_Payments__c = 12);
            
            insert opp;
            
            Payee__c payee = new Payee__c (Dealer__c = dealer.Id, Address1__c = 'test', City__c = 'test', State__c = 'MN', Zip__c = '11111', Email__c = 'test@test.com', 
                                            SL_Vendor_ID__c = 'test', X1099__c = true, Tax_ID_type__c = 'EIN', Tax_ID_Nbr__c = '6666666666',TIN_Name__c = 'TEST');
          	
            
            insert payee;

            //JAH(Tamarack - June 6, 2019): Removed Amount Financed since this causes error with Equip_Cost_Wo_Tax_grter_Sum_Amt_Finance validation rule
            //Payment__c payment = new Payment__c (Payment_Status__c = 'Ready to Send', Opportunity__c = opp.Id, Payee__c = payee.Id,Amount_Financed__c=10000);
            Payment__c payment = new Payment__c (Payment_Status__c = 'Ready to Send', Opportunity__c = opp.Id, Payee__c = payee.Id, Payment_Method__c = 'Check', 
                                                    Plus_Points__c = 1, Less_Points_Pool__c = 1);
			
            insert payment; 
            
            Payment__c[] paymentList = new Payment__c[]{};
            paymentList.add( payment);
            Solomon.SendPayments( paymentList);
            Test.stopTest();
            /*
            payment.Overnight__c = true;
            payment.Payment_Status__c = 'Ready to Send';
            
            update payment;
            
            Solomon.SendPayments( paymentList);
                        
            payee.Wire_Available__c = true;
            payee.Wire_ID__c = '000000000';
            payee.Wire_Account_Number__c = '0000000000';
            update payee;
            payment.Payment_Method__c = 'Wire';
            payment.Overnight__c = false;
            payment.Payment_Status__c = 'Ready to Send';
            
            update payment;
            
            Solomon.SendPayments( paymentList);

            payee.Wire_Available__c = false;
            payee.Wire_ID__c = '';
            payee.Wire_Account_Number__c = '';
            payee.ACH_Available__c = true;
            payee.ACH_Account_Type__c = 'Checking';
            payee.ACH_Bank_Transit__c = '000000000';
            payee.ACH_Account_Number__c = '0000000000';
            update payee;
            payment.Payment_Method__c = 'ACH';
            payment.Overnight__c = false;
            payment.Payment_Status__c = 'Ready to Send';
            
            update payment;
            
            Solomon.SendPayments( paymentList);           
            */
        }
    }
}