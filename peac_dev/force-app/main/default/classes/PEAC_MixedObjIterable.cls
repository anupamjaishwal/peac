/**************************************************************************************************************
@Author: Chalapati Murru (LTIMindtree)
@Description: This class is used to Generate Tax Matrix for bulk processing
@User Story: SAL-5692 Expo: Opportunity Refactor
@Created Date: Nov-10-2025
**************************************************************************************************************/
public with sharing class PEAC_MixedObjIterable implements Iterable<PEAC_MixedObjWrapper>{
    Set<Id> oppIds = null;
    public PEAC_MixedObjIterable(Set<Id> oppIds){
        this.oppIds = oppIds;
    }
    
    public Iterator<PEAC_MixedObjWrapper> iterator() {
		return new PEAC_MixedObjIterator(this.oppIds);
    }    
}