public with sharing class TC_OpportunityTriggerHandler extends SL_Trigger.baseHandler  {
    private Set<Id> oppsChangedApprovedAmount = new Set<Id>();
    private Set<Id> oppsAdvancedStageName = new Set<Id>();
    private Set<Id> oppsMovedToBooking = new Set<Id>();
    private Set<Id> oppsChangedSecDepPayments = new Set<Id>();
    private Set<Id> oppsChangedBookedTESD = new Set<Id>();
    private Set<Id> oppsChangedContractType = new Set<Id>();
    private Set<Id> oppsChangedLoanAmount = new Set<Id>();
    private Set<Id> oppsChangedMaxRate = new Set<Id>();
    private Set<Id> oppsChangedCompetitorPayoff = new Set<Id>();
    private Set<Id> oppsChangedRenewalPayoff = new Set<Id>();
    private Set<Id> oppsChangedOriginationAmount = new Set<Id>();
    private static Set<Id> oppsChangedInterimRent = new Set<Id>();
    private Map<Id, List<String>> fieldsChangedById = new Map<Id, List<String>>();
    private Set<Id> opportunityIds = new Set<Id>();
    Map<Id, Account> accounts = new Map<Id, Account>();
    Map<Id, Account> dealeraccounts = new Map<Id, Account>();
    Map<Id, Account> primaryBrokerAccounts = new Map<Id, Account>();
    Map<Id, User> owners = new Map<Id, User>();
    Map<Id, Contact> primaryContacts = new Map<Id, Contact>();
    Map<Id, User> dealerUsers = new Map<Id, User>();
    private Map<Id, Dealer__c> dealers = new Map<Id, Dealer__c>();
    private Map<Id, Broker__c> brokers = new Map<Id, Broker__c>();
    Map<Id, Guarantor__c> guarantors = new Map<Id, Guarantor__c>();
    Map<Id, List<TC_Origination__Checklist_Item_with_Attachments__c>> checklistItemsAttachments = new Map<Id, List<TC_Origination__Checklist_Item_with_Attachments__c>>();
    Map<Id, List<OpportunityContactRole>> contactRoles = new Map<Id, List<OpportunityContactRole>>();
    Map<Id, List<Asset__c>> assets = new Map<Id, List<Asset__c>>();
    Map<Id, List<Dealer__c>> dealersList = new Map<Id, List<Dealer__c>>();
    Map<Id, List<Miscellaneous_Invoice_Item__c>> miscInvoiceItems = new Map<Id, List<Miscellaneous_Invoice_Item__c>>();
    Map<Id, List<Blended_Income_Item__c>> blendedIncomeItems = new Map<Id, List<Blended_Income_Item__c>>();
    Map<Id, List<Miscellaneous_Billable_Item__c>> miscBillableItems = new Map<Id, List<Miscellaneous_Billable_Item__c>>();
    Map<Id, List<Variable_Payment__c>> variablePayments = new Map<Id, List<Variable_Payment__c>>();
    Map<Id, Franchisor__c> franchisors = new Map<Id, Franchisor__c>();
    User currentUser = new User();
    List<String> stagesToSetBranch = new List<String>{'Proposal', 'Lost', 'Decision', 'Funded/Booked', 'Funding (Loan)'};
    Boolean needsToSetBranch = false;
    private Map<Id, Id> mapRecordsToShare = new Map<Id, Id>();
    private Map<Id, Id> mapRecordsToRemoveSharing = new Map<Id, Id>();
    Map<Id, Asset__c> assetsToUpdateById = new Map<Id, Asset__c>();
    Map<Id, Blended_Income_Item__c> biisToUpdateById = new Map<Id, Blended_Income_Item__c>();
    private static final String OPP_SHARE_API_NAME = 'OpportunityShare';
    private SL_SharingCustomRecord shareRecords;
    Map<Id,User> assignedCreditUsers = new Map<Id,User>();
    @TestVisible
    private static String SITE_ID = System.Site.getSiteId();

    public override void beforeUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){
        checkUpdatedFields(oldMap, newMap);
        List<Opportunity> theList = new List<Opportunity>();
        for (Id opportunityId :newMap.keySet()){
            SObject theObject = newMap.get(opportunityId);
            getLookupMaps(theObject);
            theList.add((Opportunity)theObject);
        }
        TC_MoveToProposalStage.doAction((Map<Id, Opportunity>)oldMap,(Map<Id, Opportunity>)newMap);
        // have to replace these two calls with the ones below to make the interimRent for preffered work and fix any bug after that
        TC_DefaultFirstPymtAmtFromPymtAmt.defaultFirstPaymentAmountFromPaymentAmount(null, (Map<Id, Opportunity>)oldMap,(Map<Id, Opportunity>)newMap, ((Map<Id, Opportunity>)newMap).values());
        beforeChangesToSelf(theList, false, oldMap);

        TC_ValidationForManager.validationForManager((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);

        //Refactored From Trigger Actions
        TC_OpportunityDealerContactValidation.doAction((Map<Id, Opportunity>)oldMap,(Map<Id, Opportunity>)newMap, this.contactRoles);
        TC_LeadOutcomeChangeFromOpp.doAction((Map<Id, Opportunity>)oldMap,(Map<Id, Opportunity>)newMap);
        TC_OpportunityFieldUpdates.doAction((Map<Id, Opportunity>)oldMap,(Map<Id, Opportunity>)newMap, this.guarantors);
        // TC_PendingExceptionApprovalCheck.doAction((Map<Id, Opportunity>)oldMap,(Map<Id, Opportunity>)newMap);
        TC_ValidateChecklistDocsInReview.doAction((Map<Id, Opportunity>)oldMap,(Map<Id, Opportunity>)newMap);
        TC_StageToClearValidation.doAction((Map<Id, Opportunity>)oldMap,(Map<Id, Opportunity>)newMap, this.checklistItemsAttachments, this.oppsAdvancedStageName);
        TC_ValidateDocsRequestedChecklist.doAction((Map<Id, Opportunity>)oldMap,(Map<Id, Opportunity>)newMap);
        // replacing the below with calculation in SAL-4837
        // TC_OppBookingRuleClearInterimRent.doAction((Map<Id, Opportunity>)oldMap,(Map<Id, Opportunity>)newMap);
        TC_OpportunityCustomerTypeDefault.doAction((Map<Id, Opportunity>)oldMap,(Map<Id, Opportunity>)newMap, null, true);
        //End of Refactored from trigger actions

        TC_CheckPaymentsInArrearsBox.checkPaymentsInArrearsBox((Map<Id, Opportunity>)newMap, null);
        TC_ExpressOrtValidation.expressOrtValidation((Map<Id, Opportunity>)oldMap,(Map<Id, Opportunity>)newMap, null);
        TC_ReadyToDoc.readyToDoc((Map<Id, Opportunity>)oldMap,(Map<Id, Opportunity>)newMap);
        TC_DocsIn.docsIn((Map<Id, Opportunity>)oldMap,(Map<Id, Opportunity>)newMap);
        TC_DocsOut.docsOut((Map<Id, Opportunity>)oldMap,(Map<Id, Opportunity>)newMap);
        TC_DocumentDeliveryMethodValidation.documentDeliveryMethodValidation((Map<Id, Opportunity>)oldMap,(Map<Id, Opportunity>)newMap, this.dealersList);
        TC_ValidateEmailsForFunding.validateEmailsForFunding((Map<Id, Opportunity>)oldMap,(Map<Id, Opportunity>)newMap);
        TC_LeaseOpportunityDocsInStageValidation.leaseOpportunityDocsInStageValidation((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);
        TC_ValidateContactRolesOnReadyToDoc.validateContactRolesOnReadyToDoc((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap, this.contactRoles);
        TC_BeforeUpdate.beforeUpdate((Map<Id, Opportunity>)newMap, (Map<Id, Opportunity>)oldMap);
        //added by RajaSirivella SAL-4273 & $281
        TC_BeforeUpdate.BookingRulesCalGrossFinance((Map<Id, Opportunity>)newMap, (Map<Id, Opportunity>)oldMap);
        //end
        // TC_DefaultFirstPymtAmtFromPymtAmt.defaultFirstPaymentAmountFromPaymentAmount(null, (Map<Id, Opportunity>)oldMap,(Map<Id, Opportunity>)newMap, ((Map<Id, Opportunity>)newMap).values());
        TC_CalculateAssetCost.calculateAssetCost((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);
        TC_DefaultGrossContract.defaultGrossContract(null, (Map<Id, Opportunity>)oldMap,(Map<Id, Opportunity>)newMap, ((Map<Id, Opportunity>)newMap).values());
        TC_DefaultGrossFinance.defaultGrossFinance(null, (Map<Id, Opportunity>)oldMap,(Map<Id, Opportunity>)newMap, ((Map<Id, Opportunity>)newMap).values());
        TC_VariablePaymentsDefaultGrossContract.variablePaymentsDefaultGrossContract((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);
        TC_SetXRateFactor.setXRateFactor((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);
        TC_UpdatePaymentAmount.updatePaymentAmount((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);
        TC_SetPrimaryEmail.setPrimaryEmail((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap, this.contactRoles);
        TC_CheckManufacturer.checkManufacturer((Map<Id, Opportunity>)oldMap,(Map<Id, Opportunity>)newMap, this.assets);
        TC_SetLessorCode.setLessorCode((Map<Id, Opportunity>)oldMap,(Map<Id, Opportunity>)newMap);
        
        //added by RajaSirivella SAL-4274
        TC_SetLessorCode.populateInvoiceSection((Map<Id, Opportunity>)oldMap,((Map<Id, Opportunity>)newMap).values());
        //end
        TC_UpdateApprovedAmount.updateApprovedAmount((Map<Id, Opportunity>)oldMap,(Map<Id, Opportunity>)newMap);
        TC_CheckAssociatedDealersAreApproved.checkAssociatedDealersAreApproved((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap, this.dealers, this.brokers, this.franchisors);
        TC_CheckGuarantorSSNsWhenBookingStage.checkGuarantorSSNsWhenBookingStage((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap, this.guarantors);
        TC_CreditDecision.runRules((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);
        TC_CheckPrimaryDealerWhenBookingStage.checkPrimaryDealerWhenBookingStage((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);
        TC_CheckWhenBeyondDocsRequested.checkWhenBeyondDocsRequested((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);
        TC_SetRecordTypeAfterResubmit.setRecordTypeAfterResubmit((Map<Id, Opportunity>)oldMap,(Map<Id, Opportunity>)newMap);
        // TC_SetOppApprovalEmailMergeFields.setOppApprovalEmailMergeFields((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);
        TC_SetPaymentFrequencyByDeferralPayments.setPaymentFrequencyByDeferralPayments((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);
        TC_PopulateOpenExternalStips.populateOpenExternalStips((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);
        TC_ValidationTitledRequiredFields.validationTitledRequiredFields((Map<Id, Opportunity>)oldMap,(Map<Id, Opportunity>)newMap);
        TC_ValidationTaxIdRequiredFields.validationTaxIdRequiredFields((Map<Id, Opportunity>)oldMap,(Map<Id, Opportunity>)newMap);
        // TC_SetXRateFactor.setXRateFactor((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);
        TC_SetBillingPrimaryContactInfo.setBillingPrimaryContactInfo((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap, this.contactRoles);
        TC_CheckVariablePayments.checkVariablePayments((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);
        TC_CheckForBillingContact.checkForBillingContact((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);
        TC_CheckAssetFieldsWhenBookingStage.checkAssetFieldsWhenBookingStage((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);
        TC_CheckPaymentsWhenBookingStage.checkPaymentsWhenBookingStage((Map<Id, Opportunity>)oldMap,(Map<Id, Opportunity>)newMap);
        TC_ValidateCreditChecklistDocsIn.validateCreditChecklistDocsIn((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);
        TC_ValidateChkListReadyToDocChkBox.validateCreditChecklistReadyToDocCheckbox((Map<Id, Opportunity>)oldMap,(Map<Id, Opportunity>)newMap);
        TC_ValidateEmailageResults.validateEmailageResults((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap, this.primaryContacts, this.guarantors);
      TC_OpportunityTriggerHandlerRefactor.beforeUpdate((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap, (Map<id, Account>) accounts); //SAL-4124
      TC_CreateApprovedOffers.setOfferMadeByDealer((Map<Id, Opportunity>)oldMap, ((Map<Id, Opportunity>)newMap).values()); //DP-250
    }
    public override void beforeInsert(List<SObject> newList){
        List<Opportunity> theList = new List<Opportunity>();
        for(SObject theObject :newList){
            getLookupMaps(theObject);
            theList.add((Opportunity)theObject);
        }
        TC_CheckPaymentsInArrearsBox.checkPaymentsInArrearsBox(null, (List<Opportunity>) newList);
        TC_ExpressOrtValidation.expressOrtValidation(null, null, (List<Opportunity>) newList);
        // on next iteration, move the below call to immediatelly after getInfoFromOthers and add the isNew parameter so it only runs on insert
        TC_SetAccountBillingAddressFields.setAccountBillingAddressFields((List<Opportunity>) newList);
        TC_DefaultFirstPymtAmtFromPymtAmt.defaultFirstPaymentAmountFromPaymentAmount((List<Opportunity>) newList, null,null,null);
        TC_DefaultGrossContract.defaultGrossContract((List<Opportunity>) newList, null,null,null);
        TC_DefaultGrossFinance.defaultGrossFinance((List<Opportunity>) newList, null,null,null);
        TC_SetLessorCode.setLessorCode((List<Opportunity>) newList);
        //added by RajaSirivella SAL-4274
        TC_SetLessorCode.populateInvoiceSection(new Map <Id, Opportunity>(), (List<Opportunity>) newList);
        //end
        TC_OpportunityTriggerHandlerRefactor.beforeInsert((List<Opportunity>) newList, (Map<Id, Account>) accounts);//SAL-4124
        
        beforeChangesToSelf(theList, true, new Map<Id, SObject>());
        TC_OpportunityCustomerTypeDefault.doAction(null,null, (List<Opportunity>) newList, false);// DP-1945 Misael Romero
    }
    
    public override void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){
        TC_ResubmissionToCreditDetailsHandler.doAction((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);
        TC_SendLoanNotifications.doAction((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);
        TC_OppDeferralChangedUpdateRateFactor.doAction((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);
        TC_SendFraudReviewEmail.doAction((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);
        if(CheckRecursive.runOnce()){
            TC_AfterUpdate.afterUpdate((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);
            TC_LeaseFundingStage.leaseFundingStage((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);   
            TC_AddPointsReviewForBooking.addPointsReviewForBooking((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);  
            //Rajesh Kumar(LTIMindtree)-Below commented code is not required as per SAL-5396
            //TC_UpdateCaseCenterApplicationStatus.updateCaseCenterApplicationStatus((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);  
            //TC_UpdateCaseCenterPKNumber.updateCaseCenterPKNumber((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);      
            TC_AutoCreateLoanPaymentRecords.autoCreateLoanPaymentRecords((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);          
            TC_CalculateDocFee.calculateDocFee((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);       
            TC_CDR014.runRule((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);      
            TC_CDR018Asset.runRule((Map<Id, Opportunity>)newMap);  
            TC_TriggerUtilMarket.setDLGOutOfMarket((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);
            TC_CreditLeaseStipsChanged.updateStipulations((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);
            TC_SendDealerNotification.scheduleSubmissionNotification((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);
            TC_SendDealerNotification.scheduleApprovalNotification((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);    
            TC_SendDealerNotification.docsOutNotification((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);    
            TC_SendDealerNotification.docsInNotification((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);    
            TC_SendDealerNotification.inFundingNotification((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);    
            TC_SendDealerNotification.fundedNotification((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);    
            // Vinod Rathod(LTIMindtree) User Story: SAL-4872
            PEAC_CreditStipsChecklistItem.deleteRemovedChecklistItem((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);
            //Added by Rajesh Kumar(LTIMindtree) User Story:SAL-5368
            PEAC_SubmitPotralLoanApplication.submitPortalApp((Map<Id, Opportunity>)newMap,(Map<Id, Opportunity>)oldMap);
        
        }
        TC_CreateApprovedOffers.createApprovedOffers((Map<Id, Opportunity>)oldMap, ((Map<Id, Opportunity>)newMap).values());
        TC_SendDealerNotification.scheduleMoreInfoNotification((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap);    
        TC_SendDealerNotification.scheduleDeclinedNotification((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap); 
        TC_OpportunityTriggerHandlerRefactor.afterUpdate((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap, (Map<Id, Account>) accounts); //SAL-4124   
        checkUpdatedFields(oldMap, newMap);
        for (Id opportunityId :newMap.keySet()){
            SObject theObject = newMap.get(opportunityId);
            getLookupMaps(theObject);
        }
        afterChangesToOthers(newMap, false, oldMap);
        TC_AddBlendedIncomeItems.addBlendedIncomeItems((Map<Id, Opportunity>)newMap, this.oppsMovedToBooking, this.blendedIncomeItems, oppsChangedInterimRent, this.dealers);
        TC_ChangedToDocsRequested.changedToDocsRequested((Map<Id, Opportunity>)oldMap, (Map<Id, Opportunity>)newMap, assets, assetsToUpdateById);
        checkDealerUser((List<Opportunity>)newMap.values(),(Map<Id, Opportunity>) oldMap, false, this.dealerUsers);
        // SL_OpportunityTriggerHandler.commitAssetUpdates(assetsToUpdateById);// SAL-5486 Misael Romero
        if(assetsToUpdateById.keySet().size() > 0){// will replace this with commitAssetUpdates when SAL-5486 can be promoted
            update assetsToUpdateById.values();
        }
        // Changes for SAL-5464
Map<Id, SObject> oldLoanRecordMap = new Map<Id, SObject>();
        Map<Id, SObject> newLoanRecordMap = new Map<Id, SObject>();
        //set<Id> oppIdSet = new  set<Id>();
        // using formula field to get the current profile name
        String profileName = newMap.values().size()>0? ((Opportunity)newMap.values()[0]).Opportunity_CurrentUser_Profile__c: null;// SAL-5468 Misael Romero
        RescoreIsMandatoryForLoan__c validationInfo = RescoreIsMandatoryForLoan__c.getInstance('Docs Requested');
        //List<string> stageList = (validationInfo?.StageName__c ?? '').split(';');
        // List<string> profileList = (validationInfo?.ProfileName__c ?? '').split(';');
        
        List<String> stageList = new List<String>();
        List<String> profileList = new List<String>();
        
        // Safely split and trim stage and profile names
        if (validationInfo != null) {
            stageList = (validationInfo.StageName__c ?? '').split(';');
            profileList = new List<String>();
            for (String p : (validationInfo.ProfileName__c ?? '').split(';')) {
                profileList.add(p.trim());
            }
        }
        
        
        for(Opportunity opp : (List<Opportunity>) newMap.values()) {
            string oldStage = ((Opportunity)oldMap.get(opp.Id)).StageName;
            string newStage = ((Opportunity)newMap.get(opp.Id)).StageName;
            // if(profileName != null && (!profileList.contains(profileName)) && oldStage == 'Proposal' && stageList.contains(newStage) && opp.Scored_Field_Modified__c) {
            
            if (profileName != null && !profileList.contains(profileName.trim()) && oldStage == 'Proposal' && stageList.contains(newStage) && opp.Scored_Field_Modified__c && opp.Loan_Record_Type__c) 
            {
                newMap.get(opp.Id).addError('One or more fields used for scoring or rescoring the application have been modified. The application must be resubmitted.');
            }
            
            system.debug('oldStage<<>>'+ oldStage);
            system.debug('newStage<<>>'+ newStage);
            system.debug('profileList<<>>'+ profileList);
            if(opp.Loan_Record_Type__c) {
                oldLoanRecordMap.put(opp.Id,oldMap.get(opp.Id));
                newLoanRecordMap.put(opp.Id,newMap.get(opp.Id));
            }
        }
        /*for(Field_Tracker__c trackObj : [select Id, Opportunity__c from Field_Tracker__c where ID IN :oppIdSet]) {
            newMap.get(trackObj.Opportunity__c).addError('You can not change the status');
        }*/
        if(!newMap.isEmpty() && !oldMap.isEmpty()) {
            FieldChangeTracker.TrackerWrapper trackerDetails = new FieldChangeTracker.TrackerWrapper();
            trackerDetails.newRecordMap = newMap;
            trackerDetails.oldRecordMap = oldMap;
            trackerDetails.objectApiName = 'Opportunity';
            FieldChangeTracker.trackDetails(trackerDetails);
        }
        //Changes for SAL-5464
    }
    
    public override void afterInsert(Map<Id, SObject> newMap){
        TC_CreateOpportunityBeneficialOwners.createOpportunityBeneficialOwners((Map<Id, Opportunity>)newMap);
        TC_TriggerUtilMarket.setDLGMarketPosition((Map<Id, Opportunity>)newMap);
        TC_AfterInsert.afterInsert(((Map<Id, Opportunity>)newMap).values());
        TC_OpportunityTriggerHandlerRefactor.afterInsert(((Map<Id, Opportunity>)newMap).values(), (Map<Id, Account>) accounts);//SAL-4124
        afterChangesToOthers(newMap, true, new Map<Id, SObject>());
        checkDealerUser((List<Opportunity>)newMap.values(), null, true, this.dealerUsers);
        // SL_OpportunityTriggerHandler.commitAssetUpdates(assetsToUpdateById);// SAL-5486 Misael Romero
        if(assetsToUpdateById.keySet().size() > 0){// will replace this with commitAssetUpdates when SAL-5486 can be promoted
            update assetsToUpdateById.values();
        }
    }

    private void checkUpdatedFields(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){
        List<String> fieldsToCheck = null;
        if(Trigger.isBefore){
            fieldsToCheck = new List<String>{'Application__c', 'Application_Status__c',/* 'Assigned_Credit_User__c',*/ 'Bank_Statement_Status__c', 
            'Beginning_Maintenance_Fee_Amount__c', 'Commencement_Date__c', 'Contract_Type__c', 'Deferral_Payments__c', 'Equipment_Cost__c', 'First_Payment_Date__c', 
            'Funded__c', 'Invoice_Code__c', 'Lead_Invoice_Days__c', 'Lessor__c', 'Opportunity_Installed_Date__c', 'Opportunity_Status__c', 'of_ending_payments__c', 
            'Payment_Amount__c', 'Payment_Option__c',/* 'Program__c',*/'Program_Type__c', 'Purchase_Options__c', 'RecordTypeId', 'Resubmitted_to_Credit__c', 'StageName', 
            'Waive_Interim_Rent__c'};
        } else{// isAfter
            fieldsToCheck = new List<String>{'Application__c', 'Application_Status__c', 'Bank_Statement_Status__c', 'Beginning_Maintenance_Fee_Amount__c',
                'Commencement_Date__c', 'Contract_Type__c', 'Credit_Decision__c', 'Dealer_Account__c', 'Dealer_User__c', 'Deferral_Payments__c', 'Equipment_Cost__c', 'First_Payment_Date__c',
            'Funded__c', 'Opportunity_Booked_Date__c', 'Opportunity_Installed_Date__c', 'Opportunity_Status__c', 'of_ending_payments__c', 'OwnerId', 'Payment_Amount__c', 
            'Primary_Dealer__c', 'Program_Type__c', 'Purchase_Options__c', 'RecordTypeId', 'Resubmitted_to_Credit__c', 'StageName', 'Tax_Exempt__c', 
            'Waive_Interim_Rent__c'};
        } 
        for(Id opportunityId :newMap.keySet()){
            Opportunity opp = (Opportunity)newMap.get(opportunityId);
            Opportunity oldOpp = (Opportunity)oldMap.get(opportunityId);
            if(opp.Approved_Amount__c != oldOpp.Approved_Amount__c){
                this.oppsChangedApprovedAmount.add(opportunityId);
            }
            SL_TriggerUtil.findChangedFields(opportunityId, opp, oldOpp, fieldsChangedById, fieldsToCheck);
            List<String> fieldsChanged = fieldsChangedById.get(opp.Id);
            if(fieldsChanged != null && fieldsChanged.contains('StageName')){
                //this.oppsChangedStageName.add(opportunityId);
                Integer oldStageIndex = 0;
                Integer newStageIndex = 0;
                List<Schema.picklistEntry> allStages = Opportunity.stagename.getDescribe().getPicklistValues();
                for(Integer i = 0; i < allStages.size(); i++){
                    if(allStages[i].getValue() == oldOpp.StageName){
                        oldStageIndex = i;
                    }
                    if(allStages[i].getValue() == opp.StageName){
                        newStageIndex = i;
                    }
                }
                if(oldStageIndex < newStageIndex){
                    this.oppsAdvancedStageName.add(opportunityId);
                }
                if(opp.StageName == 'Booking'&& oldOpp.StageName =='Funding'){
                    this.oppsMovedToBooking.add(opportunityId);
                }
            }
            if(stagesToSetBranch.contains(opp.StageName)){
                this.needsToSetBranch = true;
            }
            if(opp.Sec_Dep_Pymts__c != oldOpp.Sec_Dep_Pymts__c){
                this.oppsChangedSecDepPayments.add(opportunityId);
            }
            if(opp.Booked_to_External_System_Date__c != oldOpp.Booked_to_External_System_Date__c){
                this.oppsChangedBookedTESD.add(opportunityId);
            }
            if(opp.Contract_Type__c != oldOpp.Contract_Type__c){
                this.oppsChangedContractType.add(opportunityId);
            }
            if(opp.Loan_Amount__c != oldOpp.Loan_Amount__c){
                this.oppsChangedLoanAmount.add(opportunityId);
            }
            if(opp.Max_Rate__c != oldOpp.Max_Rate__c){
                this.oppsChangedMaxRate.add(opportunityId);
            }
            if(opp.Competitor_Payoff_Amount__c != oldOpp.Competitor_Payoff_Amount__c){
                this.oppsChangedCompetitorPayoff.add(opportunityId);
            }
            if(opp.Renewal_Payoff_Amount__c != oldOpp.Renewal_Payoff_Amount__c){
                this.oppsChangedRenewalPayoff.add(opportunityId);
            }
            if(opp.Origination_Amount__c != oldOpp.Origination_Amount__c){
                this.oppsChangedOriginationAmount.add(opportunityId);
            }
        }
    }

    private void getLookupMaps(SObject obj){
        Opportunity opp = (Opportunity)obj;
        if(opp.AccountId != null){
            this.accounts.put(opp.AccountId, new Account());
        }
        if(opp.Dealer_Account__c <> null){
            
            this.dealeraccounts.put(opp.Dealer_Account__c, new Account());
        }
        if(opp.Primary_Dealer__c != null){
            this.dealers.put(opp.Primary_Dealer__c, new Dealer__c());
        }
        if(opp.OwnerId != null){
            this.owners.put(opp.OwnerId, new User());
        }
        if(opp.Primary_Contact__c != null){
            this.primaryContacts.put(opp.Primary_Contact__c, new Contact());
        }
        if(opp.Dealer_User__c != null){
            this.dealerUsers.put(opp.Dealer_User__c, new User());
        }
        if(opp.Id != null){
            this.opportunityIds.add(opp.Id);
            this.contactRoles.put(opp.Id, new List<OpportunityContactRole>());
            this.assets.put(opp.Id, new List<Asset__c>());
            this.miscInvoiceItems.put(opp.Id, new List<Miscellaneous_Invoice_Item__c>());
            this.blendedIncomeItems.put(opp.Id, new List<Blended_Income_Item__c>());
            this.variablePayments.put(opp.Id, new List<Variable_Payment__c>());
            this.miscBillableItems.put(opp.Id, new List<Miscellaneous_Billable_Item__c>());
        }
        //added by RajaSirivella
        if(opp.Primary_Dealer__c != null){
           this.dealersList.put(opp.Id, new List<Dealer__c>());
        }
        if(opp.Assigned_Credit_User__c!=null){
            this.assignedCreditUsers.put(opp.Assigned_Credit_User__c,new User());
        }
        //end
    }

    private void getInfoFromOthers(){
        if(opportunityIds.size() > 0){
            for(Opportunity related : [SELECT Id, Account.DBA__c, Account.Date_Established__c, Account.AnnualRevenue,
            Owner.Name, Owner.Vendor_Team__c,  Account.Tax_ID__c, Account.Business_Phone__c, Account.Id, Account.Business_Type__c, 
            Account.Private_Label_Documents__c, Dealer_Account__r.Private_Label_Documents__c,
            Primary_Broker__r.Account_Branch__c, Primary_Broker__r.Dealer_Number__c, Primary_Broker__r.CCAN__c,
            Dealer_Account__r.Name, Dealer_Account__r.Id, Assigned_Credit_User__r.Profile.Name, Assigned_Credit_User__r.XBS_Risk_Analyst__c, 
            Primary_Contact__r.Emailage_Result__c, Primary_Contact__r.Override_Emailage_Result__c, Dealer_User__r.IsActive, 
            Dealer_User__r.IsPortalEnabled, Dealer_User__r.Contact.AccountId, 
            (SELECT Id, Dealer__c, Dealer__r.Dealer_Number__c, Dealer__r.Account_Branch__c,
                Dealer__r.CCAN__c, Dealer__r.Business_Phone__c, Dealer__r.SAM__r.Vendor_Team__c, Dealer__r.Dealer_Tier__c,
                Dealer__r.Approved_Document_Delivery_Method__c, Dealer__r.Account_Dealer_Status__c,
                Dealer__r.Preferred_Dealer_Level__c, Dealer__r.Private_Label__c, Dealer__r.White_Label__c,
                Dealer__r.Account_Interim_Rent_Waived__c, Dealer__r.Interim_Rent_Dealer_Percentage__c,
                Primary_Dealer__c, Opportunity__c
                FROM Brokers__r
            ),
            (SELECT Id, Account__r.Dealer_Number__c, Account__r.CCAN__c, Broker_Dealer_Number__c,
                Account__r.Account_Branch__c, Account__r.Account_Dealer_Status__c, Primary_Broker__c, Opportunity__c
                FROM Brokers1__r
            ),
            (SELECT Id, Name, Contact_Name__c, Guarantor_Name__c, Type__c, Opportunity__c, RecordTypeId,
                Contact__r.Name, Contact__r.SSN__c, Contact__r.Emailage_Result__c, Contact__r.Override_Emailage_Result__c 
                FROM Guarantor__r
            ),
            (SELECT Id, Name, TC_Origination__Checklist_s_Opportunity__c, TC_Origination__Included__c,
                        TC_Origination__Is_Complete__c, TC_Origination__Stage_to_Clear__c,TC_Origination__Checklist__r.Checklist_Template_Name__c,TC_Origination__Checklist__r.TC_Origination__Status__c 
                FROM TC_Origination__Checklist_Items_with_Attachments__r
            ),
            (SELECT ID, Role, ContactId, IsPrimary, OpportunityId, Contact.Receive_All_Notifications__c, Contact.Email,
                Contact.Name, Contact.Emailage_Result__c, Contact.Override_Emailage_Result__c
                FROM OpportunityContactRoles ORDER BY CreatedDate ASC
            ),
            (SELECT Id, Franchisor__r.Account_Dealer_Status__c, Opportunity__c FROM Franchisors__r
            ),
            //SAL-4968   
            (SELECT Id, Manufacturer__c, Opportunity__c, Name, Asset_Description__c, Cost__c, 
            //(SELECT Id, Opportunity__c, Name, Asset_Description__c, Cost__c, 
                Opportunity_Contract_Type__c, List_Price__c, Orig_Cost__c, Upfront_County_Tax_Amount__c, 
                Upfront_City_Transit_Tax_Amount__c, Upfront_City_Tax_Amount__c, Upfront_County_Transit_Tax_Amount__c, 
                Upfront_State_Tax_Amount__c, Financed_Trigger__c 
                FROM Assets__r),
            (SELECT Id, GL_Code__c, Description__c, Interim_Percentage__c, Amount__c, Pay_Code__c, Generated_Code__c 
                FROM Miscellaneous_Invoice_Items__r),
            (SELECT Id, Opportunity__c, Blended_Income_Code__c, Blended_Income_Amount__c, Generated_Code__c 
                FROM Blended_Income_Items__r),
            (SELECT Id,CreatedDate from Variable_Payments__r ORDER BY createddate DESC),
            (SELECT Id, Generated_Code__c FROM Miscellaneous_Billable_Items__r) 
            FROM Opportunity WHERE Id IN:opportunityIds
            ]){
                if(this.accounts.get(related.AccountId) != null){
                    this.accounts.put(related.AccountId, related.Account);
                }
                if(dealeraccounts.get(related.Dealer_Account__c) != null){
                    dealeraccounts.put(related.Dealer_Account__c, related.Dealer_Account__r);
                }
                if(this.owners.get(related.OwnerId) != null){
                    this.owners.put(related.OwnerId, related.Owner);
                }
                if(this.primaryContacts.get(related.Primary_Contact__c) != null){
                    this.primaryContacts.put(related.Primary_Contact__c, related.Primary_Contact__r);
                }
                if(this.assignedCreditUsers.get(related.Assigned_Credit_User__c)!=null){
                    this.assignedCreditUsers.put(related.Assigned_Credit_User__c,related.Assigned_Credit_User__r);
                }
                if(this.dealerUsers.get(related.Dealer_User__c)!=null){
                    this.dealerUsers.put(related.Dealer_User__c, related.Dealer_User__r);
                }
                List<Dealer__c> relatedDealers = new List<Dealer__c>();
                for(Dealer__c dealerWithInfo: related.Brokers__r){
                    this.dealers.put(dealerWithInfo.Id, dealerWithInfo);
                    relatedDealers.add(dealerWithInfo);
                }
                for(Broker__c brokerWithInfo: related.Brokers1__r){
                    this.brokers.put(brokerWithInfo.Id, brokerWithInfo);
                }
                for(Guarantor__c guarantorWithInfo: related.Guarantor__r){
                    this.guarantors.put(guarantorWithInfo.Id, guarantorWithInfo);
                }
                List<TC_Origination__Checklist_Item_with_Attachments__c> relatedCliaWithInfo = new List<TC_Origination__Checklist_Item_with_Attachments__c>();
                for(TC_Origination__Checklist_Item_with_Attachments__c cliaWithInfo: related.TC_Origination__Checklist_Items_with_Attachments__r){
                    relatedCliaWithInfo.add(cliaWithInfo);
                }
                this.checklistItemsAttachments.put(related.Id, relatedCliaWithInfo);
                //added by Rajasirivella
                this.dealersList.put(related.Id,  relatedDealers);
                //end
                for(Franchisor__c franchisorWithInfo: related.Franchisors__r){
                    this.franchisors.put(franchisorWithInfo.Id, franchisorWithInfo);
                }
                List<OpportunityContactRole> relatedContactRoles = new List<OpportunityContactRole>();
                for(OpportunityContactRole ocr:related.OpportunityContactRoles){
                    relatedContactRoles.add(ocr);
                }
                this.contactRoles.get(related.Id).addAll(relatedContactRoles);
                List<Miscellaneous_Invoice_Item__c> relatedMiis = new List<Miscellaneous_Invoice_Item__c>();
                for(Miscellaneous_Invoice_Item__c mii:related.Miscellaneous_Invoice_Items__r){
                    relatedMiis.add(mii);
                }
                this.miscInvoiceItems.get(related.Id).addAll(relatedMiis);
                List<Blended_Income_Item__c> relatedBiis = new List<Blended_Income_Item__c>();
                for(Blended_Income_Item__c bii:related.Blended_Income_Items__r){
                    relatedBiis.add(bii);
                }
                this.blendedIncomeItems.get(related.Id).addAll(relatedBiis);
                this.variablePayments.get(related.Id).addAll(related.Variable_Payments__r);// it is supposed to only be one per Opp
                List<Asset__c> relatedAssets = new List<Asset__c>();
                for(Asset__c theAsset:related.Assets__r){
                    relatedAssets.add(theAsset);
                }
                this.assets.get(related.Id).addAll(relatedAssets);
                if(brokers.size() == 0 && related.Primary_Broker__c != null){
                    this.primaryBrokerAccounts.put(related.Primary_Broker__c, new Account(Account_Branch__c = related.Primary_Broker__r.Account_Branch__c,
                    Dealer_Number__c = related.Primary_Broker__r.Dealer_Number__c, CCAN__c = related.Primary_Broker__r.CCAN__c));
                }
                List<Miscellaneous_Billable_Item__c> relatedMbis = new List<Miscellaneous_Billable_Item__c>();
                for(Miscellaneous_Billable_Item__c mbi:related.Miscellaneous_Billable_Items__r){
                    relatedMbis.add(mbi);
                }
                this.miscBillableItems.get(related.Id).addAll(relatedMbis);
            }
            
        }
        if(Trigger.isBefore && this.accounts.size() > 0 && SL_TriggerUtil.checkForMissingInfo(this.accounts.values())){
            this.accounts.putAll([SELECT Id, DBA__c, Date_Established__c, AnnualRevenue,
                Tax_ID__c, Business_Phone__c, Business_Type__c, Private_Label_Documents__c
                FROM Account WHERE Id IN :this.accounts.keySet()]);
        }
        if(Trigger.isBefore && this.dealers.size() > 0  && SL_TriggerUtil.checkForMissingInfo(this.dealers.values())){
            this.dealers.putAll([SELECT Id, Dealer__c, Dealer__r.Dealer_Number__c, Dealer__r.Account_Branch__c,
                Dealer__r.CCAN__c, Dealer__r.Business_Phone__c, Dealer__r.SAM__r.Vendor_Team__c, Dealer__r.Dealer_Tier__c,
                Dealer__r.Approved_Document_Delivery_Method__c, Dealer__r.Preferred_Dealer_Level__c,
                Dealer__r.Private_Label__c, Dealer__r.White_Label__c, Dealer__r.Account_Interim_Rent_Waived__c,
                Dealer__r.Interim_Rent_Dealer_Percentage__c,
                Primary_Dealer__c, Opportunity__c
                FROM Dealer__c WHERE Id IN :this.dealers.keySet()]);
        }
        if(Trigger.isBefore && this.owners.size() > 0  && needsToSetBranch && SL_TriggerUtil.checkForMissingInfo(this.owners.values())){
            this.owners.putAll([SELECT Id, Name, Vendor_Team__c
                FROM User WHERE Id IN :this.owners.keySet()]);
        }
        if(Trigger.isBefore && this.primaryContacts.size() > 0 && SL_TriggerUtil.checkForMissingInfo(this.primaryContacts.values())){
            this.primaryContacts.putAll([SELECT Id, Emailage_Result__c, Override_Emailage_Result__c
                FROM Contact WHERE Id IN :this.owners.keySet()]);
        }
        if(this.dealerUsers.size() > 0 && SL_TriggerUtil.checkForMissingInfo(this.dealerUsers.values())){
            this.dealerUsers.putAll([SELECT Id, IsActive, IsPortalEnabled, Contact.AccountId
                FROM User WHERE Id IN :this.dealerUsers.keySet()]);
        }
        
        if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
            this.currentUser = [SELECT Id, Name, Contact.AccountId, Contact.Account.OwnerId, Contact.Account.Dealer_Tier__c, IsPortalEnabled, Contact.Account.Pre_Delivery__c, Contact.Account.Account_Branch__c FROM User WHERE Id = :System.UserInfo.getUserId()];
        }
    }

    private void beforeChangesToSelf(List<Opportunity> newList, Boolean isNew, Map<Id, SObject> oldMap){
        getInfoFromOthers();
        for (Opportunity opp :newList){
            // SAL-5464 condition for resubmit to credit checkbox is checked we have to make Scored_Field_Modified__c false
            Opportunity oldOpp = (oldMap != null) ? (Opportunity) oldMap.get(opp.Id) : null;
            Boolean becameTrue = (oldOpp == null && opp.Resubmitted_to_Credit__c == true)
                || (oldOpp != null && !oldOpp.Resubmitted_to_Credit__c && opp.Resubmitted_to_Credit__c == true);
            if (becameTrue) {
                opp.Scored_Field_Modified__c = false;
            }

        
        
            List<String> fieldsChanged = this.fieldsChangedById.get(opp.Id);
            User dealerUser = this.dealerUsers.get(opp.Dealer_User__c);
            if(this.dealers.size() > 0 && opp.Primary_Dealer__c == null){
                for(Dealer__c theDealer: dealers.values()){
                    if(theDealer.Opportunity__c == opp.Id && theDealer.Primary_Dealer__c){
                        opp.Primary_Dealer__c = theDealer.Id;
                        break;
                    }
                }
            }
            if(this.dealers.size() == 0 && opp.Primary_Dealer__c != null){
                opp.Primary_Dealer__c = null;
            }
            Broker__c primaryBroker = null;
            if(this.brokers.size() > 0){
                for(Broker__c theBroker: brokers.values()){
                    if(theBroker.Opportunity__c == opp.Id && theBroker.Primary_Broker__c){
                        opp.Primary_Broker__c = theBroker.Account__c;
                        primaryBroker = theBroker;
                        break;
                    }
                }
            }
            if(this.brokers.size() == 0 && opp.Primary_Broker__c != null){
                opp.Primary_Broker__c = null;
            }
            String exceededToleranceMessage = '';
            exceededToleranceMessage = SL_OpportunityTriggerHandler.validateApprovedAmountVsEquipmentCost(opp, fieldsChanged, 
                oppsAdvancedStageName, dealers, false);
            Boolean isToleranceExceeded = exceededToleranceMessage != '';
            Boolean isOppRescoringWhenOver = SL_OpportunityTriggerHandler.rescoreOverTolerance(opp, fieldsChanged, isToleranceExceeded, 
                false, oppsAdvancedStageName, dealers);// SAL-4104 Misael Romero
            if(isToleranceExceeded && !isOppRescoringWhenOver){
                opp.addError(exceededToleranceMessage);
            }
            setBranch(opp, primaryBroker);
            securityDepositCalculationFormerFlow(opp, isNew, fieldsChanged);
            setRepayAmountNDisbursementFormerFlow(opp, isNew, fieldsChanged);
            bankStatementChangeStageFormerFlow(opp);
            setDealerUser(opp, isNew);
            setPrivateLabel(opp);
            setFunded(opp);
            SL_OpportunityTriggerHandler.calculateInterimRent(opp, fieldsChanged, dealers, oppsMovedToBooking, oppsChangedInterimRent);
            SL_OpportunityTriggerHandler.applicationFromSF(opp, isNew, currentUser);
            SL_OpportunityTriggerHandler.addDealerAcc(opp, dealers);
             // commented code as per SAL-4865 
            // setBlindContractValue(opp, dealers);
            TC_SetOppApprovalEmailMergeFields.setOppApprovalEmailMergeFields(opp, fieldsChanged, guarantors);
            SL_OpportunityTriggerHandler.setLessorCode(opp, assignedCreditUsers, fieldsChanged);
            SL_OpportunityTriggerHandler.setGLLink(opp);
            SL_OpportunityTriggerHandler.stampDaysMetteredOpp(opp);
            SL_OpportunityTriggerHandler.setSubmittedDate(opp, isNew, fieldsChanged);// SAL-5297 Misael Romero
            SL_OpportunityTriggerHandler.removeInactiveDealerUser(opp, dealerUser);// DP-1615 Misael Romero
            SL_OpportunityTriggerHandler.populateInvoiceDataFormerFlow(opp, isNew, fieldsChanged);// SAL-3883 Misael Romero
            SL_OpportunityTriggerHandler.removeDealerAccountUser(opp, isNew, fieldsChanged, oldMap, dealerUser);// DP-1860 Misael Romero
        }
    }

    private void afterChangesToOthers(Map<Id, SObject> newMap, Boolean isNew, Map<Id, SObject> oldMap){
        getInfoFromOthers();
        List<Miscellaneous_Invoice_Item__c> upsertMiscInvoiceList = new List<Miscellaneous_Invoice_Item__c>();
        List<Variable_Payment__c> lstVariablePayments = new List<Variable_Payment__c>();
        Map<Id, List<Opportunity>> mapOppByDealerAcc = new Map<Id, List<Opportunity>>();
        List<Miscellaneous_Billable_Item__c> miscBillablesToInsert = new List<Miscellaneous_Billable_Item__c>();
        Map<Id, List<String>> emailTemplatesByOppId = new Map<Id, List<String>>();
        List<Id> idsToRescore = new List<Id>();
        Set<String> removedDealerIds = new Set<String>();
        Set<Id> removedDealerUserIds = new Set<Id>();
        String actionForBiis = '';
        for (SObject obj :newMap.values()){
            Opportunity opp = (Opportunity)obj;
            List<String> fieldsChanged = fieldsChangedById.get(opp.Id);
            if(!isNew){ //afterUpdate 
                SL_OpportunityTriggerHandler.sendStatusChangeEmailAlert(opp, fieldsChanged);
                TC_PopulateAssetListPrice.populateAssetListPrice(opp, fieldsChanged, this.assets, assetsToUpdateById);
                generateTaxMatrixFormerFlow(opp, fieldsChanged, isNew);
                TC_UpdateDataFundingToBooking.updateDataFundingToBooking(opp, oppsMovedToBooking, this.dealers, this.miscInvoiceItems, upsertMiscInvoiceList, oppsChangedInterimRent);
                //SAL-4916
                //SL_OpportunityTriggerHandler.sendXBSEmailAlert(opp,assignedCreditUsers,fieldsChanged);
                TC_CreateUpdateVariablePaymentRecord.createUpdateVariablePaymentRecord(opp, this.variablePayments, fieldsChanged, lstVariablePayments);
                SL_OpportunityTriggerHandler.UCCFees(opp, this.miscInvoiceItems, upsertMiscInvoiceList, fieldsChanged, this.blendedIncomeItems);
                // SAL-5293 Misael Romero
                TC_AutoCreateMiscBillableItems.autoCreateMiscBillableItems(opp, this.oppsMovedToBooking, this.miscBillableItems, miscBillablesToInsert);
            }
            mapOppByDealerAcc = SL_OpportunityTriggerHandler.checkUpdatedDealerAcc(opp, mapOppByDealerAcc, isNew, fieldsChanged, oldMap, removedDealerIds, removedDealerUserIds);
            // SAL-5133 Misael Romero
            emailTemplatesByOppId = SL_OpportunityTriggerHandler.emailAlertsFormerWorkFlows(opp, isNew, fieldsChanged, emailTemplatesByOppId);
            // SAL-4104 Misael Romero
            Boolean isOppRescoringWhenOver = SL_OpportunityTriggerHandler.rescoreOverTolerance(opp, fieldsChanged, false, true, oppsAdvancedStageName, dealers);
            if(isOppRescoringWhenOver){
                idsToRescore.add(opp.Id);
            }
            // SL_OpportunityTriggerHandler.rescoreWhenPrimaryDealerChanges(opp, fieldsChanged, idsToRescore);// SAL-5432 Misael Romero
            // SL_OpportunityTriggerHandler.bulkUpdateAssetsFromFlows(opp, isNew, fieldsChanged, this.assets, this.assetsToUpdateById);// SAL-5486 Misael Romero
            // actionForBiis = SL_OpportunityTriggerHandler.bookingRulesDepreciationDatesFormerFlow(opp, isNew, fieldsChanged, this.blendedIncomeItems, this.biisToUpdateById);// SAL-5486 Misael Romero
        }
        if (!upsertMiscInvoiceList.isEmpty()){
            upsert upsertMiscInvoiceList;
        }
        if (!lstVariablePayments.isEmpty()){
            upsert lstVariablePayments;
        }
        if(!TC_RecursiveTriggerHelper.oppAlreadyShared 
        && (mapOppByDealerAcc.keySet().size() > 0 || removedDealerIds.size() > 0 || removedDealerUserIds.size() > 0)){
            SL_OpportunityTriggerHandler.OppShare(mapOppByDealerAcc, removedDealerIds, removedDealerUserIds);
        }
        if(miscBillablesToInsert.size() > 0){
            insert miscBillablesToInsert;
        }
        if(biisToUpdateById.values().size() > 0){
            update biisToUpdateById.values();
        }
        if(emailTemplatesByOppId.values().size() > 0){// SAL-5133 Misael Romero
            if(System.isQueueable()){
                SL_EmailAlertsFormerWorkFlowsQ.sendAlerts(emailTemplatesByOppId);
            }else{
                System.enqueueJob(new SL_EmailAlertsFormerWorkFlowsQ(emailTemplatesByOppId));
            }
        }
        if(idsToRescore.size() > 0){// SAL-4104 Misael Romero
            if(System.isQueueable()){
                TC_GdsScoreCtrl.callGdsPb(idsToRescore);
            }else{
                System.enqueueJob(new SL_RescoreOverToleranceQ(idsToRescore));
            }
        }
    }

    void setBranch(Opportunity opp, Broker__c primaryBroker){
        if(stagesToSetBranch.contains(opp.StageName)){
            String primaryBrokerNumber = primaryBroker != null && primaryBroker.Account__r != null?
                primaryBroker.Account__r.Dealer_Number__c: 
                (primaryBrokerAccounts.get(opp.Primary_Broker__c) != null? primaryBrokerAccounts.get(opp.Primary_Broker__c).Dealer_Number__c: '');
            switch on primaryBrokerNumber {
                when '603294.1420' {
                    opp.Branch__c ='Arboretum';
                }
                when '800813.4620' {
                    opp.Branch__c ='Lending Tree';
                }
                when else {
                    Boolean hasCloudStoreDealer = false;
                    for(Dealer__c theDealer : dealers.values()){
                        if(theDealer.Opportunity__c == opp.Id && theDealer.Dealer__r.Dealer_Number__c == '734895.5002'){
                            hasCloudStoreDealer = true;
                            break;
                        }
                    }
                    if(hasCloudStoreDealer){
                        opp.Branch__c ='Arrow';
                    }else{
                        String opportunityTeam = owners.get(opp.OwnerId).Vendor_Team__c;
                        if(opportunityTeam == 'DLG'){
                            opp.Branch__c ='NJ Retail';
                        }else{
                            Boolean hasBrokerDealer = false;
                            String brokerBranch = 'IFP - Indirect Funding Pl';
                            for(Dealer__c theDealer : dealers.values()){
                                if(theDealer.Opportunity__c == opp.Id && theDealer.Dealer__r.Account_Branch__c == brokerBranch){
                                    hasBrokerDealer = true;
                                    break;
                                }
                            }
                            if(!hasBrokerDealer){
                                for(Broker__c theBroker : brokers.values()){
                                    if(theBroker.Opportunity__c == opp.Id && theBroker.Account__r.Account_Branch__c == brokerBranch){
                                        hasBrokerDealer = true;
                                        break;
                                    }
                                }
                            }
                            if(hasBrokerDealer){
                                opp.Branch__c = brokerBranch;
                            }else{
                                Dealer__c primaryDealer = dealers.get(opp.Primary_Dealer__c);
                                Boolean hasPrimaryDealer = primaryDealer != null;
                                String hcBranch = 'Healthcare Division';
                                String ctiFieldBranch = 'CT&I Field';
                                String ctiTransportBranch = 'CT&I Field Transportation';
                                String ctiBranch = 'SNAP (National Accounts)';
                                String oegBranch = 'Office Equip Group-OEG';
                                String oegNCBranch = 'OEG Non-Copier';
                                if(opportunityTeam == 'HC' || (opportunityTeam == null 
                                    && hasPrimaryDealer && primaryDealer.Dealer__r.Account_Branch__c == hcBranch)){
                                    opp.Branch__c = hcBranch;
                                }else{
                                    String samUserTeam = hasPrimaryDealer && primaryDealer.Dealer__r.SAM__c != null? primaryDealer.Dealer__r.SAM__r.Vendor_Team__c: null;
                                    String ctifTeam = 'CTIF';
                                    Boolean isTitledEquipCode = opp.Equip_Code1__c != null? opp.Equip_Code1__c.containsIgnoreCase('Titled'): false;
                                    if((samUserTeam == ctifTeam
                                        || (opportunityTeam == null && hasPrimaryDealer && primaryDealer.Dealer__r.Account_Branch__c == ctiFieldBranch))){
                                        if(!isTitledEquipCode){
                                            opp.Branch__c = ctiFieldBranch;
                                        }else{
                                            opp.Branch__c = ctiTransportBranch;
                                        }
                                    }else{
                                        if(opportunityTeam == 'SNAP'
                                            || (samUserTeam == null && hasPrimaryDealer && primaryDealer.Dealer__r.Account_Branch__c == ctiBranch)){
                                            if(!isTitledEquipCode){
                                                opp.Branch__c = ctiBranch;
                                            }else{
                                                opp.Branch__c = 'TFG-Transportation Financ';
                                            }
                                        }else{
                                            if(opportunityTeam == 'OEG' || (opportunityTeam == null
                                            && hasPrimaryDealer && primaryDealer.Dealer__r.Account_Branch__c == oegBranch)){
                                                opp.Branch__c = oegBranch;
                                            }else{
                                                if(opportunityTeam == 'OEG NC' || (opportunityTeam == null
                                                && hasPrimaryDealer && primaryDealer.Dealer__r.Account_Branch__c == oegNCBranch)){
                                                    opp.Branch__c = oegNCBranch;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            system.debug('SITE_ID:'+SITE_ID+'currentUser'+currentUser +'  '+opp.Branch__c);
            if(SITE_ID != null && currentUser != null && currentUser.Id != null){
                if(opp.Branch__c <> null && opp.Branch__c.contains('OEG') && (String.isBlank(currentUser.Contact.Account.Pre_Delivery__c)  || currentUser.Contact.Account.Pre_Delivery__c == 'No')) {
                    opp.Opportunity_Funding_Type__c = 'D&A'; //DP-472
                } else {
                    opp.Opportunity_Funding_Type__c = 'Pre-delivery';
                }
            }
        }
    }

    void setPrivateLabel(Opportunity opp){
        Account parentAccount = this.dealeraccounts.get(opp.Dealer_Account__c);
        if(parentAccount <> null && parentAccount.Private_Label_Documents__c != opp.Private_Label_Documents__c){
            opp.Private_Label_Documents__c = parentAccount.Private_Label_Documents__c;
        }
    }

    void setFunded(Opportunity opp){
        if(this.oppsMovedToBooking.contains(opp.Id)){
            opp.Funded__c = System.Datetime.Now();
        }
    }

    void setDealerUser(Opportunity opp, Boolean isNew){
        system.debug('isNew:'+isNew+ '   '+opp.Branch__c);
        if(isNew && SITE_ID != null && currentUser != null && currentUser.Id != null){
            opp.Dealer_User__c = currentUser.Id;
            opp.Dealer_Account__c = currentUser.Contact.AccountId;
            opp.OwnerId = currentUser.Contact.Account.OwnerId;
            opp.Dealer_Tier__c  = currentUser.Contact.Account.Dealer_Tier__c;
            system.debug('Branch__c:'+currentUser.Contact.Account.Account_Branch__c+'  '+'   '+currentUser.Contact.Account.Pre_Delivery__c);
            
            opp.Portal_User_ID__c='DP-';
        }
        
    }

    void securityDepositCalculationFormerFlow(Opportunity opp, Boolean isNew, List<String> fieldsChanged){
        if(this.oppsChangedSecDepPayments.contains(opp.Id) || (fieldsChanged != null && fieldsChanged.contains('Payment_Amount__c'))){
            opp.Security_Deposit__c = opp.Sec_Dep_Pymts__c != null && opp.Payment_Amount__c != null?
                opp.Sec_Dep_Pymts__c * opp.Payment_Amount__c: 0;
        }
        if(opp.Funded__c != null && opp.Opportunity_Booked_Date__c == null && opp.StageName == 'Booking'){
            opp.Opportunity_Booked_Date__c = opp.Funded__c;
        }
        Account oppAccount = this.accounts.get(opp.AccountId);
        if(oppAccount != null && opp.DBA_Override__c == null && opp.AccountId != null && oppAccount.DBA__c != null
        && opp.Opportunity_CurrentUser_Profile__c != 'DataAdmin'){
            opp.DBA_Override__c = oppAccount.DBA__c;
        }
        // Commented By Rajesh LTIMindtree.SAL-5314
        /*if(fieldsChanged != null && fieldsChanged.contains('Lessor__c') && opp.Lessor__c != null){
            opp.Region__c = '000';
        }*/
        
        if(oppAccount != null){
            Id loanOppId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan Opportunity').getRecordTypeId();
            //Rajesh Kumar(Mindtree)-Commenting the below line because GDS will be updating Years in business
            /*Integer yearsInBusiness = oppAccount.Date_Established__c != null? Math.round(oppAccount.Date_Established__c.daysBetween(Date.today())/365): 0;
            if(opp.RecordTypeId == loanOppId && (opp.Years_in_Business__c == null || opp.Years_in_Business__c != yearsInBusiness)){
                opp.Years_in_Business__c = yearsInBusiness;
            }*/
            if(opp.RecordTypeId == loanOppId && opp.Annual_Revenue__c == null && oppAccount.AnnualRevenue != null){
                opp.Annual_Revenue__c = oppAccount.AnnualRevenue;
            }
        }
        Id loanFundingId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan Funding').getRecordTypeId();
        if(fieldsChanged != null && fieldsChanged.contains('Application_Status__c') && opp.Application_Status__c == 'Booked' && opp.Loan_Record_Type__c){
            opp.StageName = 'Funding (Loan)';
            opp.RecordTypeId = loanFundingId;
        }
        if(this.oppsChangedBookedTESD.contains(opp.Id) && opp.Booked_to_External_System_Date__c != null){
            opp.Application_Status__c = 'Booked';
        }
        if(opp.of_ending_payments__c != null && opp.of_ending_payments__c != 0 
        && opp.Payment_Amount__c != null  && opp.Payment_Amount__c != 0 && (isNew 
        || (fieldsChanged != null && (fieldsChanged.contains('of_ending_payments__c') || fieldsChanged.contains('Payment_Amount__c'))))){
            opp.Ending_Pymts_in_Advance__c = opp.of_ending_payments__c * opp.Payment_Amount__c;
        }else if(opp.of_ending_payments__c == null || opp.of_ending_payments__c == 0){
            opp.Ending_Pymts_in_Advance__c = 0;
        }
        if(this.oppsChangedContractType.contains(opp.Id)){
            List<String> contractTypesForTrue = new List<String>{'TL', 'XX', 'RL'};
            opp.Is_TL_RL_or_OL__c = contractTypesForTrue.contains(opp.Contract_Type__c);
        }
    }

    void setRepayAmountNDisbursementFormerFlow(Opportunity opp, Boolean isNew, List<String> fieldsChanged){
        if(opp.Loan_Record_Type__c){
            Boolean isNotBlankLoanAmount  = opp.Loan_Amount__c != null;
            Boolean isGTZeroLoanAmount = opp.Loan_Amount__c > 0;
            Boolean isNotBlankOrigAmnt = opp.Origination_Amount__c != null;
            Boolean changedStageName = fieldsChanged != null && fieldsChanged.contains('StageName');
            if(isNotBlankLoanAmount && opp.Max_Rate__c != null && isGTZeroLoanAmount
                && (isNew || (this.oppsChangedLoanAmount.contains(opp.Id) || this.oppsChangedMaxRate.contains(opp.Id) || opp.Repayment_Amount__c == null))){
                opp.Repayment_Amount__c = opp.Loan_Amount__c * opp.Max_Rate__c;
            }
            if(isNotBlankLoanAmount && isNotBlankOrigAmnt && isGTZeroLoanAmount
                && (isNew || (this.oppsChangedLoanAmount.contains(opp.Id)
                || this.oppsChangedOriginationAmount.contains(opp.Id) || changedStageName
                || this.oppsChangedRenewalPayoff.contains(opp.Id) || this.oppsChangedCompetitorPayoff.contains(opp.Id)
                || opp.Disbursement_Amount__c == null))){
                opp.Disbursement_Amount__c = opp.Loan_Amount__c - (isNotBlankOrigAmnt? opp.Origination_Amount__c: 0);
                List<String> bookingStages = new List<String>{'Review for Booking', 'Funding', 'Booking', 'Booking (Loan)',
                    'Funding (Loan)', 'Funded/Booked', 'Lost'};
                if(bookingStages.contains(opp.StageName)){
                    opp.Disbursement_Amount__c = opp.Disbursement_Amount__c 
                        - (opp.Renewal_Payoff_Amount__c != null? opp.Renewal_Payoff_Amount__c: 0)
                        - (opp.Competitor_Payoff_Amount__c != null? opp.Competitor_Payoff_Amount__c: 0);
                }
            }
        }
    }

    void bankStatementChangeStageFormerFlow(Opportunity opp){
        List<String> fieldsChanged = fieldsChangedById.get(opp.Id);
        Boolean changedBankStatement = fieldsChanged != null && fieldsChanged.contains('Bank_Statement_Status__c');
        if(opp.Loan_Record_Type__c && opp.Application_Status__c != 'Approved' && changedBankStatement){
            opp.StageName = opp.Bank_Statement_Status__c == 'Complete'? 'Decision': 'Application';
        }   
    }

    public static void generateTaxMatrixFormerFlow(Opportunity opp, List<String> fieldsChanged, Boolean isNew) {
        if(!System.isFuture() && !System.isBatch()){
            List<String> stagesForTaxMatrix = new List<String>{'Docs In', 'Funding', 'Booking'};
            if(!isNew && !opp.Loan_Record_Type__c && stagesForTaxMatrix.contains(opp.StageName)
                &&  (fieldsChanged != null && (fieldsChanged.contains('StageName')
                || fieldsChanged.contains('Purchase_Options__c')
                || fieldsChanged.contains('Contract_Type__c')))
                && !TC_RecursiveTriggerHelper.oppsAlreadyTaxMatrixRan.contains(opp.Id)){
                TC_RecursiveTriggerHelper.oppsAlreadyTaxMatrixRan.add(opp.Id);
                List<Id> oppIds = new List<Id>{opp.Id};
                if(!Test.isRunningTest()){
                    // TC_TAX.TaxRules.runAutoGenerate(oppIds);
                }
            }
        }
    }

    private void checkDealerUser(List<Opportunity> lstNewOpp, Map<Id, Opportunity> mapOldOpp, Boolean isInsert, Map<Id, User> dealerUsers){
      shareRecords = new SL_SharingCustomRecord();
      Map<Id, Opportunity> mapOppWithDealerUser = new Map<Id, Opportunity>();
      for(Opportunity opp :lstNewOpp){
        Opportunity oldOpp = mapOldOpp?.get(opp.Id);
        User dealerUser = dealerUsers.get(opp.Dealer_User__c);
        if(dealerUser != null && dealerUser.IsPortalEnabled){
        shareRecords.checkRecordToShareOrRemove(opp, oldOpp, isInsert, this.mapRecordsToShare, this.mapRecordsToRemoveSharing);
        }

        if(opp.Dealer_User__c != null && isInsert){
          mapOppWithDealerUser.put(opp.Id, opp);
        }else if(!isInsert && opp.Dealer_User__c != oldOpp.Dealer_User__c){
          mapOppWithDealerUser.put(opp.Id, opp);
        }
      }

      if(!this.mapRecordsToShare.isEmpty() || !this.mapRecordsToRemoveSharing.isEmpty()){
        shareRecordToDealer();
      }

      if(!mapOppWithDealerUser.isEmpty()){
        setDealerUserOnChecklist(mapOppWithDealerUser);
        setDealerUserOnDocuSign(mapOppWithDealeruser);//added by Varun
      }
    }

    /*
    * @Description: DP-213 - Method to call the apex class to share the records with each Dealer_User__c.
    * History
    * <Date>      <Authors Name>     Description
      08/23/23   Jonathan Munguia   Initial Version.
    */
    public void shareRecordToDealer(){
        //docusign -added by Varun
        Map<Id, Id> mapDocusignToShare         = new Map<Id, Id>();
        Map<Id, Id> mapDocusignToRemoveSharing  = new Map<Id, Id>();
        
        for(dsfs__DocuSign_Status__c docusignStatus: [SELECT Id, dsfs__Opportunity__c, OwnerId FROM dsfs__DocuSign_Status__c 
                                                    WHERE dsfs__Opportunity__c IN :this.mapRecordsToShare.keySet()
                                                    OR dsfs__Opportunity__c IN :this.mapRecordsToRemoveSharing.keySet()]){
            Id oppId  = docusignStatus.dsfs__Opportunity__c;
            if(this.mapRecordsToShare.containsKey(oppId) && docusignStatus.OwnerId != this.mapRecordsToShare.get(oppId)){
            mapDocusignToShare.put(docusignStatus.Id, this.mapRecordsToShare.get(oppId));
            }else if(this.mapRecordsToRemoveSharing.containsKey(oppId) && docusignStatus.OwnerId != this.mapRecordsToRemoveSharing.get(oppId)){
            mapDocusignToRemoveSharing.put(docusignStatus.Id, this.mapRecordsToRemoveSharing.get(oppId));
            }                                               
        }//docusign
                                                        
     
      
      //docusign - added by Varun
      for(dsfs__DocuSign_Status__share dsShared :[SELECT ParentId, UserOrGroupId, AccessLevel, RowCause FROM dsfs__DocuSign_Status__Share
                                                      WHERE ParentId IN :mapDocusignToShare.keySet() AND UserOrGroupId IN :mapDocusignToShare.values()]){
        if(mapDocusignToShare.containsKey(dsShared.ParentId)){
          Id dealer = mapDocusignToShare.get(dsShared.ParentId);
          if(dsShared.UserOrGroupId == dealer && SL_SharingCustomRecord.rowCauseValues.contains(dsShared.RowCause)){
            mapDocusignToShare.remove(dsShared.ParentId);
          }
        }
      }//docusign
      

      For(OpportunityShare shared : [SELECT OpportunityId, UserOrGroupId, OpportunityAccessLevel, RowCause FROM OpportunityShare 
                                    WHERE OpportunityId IN :this.mapRecordsToShare.keySet() AND UserOrGroupId IN :this.mapRecordsToShare.values()]){
        if(this.mapRecordsToShare.containsKey(shared.OpportunityId)){
          Id dealer = this.mapRecordsToShare.get(shared.OpportunityId);
          if(shared.UserOrGroupId == dealer && SL_SharingCustomRecord.rowCauseValues.contains(shared.RowCause)){
            this.mapRecordsToShare.remove(shared.OpportunityId);
          }
        }
      }

      String shareAccess = 'Edit';
      for(Id key : this.mapRecordsToShare.keySet()){
        shareRecords.addRecordToList(OPP_SHARE_API_NAME, key, this.mapRecordsToShare.get(key), shareAccess, false, true);
      }
      
      for(Id key: this.mapRecordsToRemoveSharing.keySet()){
        shareRecords.addRecordToList(OPP_SHARE_API_NAME, key, this.mapRecordsToRemoveSharing.get(key), shareAccess, true, true);
      }
      shareRecords.commitRecords(OPP_SHARE_API_NAME, true);
      
      //docusign - added by Varun
      for(Id key: mapDocusignToShare.keySet()){
        shareRecords.addRecordToList('dsfs__DocuSign_Status__Share', key, mapDocusignToShare.get(key), shareAccess, false, false);
      }
      
      for(Id key: mapDocusignToRemoveSharing.keySet()){
        shareRecords.addRecordToList('dsfs__DocuSign_Status__Share', key, mapDocusignToRemoveSharing.get(key), shareAccess, true, false);
      }

        //end
      
         shareRecords.commitRecords('dsfs__DocuSign_Status__Share', false);//added by Varun
      
    }
    
    private void setDealerUserOnChecklist(Map<Id, Opportunity> mapOppWithDealerUser){
      List<TC_Origination__Checklist__c> lstChecklst = [SELECT Id, TC_Origination__Opportunity__c FROM TC_Origination__Checklist__c WHERE TC_Origination__Opportunity__c IN :mapOppWithDealerUser.keySet()];
      if(lstChecklst.isEmpty()){
        RETURN;
      }

      for(TC_Origination__Checklist__c chk : lstChecklst){
        chk.Dealer_User__c = mapOppWithDealerUser.get(chk.TC_Origination__Opportunity__c).Dealer_User__c;
      }

      UPDATE lstChecklst;
    }
    
    //added by Varun
   private void setDealerUserOnDocuSign(Map<Id, Opportunity> mapOppWithDealerUser){
      List<dsfs__DocuSign_Status__c> lstDocuSign = [SELECT Id, dsfs__Opportunity__c FROM dsfs__DocuSign_Status__c WHERE dsfs__Opportunity__c IN :mapOppWithDealerUser.keySet()];
      if(lstDocuSign.isEmpty()){
        RETURN;
      }

      for(dsfs__DocuSign_Status__c docusign : lstDocuSign){
        docusign.Dealer_User__c = mapOppWithDealerUser.get(docusign.dsfs__Opportunity__c).Dealer_User__c;
      }

      UPDATE lstDocuSign;
    }//end 
    
    private static void createShare (List<Opportunity> Ops){}
    // commented code as per SAL-4865 
    void setBlindContractValue(Opportunity opp, Map<Id, Dealer__c> dealers){
       /* Dealer__c primaryDealer = dealers.get(opp.Primary_Dealer__c);
        if(primaryDealer != null && primaryDealer.Dealer__c != null){
            if(primaryDealer.Dealer__r.Private_Label__c){
                opp.Blind_Contract__c = 'Private Label';
            }else{
                if(primaryDealer.Dealer__r.White_Label__c){
                    opp.Blind_Contract__c = 'White Label';
                }else{
                    opp.Blind_Contract__c = null;
                }
            }
        }*/
    }
  
    
}