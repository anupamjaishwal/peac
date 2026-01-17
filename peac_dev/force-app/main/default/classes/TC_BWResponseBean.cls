/**
 * Created by jheidman on 2019-02-28.
 */

public with sharing virtual class TC_BWResponseBean {

    public Header Header;
    public Response Response;
    //public Request Request;

    public class Header {
        public String NitroApi;
    }

    public virtual class Response {
        //public Boolean Success;
        public List<String> Messages;
        public List<String> Errors;
    }

    /**
     * Total hack to remove the "response:" object wrapping the JSON coming back from BW.
     * This is needed because we have nested object with the same name, "response" and "Response"
     *
     * @param json The JSON string to remove the out response object from
     *
     * @return Bean without the outer response object.
     */
    public static String unWrap(String jsonString) {

        if (jsonString.contains('"response":{')) {
            return jsonString.remove('"response":{').removeEnd('}');
        }
        return jsonString;
    }
}