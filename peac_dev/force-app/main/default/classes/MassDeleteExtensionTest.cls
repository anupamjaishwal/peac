@isTest
private class MassDeleteExtensionTest {
    @isTest
    public static void testDeleteRecords() {
        User u = SL_SCTestData.createTestUser();
        UserRole managerRole = [SELECT Id FROM UserRole WHERE Name = 'Customer Service Management'];
        u.UserRoleId = managerRole.Id;
        update u;
        System.runAs(u){
            List<Case> newCases = new List<Case>{
                new Case(Subject = 'test 1', Description = 'test case 2'),
                new Case(Subject = 'test 2', Description = 'test case')};
            insert newCases;
            ApexPages.StandardSetController sc = new ApexPages.StandardSetController(newCases);
            sc.setSelected(newCases);
            MassDeleteExtension extension = new MassDeleteExtension(sc);
            Test.startTest();
            extension.deleteRecords();
            Test.stopTest();
        }
        List<Case> casesAfter = [SELECT Id FROM Case];
        System.assertEquals(0, casesAfter.size());
    }
    @isTest
    public static void deleteNoAccess() {
        User u = SL_SCTestData.createTestUser();
        List<Case> newCases = new List<Case>{
            new Case(Subject = 'test 2', Description = 'test case 2'),
            new Case(Subject = 'test 1', Description = 'test case')};
        insert newCases;
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(newCases);
        sc.setSelected(newCases);
        MassDeleteExtension extension = new MassDeleteExtension(sc);
        System.runAs(u){
            Test.startTest();
            extension.deleteRecords();
            Test.stopTest();
        }
        List<Case> casesAfter = [SELECT Id FROM Case];
        System.assertEquals(2, casesAfter.size());
    }

    static testMethod void testSelectedSize() {
        List<Lead> leads = new List<Lead>();
        leads.add(new Lead(LastName='test'));

        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(leads);
        sc.setSelected(leads);
        MassDeleteExtension extension = new MassDeleteExtension(sc);

        System.assertEquals('1', extension.getMySelectedSize());
    }
}