/**************************************************************************************************************
@Author: Chalapati Murru (LTIMindtree)
@Description: This class is used to Generate Tax Matrix for bulk processing multiple object types
@User Story: SAL-5692 Expo: Opportunity Refactor
@Created Date: Nov-10-2025
**************************************************************************************************************/
public class PEAC_MixedObjWrapper{
    public String objectType;//Stores object type like Account or Opportunity.
    public sObject record;//Stores the actual record.
    
    public PEAC_MixedObjWrapper(String objectType, sObject record){
        this.objectType = objectType;
        this.record = record;
    }
}