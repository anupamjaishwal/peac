/**
 * Created  on 12/26/18.
 */

public with sharing class TC_DatabaseUtil {

    public static void dmlRecords (List <TC_RecordWrapper> rws, String sObjectType) {

        List <SObject> records = new List <SObject> ();

        for (TC_RecordWrapper rw : rws) {
            if (!rw.dupe && !rw.readOnly) {
                if (sObjectType == 'Account') {
                    records.add (rw.account);
                } else if (sObjectType == 'Contact') {
                    records.add (rw.contact);
                }
            }

        }

        if (records.isEmpty()) return;


        List <TC_DatabaseResult> results = new List <TC_DatabaseResult> ();

        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = FALSE;

        List <Id> orderList = new List <Id> ();
        Set <Id> dupeSet = new Set <Id> ();
        Map <Id, SObject> dupeMap = new Map <Id, SObject> ();
        Map <Id, SObject> recordMap = new Map <Id, SObject> ();
        Map <Integer, Id> indexsMap = new Map <Integer, Id> ();

        if (records != null && !records.isEmpty() && sObjectType != null && sObjectType != '') {

            List<Database.SaveResult> saveResults = Database.insert(records, dml);


            for (SObject record : records) {
                recordMap.put (record.Id, record);
            }

            for(Integer i=0;i<saveResults.size();i++){
                Database.SaveResult saveResult = saveResults.get(i);
                if (!saveResult.isSuccess()) {
                    for (Database.Error error : saveResult.getErrors()) {

                        //If there are duplicates, an error occurs
                        if (error instanceof Database.DuplicateError) {

                            Database.DuplicateError duplicateError = (Database.DuplicateError) error;
                            // Getting first dupe match
                            Id dupeId = duplicateError.getDuplicateResult ().getMatchResults ()[0].getMatchRecords ()[0].getRecord ().Id;

                            orderList.add (dupeId); // keeps the order in place
                            dupeSet.add (dupeId); // set for bulkification

                            indexsMap.put (i, dupeId);

                        } else {
                            throw new TC_LoanAppDMLUtilException ('Error saving: ' + error);
                        }
                    }
                } else {
                    orderList.add (saveResult.getId());
                    indexsMap.put (i, saveResult.getId());
                    //results.add (new TC_DatabaseResult (recordMap.get (saveResult.getId()), false));
                }

            }

            // querying the dupes
            if (!dupeSet.isEmpty()) {
                // passing in the map, so i don't have to write a function to translate the key into a dynamic query
                List <SObject> queriedRecords = queryObjectFields (sObjectType, 'Id IN :dupeSet', dupeSet);
                for (SObject record : queriedRecords) {
                    dupeMap.put (record.Id, record);
                }
            }

            for (Integer i = 0; i<rws.size (); i++) {
                if (indexsMap != null && indexsMap.get (i) != null && dupeMap != null && dupeMap.get (indexsMap.get (i)) != null) {

                    rws[i].dupe = true;
                    if (sObjectType == 'Account') {
                        rws[i].account = (Account) dupeMap.get (indexsMap.get (i));
                    } else if (sObjectType == 'Contact') {
                        rws[i].contact = (Contact) dupeMap.get (indexsMap.get (i));
                    }
                }
                rws[i].readOnly = true;

            }

        }
    }


    public class TC_DatabaseResult {
        public SObject record;
        public Boolean dupe;

        public TC_DatabaseResult (SObject record, Boolean dupe) {
            this.record = record;
            this.dupe = dupe;
        }
    }

    public static List <SObject> queryObjectFields (String objectType, String whereCluase, Set <Id> dupeSet) {


        Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectType);

        Map <String, Schema.SObjectField> fldObjMap = sObjType.getDescribe().fields.getMap();
        List <Schema.SObjectField> fldObjMapValues = fldObjMap.values();

        String queryString = 'SELECT ';
        for(Schema.SObjectField s : fldObjMapValues) {
            String fieldName = s.getDescribe().getName();


            // Continue building your dynamic query string
            queryString += fieldName + ',';
        }

        // Trim last comma
        queryString = queryString.removeEnd(',');

        // Finalize query string
        queryString += ' FROM ' +objectType;
        queryString += ' WHERE ' + whereCluase;
        System.debug(LoggingLevel.INFO, queryString);
        try {

            List <SObject> objList = Database.query(queryString);
            return objList;
        } catch (Exception e) {
            System.debug(e);
            return new List <SObject> ();
        }
    }

    public static List <SObject> queryManyObjectsFields (String objectType, Set <Id> recordIds) {


        Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectType);

        Map <String, Schema.SObjectField> fldObjMap = sObjType.getDescribe().fields.getMap();
        List <Schema.SObjectField> fldObjMapValues = fldObjMap.values();

        String queryString = 'SELECT ';
        for(Schema.SObjectField s : fldObjMapValues) {
            String fieldName = s.getDescribe().getName();


            // Continue building your dynamic query string
            queryString += fieldName + ',';
        }

        // Trim last comma
        queryString = queryString.removeEnd(',');

        // Finalize query string
        queryString += ' FROM ' +objectType;
        queryString += ' WHERE Id IN :recordIds';
        System.debug(LoggingLevel.INFO, queryString);
        try {

            List <SObject> objList = Database.query(queryString);
            return objList;
        } catch (Exception e) {
            System.debug(e);
            return new List <SObject> ();
        }
    }

    public static TC_DatabaseUtil.TC_RecordWrapper createQuriedRecordWrapper () {

        TC_RecordWrapper rw = new TC_RecordWrapper ();
        rw.dupe = false;
        rw.readOnly = true;
        return rw;
    }

    public class TC_RecordTypeIdWrapper {

        public Id pgRecordTypeId;
        public Id ccgRecordTypeId;
        public Id brokerRecordTypeId;
        public Id dealerRecordTypeId;
        public Id franchisorRecordTypeId;
        public Id endUserRecordTypeId;
        public Id pgJunctionRecordTypeId;
        public Id ccgJunctionRecordTypeId;

        public TC_RecordTypeIdWrapper () {
            Quick_App_Settings__c setting = Quick_App_Settings__c.getOrgDefaults ();

            //pgRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(setting.Personal_Guarantor_Record_Type_Label__c).getRecordTypeId();
            //ccgRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(setting.Cross_Corporate_Record_Type_Label__c).getRecordTypeId();
            brokerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(setting.Broker_Record_Type_Label__c).getRecordTypeId();
            dealerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(setting.Dealer_Record_Type_Label__c).getRecordTypeId();
            franchisorRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(setting.Franchiosor_Record_Type_Label__c).getRecordTypeId();
            endUserRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(setting.End_User_Record_Type_Label__c).getRecordTypeId();
            pgJunctionRecordTypeId = Schema.SObjectType.Guarantor__c.getRecordTypeInfosByName().get(setting.PG_Junction_Record_Type_Label__c).getRecordTypeId();
            ccgJunctionRecordTypeId = Schema.SObjectType.Guarantor__c.getRecordTypeInfosByName().get(setting.CCG_Junction_Record_Type_Label__c).getRecordTypeId();
        }
    }


    public class TC_RecordWrapper {
        @AuraEnabled
        public Account account;
        @AuraEnabled
        public Contact contact;
        @AuraEnabled
        public Asset__c equipment;
        @AuraEnabled
        public Guarantor__c guarantor; // maybe remove
        @AuraEnabled
        public Opportunity opportunity;

        @AuraEnabled
        public Dealer__c dealer;// maybe remove

        @AuraEnabled
        public Broker__c broker;// maybe remove
        @AuraEnabled
        public Franchisor__c franchisor;// maybe remove


        @AuraEnabled
        public Boolean readOnly = false;

        @AuraEnabled
        public Boolean dupe = false;

        @AuraEnabled
        public TC_RecordWrapper subRecord;

        @AuraEnabled
        public String role;

        @AuraEnabled
        public Boolean roleSaved = false;
        
        // only used in the is guarantor check
        // can't just check id becuase junction record will also need to be checked, which i'm not adding to this wrapper
        @AuraEnabled
        public Boolean saved = false;

        public TC_RecordWrapper (SObject record, Boolean readOnly) {
        }
        public TC_RecordWrapper () {}
    }


    public class TC_ClientWrapper {
        @AuraEnabled
        public TC_RecordWrapper company;
        @AuraEnabled
        public TC_RecordWrapper contact;
        @AuraEnabled
        public TC_RecordWrapper deal;
        @AuraEnabled
        public List <TC_RecordWrapper> ccgAccounts;
        @AuraEnabled
        public List <TC_RecordWrapper> pgContacts;
        @AuraEnabled
        public List <TC_RecordWrapper> pgs;// maybe remove
        @AuraEnabled
        public List <TC_RecordWrapper> ccgs;// maybe remove
        @AuraEnabled
        public List <TC_RecordWrapper> equipment;
        @AuraEnabled
        public List <TC_RecordWrapper> brokerAccounts;
        @AuraEnabled
        public List <TC_RecordWrapper> dealerAccounts;
        @AuraEnabled
        public List <TC_RecordWrapper> brokers;// maybe remove
        @AuraEnabled
        public List <TC_RecordWrapper> dealers;// maybe remove
        @AuraEnabled
        public List <TC_RecordWrapper> franchisorAccounts;
        @AuraEnabled
        public List <TC_RecordWrapper> franchisors;// maybe remove
        @AuraEnabled
        public String recordTypeName;
        @AuraEnabled
        public String recordTypeId;

        @AuraEnabled
        public String curentUserProfileName;
        
        @AuraEnabled
        public List <LightningPicklist> possibleCustomerContactRoles;
        
        @AuraEnabled
        public Boolean gdsScoreEnabled = false;

    }
    
    public class LightningPicklist {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;
        
        public LightningPicklist (String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
    

    public class TC_LoanAppDMLUtilException extends Exception {}
}