/**
 * @File Name          : SL_InfoleaseConstants.cls
 * @Description        : Constants class for CCAN Account SF to IL via BW
 * @Author             : Silverline
 * @Group              :
 * @Last Modified By   :
 * @Last Modified On   :
 * @Modification Log   :
 * Ver       Date            Author                 Modification
 * 1.0    10/06/2021      Silverline                Initial Version
 */
public with sharing class SL_InfoleaseConstants {
    public static String accountUpdateJob = 'Infolease Update Customer';
    public static String contractUpdateJob = 'Infolease Update Contract';
    public static String insuranceUpdateJob = 'Infolease Update Insurance';
    public static String assetUpdateJob = 'Infolease Update Asset';
    public static String errorOccurred = 'An error occurred. Details: ';
    public static String contactAdmin = 'Please contact your Salesforce Administrator and be sure to share this message or include it in a screenshot.';
}