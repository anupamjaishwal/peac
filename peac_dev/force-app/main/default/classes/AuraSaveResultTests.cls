@isTest
private class AuraSaveResultTests {
    @testSetup static void createData() {
        Account parent = new Account(Name='Parent');
        insert parent;
        Account child = new Account(Name='Child');
        child.ParentId = parent.Id;
        insert child;

    }
    @isTest static void positiveTests() {
        Test.startTest();
        List<Account> accts = [SELECT Id FROM Account LIMIT 1];
        AuraSaveResult asr = new AuraSaveResult(Database.update(accts)[0]);
        System.assert(asr.isSuccessful,'The save was not successful!');
        Test.stopTest();
    }

    @isTest static void negativeTests() {
        Test.startTest();
        List<Account> accts = [SELECT Id, ParentId FROM Account LIMIT 1];
        AuraSaveResult asr = new AuraSaveResult();
        try {
            Database.insert(accts);
        } catch(Exception e) {
            asr = new AuraSaveResult(e);
        }
        System.assert(!asr.isSuccessful,'The save was successful!');
        accts[0].ParentId = accts[0].Id;
        List<Database.SaveResult> srs = Database.update(accts,false);
        asr = new AuraSaveResult(srs[0]);
        System.assert(!asr.isSuccessful,'The save was successful!');
        List<AuraSaveResult> asrs = AuraSaveResult.getSaveResults(srs);
        System.assert(!asrs.isEmpty(),'No results were returned!');
        for (AuraSaveResult asrr : asrs) {
            System.assert(!asrr.isSuccessful,'The save was successful!');
        }
        String testErrMsg = 'This is a test only a test!';
        asr = AuraSaveResult.customSaveResultError(testErrMsg,'Account');
        System.assert(asr.errors[0].message.containsIgnoreCase(testErrMsg),'Message was not conveyed!');
        Test.stopTest();
    }

}