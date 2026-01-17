public with sharing class SL_retrievePrimaryContact {
    @AuraEnabled
    public static Contact getPrimaryContactsOfContract(String contractId){
        Contact conRecord = new Contact();
        if(!String.isEmpty(contractId)){
            Contract_Contact_Role__c primaryContact = [Select Id, Name,Contract__c, Contact__c, Contact_Email__c, Role__c, Responsible__c, 
                            Contact_Phone__c, Contact_Name__c, First_3_Digit_of_Ph__c from Contract_Contact_Role__c where 
                            Contract__c =: contractId AND Role__c = 'Primary Contact' order by LastModifiedDate  desc Limit 1];
                
            if(!String.isEmpty(primaryContact.Contact__c)){
                 conRecord = [Select Id, AccountId, LastName, FirstName, Salutation, MiddleName,  Name, OtherStreet, OtherCity, 
                            OtherState, OtherPostalCode, OtherCountry, OtherStateCode, OtherCountryCode, OtherLatitude, OtherLongitude, 
                            OtherGeocodeAccuracy, OtherAddress, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, 
                            MailingStateCode, MailingCountryCode, MailingLatitude, MailingLongitude, MailingGeocodeAccuracy, MailingAddress, 
                            Phone, Fax, MobilePhone, HomePhone, OtherPhone, AssistantPhone, ReportsToId, Email, Title, Department, AssistantName, 
                            LeadSource, Birthdate, Description, OwnerId, HasOptedOutOfEmail, HasOptedOutOfFax, DoNotCall, CreatedDate, CreatedById, 
                            LastCURequestDate, LastCUUpdateDate, LastViewedDate, LastReferencedDate, EmailBouncedReason, EmailBouncedDate, IsEmailBounced, 
                            PhotoUrl, Jigsaw, JigsawContactId, IndividualId, Ownership_Pct__c, SSN__c, Account_Stage__c, Ext_1__c, Ext_2__c, Best_Way_to_Contact__c,
                             Do_Not_Sync_to_Marketo__c, Do_Not_Mail__c, mkto71_Lead_Score__c, mkto71_Acquisition_Date__c, mkto71_Acquisition_Program__c, 
                             mkto71_Acquisition_Program_Id__c, mkto71_Original_Referrer__c, mkto71_Original_Search_Engine__c, mkto71_Original_Search_Phrase__c,
                              mkto71_Original_Source_Info__c, mkto71_Original_Source_Type__c, mkto71_Inferred_City__c, mkto71_Inferred_Company__c, 
                              mkto71_Inferred_Country__c, mkto71_Inferred_Metropolitan_Area__c, mkto71_Inferred_Phone_Area_Code__c, mkto71_Inferred_Postal_Code__c,
                               mkto71_Inferred_State_Region__c, Job_Level__c, Recid__c, Direct_Phone__c, Contact_CurrentUser_Profile__c, Sent_to_InfoLease_Date_Time__c, 
                               Connected_on_LinkedIn__c, C_18__c, CVG_Contact_no__c, TC_Origination__Checklist_Items_Email_Text__c, TC_Origination__Public_Checklist_View_All__c,
                                DL_Number__c, DL_State__c, mkto_si__Add_to_Marketo_Campaign__c, mkto_si__HideDate__c, mkto_si__Last_Interesting_Moment_Date__c, 
                                mkto_si__Last_Interesting_Moment_Desc__c, mkto_si__Last_Interesting_Moment_Source__c, mkto_si__Last_Interesting_Moment_Type__c,
                                 mkto_si__Last_Interesting_Moment__c, mkto_si__Mkto_Lead_Score__c, mkto_si__Priority__c, mkto_si__Relative_Score_Value__c, mkto_si__Relative_Score__c,
                                  mkto_si__Sales_Insight__c, mkto_si__Urgency_Value__c, mkto_si__Urgency__c, mkto_si__View_in_Marketo__c, Created_by_Marketo__c,
                                   TCCSC2__Languages__c, TCCSC2__Level__c, Application_Link__c, Validity_Verify__Checked__c, Validity_Verify__Status__c, 
                                   Validity_Verify__Timestamp__c, Emailage_Pull_Time_Stamp__c, Emailage_Result__c, Final_E_mail_Validity_Result__c, OK_to_Pull_Credit__c, 
                                   Override_Emailage_Result__c, fml_AccountEngagementScore__c, IsValidPhone__c, Fa_tTrack_URL__c, Phone1__c, Phone_2_Type__c, Phone_3_Type__c, 
                                   fml_ContactName__c, Active_in_My_Marlin__c, Alternate_Email_Optional__c, Dealer_Customer_Supplied_PG__c, Last_MarlinNet_Login_Date__c, 
                                   MarlinNet_Access_Level__c, MarlinNet_Active__c, MarlinNet_Admin__c, Mobile_Number_Solicitation__c, Receive_All_Notifications__c, 
                                   Used_as_PG__c, Receive_All_Loan_Notifications__c, Text_Opt_Out__c, FraudFlag__c, DOZISF__ZoomInfo_Company_ID__c, DOZISF__ZoomInfo_Enrich_Status__c, DOZISF__ZoomInfo_First_Updated__c,
                                    DOZISF__ZoomInfo_Id__c, DOZISF__ZoomInfo_InboxAI_ID__c, DOZISF__ZoomInfo_Last_Updated__c, DOZISF__ZoomInfo_Non_Matched_Reason__c, Account_Setup_Complete_Date__c,
                                     Phone_1_Opted_In_for_Auto_Texts__c, Phone_2_Opted_In_for_Auto_Texts__c, Phone_3_Opted_In_for_Auto_Texts__c, ZoomInfo_Company_Phone__c,
                                      ZoomInfo_Contact_City__c, ZoomInfo_Contact_Country__c, ZoomInfo_Contact_State__c, ZoomInfo_Contact_Street__c, ZoomInfo_Contact_Zip_Code__c,
                                       ZoomInfo_Direct_Phone__c, ZoomInfo_Email__c, ZoomInfo_First_Name__c, ZoomInfo_FullName__c, ZoomInfo_Job__c, ZoomInfo_Last_Name__c, 
                                       ZoomInfo_Management_Level__c, ZoomInfo_Mobile_Phone_Number__c, ZoomInfo_Supplemental_Email__c, ZoomInfo_Title__c, ZoomInfo_Website__c, 
                                       ccan__c, ccid__c, Phone2_Updated__c, Phone1_Status__c, Phone1_Updated__c, Phone2_Status__c, Phone3_Status__c, Phone3_Updated__c, Direct_Phone_Status__c, 
                                       Direct_Phone_Updated__c, Home_Phone_Status__c, Home_Phone_Updated__c, Email_Status__c, Email_Updated__c, Alternate_Email_Status__c, Alternate_Email_Updated__c, 
                                       Next_Financing_Need__c, Credit_Score__c from contact where Id =: primaryContact.Contact__c Limit 1];
                                    
                    return conRecord;
            }
        }
        return conRecord;
    }
}