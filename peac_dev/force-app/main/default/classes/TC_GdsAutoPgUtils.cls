public with sharing class TC_GdsAutoPgUtils {
    
    public static TC_DwhStoredProcedureRespBean.resultBean TestDwhResponse() {
        TC_DwhStoredProcedureRespBean.resultBean dwhResults = new TC_DwhStoredProcedureRespBean.resultBean();

        dwhResults.Customer_CCAN='1'; 
        dwhResults.Lease_OnBalanceSheet_Total_Exposure='5'; 
        dwhResults.Existing_Loan_Customer='10';
        dwhResults.Lease_Active_Contracts_Payments_Made='0'; 
        dwhResults.Lease_Disposed_Contracts_Payments_Made='5'; 
        dwhResults.Lease_Gain_Loss_Check='0';
        dwhResults.Lease_Curr_61_Plus_Delin='0'; 
        dwhResults.Lease_Ever_91_Plus_Delin='0'; 
        dwhResults.Lease_Active_Contracts_Past_31='0';
        dwhResults.Loan_Total_Charge_Off_Count='5'; 
        dwhResults.Loan_Curr_15_Plus_Days_Delin='5'; 
        dwhResults.Prior_PG_On_App='0'; 
        dwhResults.COVID_Restructure='0';
        dwhResults.UD_DEALER_PREFERRED='0'; 
        dwhResults.UD_DEALER_CLASSIFICATION='0';
        
        return dwhResults;
    }
}