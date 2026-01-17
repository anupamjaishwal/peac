/**
 * @File Name          : SL_InfoleaseIntegrationRequestWrapper.cls
 * @Description        : Base request class for CCAN Account SF to IL via BW
 * @Author             : Silverline
 * @Group              :
 * @Last Modified By   :
 * @Last Modified On   :
 * @Modification Log   :
 * Ver       Date            Author                 Modification
 * 1.0    10/06/2021      Silverline                Initial Version
 */
public with sharing virtual class SL_InfoleaseIntegrationRequestWrapper {
    public Header Header;

    public class Header {
        public String NitroApi;
    }

    public abstract class Request {}
}