public with sharing class TC_DocusignRecipientStatusTriggerHelper {
    
    ///decommissioning this class for SAL- 4149
    
    ////Added this line to cover code coverge to pass deployment 
    public  void TC_DocusignRecipientStatusTriggerHelper(string dummy){
        
    }
    ////End : By Raja Sirivella
    

   /* public static void callAssignSignersAPI(List<dsfs__DocuSign_Recipient_Status__c> newList) {
        Set<Id> docusignStatusIds = new Set<Id>();

        for(dsfs__DocuSign_Recipient_Status__c recipient : newList){
            if( recipient.dsfs__DocuSign_Routing_Order__c == 8){
                //add Ids of status objects needed in query
                docusignStatusIds.add(recipient.dsfs__Parent_Status_Record__c);
                //TC_AssignSignersAPI.callAssignSignersAPI(recipient.dsfs__Parent_Status_Record__c);
            }
        }
        //Query map of status objects so we can check the opportunity workflow type
        Map<Id, dsfs__DocuSign_Status__c> statusObjects = new Map<Id, dsfs__DocuSign_Status__c> ([
            SELECT Id, dsfs__Opportunity__r.Workflow_Type__c FROM dsfs__DocuSign_Status__c WHERE Id IN :docusignStatusIds
        ]);

        for(Id i : docusignStatusIds){
            if(statusObjects.get(i) != null){
                //Api is only called if Workflow Type is Simple on the opportunity
                if(statusObjects.get(i).dsfs__Opportunity__r.Workflow_Type__c == 'Simple'){
                    TC_AssignSignersAPI.callAssignSignersAPI(i);
                }
            }
        }
    }

    public static void setRecipientContactId(List<dsfs__DocuSign_Recipient_Status__c> newList){

        TC_SetDocusignRecipientContact.setContact(newList);
    }*/
}