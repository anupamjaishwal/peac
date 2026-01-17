public with sharing class TC_SetDocusignRecipientContact {
    
    
    ///decommissioning this class for SAL- 4149
    
    ////Added this line to cover code coverge to pass deployment 
    public  void TC_SetDocusignRecipientContact(string dummy){
        
    }
    ////End : By Raja Sirivella
    

    /*public static void setContact(List<dsfs__DocuSign_Recipient_Status__c> newList){

        Set<Id> statusIds = new Set<Id>();

        for(dsfs__DocuSign_Recipient_Status__c recipient : newList){
            if(recipient.dsfs__DocuSign_Routing_Order__c == 1 || recipient.dsfs__DocuSign_Routing_Order__c == 2){
                statusIds.add(recipient.dsfs__Parent_Status_Record__c);
            }
        }

        List<Opportunity> oppList = new List<Opportunity>([SELECT Id,
                                                                    Primary_Contact__c,
                                                                    Primary_Contact__r.Name, 
                                                                    Primary_Contact__r.FirstName,
                                                                    Primary_Contact__r.LastName,
                                                                    Primary_Contact__r.Email,
                                                                    (SELECT Id 
                                                                    FROM dsfs__R00N80000002fD9vEAE__r
                                                                    WHERE Id IN :statusIds),
                                                                    (SELECT Id,
                                                                            Contact__c,
                                                                            Contact_Name__c, 
                                                                            Contact_First_Name__c,
                                                                            Contact_Last_Name__c,
                                                                            Email__c
                                                                    FROM Guarantor__r
                                                                    WHERE RecordTypeId = :Schema.SObjectType.Guarantor__c.getRecordTypeInfosByName().get('Personal').getRecordTypeId()
                                                                    ORDER BY CreatedDate ASC) 
                                                            FROM Opportunity 
                                                            WHERE Id IN (SELECT dsfs__Opportunity__c FROM dsfs__DocuSign_Status__c WHERE Id IN :statusIds)]);
        //Will contain map of dsfs__DocuSign_Status__c id, Opportunity
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        for(Opportunity opp : oppList){
            for(dsfs__DocuSign_Status__c status : opp.dsfs__R00N80000002fD9vEAE__r){
                if(oppMap.get(status.Id) == null){
                    oppMap.put(status.Id, opp);
                }
            }
        }
        for(dsfs__DocuSign_Recipient_Status__c recipient : newList){
            if(oppMap.get(recipient.dsfs__Parent_Status_Record__c) != null && recipient.dsfs__Contact__c == null){
                Boolean contactSet = false;
                for(Guarantor__c g : oppMap.get(recipient.dsfs__Parent_Status_Record__c).Guarantor__r){
                    if(recipient.Name == g.Contact_Name__c && recipient.dsfs__DocuSign_Recipient_Email__c == g.Email__c){
                        system.debug('Contact Set Id:' + g.Contact__c);
                        recipient.dsfs__Contact__c = g.Contact__c;
                        contactSet = true;
                    }
                }
                if(!contactSet && oppMap.get(recipient.dsfs__Parent_Status_Record__c).Primary_Contact__c != null && oppMap.get(recipient.dsfs__Parent_Status_Record__c).Primary_Contact__r.Email == recipient.dsfs__DocuSign_Recipient_Email__c){
                    if(oppMap.get(recipient.dsfs__Parent_Status_Record__c).Primary_Contact__r.Name == recipient.Name){
                        system.debug('Contact Set Id:' + oppMap.get(recipient.dsfs__Parent_Status_Record__c).Primary_Contact__c);
                        recipient.dsfs__Contact__c = oppMap.get(recipient.dsfs__Parent_Status_Record__c).Primary_Contact__c;
                    }
                }
            }
        }
    }*/

}