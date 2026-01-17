/** @author : Northteq Consulting, Inc.
 * @date : 11/3/20
 * @description: Test class for TC_CopyAccountBusinessPhoneToContact
 *
 */
@IsTest
public with sharing class TC_CopyAccountBusinessPhoneToContactTest {

    @IsTest
    static void testInsertContactWithoutPhone() {

        // Create a test account
        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        testAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
        testAccount.Business_Phone__c = '1234567890';
        insert testAccount;

        // Create a test contact
        Contact testContact = new Contact();
        testContact.FirstName = 'Test';
        testContact.LastName = 'Contact';
        testContact.AccountId = testAccount.Id;
        insert testContact;
    }
}