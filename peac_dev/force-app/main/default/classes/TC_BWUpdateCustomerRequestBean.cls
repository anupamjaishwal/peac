/**
 * Created by jhber on 2/12/2019.
 */

public with sharing class TC_BWUpdateCustomerRequestBean extends TC_BWRequestBean {

    private static String NITRO_API = 'BW.UPDATE.CUSTOMER.UDO';

    public Request Request;

    public TC_BWUpdateCustomerRequestBean() {
        Header = new Header();
        Header.NitroApi = NITRO_API;
        Request = new Request();
    }

    public class Request {
        public String Ccan;
        public String CsDefaultSicCode;
        public String CsUdCode; //Fraud Indicator
        public String CsParentCode;
        public String CsDbRating;
        //public String CsDefaultContactPhone;
    }
}