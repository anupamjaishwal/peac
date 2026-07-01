/**************************************************************************************************************************
@Author: Vinod Rathod (LTM)
@Description: This class is used to update all related Asset records when the opportunity Booked Date is changed .
@User Story: SAL-7114 
@Created Date: April-21-2026
***************************************************************************************************************************/
public class PEAC_AssetBookedDateUpdater {
    
    public static void onOpportunityBookedDateChange( Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap ){
        
        Set<Id> oppIds = new Set<Id>();
        
        for(Opportunity opp : newMap.values()){
            Opportunity oldOpp = oldMap.get(opp.Id);
            if(opp.Opportunity_Booked_Date__c != oldOpp.Opportunity_Booked_Date__c && !opp.Loan_Record_Type__c) {
                oppIds.add(opp.Id);
            }   
        }
        
        if(!oppIds.isEmpty()){
            updateAssetBookedDates(oppIds);
        }    
    }
    
   /**
    * future Method
    * Update related Asset records for given Opportunity Ids
    */
    @future
    public static void updateAssetBookedDates(Set<Id> opportunityIds){

        List<Asset__c> assetToUpdate = new List<Asset__c>();
        
        for (Asset__c asset : [ SELECT Id,  Opportunity__c,Opportunity__r.Contract_Type__c,Opportunity__r.Opportunity_Booked_Date__c, Begin_Depreciation_Date__c,State_Begin_Depreciation_Date__c,
                               Operating_Begin_Depreciation_Date__c FROM Asset__c  WHERE Opportunity__c IN :opportunityIds
                              ]){
                                  
                                      Date bookedDate = asset.Opportunity__r.Opportunity_Booked_Date__c?.date();
                                                                           
                                      asset.State_Begin_Depreciation_Date__c = bookedDate;
                                      asset.Begin_Depreciation_Date__c = bookedDate;
                                      if(asset.Opportunity__r?.Contract_Type__c != null && PEAC_ConstantClass.OPERATING_LEASE.Contains(asset.Opportunity__r.Contract_Type__c)){
                                          asset.Operating_Begin_Depreciation_Date__c = bookedDate;
                                      }
                                      assetToUpdate.add(asset);
  
                              }
        // Update Assets
        if(!assetToUpdate.isEmpty()){
            update assetToUpdate;
        } 
    }   
}