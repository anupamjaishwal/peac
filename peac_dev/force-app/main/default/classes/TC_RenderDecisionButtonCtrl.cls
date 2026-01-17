/**
* Created by tamarack on 1/28/20.
*
*/

public with sharing class TC_RenderDecisionButtonCtrl {
    public static List<String> ccEmails = new List<String>{'MGiordano@marlincapitalsolutions.com','BRay@marlincapitalsolutions.com'};
        public static List<String> customerVerification = new List<String>{'CustomerVerifications@marlincorp.com','BRay@marlincapitalsolutions.com'};
            
            
            @AuraEnabled
            public static RenderDecisionWrapper getRenderDecisionDetails(Id recordId) {
                Opportunity opp = TC_DataUtility.getAllFieldsOnOpportunityByRecordId(recordId);
                RenderDecisionWrapper wrapper = new RenderDecisionWrapper(opp);
                Boolean isXBSAnalyst = [Select XBS_Risk_Analyst__c from User Where Id = :UserInfo.getUserId() Limit 1].XBS_Risk_Analyst__c; 
                //Added by Rajesh Kumar(LTIMindtree) SAL-5600
                List<Approved_Offer__c> approvedOffersList = new List<Approved_Offer__c>();
                approvedOffersList = [SELECT Id, Name FROM Approved_Offer__c WHERE Opportunity__c =:opp.id AND Select_for_approval__c = true LIMIT 1];
                
                // Andrew - we should really use the strategy pattern for logic like this.
                
                if (opp.Assigned_Credit_User__c == null) {
                    wrapper.errorList.add('Assigned Credit User must be populated.');
                }
                if (opp.Decision_Status__c == null ||
                    (!(opp.Decision_Status__c == 'A') && !(opp.Decision_Status__c == 'M') && !(opp.Decision_Status__c == 'R'))) {
                        wrapper.errorList.add('Decision Status must be updated to Approved, Rejected or More Info.');
                    }
                if (opp.Application_Status__c == 'Manually Approved' && opp.Policy_Exception__c == null) {
                    wrapper.errorList.add('Policy Exception must be populated when Application Status is \'Manually Approved\'.');
                }
                // Added by Vinod(LTIMIndtree).SAL-5436
                if (opp.Loan_Record_Type__c  && opp.Policy_Exception__c == 'Exception' && opp.Field_Exception_Comments__c == null) {
                    wrapper.errorList.add('Field Exception Comments must be populated when Policy Exception is set as \'Exception\'.');
                }
                // Added by Rajesh Kumar(LTIMindtree) SAL-5600
                if (opp.Loan_Record_Type__c && approvedOffersList.isEmpty() && opp.Decision_Status__c == 'A') {
                    wrapper.errorList.add(label.PEAC_Select_for_approval_message);
                }
                //End
                /*
                SAL-939 (https://marlinbusiness.atlassian.net/browse/SAL-939)
                Commenting per removal of SFP2 logic in Release 2.1
                if (opp.Decision_Status__c == 'R' && opp.SFP_Tier_2_Credit_Box__c != null
                && opp.SFP_Tier_2_Status__c != 'Approved' && opp.SFP_Tier_2_Status__c != 'Rejected') {
                wrapper.errorList.add('This deal is eligible for SFP Tier 2 Status. Please complete this process by ' +
                'updating the SFP Tier 2 Status field before proceeding. SFP Tier 2 Credit Box: ' +
                '\'' + wrapper.opp.SFP_Tier_2_Credit_Box__c + '\'');
                }
                */
                // SAL-1224 (https://marlinbusiness.atlassian.net/browse/SAL-1224) // Added by Vinod(LTIMIndtree).SAL-5436
                if ((opp.SIC_Code__c == null || opp.SIC_Code__c.equals('0000')) && (opp.Decision_Status__c == 'A' || (opp.Application_Status__c == 'Manually Approved' && opp.Loan_Record_Type__c))) {
                    wrapper.errorList.add('SIC Code is not allowed to be blank or 0000 for approved/Manually Approved transactions.');
                }
                // SAL-5440 (https://marlinbusiness.atlassian.net/browse/SAL-5440) // Added by Toms (LTIMindtree)
                if (opp.Approved_Amount__c > Decimal.valueOf(System.Label.Render_Decision_Approved_Amount)  && opp.Financials_Reviewed__c == null && !opp.Loan_Record_Type__c) {
                    wrapper.errorList.add(System.Label.Render_Decision_Error_Message);
                }
                if (opp.Decision_Status__c == 'A' && (opp.OFAC_Result__c != null && opp.OFAC_Result__c.contains('Potential OFAC'))
                    && !opp.OFAC_Override__c) {
                        wrapper.errorList.add('Cannot approve due to potential OFAC match. Please resolve or select OFAC Override.');
                    }
                
                // SAL-1206 (https://marlinbusiness.atlassian.net/browse/SAL-1206)
                if (opp.Branch__c == 'Commercial Vehicle Group' && opp.Pricing_Level__c == null && opp.Decision_Status__c == 'A') {
                    wrapper.errorList.add('Pricing Level is required when Branch is Commercial Vehicle Group and Decision Status is Approved.');
                }
                //SAL - 4917(https://marlinbusiness.atlassian.net/browse/SAL-4917)
                Boolean isXBSProgram = false;
                if(opp.Program__c<>null){
                    isXBSProgram = opp.Program__c.Contains('XBS');
                }
                
                if(isXBSProgram == false && isXBSAnalyst==true){
                    wrapper.errorList.add('XBS Risk Analysts can only decision XBS Apps');
                }
                
                // SAL-1037 (https://marlinbusiness.atlassian.net/browse/SAL-1037)
                // Set<String> sicCodeSet = new Set<String>{'8011', '8021', '8031', '8042', '8043', '8093', '8111', '8712', '8721'};
                
                // Update SFDC Rules for opportunity.Branch == "Healthcare Division" to drive off of Equip_Code1__c medical
                // https://marlinbusiness.atlassian.net/browse/SAL-1726
                Map <String, String> labelMap = TC_PicklistUtil.getLabelMap(Asset__c.Equipment_Code__c);
                
                // SAL-2554 Remove existing rule around Months in Profession (when Med equipment and HC branch) - field should no longer be required when rendering the decision.
                // if (/*opp.Branch__c == 'Healthcare Division'*/
                //     TC_EquipmentCodeUtil.isMedical(opp.Equip_Code1__c, labelMap)
                //     && opp.Decision_Status__c == 'A' && opp.Months_in_Profession__c == null) {
                //         wrapper.errorList.add(Label.TC_RenderDecision_MonthsInProfMedical);
                // }
                
                if (wrapper.errorList.isEmpty()) {
                    wrapper.confirmActionStep = true;
                }
                
                
                 // -------------------- RESCORE VALIDATION (SAL-6181) --------------------
             
               // String profileName = opp.Opportunity_CurrentUser_Profile__c;
                
                // Custom metadata that drives which stages / profiles are in-scope
               // RescoreIsMandatoryForLoan__c validationInfo = RescoreIsMandatoryForLoan__c.getInstance('Docs Requested');
                
               /* List<String> stageList = new List<String>();
                List<String> profileList = new List<String>();
                
                if (validationInfo != null) {
                    stageList = (validationInfo.StageName__c == null)
                        ? new List<String>()
                        : validationInfo.StageName__c.split(';');
                    
                    for (String p : (validationInfo.ProfileName__c == null
                                     ? new List<String>()
                                     : validationInfo.ProfileName__c.split(';'))) {
                                         if (!String.isBlank(p)) {
                                             profileList.add(p.trim());
                                         }
                                     }
                }
                
                Boolean profileExcluded = profileName != null && profileList.contains(profileName.trim());
                Boolean stageInScope   = stageList.contains(opp.StageName); */
                
                if (opp.Loan_Record_Type__c
                    && opp.Scored_Field_Modified__c) {
                        wrapper.errorList.add(
                            'One or more fields used for scoring or rescoring the application have been ' +
                            'modified. The application must be Rescored before ' +
                            'you can render a decision.'
                        );
                 }
                
                
                // SAL-1179 (https://marlinbusiness.atlassian.net/browse/SAL-1179)
                wrapper.fraudFlag = opp.Fraud_Flag__c;
                
                return wrapper;
            }
    
    /*
https://marlinbusiness.atlassian.net/browse/SAL-939
Commenting per removal of SFP2 logic in Release 2.1
@AuraEnabled
public static void setSFP2InProcess(Opportunity opp) {
opp.SFP2_In_Process__c = true;
update opp;
}*/
    
    @AuraEnabled
    public static RenderDecisionWrapper renderDecision(RenderDecisionWrapper wrapper) {
        
        Boolean isUpdateOpp = false;
        try {
            System.debug('renderDecisionWrapper start: ' + wrapper);
            if (wrapper.opp.Decision_Status__c == 'A') {
                List<User> userList = new List<User>([SELECT Credit_Authority__c,Credit_Authority_Loan__c FROM User WHERE Id =: UserInfo.getUserId()]);
                //Added by Rajesh Kumar(LTIMindtree)
                List<Webservice_Field__c> webserviceList = new List<Webservice_Field__c>([SELECT Id, Total_Exposure__c FROM Webservice_Field__c
                                                            WHERE Opportunity__c =:wrapper.opp.Id AND Stored_Procedure__c = 'getGdsGetCustCreditExpLoan' ORDER BY CreatedDate DESC LIMIT 1]);
                
                Decimal creditAuthority;
                Decimal totalExposure = 0.00;
                // Added by Vinod(LTIMIndtree).SAL-5657
                if(wrapper.opp.Loan_Record_Type__c){
                    creditAuthority = userList[0].Credit_Authority_Loan__c;
                    totalExposure = !webserviceList.isEmpty()?Decimal.valueOf(webserviceList[0].Total_Exposure__c):0.00;
                }else {
                    creditAuthority = userList[0].Credit_Authority__c;
                    totalExposure = wrapper.opp.Total_Exposure__c !=Null?wrapper.opp.Total_Exposure__c:0.00;
                }
                
                // https://marlinbusiness.atlassian.net/browse/SAL-1228
                /*
* 
* if Approved Amount is Null, then look at  Total Exposure
If Approved Amount is not Null, then look at (Approved Amount - Credit Amount) + Total Exposure
* */
                /*
if (creditAuthority == null || wrapper.opp.Total_Exposure__c > creditAuthority ) {
wrapper.errorList.add('Total Exposure exceeds User Authority.');
} else {
wrapper.opp.Application_Status__c = 'Manually Approved';
}*/
                //Added by Rajesh Kumar(LTIMindtree)
                Decimal creditAmount = wrapper.opp.Credit_Amount__c !=null?wrapper.opp.Credit_Amount__c:0.00;
                if (wrapper.opp.Approved_Amount__c == null || wrapper.opp.Approved_Amount__c == 0) {
                    if (totalExposure > creditAuthority) {
                        wrapper.errorList.add('Total Exposure exceeds User Authority.');
                    } else {
                        wrapper.opp.Application_Status__c = 'Manually Approved';
                    }
                } else {
                    if ((wrapper.opp.Approved_Amount__c - creditAmount) + totalExposure > creditAuthority) {
                        wrapper.errorList.add('Total Exposure exceeds User Authority.');
                    } else {
                        wrapper.opp.Application_Status__c = 'Manually Approved';
                    }
                }
            } else if (wrapper.opp.Decision_Status__c == 'R') {
                /*
SAL-939 (https://marlinbusiness.atlassian.net/browse/SAL-939)
Commenting per removal of SFP2 logic in Release 2.1
if (wrapper.opp.SFP_Tier_2_Status__c == 'Approved') {
wrapper.opp.Decision_Status__c = 'A';
wrapper.opp.Reason_for_Approval__c = 'Approved SFP Tier 2';
} else if (wrapper.opp.SFP_Tier_2_Status__c == 'Rejected') {
wrapper.opp.Decline_Reason__c = 'Rejected with Supplemental Information';
} else {
wrapper.opp.Application_Status__c = 'Rejected';
}*/
                wrapper.opp.Application_Status__c = 'Rejected';
            } else if (wrapper.opp.Decision_Status__c == 'M') {
                wrapper.opp.Application_Status__c = 'More Info';
            }
            
            
            // SAL-2777 - If Opportunity.Fraud Review Flag =1  AND Opportunity.Decision Status is “Approved”
            // Add by varun - SAL- 3677
            if (wrapper.opp.FraudReviewFlag__c==1 && wrapper.opp.Decision_Status__c == 'A' && wrapper.opp.Fraud_Review_Status__c != 'Approved') {
                wrapper.opp.StageName = 'Decision';
                wrapper.opp.Application_Status__c = 'Pending Decision';
                wrapper.opp.Opportunity_Status__c = 'Fraud Review';
                isUpdateOpp = true;
                //update wrapper.opp;
                
                // return error to front end
                wrapper.errorList.add('Application requires CVP Analyst Review.');
                
                //send emails
                String appNumber = wrapper.opp.Application__c;
                String appName = wrapper.opp.Name;
                String recordLink = URL.getSalesforceBaseUrl().toExternalForm()+'/'+wrapper.opp.Id;
                
                String subject = appNumber+ ' Ready for Review';
                String body = appNumber +', '+ appName +', is in the Fraud Queue and ready for Fraud Review. '+ recordLink;
                try {
                    // Create and send email to Customer Verification Email box
                    List<Messaging.SendEmailResult> sentCustomerVerifyEmail = TC_EmailUtil.sendEmailNotification(customerVerification, null, wrapper.opp.Id, null, subject, body, label.Org_Wide_Email_Id_Marlin_No_Reply, null, null);
                    System.debug(LoggingLevel.DEBUG, 'sentCustomerVerifyEmail Successful: '+sentCustomerVerifyEmail[0].isSuccess());
                    System.debug(LoggingLevel.DEBUG, 'sentCustomerVerifyEmail Errors: '+sentCustomerVerifyEmail[0].getErrors());
                    
                    // Create and send email to Sales Rep
                    subject = appNumber +', '+appName;
                    body = appNumber +', '+ appName +', is under Further Identity Verification. Please contact your CVP Analyst for questions. '+recordLink;
                    List<Messaging.SendEmailResult> sentSalesRepEmail = TC_EmailUtil.sendEmailNotification(null, ccEmails, wrapper.opp.Id, wrapper.opp.OwnerId, subject, body, label.Org_Wide_Email_Id_Marlin_No_Reply, null, null);
                    System.debug(LoggingLevel.DEBUG, 'sentSalesRepEmail Successful: '+sentSalesRepEmail[0].isSuccess());
                    
                } catch (EmailException e) {
                    System.debug(LoggingLevel.DEBUG, 'Error: '+e.getMessage());
                    System.debug(LoggingLevel.DEBUG, e.getStackTraceString());
                    AuraHandledException ahe = new AuraHandledException(e.getMessage());                    
                    if (e.getMessage().contains('INVALID_EMAIL_ADDRESS')) {
                        ahe.setMessage('Please confirm the owner\'s email address is valid/correct and try again.');
                    }
                    throw ahe;
                }
            }
            // End SAL-2777
            
            
            if (wrapper.errorList.isEmpty()) {
                if (wrapper.opp.Reason_for_Approval__c == 'Approved with Supplemental Information') {
                    wrapper.supplementalCodes = true;
                }
            }
            
            if (wrapper.opp.Application_Status__c == 'Manually Approved' && wrapper.opp.Policy_Exception__c == null) {
                wrapper.errorList.add('Application Status is being set to Manually Approved but Policy Exception is null. ' +
                                      'Provide Policy Exception before completing action step.');
            }
            
            wrapper.opp.Decisioned_By__c = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
            wrapper.opp.Credit_Decision__c = true;
            wrapper.opp.Resubmitted_to_Credit__c = false;
            
            // Added by Vinod(LTIMIndtree).SAL-5436
            If(wrapper.opp.Application_Status__c == 'Approved'){
                wrapper.opp.Approval_Date__c = System.now();
            }
            wrapper.opp.Decision_Date__c = System.now();
            If(wrapper.opp.Loan_Record_Type__c){
                AggregateResult aggResults = [SELECT MAX(Offer_Amount__c) offer FROM Approved_Offer__c WHERE Opportunity__c = : wrapper.opp.Id];
                Decimal maxOfferAmount = (Decimal)aggResults.get('offer');
                wrapper.opp.Approved_Amount__c = maxOfferAmount;
            }
            //End
            
            if (wrapper.opp.Originally_Decisioned_By__c == null){
                wrapper.opp.Originally_Decisioned_By__c = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
            }
            
            if (!wrapper.supplementalCodes && wrapper.errorList.isEmpty()) {
                /*
SAL-1198 (https://marlinbusiness.atlassian.net/browse/SAL-1198)
When renderDecision is executed, if Term != Max Term Approved, Term <= Max Term Approved
For some reason, if Terms__c is set to null, the JSON serialization in the Aura Component removes the Terms__c key
so it is missing for the DML update. Thus, putting this logic before both DMLs instead of messing with the
serialization.
*/
                //             if (wrapper.opp.Terms__c != wrapper.opp.Max_Term_Approved__c) wrapper.opp.Terms__c = wrapper.opp.Max_Term_Approved__c;
                isUpdateOpp = true;
            }
            System.debug('renderDecisionWrapper end: ' + wrapper);
            if(isUpdateOpp) {
                update wrapper.opp;
            }
            return wrapper;
        } catch (Exception e) {
            System.debug('Error: '+e.getMessage());
            System.debug(e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
        
    }
    
    @AuraEnabled
    public static void finalOppUpdate(RenderDecisionWrapper wrapper) {
        System.debug('SAL-2110');
        
        /*
SAL-1198 (https://marlinbusiness.atlassian.net/browse/SAL-1198)
When renderDecision is executed, if Term != Max Term Approved, Term <= Max Term Approved
For some reason, if Terms__c is set to null, the JSON serialization in the Aura Component removes the Terms__c key
so it is missing for the DML update. Thus, putting this logic before both DMLs instead of messing with the
serialization.
*/
        if (wrapper.opp.Terms__c != wrapper.opp.Max_Term_Approved__c) wrapper.opp.Terms__c = wrapper.opp.Max_Term_Approved__c;
        //update wrapper.opp;
        //here you have the opp id 
        Opportunity objOpp =  wrapper.opp;
        String oppId = objOpp.Id;
        List<Resubmission_to_Credit_Details__c> lstRTC = [Select Id, Render_Decision_Date_Time__c from Resubmission_to_Credit_Details__c where Opportunity__c =: oppId order by createdDate DESC limit 1];
        
        if(lstRTC.size() > 0){
            Resubmission_to_Credit_Details__c objRCD = lstRTC[0];
            
            String decimalStrWithDollarSign;
            String MaxTermApproved;
            
            If( String.isNotBlank(String.valueOf(objOpp.Approved_Amount__c))) {
                decimalStrWithDollarSign = string.format('${0}', new string[]{String.valueOf(objOpp.Approved_Amount__c.setScale(2).format())});
                
            }
            else
            {
                decimalStrWithDollarSign = '';
            }
            
            If( String.isNotBlank(String.valueOf(objOpp.Max_Term_Approved__c))) {
                MaxTermApproved = String.valueOf(objOpp.Max_Term_Approved__c);
                
            }
            else
            {
                MaxTermApproved = '';
            }            
            
            
            objRCD.Render_Decision_Date_Time__c = System.now();
            objRCD.Resub_Decisioned_By__c = UserInfo.getUserId();
            objRCD.Field_Values_at_Resub_Render_Decision__c = 'Decision Status: ' +objOpp.Decision_Status__c + '\nApproved Amount: ' + decimalStrWithDollarSign + '\n Max Term Approved: ' + MaxTermApproved;
            update objRCD;
        }
        if (wrapper.supplementalCodes) {
            update wrapper.opp; // SAL-2757
        }
        
        // here you will need to query the 
    }
    
    
    
    
    public class RenderDecisionWrapper {
        @AuraEnabled
        public Opportunity opp {get; set;}
        @AuraEnabled
        public Boolean fraudFlag {get; set;}
        @AuraEnabled
        public List<String> errorList {get; set;}
        @AuraEnabled
        public Boolean confirmActionStep {get; set;}
        @AuraEnabled
        public Boolean supplementalCodes {get; set;}
        public RenderDecisionWrapper(Opportunity opp) {
            this.opp = opp;
            this.errorList = new List<String>();
            this.confirmActionStep = false;
            this.supplementalCodes = false;
        }
        public RenderDecisionWrapper() {}
    }
    
}