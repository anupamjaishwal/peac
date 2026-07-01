/**************************************************************************************************************************
@Author: Vinod Rathod (LTM)
@Description: This class Asynchronously recalculates Asset Calculated Monthly Rent when Opportunity lease factors change.
@User Story: SAL-5830 
@Created Date: March-30-2026
***************************************************************************************************************************/
public class PEAC_LeaseCalculationService {
    
    @future
    public static void updateAssetsFromOpportunityAsync(Set<Id> oppIds) {
        // 1. Query Assets and include the Parent Opportunity factors via Relationship fields
        List<Asset__c> assetList = [ SELECT Id, Asset_Classification__c, List_Price__c, Opportunity__c,Opportunity__r.Hard_Lease_Rate_Factor__c, 
                                    Opportunity__r.Soft_Lease_Rate_Factor__c  FROM Asset__c  WHERE Opportunity__c IN :oppIds
                                   ];
        
        if (!assetList.isEmpty()){
            for (Asset__c asset : assetList) {
                
                if (asset.Asset_Classification__c == null) {
                    continue;
                }
                
                Opportunity relatedOpp = asset.Opportunity__r;
                
                // 1. Determine Price based on Classification
                Double softListPrice = asset.Asset_Classification__c == 'Soft' ? (asset.List_Price__c ?? 0) : 0;
                Double hardListPrice = asset.Asset_Classification__c == 'Hard' ? (asset.List_Price__c ?? 0) : 0;
                
                // 2. Perform Calculation using Factors from the correct Opp
                Double hardFactor = relatedOpp?.Hard_Lease_Rate_Factor__c ?? 0;
                Double softFactor = relatedOpp?.Soft_Lease_Rate_Factor__c ?? 0;
                
                asset.Calculated_Monthly_Rent__c = (hardListPrice * hardFactor) + (softListPrice * softFactor);
            }
            
            try {
                update assetList;
            } catch (Exception e) {
                System.debug('LeaseCalculationService Error: ' + e.getMessage());
            }
        }
    }
    
}