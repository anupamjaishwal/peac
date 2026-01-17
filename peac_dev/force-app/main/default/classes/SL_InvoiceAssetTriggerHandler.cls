public class SL_InvoiceAssetTriggerHandler extends SL_Trigger.baseHandler{
    private Map<Id, List<String>> fieldsChangedById = new Map<Id, List<String>>();
    Map<Id, Contract_Asset__c> contractAssets = new Map<Id, Contract_Asset__c>();
    private Set<Id> invoiceAssetIds = new Set<Id>();
    
    public override void afterInsert(Map<Id,sObject> newMap){
        for (Id invoiceAssetId :newMap.keySet()){
            getLookupMaps(newMap.get(invoiceAssetId));
        }
        afterChangesToOthers(true, newMap);
    }

    // private void checkUpdatedFields(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){
    //     List<String> fieldsToCheck = null;
    //     if(Trigger.isBefore){
    //         fieldsToCheck = new List<String>{'Name'};
    //     }else{// isAfter
    //         fieldsToCheck = new List<String>{'Name'};
    //     }
        
    //     for(Id recordId : newMap.keySet()){
    //         SObject newObj = newMap.get(recordId);
    //         SObject oldObj = oldMap.get(recordId);
    //         SL_TriggerUtil.findChangedFields(recordId, newObj, oldObj, fieldsChangedById, fieldsToCheck);
    //     }
    // }

    private void getLookupMaps(SObject obj){
        Invoice_Asset__c theInvoiceAsset = (Invoice_Asset__c)obj;
        if(theInvoiceAsset.Asset__c != null){
            this.contractAssets.put(theInvoiceAsset.Asset__c, new Contract_Asset__c());
        }
        if(theInvoiceAsset.Id != null){
            this.invoiceAssetIds.add(theInvoiceAsset.Id);           
        }
    }

    private void getInfoFromOthers(){
        if(invoiceAssetIds.size() > 0){
            for(Invoice_Asset__c related : [SELECT Id, Asset__r.Status2__c, Asset__r.Status_Date__c, Asset__r.Gross_Sale_Price__c
                FROM Invoice_Asset__c WHERE Id IN :invoiceAssetIds]){
                if(this.contractAssets.get(related.Asset__c) != null){
                    this.contractAssets.put(related.Asset__c, related.Asset__r);
                }
            }
        }
        // uncomment when we have beforeInsert scenario, or Contract asset lookup changed in beforeUpdate
        // if(this.contractAssets.size() > 0 && SL_TriggerUtil.checkForMissingInfo(this.contractAssets.values())){
        //     this.contractAssets.putAll([SELECT Id, Status2__c, Status_Date__c, Gross_Sale_Price__c
        //         FROM Contract_Asset__c WHERE Id IN :this.contractAssets.keySet()]);
        // }
    }

    private void afterChangesToOthers(Boolean isNew, Map<Id, SObject> newMap){
        List<Contract_Asset__c> UpdatecaList = new List<Contract_Asset__c>();
        getInfoFromOthers();
        for(SObject obj :newMap.values()){
            Invoice_Asset__c theInvoiceAsset = (Invoice_Asset__c) obj;
            Contract_Asset__c relatedCAsset = this.contractAssets.get(theInvoiceAsset.Asset__c);
            // List<String> fieldsChanged = fieldsChangedById.get(theInvoiceAsset.Id);
            if(isNew && relatedCAsset != null){// right now we only have afterInsert
                relatedCAsset.Status2__c='DLR Repurchase';
                relatedCAsset.Status_Date__c = Date.Today();
                relatedCAsset.Dealer_Repurchase_Date__c = Date.Today();
                relatedCAsset.Gross_Sale_Price__c = theInvoiceAsset.Unit_Price__c;
                UpdatecaList.add(relatedCAsset);
            }
        }
        if(UpdatecaList.size()>0){
            update UpdatecaList;
        }
    }

}