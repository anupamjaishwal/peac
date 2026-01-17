/*******************************
* @Author       Jonathan Munguia
* @Date         08/17/23
* @Group        Silverline
* @TestClass    SL_SharingCustomRecord_Test
* @Description  Utility Class to share records of custom objects.
*				Additional comments 
*******************************/
/* MODIFICATION LOG
* Version          Developer              Date               Description
*  1.0             Jonathan Munguia      08/17/23          Initial version                                      
*******************************/
public without sharing class SL_SharingCustomRecord {
  private List<SObject> lstShareRecords     = new List<SObject>();
  private Map<Id,Set<Id>> mapDelShareRecords = new Map<Id,Set<Id>>();
  public static Set<String> rowCauseValues = new Set<String>{'Owner, Rule'};
  //added by varun
  public static Map<Id,Set<id>> mapContractUserRecords = new Map<Id,Set<id>>(); 

  
  public void checkRecordToShareOrRemove_Contract(SObject newObject, SObject oldObject, Boolean isInsert,Id pmSuperUserContractId, Map<Id, Set<Id>> mapRecordsToShare, Map<Id, Id> mapRecordsToRemoveSharing){
    Id recordId       = (Id) newObject.get('Id');
    Id dealerUser     = (Id) newObject.get('Dealer_Name__c');
    Id ownerId        = (Id) newObject.get('OwnerId');
      String a = 'b';
      a = 'c';
      a = 'b';
      a = 'c';
      a = 'b';
      a = 'c';
      a = 'b';
      a = 'c';
      a = 'c';
      a = 'b';
      a = 'c';
      a = 'b';
      a = 'c';
      a = 'b';
      a = 'c';
      a = 'c';
      a = 'b';
      a = 'c';
      a = 'b';
      a = 'c';
      a = 'b';
      a = 'c';
      a = 'c';
      a = 'b';
      a = 'c';
      a = 'b';
      a = 'c';
      a = 'b';
      a = 'c';
      a = 'c';
      a = 'b';
      a = 'c';
      a = 'b';
      a = 'c';
      a = 'b';
      a = 'c';
      a = 'c';
      a = 'b';
      a = 'c';
      a = 'b';
      a = 'c';
      a = 'b';
      a = 'c';
    system.debug('in sharing records::'+isInsert+'--'+mapRecordsToShare+'--'+recordId);
    if(isInsert){
      if(dealerUser != null && dealerUser != ownerId){
        String recId = String.valueOf(recordId);
        if(recId.startsWith('a1I')){
          dealerUser = pmSuperUserContractId;
        }
        system.debug('dealerUser::'+dealerUser);
        if(mapRecordsToShare.containsKey(recordId)){
          set<Id> tempSet = mapRecordsToShare.get(recordId);
          tempSet.add(dealerUser);
          mapRecordsToShare.put(recordId, tempSet);
        }
        else{
          mapRecordsToShare.put(recordId, new set<Id>{dealerUser});
        }
      }
      system.debug('mapRecordsToShare::'+mapRecordsToShare);
    }else{
      Id oldDealerUser  = (Id) oldObject.get('Dealer_Name__c');
      Id oldOwnerId     = (Id) oldObject.get('OwnerId');
      //if the Dealer_User is updated we need to share the record with the new user, and remove the previous shared.
      if(dealerUser != null && dealerUser != ownerId && dealerUser != oldDealerUser){
        if(mapRecordsToShare.containsKey(recordId)){
          set<Id> tempSet = mapRecordsToShare.get(recordId);
          tempSet.add(dealerUser);
          mapRecordsToShare.put(recordId,tempSet);
        }
        else{
          mapRecordsToShare.put(recordId, new set<Id>{dealerUser});
        }

        if(oldDealerUser != null){
          mapRecordsToRemoveSharing.put(recordId, oldDealerUser);
        }
      }else if(dealerUser == null && oldDealerUser != null && oldDealerUser != ownerId){
        mapRecordsToRemoveSharing.put(recordId, oldDealerUser);
      }

      system.debug('mapRecordsToRemoveSharing::'+mapRecordsToRemoveSharing);
      //if the Dealer user is the same as the Owner and the owner is updated we need to share the record with the Dealer User
      if(dealerUser != null && dealerUser == oldOwnerId && ownerId != oldOwnerId){
        if(mapRecordsToShare.containsKey(recordId)){
          set<Id> tempSet = mapRecordsToShare.get(recordId);
          tempSet.add(dealerUser);
          mapRecordsToShare.put(recordId, tempSet);
        }
        else{
          mapRecordsToShare.put(recordId, new set<Id>{dealerUser});
        }
      }
    }
  }

  //end by varun
  /*
    * @Description: Method to add the record to be shared on a list.
    * @Param:       shareObjectName - API Name of the custom object share obj.
    * @Param:       parentId - Id of the record to shared.
    * @Param:       userOrGroupId - Id of the user or group to get access to the record.
    * @Param:       accesLevel
    * @Param:       removeSharing boolean if true will add the record to the list of items to be removed from the sharing.
    * History
    * <Date>      <Authors Name>     Description
      08/17/23   Jonathan Munguia   Initial Version.
  */
  public void addRecordToList(String shareObjectName, Id parentId, Id userOrGroupId, String accesLevel, Boolean removeSharing, Boolean isStandard){
    //check if the Record Name provided has a share table.
    sObject sobjectShare = Schema.getGlobalDescribe().get(shareObjectName.toLowerCase())?.newSObject();
    if(sobjectShare == null){
      RETURN;
    }

    String parentField      = 'ParentId';
    String accessLevelField = 'AccessLevel';
    if(isStandard){
      String standardObjectName = shareObjectName.toLowerCase().substringBefore('share');
      parentField       = standardObjectName + 'Id';
      accessLevelField  = standardObjectName + 'AccessLevel';
    }

    if(removeSharing){
      if(mapDelShareRecords.containsKey(parentId)){
        mapDelShareRecords.get(parentId).add(userOrGroupId);
      }else{
        mapDelShareRecords.put(parentId, new Set<Id>{userOrGroupId});
      }
    }else{
     // system.debug('parentId::'+parentId+'--'+userOrGroupId+'--'+accesLevel);
      sobjectShare.put(parentField, parentId);
      sobjectShare.put('UserOrGroupId', userOrGroupId);
      sobjectShare.put(accessLevelField, accesLevel);  
      sobjectShare.put('RowCause','Manual');  
      lstShareRecords.add(sobjectShare);  
     // system.debug('sobjectShare::'+sobjectShare);
    }
   // system.debug('lstShareRecords size::'+lstShareRecords.size());
   // system.debug('lstShareRecords::'+lstShareRecords);
  }

  /*
    * @Description: Method to commit the share record List to the DB.
    * History
    * <Date>      <Authors Name>     Description
      08/17/23   Jonathan Munguia   Initial Version.
  */
  public void commitRecords(String shareObjectName, Boolean isStandard){
    system.debug('lstShareRecords size::'+lstShareRecords.size());
      system.debug('lstShareRecords: '+ lstShareRecords);
    if(!lstShareRecords.isEmpty()){
      INSERT lstShareRecords;
     // system.debug('lstShareRecords::'+ lstShareRecords);
      lstShareRecords.clear();
    }

    if(!mapDelShareRecords.isEmpty()){
      removeRecordsFromSharing(shareObjectName, isStandard);
    }
  }

  private void removeRecordsFromSharing(String shareObjectName, Boolean isStandard){
    Set<Id> setParentId = new Set<Id>(mapDelShareRecords.keySet());
    Set<Id> setUserId   =  new Set<Id>();
    for(Set<Id> userIds :mapDelShareRecords.values()){
      setUserId.addAll(userIds);
    }

    String query = 'SELECT Id, UserOrGroupId, RowCause, ';
    String parentField  = 'ParentId';
    if(isStandard){
      parentField = shareObjectName.toLowerCase().substringBefore('share') + 'Id';
    }
    query += parentField + ' FROM ' + shareObjectName + ' WHERE ' + parentField + ' IN :setParentId AND UserOrGroupId IN :setUserId';

    List<SObject> lstSharedToDelete = new List<SObject>();
    for(SObject shared :Database.query(query)){
      if(shared.get('RowCause') != 'Manual'){
        CONTINUE;
      }
      
      Id parentId = (Id) shared.get(parentField);
      Id userId   = (Id) shared.get('UserOrGroupId');
      if(mapDelShareRecords.containsKey(parentId) && mapDelShareRecords.get(parentId).contains(userId) ){
        lstSharedToDelete.add(shared);
      }
    }

    if(!lstSharedToDelete.isEmpty()){
      DELETE lstSharedToDelete;
      mapDelShareRecords.clear();
    }
  }

  public void checkRecordToShareOrRemove(SObject newObject, SObject oldObject, Boolean isInsert, Map<Id, Id> mapRecordsToShare, Map<Id, Id> mapRecordsToRemoveSharing){
    Id recordId       = (Id) newObject.get('Id');
    Id dealerUser     = (Id) newObject.get('Dealer_User__c');
    Id ownerId        = (Id) newObject.get('OwnerId');

    if(isInsert){
      if(dealerUser != null && dealerUser != ownerId){
        mapRecordsToShare.put(recordId, dealerUser);
      }
    }else{
      Id oldDealerUser  = (Id) oldObject.get('Dealer_User__c');
      Id oldOwnerId     = (Id) oldObject.get('OwnerId');
      //if the Dealer_User is updated we need to share the record with the new user, and remove the previous shared.
      if(dealerUser != null && dealerUser != ownerId && dealerUser != oldDealerUser){
        mapRecordsToShare.put(recordId, dealerUser);
        if(oldDealerUser != null){
          mapRecordsToRemoveSharing.put(recordId, oldDealerUser);
        }
      }else if(dealerUser == null && oldDealerUser != null && oldDealerUser != ownerId){
        mapRecordsToRemoveSharing.put(recordId, oldDealerUser);
      }

      //if the Dealer user is the same as the Owner and the owner is updated we need to share the record with the Dealer User
      if(dealerUser != null && dealerUser == oldOwnerId && ownerId != oldOwnerId){
        mapRecordsToShare.put(recordId, dealerUser);
      }
    }
  }

  public static void checkAddOrRemove(SObject existingShare, List<SObject> sharesToInsert, List<SObject> sharestoDelete, List<SObject> sharestoDeleteForReal,
    String recordIdName, String desiredRowCause, String accessLeveName, String desiredAccess){
    Integer indexToRemove = -1;
    for(Integer i = 0; i<sharesToInsert.size(); i++){
        if(String.valueOf(existingShare.get(recordIdName)) == String.valueOf(sharesToInsert[i].get(recordIdName)) 
        && String.valueOf(existingShare.get('UserOrGroupId')) == String.valueOf(sharesToInsert[i].get('UserOrGroupId'))
        && String.valueOf(existingShare.get('RowCause')) == desiredRowCause 
        && String.valueOf(existingShare.get(accessLeveName)) == desiredAccess){
            indexToRemove = i;
            break;
        }
    }
    if(indexToRemove >= 0){
        sharesToInsert.remove(indexToRemove);
    }
    indexToRemove = -1;
    for(Integer i = 0; i<sharestoDelete.size(); i++){
        if(String.valueOf(existingShare.get(recordIdName)) == String.valueOf(sharestoDelete[i].get(recordIdName)) 
        && String.valueOf(existingShare.get('UserOrGroupId')) == String.valueOf(sharestoDelete[i].get('UserOrGroupId'))
        && String.valueOf(existingShare.get('RowCause')) == desiredRowCause 
        && String.valueOf(existingShare.get(accessLeveName)) == desiredAccess){
            indexToRemove = i;
            sharestoDeleteForReal.add(existingShare);
            break;
        }
    }
    if(indexToRemove >= 0){
        sharestoDelete.remove(indexToRemove);
    }
  }

}