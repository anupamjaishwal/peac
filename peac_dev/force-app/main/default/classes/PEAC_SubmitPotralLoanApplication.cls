/************************************************************************************************************************
 @Description: Submitting the loan application from the portal to gds
 @Author: Rajesh Kumar(LTIMindtree)
 @Created Date: 06/16/2025
 ************************************************************************************************************************/

public with sharing class PEAC_SubmitPotralLoanApplication {
    
    public static void submitPortalApp(Map<Id,SObject> newMap ,Map<Id,SObject> oldMap)
    {
        List<GDS_Action__e> gdsActionEventList = new List<GDS_Action__e>();
        for(SObject opp:newMap.values())
        {
            Opportunity oppObj = (Opportunity)opp;
            Opportunity oppOldObj = (Opportunity)oldMap.get(opp.Id);
            if(oppObj.Portal_App_Completed__c != oppOldObj.Portal_App_Completed__c && oppObj.Portal_App_Completed__c && oppObj.Loan_Record_Type__c )
            {
                gdsActionEventList.add(new GDS_Action__e(Record_Id__c = oppObj.Id,Action__c = Label.PEAC_Portal_Loan_APP));
            }

        }
        if (!gdsActionEventList.isEmpty()) {
           EventBus.publish(gdsActionEventList);
            
        }
    }
}