/**
 * This class is provided open source under the MIT license
 * This class is used to provide data to the AuraFieldSetDisplay and AuraRelatedRecordFieldSetDisplay
 * components
 */
global with sharing class AuraFieldSetDisplayCont {
    //These class properties are visible to the JS controller when the return value is this class constructed
    @AuraEnabled global List<String> fields {Get;Set;}
    @AuraEnabled global String objectName {Get;Set;}
    @AuraEnabled global Id recordId {Get;Set;}
    @AuraEnabled global String userTheme {Get;Set;}
    @AuraEnabled global List<AuraSaveResult.ErrorResult> errors {Get;Set;}
    private static List<AuraSaveResult.ErrorResult> errorsFound;

    //----------------------Controller Functions--------------------------//

    /**
     * Gets a constructor with the fields based on the lookup field and related field set.
     *
     * @param      lookupFieldToFieldSet  The lookup field to field set
     * @param      recordId               The record Id
     *
     * @return     The constructed object with the information setup based on the data obtained from the record
     */
    @AuraEnabled global static AuraFieldSetDisplayCont getFieldsFromLookupFieldAndFieldSet(
            String lookupFieldToFieldSet,
            Id recordId) {
        AuraFieldSetDisplayCont returnObj = new AuraFieldSetDisplayCont();
        errorsFound = errorsFound == null ? new List<AuraSaveResult.ErrorResult>() : errorsFound;
        if (recordId == null) {
            User u = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
            if (u.AccountId != null) recordId = u.AccountId;
        }
        if (String.isNotBlank(lookupFieldToFieldSet) && recordId != null) {
            List<String> fieldReferenceList = lookupFieldToFieldSet.split(':');

            if (fieldReferenceList.size() == 2) {
                String lookupField = fieldReferenceList[0];
                String fieldSetName = fieldReferenceList[1];
                //Checking to see if the record has a related lookup for the Id that was passed
                Id lookupId = getRelatedLookupId(lookupField,String.valueOf(recordId.getSobjectType()),recordId);
                if (lookupId != null) {
                    returnObj.objectName = String.valueOf(lookupId.getSobjectType());
                    returnObj.fields = getFieldsFromFieldSetMembers(returnObj.objectName, fieldSetName);
                    returnObj.recordId = lookupId;
                }
            }
            if (fieldReferenceList.size() != 2) errorsFound.add(newError('Lookup lookupFieldToFieldSet parameter needs to be the lookupField:fieldSetName',''));
        }
        if (String.isBlank(lookupFieldToFieldSet)) errorsFound.add(newError('There was no lookupFieldToFieldSet parameter Defined!',''));
        //if (recordId == null) errorsFound.add(newError('No Record Id passed!',''));

        returnObj.userTheme = UserInfo.getUiThemeDisplayed();
        if (!errorsFound.isEmpty()) returnObj.errors = errorsFound;
        return returnObj;
    }

    /**
     * Gets the fields from field set.
     *
     * @param      objectName    The object name
     * @param      fieldSetName  The field set name
     *
     * @return     The constructed object with the fields and any applicable errors
     */
    @AuraEnabled global static AuraFieldSetDisplayCont getFieldsFromFieldSet(String objectName, String fieldSetName) {
        AuraFieldSetDisplayCont returnObj = new AuraFieldSetDisplayCont();
        String objNm = objectName != null && objectName.startsWith('UserInfo-') ? objectName.substringAfter('UserInfo-') : objectName;

        errorsFound = errorsFound == null ? new List<AuraSaveResult.ErrorResult>() : errorsFound;
        returnObj.fields = getFieldsFromFieldSetMembers(objNm,fieldSetName);
        returnObj.userTheme = UserInfo.getUiThemeDisplayed();

        if (objectName.startsWith('UserInfo-')) {
            if (objNm == 'Account' || objectName == 'Contact') {
                User thisUser = [SELECT Id, AccountId, ContactId FROM User WHERE Id = :UserInfo.getUserId()];
                if (objNm == 'Account') returnObj.recordId = thisUser.AccountId;
                if (objNm == 'Contact') returnObj.recordId = thisUser.ContactId;
                if (objNm == 'User') returnObj.recordId = thisUser.Id;
                returnObj.objectName = objNm;
            }
        }
        if (!errorsFound.isEmpty()) returnObj.errors = errorsFound;

        return returnObj;
    }

    //-----------------Local Functions---------------------//

    /**
     * Gets the fields from field set members.
     *
     * @param      objectName    The object name
     * @param      fieldSetName  The field set name
     *
     * @return     The fields from field set members.
     */
    @TestVisible static List<String> getFieldsFromFieldSetMembers(String objectName, String fieldSetName) {
        List<String> returnList = new List<String>();
        List<Schema.FieldSetMember> fieldSetMembers = new List<Schema.FieldSetMember>();

        try {
            fieldSetMembers = Schema.getGlobalDescribe().get(objectName).getDescribe().FieldSets.getMap().get(fieldSetName).getFields();
        }catch(Exception e) {
            handleException(e);
        }
        for (Schema.FieldSetMember fsm : fieldSetMembers) {
            returnList.add(fsm.getFieldPath());
        }
        return returnList;
    }

    /**
     * Gets the related lookup Id.
     *
     * @param      lookupFieldName        The lookup field name
     * @param      primaryObjectName      The primary object name
     * @param      primaryObjectRecordId  The primary object record Id
     *
     * @return     The related lookup Id.
     */
    @TestVisible static Id getRelatedLookupId(String lookupFieldName, String primaryObjectName, Id primaryObjectRecordId) {
        Id returnId;

        if (String.isNotBlank(lookupFieldName) && String.isNotBlank(primaryObjectName) && primaryObjectRecordId != null) {
            List<String> stringFormat = new List<String> {lookupFieldName,primaryObjectName};
            String query = String.format('SELECT {0} FROM {1} WHERE Id = :primaryObjectRecordId', stringFormat);
            try {
                List<SObject> sobjs = Database.query(query);
                if (!sobjs.isEmpty()) returnId = (Id) sobjs[0].get(lookupFieldName);
            } catch(Exception e) {
                handleException(e);
            }
        }

        if (String.isBlank(lookupFieldName)) errorsFound.add(newError('There was no lookupFieldName parameter Defined!',''));
        if (String.isBlank(primaryObjectName)) errorsFound.add(newError('There was no primaryObjectName parameter Defined!',''));
        if (String.isBlank(primaryObjectRecordId)) errorsFound.add(newError('There was no primaryObjectRecordId parameter Defined!',''));

        return returnId;
    }


    /**
     * Handles any exceptions
     *
     * @param      e     The exception
     */
    @TestVisible static void handleException(Exception e) {
        errorsFound.add(newError(e.getMessage(),e.getTypeName()));
        System.debug(e.getMessage());
        System.debug(e.getStackTraceString());
    }

    /**
     * Constructs a new error message
     *
     * @param      message  The message
     * @param      code     The code
     *
     * @return     The constructed error
     */
    @TestVisible static AuraSaveResult.ErrorResult newError(String message, String code) {
        return new AuraSaveResult.ErrorResult(message,code);
    }
}