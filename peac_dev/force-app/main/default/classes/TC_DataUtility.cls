/*
* @author : sfdcdev, Tamarack Consulting, Inc.
* @date : 06/23/2015
* @description: Customer Portal
*
* © Copyright 2003 - 2017 Tamarack Consulting, Inc.  All Rights Reserved.
*
*/

public with sharing class TC_DataUtility {
    
    public static SObject queryAllById(Id recordId) {
        if (recordId==null) return null;
        List<SObject> records = queryAllByIds( new List<Id>{recordId} );
        return records[0];
    }

    public static List<SObject> queryAllByIds(List<Id> ids) {
        if (ids==null || ids.isEmpty()) return null;

        System.debug(ids);
        DescribeSObjectResult describeResult = ids[0].getSobjectType().getDescribe();
        Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();

        // Get all of the fields on the object
        List<String> fieldNames = new List<String>( fieldMap.keySet() );

        // Build a Dynamic Query String.
        String soqlQuery = ' SELECT ' + String.join(fieldNames, ',') + ' FROM ' + describeResult.getName() + ' Where Id IN: ids';

        // Need to return a generic list of sObject because we don't necessarily know exactly what the object is.
        List<SObject> records = Database.query(soqlQuery);

        return records;
    }

    public static String createSelectAllQueryString (String sObjectApiName, String whereClause, Set <String> parentFieldsSet) {
        if (parentFieldsSet == null) parentFieldsSet = new Set <String> ();

        Map <String, Schema.SObjectType> allSObjects = Schema.getGlobalDescribe();
        Schema.SObjectType sObjectSchema = allSObjects.get(sObjectApiName);
        Schema.DescribeSObjectResult d = sObjectSchema.getDescribe();
        Map<String, Schema.SObjectField> fldObjMap = d.fields.getMap();

        String queryString = 'SELECT ';
        for(Schema.SObjectField s : fldObjMap.values()) {
            queryString += s.getDescribe().getName() + ',';
        }

        if (!parentFieldsSet.isEmpty()) {
            for (String s: parentFieldsSet) {
                queryString += s + ',';
            }
        }

        // Trim last comma
        queryString = queryString.removeEnd(',');

        // Finalize query string
        queryString += ' FROM ' + sObjectApiName;
        queryString += ' WHERE ';

        if (!String.isEmpty(whereClause)) {
            queryString += whereClause;
        } else {
            queryString += 'Id != null LIMIT 1000';
        }
        System.debug ('$$$$$ Query String: ' + queryString);
        return queryString;
    }

    public static Opportunity getAllFieldsOnOpportunityByRecordId (String recordId) {
        return TC_DataUtility.getAllFieldsOnOpportunityByRecordId (recordId, null);
    }

    public static Opportunity getAllFieldsOnOpportunityByRecordId (String recordId, Set <String> parentFieldsSet) {
        String q = TC_DataUtility.createSelectAllQueryString('Opportunity', ' Id=:recordId', parentFieldsSet);
        return (Opportunity) Database.query(q);
    }

    public static Account getAllFieldsOnAccountByRecordId (String recordId) {
        return TC_DataUtility.getAllFieldsOnAccountByRecordId (recordId, null);
    }

    public static Account getAllFieldsOnAccountByRecordId (String recordId, Set <String> parentFieldsSet) {
        String q = TC_DataUtility.createSelectAllQueryString('Account', ' Id=:recordId', parentFieldsSet);
        return (Account) Database.query(q);
    }

    public static Contact getAllFieldsOnContactByRecordId (String recordId) {
        return TC_DataUtility.getAllFieldsOnContactByRecordId (recordId, null);
    }

    public static Contact getAllFieldsOnContactByRecordId (String recordId, Set <String> parentFieldsSet) {
        String q = TC_DataUtility.createSelectAllQueryString('Contact', ' Id=:recordId', parentFieldsSet);
        return (Contact) Database.query(q);
    }

    public static List<String> getPickListValues(String objectName, String fieldName) {
        List<String> values = new List<String>{};
        List<String> types = new List<String>{objectName};
            Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);
            for(Schema.DescribeSobjectResult res : results) {
                for (Schema.PicklistEntry entry : res.fields.getMap().get(fieldName).getDescribe().getPicklistValues()) {
                    if (entry.isActive()) {values.add(entry.getValue());}
                }
            }
            return values;
        }

    public static Boolean checkPicklistIsValid(String objectName, String picklistName, String selection) {

        List<String> validValues = getPickListValues(objectName, picklistName);
        return validValues.contains(selection);
    }

}