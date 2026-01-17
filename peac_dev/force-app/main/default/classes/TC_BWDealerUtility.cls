/**
 * Created by jhber on 7/5/2019.
 */

public with sharing class TC_BWDealerUtility {

    public static Account getAccountFields(String id) {
        System.debug('getAccountFields - ' + id);
        Account account = [SELECT Id,
                RecordType.Id,
                RecordType.Name,
                Name,
                Dealer_Number__c,
                Equipment_Type__c,
                Business_Phone__c,
                Account_Branch__c,
                Business_Address__c,
                Business_Address2__c,
                Business_City__c,
                Business_State__c,
                Business_Zip__c,
                Account_Dealer_Group_Code__c,
                Account_Dealer_Status__c,
                BD_Manager__c,
                Website,
                Owner.Id,
                Owner.Personnel_Number__c,
                Primary_Contact__r.Name,
                Primary_Contact__r.Email,
                Pass_Thru_Maintenance_Frequency__c,
                Overage_Remit_Frequency__c,
                Dealer_Payment_Type__c,
                Type,
        (Select Name, EMail
        FROM Contacts LIMIT 1),
        (Select Name,
                Review_Date__c,
                Review_Type__c,
                Next_Scheduled_Review__c,
                Status__c,
                Additional_Review_Comments__c
        from Dealer_Surveillances__r LIMIT 1)
        FROM Account where Id = :id];

        return account;
    }

    public static TC_BWDealerRequestBean mapSurveillanceFields(Dealer_Surveillance__c surv) {
        TC_BWDealerRequestBean request = new TC_BWDealerRequestBean();

        Account account = getAccountFields(surv.Account__c);

        //Start Mapping
        request.Request.DealerNumber = account.Dealer_Number__c;
        if (surv != null) {
            System.debug('Dealer Mapping - Surveillance found: ' + surv.Name +'/'+surv.Status__c);
            //Check Account Status
            if (    account.Account_Dealer_Status__c == 'Approved' ||
                    account.Account_Dealer_Status__c == 'Active' ||
                    account.Account_Dealer_Status__c == '1x Exception') {
                if (surv.Status__c == 'Completed') {
                    System.debug('Dealer Mapping including Dealer Surveillance <'+surv.name + '>');
                    request.Request.DlrAReviewDate = surv.Review_Date__c != null ? surv.Review_Date__c.format() : null;
                    request.Request.DlrAFiscalYearEnd = '1';
                    request.Request.DlrAFollowUpDate = surv.Next_Scheduled_Review__c != null ? surv.Next_Scheduled_Review__c.format(): null;
                    request.Request.DlrAStatementDate = Date.today().format();
                    request.Request.DlrAExtentAudit = '1';
                    request.Request.DlrAComments = surv.Additional_Review_Comments__c;
                }
                else System.debug('Dealer Mapping excluding Dealer Surveillance "'+surv.name + '", Surveillance Status is '+surv.Status__c);
            } else System.debug('Dealer Mapping excluding Dealer Surveillance "'+surv.name + '", Account Status is '+account.Account_Dealer_Status__c);
        } else System.debug('Dealer Mapping Surveillance object not found');
        return request;

    }

    public static TC_BWDealerRequestBean mapFields(Account account) {
 
        Map<String, String> branchMap = TC_BWDealerUtility.getMetaDataMapping('Branch');
        // Account_Equipment_Code to Equipment_Code
        Map<String, String> equipmentMap = TC_BWDealerUtility.getMetaDataMapping('Equipment_Code');
        Map<String, String> dealerStatusMap = TC_BWDealerUtility.getMetaDataMapping('UD_DEALER_STATUS');
        TC_BWDealerRequestBean request = new TC_BWDealerRequestBean();

        //Start Mapping
        request.Request.DealerNumber = account.Dealer_Number__c;
        request.Request.DLRBranch = account.Account_Branch__c != null ? branchMap.get(account.Account_Branch__c) : null;
        request.Request.DlrCreditPhone = account.Business_Phone__c;

        request.Request.TbVdmAddr1 = account.Business_Address__c;
        request.Request.TbVdmAddr2 = account.Business_Address2__c;
        request.Request.TbVdmCity = account.Business_City__c;
        request.Request.TbVdmState = account.Business_State__c;
        request.Request.TbVdmZip = account.Business_Zip__c;

        request.Request.ApaMailAddr1 = account.Business_Address__c;
        request.Request.ApaMailAddr2 = account.Business_Address2__c;
        request.Request.ApaMailCity = account.Business_City__c;
        request.Request.ApaMailState = account.Business_State__c;
        request.Request.ApaMailZip = account.Business_Zip__c;

        //Hardcoding country to '001' for now, since account.Business_Country__c is not collected for dealers.
        //request.Request.TbVdmCountry = '001';

        request.Request.DlrUdTable1 = account.Overage_Remit_Frequency__c;
        request.Request.DlrDealerId = account.Dealer_Number__c;
        request.Request.DlrActiveDealer = account.Account_Dealer_Status__c != null ? dealerStatusMap.get(account.Account_Dealer_Status__c) : null;

        request.Request.TbVdmName = account.Name;
        request.Request.DlrEquipCode = TC_EquipmentCodeUtil.removeDot(account.Equipment_Type__c != null ? equipmentMap.get(TC_MultiSelectUtil.getFirstValue(account.Equipment_Type__c)) : null);
        request.Request.DlrSalesperson = account.Owner.Personnel_Number__c;
        Contact c = TC_BWDealerUtility.getPrimaryContact(account.Id);
        if (c != null) {
            request.Request.DlrCreditName = c.Name;
            request.Request.DlrCreditEmail = c.Email;
        }

        //Payee info
        Payee__c p = TC_BWDealerUtility.getPayeeInfo(account.Id);
        if (p != null) {
            request.Request.DlrUdAlphaNumeric1 = p.SL_Vendor_ID__c;
        }

        request.Request.DlrMarketingRep = account.Owner.Personnel_Number__c;

        request.Request.DlrUdTable2 = account.Overage_Remit_Frequency__c;
       // request.Request.DlrMMRPaymentType = account.Dealer_Payment_Type__c;
        request.Request.DlrMMRPaymentType = '01';
        //request.Request.DlrUdTable3 = account.Overage_Remit_Frequency__c;

        request.Request.TbVdmTableType = account.Type;

        return request;
    }

    public static Dealer_Surveillance__c getDealerSurveillance(String id) {
        List<Dealer_Surveillance__c> surv = [SELECT Name,
                Account__c,
                Review_Date__c,
                Review_Type__c,
                Next_Scheduled_Review__c,
                Status__c,
                Additional_Review_Comments__c
        FROM Dealer_Surveillance__c WHERE Id = :id];

        if (!surv.isEmpty()) return surv[0];
        return null;
    }
    
    
    

    public static boolean checkDealerNumber(String phoneNumber) {
        if (phoneNumber == null || phoneNumber.length() != 10 || !phoneNumber.containsOnly('0123456789')) return false;
        return true;
    }
    /**
     * Utility function to turn a phone Number into the InfoLease XXXXXX.XXXX dealer number
     *
     * @param phoneNumber Phone Number to translate. Must contain only digits, and be at least 9 characters long
     *
     * @return null if invalid, otherwise a String with the last 4 digits of the passed in phone number
     *          being the last four digits of the dealer number, and the first 6 digits as the first portion.
     */
    public static String formatDealerNumber(String phoneNumber) {
        if (!checkDealerNumber(phoneNumber)) return null;

        return phoneNumber.left(6) + '.' + phoneNumber.right(4);
    }

    /**
 * Utility class to return the MARLIN_Rapport_Mapping__mdt as a Map<Key, Value> based on the field passed in.
 *
 * @param fieldName the Field_Name__c of the set of rows you want in you map
 *
 * @return Map<String, String> where the Label is the key, and the Rapport_Value__c is the value.
 */
    public static Map<String, String> getMetaDataMapping(String fieldName) {

        List<MARLIN_Rapport_Mapping__mdt> mappings = [SELECT Label, Rapport_Value__c FROM MARLIN_Rapport_Mapping__mdt where Field_Name__c = :fieldName];

        Map<String, String> metaDataMap = new Map<String, String>();

        for (MARLIN_Rapport_Mapping__mdt mapping : mappings) {
            metaDataMap.put(mapping.Label, mapping.Rapport_Value__c);
        }

        return metaDataMap;
    }

    public static Contact getPrimaryContact(String accountId) {
        Contact c;
        if (accountId != null && String.isNotEmpty(accountId)) {
            List<AccountContactRelation> contacts = [SELECT Contact.Name, Contact.Email, Roles
            FROM AccountContactRelation WHERE Account.Id = :accountId];

            if (!contacts.isEmpty()) c=contacts[0].Contact;
        }

        return c;
    }

    public static Payee__c getPayeeInfo(String accountId) {
        Payee__c p;
        if (accountId != null && String.isNotEmpty(accountId)) {
            List<Payee__c> payees = [SELECT Id, SL_Vendor_ID__c FROM Payee__c WHERE Dealer__c = :accountId];
            if (!payees.isEmpty()) p=payees[0];
        }

        return p;
    }
}