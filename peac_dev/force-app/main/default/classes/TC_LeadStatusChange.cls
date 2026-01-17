/**
 * Created by trohweder on 10/5/20.
 */

public with sharing class TC_LeadStatusChange implements TC_TriggerActionI{
    private static Set<Id> idsChanged {
        get {
            if (idsChanged == null) idsChanged = new Set<Id>();
            return idsChanged;
        }
        set;
    }

    private static Map<Id, Profile> profileMap {
        get {
            if (profileMap == null) profileMap = new Map<Id, Profile>([SELECT Id, Name FROM Profile]);
            return profileMap;
        }
        set;
    }

    private static Map<String, Profile> profileMapByName {
        get {
            if (profileMapByName == null) {
                Map<String, Profile> temp = new Map<String, Profile>();
                for (Profile p : profileMap.values()) {
                    temp.put(p.Name, p);
                }
                profileMapByName = temp;
            }
            return profileMapByName;
        }
        set;
    }

    private static final String SDR_PROFILE_NAME = 'SDR';
    private static final String BFA_PROFILE_NAME = 'Express Rep';

    public void doAction(TC_TriggerContext tc) {

        //the below commented out section has been turned into a validation rule

//        if (tc.isBefore() && tc.isInsert()) {
//            Map<Id, Lead> leadNewMap = (Map<Id, Lead>) tc.getNewMap();
//
//            System.debug('Is Insert: ' + leadNewMap);
//            Set<Id>userChangedIds = new Set<Id>();
//
//            for (Id key : leadNewMap.keySet()) {
//                if (leadNewMap.get(key).LastModifiedById != null) {
//                    userChangedIds.add(leadNewMap.get(key).LastModifiedById);
//                }
//            }
//            List<User> users = [SELECT Id, ProfileId FROM User WHERE Id IN :userChangedIds];
//
//            Profile systemAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
//
//            for (Id key : leadNewMap.keySet()) {
//                for (User u : users) {
//                    if (u.Id == leadNewMap.get(key).LastModifiedById && u.ProfileId != systemAdmin.Id) {
//                        if (leadNewMap.get(key).Status == 'Prospecting' ||
//                                leadNewMap.get(key).Status == 'Active Warm Transfer' ||
//                                leadNewMap.get(key).Status == 'Closed - Converted') {
//
//                            leadNewMap.get(key).addError('Can only make status "Unassigned" or "Closed - Lost" unless user is System Administrator.');
//                            break;
//                        }
//                    }
//                }
//
//            }
        if (tc.isBefore() && tc.isUpdate()) {

            Map<Id, Lead> leadNewMap = (Map<Id, Lead>) tc.getNewMap();
            Map<Id, Lead> leadOldMap = (Map<Id, Lead>) tc.getOldMap();

            System.debug('Is Update: ' + leadNewMap + '  ' + leadOldMap);
            
            Profile systemAdmin = profileMapByName.get('System Administrator');
            Profile sdrProfile = profileMapByName.get(SDR_PROFILE_NAME);
            Profile bfaProfile = profileMapByName.get(BFA_PROFILE_NAME);

            for (Id key : leadNewMap.keySet()) {
                if (leadNewMap.get(key).Status != leadOldMap.get(key).Status && !idsChanged.contains(key)){
                    if(UserInfo.getProfileId() != systemAdmin.Id && UserInfo.getProfileId() != sdrProfile.Id && UserInfo.getProfileId() != bfaProfile.Id){
                        System.debug('Error should not trigger if Closed - Lost or Closed - Converted it is: ' + leadNewMap.get(key).Status);
                        if (leadNewMap.get(key).Status != 'Closed - Lost' && leadNewMap.get(key).Status != 'Closed - Converted'){
                            System.debug('Error in lead status...');
                            leadNewMap.get(key).addError('Can only make status "Closed - Lost" or "Closed - Converted" unless user is System Administrator.');
                        }
                    }
                }
            }
            System.debug('********TC_LeadStatusChange.updateLeadStatus');

            try {

                Set<Id> ownerIds = new Set<Id>();
                for (Id key : leadNewMap.keySet()) {
                    ownerIds.add(leadNewMap.get(key).OwnerId);
                    ownerIds.add(leadOldMap.get(key).OwnerId);
                }
                System.debug(ownerIds);

                Map<Id, User> owners = new Map<Id, User>([SELECT Id, ProfileId, IsActive
                                                            FROM User
                                                            WHERE Id IN :ownerIds]);


                for (Id key : leadNewMap.keySet()) {
                    System.debug('Status 1:' + leadNewMap.get(key).Status + ' ' + leadOldMap.get(key).Status);
                    System.debug('fml_LeadClosed: ' + leadNewMap.get(key).fml_LeadClosed__c);
                    System.debug('fml_LeadClosed old:'+(leadOldMap.get(key) != null && leadOldMap.get(key).fml_LeadClosed__c));
                    System.debug('fml_LeadClosed new:'+(leadNewMap.get(key) != null && leadNewMap.get(key).fml_LeadClosed__c));

                    if ((!isClosed(leadOldMap.get(key)) && !isClosed(leadNewMap.get(key)) && String.isBlank(leadNewMap.get(key).Lead_Outcome__c))) {
                        System.debug('Status 2:' + leadNewMap.get(key).Status + ' ' + leadOldMap.get(key).Status);
                        //Updated logic here to specifications of SAL-2551 Jacob Tauer to use profiles instead of teams
                        String newProfileName = owners.containsKey(leadNewMap.get(key).OwnerId) ? profileMap.get(owners.get(leadNewMap.get(key).OwnerId).ProfileId).Name.toUpperCase() : '';
                        String oldProfileName = Trigger.isUpdate && owners.containsKey(leadOldMap.get(key).OwnerId) ? profileMap.get(owners.get(leadOldMap.get(key).OwnerId).ProfileId).Name.toUpperCase() : '';
						// This is updated as per the ticket SAL - 3244
                       /* if (Trigger.isUpdate && newProfileName == BFA_PROFILE_NAME && oldProfileName == SDR_PROFILE_NAME) {
                            leadNewMap.get(key).Status = 'Active Warm Transfer';
                            idsChanged.add(key);

                        } */
                            //else if ((newProfileName == SDR_PROFILE_NAME || newProfileName == BFA_PROFILE_NAME)) {
                            //Added condition as per SAL-2660 since existing leads should not change status
                            //&& String.isEmpty(leadOldMap.get(key).Status)
                            if ((newProfileName == SDR_PROFILE_NAME || newProfileName == BFA_PROFILE_NAME) && (String.isEmpty(leadOldMap.get(key).Status) || leadOldMap.get(key).Status == 'Unassigned')) {
                            leadNewMap.get(key).Status = 'Prospecting';
                            idsChanged.add(key);
                        }


                    }
                    System.debug('Status 3:' + leadNewMap.get(key).Status);
                }
                if (Test.isRunningTest()) idsChanged = null;

            } catch (Exception e) {

                System.debug(e.getMessage());

            }
        }

    }

    private static Boolean isClosed(Lead l) {
        return l != null && (l.IsConverted || (String.isNotBlank(l.Lead_Outcome__c) && l.Lead_Outcome__c.containsIgnoreCase('Closed')) || l.Status == 'Active Warm Transfer');
    }
}