/**
 * Created by jhber on 2/12/2019.
 */

public with sharing class TC_BWUpdateDealerRequestBean extends TC_BWRequestBean {

    private static String NITRO_API = 'BW.UPDATE.DEALER.UDO';

    public Request Request;

    public TC_BWUpdateDealerRequestBean() {
        Header = new Header();
        Header.NitroApi = NITRO_API;
        Request = new Request();
    }

    public class Request {
        public String DealerNumber;
        public String DlrUdTable2;
    }
}