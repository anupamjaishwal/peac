/**
 * Created by andrewmayer on 8/24/20.
 *
 * Standardizes Database Access Object Behaviour and includes re-useable methods
 */

public inherited sharing abstract class TC_DaoAbstract {
    public List <SObject> insertRecords (List <SObject> records) {
        insert records;
        return records;
    }

    public List <SObject> updateRecords (List <SObject> records) {
        update records;
        return records;
    }

    public void deleteRecords (List <SObject> records) {
        delete records;
    }

    public List <SObject> queryRecordsById (Set <Id> recordIds) {
        if (recordIds.isEmpty()) return null;

        Id recordId;
        for (Id recId : recordIds) {
            recordId = recId;
            break;
        }

        String query = TC_DataUtility.createSelectAllQueryString (String.valueOf(recordId.getsObjectType()), ' Id IN :recordIds', null);
        return Database.query (query);
    }
}