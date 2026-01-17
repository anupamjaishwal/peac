public with sharing class SL_InfoleaseInsuranceRequestWrapper extends SL_InfoleaseIntegrationRequestWrapper{
    private static String NITRO_API = 'BW.UPDATE.INSURANCE';

    public Request Request;

    public SL_InfoleaseInsuranceRequestWrapper() {
        Header = new Header();
        Header.NitroApi = NITRO_API;
        Request = new Request();
    }

    public class Request {
        public String UserId;
        public String InsuranceId;
        public String INSUR_CARRIER;
        public String INSUR_EFFECTIVE_DATE;
        public String INSUR_EXPIRE_DATE;
        public String INSUR_CANCEL_DATE;
        public String INSUR_STATUS;
    }
}