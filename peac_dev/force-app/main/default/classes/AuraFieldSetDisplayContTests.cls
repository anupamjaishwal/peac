@IsTest
private class AuraFieldSetDisplayContTests {
    private static String g_testObjectNm;
    private static String g_testLookupField;
    private static String g_LookupFieldAndFieldSet;
    private static String g_testFieldSet;
    @TestSetup static void createData() {
        Account parent = new Account(Name = 'Parent');
        insert parent;
        Account child = new Account(Name = 'Child');
        child.ParentId = parent.Id;
        insert child;

    }

    @IsTest static void AuraFieldSetDisplayPositiveTest() {
        setupGlobals();
        Test.startTest();
        AuraFieldSetDisplayCont afsdc = AuraFieldSetDisplayCont.getFieldsFromFieldSet(g_testObjectNm,g_testFieldSet);
        Test.stopTest();
        System.assert(afsdc.fields != null && !afsdc.fields.isEmpty(),'No fields were found!');
        System.assert(afsdc.errors == null || afsdc.errors.isEmpty(),'There were errors!');
        System.assert(String.isNotBlank(afsdc.userTheme),'User theme was blank');
    }

    @IsTest static void AuraFieldSetDisplayNegativeTest() {
        setupGlobals();
        Test.startTest();
        AuraFieldSetDisplayCont afsdc = AuraFieldSetDisplayCont.getFieldsFromFieldSet(g_testObjectNm+'1324',g_testFieldSet);
        Test.stopTest();
        System.assert(afsdc.fields == null || afsdc.fields.isEmpty(),'Fields were found!');
        System.assert(afsdc.errors != null && !afsdc.errors.isEmpty(),'There were no errors!');
    }

    @IsTest static void AuraRelatedRecordFldSetPosTest() {
        setupGlobals();
        Test.startTest();
        List<SObject> childRecords = Database.query('SELECT Id,'+g_testLookupField+' FROM '+g_testObjectNm+' WHERE '+g_testLookupField+' <> null LIMIT 1');
        System.assert(!childRecords.isEmpty(),'No child records were found!');
        SObject childRecord = childRecords[0];
        AuraFieldSetDisplayCont afsdc = AuraFieldSetDisplayCont.getFieldsFromLookupFieldAndFieldSet(g_LookupFieldAndFieldSet,childRecord.Id);
        System.assert(afsdc.fields != null && !afsdc.fields.isEmpty(), 'The fields were not found!');
        System.assert(String.isNotBlank(afsdc.objectName), 'The object name was not found!');
        System.assert(afsdc.recordId != null, 'The Record Id was not returned!');
        System.assertEquals((Id)childRecord.get(g_testLookupField), afsdc.recordId, 'The Record Id returned does not match!');
        System.assert(afsdc.errors == null || afsdc.errors.isEmpty(),'There were errors!');
        Test.stopTest();
    }

    @IsTest static void AuraRelatedRecordFldSetNegTest() {
        setupGlobals();
        Test.startTest();
        List<SObject> childRecords = Database.query('SELECT Id,'+g_testLookupField+' FROM '+g_testObjectNm+' WHERE '+g_testLookupField+' <> null LIMIT 1');
        System.assert(!childRecords.isEmpty(),'No child records were found!');
        SObject childRecord = childRecords[0];
        AuraFieldSetDisplayCont afsdc = AuraFieldSetDisplayCont.getFieldsFromLookupFieldAndFieldSet('ParentId2:'+g_testFieldSet,childRecord.Id);
        System.assert(afsdc.errors != null && !afsdc.errors.isEmpty(),'There were no errors!');
        Test.stopTest();
    }

    private static void setupGlobals() {
        g_testObjectNm = 'Account';
        g_testLookupField = 'ParentId';
        g_testFieldSet = 'Test_FS';
        g_LookupFieldAndFieldSet = g_testLookupField+':'+g_testFieldSet;
    }

}