/**
 * Created by trohweder on 1/20/21.
 *SAL-2172
 */

public without sharing class TC_SendLoanNotifications {

    public static void doAction(Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {


        if(TC_RecursiveTriggerHelper.sendLoanNotifications)return;
        TC_RecursiveTriggerHelper.sendLoanNotifications = true;


        //this is for regular updates that trigger notifications on salesforce
        System.debug('TC_SendLoanNotifications.notificationHandler');
        notificationHandler(newMap, oldMap);

    }

    public static void notificationHandler(Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap){

        //collection of opportunities from the newMap where Loan_Record_Type__c is True
        List<Opportunity> loanOpps = new List<Opportunity>();

        //get only loan record type opportunities and add to collection
        for (Opportunity opp : newMap.values()){
            if(opp.Loan_Record_Type__c){
                loanOpps.add(opp);
            }
        }

        if(loanOpps.size() > 0){
            System.debug(loanOpps.size() + ' Opportunities of Loan Type');

            //If there are loan opportunities they will get sorted into these maps and then their respective methods will be called
            //opportunities will be put into the declined map when their status is rejected, this map is named after the Declined notificaion center field.
            Map<Id, Opportunity> submittedMap = new Map<Id, Opportunity>();
            Map<Id, Opportunity> moreInfoMap = new Map<Id, Opportunity>();
            Map<Id, Opportunity> approvedMap = new Map<Id, Opportunity>();
            Map<Id, Opportunity> declinedMap = new Map<Id, Opportunity>();
            Map<Id, Opportunity> docsOutMap = new Map<Id, Opportunity>();
            Map<Id, Opportunity> docsInMap = new Map<Id, Opportunity>();
            Map<Id, Opportunity> fundedMap = new Map<Id, Opportunity>();

            //Check if the opportunity meets any email criteria and adding it to the appropriate map
            for (Opportunity opp : loanOpps){

                //If the CaseCenter__c field was updated from null SAL-2421
                //Also checks if a broker is added and it was created through a portal app
                //this was to fix issue SAL-2641 
                /*if((opp.CaseCenter__c != null && oldMap.get(opp.Id).CaseCenter__c == null) ||
                        (opp.No_of_Broker__c > 0 && oldMap.get(opp.Id).No_of_Broker__c == 0 && opp.Portal_User_ID__c != 'SF-')){
                    submittedMap.put(opp.Id, opp);
                }*/
                if((opp.CaseCenter__c != null && oldMap.get(opp.Id).CaseCenter__c == null) ||
                        (opp.No_of_Broker__c > 0 && oldMap.get(opp.Id).No_of_Broker__c == 0)){
                    submittedMap.put(opp.Id, opp);
                }

                //If the Application Status has been changed
                if(opp.Application_Status__c != oldMap.get(opp.Id).Application_Status__c){
                    System.debug('Application Status changed');
                    //SAL-2422
                    if(opp.Application_Status__c == 'More Info'){
                        moreInfoMap.put(opp.Id, opp);
                    }
                    //SAL-2423
                    else if(opp.Application_Status__c == 'Approved'){
                        approvedMap.put(opp.Id, opp);
                    }
                    //SAL-2424
                    else if(opp.Application_Status__c == 'Rejected' || opp.Application_Status__c == 'Automatically Declined' || opp.Application_Status__c == 'Declined'){
                        declinedMap.put(opp.Id, opp);
                    }
                }

                //If the Stage has been changed
                if(opp.StageName != oldMap.get(opp.Id).StageName){

                    //SAL-2425
                    if(opp.StageName == 'Docs Out'){
                        docsOutMap.put(opp.Id, opp);
                    }
                    //SAL-2426
                    else if(opp.StageName == 'Docs In'){
                        docsInMap.put(opp.Id, opp);
                    }
                    //SAL-2427
                    else if(opp.StageName == 'Funded/Booked'){
                        fundedMap.put(opp.Id, opp);
                    }
                }
            }
            //If any of the opportunities met the criteria proceed to the email alerts
            if(submittedMap.size() > 0){
                //send submitted emails SAL-2421
                
                //SAL-2701 do not schedule these emails for SF originated apps - send immediately!
                // Map<Id, Opportunity> sfApps = new Map<Id, Opportunity>();
                // Map<Id, Opportunity> nonSfApps = new Map<Id, Opportunity>();
                
                // for (Opportunity opp : submittedMap.values()) {
                    // if (opp.Portal_User_ID__c == 'SF-') {  // SAL-5496 Misael Romero, always enqueue
                    //     sfApps.put(opp.Id, opp);
                    // } else {
                        // nonSfApps.put(opp.Id, opp);
                    // }
                // }
                
                // if (nonSfApps.size() > 0) {
                    System.debug('Sending loan submitted emails for ' + submittedMap.size() + ' Opportunities');
                    try {
                        // SAL-5496 Misael Romero
                        if(System.isQueueable()){
                            checkNotificationCenter(submittedMap, 'Submitted_Loan__c', 'Loan Submitted');
                        }else{
                            System.enqueueJob(new SL_NotificationEmailQ(oldMap, submittedMap, 'Submitted Loan'));
                            // System.scheduleBatch(new TC_NotificationEmailBatch(oldMap, nonSfApps, 'Submitted Loan'), 'SubmittedLoan', 2);
                        }
                    } catch (Exception e) {
                        System.debug(LoggingLevel.ERROR, e.getMessage());
                    }
                // }
                
                // if (sfApps.size() > 0) {
                //     System.debug('Sending loan submitted emails for ' + sfApps.size() + ' Opportunities');
                //     checkNotificationCenter(sfApps, 'Submitted_Loan__c', 'Loan Submitted');
                // }
            }

            if(moreInfoMap.size() > 0){
                //send more info emails SAL-2422
                System.debug('Sending loan more info emails for ' + moreInfoMap.size() + ' Opportunities');
                checkNotificationCenter(moreInfoMap, 'More_Info_Loan__c', 'Loan More Info');
            }

            if(approvedMap.size() > 0){
                //send approved emails SAL-2423
                //Adding checklist stips to merge field for email
                List<Id> approvedOppIds = new List<Id>();
                approvedOppIds.addAll(approvedMap.keySet());
                TC_PopulateOppMergeFields.populateOppMergeFields(approvedOppIds);
                System.debug('Sending loan approved emails for ' + approvedMap.size() + ' Opportunities');
                checkNotificationCenter(approvedMap, 'Approved_Loan__c', 'Loan Approved');
            }

            if(declinedMap.size() > 0){
                //send rejected emails SAL-2424
                //As mentioned before declined and rejected the same in this context
                System.debug('Sending loan rejected emails for ' + declinedMap.size() + ' Opportunities');
                checkNotificationCenter(declinedMap, 'Declined_Loan__c', 'Loan Declined');
            }

            if(docsOutMap.size() > 0){
                //send docs out emails SAL-2425
                System.debug('Sending loan docs out emails for ' + docsOutMap.size() + ' Opportunities');
                checkNotificationCenter(docsOutMap, 'Docs_Out_Loan__c', 'Loan Docs Out');
            }

            if(docsInMap.size() > 0){
                //send docs in emails SAL-2426
                System.debug('Sending loan docs in emails for ' + docsInMap.size() + ' Opportunities');
                checkNotificationCenter(docsInMap, 'Docs_In_Loan__c', 'Loan Docs In');
            }

            if(fundedMap.size() > 0){
                //send funded emails SAL-2427
                System.debug('Sending loan funded emails for ' + fundedMap.size() + ' Opportunities');
                checkNotificationCenter(fundedMap, 'Funded_Loan__c', 'Loan Funded');
            }
        }
    }
    /**
     * This method will also call the send emails, it needs a map of Id opportunity, the notification center field name and the email template name
     * @param oppMap Map of Id, Opportunity
     * @param fieldToCheck Field that relates to the email in the Notification Center
     * @param templateName Name of the email template that will be used
     */
    public static void checkNotificationCenter(Map<Id, Opportunity> oppMap, String fieldToCheck, String templateName){

        //Map of owner Ids we need to send to with their opportunity as key
        Map<Id, Id> ownerIdMap = new Map<Id, Id>();
        Set<Id> primaryBrokersIds = new Set<Id>();
        Set<Id> noPrimaryBrokersIds = new Set<Id>();

                System.debug('oppMap SIZE ' + oppMap.keySet().size());

        for (Opportunity opp : oppMap.values()){
            ownerIdMap.put(opp.Id, opp.OwnerId);
            if(opp.Primary_Broker__c != null){
                primaryBrokersIds.add(opp.Primary_Broker__c);
            }
            else{
                noPrimaryBrokersIds.add(opp.Id);
            }
        }
        System.debug('primaryBrokersIds ' + primaryBrokersIds);
        //Pulling both the dealers and brokers that are related to the oppMap Opportunities with all of the Notification Center fields
        Map<Id, Dealer__c>dealerMap = new Map<Id, Dealer__c>([
                SELECT Id, Opportunity__c, Dealer__r.Partner_UDA_Notification__c, Dealer__c, Dealer__r.More_Info_Loan__c,
                Dealer__r.Submitted_Loan__c, Dealer__r.Approved_Loan__c, Dealer__r.Declined_Loan__c, Dealer__r.Docs_Out_Loan__c,
                Dealer__r.Docs_Out_Contracts_Loan__c, Dealer__r.Docs_In_Loan__c, Dealer__r.Funded_Loan__c
                FROM Dealer__c
                WHERE Opportunity__c IN :oppMap.keySet()
        ]);

        Map<Id, Broker__c>brokerMap = new Map<Id, Broker__c>([
            SELECT Id, Opportunity__c, Account__r.Partner_UDA_Notification__c, Account__c, Account__r.More_Info_Loan__c,
            Account__r.Submitted_Loan__c, Account__r.Approved_Loan__c, Account__r.Declined_Loan__c, Account__r.Docs_Out_Loan__c,
            Account__r.Docs_Out_Contracts_Loan__c, Account__r.Docs_In_Loan__c, Account__r.Funded_Loan__c
            FROM Broker__c
            WHERE Opportunity__c IN :oppMap.keySet() AND Account__c IN :primaryBrokersIds
        ]);

        Map<Id, Set<Id>> emailList = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> emailList2 = new Map<Id, Set<Id>>(); //adding another list to allow a second email template

        /*Here we loop through both dealers and brokers, we are checking if the account they are attached to has the
        Notification Center Field we passed in as param field to check. If we do we are putting them into the emaillist
        Map which is a map of OpportunityId, Broker/Dealer Ids. The Broker/Dealer Ids it maps to are only ones that are
        receiving the email*/
        if (!dealerMap.isEmpty()) {
            System.debug('dealerMap: ' + dealerMap);
            for (Id key : dealerMap.keySet()) {
                if((Boolean)dealerMap.get(key).Dealer__r.get(fieldToCheck)){
                    System.debug('dealer account gets notification');
                    if (emailList.get(dealerMap.get(key).Opportunity__c) == null) {
                        emailList.put(dealerMap.get(key).Opportunity__c, new Set<Id>{dealerMap.get(key).Id});
                    } else {
                        emailList.get(dealerMap.get(key).Opportunity__c).add(dealerMap.get(key).Id);
                    }
                } else if (fieldToCheck == 'Docs_Out_Loan__c' && (Boolean)dealerMap.get(key).Dealer__r.get('Docs_Out_Contracts_Loan__c')) { //SAL-3040 For Docs Out Notification, check if Docs Out with Contracts option is selected
                    if (emailList2.get(dealerMap.get(key).Opportunity__c) == null) {
                        emailList2.put(dealerMap.get(key).Opportunity__c, new Set<Id>{dealerMap.get(key).Id});
                    } else {
                        emailList2.get(dealerMap.get(key).Opportunity__c).add(dealerMap.get(key).Id);
                    }
                }
            }
        }

        if (!brokerMap.isEmpty()) {
            System.debug('brokerMap: ' + brokerMap);
            for (Id brokerKey : brokerMap.keySet()) {
                if(templateName == 'Loan Cancelled'){
                    if (emailList.get(brokerMap.get(brokerKey).Opportunity__c) == null) {
                        emailList.put(brokerMap.get(brokerKey).Opportunity__c, new Set<Id>{brokerMap.get(brokerKey).Id});
                    } else {
                        emailList.get(brokerMap.get(brokerKey).Opportunity__c).add(brokerMap.get(brokerKey).Id);
                    } 
                }
                else{
                    if ((Boolean)brokerMap.get(brokerKey).Account__r.get(fieldToCheck)) {
                        if (emailList.get(brokerMap.get(brokerKey).Opportunity__c) == null) {
                            emailList.put(brokerMap.get(brokerKey).Opportunity__c, new Set<Id>{brokerMap.get(brokerKey).Id});
                        } else {
                            emailList.get(brokerMap.get(brokerKey).Opportunity__c).add(brokerMap.get(brokerKey).Id);
                        } 
                    } else if (fieldToCheck == 'Docs_Out_Loan__c' && (Boolean)brokerMap.get(brokerKey).Account__r.get('Docs_Out_Contracts_Loan__c')) { //SAL-3040 For Docs Out Notification, check if Docs Out with Contracts option is selected
                        if (emailList2.get(brokerMap.get(brokerKey).Opportunity__c) == null) {
                            emailList2.put(brokerMap.get(brokerKey).Opportunity__c, new Set<Id>{brokerMap.get(brokerKey).Id});
                        } else {
                            emailList2.get(brokerMap.get(brokerKey).Opportunity__c).add(brokerMap.get(brokerKey).Id);
                        }                    
                    }
                }

            }
        }
        System.debug('Sending emails to: ' + emailList);


                    System.debug('noPrimaryBrokersIds: ' + noPrimaryBrokersIds);


        if(noPrimaryBrokersIds.size() > 0)
        {
            for(Opportunity opp : oppMap.values()){
                if(noPrimaryBrokersIds.contains(opp.Id))
                {
                    emailList.put(opp.Id, null);
                }
            }
        }

        Id emailTemplateId = null;

        if (!emailList.isEmpty() || !ownerIdMap.isEmpty()) {
            emailTemplateId = [
                    SELECT Id, Name
                    FROM EmailTemplate
                    WHERE Name = :templateName
                    LIMIT 1
            ]?.Id;
        }

        if (emailTemplateId != null) {
            System.debug ('#$#$#$ email is being triggered to send');
            sendLoanEmails (emailList, emailTemplateId, ownerIdMap);
        }
        
        //SAL-3040 For Docs Out Notification, use alternative email template for brokers/dealers who have selected the Contracts option
        if (fieldToCheck == 'Docs_Out_Loan__c' && emailList2.size() > 0) {
            System.debug('Sending emails with contracts to: ' + emailList2);
            
            Id emailTemplateId2 = null; //alternative template
            
            if (!emailList.isEmpty() || !ownerIdMap.isEmpty()) {
                emailTemplateId2 = [
                    SELECT Id, Name
                    FROM EmailTemplate
                    WHERE Name = 'Loan Docs Out w/ Contracts'
                    LIMIT 1
                ]?.Id;
            }
            
            if (emailTemplateId2 != null) {
                System.debug ('#$#$#$ email is being triggered to send');
                sendLoanEmails (emailList2, emailTemplateId2, ownerIdMap);
            }
        }
        
    }

    /**
     * called from the notification center check will get the appropriate contacts and send the email notifications
     * @param emailList Email list is a map of OpportunityId, Set Dealer/Broker Ids. These have been checked and are receiving emails;
     * @param templateId The Id of the email template to use
     * @param ownerIds Map of Opportunity Id, User Id to add the owner to the email being sent.
     */
    public static void sendLoanEmails(Map <Id, Set<Id>> emailList, Id templateId, Map<Id, Id> ownerIds){
        System.debug('**sendLoanEmails**');
        List <OrgWideEmailAddress> noreply = new List <OrgWideEmailAddress> ([SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address = 'wclinfo@peacsolutions.com']);
        Contact dummyContact = [SELECT Id FROM COntact WHERE Name = 'Dealer Repurchase DocGen DO NOT DELETE'];
        Map <Id, Set <Id>> oppContacts = new Map <Id, Set <Id>> ();
        Map<Id, User> opportunityOwnersMap = null;
        Map<Id, Contact> dealerBrokerContactMap = new Map<Id, Contact>();
		
        //Get Opportunity Owners
        opportunityOwnersMap = new Map<Id, User>([
                SELECT Id, Email
                FROM User
                WHERE Id IN :ownerIds.values()
        ]);
        
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>([
            SELECT Id, Name, Assigned_Credit_User__r.Email
                FROM Opportunity
                WHERE Id IN :ownerIds.keySet()
        ]);

        System.debug('sendLoanEmails opportunityMap' + opportunityMap.values().size() );
                System.debug('sendLoanEmails emailList' + emailList );

        //see lines 663 - 693 of TC_SendDealerNotifications for adding contact roles

        Set<String> contactRoleStringSet = new Set<String>{
                'Dealer Primary Contact', 'Dealer Sales Contact'
        };

        Set <Id> primaryDealerAndBrokerIdSet = new Set <Id> ();

        if(!emailList.isEmpty()){

            List<OpportunityContactRole> oppContactRoleList = new List<OpportunityContactRole>([
                    SELECT ContactId, OpportunityId
                    FROM OpportunityContactRole
                    WHERE OpportunityId IN:emailList.keySet ()
                    AND Role IN:contactRoleStringSet
                    AND Contact.Email != null
                    AND Contact.Email != ''
            ]);

            System.debug('oppContactRoleList: ' + oppContactRoleList);
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
            for (Id oppId : emailList.keySet()) {
                if(emailList.get(oppId) != null){
                    Set<Id> dbIds = emailList.get(oppId);
                    for (Id dbId : dbIds) {
                        primaryDealerIdSet.add(dbId);
                    }
                }
            }

            for (Id oppId : emailList.keySet()) {
                if(emailList.get(oppId) != null){
                    Set<Id> dealerAndBrokerIds = emailList.get(oppId);
                    for (Id dbId : dealerAndBrokerIds) {
                        primaryDealerAndBrokerIdSet.add(dbId);
                    }
                }
            }
        }

        System.debug('Dealer and broker Ids: ' + primaryDealerAndBrokerIdSet);

        Map<Id, Dealer__c>dealerMap = new Map<Id, Dealer__c>([SELECT Id, Dealer__c FROM Dealer__c WHERE Id IN :primaryDealerAndBrokerIdSet]);
        Map<Id, Broker__c>brokerMap = new Map<Id, Broker__c>([SELECT Id, Account__c FROM Broker__c WHERE Id IN :primaryDealerAndBrokerIdSet]);

                //Map<Id, AccountTeamMember> accountTeamMemberMap = new Map<Id, AccountTeamMember>([SELECT Id, AccountId, UserId, User.Email, TeamMemberRole FROM AccountTeamMember WHERE AccountId = :primaryDealerAndBrokerIdSet]);
       
        //It retrieves Account Team Members for the relatedBrokers SAL-5987
        Set<Id> brokerAccountIds = new Set<Id>();
        for (Broker__c br : brokerMap.values()) {
            if (br.Account__c != null) {
                brokerAccountIds.add(br.Account__c);
            }
        }

        List<AccountTeamMember> brokerAccountTeamList = [
            SELECT Id, AccountId, UserId, User.Email, TeamMemberRole
            FROM AccountTeamMember
            WHERE AccountId IN :brokerAccountIds
        ];


        //Map Email of Primary Broker Account by Opportunity
        Map<Id, Account> brokerAccountMap = new Map<Id, Account>(
            [SELECT Id, Owner.Email 
            FROM Account 
            WHERE Id IN :brokerAccountIds]
        );


        // Map EMAILS of Account Team Members by Opportunity
        Map<Id, List<String>> brokerTeamEmailsByOpp = new Map<Id, List<String>>();

        for (AccountTeamMember atm : brokerAccountTeamList) {
            for (Id oppId : emailList.keySet()) {
                // For each opportunity, check if its Broker.Account__c matches
                if (brokerMap.containsKey(emailList.get(oppId)?.iterator().next())) {

                    Id brokerAccountId = brokerMap.get(emailList.get(oppId).iterator().next()).Account__c;

                    if (atm.AccountId == brokerAccountId) {
                        if (!brokerTeamEmailsByOpp.containsKey(oppId)) {
                            brokerTeamEmailsByOpp.put(oppId, new List<String>());
                        }
                        if (atm.User.Email != null) {
                            brokerTeamEmailsByOpp.get(oppId).add(atm.User.Email);
                        }
                    }
                }
            }
        }
         System.debug('Account Team: ' + brokerAccountTeamList);
        // END SAL-5987


        Set<Id> accIds = new Set<Id>();
        if(!dealerMap.isEmpty()){
            for(Dealer__c dealer : dealerMap.values()){
                accIds.add(dealer.Dealer__c);
            }
        }
        if(!brokerMap.isEmpty()){
            for(Broker__c broker : brokerMap.values()){
                accIds.add(broker.Account__c);
            }
        }

        List <Contact> dbContacts;
        if (accIds.size() > 0) {
            dbContacts = new List<Contact>([
                    SELECT Id, AccountId, Email, Receive_All_Loan_Notifications__c,Account.SAM__r.Email, Account.Owner.Email
                    FROM Contact
                    WHERE AccountId IN :accIds AND Email != NULL
            ]);
        }
        System.debug('Dealer and Broker Contacts: ' + dbContacts);
        System.debug('Owner ' + opportunityOwnersMap);

        if (dbContacts != null){
            for (Contact c : dbContacts){
                //Check if the individual contact recieves all notifications
                System.debug('Contact ' + c.Id + ' receive notifications: ' + c.Receive_All_Loan_Notifications__c);

                for (Id key : emailList.keySet()){
                    if(emailList.get(key) != null){
                    for(Id dbId : emailList.get(key)){

                        if(dealerMap.get(dbId) != null && dealerMap.get(dbId).Dealer__c == c.AccountId){
                            if(c.Email != null && c.Receive_All_Loan_Notifications__c){
                                if (oppContacts.get(key) != null){
                                    oppContacts.get(key).add(c.Id);
                                } else {
                                    oppContacts.put(key, new Set <Id>{c.Id});
                                }
                            }
                        } else if (brokerMap.get(dbId) != null && brokerMap.get(dbId).Account__c == c.AccountId){
                            if(c.Email != null && c.Receive_All_Loan_Notifications__c){
                                if (oppContacts.get(key) != null){
                                    oppContacts.get(key).add(c.Id);
                                } else {
                                    oppContacts.put(key, new Set <Id>{c.Id});
                                }
                            }
                        }
                    }
                    }
                }
				dealerBrokerContactMap.put(c.Id, c);
            }
        }

        //SAL-3040 if emailTemplate is Docs Out with Contracts, get Contracts as Email attachments
        Map<Id, List<Messaging.EmailFileAttachment>> oppWithEmailAtts = new Map<Id, List<Messaging.EmailFileAttachment>>();
        
        Map<Id,Opportunity_Attachment__c> oAMap = new Map<Id,Opportunity_Attachment__c>([select Id,Opportunity__c from Opportunity_Attachment__c where Opportunity__c IN :emailList.keySet() AND (Dealer_Doc_Type__c = 'Approval Letter' OR Type__c = 'FS - Approval Letter' OR Type__c = 'Approval Letter') ORDER BY Createddate Desc]);
        System.debug('Varun::oAMap::'+oAMap);
        for(Attachment att : [select Id, Name,Body,ParentId from Attachment where ParentId IN :oAMap.keySet() ORDER BY Createddate Desc]) {
            string oppId = oAMap.get(att.ParentId).Opportunity__c;
            if(!oppWithEmailAtts.containsKey(oppId)) {
                List<Messaging.EmailFileAttachment> attachmentList = new List<Messaging.EmailFileAttachment>();
                Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
                
                attach.setContentType('application/pdf');
                attach.setFileName(att.Name);
                attach.setInline(false);
                attach.Body = att.Body;
                attachmentList.add(attach);
                oppWithEmailAtts.put(oppId,attachmentList);
            }
        }
        List<EmailTemplate> emailTemplateList = new List<EmailTemplate>();
        if (templateId != null) {
            emailTemplateList = [SELECT Id, Name FROM EmailTemplate WHERE Id = :templateId];
            if (emailTemplateList.size() == 1 && emailTemplateList[0].Name == 'Loan Docs Out w/ Contracts') {
                oppWithEmailAtts = TC_SendNotificationHelper.oppsWithEmailAttachments(emailList.keySet());
            }
        }

        //Get guarantors for More Info template

        Map<Id, Guarantor__c> oldestGuarantorByOpp = new Map<Id, Guarantor__c>();

        if (emailTemplateList.size() == 1 && emailTemplateList[0].Name == 'Loan More Info') {
            // Suppose opportunityIds is Set<Id> of the Opps you're processing
            List<Guarantor__c> allGuarantors = [
                SELECT Id, Opportunity__c, CreatedDate
                FROM Guarantor__c
                WHERE Opportunity__c IN :emailList.keySet() AND Type__c='Personal Guarantor'
                ORDER BY Opportunity__c, CreatedDate ASC
            ];

            // Map to hold the oldest guarantor per opportunity
            for (Guarantor__c g : allGuarantors) {
                // If we don't have one recorded yet for this Opportunity, add this one (oldest due to ordering)
                if (!oldestGuarantorByOpp.containsKey(g.Opportunity__c)) {
                    oldestGuarantorByOpp.put(g.Opportunity__c, g);
                }
            }
        }



        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        for (Id oppId : emailList.keySet()){
            //if(!oppContacts.isEmpty()){
                List<String> templatesWithAttachments = new List<String>{'Loan Approved'};
                List <String> bccAddresses = new List <String> ();
				List <String> ccAddresses = new List <String> ();

                if (Label.TC_DealerEmailsBCC.toLowerCase () != 'nobcc') bccAddresses = Label.TC_DealerEmailsBCC.split (';');



                // ############################# This is sending multiple email (one for each contact). Keep it commented unless logic changes.
                /*
                if(emailTemplateList[0].Name != 'Loan Declined' && emailTemplateList[0].Name != 'Loan More Info' && emailTemplateList[0].Name != 'Loan Cancelled' && emailTemplateList[0].Name !='Loan Approved'){
                    for (Id conId : oppContacts.get(oppId)){
                        Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
                        emailMessage.setWhatId(oppId);
                        emailMessage.setTargetObjectId (conId);
                        System.debug('Sending email to Contact: ' + conId);
                        emailMessage.setTemplateId(templateId);
                        if (!bccAddresses.isEmpty()) emailMessage.setBccAddresses(bccAddresses);
                        emailMessage.setToAddresses (new List <Id>{
                                conId
                        });
                        System.debug('Sent Emails to: ' + conId);
                        if(!oAMap.isEmpty() || (emailTemplateList.size() == 1 && emailTemplateList[0].Name == 'Loan Declined')) {
                            ccAddresses.add(opportunityMap.get(oppId).Assigned_Credit_User__r.Email);
                        } else {
                            ccAddresses.add('PartnerNotifications@peacsolutions.com');

                            
                            if(dealerBrokerContactMap.containsKey(conId) && dealerBrokerContactMap.get(conId).Account.SAM__r.Email <> null)
                                ccAddresses.add(dealerBrokerContactMap.get(conId).Account.SAM__r.Email);
                            if(dealerBrokerContactMap.containsKey(conId) && dealerBrokerContactMap.get(conId).Account.Owner.Email <> null)
                                ccAddresses.add(dealerBrokerContactMap.get(conId).Account.Owner.Email);
                        
                        }                         

                            emailMessage.setCcAddresses(ccAddresses);
                        
                        emailMessage.saveAsActivity = false;
                        if (!noreply.isEmpty()) emailMessage.setOrgWideEmailAddressId(noreply[0].Id);
                        
                        if(!oAMap.isEmpty() && oppWithEmailAtts.containskey(oppId) && emailTemplateList[0].Name != 'Loan Declined' && emailTemplateList[0].Name != 'Loan More Info' && emailTemplateList[0].Name != 'Loan Cancelled') {
                            emailMessage.setFileAttachments(oppWithEmailAtts.get(oppId));
                        }
                        //SAL-3040 if emailTemplate is Docs Out with Contracts, add attachments to email
                        if (emailTemplateList.size() == 1 && emailTemplateList[0].Name == 'Loan Docs Out w/ Contracts') {
                            List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
                            
                            //check if there were contracts returned for this oppId
                            if (oppWithEmailAtts.containsKey(oppId)){
                                for (Messaging.EmailFileAttachment efa : oppWithEmailAtts.get(oppId)) {
                                    emailAttachments.add(efa);
                                }
                                if (emailAttachments.size() > 0) {
                                    emailMessage.setFileAttachments(emailAttachments);
                                }
                            }
                        }
                        
                        emailsToSend.add(emailMessage);
                        System.debug('email message target object id con: ' + emailMessage.targetObjectId);
                    }
                } 
                */
                // #############################




                //This will be used to send a single email
                if(opportunityOwnersMap != null){
                    Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage ();
                    List<String> recipients = new List<String>{
                            opportunityOwnersMap.get(ownerIds.get(oppId)).Email
                    };
                    List<String> ownerEmail = new List<String>{
                            opportunityOwnersMap.get(ownerIds.get(oppId)).Email
                    };
                    System.debug('Sending email to Owner: ' + opportunityOwnersMap.get(oppId));


                    List<Id> conIds = new List<Id>(oppContacts.get(oppId));

                    if(!oppContacts.isEmpty()){
                        if(oppContacts.get(oppId) != null){
                            for(Id conId : oppContacts.get(oppId))
                            {
                                recipients.add(conId);
                            }
                        }
                    }

                    //Account Team Members
                    List<String> accountTeamMemberEmail = new List<String>(brokerTeamEmailsByOpp.get(oppId));
                    if(!accountTeamMemberEmail.isEmpty()){
                            for(String email : accountTeamMemberEmail)
                            {
                                if(!recipients.contains(email))recipients.add(email);
                            }                        
                    }

                    Id brokerAccountId; 
    
                    if(!brokerMap.isEmpty() && brokerMap.containsKey(emailList.get(oppId)?.iterator().next())){
                        Broker__c b = brokerMap.get(emailList.get(oppId).iterator().next());
                        if(b != null){
                            brokerAccountId= b.Account__c;
                        }
                    }

                    if (brokerAccountId != null && brokerAccountMap.containsKey(brokerAccountId)) {
                        String brokerOwnerEmail = brokerAccountMap.get(brokerAccountId).Owner.Email;

                        if (brokerOwnerEmail != null && !recipients.contains(brokerOwnerEmail)) {
                            recipients.add(brokerOwnerEmail);
                        }
                    }


                    emailMessage.setToAddresses(recipients);
                    emailMessage.setWhatId(oppId);
                    //List<Id> conIds = new List<Id>(oppContacts.get(oppId));
                    if(conIds.size()>0){
                        emailMessage.setTargetObjectId(conIds[0]);
                    } else{
                        emailMessage.setTargetObjectId(dummyContact.Id);
                    }
                    emailMessage.setTreatTargetObjectAsRecipient(false);
                    emailMessage.setTemplateId(templateId);
                    emailMessage.saveAsActivity = false;
                    if (!noreply.isEmpty()) emailMessage.setOrgWideEmailAddressId(noreply[0].Id);


                    //FOR Loan More Info Template
                    if(emailTemplateList.size() == 1 && (emailTemplateList[0].Name == 'Loan More Info' || emailTemplateList[0].Name == 'Loan Cancelled') ){
                        List<String> assignedCUs = new List<String>();
                        if(opportunityMap.get(oppId).Assigned_Credit_User__r.Email != null && emailTemplateList[0].Name != 'Loan Cancelled'){
                            assignedCUs.add(opportunityMap.get(oppId).Assigned_Credit_User__r.Email);
                            emailMessage.setToAddresses(assignedCUs);
                        }
                        else{
                            recipients.remove(0); //Remove owner email to set it as TO recipient
                            emailMessage.setToAddresses(ownerEmail);
                        }

                        emailMessage.setCcAddresses(recipients);                                               

                        //For Loan More Info we need to set Guarantor as WhatId
                        if(emailTemplateList[0].Name == 'Loan More Info'){
                            if(!oldestGuarantorByOpp.isEmpty())emailMessage.setWhatId(oldestGuarantorByOpp.get(oppId).Id);
                            oAMap.clear();
                        } 
                    }
                    
                    if(!oAMap.isEmpty() || (emailTemplateList.size() == 1 && (emailTemplateList[0].Name == 'Loan Declined' || emailTemplateList[0].Name =='Loan Approved'))) {

                        if(opportunityMap.get(oppId).Assigned_Credit_User__r.Email != null && emailTemplateList[0].Name != 'Loan Cancelled'){
                            ccAddresses.add(opportunityMap.get(oppId).Assigned_Credit_User__r.Email);
                            emailMessage.setCcAddresses(ccAddresses);
                        }
                    } 
                    if(!oAMap.isEmpty() && templatesWithAttachments.contains(emailTemplateList[0].Name)) {
                           emailMessage.setFileAttachments(oppWithEmailAtts.get(oppId));
                    }
                    //SAL-3040 if emailTemplate is Docs Out with Contracts, add attachments to email
                    if (emailTemplateList.size() == 1 && emailTemplateList[0].Name == 'Loan Docs Out w/ Contracts') {
                        List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
                        
                        //check if there were contracts returned for this oppId
                        if (oppWithEmailAtts.containsKey(oppId)){
                            for (Messaging.EmailFileAttachment efa : oppWithEmailAtts.get(oppId)) {
                                emailAttachments.add(efa);
                            }
                            if (emailAttachments.size() > 0) {
                                emailMessage.setFileAttachments(emailAttachments);
                            }
                        }
                    }
                    
                    emailsToSend.add(emailMessage);

                }
                if (emailsToSend.size() > 0) {
                   // emailsToSend.get(0).setCcAddresses(new List<String>{'PartnerNotifications@peacsolutions.com'});
                }


            //}
        }

        System.debug('>>>>> emailList: ' + emailsToSend.size ());
        for(Messaging.SingleEmailMessage email  : emailsToSend){
                    System.debug('>>>>> EMAIL: ' + email.getToAddresses() +'  ' + email.getCcAddresses());

        }
        if (!emailsToSend.isEmpty()) {
            Messaging.SendEmailResult[] results = new List<Messaging.SendEmailResult>();
            if (!Test.isRunningTest()) {
                try {
                   results = Messaging.sendEmail(emailsToSend);
                //if(emailTemplateList[0].Name != 'Loan Cancelled') results = Messaging.sendEmail(emailsToSend);

                } catch (Exception e) {
                    System.debug ('Error while sending dealer emails: ' + e + ' ' + results);
                }
            }
        }
    }
}