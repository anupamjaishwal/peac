public with sharing class TC_QueryUtil {
    public static List <SObject> queryObjectFields (String objectType, String whereCluase) {


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
}