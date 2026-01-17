//SAL-1890
public without sharing class TC_ContactRelatedObjUpdate implements TC_TriggerActionI {

    private Map<Id, Integer> acctIdToEngagementScoreMap {

        get {
            if (this.acctIdToEngagementScoreMap == null) this.acctIdToEngagementScoreMap = new Map<Id, Integer>();
            return this.acctIdToEngagementScoreMap;
        }
        set;
    }

    public void doAction(TC_TriggerContext tc) {
        System.debug('TC_ContactRelatedObjUpdate');
        Map<Id, Contact> contMap = new Map<Id, Contact>();
        Map<Id, List<String>> fieldsChangedById = new Map<Id, List<String>>();
        Integer countMembers = [
            SELECT COUNT()
            FROM GroupMember
            WHERE Group.DeveloperName = 'ValidityVerifyUsers'
            AND UserOrGroupId = :UserInfo.getUserId()
        ];
        for (Contact cont : tc.getNewList() == null ? (List<Contact>) tc.getOldMap().values() : tc.getNewList()) {
            Contact contOld = tc.getOldMap() == null ? null : (Contact)tc.getOldMap().get(cont.Id);
            //SAL-1890
            if (accountScoreNeedsAdjusting(cont, contOld)) acctIdToEngagementScoreMap.put(cont.AccountId, Integer.valueOf(cont.fml_AccountEngagementScore__c));
            // by varun
            Boolean oldReceive = contOld != null? contOld.Receive_All_Notifications__c: false;
            Id oldAccountId = contOld != null? contOld.AccountId: null;// DP-1851 Misael Romero
            if(cont.AccountId !=oldAccountId){
                fieldsChangedById.put(cont.Id, new List<String>{'AccountId'});
            }
            if(cont.Receive_All_Notifications__c <> oldReceive || cont.AccountId !=oldAccountId){
                contMap.put(cont.Id, cont);
            }
            
            // Updated to fire on both insert and update when email is set/changed - by Varun
           // Boolean emailChanged = (contOld == null && cont.Email != null) || (contOld != null && cont.Email != contOld.Email && cont.Email != null) || (cont.Email != null && cont.Final_E_mail_Validity_Result__c == null);
            
            Boolean emailChanged = (contOld == null && cont.Email != null) || (contOld != null && cont.Email != null && cont.Email != contOld.Email);

            Boolean systemChangeWithNull = contOld != null && cont.Email == contOld.Email && cont.Email != null && cont.Final_E_mail_Validity_Result__c == null && (cont.LastModifiedById != contOld.LastModifiedById || cont.LastModifiedDate != contOld.LastModifiedDate);

            Boolean shouldVerifyEmail = emailChanged || (cont.Email != null && cont.Final_E_mail_Validity_Result__c == null) || systemChangeWithNull;
            
            if(tc.isAfter() && (tc.isInsert() || tc.isUpdate()) && shouldVerifyEmail && countMembers > 0) {
                if(!System.isFuture() && !System.isBatch()){// Misael Romero, due to test class errors
                    verifyEmail(cont.Id,cont.Email);
                }
             }
            
            /*if(tc.isAfter() && tc.isInsert() && cont.Email != null && countMembers > 0) {
                verifyEmail(cont.Id,cont.Email);
            }*/
        }
        System.debug(acctIdToEngagementScoreMap);
        //SAL-1890
        if (!acctIdToEngagementScoreMap.isEmpty()) checkForAccountsNeedingScoreUpdates();
        
        //by vrun
        if(!contMap.isEmpty()) checkForUserToUpdate(contMap, fieldsChangedById);
    
        // WCL related
        if(tc.getNewMap() != null && tc.getoldMap() != null) {
            Map<Id,Set<Id>> contactWithOppIdMap = new Map<Id, Set<Id>>();
            for(Guarantor__c gr : [select Id, Contact__c, Opportunity__c from Guarantor__c where Contact__c IN :tc.getNewMap().keySet()]) {
                if(!contactWithOppIdMap.containskey(gr.Contact__c)) {
                    contactWithOppIdMap.put(gr.Contact__c,new Set<Id>{gr.Opportunity__c});
                } else {
                    Set<Id> oppIdSet = contactWithOppIdMap.get(gr.Contact__c);
                    oppIdSet.add(gr.Opportunity__c);
                    contactWithOppIdMap.put(gr.Contact__c,oppIdSet);
                }
            }
            
            FieldChangeTracker.TrackerWrapper trackerDetails = new FieldChangeTracker.TrackerWrapper();
            trackerDetails.newRecordMap = tc.getNewMap();
            trackerDetails.oldRecordMap =  tc.getoldMap();
            trackerDetails.recordIdWithOppIdsMap = contactWithOppIdMap;
            trackerDetails.objectApiName = 'Contact';
            FieldChangeTracker.trackDetails(trackerDetails);
        }
    }
    Void checkForUserToUpdate(Map<Id, Contact> contMap, Map<Id, List<String>> fieldsChangedById){
        List<Contract__c> contractsToUpdate = new List<Contract__c>();
        List<Dealer__c> primDealersToUpd = new List<Dealer__c>();
        List<Dealer__c> primDealersToInsert = new List<Dealer__c>();
        List<Dealer__c> primDealersToDelete = new List<Dealer__c>();
        // List<Opportunity> oppsToUpdate = new List<Opportunity>();
        List<User> updateUSers = new List<User>();
        system.debug('checkForUserToUpdate ' + contMap + ' ' + fieldsChangedById);
        for(User u : [SELECT Id, Receive_Notifications__c, contactId, Contact.AccountId,
            (SELECT Id, Dealer_Name__c, Dealer_User__c FROM DealerUser_Contracts__r), 
            (SELECT Id, Dealer_Account__c, Dealer_User__c FROM OpportunitiesDealerUser__r WHERE Application_Status__c !='Booked' 
            AND Application_Status__c != 'Cancelled' AND StageName != 'Lost') 
        FROM User WHERE contactId IN :contMap.keySet()]){
            if(u.Receive_Notifications__c <>  contMap.get(u.contactId).Receive_All_Notifications__c){
                u.Receive_Notifications__c = contMap.get(u.contactId).Receive_All_Notifications__c;
                updateUSers.add(u);
            }
            List<String> fieldsChanged = fieldsChangedById.get(u.contactId);
            checkChangedDealerAccount(u, contMap.get(u.contactId), fieldsChanged, contractsToUpdate, primDealersToUpd, primDealersToInsert, 
                primDealersToDelete);// DP-1851 Misael Romero
        }
        If(!updateUSers.isEmpty()) update updateUSers;
        if(contractsToUpdate.size() > 0 || primDealersToUpd.size() > 0 || primDealersToInsert.size() > 0){
            System.enqueueJob(new SL_DealerPortalShareOppQ(contractsToUpdate, primDealersToUpd, primDealersToInsert, primDealersToDelete));
        }
    }
    /**
     * @description This function will check for accounts needing a score update
     * @see         SAL-1890
     */
    @TestVisible void checkForAccountsNeedingScoreUpdates() {
        Map<Id, Account> acctsToUpdate = new Map<Id, Account>();

        if (!acctIdToEngagementScoreMap.isEmpty()) {
            //Making an aggregate query for all contacts related to the accounts in need of updating
            for (AggregateResult ar : [SELECT AccountId, MAX(mkto71_Lead_Score__c) score FROM Contact WHERE AccountId IN :acctIdToEngagementScoreMap.keySet() GROUP BY AccountId]) {

                Id acctId = (Id) ar.get('AccountId');
                //MAx value across all contacts on the account
                Integer maxVal = ar.get('score') == null ? 0 : Integer.valueOf(ar.get('score'));
                //The mapped value that's currently set on the account
                Integer mappedVal = acctIdToEngagementScoreMap.get(acctId) == null ? 0 : acctIdToEngagementScoreMap.get(acctId);
                //If the max is not the same (which should be the case), then we will construct a new account to be updated with the new score
                if (mappedVal != maxVal) acctsToUpdate.put(acctId, new Account(Id = acctId, Account_Engagement_Score__c=Math.max(maxVal, mappedVal)));
            }
        }
        //updating the accounts with the new scores
        Database.update(acctsToUpdate.values(),false);
    }

    /**
     * @description     This function will check if the account score needs adjusting
     * @see             SAL-1890
     *
     * @param cont      The triggered record
     * @param contOld   The previous version of the triggered record
     *
     * @return          If the account score needs adjusting
     */
    private Boolean accountScoreNeedsAdjusting(Contact cont, Contact contOld) {
        return cont.mkto71_Lead_Score__c != null && ((cont.fml_AccountEngagementScore__c == null || (cont.fml_AccountEngagementScore__c == 0 && cont.mkto71_Lead_Score__c != 0)) || (contOld != null && contOld.mkto71_Lead_Score__c != cont.mkto71_Lead_Score__c));
    }

    // DP-1851 Misael Romero
    public static void checkChangedDealerAccount(User theUser, Contact userContact, List<String> fieldsChanged, List<Contract__c> contractsToUpdate, 
    List<Dealer__c> primDealersToUpd, List<Dealer__c> primDealersToInsert, List<Dealer__c> primDealersToDelete/*List<Opportunity> oppsToUpdate*/){
        Boolean changedAccountId = fieldsChanged != null && fieldsChanged.contains('AccountId');
        if(userContact != null && userContact.AccountId != null && changedAccountId){
            // List<Contract__c> contracts = this.dealerUserContracts.get(theUser.Id);
            // List<Opportunity> opps = this.dealerUserOpps.get(theUser.Id);
            for(Contract__c relatedContract :theUser.DealerUser_Contracts__r){
                if(relatedContract.Dealer_Name__c != userContact.AccountId){
                    relatedContract.Dealer_Name__c = userContact.AccountId;
                    contractsToUpdate.add(relatedContract);
                }
            }
            Set<Id> oppIdsToUpdate = new Set<Id>();
            for(Opportunity relatedOpp :theUser.OpportunitiesDealerUser__r){
                if(relatedOpp.Dealer_Account__c != userContact.AccountId){
                    oppIdsToUpdate.add(relatedOpp.Id);
                }
            }
            Set<Id> oppIdsExistingDealer = new Set<Id>();
            for(Dealer__c oppDealer :[SELECT Id, Dealer__c, Opportunity__c, Primary_Dealer__c FROM Dealer__c 
                WHERE Opportunity__c IN :oppIdsToUpdate]){
                if(!oppDealer.Primary_Dealer__c && oppDealer.Dealer__c == userContact.AccountId){
                    oppDealer.Primary_Dealer__c = true;
                    primDealersToUpd.add(oppDealer);
                    oppIdsExistingDealer.add(oppDealer.Opportunity__c);
                }
                if(oppDealer.Primary_Dealer__c && oppDealer.Dealer__c != userContact.AccountId){
                    primDealersToDelete.add(oppDealer);
                }
            }
            for(Id oppId :oppIdsToUpdate){
                if(!oppIdsExistingDealer.contains(oppId)){
                    Dealer__c primaryDealer = new Dealer__c(Dealer__c = userContact.AccountId, 
                        Opportunity__c = oppId, Primary_Dealer__c = true);
                    primDealersToInsert.add(primaryDealer);
                }
            }
        }
    }

    @future(callout=true)
    public static void verifyEmail(string conId, string email) {
        List <BriteVerifyResponse> responses =  runBriteVerifyCheck (new Set <String> {email});
        if (!responses.isEmpty ()){
            Contact con = new Contact();
            con.Id = conId;
            con.Validity_Verify__Checked__c = true;
            con.Validity_Verify__Status__c = responses[0].status;
            con.Validity_Verify__Timestamp__c = Datetime.now ();
            update con;
        }
    }
    
     public static List<BriteVerifyResponse> runBriteVerifyCheck (Set <String> emails) {
        
        List <BriteVerifyResponse> responses = new List <BriteVerifyResponse> ();
        
        Set <String> errorMessages = new Set <String> ();
        for (String email : emails) {
            BriteVerifyResponse resp = BriteVerifyAPI.verifyEmail (email);
            responses.add (resp);
           
        }return responses;
    }
    
}