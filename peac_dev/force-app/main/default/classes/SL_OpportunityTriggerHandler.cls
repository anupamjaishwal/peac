public with sharing class SL_OpportunityTriggerHandler {

  public static void addDealerAcc(Opportunity opp, Map<Id, Dealer__c> dealers){
    Dealer__c pDealer = dealers.get(opp.Primary_Dealer__c);
    if(pDealer != null){
      Id dealerAccountBefore = opp.Dealer_Account__c;
      if(opp.Dealer_Account__c == null || opp.Dealer_Account__c != pDealer.Dealer__c){
        opp.Dealer_Account__c = pDealer.Dealer__c;
        opp.Dealer_Tier__c    = pDealer.Dealer__r?.Dealer_Tier__c;
      }
    }else{
      opp.Dealer_Account__c = null;
      opp.Dealer_Tier__c    = null;
    }
  }

  public static Map<Id, List<Opportunity>> checkUpdatedDealerAcc(Opportunity opp, Map<Id, List<Opportunity>> mapOppByDealerAcc, Boolean isNew,
  List<String> fieldsChanged, Map<Id, SObject> oldMap, Set<String> removedDealerIds, Set<Id> removedDealerUserIds){
    Boolean changedDealerAcc = fieldsChanged != null && fieldsChanged.contains('Dealer_Account__c');
    Boolean changedDealerUser = fieldsChanged != null && fieldsChanged.contains('Dealer_User__c');
    Boolean changedOwner = fieldsChanged != null && fieldsChanged.contains('OwnerId');
    if((opp.Dealer_Account__c != null || opp.Dealer_User__c != null) && (isNew 
    || (changedDealerAcc || changedDealerUser || changedOwner))){
      if(opp.Dealer_Account__c != null){
        if(mapOppByDealerAcc.containsKey(opp.Dealer_Account__c)){
          mapOppByDealerAcc.get(opp.Dealer_Account__c).add(opp);
        }else{
          mapOppByDealerAcc.put(opp.Dealer_Account__c, new List<Opportunity>{opp});
        }
      }
    }
    if(!isNew){
      Opportunity oldOpp = (Opportunity)oldMap.get(opp.Id);// DP-1860 Misael Romero
      if(changedDealerAcc && oldOpp.Dealer_Account__c != null){
        removedDealerIds.add(oldOpp.Dealer_Account__c);
      }
      if(changedDealerUser && oldOpp.Dealer_User__c != null){
        removedDealerUserIds.add(oldOpp.Dealer_User__c);
      }
    }
    
    return mapOppByDealerAcc;
  }
  // DP-1860 Misael Romero
  public static void removeDealerAccountUser(Opportunity opp, Boolean isNew, List<String> fieldsChanged, Map<Id, SObject> oldMap,
  User dealerUser){
    if(!isNew){
      Opportunity oldOpp = (Opportunity)oldMap.get(opp.Id);
      Boolean changedDealerAcc = (fieldsChanged != null && fieldsChanged.contains('Dealer_Account__c'))
        || oldOpp.Dealer_Account__c != opp.Dealer_Account__c;
      Id DealerUserAccId = dealerUser?.Contact?.AccountId;
      if(changedDealerAcc && oldOpp.Dealer_Account__c != null && opp.Dealer_Account__c != DealerUserAccId){
        opp.Dealer_User__c = null;
      }
    }
  }

  public static void OppShare(Map<Id, List<Opportunity>> mapOppByDealerAcc, Set<String> removedDealerIds, Set<Id> removedDealerUserIds){
    List<User>  lstContactUsers = [SELECT Id, IsPrmSuperUser, Contact.AccountId FROM User 
        WHERE (Contact.AccountId IN :mapOppByDealerAcc.keySet() OR Id IN :removedDealerUserIds) 
        AND isPortalEnabled = true AND IsActive = true];
    
    Map<Id, List<Id>> usersByOppsToShare = new Map<Id, List<Id>>();

    for(User u : lstContactUsers){
      if(u.IsPrmSuperUser){
        List<Opportunity> oppsByDealer = mapOppByDealerAcc.get(u.Contact.AccountId) ?? new List<Opportunity>();
        for(Opportunity opp :oppsByDealer){
          List<Id> superUserIds = new List<Id>();
          if(usersByOppsToShare.get(opp.Id) != null){
            superUserIds = usersByOppsToShare.get(opp.Id);
          }
          superUserIds.add(u.Id);
          usersByOppsToShare.put(opp.Id, superUserIds);
        }
      }
      if(removedDealerUserIds.contains(u.Id)){
        removedDealerIds.add(u.Contact.AccountId);
      }
    }
    if(usersByOppsToShare.values().size() > 0 || removedDealerIds.size() > 0){
      if(usersByOppsToShare.values().size() > 0 && !System.isBatch()){
        Integer alreadyQueuedJobs = [SELECT COUNT() FROM asyncapexjob 
            WHERE ApexClass.Name = 'SL_DealerPortalShareOppQ' AND (NOT Status IN ('Aborted', 'Completed', 'Failed')) AND ParentJobId = null];
        if(alreadyQueuedJobs == 0){
          TC_RecursiveTriggerHelper.oppAlreadyShared = true;
          System.enqueueJob(new SL_DealerPortalShareOppQ(usersByOppsToShare));
        }
      }
      if(removedDealerIds.size() > 0 && !System.isQueueable()){// DP-1860 Misael Romero
        List<String> dealerAccountIds = new List<String>(removedDealerIds);
        TC_RecursiveTriggerHelper.oppAlreadyShared = true;
        System.enqueueJob(new SL_UserAccountShareQ('OpportunityShare', dealerAccountIds));
      }
    }else{
      TC_RecursiveTriggerHelper.oppAlreadyShared = true;
    }
  }

  //Stamp SF- for application created on SF.
  public static void applicationFromSF(Opportunity opp, Boolean isNew, User u){
    if(isNew && opp.Portal_User_ID__c != 'DP-' && u != null && u.Id != null && isInternalUser(u)){
      opp.Portal_User_ID__c = 'SF-';
    }
  }
  public static void stampDaysMetteredOpp(Opportunity opp){
      //SAL-4794
      if(opp.Metered__c=='Yes'){
              opp.Lead_Invoice_Days__c = 20;
         }
    }

  public static boolean isInternalUser(User u){
    return (
        !u.Name.containsIgnoreCase('Portal') && !u.Name.containsIgnoreCase('Bhoomi') && !u.Name.containsIgnoreCase('Inform') && 
      !u.Name.containsIgnoreCase('GDS') && !u.Name.containsIgnoreCase('Rapport') && !u.IsPortalEnabled
    );
  }
  public static void setLessorCode(Opportunity opp, Map<ID,User> assignedCreditUser, List<String> fieldsChanged){
    User creditUser = assignedCreditUser.get(opp.Assigned_Credit_User__c);
    Boolean isXBSAnalyst;
    Boolean changedAssignedCreditUser = false;
    Boolean changedProgram = false;
    Boolean changedApplicationStatus = false;
    List<String> stagesToForceLessorCode = new List<String>{'Quote', 'Application', 'Decision', 'Proposal'};
    // if(fieldsChanged != null){
    //   changedAssignedCreditUser = fieldsChanged.contains('Assigned_Credit_User__c');
    //   changedProgram = fieldsChanged.contains('Program__c');
    //   changedApplicationStatus = fieldsChanged.contains('Application_Status__c');
    // }
    if(creditUser<>null){
        isXBSAnalyst= creditUser.XBS_Risk_Analyst__c;
    }
    if(stagesToForceLessorCode.contains(opp.StageName) /*|| !(fieldsChanged != null && fieldsChanged.contains('Lessor__c'))*/){
      Boolean isXBS=false;
      if(opp.Program__c!=NULL){
          isXBS = opp.Program__c.Contains('XBS');
      }
      if(isXBSAnalyst== true && opp.Application_Status__c=='Manually Approved'
          /*&& (changedAssignedCreditUser || changedApplicationStatus)*/){
            opp.Lessor__c= 111;
        }
      if(isXBS == true && opp.Lessor__c != 111){
          opp.Lessor__c = 211;
      }
    }
  }

	public static void calculateInterimRent(Opportunity opp, List<String> fieldsChanged, Map<Id, Dealer__c> dealers, Set<Id> oppsMovedToBooking, Set<Id> oppsChangedInterimRent){
		Dealer__c primaryDealer = dealers.get(opp.Primary_Dealer__c);
		if(primaryDealer != null && (oppsMovedToBooking.contains(opp.Id)
    || (opp.StageName == 'Booking' && fieldsChanged != null && (fieldsChanged.contains('Beginning_Maintenance_Fee_Amount__c')
    || fieldsChanged.contains('Payment_Amount__c') || fieldsChanged.contains('Commencement_Date__c')
    || fieldsChanged.contains('Opportunity_Installed_Date__c') || fieldsChanged.contains('Waive_Interim_Rent__c'))))){
      if(!opp.Waive_Interim_Rent__c && fieldsChanged != null && !fieldsChanged.contains('Waive_Interim_Rent__c')){
        opp.Waive_Interim_Rent__c = (primaryDealer.Dealer__r.Account_Interim_Rent_Waived__c == 'Yes');
      }
      opp.Lease_Payment_Interim_Rent__c = null;
      opp.Maintenance_Interim_Rent__c = null;
      opp.Interim_Rent_To_Dealer__c = null;
      opp.Interim_Rent_To_Lessor__c = null;
      if(opp.Waive_Interim_Rent__c){
        opp.Interim_Rent__c = null;
      }else{
        if(primaryDealer.Dealer__r.Preferred_Dealer_Level__c != null){
          Decimal interimDays = opp.Opportunity_Installed_Date__c == null || opp.Commencement_Date__c == null? 0
            : Decimal.valueOf(Date.valueOf(String.valueOf(opp.Opportunity_Installed_Date__c)).daysBetween(Date.valueOf(opp.Commencement_Date__c)));
          Decimal paymentAmount = opp.Payment_Amount__c != null? opp.Payment_Amount__c: 0;
          // Decimal monthlyPayment = opp.Monthly_Payment__c != null? opp.Monthly_Payment__c: 0;
          // Decimal serviceAmount = opp.Beginning_Maintenance_Fee_Amount__c != null? opp.Beginning_Maintenance_Fee_Amount__c: 0;
          // Decimal dailyLeasePaymentAmount = monthlyPayment / 30;
          Decimal dailyLeasePaymentAmount = opp.Daily_Lease_Payment_Amount__c; //paymentAmount / 30;
          Decimal dailyServicePaymentAmount = opp.Daily_Service_Payment_Amount__c;
          Decimal leasePaymentInterimRent = interimDays * dailyLeasePaymentAmount;
          Decimal maintenanceInterimRent = interimDays * dailyServicePaymentAmount;
          Decimal interimRent = leasePaymentInterimRent + maintenanceInterimRent;
          Decimal interimRentDealerPercentage = primaryDealer.Dealer__r.Interim_Rent_Dealer_Percentage__c != null? primaryDealer.Dealer__r.Interim_Rent_Dealer_Percentage__c: 0;
          Decimal interimRentToDealer = interimRent * (interimRentDealerPercentage/100);
          opp.Interim_Rent__c = interimRent;
          opp.Lease_Payment_Interim_Rent__c = leasePaymentInterimRent;
          opp.Maintenance_Interim_Rent__c = maintenanceInterimRent;
          opp.Interim_Rent_To_Dealer__c = interimRentToDealer;
          opp.Interim_Rent_To_Lessor__c = interimRent - interimRentToDealer;
        }else{// non-preferred dealer
          opp.Interim_Rent__c = (opp.Payment_Amount_w_o_Tax__c <> null) ? opp.Payment_Amount_w_o_Tax__c * 0.85 : null;
        }
      }

      oppsChangedInterimRent.add(opp.Id);
		}
		
	}
    
    /*Commented as part of SL-5225
    public static void sendXBSEmailAlert(Opportunity opp, Map<ID,User> assignedCreditUser, List<String>fieldsChanged){
        Boolean changedAppStatus = fieldsChanged != null && fieldsChanged.contains('Application_Status__c');
        Boolean changedResubmittedCredit= fieldsChanged != null && fieldsChanged.contains('Resubmitted_to_Credit__c');
        Boolean isXBSCreditUser;
        Boolean isXBSUser;
        User creditUser = assignedCreditUser.get(opp.Assigned_Credit_User__c);
        if(creditUser != null){
            isXBSCreditUser = creditUser.XBS_Risk_Analyst__c == true && creditUser.Profile.Name == 'Credit';
            isXBSUser = creditUser.XBS_Risk_Analyst__c == true;
        }
        String Subject = opp.Name + ' ' + opp.Application__c;
        String Body = 'PEAC has declined please review if Xerox wants to credit approve this transaction.';
        String Recipient = 'RiskRequestsandInquiries@xerox.com';
        List<String> RecipientList = new List<String>();        
        RecipientList.add(Recipient);
        //String testRecipient = 'gabriela.giron@silverlinecrm.com';
		//String testRecipient2 = 'sakuthota@peacsolutions.com';        
        //RecipientList.add(testRecipient);
        //RecipientList.add(testRecipient2);
        IF(changedAppStatus == true || changedResubmittedCredit){
        IF(opp.Program__c<>null){
            IF((opp.Program__c.Contains('XBS')&&opp.Application_Status__c=='Rejected'&&(isXBSCreditUser<>true||opp.Decisioned_By__c=='Scorecard'))){
            	Messaging.SingleEmailMessage errorMessage = CustomSendMailUtil.SetCustomSingleEmail(RecipientList,Subject,Body,null,null);
                List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>{errorMessage};
                Messaging.SendEmailResult[] results = Messaging.sendEmail(mails);
            // }else if(opp.Resubmitted_to_Credit__c==true && opp.Lessor__c==111&&opp.Program__c.Contains('XBS')&&isXBSCreditUser==true&&opp.Application_Status__c=='Manually Approved'){
            }else if(opp.Resubmitted_to_Credit__c==true && opp.Lessor__c==111){
            	Messaging.SingleEmailMessage errorMessage = CustomSendMailUtil.SetCustomSingleEmail(RecipientList,Subject,Body,null,null);
                List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>{errorMessage};
                Messaging.SendEmailResult[] results = Messaging.sendEmail(mails);
        	}
        }
        }        
    }*/
    
    public static void setGLLink(Opportunity opp){
        IF(opp.Lessor__c <> null && (opp.Lessor__c==111||opp.Lessor__c==113)){
            opp.GL_Link__c='173';
        }
    }

    public static void sendStatusChangeEmailAlert(Opportunity opp, List<String> fieldsChanged){
      Boolean changedOpportunityStatus = fieldsChanged != null && fieldsChanged.contains('Opportunity_Status__c');
      
      if(changedOpportunityStatus && opp.Opportunity_Status__c == 'Rejected'){
          sendRejectionEmail(opp);
      }
    }

    public static void sendRejectionEmail(Opportunity opp){
      String submitterEmail = opp.Dealer_User__c;
      Site dpSite = [SELECT Id, name FROM Site WHERE Name = 'Dealer_Portal1'];
      SiteDetail dpSiteDetail = [SELECT SecureURL FROM SiteDetail WHERE DurableId = :dpSite.Id];
      String secureURL = dpSiteDetail.SecureURL;
      
      if (String.isNotBlank(submitterEmail)) {
          String subject = 'Funding Transaction Rejected: ' + opp.Name;
          
          String body = 'Please click on the below link for details regarding this transaction:\n';
          body += secureURL + '/opportunity/' + opp.Id + '\n\n';
          body += 'Thank You';
          
          OrgWideEmailAddress orgWideEmail = [
            SELECT Id
            FROM OrgWideEmailAddress 
            WHERE Address = 'noreply@peacsolutions.com'
          ]; 
          Messaging.SingleEmailMessage rejectionEmail = new Messaging.SingleEmailMessage();
          rejectionEmail.setToAddresses(new List<String>{submitterEmail});
          rejectionEmail.setSubject(subject);
          rejectionEmail.setPlainTextBody(body);
          rejectionEmail.setOrgWideEmailAddressId(orgWideEmail.Id);
          Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{rejectionEmail});
        }
    }
    public static void UCCFees(Opportunity opp, Map<Id, List<Miscellaneous_Invoice_Item__c>> miscInvoiceItems, 
      List<Miscellaneous_Invoice_Item__c> misInvItem, List<String> fieldsChanged, Map<Id, List<Blended_Income_Item__c>> blendedIncomeItems){
        List<Blended_Income_Item__c> blendIncItem = new List<Blended_Income_Item__c>();
        if(Opp.Program__c<>null){
          if(fieldsChanged != null && fieldsChanged.contains('StageName') && Opp.Program__c.contains('XBS')){
              if(Opp.StageName=='Docs In' && Opp.Equipment_Cost__c > 50000){
                if(!TC_RecursiveTriggerHelper.oppsAlreadyMiiAdded.contains(opp.Id)){
                  TC_RecursiveTriggerHelper.oppsAlreadyMiiAdded.add(opp.Id);
                  Boolean canInsertMii = true;
                  List<Miscellaneous_Invoice_Item__c> miisByOpp = miscInvoiceItems.get(opp.Id);
                  if(miisByOpp != null){
                    for(Miscellaneous_Invoice_Item__c existinMii :miisByOpp){
                      if(existinMii.Amount__c == 75 && existinMii.GL_Code__c == '0003 - OneTime Documentation Fee'){
                        canInsertMii = false;
                        break;
                      }
                    }
                  }
                  if(canInsertMii){
                    Miscellaneous_Invoice_Item__c miscItem = new Miscellaneous_Invoice_Item__c();
                    miscItem.Opportunity__c = Opp.Id;
                    miscItem.Amount__c = 75;
                    miscItem.GL_Code__c = '0003 - OneTime Documentation Fee';
                    miscItem.Pay_Code__c = '0';
                    miscItem.Description__c = 'UCC Fee';
                    misInvItem.add(miscItem);
                  }
                } 
              }else if(Opp.StageName == 'Booking'&& Opp.Equipment_Cost__c > 50000){
                  List<Blended_Income_Item__c> oppBiis = blendedIncomeItems.get(opp.Id);
                  Boolean okToAddBii = true;
                  if(oppBiis != null && oppBiis.size() > 0){
                    for(Blended_Income_Item__c existingBII : oppBiis){
                      if(existingBII.Blended_Income_Amount__c == 75 && existingBII.Blended_Income_Code__c == '0004'
                        && existingBII.Generated_Code__c == null){
                        okToAddBii = false;
                      }
                    }
                  }
                  if(okToAddBii){
                    Blended_Income_Item__c blendItem = new Blended_Income_Item__c();
                    blendItem.Opportunity__c = Opp.Id;
                    blendItem.Blended_Income_Amount__c = 75;
                    blendItem.Blended_Income_Code__c = '0004';
                    blendIncItem.add(blendItem);
                  }
              }
          }
        }
        if(blendIncItem.size()>0){
            insert blendIncItem;
        }
    }
  // SAL-5297 Misael Romero
  public static void setSubmittedDate(Opportunity opp, Boolean isNew, List<String> fieldsChanged){
    if((isNew || (fieldsChanged != null && fieldsChanged.contains('Application__c')))
      && opp.Application__c != null && opp.record_type_name__c != 'Historical'){
        opp.Application_Submitted__c = System.now();
    }
  }
  // DP-1615 Misael Romero
  public static void removeInactiveDealerUser(Opportunity opp, User dealerUser){
    if(dealerUser != null && !dealerUser.IsActive){
      opp.Dealer_User__c = null;
    }
  }
  // SAL-5133 Misael Romero
  public static Map<Id, List<String>> emailAlertsFormerWorkFlows(Opportunity opp, Boolean isNew, List<String> fieldsChanged,
  Map<Id, List<String>> emailTemplatesByOppId){
    if(!TC_RecursiveTriggerHelper.oppsAlreadyEmailAlerted.contains(opp.Id) && !opp.Loan_Record_Type__c){
      List<String> emailTemplateNames = new List<String>();
      List<String> approvedAppStatuses = new List<String>{'Automatically Approved', 'Manually Approved'};
      List<String> pendingAppStatuses = new List<String>{'Returned to Submitter', 'More Info'};
        List<Integer> lessorCodesSFP = new List<Integer>{421, 422, 423};
      
      if((isNew || (fieldsChanged != null && fieldsChanged.contains('Application__c')))
        && opp.Application__c != null){// former workflow "SalesSubmitted -For-Sales"
        emailTemplateNames.add('SalesSubmitted');
      }
      if(approvedAppStatuses.contains(opp.Application_Status__c)
        && (((isNew || (fieldsChanged != null && (fieldsChanged.contains('Application_Status__c') || fieldsChanged.contains('Credit_Decision__c'))))
        && opp.Application__c != null && opp.Credit_Decision__c == true)
        || ((isNew || (fieldsChanged != null && fieldsChanged.contains('Resubmitted_to_Credit__c'))) 
        && !opp.Resubmitted_to_Credit__c))){// former Flow "TC Opportunity - Sales Approved Email Notification Flow"
            // if(lessorCodesSFP.contains(opp.Lessor__c)){ //  template SalesApprovedSFP was not being used in the Flow so I didn't use it even though there is an old ticket SAL-2976 that mentions it
            //   emailTemplateNames.add('SalesApprovedSFP');
            // }else{
          emailTemplateNames.add('SalesApproved');
            // }
      }
      if(opp.Application_Status__c == 'Rejected' && (((isNew || (fieldsChanged != null && fieldsChanged.contains('Application_Status__c')))
        && opp.Application__c != null)
        || ((isNew || (fieldsChanged != null && fieldsChanged.contains('Resubmitted_to_Credit__c')))
        && !opp.Resubmitted_to_Credit__c))){// former Flow SalesDeclined_For_Sales
        emailTemplateNames.add('SalesDecline');
      }
      if(((isNew || (fieldsChanged != null && fieldsChanged.contains('Application_Status__c')))
      && opp.Application__c != null && pendingAppStatuses.contains(opp.Application_Status__c))
      || ((isNew || (fieldsChanged != null && fieldsChanged.contains('Resubmitted_to_Credit__c')))
      && opp.Application_Status__c == 'More Info' && !opp.Resubmitted_to_Credit__c)){// former Flow SalesPending_For_MoreInfo_Sales
        emailTemplateNames.add('SalesPending');
      }
      if(emailTemplateNames.size() > 0){
        emailTemplatesByOppId.put(opp.Id, emailTemplateNames);
        TC_RecursiveTriggerHelper.oppsAlreadyEmailAlerted.add(opp.Id);
      }
    }
    return emailTemplatesByOppId;
  }
  // SAL-3883 Misael Romero
  public static void populateInvoiceDataFormerFlow(Opportunity opp, Boolean isNew, List<String> fieldsChanged){
    List<String> paymentOptionsToEnter = new List<String>{'N', 'U'};
    if((isNew || (fieldsChanged != null && fieldsChanged.contains('Payment_Option__c'))) 
    && !opp.Loan_Record_Type__c && paymentOptionsToEnter.contains(opp.Payment_Option__c)){
      String invoiceCode = opp.Payment_Option__c == 'N'? 'A': 'S';
      Integer leadInvoiceDays = opp.Payment_Option__c == 'N'? 22 : 3;
      if(isNew || (fieldsChanged != null && !fieldsChanged.contains('Invoice_Code__c'))){
        opp.Invoice_Code__c = invoiceCode;
      }
      if(isNew || (fieldsChanged != null && !fieldsChanged.contains('Lead_Invoice_Days__c'))){
        opp.Lead_Invoice_Days__c = leadInvoiceDays;
      }
    }
  }
  // SAL-4104 Misael Romero
  public static Boolean rescoreOverTolerance(Opportunity opp, List<String> fieldsChanged, Boolean isToleranceExceeded, Boolean isAfterUpdate,
  Set<Id> oppsAdvancedStageName, Map<Id, Dealer__c> dealers){
    Boolean isOppRescoringWhenOver = false;
    Boolean changedStageName = fieldsChanged != null && fieldsChanged.contains('StageName');
    Boolean changedResubmittedTo = fieldsChanged != null && fieldsChanged.contains('Resubmitted_to_Credit__c');
    if(!opp.Credit_Decision__c && opp.Resubmitted_to_Credit__c && opp.StageName == 'Decision'
      && changedStageName && !oppsAdvancedStageName.contains(opp.Id)){
      if(!isToleranceExceeded && !isAfterUpdate){
        String exceededToleranceMessage = '';
        exceededToleranceMessage = validateApprovedAmountVsEquipmentCost(opp, fieldsChanged, oppsAdvancedStageName, dealers, true);
        isToleranceExceeded = exceededToleranceMessage != '';
        opp.Rescore__c = isToleranceExceeded;
      }
      if(!isToleranceExceeded && isAfterUpdate && opp.Rescore__c 
      && !TC_RecursiveTriggerHelper.oppsAlreadyRescoredOver.contains(opp.Id)){
        isToleranceExceeded = true;
        TC_RecursiveTriggerHelper.oppsAlreadyRescoredOver.add(opp.Id);
      }
      if(isToleranceExceeded){
        isOppRescoringWhenOver = true;
      }
    }
    return isOppRescoringWhenOver;
  }
  // SAL-3801
  public static String validateApprovedAmountVsEquipmentCost(Opportunity opp, List<String> fieldsChanged,
  Set<Id> oppsAdvancedStageName, Map<Id, Dealer__c> dealers, Boolean isCalledFromResubmit){
    ORE__c OrgExceptions = ORE__c.getInstance(System.UserInfo.getUserId());
    String errorMessage = '';
    Decimal approvedAmount = opp.Approved_Amount__c == null? 0: Math.abs(opp.Approved_Amount__c);
    Boolean changedRecordType = fieldsChanged != null && fieldsChanged.contains('RecordTypeId');
    Boolean changedProgramType = fieldsChanged != null && fieldsChanged.contains('Program_Type__c');
    Boolean isGdsScoring = System.UserInfo.getFirstName() == 'Automated' && System.UserInfo.getLastName() == 'Process' 
      && (opp.Credit_Decision__c || opp.Application_Status__c == 'Automatically Approved' 
      || opp.Application_Status__c == 'Pending Decision' || opp.SFP2_In_Process__c);
    if(isGdsScoring && opp.Recommended_Decision__c == 'Application should be approved.' && opp.Decision_Status__c == 'A'
    && opp.UD_CO_REC_DEC__c == 4 && opp.Application_Status__c == 'Automatically Approved'){
      // SAL-5556 Misael Romero
      opp.Approved_Amount__c = opp.Equipment_Cost_w_o_Tax__c;
    }
    if(!opp.Loan_Record_Type__c && !isGdsScoring && !OrgExceptions.Tolerance__c && !OrgExceptions.Bypass__c
        && opp.Program_Type__c != '1100' && opp.Program_Type__c != '1200'
        && (!opp.Resubmitted_to_Credit__c || isCalledFromResubmit)
        && approvedAmount != 0
        && (changedRecordType || changedProgramType
        || oppsAdvancedStageName.contains(opp.Id) || isCalledFromResubmit)
        && opp.RecordTypeId != Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Funding_Stream_Opportunity').getRecordTypeId() /* RecordType.name='Loan Opportunity' */){
        List<Tolerance_Override__mdt> toleranceOverrides = [SELECT Id, Account__c, Low_Amount__c, High_Amount__c, Variance__c, Variance_Type__c
            FROM Tolerance_Override__mdt];
        Map<String, List<Tolerance_Override__mdt>> overridesByAccount = new Map<String, List<Tolerance_Override__mdt>>();
        Decimal variance = 0;
        String varianceType = 'Flat';
        for(Tolerance_Override__mdt theOverride : toleranceOverrides){
            if(!overridesByAccount.containsKey(theOverride.Account__c)){
                overridesByAccount.put(theOverride.Account__c, new List<Tolerance_Override__mdt>{theOverride});
            }else{
                overridesByAccount.get(theOverride.Account__c).add(theOverride);
            }
        }
        Id dealerId = null;
        if(dealers.size() > 0){
            dealerId = dealers.get(opp.Primary_Dealer__c)?.Dealer__c;
        }
        List<Tolerance_Override__mdt> overridesToUse = overridesByAccount.get(dealerId);
        if(overridesToUse == null){
            overridesToUse = overridesByAccount.get(opp.Primary_Broker__c);
        }
        if(overridesToUse == null){
            overridesToUse = overridesByAccount.get('Standard');
        }
        if(overridesToUse != null){
            for(Tolerance_Override__mdt theOverride : overridesToUse){
                Boolean isLimitless = theOverride.High_Amount__c == null;
                Boolean isLowest = theOverride.Low_Amount__c == null || theOverride.Low_Amount__c == 0;
                if((isLowest || approvedAmount > theOverride.Low_Amount__c) 
                    && (isLimitless || approvedAmount <= theOverride.High_Amount__c)){
                    variance = theOverride.Variance__c;
                    varianceType = theOverride.Variance_Type__c;
                    break;
                }
            }
        }
        Decimal allowedMax = approvedAmount + (varianceType == 'Flat'? variance: approvedAmount * (variance/100));
        Decimal equipmentCostNoTax = opp.Equipment_Cost_w_o_Tax__c == null? 0: opp.Equipment_Cost_w_o_Tax__c;
        if(equipmentCostNoTax > allowedMax && !OrgExceptions.Bypass__c){
            String varianceToShow = varianceType == 'Flat'? '$' + variance: variance + '%';
            errorMessage = 'Cannot Increase Equipment Cost past ' + 
                varianceToShow + ' over the Approved Amount $' + approvedAmount + ', the maximum is $' + allowedMax + '; Please resubmit to credit';
        }
    }
    return errorMessage;
  }
  // SAL-5432 Misael Romero
  // public static void rescoreWhenPrimaryDealerChanges(Opportunity opp, List<String> fieldsChanged, List<Id> idsToRescore){
  //   List<String> applicationStatusToRescore = new List<String>{'Returned to Submitter', 'Pending Decision', 'Rejected'};
  //   if(!idsToRescore.contains(opp.Id) && opp.Branch__c != 'NJ Retail' 
  //   && (fieldsChanged != null && fieldsChanged.contains('Primary_Dealer__c')) && opp.StageName == 'Decision'
  //   && applicationStatusToRescore.contains(opp.Application_Status__c)){// APIvalues instead of visible value
  //     idsToRescore.add(opp.Id);
  //   }
  // }

  // SAL-5486 Misael Romero
  public static void bulkUpdateAssetsFromFlows(Opportunity opp, Boolean isNew, List<String> fieldsChanged,
  Map<Id, List<Asset__c>> assets, Map<Id, Asset__c> assetsToUpdateById){
    List<Asset__c> oppAssets = assets.get(opp.Id);
    if(oppAssets != null && oppAssets.size() > 0){
      List<String> actionsForAssets = new List<String>();
      if(!isNew){
        String action031Or050 = setAssetInfoIf031Or050FormerFlow(opp, fieldsChanged);
        if(action031Or050 != ''){
          actionsForAssets.add(action031Or050);
        }
      }
      String actionDeprecDates = bookingRulesDepreciationDatesFormerFlow(opp, isNew, fieldsChanged);
      if(actionDeprecDates != ''){
        actionsForAssets.add(actionDeprecDates);
      }
      String actionDeprecSection = notTrueLeaseNullOutDeprecSectionFormerFlow(opp, isNew, fieldsChanged);
      if(actionDeprecSection != ''){
        actionsForAssets.add(actionDeprecSection);
      }

      if(actionsForAssets.size() > 0){
        for(Asset__c oppAsset : oppAssets){
          Asset__c withOtherChange = assetsToUpdateById.get(oppAsset.Id);
          Asset__c assetToUpdate = withOtherChange == null? oppAsset: withOtherChange;
          if(actionsForAssets.contains('taxCode031')){
            assetToUpdate.City_Tax_Amount__c = 0;
            assetToUpdate.City_Tax_Code__c = '031';
            assetToUpdate.City_Tax_Percentage__c = 0;
            assetToUpdate.City_Transit_Tax_Amount__c = 0;
            assetToUpdate.City_Transit_Tax_Percentage__c = 0;
            assetToUpdate.County_Tax_Amount__c = 0;
            assetToUpdate.County_Tax_Code__c = '031';
            assetToUpdate.County_Tax_Percentage__c = 0;
            assetToUpdate.County_Transit_Tax_Amount__c = 0;
            assetToUpdate.County_Transit_Tax_Percentage__c = 0;
            assetToUpdate.Misc_City_Tax_Code__c = '031';
            assetToUpdate.Misc_County_Tax_Code__c = '031';
            assetToUpdate.Misc_State_Tax_Code__c = '031';
            assetToUpdate.Responsibility_Code__c = null;
            assetToUpdate.State_Tax_Amount__c = 0;
            assetToUpdate.State_Tax_Code__c = '031';
            assetToUpdate.State_Tax_Percentage__c = 0;
            assetToUpdate.Tax_Date_Time__c = Datetime.now();
            assetToUpdate.Upfront_City_Tax_Amount__c = 0;
            assetToUpdate.Upfront_City_Transit_Tax_Amount__c = 0;
            assetToUpdate.Upfront_County_Tax_Amount__c = 0;
            assetToUpdate.Upfront_County_Transit_Tax_Amount__c = 0;
            assetToUpdate.Upfront_State_Tax_Amount__c = 0;
            assetToUpdate.Upfront_Tax_Code__c = '031';
            assetToUpdate.Upfront_Tax_Method__c = null;
            assetToUpdate.Usage_User_Table__c = '2';
          }
          if(actionsForAssets.contains('taxCode050')){
            assetToUpdate.ACE_Depreciation_Basis__c = 0;
            assetToUpdate.City_Tax_Amount__c = 0;
            assetToUpdate.City_Tax_Code__c = '050';
            assetToUpdate.City_Tax_Percentage__c = 0;
            assetToUpdate.City_Transit_Tax_Percentage__c = 0;
            assetToUpdate.County_Tax_Amount__c = 0;
            assetToUpdate.County_Tax_Code__c = '050';
            assetToUpdate.County_Tax_Percentage__c = 0;
            assetToUpdate.County_Transit_Tax_Amount__c = 0;
            assetToUpdate.County_Transit_Tax_Percentage__c = 0;
            assetToUpdate.LC_City_Tax_Code__c = '050';
            assetToUpdate.LC_County_Tax_Code__c = '050';
            assetToUpdate.LC_State_Tax_Code__c = '050';
            assetToUpdate.Misc_City_Tax_Code__c = '050';
            assetToUpdate.Misc_County_Tax_Code__c = '050';
            assetToUpdate.Misc_State_Tax_Code__c = '050';
            assetToUpdate.Property_Status__c = '10';
            assetToUpdate.Responsibility_Code__c = null;
            assetToUpdate.State_Tax_Amount__c = 0;
            assetToUpdate.State_Tax_Code__c = '050';
            assetToUpdate.State_Tax_Percentage__c = 0;
            assetToUpdate.Tax_Date_Time__c = Datetime.now();
            assetToUpdate.Upfront_City_Tax_Amount__c = 0;
            assetToUpdate.Upfront_City_Transit_Tax_Amount__c = 0;
            assetToUpdate.Upfront_County_Tax_Amount__c = 0;
            assetToUpdate.Upfront_County_Transit_Tax_Amount__c = 0;
            assetToUpdate.Upfront_Responsibility_Code__c = null;
            assetToUpdate.Upfront_State_Tax_Amount__c = 0;
            assetToUpdate.Upfront_Tax_Code__c = '050';
            assetToUpdate.Upfront_Tax_Method__c = null;
          }
          if(actionsForAssets.contains('taxCodeNull')){
            assetToUpdate.City_Tax_Code__c = null;
            assetToUpdate.County_Tax_Code__c = null;
            assetToUpdate.State_Tax_Code__c = null;
            assetToUpdate.Upfront_Tax_Code__c = null;
          }
          if(actionsForAssets.contains('depreciationDates')){
            assetToUpdate.Begin_Depreciation_Date__c = opp.Opportunity_Booked_Date__c.date();
            assetToUpdate.State_Begin_Depreciation_Date__c = opp.Opportunity_Booked_Date__c.date();
          }
          if(actionsForAssets.contains('deprecFieldsNull')){
            assetToUpdate.ACE_Depreciation_Basis__c = null;
            assetToUpdate.ADS_Class_Life_in_Months__c = null;
            assetToUpdate.AMT_Depreciation_Basis__c = null;
            assetToUpdate.Begin_Depreciation_Date__c = null;
            assetToUpdate.Calculate_ACE_Depr__c = false;
            assetToUpdate.Calculate_AMT__c = false;
            assetToUpdate.Depreciation_Basis__c = null;
            assetToUpdate.Federal_Calculation_Basis__c = null;
            assetToUpdate.Federal_Convention__c = null;
            assetToUpdate.Federal_Life__c = null;
            assetToUpdate.Federal_Method__c = null;
            assetToUpdate.State_Begin_Depreciation_Date__c = null;
            assetToUpdate.State_Depreciation_Basis__c = null;
            assetToUpdate.State_Life_in_Months__c = null;
            assetToUpdate.State_Method__c = null;
          }
          assetsToUpdateById.put(assetToUpdate.Id, assetToUpdate);
        }
      }
    }
  }
  // SAL-5486 Misael Romero
  public static String setAssetInfoIf031Or050FormerFlow(Opportunity opp, List<String> fieldsChanged){
    String actionForAssets = '';
    Boolean changedStage = fieldsChanged != null && fieldsChanged.contains('StageName');
    Boolean changedPurchaseOption = fieldsChanged != null && fieldsChanged.contains('Purchase_Options__c');
    Boolean changedTaxExempt = fieldsChanged != null && fieldsChanged.contains('Tax_Exempt__c');
    Boolean changedContractType = fieldsChanged != null && fieldsChanged.contains('Contract_Type__c');
    if(changedStage || changedPurchaseOption || changedTaxExempt || changedContractType){
      List<String> stagesTaxExemptOrg = new List<String>{'Docs In', 'Funding', 'Booking'};
      if(!opp.IsClosed && opp.Tax_Exempt__c == 'Yes' && (changedTaxExempt
      || (changedStage && stagesTaxExemptOrg.contains(opp.StageName)))){
        actionForAssets = 'taxCode031';
      }else{
        List<String> stagesCustomerOwned = new List<String>{'Funding', 'Booking'};
        if(opp.Purchase_Options__c == 'Customer Owned' && (!opp.IsClosed 
        && (changedPurchaseOption || (changedContractType && opp.Contract_Type__c == 'RL'))
        || (!opp.Loan_Record_Type__c && changedStage && stagesCustomerOwned.contains(opp.StageName)))){
          actionForAssets = 'taxCode050';
        }else{
          if((changedTaxExempt && opp.Tax_Exempt__c != 'Yes')
          || (changedPurchaseOption && opp.Purchase_Options__c != 'Customer Owned')){
            actionForAssets = 'taxCodeNull';
          }
        }
      }
    }
    return actionForAssets;
  }
  // SAL-5486 Misael Romero
  public static String bookingRulesDepreciationDatesFormerFlow(Opportunity opp, Boolean isNew, List<String> fieldsChanged){
    String actionForAssets = '';
    Boolean changedBookedDate = fieldsChanged != null && fieldsChanged.contains('Opportunity_Booked_Date__c');
    if(opp.Opportunity_Booked_Date__c != null && ((isNew && !opp.Loan_Record_Type__c && !opp.IsClosed) || changedBookedDate)){
      actionForAssets = 'depreciationDates';
    }
    return actionForAssets;
  }
  // SAL-5486 Misael Romero
  public static String bookingRulesDepreciationDatesFormerFlow(Opportunity opp, Boolean isNew, List<String> fieldsChanged,
  Map<Id, List<Blended_Income_Item__c>> blendedIncomeItems, Map<Id, Blended_Income_Item__c> biisToUpdateById){
    String actionForBiis = '';
    Boolean changedCommencementDate = fieldsChanged != null && fieldsChanged.contains('Commencement_Date__c');
    List<Blended_Income_Item__c> oppBiis = blendedIncomeItems.get(opp.Id);
    if(oppBiis != null && oppBiis.size() > 0 
    && ((isNew && !opp.Loan_Record_Type__c && !opp.IsClosed && opp.Opportunity_Booked_Date__c != null 
    && opp.Commencement_Date__c != null) || changedCommencementDate)){
      if(opp.Commencement_Date__c != null){
        actionForBiis = 'updateBeginDate';
        for(Blended_Income_Item__c bii : oppBiis){
          Blended_Income_Item__c withOtherChange = biisToUpdateById.get(bii.Id);
          Blended_Income_Item__c biiToUpdate = withOtherChange == null? bii: withOtherChange;
          biiToUpdate.Begin_Date__c = opp.Commencement_Date__c;
          biisToUpdateById.put(biiToUpdate.Id, biiToUpdate);
        }
      }
    }
    return actionForBiis;
  }
  // SAL-5486 Misael Romero
  public static String notTrueLeaseNullOutDeprecSectionFormerFlow(Opportunity opp, Boolean isNew, List<String> fieldsChanged){
    String actionForAssets = '';
    Boolean changedStage = fieldsChanged != null && fieldsChanged.contains('StageName');
    Boolean changedContractType = fieldsChanged != null && fieldsChanged.contains('Contract_Type__c');
    if(!isNew && opp.Contract_Type__c != 'TL' && (changedContractType 
    || (opp.StageName == 'Booking' && changedStage))){
      actionForAssets = 'deprecFieldsNull';
    }
    return actionForAssets;
  }
  // SAL-5486 Misael Romero
  // remember to uncomment this when the ticket is ready to be promoted
  // public static void commitAssetUpdates(Map<Id, Asset__c> assetsToUpdateById){
  //   if(assetsToUpdateById.keySet().size() > 0){
  //     if(assetsToUpdateById.keySet().size() <= Integer.valueOf(Label.SL_MaxAssetsPerUpdate)){
  //       update assetsToUpdateById.values();
  //     }else{
  //       Integer alreadyQueuedJobs = [SELECT COUNT() FROM asyncapexjob 
  //         WHERE ApexClass.Name = 'SL_AssetUpdateQ' AND (NOT Status IN ('Aborted', 'Completed', 'Failed')) AND ParentJobId = null];
  //       System.enqueueJob(new SL_AssetUpdateQ(assetsToUpdateById), alreadyQueuedJobs);
  //     } 
  //   }
  // }
}