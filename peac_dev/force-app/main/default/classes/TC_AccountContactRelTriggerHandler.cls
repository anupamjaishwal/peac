public class TC_AccountContactRelTriggerHandler {
    public static void checkNumberOfACRs(List<AccountContactRelation> lstAcr, Map<Id, AccountContactRelation> mapOldACR, TriggerOperation operation){
        
        // User Bhoomi Exception
        Boolean isUserBhoomi = UserInfo.getUserName().contains('userbhoomi');
        Boolean isLoanPortal = UserInfo.getUserName().contains('marlinloansps');
        Boolean isUpdate = operation.name().toLowerCase().contains('update');
        Boolean isInsert = operation.name().toLowerCase().contains('insert');
        Boolean isDelete = operation.name().toLowerCase().contains('delete');

        
        //Insert and update
        if(!isDelete){
        Set<String> setAccountId = new Set<String>();

        for(AccountContactRelation objACR : lstAcr){
            if(isInsert && objACR.Roles != null && objACR.Roles.containsIgnoreCase('Primary contact')){
                setAccountId.add(objACR.accountId);
            }else if(!isInsert){
                if(!(mapOldACR.get(objACR.Id).Roles != null && mapOldACR.get(objACR.Id).Roles.containsIgnoreCase('Primary contact') &&
                     (objACR.Roles != null && objACR.Roles.containsIgnoreCase('Primary contact')))){
                         setAccountId.add(objACR.accountId);
                     }
            }
        }
        
        System.debug('setAccountId---'+setAccountId);
        Map<String, Integer> newAccountWithPrimartContact = new Map<String, Integer>();
        for(Account objAcc : [Select Id, (select Id from AccountContactRelations  where Roles INCLUDES('Primary contact')) from Account where Id in : setAccountId ]){
            newAccountWithPrimartContact.put(objAcc.id, objAcc.AccountContactRelations.size());
        }
        
        for(AccountContactRelation objACR : lstAcr){
            if(objACR.accountId != null && newAccountWithPrimartContact.containskey(objACR.accountId)){
                
                // If we're inserting a new ACR, we want to check if the size is >= 3
                // If we're updating a record which has > 3 but we're going to = 3, then do not run this validation
                
                System.debug('operation: ' + operation.name());
                if (!isUserBhoomi && !isLoanPortal) {
                    if (isInsert) {
                        if(newAccountWithPrimartContact.get(objACR.accountId) >= 3){
                            objACR.addError('Can not add more than 3 Primary Contacts');
                        }
                    } else if (isUpdate) {
                        if(newAccountWithPrimartContact.get(objACR.accountId) > 3){
                            objACR.addError('Can not add more than 3 Primary Contacts');
                        }
                    }
                }
            }
        }
    }
//Eautomate permission
        Set<String> setEautomateContacts= new Set<String>();
        Set<String> updateSetEautomateContacts= new Set<String>();
        for(AccountContactRelation objACR : lstAcr){

            if(isInsert){
                if(objACR.Roles != null && objACR.Roles.containsIgnoreCase('Eauto auto posting'))
                {
                    setEautomateContacts.add(objACR.ContactId);
                }
            }

            if(isUpdate){
                
                if(objACR.Roles != null && objACR.Roles.containsIgnoreCase('Eauto auto posting'))
                {
                    setEautomateContacts.add(objACR.ContactId);
                }


                if( objACR.Roles == null ||  mapOldACR.get(objACR.Id).Roles != null && (!objACR.Roles.containsIgnoreCase('Eauto auto posting' )) && mapOldACR.get(objACR.Id).Roles.containsIgnoreCase('Eauto auto posting')) //We are removing but we need to check if there is another ACR giving permission
                {
                    updateSetEautomateContacts.add(objACR.ContactId);
                }
            }
        }
        if(isDelete){
            for(String  objACRId : mapOldACR.keySet()){
                if( mapOldACR.get(objACRId).Roles.containsIgnoreCase('Eauto auto posting')){
                    updateSetEautomateContacts.add(mapOldACR.get(objACRId).ContactId);
                }
            }
        }
        eAutomatePermission(setEautomateContacts, updateSetEautomateContacts);

    }
        //******************************* */
        @future
    public static void eAutomatePermission (Set<String> setEautomateContacts ,  Set<String> updateSetEautomateContacts){

        Set<String> deleteSetEautomateContacts= new Set<String>();

        PermissionSet psEautomate = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Dealer_eAutomate_Access'];


        if(updateSetEautomateContacts.size()>0){
            Map<Id, Integer> AutomateRolesByContact = new Map<Id, integer>();
            List<AccountContactRelation> ACRwithEautomate = [SELECT ID FROM AccountContactRelation WHERE ContactId IN :updateSetEautomateContacts AND Roles INCLUDES('Eauto auto posting')];
            for(AccountContactRelation acr : ACRwithEautomate){
                AutomateRolesByContact.put(acr.ContactId, AutomateRolesByContact.get(acr.ContactId)+1);
            }

            for(String contactId : updateSetEautomateContacts)
            {
                if(AutomateRolesByContact.get(contactId) == null ) deleteSetEautomateContacts.add(contactId);
            }

            if(deleteSetEautomateContacts.size()>0){
                Map<Id, User> usersMapDelete = new Map<Id, User>([SELECT Id, ContactID  FROM USER WHERE ContactID IN :deleteSetEautomateContacts]);

                List<PermissionSetAssignment> deletePermissionAssignments = [SELECT ID FROM PermissionSetAssignment WHERE AssigneeId IN :usersMapDelete.keyset() AND PermissionSetId = :psEautomate.Id];
                delete deletePermissionAssignments;
            }

        }


        if(setEautomateContacts.size()>0){
                   
        List<PermissionSetAssignment> permissionAssignments = new List<PermissionSetAssignment>(); 
        Map<Id, User> usersMap = new Map<Id, User>([SELECT Id, ContactID  FROM USER WHERE ContactID IN :setEautomateContacts]);

        for(Id userId : usersMap.keySet()){
            permissionAssignments.add(new PermissionSetAssignment(
                PermissionSetId = psEautomate.Id,
                AssigneeId = userId
            ));
        }

        insert permissionAssignments;
        }


    }
}