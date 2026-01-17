/**
 * Created by jhber on 2/12/2019.
 */

public with sharing class TC_BWCustomerRequestBean extends TC_BWRequestBean {

    private static String NITRO_API = 'BW.CREATE.CUSTOMER.UDO';

    public Request Request;

    public TC_BWCustomerRequestBean() {
        Header = new Header();
        Header.NitroApi = NITRO_API;
        Request = new Request();
    }

    public class Request {
        public String CsDefaultName;
        public String CsDefaultContactName ;
        public String CsDefaultTitle ;
        public String CsDefaultDateOfBirth ;
        public String CsDefaultFederalTaxId ;
        public String CsDefaultCellPhone;
        public String CsDefaultContactPhone ;
        public String CsDefaultContactEmail ;
        public Decimal CsDefaultCreditScoring ;
        public String CsBusiness ;
        public String CsBusinessType ;
        public Date CsUdDate1 ;
        public String Ccan;
        public String CSAcdContactEmail;


        public String CsDefaultAddr1;
        public String CsDefaultCity ;
        public String CsDefaultState ;
        public String CsDefaultCountry ;
        public String CsDefaultZip ;
        public String CsDefaultDba ;
        public String CsDefaultArName;

        public String CsDefaultArAddr1;
        public String CsDefaultArCity;
        public String CsDefaultArCountry ;
        public String CsDefaultArState ;
        public String CsDefaultArZip ;
        
        public String CsBusinessPhone;
        public String CsDefaultContactFaxPhone;
        public String CsDbRating;
        public STring CsParentCode;
        public String CsDefaultSicCode;
        public String CsDefaultArAddr2;
        public String CsDefaultAddr2;

        public String AusrAdditionalData ;
    }
}