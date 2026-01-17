public class TC_CheckListWithAttachmentsTriggerHelper {
    
    public static void UpadateChecklist(List<TC_Origination__Checklist_Item_with_Attachments__c> newlist, Map<Id,TC_Origination__Checklist_Item_with_Attachments__c> oldMap){
        
        Set<String> setCheckListIds = new Set<String>();
      
        for(TC_Origination__Checklist_Item_with_Attachments__c objCIA : newlist){
            
            if(objCIA.Name == 'Customer Verification Procedures Required'){
                system.debug('oldMap'+oldMap.get(objCIA.Id).TC_Origination__Primary_Reviewer__c);
                if(objCIA.TC_Origination__Primary_Reviewer__c != oldMap.get(objCIA.Id).TC_Origination__Primary_Reviewer__c){
                    setCheckListIds.add(objCIA.TC_Origination__Checklist__c);
                }
            }
            
            
        }
        system.debug('setCheckListIds'+setCheckListIds);
        List<TC_Origination__Checklist_Item_with_Attachments__c> lstCheckListItemsToUpdate = new List<TC_Origination__Checklist_Item_with_Attachments__c>();
        Map<String, Map<String, Boolean>> mapCheckListToCItems = new Map<String, Map<String, Boolean>>();
        
        List<TC_Origination__Checklist__c> lstCL = [Select Id, Name, (Select Id, Name, TC_Origination__Primary_Reviewer__c from TC_Origination__Checklist_Items_with_Attachments__r) from TC_Origination__Checklist__c where Id IN :setCheckListIds];
        for(TC_Origination__Checklist__c objCL : lstCL){
            Map<String, Boolean> mapCheckListItem = new Map<String, Boolean>();
            for(TC_Origination__Checklist_Item_with_Attachments__c objTCIA : objCL.TC_Origination__Checklist_Items_with_Attachments__r){
                if(objTCIA.Name == 'Customer Verification Procedures Required'){
                    mapCheckListItem.put(objTCIA.Name, objTCIA.TC_Origination__Primary_Reviewer__c);
                }
                if(objTCIA.Name == 'Copy of drivers\'s license'){
                    mapCheckListItem.put(objTCIA.Name, objTCIA.TC_Origination__Primary_Reviewer__c);
                }
                
            }
            
           mapCheckListToCItems.put(objCL.Id, mapCheckListItem);
        }
        for(TC_Origination__Checklist__c objCL : lstCL){
            Boolean isCVPCompleted = false;
            if(objCL.TC_Origination__Checklist_Items_with_Attachments__r.size() > 0){
               
            objCL.TC_Origination__Checklist_Items_with_Attachments__r.sort();
            for(TC_Origination__Checklist_Item_with_Attachments__c objTCIA : objCL.TC_Origination__Checklist_Items_with_Attachments__r){
               /* if(objTCIA.Name == 'Customer Verification Procedures Required' && objTCIA.TC_Origination__Primary_Reviewer__c){
                    isCVPCompleted = true;
                    System.debug('inside 1stIf    '+isCVPCompleted);
                } */
                if(mapCheckListToCItems.containsKey(objCL.Id) && objTCIA.Name == 'Copy of drivers\'s license'){
                    if(mapCheckListToCItems.get(objCL.Id).containsKey('Customer Verification Procedures Required')){
                        isCVPCompleted = mapCheckListToCItems.get(objCL.Id).get('Customer Verification Procedures Required');
                    }
                }
                
               
                System.debug('objTCIA.Name =' +objTCIA.Name);
                 System.debug('isCVPCompleted =' +isCVPCompleted);
                System.debug('objTCIA.TC_Origination__Primary_Reviewer__c =' +objTCIA.TC_Origination__Primary_Reviewer__c);
                if(objTCIA.Name == 'Copy of drivers\'s license' && !objTCIA.TC_Origination__Primary_Reviewer__c && isCVPCompleted){
                    System.debug('inside 2ndIf    '+isCVPCompleted);
                    objTCIA.TC_Origination__Primary_Reviewer__c = true;
                    objTCIA.TC_Origination__Included__c = true;
                }
                lstCheckListItemsToUpdate.add(objTCIA);
            } 
            }
            
           
        }
        if(lstCheckListItemsToUpdate.size() > 0){
             System.debug('lstCheckListItemsToUpdate'+lstCheckListItemsToUpdate[0].TC_Origination__Primary_Reviewer__c);
        }
       
        update lstCheckListItemsToUpdate;
    }
    
    
}