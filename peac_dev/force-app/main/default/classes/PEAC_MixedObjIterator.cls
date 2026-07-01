/**************************************************************************************************************
@Author: Chalapati Murru (LTIMindtree)
@Description: This class is used to Generate Tax Matrix for bulk processing multiple object types
@User Story: SAL-5692 Expo: Opportunity Refactor
@Created Date: Nov-10-2025
**************************************************************************************************************/
public class PEAC_MixedObjIterator implements Iterator<PEAC_MixedObjWrapper>{
	private Integer index = 0;
    private List<PEAC_MixedObjWrapper> records;
    
    public PEAC_MixedObjIterator(Set<Id> oppIds){
        records = new List<PEAC_MixedObjWrapper>();
        //Fetch Asset__c
        for(Asset__c asset : [SELECT Id, Opportunity__c FROM Asset__c WHERE Opportunity__c IN: oppIds]){
            records.add(new PEAC_MixedObjWrapper('Asset__c',asset));
        }
        //Fetch Miscellaneous_Billable_Item__c
        for(Miscellaneous_Billable_Item__c mbItem : [SELECT Id, Opportunity__c FROM Miscellaneous_Billable_Item__c WHERE Opportunity__c IN: oppIds]){
            records.add(new PEAC_MixedObjWrapper('Miscellaneous_Billable_Item__c',mbItem));
        }
        //Fetch Miscellaneous_Invoice_Item__c
		for(Miscellaneous_Invoice_Item__c miItem : [SELECT Id, Opportunity__c FROM Miscellaneous_Invoice_Item__c WHERE Opportunity__c IN: oppIds]){
            records.add(new PEAC_MixedObjWrapper('Miscellaneous_Invoice_Item__c',miItem));
        }
    }
    
    public Boolean hasNext(){
        return index < records.size();
    }
    
    public PEAC_MixedObjWrapper next(){
        if(!hasNext()){
            throw new NoSuchElementException('No more records');
        }
        return records[index++];
    }
}