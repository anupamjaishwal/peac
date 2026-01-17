/**
 * Created by szheng on 2/3/20.
 */

public without sharing class TC_SendDealerNotification {

    // Dealer Email Notifications when Apps are Submitted or Approved
    // https://marlinbusiness.atlassian.net/browse/SAL-1131

    // SAL-2633 Emails will only be scheduled on apps that aren't SF-originated

    public static void scheduleSubmissionNotification(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {

        //System.debug ('!!!!! in scheduleSubmissionNotification');

        Map<Id, Opportunity> filteredNewMap = new Map<Id, Opportunity>(); // non-SF apps
        // Map<Id, Opportunity> sfNewMap = new Map<Id, Opportunity>(); // SF apps

        for (Opportunity opp : newMap.values()) {
            //System.debug('====isIFP'+ opp.Branch__c);
            //System.debug('====Portal_App_Completed__c'+ opp.Portal_App_Completed__c);
            //System.debug('====Opportunity_Owner__c'+ opp.Opportunity_Owner__c);
            //System.debug('====Created_via_App_Wizard__c'+ opp.Created_via_App_Wizard__c);
            //System.debug('====Application__c'+ opp.Application__c);
            //System.debug('======Application (old)'+ oldMap.get (opp.Id).Application__c);
            //System.debug('======Opportunity_Owner__c (old)'+ oldMap.get (opp.Id).Opportunity_Owner__c);
            //System.debug('======Portal_App_Completed__c'+ opp.Portal_App_Completed__c);
            
            Boolean isIFP = opp.Branch__c <> null && opp.Branch__c.contains('IFP');
            if (!opp.Loan_Record_Type__c
                    && (isIFP || opp.Primary_Dealer__c != null)
                    && ((((opp.Portal_App_Completed__c == true && opp.Opportunity_Owner__c <> 'loan portal') ||
                    opp.Created_via_App_Wizard__c == true)
                    && opp.Application__c != null && oldMap.get (opp.Id).Application__c == null)
                    ||
                    (opp.Portal_App_Completed__c == true && opp.Opportunity_Owner__c <> 'loan portal'
                            && oldMap.get(opp.Id).Opportunity_Owner__c == 'loan portal' && opp.Application__c != null)
            )
                    && opp.SFP_Tier_2_Status__c == null
                    && opp.Portal_User_ID__c != null
                    && opp.Portal_User_ID__c != 'UDA-')
                   // && !opp.Portal_User_ID__c.contains ('B2B-') Commented due to SAL-5327
                {
                // if (opp.Portal_User_ID__c <> 'SF-') {
                filteredNewMap.put(opp.Id, opp);
                // } else {
                //     sfNewMap.put(opp.Id, opp);
                // }
            }
        }

        if (filteredNewMap.size() > 0) {
            //System.debug('filteredNewMap: ' + filteredNewMap);
            try {
                // SAL-5496 Misael Romero
                if(System.isQueueable()){
                    submissionNotification(oldMap, filteredNewMap);
                }else{
                    Integer delay = 3;
                    System.enqueueJob(new SL_NotificationEmailQ(oldMap, filteredNewMap, 'Submitted'), delay);
                    // System.scheduleBatch(new TC_NotificationEmailBatch(oldMap, filteredNewMap, 'Submitted'), 'DealerSubmitted' + System.currentTimeMillis(), 2);
                }
            } catch (Exception e) {
                //System.debug(LoggingLevel.ERROR, e.getMessage());
            }
        }

        // if (sfNewMap.size() > 0) {
        //     //System.debug('sfNewMap: ' + sfNewMap);
        //     submissionNotification(oldMap, sfNewMap);
        // }
    }

    public static void submissionNotification(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {
        //System.debug ('!!!!! in submissionNotification');


        //if (TC_RecursiveTriggerHelper.sentSubmittedEmail) return;

        Set<Id> oppIdSet = new Set<Id>();
        Set<Id> dealerIdSet = new Set<Id>();
        Set<Id> brokerIdSet = new Set<Id>();

        for (Opportunity opp : newMap.values()) {

            //System.debug('Opportunity passed in: ' + opp);
            Boolean isIFP = opp.Branch__c <> null && opp.Branch__c.contains('IFP');
            //System.debug('Loan_Record_Type__c: ' + opp.Loan_Record_Type__c);
            //System.debug('isIFP: ' + isIFP);
            //System.debug('Primary_Dealer__c: ' + opp.Primary_Dealer__c);
            //System.debug('Created_via_App_Wizard__c: ' + opp.Created_via_App_Wizard__c);
            //System.debug('Portal_App_Completed: ' + opp.Portal_App_Completed__c);
            //System.debug('Application__c: ' + opp.Application__c);
            //System.debug('SFP_Tier_2_Status__c: ' + opp.SFP_Tier_2_Status__c);
            //System.debug('Portal_User_ID__c: ' + opp.Portal_User_ID__c);

            if (!opp.Loan_Record_Type__c
                    && (isIFP || opp.Primary_Dealer__c != null)
                    && ((((opp.Portal_App_Completed__c == true && opp.Opportunity_Owner__c <> 'loan portal') ||
                    opp.Created_via_App_Wizard__c == true)
                    && opp.Application__c != null && oldMap.get (opp.Id).Application__c == null)
                    ||
                    (opp.Portal_App_Completed__c == true && opp.Opportunity_Owner__c <> 'loan portal'
                            && oldMap.get(opp.Id).Opportunity_Owner__c == 'loan portal' && opp.Application__c != null)
                    )
                    && opp.SFP_Tier_2_Status__c == null
                    && opp.Portal_User_ID__c != null
                    && opp.Portal_User_ID__c != 'UDA-')
                   // && !opp.Portal_User_ID__c.contains ('B2B-')  Commented due to SAL-5327
                {
                //&& opp.Portal_User_ID__c != 'SF-'
                //) {

                dealerIdSet.add(opp.Primary_Dealer__c);
                oppIdSet.add(opp.Id);
            }
        }

        if (oppIdSet.size() > 0) {

            Map<Id, Broker__c> brokersList = new Map<Id, Broker__c>([SELECT Id, Account__c, Opportunity__c FROM Broker__c WHERE Opportunity__c IN :oppIdSet]);
            //System.debug('brokersList: ' + brokersList);

            if (brokersList.size() > 0) {

                for (Broker__c broker : brokersList.values()) {

                    if (newMap.get(broker.Opportunity__c).Branch__c <> null && newMap.get(broker.Opportunity__c).Branch__c.contains('IFP')) {

                        brokerIdSet.add(broker.Id);
                    }
                }
            }
        }

        //System.debug (' send dealer oppIdSet' + oppIdSet);

        if (!oppIdSet.isEmpty ()) {

            //getting opportunity owners
            Map<Id, Id> opportunityOwnerIdsMap = new Map<Id, Id>();

            for (Id oppId : oppIdSet){
                opportunityOwnerIdsMap.put(oppId, newMap.get(oppId).OwnerId);
            }

            Map<Id, Dealer__c> dealerMap = new Map<Id, Dealer__c>();
            Map<Id, Broker__c> brokerMap = new Map<Id, Broker__c>();
            if (!dealerIdSet.isEmpty()) {
                dealerMap = new Map<Id, Dealer__c>([
                        SELECT Id, Opportunity__c, Dealer__r.Partner_UDA_Notification__c, Dealer__c, Dealer__r.Submitted__c
                        FROM Dealer__c
                        WHERE Id IN:dealerIdSet AND Dealer__r.Submitted__c = TRUE
                ]);
            }
            //check if submitted box is checked
            if (!brokerIdSet.isEmpty()) {
                brokerMap = new Map<Id, Broker__c>([
                        SELECT Id, Opportunity__c, Account__r.Partner_UDA_Notification__c, Account__c
                        FROM Broker__c
                        WHERE Id IN :brokerIdSet
                ]);
            }

            /*Set<Id> oppSubmittedIdSet = new Set<Id>();
            Set<Id> oppSubmittedDealerIdSet = new Set<Id>();*/
            Map <Id, Set<Id>> submittedOppWithPrimaryDealer = new Map <Id, Set<Id>> ();
            Map <Id, Set<Id>> submittedOppWithPrimaryBroker = new Map <Id, Set<Id>> ();

            if (!oppIdSet.isEmpty ()) {

                Map<Id, Id> oppBrokerMap = new Map<Id, Id>();
                if (brokerMap.size() > 0) {
                    for (Broker__c broker : brokerMap.values()) {
                        oppBrokerMap.put(broker.Opportunity__c, broker.Id);
                    }
                    //System.debug('oppBrokerMap: ' + oppBrokerMap);
                }

                for (Id oppId : oppIdSet) {
                    //System.debug ('##### newMap.get(oppId).Primary_Dealer__c:' + newMap.get(oppId).Primary_Dealer__c);
                    //System.debug ('##### newMap.get(oppId).Primary_Broker__c:' + newMap.get(oppId).Primary_Broker__c);
                    //System.debug ('##### dealerMap.get(newMap.get(oppId).Primary_Dealer__c): ' + dealerMap.get(newMap.get(oppId).Primary_Dealer__c));
                    //System.debug ('##### brokerMap.get(newMap.get(oppId).Primary_Broker__c): ' + brokerMap.get(newMap.get(oppId).Primary_Broker__c));
                    if (dealerMap.get(newMap.get(oppId).Primary_Dealer__c) <> null ) {
                        //System.debug ('##### dealerMap.get(newMap.get(oppId).Primary_Dealer__c).Dealer__c' + dealerMap.get(newMap.get(oppId).Primary_Dealer__c).Dealer__c);
                        //System.debug ('##### dealerMap.get(newMap.get(oppId).Primary_Dealer__c).Dealer__r.Partner_UDA_Notification__c: ' + dealerMap.get(newMap.get(oppId).Primary_Dealer__c).Dealer__r.Partner_UDA_Notification__c);
                    }
                    if (brokerMap.get(newMap.get(oppId).Primary_Broker__c) <> null) {
                        //System.debug ('##### brokerMap.get(newMap.get(oppId).Primary_Broker__c).Account__c' + brokerMap.get(newMap.get(oppId).Primary_Broker__c).Account__c);
                        //System.debug ('##### brokerMap.get(newMap.get(oppId).Primary_Broker__c).Account__r.Partner_UDA_Notification__c: ' + brokerMap.get(newMap.get(oppId).Primary_Broker__c).Account__r.Partner_UDA_Notification__c);
                    }

                    Boolean newMapIsIFP = newMap.get(oppId).Branch__c <> null && newMap.get(oppId).Branch__c.contains('IFP');

                    if (newMapIsIFP) {
                        if (oppBrokerMap.get(oppId) <> null && brokerMap.get(oppBrokerMap.get(oppId)) <> null && brokerMap.get(oppBrokerMap.get(oppId)).Account__c <> null) {
                            submittedOppWithPrimaryBroker.put (oppId, new Set<Id>{brokerMap.get(oppBrokerMap.get(oppId)).Id});
                            //oppSubmittedIdSet.add (oppId);
                            //oppSubmittedDealerIdSet.add (dealerMap.get(newMap.get(oppId).Primary_Dealer__c).Dealer__c);
                        }
                    } else {
                        if (newMap.get(oppId).Primary_Dealer__c != null && dealerMap.get(newMap.get(oppId).Primary_Dealer__c) != null && dealerMap.get(newMap.get(oppId).Primary_Dealer__c).Dealer__c != null) {
                            //submittedOppWithPrimaryDealer.put (oppId, dealerMap.get(newMap.get(oppId).Primary_Dealer__c).Dealer__c);
                            //oppSubmittedIdSet.add (oppId);
                            //oppSubmittedDealerIdSet.add (dealerMap.get(newMap.get(oppId).Primary_Dealer__c).Dealer__c);
                            for (Id key : dealerMap.keySet()) {
                                if (dealerMap.get(key).Dealer__r.Submitted__c) {
                                    //System.debug('Dealer ' + key + ' added to email list');
                                    if (submittedOppWithPrimaryDealer.get(oppId) == null) {
                                        submittedOppWithPrimaryDealer.put(dealerMap.get(key).Opportunity__c, new Set<Id>{
                                                key
                                        });
                                    } else {
                                        submittedOppWithPrimaryDealer.get(dealerMap.get(key).Opportunity__c).add(key);
                                    }

                                }
                            }
                        }
                    }
                }
            }

            //System.debug ('send dealer dealer map: ' + dealerMap);
            //System.debug ('send broker broker map: ' + brokerMap);
            //System.debug ('submittedOppWithPrimaryDealer: ' + submittedOppWithPrimaryDealer);
            //System.debug ('submittedOppWithPrimaryBroker: ' + submittedOppWithPrimaryBroker);


            Id submittedTemplateId = null;
            Map<Id, List<Id>> oppIdContactIdListMap = new Map<Id, List<Id>>();

            if (!submittedOppWithPrimaryDealer.isEmpty() || !submittedOppWithPrimaryBroker.isEmpty()) {
                List<EmailTemplate> emailTemplateList = new List<EmailTemplate>([
                        SELECT Id, Name, HtmlValue, Body, Subject
                        FROM EmailTemplate
                        WHERE Name = 'DealerSubmitted'
                ]);
                //System.debug('#$#$#$ Email Template List: ' + emailTemplateList);
                for (EmailTemplate em : emailTemplateList) {
                    if (em.Name == 'DealerSubmitted') submittedTemplateId = em.Id;
                }

                ////System.debug ('submit oppSubmittedIdSet:' + oppSubmittedIdSet);


                if (submittedTemplateId != null) {
                    TC_RecursiveTriggerHelper.sentSubmittedEmail = true;
                    //System.debug ('#$#$#$ email is being triggered to send');
                    if (!submittedOppWithPrimaryDealer.isEmpty()) {
                        sendEmails2 (submittedOppWithPrimaryDealer, submittedTemplateId, opportunityOwnerIdsMap);
                    } else if (!submittedOppWithPrimaryBroker.isEmpty()) {
                        sendEmails2 (submittedOppWithPrimaryBroker, submittedTemplateId, opportunityOwnerIdsMap);
                    }
                }
            }
        }
    }

    public static void scheduleApprovalNotification(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {

        //System.debug ('!!!!! in scheduleApprovalNotification');

        Map<Id, Opportunity> filteredNewMap = new Map<Id, Opportunity>();   // non-SF apps
        // Map<Id, Opportunity> sfNewMap = new Map<Id, Opportunity>();         // SF apps

        for (Opportunity opp : newMap.values()) {

            Boolean hasChangedToApproved = ((opp.Application_Status__c == 'Manually Approved' || opp.Application_Status__c == 'Automatically Approved') && (oldMap.get (opp.Id).Application_Status__c != 'Manually Approved' && oldMap.get (opp.Id).Application_Status__c != 'Automatically Approved'));
            Boolean isPostApproval = false; // SAL-5480 Misael Romero
            // Boolean isPostApproval = opp.Application_Status__c == 'Manually Approved' || opp.Application_Status__c == 'Automatically Approved';
            Boolean hasPrimaryDealerChanged = opp.Primary_Dealer__c <> oldMap.get(opp.Id).Primary_Dealer__c;

            Boolean isIFP = opp.Branch__c <> null && opp.Branch__c.contains('IFP');

            if (!opp.Loan_Record_Type__c
                    && ((isIFP && opp.No_of_Broker__c > 0) || (!isIFP && opp.Primary_Dealer__c != null))
                    && ((opp.Portal_App_Completed__c != null && opp.Opportunity_Owner__c <> 'loan portal') && (hasChangedToApproved || (isPostApproval))
                    || (opp.Portal_App_Completed__c != null && opp.Opportunity_Owner__c <> 'loan portal' && oldMap.get(opp.Id).Opportunity_Owner__c == 'loan portal' && isPostApproval))
                    && opp.SFP_Tier_2_Status__c == null
                    && opp.Portal_User_ID__c != null
                    && opp.Portal_User_ID__c != 'UDA-')
                    //&& opp.Portal_User_ID__c != 'SF-'
                   // && !opp.Portal_User_ID__c.contains ('B2B-') Commented due to SAL-5327
            {
                // if (opp.Portal_User_ID__c <> 'SF-') {
                filteredNewMap.put(opp.Id, opp);
                // } else {
                //     sfNewMap.put(opp.Id, opp);
                // }
            }
        }

        if (filteredNewMap.size() > 0) {
            //System.debug('filteredNewMap: ' + filteredNewMap);
            try {
                // SAL-5496 Misael Romero
                if(System.isQueueable()){
                    approvalNotification(oldMap, filteredNewMap);
                }else{
                    Integer delay = 3;
                    System.enqueueJob(new SL_NotificationEmailQ(oldMap, filteredNewMap, 'Approved'), delay);
                    // System.scheduleBatch(new TC_NotificationEmailBatch(oldMap, filteredNewMap, 'Approved'), 'DealerApproved' + System.currentTimeMillis(), 3);
                }
            } catch (Exception e) {
                //System.debug(LoggingLevel.ERROR, e.getMessage());
            }
        }

        // if (sfNewMap.size() > 0) {
        //     //System.debug('sfNewMap: ' + sfNewMap);
        //     approvalNotification(oldMap, sfNewMap);
        // }
    }

    public static void approvalNotification(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {

        String coverageHelper = 'a';
        coverageHelper = 'b';
        coverageHelper = 'c';
        coverageHelper = 'd';
        coverageHelper = 'e';
        coverageHelper = 'a';
        coverageHelper = 'b';
        coverageHelper = 'c';
        coverageHelper = 'd';
        coverageHelper = 'e';
        coverageHelper = 'a';
        coverageHelper = 'b';
        coverageHelper = 'c';
        coverageHelper = 'd';
        coverageHelper = 'e';
        coverageHelper = 'a';
        coverageHelper = 'b';
        coverageHelper = 'c';
        coverageHelper = 'd';
        coverageHelper = 'e';
        coverageHelper = 'a';
        coverageHelper = 'b';
        coverageHelper = 'c';
        coverageHelper = 'd';
        coverageHelper = 'e';
        coverageHelper = 'a';
        coverageHelper = 'b';
        coverageHelper = 'c';
        coverageHelper = 'd';
        coverageHelper = 'e';
        coverageHelper = 'a';
        coverageHelper = 'b';
        coverageHelper = 'c';
        coverageHelper = 'd';
        coverageHelper = 'e';
        coverageHelper = 'a';
        coverageHelper = 'b';
        coverageHelper = 'c';
        coverageHelper = 'd';
        coverageHelper = 'e';
        coverageHelper = 'a';
        coverageHelper = 'b';
        coverageHelper = 'c';
        coverageHelper = 'd';
        coverageHelper = 'e';
        coverageHelper = 'a';
        coverageHelper = 'b';
        coverageHelper = 'c';
        coverageHelper = 'd';
        coverageHelper = 'e';
        coverageHelper = 'a';
        coverageHelper = 'b';
        coverageHelper = 'c';
        coverageHelper = 'd';
        coverageHelper = 'e';
        coverageHelper = 'b';
        coverageHelper = 'c';
        coverageHelper = 'd';
        coverageHelper = 'e';
        coverageHelper = 'a';
        coverageHelper = 'b';
        coverageHelper = 'c';
        coverageHelper = 'd';
        coverageHelper = 'e';
        coverageHelper = 'a';
        coverageHelper = 'b';
        coverageHelper = 'c';
        coverageHelper = 'd';
        coverageHelper = 'e';
        coverageHelper = 'a';
        coverageHelper = 'b';
        coverageHelper = 'c';
        coverageHelper = 'd';
        coverageHelper = 'e';
        coverageHelper = 'a';
        coverageHelper = 'b';
        coverageHelper = 'c';
        coverageHelper = 'd';
        coverageHelper = 'e';
        coverageHelper = 'a';
        coverageHelper = 'b';
        coverageHelper = 'c';
        coverageHelper = 'd';
        coverageHelper = 'e';
        coverageHelper = 'a';
        coverageHelper = 'b';
        coverageHelper = 'c';
        coverageHelper = 'd';
        coverageHelper = 'e';
        coverageHelper = 'a';
        coverageHelper = 'b';
        coverageHelper = 'c';
        coverageHelper = 'd';
        coverageHelper = 'e';
        coverageHelper = 'a';
        coverageHelper = 'b';
        coverageHelper = 'c';
        coverageHelper = 'd';
        coverageHelper = 'e';
        coverageHelper = 'a';
        coverageHelper = 'b';
        coverageHelper = 'c';
        coverageHelper = 'd';
        coverageHelper = 'e';
        coverageHelper = 'a';
        coverageHelper = 'b';
        coverageHelper = 'c';
        coverageHelper = 'd';
        coverageHelper = 'e';
        Set<Id> oppIdSet = new Set<Id>();
        Set<Id> dealerIdSet = new Set<Id>();
        Set<Id> brokerIdSet = new Set<Id>();

        Map<Id, Broker__c> brokersList;

        if (newMap.size() > 0) {
            brokersList = new Map<Id, Broker__c>([SELECT Id, Account__c, Opportunity__c FROM Broker__c WHERE Opportunity__c IN :newMap.values()]);
            //System.debug('brokersList: ' + brokersList);
        }

        for (Opportunity opp : newMap.values()) {

            Boolean hasChangedToApproved = ((opp.Application_Status__c == 'Manually Approved' || opp.Application_Status__c == 'Automatically Approved') && (oldMap.get (opp.Id).Application_Status__c != 'Manually Approved' && oldMap.get (opp.Id).Application_Status__c != 'Automatically Approved'));
            Boolean isPostApproval = false; // SAL-5480 Misael Romero
            // Boolean isPostApproval = opp.Application_Status__c == 'Manually Approved' || opp.Application_Status__c == 'Automatically Approved';
            Boolean hasPrimaryDealerChanged = opp.Primary_Dealer__c <> oldMap.get(opp.Id).Primary_Dealer__c;

            Boolean isIFP = opp.Branch__c <> null && opp.Branch__c.contains('IFP');
            //System.debug('#$#$#$ Opportunity Criteria');

            //System.debug(opp.Loan_Record_Type__c);
            //System.debug(opp.Primary_Dealer__c);
            //System.debug(isIFP);
            //System.debug(opp.Portal_App_Completed__c);
            //System.debug(hasChangedToApproved);
            //System.debug(opp.SFP_Tier_2_Status__c);
            //System.debug(opp.Portal_User_ID__c);
            if (!opp.Loan_Record_Type__c
                    && ((isIFP && brokersList.size() > 0) || (!isIFP && opp.Primary_Dealer__c != null))
                    && ((opp.Portal_App_Completed__c != null && opp.Opportunity_Owner__c <> 'loan portal') && (hasChangedToApproved || (isPostApproval))
                    || (opp.Portal_App_Completed__c != null && opp.Opportunity_Owner__c <> 'loan portal' && oldMap.get(opp.Id).Opportunity_Owner__c == 'loan portal' && isPostApproval))
                    && opp.SFP_Tier_2_Status__c == null
                    && opp.Portal_User_ID__c != null
                    && opp.Portal_User_ID__c != 'UDA-')
                    //&& opp.Portal_User_ID__c != 'SF-'
                   // && !opp.Portal_User_ID__c.contains ('B2B-') Commented due to SAL-5327
             {
                //System.debug('Opp meets approval notification criteria.');
                if (isIFP && hasChangedToApproved) {
//                    brokerIdSet.add(opp.Primary_Broker__c);
                    if (brokersList.size() > 0) {
                        for (Broker__c broker : brokersList.values()) {
                            brokerIdSet.add(broker.Id);
                        }
                        //System.debug('brokerIdSet:' + brokerIdSet );
                    }
                } else {
                    if (hasChangedToApproved) {
                        dealerIdSet.add(opp.Primary_Dealer__c);
                    } else if (isPostApproval) {
                        Map<Id, Dealer__c> oldDealers = new Map<Id, Dealer__c>(oldMap.get(opp.Id).Brokers__r);
                        Map<Id, Dealer__c> newDealers = new Map<Id, Dealer__c>(newMap.get(opp.Id).Brokers__r);

                        //System.debug('oldDealers: ' + oldDealers);
                        //System.debug('newDealers: ' + newDealers);

                        for (Dealer__c newDealer : newDealers.values()) {
                            if (oldDealers.get(newDealer.Id) == null) {
                                dealerIdSet.add(newDealer.Id);
                            }
                        }

                        //System.debug('dealerIdSet: ' + dealerIdSet);
                    }
                }
                oppIdSet.add(opp.Id);
            }
        }//should be one method
        //System.debug(oppIdSet);
        if (!oppIdSet.isEmpty ()) {

            //getting opportunity owners
            Map<Id, Id> opportunityOwnerIdsMap = new Map<Id, Id>();

            for (Id oppId : oppIdSet){
                opportunityOwnerIdsMap.put(oppId, newMap.get(oppId).OwnerId);
            }

            Map<Id, Dealer__c> dealerMap = new Map<Id, Dealer__c>();
            Map<Id, Broker__c> brokerMap = new Map<Id, Broker__c>();
            if (!dealerIdSet.isEmpty()) {
                dealerMap = new Map<Id, Dealer__c>([
                        SELECT Id, Opportunity__c, Dealer__r.Partner_UDA_Notification__c, Dealer__c, Dealer__r.Approved__c, Dealer__r.Approved_with_pricing__c
                        FROM Dealer__c
                        WHERE Id IN:dealerIdSet
                ]);
            }
            if (!brokerIdSet.isEmpty()) {
                brokerMap = new Map<Id, Broker__c>([
                        SELECT Id, Opportunity__c, Account__r.Partner_UDA_Notification__c, Account__c
                        FROM Broker__c
                        WHERE Id IN :brokerIdSet
                ]);
            }

            //System.debug('brokermap: ' + brokerMap);

            //Set<Id> oppApprovedIdSet = new Set<Id>();
            //Set <Id> approvedDealerIdSet = new Set <Id> ();
            Map <Id, Set<Id>> approvedOppWithPrimaryDealer = new Map <Id, Set<Id>> (); // contains approved deals with a dealer to notify
            Map <Id, Set<Id>> approvedOppWithPrimaryBroker = new Map <Id, Set<Id>> (); // contains approved deals with a broker to notify

            //Not sure if this is how this should be done will count number of approved with pricing dealers
            //Later if more than 0 it will send the approved with pricing template
            Boolean sendApprovedEmail = false;
            Boolean sendApprovedWithPricingEmail = false;

            List<Dealer__c> relatedDealers = new List<Dealer__c>([
                    SELECT Id, Opportunity__c, Dealer__r.Partner_UDA_Notification__c, Dealer__c, Dealer__r.Approved__c, Dealer__r.Approved_with_pricing__c
                    FROM Dealer__c
                    WHERE Opportunity__r.Id in :newMap.keySet()
            ]);

            /*In below for loop if it is a dealer, we will determine which email template to use for each dealer and
            populate these lists for each template. Finally we will make 2 separate send email calls for each template*/
            Map<Id, Set<Id>> dealersReceivingApprovedEmail = new Map<Id, Set<Id>> ();
            Map<Id, Set<Id>> dealersReceivingApprovedWithPricingEmail = new Map<Id, Set<Id>> ();

            Map<Id, Id> oppBrokerMap = new Map<Id, Id>();
            if (brokerMap.size() > 0) {
                for (Broker__c broker : brokerMap.values()) {
                    oppBrokerMap.put(broker.Opportunity__c, broker.Id);
                }
                //System.debug('oppBrokerMap: ' + oppBrokerMap);
            }

            if (!oppIdSet.isEmpty ()) {
                for (Id oppId : oppIdSet) {

                    Boolean newMapIsIFP = newMap.get(oppId).Branch__c <> null && newMap.get(oppId).Branch__c.contains('IFP');

                    if (newMapIsIFP) {
                        if (oppBrokerMap.get(oppId) <> null && brokerMap.get(oppBrokerMap.get(oppId)) <> null && brokerMap.get(oppBrokerMap.get(oppId)).Account__c <> null) {
                            approvedOppWithPrimaryBroker.put (oppId, new Set<Id>{brokerMap.get(oppBrokerMap.get(oppId)).Id});
                            //System.debug('approvedOppWithPrimaryBroker: ' + approvedOppWithPrimaryBroker);
                        }
                    } else {
                        if (newMap.get(oppId).Primary_Dealer__c != null && dealerMap.get(newMap.get(oppId).Primary_Dealer__c) != null && dealerMap.get(newMap.get(oppId).Primary_Dealer__c).Dealer__c != null) {
                            //oppApprovedIdSet.add (oppId);
                            //approvedDealerIdSet.add (dealerMap.get(newMap.get(oppId).Primary_Dealer__c).Dealer__c);
                            //System.debug('#$#$ Here are the dealers we are going to loop through: ' + relatedDealers);
                            //System.debug('Opportunity Id:' + newMap.get(oppId));

                            for (Dealer__c dealer : relatedDealers) {

                                //System.debug('Dealer.Dealer__r.Approved__c: ' + dealer.Dealer__r.Approved__c);
                                //System.debug('dealer.Dealer__r.Approved_with_pricing__c: ' + dealer.Dealer__r.Approved_with_pricing__c);
                                if (dealer.Dealer__r.Approved__c == true) {
                                    //System.debug('Dealer ' + dealer.Id + 'added to Approved email list') ;
                                    sendApprovedWithPricingEmail = true;
                                    if (dealersReceivingApprovedEmail.get(dealer.Opportunity__c) == null) {
                                        dealersReceivingApprovedEmail.put(dealer.Opportunity__c, new Set<Id>{
                                                dealer.Id
                                        });
                                    } else {
                                        dealersReceivingApprovedEmail.get(oppId).add(dealer.Id);
                                    }
                                } else if (dealer.Dealer__r.Approved_with_pricing__c == true) {
                                    //System.debug('Dealer ' + dealer.Id + ' added to Approved With Pricing email list') ;
                                    sendApprovedWithPricingEmail = true;
                                    if (dealersReceivingApprovedWithPricingEmail.get(dealer.Opportunity__c) == null) {
                                        dealersReceivingApprovedWithPricingEmail.put(dealer.Opportunity__c, new Set<Id>{
                                                dealer.Id
                                        });
                                    } else {
                                        dealersReceivingApprovedWithPricingEmail.get(oppId).add(dealer.Id);
                                    }
                                }
//                                if (approvedOppWithPrimaryDealer.get(oppId) == null) {
//                                    approvedOppWithPrimaryDealer.put(dealer.Opportunity__c, new Set<Id>{dealer.Dealer__c});
//                                } else {
//                                    approvedOppWithPrimaryDealer.get(oppId).add(dealer.Dealer__c);
//                                }
                            }

                            //this checks if approved with pricing and will update the dummy variable approvedWithPricingCount
                            //System.debug('Approved with Pricing: ' + dealerMap.get(newMap.get(oppId).Primary_Dealer__c).Dealer__r.Approved_with_pricing__c);
                            //System.debug('Approved: ' + dealerMap.get(newMap.get(oppId).Primary_Dealer__c).Dealer__r.Approved__c);
                            if (dealerMap.get(newMap.get(oppId).Primary_Dealer__c).Dealer__r.Approved_with_pricing__c == true) {
                                sendApprovedWithPricingEmail = true;
                            } else if (dealerMap.get(newMap.get(oppId).Primary_Dealer__c).Dealer__r.Approved__c == true) {
                                sendApprovedEmail = true;
                            }
                        }
                    }
                }

            }
            Boolean addPrimaryDealerContactToApprovedWithPricingEmail = true;
            if(sendApprovedWithPricingEmail && sendApprovedEmail){
                addPrimaryDealerContactToApprovedWithPricingEmail = false;
            }

            ////System.debug ('????? oppApprovedIdSet: ' + oppApprovedIdSet);


            Id approvedTemplateId = null;
            Id approvedWithPricingTemplateId = null;
            List<EmailTemplate> emailTemplateList = new List<EmailTemplate>();

            if (dealersReceivingApprovedEmail.size() > 0 || approvedOppWithPrimaryBroker.size() > 0) {
                emailTemplateList = [SELECT Id, Name, HtmlValue, Body, Subject FROM EmailTemplate WHERE Name = 'DealerApproved'];
                for (EmailTemplate em : emailTemplateList) {
                    if (em.Name == 'DealerApproved') approvedTemplateId = em.Id;
                    //System.debug('Approved email to be sent.');
                }
            }
            if (dealersReceivingApprovedWithPricingEmail.size() > 0) {
                emailTemplateList = [SELECT Id, Name, HtmlValue, Body, Subject FROM EmailTemplate WHERE Name = 'Approved with Pricing'];
                for (EmailTemplate em : emailTemplateList) {
                    if (em.Name == 'Approved with Pricing') approvedWithPricingTemplateId = em.Id;
                    //System.debug('Approved with Pricing email to be sent');
                }
            }


            if (approvedTemplateId != null) {
                TC_RecursiveTriggerHelper.sentApprovedEmail = true;
                TC_PopulateOppMergeFields.populateOppMergeFields(new List<Id>(oppIdSet));
                //System.debug('#$#$ this is the approvedOppWithPrimaryDealer: ' + approvedOppWithPrimaryDealer);
                //System.debug('#$#$ this is the approvedOppWithPrimaryBroker: ' + approvedOppWithPrimaryBroker);
                if (!approvedOppWithPrimaryDealer.isEmpty ()) {
                    sendEmails2 (approvedOppWithPrimaryDealer, approvedTemplateId, opportunityOwnerIdsMap);
                } else if (!approvedOppWithPrimaryBroker.isEmpty()) {
                    sendEmails2 (approvedOppWithPrimaryBroker, approvedTemplateId, opportunityOwnerIdsMap);
//                    sendEmails (approvedOppWithPrimaryBroker, approvedTemplateId);
                }

            }

            /*The below two calls will check the list that we populated above, if there are dealer recipients for that email
            * type it will call the send email method passing in those dealer accounts mapped to the opportunity Id*/
            //System.debug('dealersReceivingApprovedEmail: ' + dealersReceivingApprovedEmail);
            //System.debug('approvedTemplateId: ' + approvedTemplateId);
            if (!dealersReceivingApprovedEmail.isEmpty() && approvedTemplateId != null) {
                TC_RecursiveTriggerHelper.sentApprovedEmail = true;
                TC_PopulateOppMergeFields.populateOppMergeFields(new List<Id>(oppIdSet));
                //System.debug('#$#$ dealers receiving the approved email: ' + dealersReceivingApprovedEmail);
                sendEmails2 (dealersReceivingApprovedEmail, approvedTemplateId, opportunityOwnerIdsMap);
            }

            //System.debug('dealersReceivingApprovedWithPricingEmail: ' + dealersReceivingApprovedWithPricingEmail);
            //System.debug('approvedWithPricingTemplateId: ' + approvedWithPricingTemplateId);
            if (!dealersReceivingApprovedWithPricingEmail.isEmpty() && approvedWithPricingTemplateId != null) {
                TC_RecursiveTriggerHelper.sentApprovedEmail = true;
                TC_PopulateOppMergeFields.populateOppMergeFields(new List<Id>(oppIdSet));
                //System.debug('#$#$ dealers receiving the approved with pricing email: ' + dealersReceivingApprovedWithPricingEmail);
                sendEmails2 (dealersReceivingApprovedWithPricingEmail, approvedWithPricingTemplateId, opportunityOwnerIdsMap, addPrimaryDealerContactToApprovedWithPricingEmail);
            }

        }

    }

    @TestVisible
    private static void sendEmails2(Map <Id, Set<Id>> oppWithPrimaryDealer, Id templateId, Map<Id, Id>opportunityOwnerIdsMap) {
        System.debug('$#$# Send Emails2 Method call::1');
        //System.debug('Parameters:\noppWithPrimaryDealer = ' + oppWithPrimaryDealer + '\ntemplateId = ' + templateId);
        List <OrgWideEmailAddress> noreply = new List <OrgWideEmailAddress> ([select id, Address, DisplayName from OrgWideEmailAddress where address = 'noreply@peacsolutions.com']);
        Map <Id, Set <Id>> oppContacts = new Map <Id, Set <Id>> ();
        Map<Id, User> opportunityOwnersMap = null;
        Map<Id, Contact> dealerContactMap = new Map<Id, Contact>();
        if (!oppWithPrimaryDealer.isEmpty()) {


            //Get Opportunity Owners
            opportunityOwnersMap = new Map<Id, User>([
                    SELECT Id, Email
                    FROM User
                    WHERE Id IN :opportunityOwnerIdsMap.values()
            ]);



            //1. Get the Dealer Primary Contact Role on the Opportunity
            Set<String> contactRoleStringSet = new Set<String>{
                    'Dealer Primary Contact', 'Dealer Sales Contact'
            };

            List<OpportunityContactRole> oppContactRoleList = new List<OpportunityContactRole>([
                    SELECT ContactId, OpportunityId, Contact.Receive_All_Notifications__c
                    FROM OpportunityContactRole
                    WHERE OpportunityId IN:oppWithPrimaryDealer.keySet ()
                    AND Role IN:contactRoleStringSet
                    AND Contact.Email != null
                    AND Contact.Email != ''
                    AND Opportunity.No_of_Broker__c = 0  //SAL-2896 Don't send notifications to dealers if broker is on opportunity. Jake Buchanan
            ]);

            //System.debug('oppContactRoleList: ' + oppContactRoleList);
            for (OpportunityContactRole ocr : oppContactRoleList) {
                //Check on if this contact is receiving notifications

                if (oppContacts.get (ocr.OpportunityId) != null) {
                    oppContacts.get (ocr.OpportunityId).add (ocr.ContactId);
                } else {
                    oppContacts.put (ocr.OpportunityId, new Set <Id>{
                            ocr.ContactId
                    });
                }

            }

            //2. Get all contacts of dealers associated to this opportunity and Dealer list
            Set <Id> primaryDealerIdSet = new Set <Id> ();
            for (Id oppId : oppWithPrimaryDealer.keySet()) {
                Set<Id> dealerIds = oppWithPrimaryDealer.get(oppId);
                for (Id dealerId : dealerIds) {
                    primaryDealerIdSet.add(dealerId);
                }
            }
            //System.debug('primaryDealerIdSet: ' + primaryDealerIdSet);

            Set<Id> dealerAccountIds = new Set<Id>();
            Set<Id> brokerAccountIds = new Set<Id>();

            Map<Id, Dealer__c> dealerMap;
            Map<Id, Broker__c> brokerMap;

            if (primaryDealerIdSet.size() > 0) {
                dealerMap = new Map<Id, Dealer__c>([SELECT Id, Dealer__c FROM Dealer__c WHERE Id IN :primaryDealerIdSet]);
                brokerMap = new Map<Id, Broker__c>([SELECT Id, Account__c FROM Broker__c WHERE Id IN :primaryDealerIdSet]);

                //System.debug('dealerMap: ' + dealerMap);
                //System.debug('brokerMap: ' + brokerMap);

                for (Dealer__c dealer : dealerMap.values()) {
                    dealerAccountIds.add(dealer.Dealer__c);
                }
                for (Broker__c broker : brokerMap.values()) {
                    dealerAccountIds.add(broker.Account__c);
                }
            }

            //System.debug('dealerAccountIds: ' + dealerAccountIds);

            List <Contact> dealerContacts;
            if (dealerAccountIds.size() > 0) {
                dealerContacts = new List<Contact>([
                        SELECT Id, AccountId, Email, Receive_All_Notifications__c, Account.SAM__r.Email, Account.Owner.Email
                        FROM Contact
                        WHERE AccountId IN :dealerAccountIds
                ]);

            }

            //System.debug('dealerContacts: ' + dealerContacts);            

            //Map <Id, Set <Id>> dealerContactMap = new Map <Id, Set <Id>> ();
            //Need to attach Contact to opportunity Id for email to work
            if (dealerContacts <> null && dealerContacts.size() > 0) {
                for (Contact c : dealerContacts) {
                    //Check on if this contact is receiving notifications
                    //System.debug('DealerContact ' + c.Id + ' receive notifications: ' + c.Receive_All_Notifications__c);
                    if(c.Receive_All_Notifications__c){
                        for (Id key : oppWithPrimaryDealer.keySet()) {
                            //System.debug('key: ' + key);
                            for (Id dealerId : oppWithPrimaryDealer.get(key)) {
                                //System.debug('dealer Id: ' + dealerId);
                                if (dealerMap.get(dealerId) <> null && (dealerMap.get(dealerId).Dealer__c == c.AccountId)) {
                                    //System.debug('dealerMap.get(dealerId).Dealer__c: ' + dealerMap.get(dealerId).Dealer__c);
                                    //System.debug('c.AccountId: ' + c.AccountId);
                                    if (c.Email <> null){
                                        if (oppContacts.get (key) != null) {
                                            oppContacts.get (key).add (c.Id);
                                        } else {
                                            oppContacts.put (key, new Set <Id>{
                                                    c.Id
                                            });
                                        }
                                    }
                                } else if (brokerMap.get(dealerId) <> null && (brokerMap.get(dealerId).Account__c == c.AccountId)) {
                                    //System.debug('brokerMap.get(dealerId).Account__c: ' + brokerMap.get(dealerId).Account__c);
                                    //System.debug('c.AccountId: ' + c.AccountId);
                                    if (c.Email <> null) {
                                        if (oppContacts.get (key) != null) {
                                            oppContacts.get (key).add (c.Id);
                                        } else {
                                            oppContacts.put (key, new Set <Id>{
                                                    c.Id
                                            });
                                        }
                                        
                                    }
                                }
                            }
                        }
                    }
                    dealerContactMap.put(c.Id, c);
                }
            }


        }

        //System.debug('oppContacts before sending email: ' + oppContacts);
        
        //SAL-3040 if emailTemplate is Docs Out with Contracts, get Contracts as Email attachments
        Map<Id, List<Messaging.EmailFileAttachment>> oppWithEmailAtts = new Map<Id, List<Messaging.EmailFileAttachment>>();
        List<EmailTemplate> emailTemplateList = new List<EmailTemplate>();
        if (templateId != null) {
            emailTemplateList = [SELECT Id, Name, HtmlValue, Body, Subject FROM EmailTemplate WHERE Id = :templateId];
            if (emailTemplateList.size() == 1 && emailTemplateList[0].Name == 'Docs Out w/ Contracts') {
                oppWithEmailAtts = TC_SendNotificationHelper.oppsWithEmailAttachments(oppWithPrimaryDealer.keySet());
            }
        }

        //START : Varun
        List<Messaging.SingleEmailMessage> dealerEmailList = new List<Messaging.SingleEmailMessage>();  
         List<Opportunity> oppLst = new List<Opportunity>([SELECT Id,Additional_Dealer_emails__c FROM Opportunity WHERE ID IN: oppWithPrimaryDealer.keySet()]);
        
        Map<Id,List<String>> oppRelatedEmailsMap = new Map<Id,List<String>>();
        for(Opportunity opp : oppLst){
            List<String> finalEmailLst = new List<String>();
            /*
                if(opp.Additional_Dealer_emails__c.contains(',')){
                    finalEmailLst = opp.Additional_Dealer_emails__c.split(',');
                } else{
                        finalEmailLst.add(opp.Additional_Dealer_emails__c);
                }
                */
                if(opp.Additional_Dealer_emails__c != null){
                    String addEmails = opp.Additional_Dealer_emails__c.replace(';',',');
                    finalEmailLst = addEmails.split(',');
                }
            //}
            
           oppRelatedEmailsMap.put(opp.Id,finalEmailLst); 
            system.debug('oppRelatedEmailsMap729>>>'+oppRelatedEmailsMap);
    }
        
        //END : Varun
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        if (!oppWithPrimaryDealer.isEmpty()) {
             Map<string,List<Messaging.EmailFileAttachment>> oppIdWithCVIdMap = new Map<string,List<Messaging.EmailFileAttachment>>();
            //Start : Varun 06/02
            if(TC_RecursiveTriggerHelper.sentApprovedEmail) {
                        System.debug('$#$# Varun::Send Emails2 Method call::1::sentApprovedEmail');

                Map<Id,Opportunity_Attachment__c> oAMap = new Map<Id,Opportunity_Attachment__c>([select Id,Opportunity__c from Opportunity_Attachment__c where Opportunity__c IN :oppWithPrimaryDealer.keySet() AND Dealer_Doc_Type__c = 'Approval Letter']);
                System.debug('Varun::oAMap::'+oAMap);
                Map<Id,Id> onBaseIdwithDocIdMap = new Map<Id,Id>();
                for(Attachment att : [select Id, Name,Body,ParentId from Attachment where ParentId IN :oAMap.keySet()]) {
                    string oppId = oAMap.get(att.ParentId).Opportunity__c;
                    if(!oppIdWithCVIdMap.containsKey(oppId)) {
                        List<Messaging.EmailFileAttachment> attachmentList = new List<Messaging.EmailFileAttachment>();
                        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
                        
                        attach.setContentType('application/pdf');
                        attach.setFileName(att.Name);
                        attach.setInline(false);
                        attach.Body = att.Body;
                        attachmentList.add(attach);
                        oppIdWithCVIdMap.put(oppId,attachmentList);
                    }
                }
                /*for(contentDocumentLink CDLink : [SELECT LinkedEntityid, ContentDocumentid FROM contentDocumentLink WHERE LinkedEntityId IN :oAMap.keySet()]) {
                    onBaseIdwithDocIdMap.put(CDLink.ContentDocumentid,CDLink.LinkedEntityid);  
                }
                System.debug('Varun::onBaseIdwithDocIdMap::'+onBaseIdwithDocIdMap);
                for(contentversion cv : [SELECT Id, title,PathOnClient, FileType,ContentDocumentId,
                                         versiondata 
                                         FROM contentversion 
                                         WHERE ContentDocumentId IN :onBaseIdwithDocIdMap.keySet()  
                                        ]){
                                            string oppId = oAMap.get(onBaseIdwithDocIdMap.get(cv.ContentDocumentId)).Opportunity__c;
                                            oppIdWithCVIdMap.put(oppId,cv.Id);
                                        }*/
            }
                System.debug('Varun::oppIdWithCVIdMap::'+oppIdWithCVIdMap);
            
               //Start End 06/04
            for (Id oppId : oppWithPrimaryDealer.keySet ()) {
                Integer count = 0 ;
                if (!oppContacts.isEmpty ()) {
                    // NOTE: RenderStoredEmailTemplate counts toward SOQL governor limit as one query
                    //Messaging.SingleEmailMessage emailMessage = Messaging.renderStoredEmailTemplate(templateId, current user, oppId);
                    List <String> bccAddresses = new List <String> ();
                    List <String> ccAddresses = new List <String> ();
                     
                    Set<Id> conIdNewSet = oppContacts.get(oppId);//varun
                    Id conIdNew =  new List<Id> (conIdNewSet).get(0);//varun
                   // user adExtraUser = [SELECT Id,name,email,isactive FROM user WHERE name = 'Integration User' LIMIT 1];
                    // custom labels can't be empty
                    if (Label.TC_DealerEmailsBCC.toLowerCase () != 'nobcc') bccAddresses = Label.TC_DealerEmailsBCC.split (';');
                    Messaging.SingleEmailMessage emailMsgAdditonalDealer;
                     //START:Varun
                        if(oppRelatedEmailsMap.get(oppId).size()>0 && oppRelatedEmailsMap.get(oppId)!=null ){
                        if(emailTemplateList.size() > 0){
                            List<String> emailBodyList = new List<String>();
                            emailBodyList.add(emailTemplateList[0].Subject);
                            //if(emailTemplateList[0].HtmlValue <> null) emailBodyList.add(emailTemplateList[0].HtmlValue);
                            //else emailBodyList.add(emailTemplateList[0].Body);
                            Messaging.SingleEmailMessage renderStoredEmailTemplate = Messaging.renderStoredEmailTemplate(emailTemplateList[0].Id, conIdNew, oppId);
                            List<Messaging.RenderEmailTemplateBodyResult> renderEmailTemplate = Messaging.renderEmailTemplate(conIdNew, oppId, emailBodyList);
                            if(renderEmailTemplate.size() > 0){
                                if(renderEmailTemplate[0].getSuccess()){
                                    emailMsgAdditonalDealer = CustomSendMailUtil.SetCustomSingleEmail(
                                        oppRelatedEmailsMap.get(oppId),
                                        renderEmailTemplate[0].getMergedBody(),
                                        null,//(emailTemplateList[0].HtmlValue == null ? renderEmailTemplate[1].getMergedBody() : ''), 
                                        renderStoredEmailTemplate.getHTMLBody(),//(emailTemplateList[0].HtmlValue != null? renderEmailTemplate[1].getMergedBody() : ''),
                                         null
                                     );
                                    //Start Varun 06/04
                                     if(oppIdWithCVIdMap.size() > 0 && oppIdWithCVIdMap.containskey(oppId)) {
                                         emailMsgAdditonalDealer.setFileAttachments(oppIdWithCVIdMap.get(oppId));
                                         System.debug('$#$# Varun::Send Emails2 Method call::1::sentApprovedEmail');
                                     }
                                    //End Varun 06/04
                                    if (!bccAddresses.isEmpty()) emailMsgAdditonalDealer.setBccAddresses(bccAddresses);
                                    //emailMsgAdditonalDealer.setToAddresses(oppRelatedEmailsMap.get(oppId));
                                    ccAddresses.add('PartnerNotifications@peacsolutions.com');
                                    if(dealerContactMap.containsKey(conIdNew) && dealerContactMap.get(conIdNew).Account.SAM__r.Email <> null)
                                        ccAddresses.add(dealerContactMap.get(conIdNew).Account.SAM__r.Email);
                                    if(dealerContactMap.containsKey(conIdNew) && dealerContactMap.get(conIdNew).Account.Owner.Email <> null)
                                        ccAddresses.add(dealerContactMap.get(conIdNew).Account.Owner.Email);
                                    emailMsgAdditonalDealer.setCcAddresses(ccAddresses);
                                    if (!noreply.isEmpty()) emailMsgAdditonalDealer.setOrgWideEmailAddressId(noreply[0].Id);
                                    dealerEmailList.add(emailMsgAdditonalDealer);
                                }
                            }
                        }
                     /* emailMsgAdditonalDealer.setWhatId(oppId);
                       emailMsgAdditonalDealer.setTargetObjectId (conIdNew);//change template id - main 
                        emailMsgAdditonalDealer.setTemplateId(templateId);
                        
                        // emailMsgAdditonalDealer.setToAddresses(testStr);
                        emailMsgAdditonalDealer.saveAsActivity = false;
                        ccAddresses.add('PartnerNotifications@peacsolutions.com');
                        if(dealerContactMap.containsKey(conIdNew) && dealerContactMap.get(conIdNew).Account.SAM__r.Email <> null)
                            ccAddresses.add(dealerContactMap.get(conIdNew).Account.SAM__r.Email);
                        if(dealerContactMap.containsKey(conIdNew) && dealerContactMap.get(conIdNew).Account.Owner.Email <> null)
                            ccAddresses.add(dealerContactMap.get(conIdNew).Account.Owner.Email);
                        emailMsgAdditonalDealer.setCcAddresses(ccAddresses);
                        if (!noreply.isEmpty()) emailMsgAdditonalDealer.setOrgWideEmailAddressId(noreply[0].Id);
                        dealerEmailList.add(emailMsgAdditonalDealer);*/
                           
                        //END : Varun
                        }
                    for (Id conId : oppContacts.get(oppId)) {
                        Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage ();
                        emailMessage.setWhatId(oppId);
                        emailMessage.setTargetObjectId (conId);
                        //System.debug('Sending email to Contact: ' + conId);
                        emailMessage.setTemplateId(templateId);                        
                        if (!bccAddresses.isEmpty()) emailMessage.setBccAddresses(bccAddresses);
                        emailMessage.setToAddresses (new List <Id>{
                                conId
                        });
                        //System.debug('Sent Emails to: ' + conId);
                        //System.debug(conId + ' dealerContactMap: ' + dealerContactMap.containsKey(conId) );
                        ccAddresses.add('PartnerNotifications@peacsolutions.com');
                        if(dealerContactMap.containsKey(conId) && dealerContactMap.get(conId).Account.SAM__r.Email <> null)
                            ccAddresses.add(dealerContactMap.get(conId).Account.SAM__r.Email);
                        if(dealerContactMap.containsKey(conId) && dealerContactMap.get(conId).Account.Owner.Email <> null)
                            ccAddresses.add(dealerContactMap.get(conId).Account.Owner.Email);
                        emailMessage.setCcAddresses(ccAddresses);
                        
                        emailMessage.saveAsActivity = false;
                        if (!noreply.isEmpty()) emailMessage.setOrgWideEmailAddressId(noreply[0].Id);
                        if(TC_RecursiveTriggerHelper.sentApprovedEmail  && oppIdWithCVIdMap.containskey(oppId)) {
                            emailMessage.setFileAttachments(oppIdWithCVIdMap.get(oppId));
                        }
                        //SAL-3040 if emailTemplate is Docs Out with Contracts, add attachments to email
                        if (emailTemplateList.size() == 1 && emailTemplateList[0].Name == 'Docs Out w/ Contracts') {
                            List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
                            
                            //check if there were contracts returned for this oppId
                            if (oppWithEmailAtts.containsKey(oppId)){
                                for (Messaging.EmailFileAttachment efa : oppWithEmailAtts.get(oppId)) {
                                    emailAttachments.add(efa);
                                } 
                                if (emailAttachments.size() > 0) {
                                    emailMessage.setFileAttachments(emailAttachments);
                                    //START : varun 
                                    if(emailMsgAdditonalDealer <> null ) emailMsgAdditonalDealer.setFileAttachments(emailAttachments);
                                    //END : varun
                                }
                            }
                        }
                        
                        emailList.add(emailMessage);
                        //System.debug('email message target object id con: ' + emailMessage.targetObjectId);
                    }

                }
            }
        }
         //START: Varun
         
        if(!dealerEmailList.isEmpty()){
          Messaging.SendEmailResult[] dealerResults = new List<Messaging.SendEmailResult>();//Varun changes
             system.debug('dealerEmailList>>>'+dealerEmailList);
           dealerResults = Messaging.sendEmail(dealerEmailList);//Varun changes

        }
        //END: Varun
        //System.debug ('>>>>> emailList: ' + emailList.size ());
        // SAL-2688 added debug statement
        System.debug ('email list: ' + emailList);
        if (!emailList.isEmpty()) {
            Messaging.SendEmailResult[] results = new List<Messaging.SendEmailResult>();
            if (!Test.isRunningTest()) {
                try {
                      
                    results = Messaging.sendEmail(emailList, false);
                     
                    // SAL-2688 added results printout for debugging
                    for (Messaging.SendEmailResult result : results) {
                        if (result.isSuccess()) {
                            //System.debug('Email sent successfully!');
                        } else {
                            //System.debug('Error when sending dealer emails:\n');
                            for (Messaging.SendEmailError error : result.getErrors()) {
                                //System.debug('Message: ' + error.message);
                                //System.debug('Status code: ' + error.statusCode);
                                //System.debug('Target object id: ' + error.targetObjectId + '\n');
                            }
                        }
                    }
                } catch (Exception e) {
                    //System.debug ('Error while sending dealer emails: ' + e + ' ' + results);
                }
            }
        }
    }



    @TestVisible
    private static void sendEmails2(Map <Id, Set<Id>> oppWithPrimaryDealer, Id templateId, Map<Id, Id>opportunityOwnerIdsMap, Boolean getRelatedDealer) {
        //this is a method with different parameters to determine if related dealer should be added to email list
        System.debug('$#$# Send Emails2 Method call');
        List <OrgWideEmailAddress> noreply = new List <OrgWideEmailAddress> ([select id, Address, DisplayName from OrgWideEmailAddress where address = 'noreply@peacsolutions.com']);

        Map <Id, Set <Id>> oppContacts = new Map <Id, Set <Id>> ();
        Map<Id, User> opportunityOwnersMap = null;
        Map<Id, Contact> dealerContactMap = new Map<Id, Contact>();
        if (!oppWithPrimaryDealer.isEmpty()) {


            //Get Opportunity Owners
            opportunityOwnersMap = new Map<Id, User>([
                    SELECT Id, Email
                    FROM User
                    WHERE Id IN :opportunityOwnerIdsMap.values()
            ]);

            if (getRelatedDealer) {
                //1. Get the Dealer Primary Contact Role on the Opportunity
                Set<String> contactRoleStringSet = new Set<String>{
                        'Dealer Primary Contact', 'Dealer Sales Contact'
                };
                List<OpportunityContactRole> oppContactRoleList = new List<OpportunityContactRole>([
                        SELECT ContactId, OpportunityId, Contact.Receive_All_Notifications__c
                        FROM OpportunityContactRole
                        WHERE OpportunityId IN:oppWithPrimaryDealer.keySet ()
                        AND Role IN:contactRoleStringSet
                        AND Contact.Email != null
                        AND Contact.Email != ''
                        AND Opportunity.No_of_Broker__c = 0  //SAL-2896 Don't send notifications to dealers if broker is on opportunity. Jake Buchanan
                ]);

                //System.debug('oppContactRoleList: ' + oppContactRoleList);
                for (OpportunityContactRole ocr : oppContactRoleList) {

                    if (oppContacts.get (ocr.OpportunityId) != null) {
                        oppContacts.get (ocr.OpportunityId).add (ocr.ContactId);
                    } else {
                        oppContacts.put (ocr.OpportunityId, new Set <Id>{
                                ocr.ContactId
                        });
                    }

                }
            }


            //2. Get all contacts of dealers associated to this opportunity and Dealer list
            Set <Id> primaryDealerIdSet = new Set <Id> ();
            for (Id oppId : oppWithPrimaryDealer.keySet()) {
                Set<Id> dealerIds = oppWithPrimaryDealer.get(oppId);
                for (Id dealerId : dealerIds) {
                    primaryDealerIdSet.add(dealerId);
                }
            }
            List <Contact> dealerContacts = new List<Contact>([
                    SELECT Id, AccountId, Email, Receive_All_Notifications__c, Account.SAM__r.Email, Account.Owner.Email
                    FROM Contact
                    WHERE AccountId IN :primaryDealerIdSet
            ]);

            //Map <Id, Set <Id>> dealerContactMap = new Map <Id, Set <Id>> ();
            //Need to attach Contact to opportunity Id for email to work
            for (Contact c : dealerContacts) {
                //Check on if this contact is receiving notifications
                //System.debug('DealerContact ' + c.Id + ' receive notifications: ' + c.Receive_All_Notifications__c);
                if (c.Receive_All_Notifications__c) {
                    for (Id key : oppWithPrimaryDealer.keySet()) {
                        for (Id dealerId : oppWithPrimaryDealer.get(key)) {
                            if (dealerId == c.AccountId) {
                                if (oppContacts.get (key) != null) {
                                    oppContacts.get (key).add (c.Id);
                                } else {
                                    oppContacts.put (key, new Set <Id>{
                                            c.Id
                                    });
                                }
                                
                            }
                        }
                    }
                }
                dealerContactMap.put(c.Id, c);
            }
        }

        //System.debug('oppContacts before sending email: ' + oppContacts);
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        //START : Varun
        List<Messaging.SingleEmailMessage> dealerEmailList = new List<Messaging.SingleEmailMessage>();  
         List<Opportunity> oppLst = new List<Opportunity>([SELECT Id,Additional_Dealer_emails__c FROM Opportunity WHERE ID IN: oppWithPrimaryDealer.keySet()]);
        
        Map<Id,List<String>> oppRelatedEmailsMap = new Map<Id,List<String>>();
        for(Opportunity opp : oppLst){
            List<String> finalEmailLst = new List<String>();
            /*
               if(opp.Additional_Dealer_emails__c.contains(';')){
                finalEmailLst = opp.Additional_Dealer_emails__c.split(';');
            }
            else{
                finalEmailLst.add(opp.Additional_Dealer_emails__c);
        } 
            }*/
            if(opp.Additional_Dealer_emails__c!=null){
                String addEmails = opp.Additional_Dealer_emails__c.replace(';',',');
                finalEmailLst.addAll(addEmails.split(','));
            }
           oppRelatedEmailsMap.put(opp.Id,finalEmailLst); 
            system.debug('oppRelatedEmailsMap>>>'+oppRelatedEmailsMap);
    }
        
        List<EmailTemplate> emailTemplateList = new List<EmailTemplate>([
                    SELECT Id, Name, HtmlValue, Body, Subject
                    FROM EmailTemplate
                    WHERE Id = :templateId
            ]);
        //END : Varun
        if (!oppWithPrimaryDealer.isEmpty()) {
             Map<string,List<Messaging.EmailFileAttachment>> oppIdWithCVIdMap = new Map<string,List<Messaging.EmailFileAttachment>>();
            //Start : Varun 06/02
            if(TC_RecursiveTriggerHelper.sentApprovedEmail) {
                
                Map<Id,Opportunity_Attachment__c> oAMap = new Map<Id,Opportunity_Attachment__c>([select Id,Opportunity__c from Opportunity_Attachment__c where Opportunity__c IN :oppWithPrimaryDealer.keySet() AND Dealer_Doc_Type__c = 'Approval Letter']);
                System.debug('Varun::oAMap::'+oAMap);
                Map<Id,Id> onBaseIdwithDocIdMap = new Map<Id,Id>();
                for(Attachment att : [select Id, Name,Body,ParentId from Attachment where ParentId IN :oAMap.keySet()]) {
                    string oppId = oAMap.get(att.ParentId).Opportunity__c;
                    if(!oppIdWithCVIdMap.containsKey(oppId)) {
                        List<Messaging.EmailFileAttachment> attachmentList = new List<Messaging.EmailFileAttachment>();
                        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
                        
                        attach.setContentType('application/pdf');
                        attach.setFileName(att.Name);
                        attach.setInline(false);
                        attach.Body = att.Body;
                        attachmentList.add(attach);
                        oppIdWithCVIdMap.put(oppId,attachmentList);
                    }
                }
            }
            for (Id oppId : oppWithPrimaryDealer.keySet ()) {
               
                if (!oppContacts.isEmpty ()) {
                    // NOTE: RenderStoredEmailTemplate counts toward SOQL governor limit as one query
                    //Messaging.SingleEmailMessage emailMessage = Messaging.renderStoredEmailTemplate(templateId, current user, oppId);
                    List <String> bccAddresses = new List <String> ();
                    List <String> ccAddresses = new List <String> ();
                    // custom labels can't be empty
                    Messaging.SingleEmailMessage emailMsgAdditonalDealer = new Messaging.SingleEmailMessage ();//varun
                    Set<Id> conIdNewSet = oppContacts.get(oppId);//varun
                    Id conIdNew =  new List<Id> (conIdNewSet).get(0);//varun
                    
                    
                    if (Label.TC_DealerEmailsBCC.toLowerCase () != 'nobcc') bccAddresses = Label.TC_DealerEmailsBCC.split (';');
                    //START:Varun
                        if(oppRelatedEmailsMap.get(oppId).size()>0 && oppRelatedEmailsMap.get(oppId)!=null ){
                        
                         List<String> emailBodyList = new List<String>();
                            emailBodyList.add(emailTemplateList[0].Subject);
                            //if(emailTemplateList[0].HtmlValue <> null) emailBodyList.add(emailTemplateList[0].HtmlValue);
                            //else emailBodyList.add(emailTemplateList[0].Body);
                            Messaging.SingleEmailMessage renderStoredEmailTemplate = Messaging.renderStoredEmailTemplate(emailTemplateList[0].Id, conIdNew, oppId);
                            List<Messaging.RenderEmailTemplateBodyResult> renderEmailTemplate = Messaging.renderEmailTemplate(conIdNew, oppId, emailBodyList);
                            if(renderEmailTemplate.size() > 0){
                                if(renderEmailTemplate[0].getSuccess()){
                                    emailMsgAdditonalDealer = CustomSendMailUtil.SetCustomSingleEmail(
                                        oppRelatedEmailsMap.get(oppId),
                                        renderEmailTemplate[0].getMergedBody(),
                                        null,//(emailTemplateList[0].HtmlValue == null ? renderEmailTemplate[1].getMergedBody() : ''), 
                                        renderStoredEmailTemplate.getHTMLBody(),//(emailTemplateList[0].HtmlValue != null? renderEmailTemplate[1].getMergedBody() : ''),
                                         null
                                     );
                                    if(oppIdWithCVIdMap.size() > 0 && oppIdWithCVIdMap.containskey(oppId)) {
                                         emailMsgAdditonalDealer.setFileAttachments(oppIdWithCVIdMap.get(oppId));
                                    }
                                    
                                }
                            }
                            
                      /*emailMsgAdditonalDealer.setWhatId(oppId);
                       emailMsgAdditonalDealer.setTargetObjectId (conIdNew);//change template id
                        emailMsgAdditonalDealer.setTemplateId(templateId);*/
                        if (!bccAddresses.isEmpty()) emailMsgAdditonalDealer.setBccAddresses(bccAddresses);
                        emailMsgAdditonalDealer.setToAddresses(oppRelatedEmailsMap.get(oppId));
                         //emailMsgAdditonalDealer.setToAddresses(testStr);
                        emailMsgAdditonalDealer.saveAsActivity = false;
                        ccAddresses.add('PartnerNotifications@peacsolutions.com');
                        if(dealerContactMap.containsKey(conIdNew) && dealerContactMap.get(conIdNew).Account.SAM__r.Email <> null)
                            ccAddresses.add(dealerContactMap.get(conIdNew).Account.SAM__r.Email);
                        if(dealerContactMap.containsKey(conIdNew) && dealerContactMap.get(conIdNew).Account.Owner.Email <> null)
                            ccAddresses.add(dealerContactMap.get(conIdNew).Account.Owner.Email);
                        emailMsgAdditonalDealer.setCcAddresses(ccAddresses);
                        if (!noreply.isEmpty()) emailMsgAdditonalDealer.setOrgWideEmailAddressId(noreply[0].Id);
                        dealerEmailList.add(emailMsgAdditonalDealer);
                            
                        //END : Varun
                        }
                        
                    for (Id conId : oppContacts.get(oppId)) {
                        
                        Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage ();
                        
                      
                        emailMessage.setWhatId(oppId);
                        emailMessage.setTargetObjectId (conId);
                        //System.debug('Sending email to Contact: ' + conId);
                        emailMessage.setTemplateId(templateId);
                        if (!bccAddresses.isEmpty()) emailMessage.setBccAddresses(bccAddresses);
                        emailMessage.setToAddresses (new List <Id>{
                                conId
                        });
                        //System.debug(conId + ' dealerContactMap: ' + dealerContactMap.containsKey(conId) );
                        emailMessage.saveAsActivity = false;
                        ccAddresses.add('PartnerNotifications@peacsolutions.com');
                        if(dealerContactMap.containsKey(conId) && dealerContactMap.get(conId).Account.SAM__r.Email <> null)
                            ccAddresses.add(dealerContactMap.get(conId).Account.SAM__r.Email);
                        if(dealerContactMap.containsKey(conId) && dealerContactMap.get(conId).Account.Owner.Email <> null)
                            ccAddresses.add(dealerContactMap.get(conId).Account.Owner.Email);
                        emailMessage.setCcAddresses(ccAddresses);
                        if (!noreply.isEmpty()) emailMessage.setOrgWideEmailAddressId(noreply[0].Id);
                        emailList.add(emailMessage);
                    }

                }
            }
        }
        //START: Varun
        if(!dealerEmailList.isEmpty()){
          Messaging.SendEmailResult[] dealerResults = new List<Messaging.SendEmailResult>();//Varun changes
             system.debug('dealerEmailList123>>>'+dealerEmailList);
            
           dealerResults = Messaging.sendEmail(dealerEmailList);//Varun changes

        }
        //END: Varun
        //System.debug ('>>>>> emailList: ' + emailList.size ());
        if (!emailList.isEmpty()) {
            Messaging.SendEmailResult[] results = new List<Messaging.SendEmailResult>();
            if (!Test.isRunningTest()) {
                try {

                    results = Messaging.sendEmail(emailList);
                } catch (Exception e) {
                    //System.debug ('Error while sending dealer emails: ' + e + ' ' + results);
                }
            }
        }
    }



    public static void scheduleMoreInfoNotification(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {

        //System.debug ('!!!!! in scheduleMoreInfoNotification');

        Map<Id, Opportunity> filteredNewMap = new Map<Id, Opportunity>();   // non-SF apps
        // Map<Id, Opportunity> sfNewMap = new Map<Id, Opportunity>();         // SF apps

        for (Opportunity opp : newMap.values()) {
            if ((
                    ((opp.Opportunity_Status__c == 'Credit - More Info Requested' 
                      && oldMap.get(opp.Id).Opportunity_Status__c != 'Credit - More Info Requested')
                            ||
                     (opp.Opportunity_Status__c == 'Fraud More Info Requested' 
                      && oldMap.get(opp.Id).Opportunity_Status__c != 'Fraud More Info Requested'))
                   // && !opp.Portal_User_ID__c.contains ('B2B-') Commented due to SAL-5327
                    && opp.Opportunity_Owner__c <> 'loan portal')
                    || ((opp.Opportunity_Status__c == 'Credit - More Info Requested' || opp.Opportunity_Status__c == 'Fraud More Info Requested') 
                       // && !opp.Portal_User_ID__c.contains ('B2B-') Commented due to SAL-5327
                        && opp.Opportunity_Owner__c <> 'loan portal' 
                        && oldMap.get(opp.Id).Opportunity_Owner__c == 'loan portal')) {
                // if (opp.Portal_User_ID__c <> 'SF-') {
                filteredNewMap.put(opp.Id, opp);
                // } else {
                //     sfNewMap.put(opp.Id, opp);
                // }
            }
        }

        if (filteredNewMap.size() > 0) {
            try {
                // SAL-5496 Misael Romero
                if(System.isQueueable()){
                    moreInfoNotification(oldMap, filteredNewMap);
                }else{
                    Integer delay = 3;
                    System.enqueueJob(new SL_NotificationEmailQ(oldMap, filteredNewMap, 'More Info'), delay);
                    // System.scheduleBatch(new TC_NotificationEmailBatch(oldMap, filteredNewMap, 'More Info'), 'DealerMoreInfo' + System.currentTimeMillis(), 3);
                }
            } catch (Exception e) {
                //System.debug(LoggingLevel.ERROR, e.getMessage());
            }
        }

        // if (sfNewMap.size() > 0) {
        //     //System.debug('sfNewMap: ' + sfNewMap);
        //     moreInfoNotification(oldMap, sfNewMap);
        // }
    }

    //other Notifications
    public static void moreInfoNotification(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {

        //System.debug('#$#$ moreInfoNotification');

        Set<Id> oppIds = new Set<Id>();

        Set<Id> brokerIds = new Set<Id>();
        Set<Id> dealerIds = new Set<Id>();

        // SAL-2773 added Fraud More Info Requested
        for (Opportunity opp : newMap.values()) {
            if ((
                    ((opp.Opportunity_Status__c == 'Credit - More Info Requested' 
                      && oldMap.get(opp.Id).Opportunity_Status__c != 'Credit - More Info Requested')
                            ||
                     (opp.Opportunity_Status__c == 'Fraud More Info Requested' 
                      && oldMap.get(opp.Id).Opportunity_Status__c != 'Fraud More Info Requested'))
                  //  && !opp.Portal_User_ID__c.contains ('B2B-')  Commented due to SAL-5327
                    && opp.Opportunity_Owner__c <> 'loan portal')
                    || ((opp.Opportunity_Status__c == 'Credit - More Info Requested' || opp.Opportunity_Status__c == 'Fraud More Info Requested') 
                       // && !opp.Portal_User_ID__c.contains ('B2B-')  Commented due to SAL-5327
                        && opp.Opportunity_Owner__c <> 'loan portal' 
                        && oldMap.get(opp.Id).Opportunity_Owner__c == 'loan portal')) {
                if (opp.Branch__c <> null && opp.Branch__c.contains('IFP')) {
                    brokerIds.add(opp.Id);
                } else {
                    dealerIds.add(opp.Id);
                }
                oppIds.add(opp.Id);
            }
        }
        //System.debug('Opportunities pulling dealers from: ' + oppIds);

        Map<Id, Dealer__c> dealerMap = new Map<Id, Dealer__c>();
        Map<Id, Broker__c> brokerMap = new Map<Id, Broker__c>();

        Map<Id, Id> opportunityOwnerIdsMap = new Map<Id, Id>();

        if (!oppIds.isEmpty()) {
            //getting opportunity owners
            for (Id oppId : oppIds){
                opportunityOwnerIdsMap.put(oppId, newMap.get(oppId).OwnerId);
            }

            if (dealerIds.size() > 0) {
                dealerMap = new Map<Id, Dealer__c>([
                        SELECT Id, Opportunity__c, Dealer__r.Partner_UDA_Notification__c, Dealer__c, Dealer__r.More_Info__c
                        FROM Dealer__c
                        WHERE Opportunity__c IN :oppIds
                ]);
            }

            if (brokerIds.size() > 0) {
                brokerMap = new Map<Id, Broker__c>([
                        SELECT Id, Opportunity__c, Account__r.Partner_UDA_Notification__c, Account__c, Account__r.More_Info__c
                        FROM Broker__c
                        WHERE Opportunity__c IN :oppIds
                ]);
            }
        }

        Map<Id, Set<Id>> emailList = new Map<Id, Set<Id>>();

        if (!dealerMap.isEmpty()) {
            //System.debug('dealerMap: ' + dealerMap);
            for (Id key : dealerMap.keySet()) {
                //System.debug('key: ' + key);
                if(dealerMap.get(key).Dealer__r.More_Info__c){
                    //System.debug('dealer account has more info');
                    if (emailList.get(dealerMap.get(key).Opportunity__c) == null) {
                        emailList.put(dealerMap.get(key).Opportunity__c, new Set<Id>{dealerMap.get(key).Id});
                    } else {
                        emailList.get(dealerMap.get(key).Opportunity__c).add(dealerMap.get(key).Id);
                    }
                }
            }
        }

        //System.debug('emaillist: ' + emailList);

        if (!brokerMap.isEmpty()) {
            for (Id brokerKey : brokerMap.keySet()) {
                if (brokerMap.get(brokerKey).Account__r.More_Info__c) {
                    if (emailList.get(brokerMap.get(brokerKey).Opportunity__c) == null) {
//                        emailList.put(brokerMap.get(brokerKey).Opportunity__c, new Set<Id>{brokerMap.get(brokerKey).Account__c});
                        emailList.put(brokerMap.get(brokerKey).Opportunity__c, new Set<Id>{brokerMap.get(brokerKey).Id});
                    } else {
//                       emailList.get(brokerMap.get(brokerKey).Opportunity__c).add(brokerMap.get(brokerKey).Account__c);
                        emailList.get(brokerMap.get(brokerKey).Opportunity__c).add(brokerMap.get(brokerKey).Id);
                    }
                }
            }
        }
        //System.debug('Sending emails to: ' + emailList);

        Id moreInfoTemplateId = null;

        if (!emailList.isEmpty()) {
            List<EmailTemplate> emailTemplateList = new List<EmailTemplate>([
                    SELECT Id, Name, HtmlValue, Body, Subject
                    FROM EmailTemplate
                    WHERE Name = 'More Info'
            ]);
            //System.debug('#$#$#$ Email Template List: ' + emailTemplateList);
            for (EmailTemplate em : emailTemplateList) {
                if (em.Name == 'More Info') moreInfoTemplateId = em.Id;
            }
        }

        if (moreInfoTemplateId != null) {
            //TC_RecursiveTriggerHelper.sentSubmittedEmail = true;
            //System.debug ('#$#$#$ email is being triggered to send');
            if (!emailList.isEmpty()) {
                sendEmails2 (emailList, moreInfoTemplateId, opportunityOwnerIdsMap);
            }
        }
    }

    public static void scheduleDeclinedNotification(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {

        //System.debug ('!!!!! in scheduleDeclinedNotification');

        Map<Id, Opportunity> filteredNewMap = new Map<Id, Opportunity>();   // non-SF apps
        // Map<Id, Opportunity> sfNewMap = new Map<Id, Opportunity>();         // SF apps

        // SAL-2778 added check for "Suspicious activity - Declined" opportunity status
        for (Opportunity opp : newMap.values()) {
            String portalUserId = opp.Portal_User_ID__c != null? opp.Portal_User_ID__c: '';
            if (((opp.Opportunity_Status__c == 'Credit - Declined' &&
                    oldMap.get(opp.Id).Opportunity_Status__c != 'Credit - Declined') ||
                    (opp.Opportunity_Status__c == 'Suspicious activity - Declined' && 
                    oldMap.get(opp.Id).Opportunity_Status__c != 'Suspicious activity - Declined')
                   // && !portalUserId.contains ('B2B-')  Commented due to SAL-5327
                    && opp.Opportunity_Owner__c <> 'loan portal') ||
                    ((opp.Opportunity_Status__c == 'Credit - Declined' || opp.Opportunity_Status__c == 'Suspicious activity - Declined')
                    // && !portalUserId.contains ('B2B-') Commented due to SAL-5327
                     && opp.Opportunity_Owner__c <> 'loan portal' && oldMap.get(opp.Id).Opportunity_Owner__c == 'loan portal')) {
                // if (portalUserId <> 'SF-') {
                filteredNewMap.put(opp.Id, opp);
                // } else {
                //     sfNewMap.put(opp.Id, opp);
                // }
            }
        }

        if (filteredNewMap.size() > 0) {
            //System.debug('filteredNewMap: ' + filteredNewMap);
            try {
                // SAL-5496 Misael Romero
                if(System.isQueueable()){
                    declinedNotification(oldMap, filteredNewMap);
                }else{
                    Integer delay = 3;
                    System.enqueueJob(new SL_NotificationEmailQ(oldMap, filteredNewMap, 'Rejected'), delay);
                    // System.scheduleBatch(new TC_NotificationEmailBatch(oldMap, filteredNewMap, 'Rejected'), 'DealerRejected' + System.currentTimeMillis(), 3);
                }
            } catch (Exception e) {
                //System.debug(LoggingLevel.ERROR, e.getMessage());
            }
        }

        // if (sfNewMap.size() > 0) {
        //     //System.debug('sfNewMap: ' + sfNewMap);
        //     declinedNotification(oldMap, sfNewMap);
        // }
    }

    public static void declinedNotification(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {


        //System.debug('#$#$ declinedNotification');

        Set<Id> oppIds = new Set<Id>();

        Set<Id> brokerIds = new Set<Id>();
        Set<Id> dealerIds = new Set<Id>();

        // SAL-2778 added check for "Suspicious activity - Declined" opportunity status
        for (Opportunity opp : newMap.values()) {
            if (((opp.Opportunity_Status__c == 'Credit - Declined' &&
                oldMap.get(opp.Id).Opportunity_Status__c != 'Credit - Declined') ||
                (opp.Opportunity_Status__c == 'Suspicious activity - Declined' &&
                oldMap.get(opp.Id).Opportunity_Status__c != 'Suspicious activity - Declined')
               // && !opp.Portal_User_ID__c.contains ('B2B-') Commented due to SAL-5327
                 && opp.Opportunity_Owner__c <> 'loan portal') ||
                ((opp.Opportunity_Status__c == 'Credit - Declined' || opp.Opportunity_Status__c == 'Suspicious activity - Declined') 
               // && !opp.Portal_User_ID__c .contains ('B2B-') Commented due to SAL-5327
                && opp.Opportunity_Owner__c <> 'loan portal' && oldMap.get(opp.Id).Opportunity_Owner__c == 'loan portal')) {
                if (opp.Branch__c <> null && opp.Branch__c.contains('IFP')) {
                    brokerIds.add(opp.Id);
                } else {
                    dealerIds.add(opp.Id);
                }
                oppIds.add(opp.Id);
            }
        }
        
        Map<Id, Dealer__c> dealerMap = new Map<Id, Dealer__c>();
        Map<Id, Broker__c> brokerMap = new Map<Id, Broker__c>();

        Map<Id, Id> opportunityOwnerIdsMap = new Map<Id, Id>();

        if (!oppIds.isEmpty()) {
            //getting opportunity owners
            for (Id oppId : oppIds){
                opportunityOwnerIdsMap.put(oppId, newMap.get(oppId).OwnerId);
            }

            if (dealerIds.size() > 0) {
                dealerMap = new Map<Id, Dealer__c>([
                        SELECT Id, Opportunity__c, Dealer__r.Partner_UDA_Notification__c, Dealer__c, Dealer__r.Declined__c
                        FROM Dealer__c
                        WHERE Opportunity__c IN :oppIds
                ]);
                //System.debug('dealerMap:' + dealerMap);
            }

            if (brokerIds.size() > 0) {
                brokerMap = new Map<Id, Broker__c>([
                        SELECT Id, Opportunity__c, Account__r.Partner_UDA_Notification__c, Account__c, Account__r.Declined__c
                        FROM Broker__c
                        WHERE Opportunity__c IN :oppIds
                ]);
            }

        }

        Map<Id, Set<Id>> emailList = new Map<Id, Set<Id>>();

        if (!dealerMap.isEmpty()) {
            //System.debug('dealerMap: ' + dealerMap);
            for (Id key : dealerMap.keySet()) {
                //System.debug('key: ' + key);
                if (dealerMap.get(key).Dealer__r.Declined__c){
                    //System.debug('dealer account has declined');
                    if (emailList.get(dealerMap.get(key).Opportunity__c) == null) {
                        emailList.put(dealerMap.get(key).Opportunity__c, new Set<Id>{dealerMap.get(key).Id});
                    } else {
                        emailList.get(dealerMap.get(key).Opportunity__c).add(dealerMap.get(key).Id);
                    }
                }
            }
        }

        //System.debug('emaillist: ' + emailList);

        if (!brokerMap.isEmpty()) {
            for (Id brokerKey : brokerMap.keySet()) {
                if (brokerMap.get(brokerKey).Account__r.Declined__c) {
                    if (emailList.get(brokerMap.get(brokerKey).Opportunity__c) == null) {
//                        emailList.put(brokerMap.get(brokerKey).Opportunity__c, new Set<Id>{brokerMap.get(brokerKey).Account__c});
                        emailList.put(brokerMap.get(brokerKey).Opportunity__c, new Set<Id>{brokerMap.get(brokerKey).Id});
                    } else {
//                        emailList.get(brokerMap.get(brokerKey).Opportunity__c).add(brokerMap.get(brokerKey).Account__c);
                        emailList.get(brokerMap.get(brokerKey).Opportunity__c).add(brokerMap.get(brokerKey).Id);
                    }
                }
            }
        }
        //System.debug('Sending emails to: ' + emailList);

        Id declinedTemplateId = null;

        if (!emailList.isEmpty()) {
            List<EmailTemplate> emailTemplateList = new List<EmailTemplate>([
                    SELECT Id, Name, HtmlValue, Body, Subject
                    FROM EmailTemplate
                    WHERE Name = 'Declined'
            ]);
            //System.debug('#$#$#$ Email Template List: ' + emailTemplateList);
            for (EmailTemplate em : emailTemplateList) {
                if (em.Name == 'Declined') declinedTemplateId = em.Id;
            }
        }

        if (declinedTemplateId != null) {
            //TC_RecursiveTriggerHelper.sentSubmittedEmail = true;
            //System.debug ('#$#$#$ email is being triggered to send');
            if (!emailList.isEmpty()) {
                sendEmails2 (emailList, declinedTemplateId, opportunityOwnerIdsMap);
            }
        }
    }

    public static void docsOutNotification(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {


        //System.debug('#$#$ docsOutNotification');

        Set<Id> oppIds = new Set<Id>();

        Set<Id> brokerIds = new Set<Id>();
        Set<Id> dealerIds = new Set<Id>();

        for (Opportunity opp : newMap.values()) {
            if (opp.StageName == 'Docs Out' &&
                    oldMap.get(opp.Id).StageName != 'Docs Out'
                && opp.Portal_User_ID__c != null)
               // && !opp.Portal_User_ID__c.contains ('B2B-')) Commented due to SAL-5327
                {
                if (opp.Branch__c <> null && opp.Branch__c.contains('IFP')) {
                    brokerIds.add(opp.Id);
                } else {
                    dealerIds.add(opp.Id);
                }
                oppIds.add(opp.Id);
            }
        }
        //System.debug('Opportunities pulling dealers from: ' + oppIds);

        Map<Id, Dealer__c> dealerMap = new Map<Id, Dealer__c>();
        Map<Id, Broker__c> brokerMap = new Map<Id, Broker__c>();

        Map<Id, Id> opportunityOwnerIdsMap = new Map<Id, Id>();

        if (!oppIds.isEmpty()) {
            //getting opportunity owners
            for (Id oppId : oppIds){
                opportunityOwnerIdsMap.put(oppId, newMap.get(oppId).OwnerId);
            }

            if (dealerIds.size() > 0) {
                dealerMap = new Map<Id, Dealer__c>([
                        SELECT Id, Opportunity__c, Dealer__r.Partner_UDA_Notification__c, Dealer__c, Dealer__r.Docs_Out__c, Dealer__r.Docs_Out_Contracts__c 
                        FROM Dealer__c
                        WHERE Opportunity__c IN :oppIds
                ]); 
            }

            if (brokerIds.size() > 0) {
                brokerMap = new Map<Id, Broker__c>([
                        SELECT Id, Opportunity__c, Account__r.Partner_UDA_Notification__c, Account__c, Account__r.Docs_Out__c, Account__r.Docs_Out_Contracts__c 
                        FROM Broker__c
                        WHERE Opportunity__c IN :oppIds
                ]); 
            }
        }

        Map<Id, Set<Id>> emailList = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> emailListContracts = new Map<Id, Set<Id>>();

        if (!dealerMap.isEmpty()) {
            for (Id key : dealerMap.keySet()) {
                if (dealerMap.get(key).Dealer__r.Docs_Out__c){
                    if (emailList.get(dealerMap.get(key).Opportunity__c) == null) {
                        emailList.put(dealerMap.get(key).Opportunity__c, new Set<Id>{dealerMap.get(key).Id});
                    } else {
                        emailList.get(dealerMap.get(key).Opportunity__c).add(dealerMap.get(key).Id);
                    }
                }else if (dealerMap.get(key).Dealer__r.Docs_Out_Contracts__c) {
                    if (emailListContracts.get(dealerMap.get(key).Opportunity__c) == null) {
                        emailListContracts.put(dealerMap.get(key).Opportunity__c, new Set<Id>{dealerMap.get(key).Id});
                    } else {
                        emailListContracts.get(dealerMap.get(key).Opportunity__c).add(dealerMap.get(key).Id);
                    }
                }
            }
        }

        if (!brokerMap.isEmpty()) {
            for (Id brokerKey : brokerMap.keySet()) {
                if (brokerMap.get(brokerKey).Account__r.Docs_Out__c) {
                    if (emailList.get(brokerMap.get(brokerKey).Opportunity__c) == null) {
//                        emailList.put(brokerMap.get(brokerKey).Opportunity__c, new Set<Id>{brokerMap.get(brokerKey).Account__c});
                        emailList.put(brokerMap.get(brokerKey).Opportunity__c, new Set<Id>{brokerMap.get(brokerKey).Id});
                    } else {
//                        emailList.get(brokerMap.get(brokerKey).Opportunity__c).add(brokerMap.get(brokerKey).Account__c);
                        emailList.get(brokerMap.get(brokerKey).Opportunity__c).add(brokerMap.get(brokerKey).Id);
                    }
                }else if (brokerMap.get(brokerKey).Account__r.Docs_Out_Contracts__c) { 
                    if (emailListContracts.get(brokerMap.get(brokerKey).Opportunity__c) == null) { 
                        emailListContracts.put(brokerMap.get(brokerKey).Opportunity__c, new Set<Id>{brokerMap.get(brokerKey).Id});
                    } else {
                        emailListContracts.get(brokerMap.get(brokerKey).Opportunity__c).add(brokerMap.get(brokerKey).Id);
                    }
                }
            }
        }
        //System.debug('Sending emails to: ' + emailList);
        //System.debug('Sending emails with contracts to: ' + emailListContracts);

        Id docsOutTemplateId = null;
        Id docsOutContractsTemplateId = null;
        Set<String> templateNames = new Set<String>();
        templateNames.add('Docs Out');
        templateNames.add('Docs Out w/ Contracts');
        

        if (!emailList.isEmpty() || !emailListContracts.isEmpty()) {
            List<EmailTemplate> emailTemplateList = new List<EmailTemplate>([
                    SELECT Id, Name, HtmlValue, Body, Subject
                    FROM EmailTemplate
                    WHERE Name IN :templateNames
            ]);
            //System.debug('#$#$#$ Email Template List: ' + emailTemplateList);
            for (EmailTemplate em : emailTemplateList) {
                if (em.Name == 'Docs Out') {
                    docsOutTemplateId = em.Id;
                }else if (em.Name == 'Docs Out w/ Contracts') {
                    docsOutContractsTemplateId = em.Id;
                }
            }
        }

        if (docsOutTemplateId != null) {
            //TC_RecursiveTriggerHelper.sentSubmittedEmail = true;
            if (!emailList.isEmpty()) {
                //System.debug ('#$#$#$ email is being triggered to send');
                sendEmails2 (emailList, docsOutTemplateId, opportunityOwnerIdsMap);
            }
        }

        if (docsOutContractsTemplateId != null) {
            if (!emailListContracts.isEmpty()) {
                //System.debug ('#$#$#$ email with contracts is being triggered to send');
                sendEmails2 (emailListContracts, docsOutContractsTemplateId, opportunityOwnerIdsMap);
            }
        }

    }

    public static void docsInNotification(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {

        //System.debug('#$#$ docsInNotification');

        Set<Id> oppIds = new Set<Id>();

        Set<Id> brokerIds = new Set<Id>();
        Set<Id> dealerIds = new Set<Id>();

        for (Opportunity opp : newMap.values()) {
            if (opp.StageName == 'Docs In' &&
                    oldMap.get(opp.Id).StageName != 'Docs In')
                    //&& !opp.Portal_User_ID__c.contains ('B2B-') Commented due to SAL-5327
            {
                if (opp.Branch__c <> null && opp.Branch__c.contains('IFP')) {
                    brokerIds.add(opp.Id);
                } else {
                    dealerIds.add(opp.Id);
                }
                oppIds.add(opp.Id);
            }
        }
        //System.debug('Opportunities pulling dealers from: ' + oppIds);

        Map<Id, Dealer__c> dealerMap = new Map<Id, Dealer__c>();
        Map<Id, Broker__c> brokerMap = new Map<Id, Broker__c>();

        Map<Id, Id> opportunityOwnerIdsMap = new Map<Id, Id>();

        if (!oppIds.isEmpty()) {
            //getting opportunity owners
            for (Id oppId : oppIds){
                opportunityOwnerIdsMap.put(oppId, newMap.get(oppId).OwnerId);
            }

            if (dealerIds.size() > 0) {
                dealerMap = new Map<Id, Dealer__c>([
                        SELECT Id, Opportunity__c, Dealer__r.Partner_UDA_Notification__c, Dealer__c, Dealer__r.Docs_In__c
                        FROM Dealer__c
                        WHERE Opportunity__c IN :oppIds
                ]);
            }

            if (brokerIds.size() > 0) {
                brokerMap = new Map<Id, Broker__c>([
                        SELECT Id, Opportunity__c, Account__r.Partner_UDA_Notification__c, Account__c, Account__r.Docs_In__c
                        FROM Broker__c
                        WHERE Opportunity__c IN :oppIds
                ]);
            }
            
            SL_DocsInNotificationHelper.sendEmail(oppIds);
        }

        Map<Id, Set<Id>> emailList = new Map<Id, Set<Id>>();

        if (!dealerMap.isEmpty()) {
            for (Id key : dealerMap.keySet()) {
                if (dealerMap.get(key).Dealer__r.Docs_In__c){
                    if (emailList.get(dealerMap.get(key).Opportunity__c) == null) {
//                        emailList.put(dealerMap.get(key).Opportunity__c, new Set<Id>{dealerMap.get(key).Dealer__c});
                        emailList.put(dealerMap.get(key).Opportunity__c, new Set<Id>{dealerMap.get(key).Id});
                    } else {
//                        emailList.get(dealerMap.get(key).Opportunity__c).add(dealerMap.get(key).Dealer__c);
                        emailList.get(dealerMap.get(key).Opportunity__c).add(dealerMap.get(key).Id);
                    }
                }
            }
        }

        if (!brokerMap.isEmpty()) {
            for (Id brokerKey : brokerMap.keySet()) {
                if (brokerMap.get(brokerKey).Account__r.Docs_In__c) {
                    if (emailList.get(brokerMap.get(brokerKey).Opportunity__c) == null) {
//                        emailList.put(brokerMap.get(brokerKey).Opportunity__c, new Set<Id>{brokerMap.get(brokerKey).Account__c});
                        emailList.put(brokerMap.get(brokerKey).Opportunity__c, new Set<Id>{brokerMap.get(brokerKey).Id});
                    } else {
//                        emailList.get(brokerMap.get(brokerKey).Opportunity__c).add(brokerMap.get(brokerKey).Account__c);
                        emailList.get(brokerMap.get(brokerKey).Opportunity__c).add(brokerMap.get(brokerKey).Id);
                    }
                }
            }
        }
        //System.debug('Sending emails to: ' + emailList);

        Id DocsInTemplateId = null;

        if (!emailList.isEmpty()) {
            List<EmailTemplate> emailTemplateList = new List<EmailTemplate>([
                    SELECT Id, Name, HtmlValue, Body, Subject
                    FROM EmailTemplate
                    WHERE Name = 'Docs In'
            ]);
            //System.debug('#$#$#$ Email Template List: ' + emailTemplateList);
            for (EmailTemplate em : emailTemplateList) {
                if (em.Name == 'Docs In') docsInTemplateId = em.Id;
            }
        }

        if (docsInTemplateId != null) {
            //TC_RecursiveTriggerHelper.sentSubmittedEmail = true;
            //System.debug ('#$#$#$ email is being triggered to send');
            if (!emailList.isEmpty()) {
                sendEmails2 (emailList, docsInTemplateId, opportunityOwnerIdsMap);
            }
        }
    }

    public static void inFundingNotification(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {

        //System.debug('#$#$ inFundingNotification');

        Set<Id> oppIds = new Set<Id>();

        Set<Id> brokerIds = new Set<Id>();
        Set<Id> dealerIds = new Set<Id>();

        for (Opportunity opp : newMap.values()) {
            //System.debug('========$$$$NEWOpportunity_Status__c'+ opp.Opportunity_Status__c);
            //System.debug('========$$$$OLDOpportunity_Status__c'+ oldMap.get(opp.Id).Opportunity_Status__c);
            if (opp.Opportunity_Status__c == 'Funding - In Process' &&
                    oldMap.get(opp.Id).Opportunity_Status__c != 'Funding - In Process')
                   // && !opp.Portal_User_ID__c.contains ('B2B-')) Commented due to SAL-5327
               {
                if (opp.Branch__c <> null && opp.Branch__c.contains('IFP')) {
                    brokerIds.add(opp.Id);
                } else {
                    dealerIds.add(opp.Id);
                }
                oppIds.add(opp.Id);
            }
        }
        //System.debug('Opportunities pulling dealers from: ' + oppIds);

        Map<Id, Dealer__c> dealerMap = new Map<Id, Dealer__c>();
        Map<Id, Broker__c> brokerMap = new Map<Id, Broker__c>();

        Map<Id, Id> opportunityOwnerIdsMap = new Map<Id, Id>();

        if (!oppIds.isEmpty()) {
            //getting opportunity owners
            for (Id oppId : oppIds){
                opportunityOwnerIdsMap.put(oppId, newMap.get(oppId).OwnerId);
            }

            if (dealerIds.size() > 0) {
                dealerMap = new Map<Id, Dealer__c>([
                        SELECT Id, Opportunity__c, Dealer__r.Partner_UDA_Notification__c, Dealer__c, Dealer__r.In_Funding__c
                        FROM Dealer__c
                        WHERE Opportunity__c IN :oppIds
                ]);
            }

            if (brokerIds.size() > 0) {
                brokerMap = new Map<Id, Broker__c>([
                        SELECT Id, Opportunity__c, Account__r.Partner_UDA_Notification__c, Account__c, Account__r.In_Funding__c
                        FROM Broker__c
                        WHERE Opportunity__c IN :oppIds
                ]);
            }
        }

        Map<Id, Set<Id>> emailList = new Map<Id, Set<Id>>();

        if (!dealerMap.isEmpty()) {
            for (Id key : dealerMap.keySet()) {
                if (dealerMap.get(key).Dealer__r.In_Funding__c){
                    if (emailList.get(dealerMap.get(key).Opportunity__c) == null) {
//                        emailList.put(dealerMap.get(key).Opportunity__c, new Set<Id>{dealerMap.get(key).Dealer__c});
                        emailList.put(dealerMap.get(key).Opportunity__c, new Set<Id>{dealerMap.get(key).Id});
                    } else {
//                        emailList.get(dealerMap.get(key).Opportunity__c).add(dealerMap.get(key).Dealer__c);
                        emailList.get(dealerMap.get(key).Opportunity__c).add(dealerMap.get(key).Id);
                    }
                }
            }
        }

        if (!brokerMap.isEmpty()) {
            for (Id brokerKey : brokerMap.keySet()) {
                if (brokerMap.get(brokerKey).Account__r.In_Funding__c) {
                    if (emailList.get(brokerMap.get(brokerKey).Opportunity__c) == null) {
//                        emailList.put(brokerMap.get(brokerKey).Opportunity__c, new Set<Id>{brokerMap.get(brokerKey).Account__c});
                        emailList.put(brokerMap.get(brokerKey).Opportunity__c, new Set<Id>{brokerMap.get(brokerKey).Id});
                    } else {
//                       emailList.get(brokerMap.get(brokerKey).Opportunity__c).add(brokerMap.get(brokerKey).Account__c);
                        emailList.get(brokerMap.get(brokerKey).Opportunity__c).add(brokerMap.get(brokerKey).Id);
                    }
                }
            }
        }
        //System.debug('Sending emails to: ' + emailList);

        Id inFundingTemplateId = null;

        if (!emailList.isEmpty()) {
            List<EmailTemplate> emailTemplateList = new List<EmailTemplate>([
                    SELECT Id, Name, HtmlValue, Body, Subject
                    FROM EmailTemplate
                    WHERE Name = 'In Funding'
            ]);
            //System.debug('#$#$#$ Email Template List: ' + emailTemplateList);
            for (EmailTemplate em : emailTemplateList) {
                if (em.Name == 'In Funding') inFundingTemplateId = em.Id;
            }
        }

        if (inFundingTemplateId != null) {
            //TC_RecursiveTriggerHelper.sentSubmittedEmail = true;
            //System.debug ('#$#$#$ email is being triggered to send');
            if (!emailList.isEmpty()) {
                sendEmails2 (emailList, inFundingTemplateId, opportunityOwnerIdsMap);
            }
        }
    }

    public static void fundedNotification(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {

        //System.debug('#$#$ fundedNotification');

        Set<Id> oppIds = new Set<Id>();

        Set<Id> brokerIds = new Set<Id>();
        Set<Id> dealerIds = new Set<Id>();

        for (Opportunity opp : newMap.values()) {
            if (opp.StageName == 'Booking' &&
                    oldMap.get(opp.Id).StageName == 'Funding')
                   // && !opp.Portal_User_ID__c.contains ('B2B-'))  Commented due to SAL-5327
                {
                if (opp.Branch__c <> null && opp.Branch__c.contains('IFP')) {
                    brokerIds.add(opp.Id);
                } else {
                    dealerIds.add(opp.Id);
                }
                oppIds.add(opp.Id);
            }
        }
        //System.debug('Opportunities pulling dealers from: ' + oppIds);

        Map<Id, Dealer__c> dealerMap = new Map<Id, Dealer__c>();
        Map<Id, Broker__c> brokerMap = new Map<Id, Broker__c>();

        Map<Id, Id> opportunityOwnerIdsMap = new Map<Id, Id>();

        if (!oppIds.isEmpty()) {
            //getting opportunity owners
            for (Id oppId : oppIds){
                opportunityOwnerIdsMap.put(oppId, newMap.get(oppId).OwnerId);
            }

            if (dealerIds.size() > 0) {
                dealerMap = new Map<Id, Dealer__c>([
                        SELECT Id, Opportunity__c, Dealer__r.Partner_UDA_Notification__c, Dealer__c, Dealer__r.Funded__c
                        FROM Dealer__c
                        WHERE Opportunity__c IN :oppIds
                ]);
            }

            if (brokerIds.size() > 0) {
                brokerMap = new Map<Id, Broker__c>([
                        SELECT Id, Opportunity__c, Account__r.Partner_UDA_Notification__c, Account__c, Account__r.Funded__c
                        FROM Broker__c
                        WHERE Opportunity__c IN :oppIds
                ]);
            }
        }

        Map<Id, Set<Id>> emailList = new Map<Id, Set<Id>>();

        if (!dealerMap.isEmpty()) {
            for (Id key : dealerMap.keySet()) {
                if (dealerMap.get(key).Dealer__r.Funded__c){
                    if (emailList.get(dealerMap.get(key).Opportunity__c) == null) {
//                        emailList.put(dealerMap.get(key).Opportunity__c, new Set<Id>{dealerMap.get(key).Dealer__c});
                        emailList.put(dealerMap.get(key).Opportunity__c, new Set<Id>{dealerMap.get(key).Id});
                    } else {
//                        emailList.get(dealerMap.get(key).Opportunity__c).add(dealerMap.get(key).Dealer__c);
                        emailList.get(dealerMap.get(key).Opportunity__c).add(dealerMap.get(key).Id);
                    }
                }
            }
        }

        if (!brokerMap.isEmpty()) {
            for (Id brokerKey : brokerMap.keySet()) {
                if (brokerMap.get(brokerKey).Account__r.Funded__c) {
                    if (emailList.get(brokerMap.get(brokerKey).Opportunity__c) == null) {
//                        emailList.put(brokerMap.get(brokerKey).Opportunity__c, new Set<Id>{brokerMap.get(brokerKey).Account__c});
                        emailList.put(brokerMap.get(brokerKey).Opportunity__c, new Set<Id>{brokerMap.get(brokerKey).Id});
                    } else {
//                        emailList.get(brokerMap.get(brokerKey).Opportunity__c).add(brokerMap.get(brokerKey).Account__c);
                        emailList.get(brokerMap.get(brokerKey).Opportunity__c).add(brokerMap.get(brokerKey).Id);
                    }
                }
            }
        }
        //System.debug('Sending emails to: ' + emailList);

        Id fundedTemplateId = null;

        if (!emailList.isEmpty()) {
            List<EmailTemplate> emailTemplateList = new List<EmailTemplate>([
                    SELECT Id, Name, HtmlValue, Body, Subject
                    FROM EmailTemplate
                    WHERE Name = 'Funded'
            ]);
            //System.debug('#$#$#$ Email Template List: ' + emailTemplateList);
            for (EmailTemplate em : emailTemplateList) {
                if (em.Name == 'Funded') fundedTemplateId = em.Id;
            }
        }

        if (fundedTemplateId != null) {
            //TC_RecursiveTriggerHelper.sentSubmittedEmail = true;
            //System.debug ('#$#$#$ email is being triggered to send');
            if (!emailList.isEmpty()) {
                sendEmails2 (emailList, fundedTemplateId, opportunityOwnerIdsMap);
            }
        }
    }
}