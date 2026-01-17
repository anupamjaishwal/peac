/**
 * Created by andrewmayer on 9/7/20.
 *
 * https://marlinbusiness.atlassian.net/browse/SAL-1729
 */

public with sharing class TC_AutoAssignEndUserAndDealerAcc{


    public static void doAction(List <Account> newList, User currentUser) {
        Id DEALER_RT_ID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId();
        Id END_USER_RT_ID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
        
        // SAL-5468 Misael Romero
        Boolean isUserNonProgramAndNonSpecialty = !programOrSpecialtyOrAdmin (currentUser.Profile.Name);

        List <Account> updateList = new List <Account> ();

        //User Informatica
        String SITE_ID = System.Site.getSiteId();
        
        for (Account acc : newList) {
            if (acc.RecordTypeId == END_USER_RT_ID
                    || (acc.RecordTypeId == DEALER_RT_ID && isUserNonProgramAndNonSpecialty)) {
                updateList.add (acc);
            }
            if(SITE_ID <> null ){
                acc.OwnerId = Label.AccountOwnerForPortalUsers;
            }
        }

        if (updateList.isEmpty()) return;

        List <User> endUserDealerOwner = new List <User> ([SELECT Id FROM User WHERE User_Api_Name__c = :Label.TC_OwnerOfEndUserDealerAcc]);
        if (endUserDealerOwner.isEmpty()) return;

        for (Account acc : updateList) {
            acc.OwnerId = endUserDealerOwner[0].Id;
        }

    }

    private static Boolean programOrSpecialtyOrAdmin (String profileName) {
        if (String.isBlank(profileName)) return false;
        return profileName.containsIgnoreCase('oeg')
                || profileName.containsIgnoreCase('program')
                || profileName.containsIgnoreCase('hkf')
                || profileName.containsIgnoreCase('cvg')
                || profileName.containsIgnoreCase('admin')
                || profileName.toLowercase() == 'strategic rep';
    }
}