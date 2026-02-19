trigger TC_AssetTrigger on Asset__c (after insert, after update, after delete, before insert, before update) {
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            // TC_AssetTriggerHelper.populateCostFieldsPriceFirstAsset (Trigger.new);
            // TC_AssetTriggerHelper.updateCostFieldsOnAsset (Trigger.new, null, null, null);
            TC_AssetTriggerHelper.copyRentalAmountFromFormula(Trigger.new);
        } else if (Trigger.isUpdate) {
            //TC_AssetTriggerHelper.updateCostFieldsOnAsset (null, Trigger.oldMap, Trigger.newMap, Trigger.new);
            // TC_AssetTriggerHelper.listPriceUpdated (null, Trigger.oldMap, Trigger.newMap, Trigger.new);
            // TC_AssetTriggerHelper.costUpdated (null, Trigger.oldMap, Trigger.newMap, Trigger.new);
            TC_AssetTriggerHelper.roundTaxAmounts (Trigger.oldMap, Trigger.new);
            TC_AssetTriggerHelper.copyRentalAmountFromFormula(Trigger.new);
        }
        // reducing CPU time by replacing this function with assetTriggerHandler.setZipUpdatedFlag
        // TC_BridgewareUtility.setZipUpdatedFlag(Trigger.new, Trigger.oldMap);
    }
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert && (!Test.isRunningTest())) {
            TC_AssetTriggerHelper.createStandardAsset (null, Trigger.newMap);
            // TC_AssetTriggerHelper.rollupFields(null, Trigger.newMap);
            
        } else if (Trigger.isUpdate) {
            // TC_AssetTriggerHelper.rollupFields(Trigger.oldMap, Trigger.newMap);
            TC_AssetTriggerHelper.updateTNUpfrontCountyTax (Trigger.oldMap, Trigger.new);
            // TC_AssetTriggerHelper.setOpportunityTaxState (Trigger.oldMap, Trigger.new);
            
        } else if (Trigger.isDelete) {
            // TC_AssetTriggerHelper.rollupFields(Trigger.oldMap, null);
        }
    }
}