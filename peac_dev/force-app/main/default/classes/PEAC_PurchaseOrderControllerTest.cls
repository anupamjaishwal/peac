/***********************************************************************************************************************
@Author: Vinod Rathod (LTIMindtree)
@Description: This test class validates the PEAC_PurchaseOrderController logic for creating Purchase orders from Assets
grouped by Customer PO number.
@User Story: SAL-6375
@Created Date: JAN-28-2026
*************************************************************************************************************************/
@IsTest
public class PEAC_PurchaseOrderControllerTest {
    @TestSetup
    public static void setupAssetTest () {
        //Create Account
        Account acc = new Account (Name = 'test');
        insert acc;
        //Create Opportunity
        Opportunity opp = new Opportunity (CloseDate = Date.today()+10,Name='test',AccountId=acc.Id,Equipment_Cost__c=50000,StageName='Decision',Contract_Type__c='TL');
        insert opp;
        //Create Asset with Same Customer PO Number
        List <Asset__c> assetList = new List <Asset__c>();
        assetList.add(new Asset__c (End_User_Billing_Address__c = true, Quantity__c = 1, Equipment_Code__c = 'ATM',Usage_Dealer_Invoice_Number__c ='INV-01',
                                    Customer_PO_Number__c = 'PO-001',Equipment_Sub_Category__c = 'ATM', Opportunity__c = opp.Id));
        assetList.add(new Asset__c (End_User_Billing_Address__c = true, Quantity__c = 1, Equipment_Code__c = 'ATM',Usage_Dealer_Invoice_Number__c ='INV-01',
                                    Customer_PO_Number__c = 'PO-001',Equipment_Sub_Category__c = 'ATM', Opportunity__c = opp.Id));
        
        
        //Create Asset with Different Customer PO Number
        assetList.add(new Asset__c (End_User_Billing_Address__c = true, Quantity__c = 1, Equipment_Code__c = 'ATM',Usage_Dealer_Invoice_Number__c ='INV-02',
                                    Customer_PO_Number__c = 'PO-002',Equipment_Sub_Category__c = 'ATM', Opportunity__c = opp.Id));
        insert assetList;
        //Existing Purchase Order (duplicate previntion case)
        Purchase_Order__c existingPurchaseOrder= new Purchase_Order__c();
        existingPurchaseOrder.Customer_PO_Number__c = 'PO-002';
        existingPurchaseOrder.Opportunity__c = opp.Id;
        insert existingPurchaseOrder;
        
    }
    
    @IsTest
    public static void testCreatePurchaseOrders(){
        Test.startTest();
        Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
        String result = PEAC_PurchaseOrderController.createPurchaseOrders(opportunity.Id);
        
        // Verify Purchase Orders
        List<Purchase_Order__c> purchaseOrderList = [SELECT Id, Customer_PO_Number__c FROM Purchase_Order__c
                                                     WHERE Opportunity__c = :opportunity.Id 
                                                    ];
        // Verify Assets updated with PO lookup
        List<Asset__c> updatedAssets = [SELECT Id, Customer_PO_Number__c, Purchase_Order__c FROM Asset__c
                                        WHERE Opportunity__c = :opportunity.Id 
                                       ];
        Test.stopTest();
        system.debug('updatedAssets ---'+updatedAssets);
        system.debug('purchaseOrderList ---'+purchaseOrderList);
        
        system.assertEquals('Purchase Orders created successfully.',result,'Success message should be returned');
        system.assertEquals(2, purchaseOrderList.size(), 'Two Purchase Order should exist');
    }    
}