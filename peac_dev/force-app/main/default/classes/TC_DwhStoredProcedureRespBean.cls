/** @author : Tamarack Consulting, Inc.
 * @date : 12/21/20
 * @description: 
 *
 */
public with sharing class TC_DwhStoredProcedureRespBean {

    public List<ResultBean> results;

    public TC_DwhStoredProcedureRespBean() {
        this.results = new List<TC_DwhStoredProcedureRespBean.resultBean>();
    }

    public class resultBean{
         @AuraEnabled
        public String Customer_CCAN;
         @AuraEnabled
        public String Lease_OnBalanceSheet_Total_Exposure;
         @AuraEnabled
        public String Existing_Loan_Customer;
         @AuraEnabled
        public String Lease_Active_Contracts_Payments_Made;
         @AuraEnabled
        public String Lease_Disposed_Contracts_Payments_Made;
         @AuraEnabled
        public String Lease_Gain_Loss_Check;
         @AuraEnabled
        public String Lease_Curr_61_Plus_Delin;
         @AuraEnabled
        public String Lease_Ever_91_Plus_Delin;
         @AuraEnabled
        public String Lease_Active_Contracts_Past_31;
         @AuraEnabled
        public String Loan_Total_Charge_Off_Count;
         @AuraEnabled
        public String Loan_Curr_15_Plus_Days_Delin;
         @AuraEnabled
        public String Prior_PG_On_App;
         @AuraEnabled
        public String COVID_Restructure;
         @AuraEnabled
        Public String UD_DEALER_PREFERRED;
         @AuraEnabled
        public String UD_DEALER_CLASSIFICATION;

        //Added per SAL-2770 DWH fraud response
        @AuraEnabled
        public String BizCityMatch;
        @AuraEnabled
        public String BizStateMatch;
        @AuraEnabled
        public String BizZipMatch;
        @AuraEnabled
        public String BizPhoneMatch;
        @AuraEnabled
        public String BizInfoMatch;
        @AuraEnabled
        public String CustomerType;
        @AuraEnabled
        public String FraudReviewStatus;
        @AuraEnabled
        public String Fraud_Review_Flag;
        @AuraEnabled
        public String RunNewCustomerFlow;

        //Added per SAL-2770 DWH pg response
        @AuraEnabled
        public String PG1SSNMatch;
        @AuraEnabled
        public String PG2SSNMatch;
        @AuraEnabled
        public String PG1EmailMatch;
        @AuraEnabled
        public String PG2EmailMatch;
        @AuraEnabled
        public String PG1LastNameMatch;
        @AuraEnabled
        public String PG2LastNameMatch;
        @AuraEnabled
        public String PersonalInfoMatch;

        //Used for SAL-2754 to add distance to bean to be mapped back to Webservice Field
        public Decimal DealerDistance;
    }
}