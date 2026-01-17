public with sharing class SL_InfoleaseAssetRequestWrapper extends SL_InfoleaseIntegrationRequestWrapper{
    private static String NITRO_API = 'BW.UPDATE.ASSET';

    public Request Request;

    public SL_InfoleaseAssetRequestWrapper() {
        Header = new Header();
        Header.NitroApi = NITRO_API;
        Request = new Request();
    }

    public class Request {
        public String AssetNumber;
        public String UserId;
        public String EQUIP_DESC;
        public String MODEL;
        public String A_MANUFACTURER_YEAR;
        public Decimal QUANTITY;
        public String SERIAL_NUMBER;
        public String LICENSE_NUMBER;
        /*public String EQUIP_ADDR1;
        public String EQUIP_ADDR2;
        public String EQUIP_CITY;
        public String EQUIP_STATE;
        public String EQUIP_ZIP;
        public String EQUIP_COUNTRY;*/
        //public String A_EFFECTIVE_DATE;
        /*public String STATE_TAX_CODE;
        public String A_MISC_STATE_TAX_CODE;
        public String A_LC_STATE_TAX_CODE;
        public Decimal STATE_TAX_PCT;
        public String CNTY_TAX_CODE;
        public String A_MISC_CNTY_TAX_CODE;
        public String A_LC_CNTY_TAX_CODE;
        public Decimal CNTY_TAX_PCT;
        public Decimal TCNTY_TAX_PCT;
        public String CITY_TAX_CODE;
        public String A_MISC_CITY_TAX_CODE;
        public String A_LC_CITY_TAX_CODE;
        public Decimal CITY_TAX_PCT;
        public Decimal TCITY_TAX_PCT;
        public String ACAU_ALPHA_FIELD1;
        public String ACAU_ALPHA_FIELD2;*/
    }
}