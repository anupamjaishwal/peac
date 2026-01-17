/**
 * Created by jheidman on 2019-02-28.
 */

public with sharing class TC_BWDealerResponseBean extends TC_BWResponseBean {

    public Response Response;

    public class Response extends TC_BWResponseBean.Response {
        public String Success;
        public String DealerNumber;
    }
}