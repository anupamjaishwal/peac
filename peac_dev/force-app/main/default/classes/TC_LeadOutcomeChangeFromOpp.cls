/**
 * Created by trohweder on 10/7/20.
 */

public with sharing class TC_LeadOutcomeChangeFromOpp{
    
   
    Public static  boolean LeadOutComeUpdated = false ; // Recursive check for 101 error SAL-2414
    public static void updateLeadOutcome(Map <Id, Opportunity> oppOldMap, Map <Id, Opportunity> oppNewMap) {
       // Start Recursive check for 101 error SAL-2414
       if(LeadOutComeUpdated){ //
          return;//
        }else{//
            LeadOutComeUpdated = true;//
       }  //End Recursive check for 101 error SAL-2414
        
        List<Lead> leadsToUpdate;

        try{

            leadsToUpdate = new List<Lead>();

            system.debug('*****TC_LeadOutcomeChangeFromOpp*******');
            List<Lead> leads = [SELECT Id, Status, Lead_Outcome__c, Opportunity_Record_ID__c
            FROM Lead WHERE Opportunity_Record_ID__c in :oppNewMap.keySet()];
            System.debug(leads);
            for (Lead l : leads){

                if (l.Status == 'Closed - Converted'){
                    if(oppNewMap.get(l.Opportunity_Record_ID__c).Application_Status__c != 'Canceled' &&
                            (oppNewMap.get(l.Opportunity_Record_ID__c).StageName == 'Proposal' ||
                                    oppNewMap.get(l.Opportunity_Record_ID__c).StageName == 'Docs Requested' ||
                                    oppNewMap.get(l.Opportunity_Record_ID__c).StageName == 'Docs Out' ||
                                    oppNewMap.get(l.Opportunity_Record_ID__c).StageName == 'Docs In')){
                        if (l.Lead_Outcome__c <> 'Warm Transfer Approved'){
                            l.Lead_Outcome__c = 'Warm Transfer Approved';
                            leadsToUpdate.add(new Lead(Id = l.Id, Lead_Outcome__c = l.Lead_Outcome__c));
                        }
                    }
                    else if(oppNewMap.get(l.Opportunity_Record_ID__c).StageName == 'Funded/Booked'){
                        if (l.Lead_Outcome__c <> 'Warm Transfer Booked') {
                            l.Lead_Outcome__c = 'Warm Transfer Booked';
                            leadsToUpdate.add(new Lead(Id = l.Id, Lead_Outcome__c = l.Lead_Outcome__c));
                        }
                    }
                }
            }

            if (leadsToUpdate.size() > 0) {
                update leadsToUpdate;
            }

        }catch (Exception e){
            System.debug(e.getMessage());
        }

    }


    public static void doAction(Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
            updateLeadOutcome(oldMap,newMap);
       
    }
}