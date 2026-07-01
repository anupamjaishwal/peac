@IsTest
private class EquipmentByBranchServiceTest {

    @IsTest
    static void testGetEquipment_OEG() {

        Profile p = [
            SELECT Id, Name 
            FROM Profile 
            WHERE Name LIKE '%OEG%' 
            LIMIT 1
        ];

        // Crear usuario de prueba con profile OEG
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuseroeg@test.com',
            Username = 'testuseroeg' + System.currentTimeMillis() + '@test.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );

        insert u;

        System.runAs(u) {

            Test.startTest();

            List<List<EquipmentOption>> result =
                EquipmentByBranchService.getEquipment(
                    new List<String>{ 'run' }
                );

            Test.stopTest();

            System.assertNotEquals(null, result);
            System.assertEquals(1, result.size());
        }
    }
}