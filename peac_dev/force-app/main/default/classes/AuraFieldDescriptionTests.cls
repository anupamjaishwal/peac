@isTest
private class AuraFieldDescriptionTests {
    @TestSetup static void setupData() {
    }

    @isTest static void constructionTest() {
        Test.startTest();
        DescribeSObjectResult sobjRes = Schema.getGlobalDescribe().get('Account').getDescribe();
        List<Schema.FieldSetMember> fieldSetMembers = sobjRes.FieldSets.getMap().get('Test_FS').getFields();
        System.assert(!fieldSetMembers.isEmpty(),'The field set members list was empty!');
        Map<String,Schema.SObjectField> flds = sobjRes.fields.getMap();
        System.assert(!flds.isEmpty(),'No fields were found');
        Account acct = new Account(Name='Testing');
        Database.DMLOptions dmlo = new Database.DMLOptions();
        dmlo.allowFieldTruncation = true;
        dmlo.duplicateRuleHeader.allowSave = true;
        dmlo.optAllOrNone = true;
        Database.insert(acct,dmlo);
        Id acctId = acct.Id;
        List<Account> accts = Database.query('SELECT '+String.join(new List<String>(flds.keySet()),',')+' FROM Account WHERE Id =:acctId');
        /*for (Schema.FieldSetMember fsm : fieldSetMembers) {
            Schema.DescribeFieldResult dfr = flds.get(fsm.getFieldPath()).getDescribe();
            AuraFieldDescription afd = new AuraFieldDescription(dfr,fsm.getRequired());
        }
        */
        Integer index = 0;
        for (Schema.SObjectField fld : flds.values()) {
            Schema.DescribeFieldResult dfr = fld.getDescribe();
            //AuraFieldDescription afd = new AuraFieldDescription(dfr,!dfr.isNillable(),AuraFieldDescription.g_NumTypes.contains(String.valueOf(dfr.getType())));
            AuraFieldDescription afd = new AuraFieldDescription(index,dfr,accts[0].get(dfr.getLocalName()));
            Object val = afd.getFormattedValue();
            afd = new AuraFieldDescription(index,dfr.getLocalName(),accts[0]);
            System.assertEquals(val,afd.getFormattedValue(),'The value was not the same!');
            afd = new AuraFieldDescription(index,dfr.getLocalName(),accts[0].get(dfr.getLocalName()));
            System.assertEquals(String.valueOf(val),afd.fieldValue,'The value was not the same!');
            index++;
        }
        new AuraFieldDescription();
        Test.stopTest();
    }
}