@isTest
public class SL_ExternalAccountHierarchyServiceTest {
    
    @isTest
    static void testGetAccountHierarchyWithPortalRoles() {

		SL_SCTestData.createAccountAndContracts(3,1);
        List<Account> accs = [SELECT Id, RecordTypeId FROM Account]; 
        
        for(Account a : accs){
            a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId();
        }
        
        //Parent Account
        Account parentAccount = accs[0];
        SL_SCTestData.createDPUser(parentAccount.Id);
        SL_SCTestData.createDPDataForUser(parentAccount);

        ExternalAccountHierarchy parenteah = new ExternalAccountHierarchy(Name='Parent EAH', AccountId = parentAccount.Id);
        insert parenteah;


        //Child 1
		Account child1Account = accs[1];
		SL_SCTestData.createDPUser(child1Account.Id);
        SL_SCTestData.createDPDataForUser(child1Account);
		ExternalAccountHierarchy child1eah = new ExternalAccountHierarchy(Name='Child EAH', AccountId = child1Account.Id, ParentId=parenteah.Id);
        insert child1eah;
        
        
        //Grandchild 
		Account grandchildAccount = accs[2];
		SL_SCTestData.createDPUser(grandchildAccount.Id);
        SL_SCTestData.createDPDataForUser(grandchildAccount);
        ExternalAccountHierarchy grandchildeah = new ExternalAccountHierarchy(Name='Grandchild EAH', AccountId = grandchildAccount.Id, ParentId=child1eah.Id);
        insert grandchildeah;

        
        Test.startTest();
        List<Account> hierarchy = SL_ExternalAccountHierarchyService.getAccountHierarchy(parentAccount.Id);
        Test.stopTest();

 		// Assert the results
        System.assertNotEquals(hierarchy, null, 'Hierarchy should not be null');
        System.assertEquals(hierarchy.size(), 3, 'The hierarchy should contain 3 accounts');

    }

}