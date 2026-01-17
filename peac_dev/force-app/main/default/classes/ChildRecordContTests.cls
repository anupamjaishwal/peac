@IsTest class ChildRecordContTests {
    @TestSetup static void createData() {
        Account pa = new Account(Name = 'Parent');
        insert pa;
        Account ca = new Account(Name = 'Child', ParentId = pa.Id);
        insert ca;
    }

    @IsTest static void handleChildRecordInitTest() {
        Account pa = [SELECT Id FROM Account WHERE ParentId = null];
        ChildRecordCont crc = ChildRecordCont.handleChildRecordInit(pa.Id, 'Account:ParentId:Test_FS');
        System.assertEquals(crc.parentIdFieldNm, 'ParentId');
        System.assertEquals(crc.parentId, pa.Id);
        System.assertEquals(crc.objectName, 'Account');
        System.assert(!crc.fieldList.isEmpty());
    }

    @IsTest static void handleChildRecordInitFromParentFieldTest() {
        Account pa = [SELECT Id FROM Account WHERE ParentId != null];
        ChildRecordCont crc = ChildRecordCont.handleChildRecordInitFromParentField(pa.Id, 'ParentId', 'Test_FS', 'ChildAccounts','','',5);
        System.assertEquals(crc.objectName, 'Account');
        System.assert(!crc.fieldList.isEmpty());
        System.assert(!crc.sObjects.isEmpty());
    }
}