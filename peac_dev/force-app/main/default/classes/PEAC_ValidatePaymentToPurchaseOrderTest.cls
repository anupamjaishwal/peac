@IsTest
public class PEAC_ValidatePaymentToPurchaseOrderTest {
    // Convenience variables for constants used by the class under test
    private static final String PO_FUNDED = PEAC_ConstantClass.PURCHASE_ORDER_STATUS_FUNDED;
    private static final String PAY_ACK  = PEAC_ConstantClass.PAYMENT_STATUS_PAYMENT_ANKNOWLEDGED;
    private static final String PAY_REL  = PEAC_ConstantClass.PAYMENT_STATUS_PAYMENT_RELEASED;

     @TestSetup
    static void setup() {
        
        Marlin_Configuration__c config = Marlin_Configuration__c.getOrgDefaults ();
        config.Enable_Auto_Move_to_Booking__c = true;
        insert config;
        
        Account acc = new Account (Name = 'test', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Franchisee Account').getRecordTypeId(), Business_Address__c = 'test', Business_Phone__c = '1234567890');
        insert acc;
        
        Contact primary = new Contact (FirstName = 'test', LastName = 'test2', Email = 'test@test.com', AccountId = acc.Id);
        insert primary;
        
        Test.startTest();
        Contact billing = new Contact (FirstName = 'test', LastName = 'test2', AccountId = acc.Id);
        insert billing;
        
        Account dealer = new Account (Name = 'dealer', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId(), Equipment_Type__c = 'A/V (General)');
        insert dealer;
        Test.stopTest();
    }

	@isTest
    public static void validatePaymentToUpdatePOTest(){
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        Account acc = [SELECT Id FROM Account WHERE Name = 'test'];
        Account dealer = [SELECT Id FROM Account WHERE Name = 'dealer'];
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'][0];
       	Opportunity opp = new Opportunity (Name = 'checklistTest', StageName = 'Decision', CloseDate = Date.today () + 10, AccountId = acc.Id, Primary_Source__c = 'Direct Mail', Application_Status__c = 'Manually Approved', Application__c = 'test', Equipment_Cost__c = 5000, Equipment_Description__c = 'test', Payment_Amount__c = 5000, of_Payments__c = 12);
       	insert opp;
        Test.startTest();
        Purchase_Order__c po = new Purchase_Order__c();
        po.Opportunity__c = opp.Id;
        insert po;
        Payee__c payee = new Payee__c (Dealer__c = dealer.Id, Address1__c = 'test', City__c = 'test', State__c = 'MN', Zip__c = '11111', Email__c = 'test@test.com', SL_Vendor_ID__c = 'test');
        insert payee;
        Payment__c payment = new Payment__c (Payment_Status__c = PEAC_ConstantClass.PAYMENT_STATUS_PAYMENT_ANKNOWLEDGED,
                                             Opportunity__c = opp.Id, Payee__c = payee.Id, Purchase_Order__c=po.Id);
        insert payment;
        Payment__c objPayment = [SELECT Id, Payment_Status__c, Purchase_Order__c, Opportunity__c, Payee__c  FROM Payment__c WHERE Opportunity__c =: opp.Id LIMIT 1];
        PEAC_ValidatePaymentToPurchaseOrder.validatePaymentToUpdatePO(new List<Payment__c>{objPayment});
        Test.stopTest();
        
            //payment.Payment_Status__c = 'Payment Confirmed';
            //update payment;
    }


}