public class TC_UpdateHiddenRTField {
    public static void updateHiddenRTField (Map <Id, Account> oldMap, List <Account> newList) {
        
        // List <Account> accs = new List <Account> ();
        
        // for (Account acc : newList) {
        //     if (oldMap != null) {
        //         if (acc.RecordTypeId != oldMap.get (acc.Id).RecordTypeId) accs.add (acc); 
        //     } else {
        //         //insert
        //         accs.add (acc);
        //     }  
        // }
        // if (!accs.isEmpty ()) {
        //     Map <Id, RecordType> recordTypeMap = new Map <Id, RecordType> ([SELECT Id, Name FROM RecordType WHERE SObjectType = 'Account']);
        //     for (Account acc : accs) {
        //         acc.Account_Record_Type_Custom__c = recordTypeMap.get (acc.RecordTypeId).Name.contains ('Dealer') || recordTypeMap.get (acc.RecordTypeId).Name.contains ('dealer') ? 'Dealer Account' : recordTypeMap.get (acc.RecordTypeId).Name;
        //     }
        // }
    }
    // public static void updateHiddenRTField (Map <Id, Account> oldMap, Map <Id, Account> newMap) {
        
    //     List <Account> accs = new List <Account> ();
        
    //     for (Id i : newMap.keySet()) {
    //         if (oldMap != null) {
    //             if (newMap.get(i).RecordTypeId != oldMap.get (i).RecordTypeId) accs.add (newMap.get(i)); 
    //         } else {
    //             //insert
    //             accs.add (newMap.get(i));
    //         }  
    //     }
    //     if (!accs.isEmpty ()) {
    //         Map <Id, RecordType> recordTypeMap = new Map <Id, RecordType> ([SELECT Id, Name FROM RecordType WHERE SObjectType = 'Account']);
    //         for (Account acc : accs) {
    //             acc.Account_Record_Type_Custom__c = recordTypeMap.get (acc.RecordTypeId).Name.contains ('Dealer') || recordTypeMap.get (acc.RecordTypeId).Name.contains ('dealer') ? 'Dealer Account' : recordTypeMap.get (acc.RecordTypeId).Name;
    //         }
    //     }
    // }
}