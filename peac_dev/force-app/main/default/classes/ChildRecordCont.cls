/**
 * This class is provided open source under the MIT license
 * This controller is that allows  the Child record display component to function
 */
public without sharing class ChildRecordCont {
    @AuraEnabled public String objectName {get;set;}
    @AuraEnabled public String parentId {get;set;}
    @AuraEnabled public String parentIdFieldNm {get;set;}
    @AuraEnabled public List<String> fieldList {get;set;}
    @AuraEnabled public Map<Id, List<AuraFieldDescription>> sobjectIdToFieldDesc {get;set;}
    @AuraEnabled public List<AuraFieldDescription> describedFieldList {get;set;}
    @AuraEnabled public List<List<AuraFieldDescription>> describedSobjectFieldsWithData {get;set;}
    @AuraEnabled public List<SObject> sObjects {get;set;}

    @AuraEnabled public static ChildRecordCont handleChildRecordInitFromParentField(String recId, String parentIdField, String fieldSetName, String subQueryRelationship, String whereConditions, String orderByConditions, Integer recordLimit) {
        ChildRecordCont crc = new ChildRecordCont();

        if (recordLimit == null) recordLimit = 5;

        if (String.isNotBlank(recId) && (recId instanceof Id) && String.isNotBlank(fieldSetName) && String.isNotBlank(subQueryRelationship)) {
            List<SObject> initRecords = Database.query('SELECT Id, '+parentIdField+' FROM '+Id.valueOf(recId).getSobjectType().getDescribe().getLocalName()+' WHERE Id = :recId');

            String parentId;

            if (!initRecords.isEmpty()) parentId = (Id) initRecords[0].get(parentIdField);

            if (parentId != null) {
                crc.parentId = parentId;
                DescribeSObjectResult pSobDesc = Id.valueOf(crc.parentId).getSobjectType().getDescribe();
                crc.objectName = getChildSObjectName(pSobDesc, subQueryRelationship);
                crc.fieldList = getFieldsFromFieldset(getChildSObjectName(pSobDesc, subQueryRelationship), fieldSetName);
                crc.describedSobjectFieldsWithData = new List<List<AuraFieldDescription>>();

                String query = 'SELECT Id, ';
                       query += '(SELECT '+String.join(crc.fieldList,',')+' FROM '+subQueryRelationship;
                       query += String.isNotBlank(whereConditions) ? ' WHERE '+whereConditions : '';
                       query += String.isNotBlank(orderByConditions) ? ' ORDER BY '+orderByConditions : '';
                       query += ' LIMIT '+recordLimit;
                       query +=') FROM '+pSobDesc.getLocalName()+' WHERE Id = :parentId';

                List<AuraFieldDescription> describedFields = populateBaseDescriedFields(crc.fieldList, crc.objectName);
                crc.describedFieldList = describedFields;


                //Going through the parent sobjects (there should only be one, but if no result is returned we won't error out
                for (SObject sobj : Database.query(query)) {
                    //Populating the child sobjects
                    crc.sObjects = sobj.getSObjects(subQueryRelationship);
                    //Getting the aura field describes for the child objects, they will allow for a more flexible approach
                    //to displaying a field (e.g. if SFDC doesn't support the sobject, this will allow us to have it
                    //represented artificially through the AuraFieldDisplay component
                    for (SObject cSobj : crc.sObjects) {
                        crc.describedSobjectFieldsWithData.add(getDescribedFieldsFromSobject(cSobj, describedFields));
                        //crc.sobjectIdToFieldDesc.put(cSobj.Id, getDescribedFieldsFromSobject(cSobj, describedFields));
                    }
                }

                if (crc.sObjects == null) crc.sObjects = new List<SObject>();
            }
        }

        return crc;
    }


    /**
     * @description             This function will get aura field descriptions from the pre-defined blank describe fields
     *
     * @param sobj              The sobject to populate the field values with
     * @param describedFields   The default described fields that will be cloned and the field value updated
     *
     * @return                  The list of aura field descriptions
     */
    private static List<AuraFieldDescription> getDescribedFieldsFromSobject(SObject sobj, List<AuraFieldDescription> describedFields) {
        List<AuraFieldDescription> returnList = new List<AuraFieldDescription>();

        for (AuraFieldDescription describedFld : describedFields) {
            AuraFieldDescription afd = (AuraFieldDescription) JSON.deserialize(JSON.serialize(describedFld), AuraFieldDescription.class);
            afd.fieldValue = String.valueOf(sobj.get(afd.fieldName));
            returnList.add(afd);
        }

        return returnList;
    }

    /**
     * @description                     This function will handle the child record initialization
     *
     * @param parentRecordID            The Id of the parent record
     * @param childObjParentFldFieldSet The field set of the sobject name to parent field name to field set
     * @param whereConditions           The where conditions to filter upon
     * @param orderByConditions         The condition to order the results by
     * @param recordLimit               The record limit of how many records to return
     *
     * @return
     */
    @AuraEnabled public static ChildRecordCont handleChildRecordInit(String parentRecordID, String childObjParentFldFieldSet, String whereConditions, String orderByConditions, Integer recordLimit) {
        ChildRecordCont crc = new ChildRecordCont();
        if (parentRecordID != null && String.isNotBlank(childObjParentFldFieldSet)) {
            List<String> splitVals = childObjParentFldFieldSet.split(':');
            String childObjName = splitVals[0];
            String parentField = splitVals[1];
            String fieldSetName = splitVals[2];

            crc.fieldList = getFieldsFromFieldset(childObjName, fieldSetName);
            String q = 'SELECT '+String.join(crc.fieldList,',')+' FROM '+childObjName;
                   q+= ' WHERE '+parentField +' =:parentRecordID' + (String.isNotBlank(whereConditions) ? ' AND '+whereConditions : '');
                   q+= String.isBlank(orderByConditions) ? '' : ' ORDER BY '+orderByConditions;
                   q+= recordLimit == null ? '' : ' LIMIT '+String.valueOf(recordLimit);
            crc.sObjects = Database.query(q);
            crc.parentId = parentRecordID;
            crc.objectName = childObjName;
            crc.parentIdFieldNm = parentField;
        }

        return crc;
    }

    /**
     * @description                     This lightning method will return a pared down version of the child record init
     * with no where conditions defined and default values for order by and the limit
     *
     * @param parentRecordID            The parent record Id
     * @param childObjParentFldFieldSet The child object to parent field to field set
     *
     * @return
     */
    @AuraEnabled public static ChildRecordCont handleChildRecordInit(String parentRecordID, String childObjParentFldFieldSet) {
        return handleChildRecordInit(parentRecordID, childObjParentFldFieldSet, '', 'CreatedById DESC', 5);
    }

    /**
     * @description         This function will get a list of fields as a string from the field set
     *
     * @param childObj      The sobject to get the field set from
     * @param fieldSetName  The field set to return the field values for
     *
     * @return              The list of fields as strings
     */
    private static List<String> getFieldsFromFieldset(String childObj, String fieldSetName) {
        childObj = childObj == 'ActivityHistory' ? 'Task' : childObj;
        FieldSet fs = Schema.getGlobalDescribe().get(childObj).getDescribe().fieldSets.getMap().get(fieldSetName);
        List<String> returnList = new List<String>();

        for (FieldSetMember fsm : fs.getFields()) returnList.add(fsm.getFieldPath());
        if (childObj == 'Task' && !returnList.contains('Subject')) returnList.add('Subject');
        if (childObj == 'Task' && !returnList.contains('ActivityDate')) returnList.add('ActivityDate');
        return returnList;
    }

    /**
     * @description         This function will populate the base describe fields so they can be cloned with values
     * defined later. This will save on describe calls
     *
     * @param fieldList     The list of fields to get aura field descriptions for
     * @param sobjectName   The name of the sobject to describe
     *
     * @return              The list of described aura fields
     */
    private static List<AuraFieldDescription> populateBaseDescriedFields(List<String> fieldList, String sobjectName) {
        List<AuraFieldDescription> returnList = new List<AuraFieldDescription>();

        DescribeSObjectResult dsr = Schema.getGlobalDescribe().get(sobjectName).getDescribe();
        Map<String, SObjectField> sobjFields = dsr.fields.getMap();
        SObject sobj = dsr.getSObjectType().newSObject();
        for (Integer i = 0; i < fieldList.size(); i++) {
            String fldNm = fieldList[i];
            returnList.add(new AuraFieldDescription(i, sobjFields.get(fldNm).getDescribe(), sobj));
        }

        return returnList;
    }

    /**
     * @description                 This function will return the child sobject name based on the sub query relationship
     * with the parent
     *
     * @param pSobDesc              The parent sobject description
     * @param subQueryRelationship  The sub query relationship name
     *
     * @return                      The child sobject name as a string
     */
    private static String getChildSObjectName(DescribeSObjectResult pSobDesc, String subQueryRelationship) {
        String returnStr;
        for (ChildRelationship cr : pSobDesc.childRelationships) {
            if (String.isNotBlank(cr.getRelationshipName()) && cr.getRelationshipName().equalsIgnoreCase(subQueryRelationship)) {
                returnStr = cr.childSObject.getDescribe().getLocalName();
                break;
            }
        }
        return returnStr;
    }

}