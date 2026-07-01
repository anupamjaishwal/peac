/*************************************************************************************************************************
@Author: Chalapati Murru (LTIMindtree)
@Description: This class is used to update Assets & Blended Income Items Asynchronously when Opp moved to Booking stage
@User Story:SAL-5692 Expo: Opp Refactor - To replace "TC Opportunity: Booking Rules - Depreciation Dates Flow"
@Created Date: Jan-30-2026
*************************************************************************************************************************/
public class PEAC_UpdateAssetsBlenIncItemAsync {
    
    public static void updateAssetsBlenIncItemAsync(String oppId){
        System.enqueueJob(new PEAC_UpdateAssetsQueueable(oppId));
        System.enqueueJob(new PEAC_UpdateBlenIncItemsQueueable(oppId));
    }
    
    /**************************************************************************************************************
    @Author: Chalapati Murru (LTIMindtree)
    @Description: This class is used to update Assets Asynchronously when Opp moved to Booking stage
    @User Story: SAL-5692 Expo: Opportunity Refactor
    @Created Date: Jan-30-2026
    **************************************************************************************************************/
    public class PEAC_UpdateAssetsQueueable implements Queueable {
        private Id oppId;
        
        public PEAC_UpdateAssetsQueueable(Id oppId) {
            this.oppId = oppId;
        }
        
        public void execute(QueueableContext qc) {
            List<Asset__c> assetsList = new List<Asset__c>();
            
            for(Asset__c asset : [SELECT Id,Begin_Depreciation_Date__c,State_Begin_Depreciation_Date__c,Opportunity__r.Opportunity_Booked_Date__c 
                          FROM Asset__c WHERE Opportunity__c =: this.oppId
                          AND Opportunity__r.Opportunity_Booked_Date__c != null]){
               asset.Begin_Depreciation_Date__c = asset.State_Begin_Depreciation_Date__c = asset.Opportunity__r.Opportunity_Booked_Date__c?.date();
               assetsList.add(asset);
            }
            if(!assetsList.isEmpty())
        		update assetsList;
        }
    }
    
    /**********************************************************************************************************************
    @Author: Chalapati Murru (LTIMindtree)
    @Description: This class is used to update Blended Income Items Asynchronously when Opp moved to Booking stage
    @User Story: SAL-5692 Expo: Opportunity Refactor
    @Created Date: Jan-30-2026
    **********************************************************************************************************************/
    public class PEAC_UpdateBlenIncItemsQueueable implements Queueable {
        private Id oppId;
        
        public PEAC_UpdateBlenIncItemsQueueable(Id oppId) {
            this.oppId = oppId;
        }
        
        public void execute(QueueableContext qc) {
            List<Blended_Income_Item__c> blenIncItemsList = new List<Blended_Income_Item__c>();
    
            for(Blended_Income_Item__c blenIncItem : [SELECT Id,Begin_Date__c,Opportunity__r.Commencement_Date__c 
                          FROM Blended_Income_Item__c WHERE Opportunity__c =: this.oppId
                          AND Opportunity__r.Commencement_Date__c != null]){
               blenIncItem.Begin_Date__c = blenIncItem.Opportunity__r.Commencement_Date__c;
               blenIncItemsList.add(blenIncItem);
            }
            if(!blenIncItemsList.isEmpty())
            	update blenIncItemsList;
        }
    }
}