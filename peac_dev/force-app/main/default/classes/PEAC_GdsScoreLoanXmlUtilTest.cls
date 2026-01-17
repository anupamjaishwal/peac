/********************************************************************************************************************
@Author:Vinod Rathod(LTIMindtree)
@Description: This test class Serializes object representation of the request/response to and from xml
@Created Date:July-24-2024 	    
*********************************************************************************************************************/
@isTest
public class PEAC_GdsScoreLoanXmlUtilTest {
    
    // Prepare test data
    @testSetup public static void setupData() {
        
        User adminUser = TestDataFactory.createTestUser();
        System.runAs(adminUser){
            
            // Create a test Account Reacord
            SL_SCTestData.createAccountAndContracts(1,1);
            Account testAccount = [SELECT Id,CCID__c,RecordTypeId FROM Account LIMIT 1];
            testAccount.Date_Established__c = Date.newInstance(2022,10, 1);
            testAccount.Account_State_Of_Incorporation__c = 'CO';
            testAccount.CCID__c = 'C000223';
            update testAccount;
            
            // Create a test Opportunity Reacord
            Opportunity testOpportunity = new Opportunity (AccountId = testAccount.Id, Actual_Annual_Revenue__c = 3, Actual_Average_Daily_Balance__c = 4,
                                                           Annual_Revenue__c = 2, Appeal_Information_Provided__c = 'Financial Statements', Application_Status__c = 'Manually Approved',
                                                           Approved_Amount__c = 1000, Approved_Document_Delivery_Method__c = 'DocuSign Only', Average_Daily_Balance__c = 5,
                                                           Billing_Attention_To__c = 'Accounts Payable', Broker_Book_Method__c = 'F',
                                                           Broker_Tax_Method__c = 'F', Business_Phone__c = '1234567898',
                                                           CloseDate = Date.today(), Contract_Status__c = 'Active', Custom_Stipulation__c = 'A1', 
                                                           Decision_Date__c = Datetime.now(), Docs_Out_Dollar__c = 13, Document_Delivery_Method__c = 'DocuSign',
                                                           Equip_Code1__c = 'Air Compressors', Equipment_Cost__c = 1201,
                                                           Equipment_Description__c = 'equipment 1', Final_Product_Loc__c = '1 stnarnia',
                                                           Funded_Amount__c = 14, Funded_Term__c = 15, Gross_Finance__c = -1201, Income_Method__c = 'E', Invoice_Code__c = 'A',
                                                           Invoice_Description__c = 'equipment 1', Late_Charge_Rate__c = 15, Lead_Invoice_Days__c = 22, Loan_Purpose__c = 'Other',
                                                           Loan_Score__c = 6, Oppt_FS_Use_Of_Funds__c = 'testing purposes',
                                                           Name = 'test XmlOpp ', StageName = 'Application',Payment_Amount__c=1,
                                                           RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan Booking').getRecordTypeId(),
                                                           Primary_Source__c = 'LendingTree',Requested_Amount__c = 55000,CaseCenter__c = 'L000345',PK__c ='2321602',
                                                           CustomerType__c = 'NEW',Decision_Status__c = 'PE',
                                                           UD_TMETRIX_POLICY_SCORE__c='UD_TMETRIX_POLICY_SCORE__c',UD_TMETRIX_REASON_CODE__c = 'UD_TMETRIX_REASON_CODE__c',UD_TMETRIX_REVIEW_STATUS__c= 
                                                           'UD_TMETRIX_REVIEW_STATUS__c',UD_TMETRIX_RISK_RATING__c = 'UD_TMETRIX_RISK_RATING__c',UD_TMETRIX_TRUE_IP__c = 'UD_TMETRIX_TRUE_IP__c');
            Insert testOpportunity;
            
            // Create a test Contact Reacord
            Contact con = new Contact (AccountId = testAccount.Id, FirstName = 'testGds' ,
                                       LastName = 'testbeni' , OtherStreet = 'test', OtherCity = 'test', 
                                       OtherStateCode = 'CA', OtherPostalCode = String.valueOf(111118), Title = 'title2' , 
                                       SSN__c = '112233489', BirthDate = Date.today (),
                                       Email = 'test@email' + String.valueOf(111116) + '.com', Validity_Verify__Status__c = 'Valid',
                                       OtherState='California',Ownership_Pct__c = 100);
            Insert con;
            
            // Create a test OpportunityContactRole Reacord
            OpportunityContactRole role = new OpportunityContactRole();
            role.ContactId = con.Id;
            role.OpportunityId = testOpportunity.Id;
            role.Role = 'Primary Contact';
            insert role;
            
            Test.startTest();
            // Create a test Guarantor Reacord
            Guarantor__c g = new Guarantor__c(
                Opportunity__c = testOpportunity.Id,
                Contact__c = con.Id,
                Account__c = testAccount.id,
                RP_PRIN_GUAR_CODE__c = 'Guarantor',
                PG_Number__c = 'PG1',
                RecordTypeId = Schema.SObjectType.Guarantor__c.getRecordTypeInfosByName().get('Personal').getRecordTypeId(), 
                Type__c = 'Personal Guarantor'
            );
            Insert g;
            
            // Add Attachment record (simulate FS attachment)
            Opportunity_Attachment__c att = new Opportunity_Attachment__c(
                Name = 'Bank Statement',
                Opportunity__c = testOpportunity.Id,
                Type__c = 'FS - Bank Statements'
            );
            insert att;
            
            // Create a test Financial Reacord related to the Opportunity
            Financial__c financialRecord = new Financial__c(
                Opportunity__c = testOpportunity.Id
            );
            upsert financialRecord;
            
            // Create a test Bank Information Reacord 
            Financial_Bank_Information__c bankInformationRecord = new Financial_Bank_Information__c(
                Name = 'Bank Of America',
                Bank_Account_Type__c = 'Checking',
                Bank_Account_Number_No_Masking__c = '1213123213266',
                Bank_Address__c = '530 east ohio street',
                Bank_City__c = 'Indianapolis',
                Bank_State__c = 'IN',
                Bank_Zip__c = '46204',
                Financial__c = financialRecord.Id,
                Opportunity__c = testOpportunity.Id
            );
            insert bankInformationRecord;
            
            // Create a test Bank Statement Reacord 
            Bank_Statement__c bankStatementRecord = new Bank_Statement__c(
                Amount_of_Deposits__c = 1000,
                Number_of_Deposits__c = 4,
                Opening_Balance__c = 1000,
                Daily_Average_Balance__c = 1000,
                Ending_Balance__c = 1000,
                Negative_Days__c = 3,
                NSFs__c = 5,
                Opportunity__c = testOpportunity.Id,
                Bank_Information__c = bankInformationRecord.Id
            );
            upsert bankInformationRecord;
            
            // Create a test Request Company Reacord
            Gds_Score_Request_Company__c company1 = New Gds_Score_Request_Company__c(Name ='Company 1',Guarantor_Based_On__c = g.Id,
                                                                                     RecordTypeId = Schema.SObjectType.Gds_Score_Request_Company__c.getRecordTypeInfosByName().get('Loan').getRecordTypeId(),Request_Based_On__c=testAccount.Id);
            Insert company1;
            
            
            // Create a test Request Individual Reacord
            List<Gds_Score_Request_Individual__c>  pgList= New List<Gds_Score_Request_Individual__c>();
            pgList.add(new Gds_Score_Request_Individual__c(Name = 'PG1',Guarantor_Based_On__c = g.Id,Request_Based_On__c=con.Id,
                                                           RecordTypeId = Schema.SObjectType.Gds_Score_Request_Individual__c.getRecordTypeInfosByName().get('Loan').getRecordTypeId()));
            Insert pgList;
            
            // Create a test Gds Score Reacord
            Gds_Score__c scoreReq = New Gds_Score__c(
                Opportunity__c = testOpportunity.Id,
                Company_1__c = company1.Id,
                Personal_Guarantor_1__c = pgList[0].Id,
                Financial__c = financialRecord.Id,
                RecordTypeId = Schema.SObjectType.Gds_Score__c.getRecordTypeInfosByName().get('Loan').getRecordTypeId()
            );
            Insert scoreReq;
            
            // Create a test FraudFlags Reacord
            Webservice_Field__c gdsFraudFlags = New Webservice_Field__c(
                LN_Total_Exposure__c = '24517',
                LS_Total_Exposure__c = '6517',
                Total_Exposure__c = '18000',
                Opportunity__c = testOpportunity.Id,
                Stored_Procedure__c = 'getGDSFraudFlags');
            Insert gdsFraudFlags;
            // Create a test CustCreditExpLoan Reacord
            Webservice_Field__c gdsGetCustCreditExpLoan = New Webservice_Field__c(
                LN_Total_Exposure__c = '24517',
                LS_Total_Exposure__c = '6517',
                Total_Exposure__c = '18000',
                Opportunity__c = testOpportunity.Id,
                Stored_Procedure__c = 'getGdsGetCustCreditExpLoan'
            );
            Insert gdsGetCustCreditExpLoan;
            
        }
        Test.stopTest();      
    }
    
