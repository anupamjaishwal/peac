/**
 * @File Name          : SL_InfoleaseIntegrationRequestWrapper.cls
 * @Description        : Base response wrapper class for CCAN Account SF to IL via BW
 * @Author             : Silverline
 * @Group              :
 * @Last Modified By   :
 * @Last Modified On   :
 * @Modification Log   :
 * Ver       Date            Author                 Modification
 * 1.0    10/06/2021      Silverline                Initial Version
 */
public with sharing virtual class SL_InfoleaseIntegrationResponseWrapper {
    public Responses response;
    /*public Header Header;
    public Response Response;*/
    
    public class Responses{
        public Header Header;
        public Response Response;
    }
    public class Header {
        public String NitroApi;
    }

    public virtual class Response {
        //public Boolean Success;
        public List<String> Messages;
        public List<String> Errors;
    }

    public static String wrap(String jsonString) {

        if (!jsonString.contains('{"response":')) {
            return jsonString = '{"response":' + jsonString + '}';
        }
        return jsonString;
    }

    public static String unWrap(String jsonString) {
        return wrap(jsonString);
    }
}