public with sharing class SL_ChecklistTriggerHelper {
  // private static final String CHECKLIST_SHARE_API_NAME = 'TC_Origination__Checklist__Share';

  public static void beforeInsert(List<TC_Origination__Checklist__c> lstNewCheckLst){
    Map<Id, List<TC_Origination__Checklist__c>> mapCheckListOpp = new Map<Id, List<TC_Origination__Checklist__c>>();
    for(TC_Origination__Checklist__c checklist :lstNewCheckLst){
      if(checklist.TC_Origination__Opportunity__c == null){
        CONTINUE;
      }

      if(mapCheckListOpp.containsKey(checklist.TC_Origination__Opportunity__c)){
        mapCheckListOpp.get(checklist.TC_Origination__Opportunity__c).add(checklist);
      }else{
        mapCheckListOpp.put(checklist.TC_Origination__Opportunity__c, new List<TC_Origination__Checklist__c>{checklist});
      }
    }

    if(!mapCheckListOpp.isEmpty()){
      setDealerUser(mapCheckListOpp);
    }
  }

  public static void beforeUpdate(Map<Id, TC_Origination__Checklist__c> mapNewCheckLst, Map<Id, TC_Origination__Checklist__c> mapOldChecklst){
    Map<Id, List<TC_Origination__Checklist__c>> mapCheckListOpp = new Map<Id, List<TC_Origination__Checklist__c>>();
    for(TC_Origination__Checklist__c checklist :mapNewCheckLst.values()){
      TC_Origination__Checklist__c oldChecklst = mapOldChecklst.get(checklist.Id);
      if(checklist.TC_Origination__Opportunity__c == null || checklist.TC_Origination__Opportunity__c == oldChecklst.TC_Origination__Opportunity__c){
        CONTINUE;
      }

      if(mapCheckListOpp.containsKey(checklist.TC_Origination__Opportunity__c)){
        mapCheckListOpp.get(checklist.TC_Origination__Opportunity__c).add(checklist);
      }else{
        mapCheckListOpp.put(checklist.TC_Origination__Opportunity__c, new List<TC_Origination__Checklist__c>{checklist});
      }
    }

    if(!mapCheckListOpp.isEmpty()){
      setDealerUser(mapCheckListOpp);
    }
  }

  public static void afterInsert(Map<Id, TC_Origination__Checklist__c> mapNewCheckLst){
    system.debug('in after Insert of helper::');
    // DP-1616 Misael Romero
    // checkDealerUserSharing(mapNewCheckLst.values(), null, true);
  }

  public static void afterUpdate(Map<Id, TC_Origination__Checklist__c> mapNewCheckLst, Map<Id, TC_Origination__Checklist__c> mapOldChecklst){
    system.debug('in after Update of helper::');
    // DP-1616 Misael Romero
    // checkDealerUserSharing(mapNewCheckLst.values(), mapOldChecklst, false);
  }

  private static void setDealerUser(Map<Id, List<TC_Origination__Checklist__c>> mapCheckListOpp){
    for(Opportunity opp : [SELECT Id, Dealer_User__c FROM Opportunity WHERE Id IN :mapCheckListOpp.keySet() AND Dealer_User__c != null]){
      if(mapCheckListOpp.containsKey(opp.Id)){
        for(TC_Origination__Checklist__c checklist :mapCheckListOpp.get(opp.Id)){
          checklist.Dealer_User__c = opp.Dealer_User__c;
        }
      }
    }
  }

  // private static void checkDealerUserSharing(List<TC_Origination__Checklist__c> lstNewChecklst, Map<Id, TC_Origination__Checklist__c> mapOldChecklst, Boolean isInsert){
  //   Map<Id, Id> mapRecordsToShare = new Map<Id, Id>();
  //   Map<Id, Id> mapRecordsToRemoveSharing = new Map<Id, Id>();
  //   SL_SharingCustomRecord shareRecords = new SL_SharingCustomRecord();
    
  //   for(TC_Origination__Checklist__c chk :lstNewChecklst){
  //     TC_Origination__Checklist__c oldChk = mapOldChecklst?.get(chk.Id);
  //     shareRecords.checkRecordToShareOrRemove(chk, oldChk, isInsert, mapRecordsToShare, mapRecordsToRemoveSharing);
  //   }
      
  //   if(!mapRecordsToShare.isEmpty() || !mapRecordsToRemoveSharing.isEmpty()){
  //     shareRecordToDealer(shareRecords, mapRecordsToShare, mapRecordsToRemoveSharing);
  //   }
  // }

/*
    * @Description: DP-213 - Method to call the apex class to share the records with each Dealer_User__c.
    * History
    * <Date>      <Authors Name>     Description
      08/24/23   Jonathan Munguia   Initial Version.
    */
    // public static void shareRecordToDealer(SL_SharingCustomRecord shareRecords, Map<Id, Id> mapRecordsToShare, Map<Id, Id> mapRecordsToRemoveSharing){
    //   for(TC_Origination__Checklist__Share chShared :[SELECT ParentId, UserOrGroupId, AccessLevel, RowCause FROM TC_Origination__Checklist__Share
    //                                                   WHERE ParentId IN :mapRecordsToShare.keySet() AND UserOrGroupId IN :mapRecordsToShare.values()]){
    //     if(mapRecordsToShare.containsKey(chShared.ParentId)){
    //       Id dealer = mapRecordsToShare.get(chShared.ParentId);
    //       if(chShared.UserOrGroupId == dealer && SL_SharingCustomRecord.rowCauseValues.contains(chShared.RowCause)){
    //         mapRecordsToShare.remove(chShared.ParentId);
    //       }
    //     }
    //   }

    //   String shareAccess = 'Read';
    //   for(Id key: mapRecordsToShare.keySet()){
    //     shareRecords.addRecordToList(CHECKLIST_SHARE_API_NAME, key, mapRecordsToShare.get(key), shareAccess, false, false);
    //   }

    //   for(Id key: mapRecordsToRemoveSharing.keySet()){
    //     shareRecords.addRecordToList(CHECKLIST_SHARE_API_NAME, key, mapRecordsToRemoveSharing.get(key), shareAccess, true, false);
    //   }
    //   system.debug('shareRecords::'+shareRecords);
    //   shareRecords.commitRecords(CHECKLIST_SHARE_API_NAME, false);
    // }
}