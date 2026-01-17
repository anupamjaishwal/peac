public with sharing class SL_InfoleaseContractRequestWrapper extends SL_InfoleaseIntegrationRequestWrapper{
    private static String NITRO_API = 'BW.UPDATE.CONTRACT';

    public Request Request;

    public SL_InfoleaseContractRequestWrapper() {
        Header = new Header();
        Header.NitroApi = NITRO_API;
        Request = new Request();
    }

    public class Request {

        public String ContractNumber ;
        public String UserId;
        public String CUST_NAME;
        public String CUST_ADDRESS1;
        public String CUST_ADDRESS2;
        public String CUST_ADDRESS3;
        public String CUST_CITY;
        public String CUST_STATE;
        public String CUST_ZIP;
        public String AR_NAME;
        public String AR_ADDRESS1;
        public String AR_ADDRESS2;
        public String AR_ADDRESS3;
        public String AR_CITY;
        public String AR_STATE;
        public String AR_ZIP;
        public String AR_ATTN;
        //public String CsDefaultFederalTaxId;
        public String INVOICE_CODE;
        public String USER_CODE;
        public String UM_ALPHA_FIELD3;
        public String INSURANCE_CODE;
        public String PUR_ORDER_NUM;

        //new fields
        public String FED_ID;
        public String QUOTE_BUYOUT;
        public String INVOICE_FRMT;
    }
}