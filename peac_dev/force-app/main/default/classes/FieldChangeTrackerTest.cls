@isTest
public class FieldChangeTrackerTest {
      private static Id getRecordTypeId(String sObjectTypeName, String recordTypeName) {
        return [SELECT Id FROM RecordType WHERE SObjectType = :sObjectTypeName AND DeveloperName = :recordTypeName LIMIT 1].Id;
    }
     private static Contact createTestContact(String firstName) {
        Account acct = TC_SDR_TestUtility.constructAccount('Test', null ,null);
        acct.Business_Phone__c = '1234567890';

        insert acct;
        Contact cont = TC_SDR_TestUtility.constructContact('fn','ln','fnln@testingorg.com',acct.Id);
        insert cont;
        return cont;
    }
    
    @testSetup
    static void setupData() {
        // Create test Opportunity
        Opportunity opp = new Opportunity(Name = 'Test Opp', StageName = 'Prospecting', CloseDate = Date.today());
        insert opp;

        Contact contact = createTestContact('ValidSeq');
        Id recordTypeId = getRecordTypeId('Guarantor__c', 'Personal');

        List<Guarantor__c> pgList = new List<Guarantor__c>{
            new Guarantor__c(PG_Number__c='PG1', Opportunity__c=opp.Id, Contact__c=contact.Id, Type__c = 'Personal Guarantor',RecordTypeId = recordTypeId)
        };

        Test.startTest();
        insert pgList;
        
        contact.LastName = 'New Name';
        update contact;

        // Add dummy profile exclusion record if needed (mocking non-exclusion for testing)
        // No ExcludeUsersFromFieldTracking__c created to allow method execution
    }

    /*@isTest
    static void testTrackDetails() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Contact newRec = [SELECT Id, Name, Opportunity__c FROM Guarantor__c LIMIT 1];
        Contact oldRec = newRec.clone(false, false, false, false);
        oldRec.Name = 'Old Name';

        FieldChangeTracker.TrackerWrapper wrapper = new FieldChangeTracker.TrackerWrapper();
        wrapper.objectApiName = 'Contact';
        wrapper.oldRecordMap = new Map<Id, SObject>{ oldRec.Id => oldRec };
        wrapper.newRecordMap = new Map<Id, SObject>{ newRec.Id => newRec };
        wrapper.recordIdWithOppIdsMap = new Map<Id, Set<Id>>{ newRec.Id => new Set<Id>{ opp.Id } };

        Test.startTest();
        FieldChangeTracker.trackDetails(wrapper);
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Field_Tracker__c]);
    }*/

    @isTest
    static void testRemoveTrackedChanges() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        FieldChangeTracker.removeTrackedChanges(new List<String>{opp.Id});
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Field_Tracker__c WHERE Opportunity__c = :opp.Id]);
    }

    @isTest
    static void testUpdateScoreFieldFlag() {
        Opportunity opp = new Opportunity(Name = 'Flag Test', StageName = 'Prospecting', CloseDate = Date.today());
        insert opp;

        Test.startTest();
        FieldChangeTracker.updateScoreFieldFlag(new Set<string>{ opp.Id }, true);
        Test.stopTest();

       
    }

   /* @isTest
    static void testTrackCreateAndDeleteForChilds() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Id recordTypeId = getRecordTypeId('Guarantor__c', 'Personal');
        Contact contact = createTestContact('ValidSeq');

               List<Guarantor__c> pgList = new List<Guarantor__c>{
            new Guarantor__c(PG_Number__c='PG1', Opportunity__c=opp.Id, Contact__c=contact.Id, Type__c = 'Personal Guarantor',RecordTypeId = recordTypeId)
        };

        Test.startTest();
        insert pgList;

        Map<Id, SObject> recordMap = new Map<Id, SObject>{ pgList.get(0).Id => pgList.get(0) };

        Test.startTest();
        FieldChangeTracker.trackCreateAndDeleteForChilds(recordMap, 'Guarantor__c', 'Created');
        Test.stopTest();

        //System.assertEquals(1, [SELECT COUNT() FROM Field_Tracker__c WHERE Action__c = 'Created']);
    }*/
}