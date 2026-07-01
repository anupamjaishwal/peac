/**************************************************************************************************************
@Author: Vinod Rathod (LTIMindtree)
@Description: This class is used to Create Purchase Orders for Assets and Used in pEAC_CreatePurchaseOrder LWC.  
@User Story: SAL-6375
@Created Date: JAN-14-2026
**************************************************************************************************************/

public with sharing class PEAC_PurchaseOrderController {
    
    @AuraEnabled
    public static String createPurchaseOrders(Id OpportunityId) {
        
        If(OpportunityId == null){
            throw new AuraHandledException('Opportunity Id is required');
        }
        
        /* Step 1: Fetch Assets*/
        //
        List<Asset__c> assetList = [SELECT Id, Dealer__c, Customer_PO_Number__c, Purchase_Order__c, Usage_Dealer_Invoice_Number__c,Vendor_PO_Number__c 
                                    FROM Asset__c WHERE Opportunity__c = :OpportunityId 
                                    AND Customer_PO_Number__c != null
                                   ];
        If(assetList.isEmpty()){
            return  System.Label.PEAC_Purchase_Order_Error;
        }
        
        /* Step 2: Group Assets by Customer PO Number */
        Map<String, List<Asset__c>> assetsByPONumber = New Map<String, List<Asset__c>>();
        
        for(Asset__c asset : assetList){
            If(!assetsByPONumber.containsKey(asset.Customer_PO_Number__c)){
                assetsByPONumber.put(asset.Customer_PO_Number__c, new List<Asset__c>());
            }
            assetsByPONumber.get(asset.Customer_PO_Number__c).add(asset);
        }
        
        /* Step 3: Fetch Existing Purchase Orders (Duplicate Prevention)*/
        Map<String, Purchase_Order__c> existingPOByNumber = new Map<String, Purchase_Order__c>();
        
        List<Purchase_Order__c> purchaseOrderList = [SELECT Id, Customer_PO_Number__c FROM Purchase_Order__c
                                                     WHERE Opportunity__c = :OpportunityId AND 
                                                     Customer_PO_Number__c In :assetsByPONumber.keySet()
                                                    ];
        If(!purchaseOrderList.isEmpty()){  
            for(Purchase_Order__c purchaseOrder : purchaseOrderList){
                existingPOByNumber.put(purchaseOrder.Customer_PO_Number__c, purchaseOrder);
            }
        }
        
        /* Step 4: Create Missing Purchase Order */
        List<Purchase_Order__c> purchaseOrderToInsert = new List<Purchase_Order__c>();
        
        // Fetch the ID 
        Id poRecordTypeId = Schema.SObjectType.Purchase_Order__c.getRecordTypeInfosByDeveloperName()
            .get('Ordering_Purchase_Order')
            .getRecordTypeId();
        
        for(String poNumber : assetsByPONumber.keySet()){
            Asset__c a = assetsByPONumber.get(poNumber)[0];
            If(!existingPOByNumber.containsKey(poNumber)){
                Purchase_Order__c purchaseOrder = new Purchase_Order__c();
                purchaseOrder.Opportunity__c = OpportunityId;
                purchaseOrder.Customer_PO_Number__c = poNumber;
                purchaseOrder.Invoice_Number__c = a.Usage_Dealer_Invoice_Number__c;
                purchaseOrder.RecordTypeId = poRecordTypeId;
                purchaseOrder.Vendor_PO_Number__c = a.Vendor_PO_Number__c;
                purchaseOrder.Dealer__c = a.Dealer__c;
                purchaseOrder.Opp_Unique_Customer_PO_Number__c = OpportunityId+'~'+poNumber;//SAL-7234
                purchaseOrderToInsert.add(purchaseOrder);
            }   
        }
        
        if(!purchaseOrderToInsert.isEmpty()){
            insert purchaseOrderToInsert;
            
            for(Purchase_Order__c purchaseOrder :purchaseOrderToInsert){
                existingPOByNumber.put(purchaseOrder.Customer_PO_Number__c, purchaseOrder);   
            }
        
        
        /* Step 5: Prepare for Future Method */
        // We pass a Map of PO Number to PO Id for the lookup update
        Map<String, Id> poNumberToIdMap = new Map<String, Id>();
        for(String poNum : existingPOByNumber.keySet()){
            poNumberToIdMap.put(poNum, existingPOByNumber.get(poNum).Id);
        }
        
        // Serialize maps to JSON strings to bypass the Map parameter limitation
        String serializedPONumbers = JSON.serialize(poNumberToIdMap);
        String serializedAssets = JSON.serialize(assetsByPONumber);
        
        updateAssetsAsync(serializedPONumbers, serializedAssets); 
            
        // Return Success Message
        return System.Label.PEAC_Purchase_Order;
        }
        // Return Info string if no new customer po# 
        return System.Label.PEAC_Purchase_Order_Error;
    }
    
    /** 
     * Step 5: Update Assets with PO Lookup.
     * @Description: Future method to update Assets with the created Purchase Order lookup asynchronously.
     */
    @future
    public static void updateAssetsAsync(String serializedPONumbers, String serializedAssets) {
        // Deserializing back to original types
        Map<String, Id> poMap = (Map<String, Id>)JSON.deserialize(serializedPONumbers, Map<String, Id>.class);
        Map<String, List<Asset__c>> assetsMap = (Map<String, List<Asset__c>>)JSON.deserialize(serializedAssets, Map<String, List<Asset__c>>.class);
        
        List<Asset__c> assetsToUpdate = new List<Asset__c>();
        
        for(String poNumber : assetsMap.keySet()){
            Id purchaseOrderId = poMap.get(poNumber);
            
            for(Asset__c asset : assetsMap.get(poNumber)){
                if(asset.Purchase_Order__c != purchaseOrderId){
                    asset.Purchase_Order__c = purchaseOrderId;
                    assetsToUpdate.add(asset);
                }
            }
        }
        
        if(!assetsToUpdate.isEmpty()){
            // Perform the DML operation in the future context
            update assetsToUpdate;
        }
    }        
    
}