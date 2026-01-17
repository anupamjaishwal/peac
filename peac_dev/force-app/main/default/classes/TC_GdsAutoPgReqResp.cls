/**
 * @description       : SAL-2310 - New Integration call to GDS Auto PG Webservice
 * @author            : Joseph Cadd
 * @group             : 
 * @last modified on  : 12-30-2020
 * @last modified by  : Joseph Cadd
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   12-21-2020   Joseph Cadd   Initial Version
**/
public with sharing class TC_GdsAutoPgReqResp {
    
    public Id recordId; // Can accept lead or opp 
    public String objectName;
    public Lead lead;
    public Opportunity opp;
    public Account acc;
    public Webservice_Field__c wsFields;

    public cls_ApplicationData request;
    public cls_Record response;
    public String errorMessage;

    public TC_GdsAutoPgReqResp(Id recordId) {

        // Accepts Lead or Opp Ids
        this.objectName = recordId.getSObjectType().getDescribe().getName();

        this.recordId = recordId;

        if (objectName == 'Opportunity') {
            this.opp = (Opportunity) TC_DataUtility.queryAllById(recordId);
            this.acc = (Account) TC_DataUtility.queryAllById(this.opp.AccountId);

            List<Webservice_Field__c> latestWebServiceFieldRecord = [SELECT Id,Manager_PG_Override__c,Reason_PG_Required__c, BizInfoMatch__c, RunNewCustomerFlow__c, CustomerDealerDistance__c 
                FROM Webservice_Field__c WHERE Opportunity__c=:recordId ORDER BY CreatedDate DESC LIMIT 1
            ];
            this.wsFields = !latestWebServiceFieldRecord.isEmpty() ? latestWebServiceFieldRecord[0] : null;
         } else if (objectName == 'Lead') {
            this.lead = (Lead) TC_DataUtility.queryAllById(recordId);
        }
        

        this.request = new cls_ApplicationData();
        this.response = new cls_Record();
        this.errorMessage = '';
    }


    // Start Request Class Definitions
    // Start Request Class Definitions
    // Start Request Class Definitions
    /*
        REQUEST EXAMPLE

        <APPLICATIONDATA>
            <APPLICATIONDATE>2020-09-28</APPLICATIONDATE>
            <BUSTYPE>03</BUSTYPE>
            <CALLTYPE>SF_PG</CALLTYPE>
            <CCAN>2016010</CCAN>
            <EQUIP.CODE>1234567</EQUIP.CODE>
            <EQUIP_COST>1500</EQUIP_COST>
            <LOANAMOUNT>2900</LOANAMOUNT>
            <OPPORTUNITY_ID>TESTID0001</OPPORTUNITY_ID>
            <COMPANY1>
                <NAME>Brownsville Scrap Paper, Inc.</NAME>
                <ADDRESS>5850 FM 511</ADDRESS>
                <CITY>Brownsville</CITY>
                <STATE>TX</STATE>
                <ZIPCODE>78521</ZIPCODE>
                <ZIPEXTENSION />
                <PHONE>9568381999</PHONE>
                <IDNUMBER>2016010</IDNUMBER>
                <DBDUNSNUMBER />
                <EBFILENUMBER />
                <STATEINCORP />
                <DBA />
                <SELFREPORTEDBUSSTARTDATE />
                <STRUCTURE />
                <PRIMARYCONTACT_EMAIL />
                <PRIMARYCONTACT_FINALEMAILVALIDITY />
                <PRIMARYCONTACT_VALIDITYVERIFY_RESULT />
                <Equip_Address />
                <Equip_City />
                <Equip_State />
                <Equip_Zip />
            </COMPANY1>
            <PGSEQUENCING>
                <Total_Exposure>1</Total_Exposure>
                <UD_EXIST_CUST>5</UD_EXIST_CUST>
                <UD_ACT_CONT_PYMTS_MADE>10</UD_ACT_CONT_PYMTS_MADE>
                <UD_DISP_CONT_PYMTS_MADE>0</UD_DISP_CONT_PYMTS_MADE>
                <UD_GAIN_LOSS_CHECK>5</UD_GAIN_LOSS_CHECK>
                <Lease_61plus_Delin>0</Lease_61plus_Delin>
                <Lease_Ever91plus_Delin>0</Lease_Ever91plus_Delin>
                <UD_ACTIVE_CONT_PAST_31>0</UD_ACTIVE_CONT_PAST_31>
                <Loan_Total_Charge_Off_Count>5</Loan_Total_Charge_Off_Count>
                <Loan_Current_Days_Delinquent>5</Loan_Current_Days_Delinquent>
                <PriorPGonApp>0</PriorPGonApp>
                <COVID_Restructure>0</COVID_Restructure>
                <UD_DLR_PREFERRED>0</UD_DLR_PREFERRED>
                <UD_DLR_CLASSIFICATION>0</UD_DLR_CLASSIFICATION>
            </PGSEQUENCING>
            <MATCHING>
                <BizInfoMatch>1</BizInfoMatch> // 1 or 0
                <RunNewCustomerFlow>1</RunNewCustomerFlow>  // 1 or 0
            </MATCHING>
            <CustomerType></CustomerType>  // NEW, REPEAT, EXISTING
            <CustomerDealerDistance>125</CustomerDealerDistance> 
        </APPLICATIONDATA>
    */

    // PARENT REQUEST CLASS 
    public class cls_ApplicationData {  // XML Node = <APPLICATIONDATA>
        public String APPLICATIONDATE='';      // <APPLICATIONDATE>2020-09-28</APPLICATIONDATE>
        public String DEALERNUMBER='';          // <DEALERNUMBER>310464.8400</DEALER_NUMBER>
        public String BUSTYPE='';              // <BUSTYPE>03</BUSTYPE>
        public String CALLTYPE = 'SF_PG';   // <CALLTYPE>SF_PG</CALLTYPE>
        public String CCAN='';                 // <CCAN>2016010</CCAN>
        public String EQUIP_CODE='';           // <EQUIP.CODE>1234567</EQUIP.CODE>
        public String EQUIP_COST='';          // <EQUIP_COST>1500</EQUIP_COST>
        public String LOANAMOUNT='';          // <LOANAMOUNT>2900</LOANAMOUNT>
        public String OPPORTUNITY_ID='';       // <OPPORTUNITY_ID>TESTID0001</OPPORTUNITY_ID>
        public String CustomerType='';       // <CustomerType></CustomerType>  // NEW, REPEAT, EXISTING
        public String CustomerDealerDistance=''; // <CustomerDealerDistance>125</CustomerDealerDistance> 
        public String UD_DLR_ENTERED_DATE=''; // <UD_DLR_ENTERED_DATE>YYYY-MM-DD</UD_DEALER_ENTERED_DATE>
        public String timesDelinquentOver90=''; // <timesDelinquentOver90></timesDelinquentOver90>
        Public String Accounttype=''; //<Account_type>ABC123</Account_type>
        //Added by Tyler for SAL-2732
        public String ORT = ''; //<ORT>Express</ORT>

        public cls_Company1 COMPANY1 = new cls_Company1();
        public cls_PgSequencing PGSEQUENCING = new cls_PgSequencing();
        public cls_Matching MATCHING = new cls_Matching(); 
        
    }
    public class cls_Company1 {                 // XML Node = COMPANY1
        public String NAME='';                         // <NAME>Brownsville Scrap Paper, Inc.</NAME>
        public String ADDRESS='';                      // <ADDRESS>5850 FM 511</ADDRESS>
        public String CITY='';                         // <CITY>Brownsville</CITY>
        public String STATE='';                        // <STATE>TX</STATE>
        public String ZIPCODE='';                      // <ZIPCODE>78521</ZIPCODE>
        public String ZIPEXTENSION='';                 // <ZIPEXTENSION />
        public String PHONE='';                        // <PHONE>9568381999</PHONE>
        public String IDNUMBER='';                     // <IDNUMBER>2016010</IDNUMBER>
        public String DBDUNSNUMBER='';                 // <DBDUNSNUMBER />
        public String EBFILENUMBER='';                 // <EBFILENUMBER />
        public String STATEINCORP='';                  // <STATEINCORP />
        public String DBA='';                          // <DBA />
        public String SELFREPORTEDBUSSTARTDATE='';     // <SELFREPORTEDBUSSTARTDATE />
        public String STRUCTURE='';                    // <STRUCTURE />
        public String PRIMARYCONTACT_FIRSTNAME;        // <PRIMARYCONTACT_FIRSTNAME />
        public String PRIMARYCONTACT_LASTNAME;         // <PRIMARYCONTACT_LASTNAME />
        public String PRIMARYCONTACT_PHONE;            // <PRIMARYCONTACT_PHONE />
        public String PRIMARYCONTACT_EMAIL='';                  // <PRIMARYCONTACT_EMAIL />
        public String PRIMARYCONTACT_FINALEMAILVALIDITY='';     // <PRIMARYCONTACT_FINALEMAILVALIDITY />
        public String PRIMARYCONTACT_VALIDITYVERIFY_RESULT='';  // <PRIMARYCONTACT_VALIDITYVERIFY_RESULT />
        public String EQUIP_ADDRESS='';  // <Equip_Address />
        public String EQUIP_ADDRESS2=''; // <Equip_Address2 />
        public String EQUIP_CITY='';  // <Equip_City />
        public String EQUIP_STATE='';  // <Equip_State />
        public String EQUIP_ZIP='';  // <Equip_Zip />
    } 
    public class cls_PgSequencing {             // XML Node = <PGSEQUENCING>
        public String Total_Exposure='';               // <Total_Exposure>1</Total_Exposure>
        public String UD_EXIST_CUST='';                // <UD_EXIST_CUST>5</UD_EXIST_CUST>
        public String UD_ACT_CONT_PYMTS_MADE='';       // <UD_ACT_CONT_PYMTS_MADE>10</UD_ACT_CONT_PYMTS_MADE>
        public String UD_DISP_CONT_PYMTS_MADE='';      // <UD_DISP_CONT_PYMTS_MADE>0</UD_DISP_CONT_PYMTS_MADE>
        public String UD_GAIN_LOSS_CHECK='';           // <UD_GAIN_LOSS_CHECK>5</UD_GAIN_LOSS_CHECK>
        public String Lease_61plus_Delin='';           // <Lease_61plus_Delin>0</Lease_61plus_Delin>
        public String Lease_Ever91plus_Delin='';       // <Lease_Ever91plus_Delin>0</Lease_Ever91plus_Delin>
        public String UD_ACTIVE_CONT_PAST_31='';       // <UD_ACTIVE_CONT_PAST_31>0</UD_ACTIVE_CONT_PAST_31>
        public String Loan_Total_Charge_Off_Count='';  // <Loan_Total_Charge_Off_Count>5</Loan_Total_Charge_Off_Count>
        public String Loan_Current_Days_Delinquent=''; // <Loan_Current_Days_Delinquent>5</Loan_Current_Days_Delinquent>
        public String PriorPGonApp='';                 // <PriorPGonApp>0</PriorPGonApp>
        public String COVID_Restructure='';            // <COVID_Restructure>0</COVID_Restructure>
        public String UD_DLR_PREFERRED='';             // <UD_DLR_PREFERRED>0</UD_DLR_PREFERRED>
        public String UD_DLR_CLASSIFICATION='';        // <UD_DLR_CLASSIFICATION>0</UD_DLR_CLASSIFICATION>
        public String Equipment_type='';                //<Equipment_type>String1,String2<Equipment_type>
    }
    public class cls_Matching {
        public String BizInfoMatch='';
        public String RunNewCustomerFlow='';
    }


    // Start Response Class Definitions
    // Start Response Class Definitions
    // Start Response Class Definitions

    // PARENT REQUEST CLASS 
    public class cls_Record {
        
    }


}