    //Calling all serialize Method
    @isTest static void testSerializeRequest() {
        
        String xml;
        //User adminUser = TestDataFactory.createTestUser();
        //System.runAs(adminUser){
            
            // Create a test GDSScoreLoanReqRespBean Wraper 
            PEAC_GDSScoreLoanReqRespBean bean = New PEAC_GDSScoreLoanReqRespBean();
            Test.startTest();
            bean.scoreReq = [SELECT Id, Name,Offer_Pricing_Model__c,PK__c,Info_Lease_Number__c,Ccan__c,CCID__c,Application_Date__c,CALLTYPE__c, Opportunity__c, Company_1__c ,Personal_Guarantor_1__c, 
                             APPLICATION_LP_STATUS__c,Agreed_to_Legal_Disclaimer__c,Loan_Amount__c,Loan_Type__c,Loan_Purpose__c,Other_Purpose__c,MLC_Exposure__c
                             ,Total_Exposure__c,Annual_Revenue__c,Average_Daily_Balance__c,Processor__c,Competitor__c,Financial__c,Gds_Score_External_Id__c
                             ,Amount_of_Deposits_Average__c,NSFs_Average__c,Ratio_ADB_Monthly_Revenue__c,Number_of_Deposits_Average__c,Bank_Annual_Revenue__c,Total_Bank_Statements__c,Suspicious_Activity__c
                             ,Months_Verified_TIB__c,TIB_Override__c,Negative_Days_Average__c,Daily_Average_Balance_Average__c,Opening_Balance_Average__c,Ending_Balance_Average__c,RecordType.Name,PQ_Expiration__c,
                             UD_TMETRIX_POLICY_SCORE__c,UD_TMETRIX_REASON_CODE__c,UD_TMETRIX_REVIEW_STATUS__c,UD_TMETRIX_RISK_RATING__c,UD_TMETRIX_TRUE_IP__c,SICCODE_Preference_Input__c FROM Gds_Score__c Limit 1];
            
            bean.company1 = [SELECT Id, Name, Guarantor_Based_On__c, RecordType.Name, Request_Based_On__c,
                             Address__c, City__c, Id_Number__c, State__c, Zip__c, FAX__c, Contact__c, Contact_Title__c, Website__c, 
                             Phone__c, Primary_Contact_Phone__c, Primary_Contact_Email__c, Account_State_Of_Incorporation__c, Date_Established__c, 
                             DBA__c, STRUCTURE__c,Is_Company_Changed__c FROM Gds_Score_Request_Company__c Limit 1];
            
            bean.pgs = [SELECT Id, Name, Guarantor_Based_On__c, RecordType.Name, Request_Based_On__c,
                        First_Name__c, Last_Name__c, Suffix__c, Address__c, City__c,PG_Number__c,Validity_Verify_Status__c,
                        State__c, Zip__c, Ssn__c, Ccan__c, Email__c,Is_PG_Changed__c,Is_PG_Deleted__c,
                        Birthdate__c, Phone__c, Title__c, OWNERSHIP_PERCENTAGE__c,Final_Email_Validity_Result__c FROM Gds_Score_Request_Individual__c Limit 1];
            
            
            bean.wsFields = [SELECT Id, Name, Opportunity__c, Stored_Procedure__c,LS_CS_Customer_Name__c, LS_CS_Customer_CCAN__c, LN_CS_Customer_CCID__c, LS_CS_First_App_Date__c, LS_CS_First_Book_Date__c,
                             LS_CS_Last_Reject_Date__c, LS_CS_Total_Apps__c, LS_CS_Num_Of_Approved_Apps__c, LS_CS_Num_Of_Rejected_Apps__c, LS_CS_Num_Of_Pending_Apps__c,
                             LS_CS_Num_Of_Cancelled_Apps__c, LS_CS_Num_Of_PO_Issued_Apps__c, LS_CS_Num_Of_Booked_Apps__c, LS_CS_Booking_Percent_Of_Approved__c, LS_CS_Approval_Percent_Of_Decisions__c,
                             LS_CS_Num_Of_Active_Contracts__c, LS_CS_Actual_Charge_Off__c, LS_CS_Charge_Off_Count__c, LS_Delinquency_Status__c, LS_CS_Current_Deliquency_31_Count__c,
                             LS_CS_Current_Deliquency_61_Count__c, LS_CS_Current_Deliquency_91_Count__c, LS_CS_Current_Deliquency_121_Count__c, LS_CS_Current_Deliquency_31_CBR__c, LS_CS_Current_Deliquency_61_CBR__c,
                             LS_CS_Current_Deliquency_91_CBR__c, LS_CS_Current_Deliquency_121_CBR__c, LS_CS_Current_Deliquency_Total_CBR__c, LS_CS_Current_Del_31_CBR_Percent__c, LS_CS_Current_Del_61_CBR_Percent__c,
                             LS_CS_Current_Del_91_CBR_Percent__c, LS_CS_Current_Del_121_CBR_Percent__c, LS_CS_Current_Rental_Total__c, LS_CS_Hist_Delinquency_Count_1_30__c, LS_CS_Hist_Delinquency_Count_31_60__c,
                             LS_CS_Hist_Delinquency_Count_61_90__c, LS_CS_Hist_Delinquency_Count_91_above__c, LS_CS_Curr_Pay_Past_Due_1_30__c, LS_CS_Curr_Pay_Past_Due_31_60__c, LS_CS_Curr_Pay_Past_Due_61_90__c,
                             LS_CS_Curr_Pay_Past_Due_91_above__c, LS_CS_Curr_Miscellaneous_Due__c, LS_CS_Curr_Miscellaneous_Past_Due__c, LS_CS_Curr_Late_Charges_Due__c, LS_CS_Curr_Late_Charges_Taxes_Due__c,
                             LN_CS_First_App_Date__c, LN_CS_First_Book_Date__c, LN_CS_Last_Reject_Date__c, LN_CS_Total_Apps__c, LN_CS_Num_Of_Ever_Approved_Apps__c,
                             LN_CS_Num_Of_Approved_Apps__c, LN_CS_Num_Of_Rejected_Apps__c, LN_CS_Num_Of_Pending_Apps__c, LN_CS_Num_Of_Cancelled_Apps__c, LN_CS_Num_Of_Booked_Apps__c,
                             LN_CS_Booking_Percent_Of_Approved__c, LN_CS_Approval_Percent_Of_Decisions__c, LN_CS_Num_Of_Active_Contracts__c, LN_CS_Actual_Charge_Off__c, LN_CS_Charge_Off_Count__c,
                             LN_CS_Current_Days_Delinquent__c, LN_CS_Total_Delinquency_Count__c, LN_CS_Max_Delinquent__c, LN_CS_Delinquent_1__c, LN_CS_Delinquent_2_5__c,
                             LN_CS_Delinquent_6_10__c, LN_CS_Delinquent_11_30__c, LN_CS_Delinquent_31__c, LN_CS_Number_of_Payments_Made__c, CS_Length_Of_Relationship__c,
                             CS_Existing_Customer__c, COVID_Restructure__c, LS_CS_Approved_Exposure_Amount__c, LS_CS_Booked_Amount__c, LS_CS_PO_Issued_Amount__c,
                             LS_CS_Net_Investment__c, LS_Direct_Exposure__c, LS_CG_Approved_Exposure_Amount__c, LS_CG_PO_Issued_Amount__c, LS_CG_Net_Investment__c,
                             LS_Indirect_Exposure__c, LS_PA_Approved_Exposure_Amount__c, LS_PA_PO_Issued_Amount__c, LS_PA_Net_Investment__c, LS_Affliate_Exposure__c,
                             LN_CS_Approved_Exposure_Amount__c, LN_CS_Amount_Financed__c, LN_CS_Contract_Receivable__c, LN_CS_Principal_Balance__c, LS_Total_Exposure__c,
                             LN_Total_Exposure__c, Total_Exposure__c FROM Webservice_Field__c WHERE Stored_Procedure__c = 'getGdsGetCustCreditExpLoan'];
            
            
            bean.wsFieldsFraud = [SELECT Id, Name, LN_Total_Exposure__c , LS_Total_Exposure__c , Total_Exposure__c, Opportunity__c, Stored_Procedure__c,
                                  Account_FraudFlag__c,PG1_FraudFlag__c,PG2_FraudFlag__c,PC_FraudFlag__c FROM Webservice_Field__c WHERE Stored_Procedure__c = 'getGDSFraudFlags'];
            
            Opportunity opp = [SELECT Id, Name From Opportunity Limit 1];
            bean.opp = opp;
            bean.oppId = opp.Id;
            
            PEAC_GdsScoreLoanXmlUtil.serializeApplicationData(bean.scoreReq,'APPLICATIONDATA');
            PEAC_GdsScoreLoanXmlUtil.serializeThreatMetrix(bean.scoreReq,'THREATMETRIX');
            PEAC_GdsScoreLoanXmlUtil.serializeDWHGetCusCredExp(bean.wsFields,'DWH_GetCustomerCreditExposure');
            PEAC_GdsScoreLoanXmlUtil.serializeGetFraudFlags(bean.wsFieldsFraud,'GetFraudFlags');
            //Calling serializeRequest Method
            xml = PEAC_GdsScoreLoanXmlUtil.serializeRequest(bean);
            
        //}
        Test.stopTest();
        // Assert the results
        System.assert(xml.startsWith('<?xml'));
        System.assert(xml.contains('</APPLICATIONDATA>'));
        System.assert(xml.contains('</ORIGINATORS>'));
        System.assert(xml.contains('</THREATMETRIX>'));
        System.assert(xml.contains('</COMPANY1>'));
        System.assert(xml.contains('</GetFraudFlags>'));
        System.assert(xml.contains('</DWH_GetCustomerCreditExposure>'));
        
    } 
   
    
}