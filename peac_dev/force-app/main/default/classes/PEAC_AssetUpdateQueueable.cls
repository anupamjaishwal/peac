/************************************************************************************************************************
 @Description: Update assets asynchronously
 @Author: Rajesh Kumar(LTIMindtree)
 @Created Date: 03/11/2026
************************************************************************************************************************/
public without sharing class PEAC_AssetUpdateQueueable implements Queueable, Database.AllowsCallouts{
    List<Asset__c> assetsList = new List<Asset__c>();
    public PEAC_AssetUpdateQueueable(List<Asset__c> assetsList) {
        this.assetsList = assetsList;
    }

    public void execute(QueueableContext qc)
    {
        if (!assetsList.isEmpty()) {
            update assetsList; // update opportunity assets
        }
    }

}