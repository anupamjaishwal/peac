/**
 * Created by jhber on 3/12/2019.
 */

/**
 * Bridgeware Utility class. This is a class for utilities for the JSON driven newer
 * Bridgeware integrations.
 *
 * THIS IS A UTILITY CLASS AND SHOULD NOT CONTAIN ANY CODE SPECIFIC TO A PARTICULAR INTEGRATION CALL!!
 *
 */
public with sharing class TC_BWUtility {


    private static Bridgeware_Service_Setting__c setting;
    private static TC_BWUtility util;
    private TC_BWUtility() {}

    public static TC_BWUtility getInstance () {
        if (util == null) util = new TC_BWUtility ();
        return util;
    }

    public Bridgeware_Service_Setting__c getServiceSettings () {
        setting = Bridgeware_Service_Setting__c.getInstance();
        if (setting == null) setting = new Bridgeware_Service_Setting__c();

        return setting;
    }

    public void logInfo (String log) {
        if (getServiceSettings().Enable_Debug_Log__c)
            System.debug(LoggingLevel.INFO, '---INFO---> \n' + log );
    }

    public void logError (String log) {
        if (getServiceSettings().Enable_Debug_Log__c)
            System.debug(LoggingLevel.ERROR, '---ERROR----> \n' + log );
    }

    /**
    * Return all dealers associated to the given Opportunity ID if and only if the Opportunity is IFP or Franchise
    *
    * @param recordId - Id of the Opportunity to get associated dealers from
    *
    * @return
    */
    public static List<Dealer__c> getDealers(String recordId) {

        return [SELECT Name,
            Dealer__r.Name,
            Dealer__r.CCAN__c,
            Dealer__r.Sent_to_InfoLease_Date_Time__c,
            Dealer__r.Business_Address__c,
            Dealer__r.Business_City__c,
            Dealer__r.Business_State__c,
            Dealer__r.Business_Zip__c,
            Dealer__r.Business_Phone__c,
            Opportunity__r.Name,
            Opportunity__r.Id,
            Primary_Dealer__c
            FROM Dealer__c
            WHERE Opportunity__r.Id = :recordId AND Opportunity__r.Marlin_Business_Group__c IN ('IFP', 'Franchise')];
    }

    /**
     * Return all guranators associated to the given Opportunity ID and guarantor type
     *
     * @param recordId - Opportunity ID
     * @param guarantorType - Record Type of the Guarantors
     *
     * @return List of Guarantor__c
     */
    public static List<Guarantor__c> getGuarantors(String recordId, String guarantorType) {

        System.debug('Query - recordId: ' + recordId + ' type -' + guarantorType);
        Opportunity opp = [SELECT
        (SELECT RP_PRIN_GUAR_CODE__c,
                Account__r.Name,
                Account__r.CCAN__c,
                Contact__r.SSN__c,
                Contact__r.Sent_to_InfoLease_Date_Time__c,
                Account__r.Sent_to_InfoLease_Date_Time__c,
                Account__r.Business_Address__c,
                Account__r.Business_City__c,
                Account__r.Business_State__c,
                Account__r.Business_Zip__c,
                //GL 795 - Code for PC/CG issue, not need for Release 1.8
                Contact__r.Name,
                Contact__r.FirstName,
                Contact__r.LastName,
                Contact__r.OtherStreet,
                Contact__r.OtherCity,
                Contact__r.OtherStateCode,
                Contact__r.OtherPostalCode,
                Contact__c,
                Guarantor_Name__c,
                Title__c,
                DOB__c,
                Phone__c,
                Mobile__c,
                Email__c,
                Home_Street__c,
                Home_State__c,
                Home_Postal_Code__c,
                Home_City__c,
                Billing_Street__c,
                Billing_City__c,
                Billing_State__c,
                Billing_Country__c,
                Billing_ZipCode__c,
                Shipping_Street__c,
                Mailing_Street__c,
                Mailing_City__c,
                Mailing_Country__c,
                Mailing_State__c,
                Mailing_ZipCode__c,
                Shipping_City__c,
                Shipping_State__c,
                Shipping_Country__c,
                Shipping_ZipCode__c,
                Business_Phone__c,
                Name,
                RecordType.Name
        FROM Guarantor__r
        WHERE RecordType.Name = :guarantorType),
                Booked_to_External_System_Date__c,
                Booked_to_External_System_User__c,
                Late_Charge_Exempt__c
        FROM Opportunity
        WHERE Id = :recordId];

        return opp.Guarantor__r;
    }

    public static void requestToIL10(HttpRequest req){
        requestToIL10(req, 'general');
    }
    public static void requestToIL10(HttpRequest req, String urlOption){
        SL_InfoleaseUtils util = SL_InfoleaseUtils.getInstance();
        Blob headerValue = Blob.valueOf(util.getServiceSettings().IL10_Username__c + ':' + util.getServiceSettings().IL10_Password__c);
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        req.setHeader('Authorization', authorizationHeader);
        String endpointUrl = '';
        switch on urlOption{
            when 'general'{
                endpointUrl = util.getServiceSettings().IL10_Url__c;
            }
            when 'UCI'{
                endpointUrl = util.getServiceSettings().IL10_Uci_Url__c;
            }
            when 'ZIP'{
                endpointUrl = util.getServiceSettings().IL10_Zip_Url__c;
            }
        }
        req.setEndpoint(endpointUrl);
    }
    public static Boolean isIL10Record(SObject accountOrContract){
        return accountOrContract.get('Infolease_Environment__c') == '10' || accountOrContract.get('Infolease_Environment__c') == 'C';
    }
    public static Boolean isMigratedRecord(SObject accountOrContract){
        return accountOrContract.get('Infolease_Environment__c') == 'C';
    }
}