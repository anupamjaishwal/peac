/************************************************************************************************************************
 @Description: Gatekeeper class for sending emails to dealers
 @Author: Rajesh Kumar(LTM)
 @Created Date: 05/11/2026
 @User Story: SAL-7221
 ************************************************************************************************************************/

public without sharing class PEAC_DealerNotificationGatekeeper {
    
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTM)
    @Description: This method will be called from TC_OpportunityTriggerHandler to send emails to dealers
    @User Story:SAL-7221	 
    @Param:New Map of opportunity id with record and old map of opportunity id with record 
    @Created Date:05/11/2026   
    **************************************************************************************************************/
    public static void sendDealerNotification(Map<Id, Opportunity> newOppsMap, Map<Id, Opportunity> oldOppsMap) {
        Map<Id, Opportunity> newOpportunityMap = new Map<Id, Opportunity>();
        Map<Id, Opportunity> oldOpportunityMap = new Map<Id, Opportunity>();
        Set<Id> oppIdSet = new Set<Id>();
        for(Opportunity opp : newOppsMap.values()) {
            if(!Label.PEAC_Exclude_Dealer_Notification.split(',').Contains(opp.originating_business__c))  {
                newOpportunityMap.put(opp.Id, opp);
                oldOpportunityMap.put(opp.Id,oldOppsMap != null ? oldOppsMap.get(opp.Id) : null  );
            }
            if (Label.PEAC_Exclude_Dealer_Notification.split(',').Contains(opp.originating_business__c) && opp.StageName == 'Docs In' && oldOppsMap.get(opp.Id).StageName != 'Docs In')
            {
                oppIdSet.add(opp.Id);
            }
            
        }
        if(!newOpportunityMap.isEmpty())
        {
            TC_SendDealerNotification.scheduleSubmissionNotification((Map<Id, Opportunity>)oldOpportunityMap, (Map<Id, Opportunity>)newOpportunityMap);
            TC_SendDealerNotification.scheduleApprovalNotification((Map<Id, Opportunity>)oldOpportunityMap, (Map<Id, Opportunity>)newOpportunityMap);    
            TC_SendDealerNotification.docsOutNotification((Map<Id, Opportunity>)oldOpportunityMap, (Map<Id, Opportunity>)newOpportunityMap);    
            TC_SendDealerNotification.docsInNotification((Map<Id, Opportunity>)oldOpportunityMap, (Map<Id, Opportunity>)newOpportunityMap);    
            TC_SendDealerNotification.inFundingNotification((Map<Id, Opportunity>)oldOpportunityMap, (Map<Id, Opportunity>)newOpportunityMap);    
            TC_SendDealerNotification.fundedNotification((Map<Id, Opportunity>)oldOpportunityMap, (Map<Id, Opportunity>)newOpportunityMap);    
            TC_SendDealerNotification.scheduleMoreInfoNotification((Map<Id, Opportunity>)oldOpportunityMap, (Map<Id, Opportunity>)newOpportunityMap);    
            TC_SendDealerNotification.scheduleDeclinedNotification((Map<Id, Opportunity>)oldOpportunityMap, (Map<Id, Opportunity>)newOpportunityMap); 
            
        }
        if(!oppIdSet.IsEmpty())
        {
            SL_DocsInNotificationHelper.sendEmail(oppIdSet);
        }

    }
}