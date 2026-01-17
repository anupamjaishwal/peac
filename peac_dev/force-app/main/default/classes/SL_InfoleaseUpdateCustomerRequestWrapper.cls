/**
 * @File Name          : SL_InfoleaseUpdateCustomerRequestWrapper.cls
 * @Description        : Request Wrapper class for CCAN Account SF to IL via BW
 * @Author             : Silverline
 * @Group              :
 * @Last Modified By   :
 * @Last Modified On   :
 * @Modification Log   :
 * Ver       Date            Author                 Modification
 * 1.0    10/06/2021      Silverline                Initial Version
 */
public with sharing class SL_InfoleaseUpdateCustomerRequestWrapper extends SL_InfoleaseIntegrationRequestWrapper{
    private static String NITRO_API = 'BW.UPDATE.CUSTOMER.UDO';

    public Request Request;
    public Response response;
    public class Response{
        public Header Header;
        public Request Request;
        Response(){
            this.Header = new Header();
            Header.NitroApi = NITRO_API;
            this.Request = new Request();
        }
    }
    
    public class Header{
        public string NitroApi;
    }

    public SL_InfoleaseUpdateCustomerRequestWrapper() {
        this.response = new Response();
        this.Request = new Request();
    }

    public class Request {

        public String Ccan ;
        public String CsDefaultName;
        public String CsDefaultAddr1;
        public String CsDefaultAddr2;
        public String CsDefaultAddr3;
        public String CsDefaultCity ;
        public String CsDefaultState ;
        public String CsDefaultCountry ;
        public String CsDefaultZip ;
        public String CsDefaultDba ;
        public String CsDefaultFederalTaxId ;
        public String CsDefaultArName;
        public String CsDefaultArAddr3;
        public String CsDefaultArAddr2;
        public String CsDefaultArAddr1;
        public String CsDefaultArCity;
        public String CsDefaultArCountry ;
        public String CsDefaultArState ;
        public String CsDefaultArZip ;
    }
}