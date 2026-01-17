/**
 * Created by jhber on 2/13/2019.
 */

public with sharing virtual class TC_BWRequestBean {

    public Header Header;
    //public Request Request;

    public class Header {
        public String NitroApi;
    }

    public abstract class Request {}
}