/** @author : Northteq Consulting, Inc.
 * @date : 2/23/21
 * @description: SAL-2320 - Test class for TC_UpdateLastContactActivityField
 *
 */

@IsTest
public with sharing class TC_UpdateLastContactActivityFieldTest {

    @TestSetup
    static void setup() {

        Account primaryAccount = new Account();
        primaryAccount.Name = 'Test Account';
        primaryAccount.Business_Phone__c = '5555555555';
        primaryAccount.RecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
        insert primaryAccount;
    }

    @IsTest
    static void testOnAccountWithContactOutcome() {

        Account primaryAccount = [SELECT Id, Name FROM Account WHERE Name = 'Test Account'];

        Task activity = new Task();
        activity.Subject = 'Outbound Call - Prospecting';
        activity.Task_Outcome__c = 'Contact with Decision Maker - Not Interested';
        activity.Status = 'Completed';
        activity.WhatId = primaryAccount.Id;
        activity.Activity_Type__c = 'Outbound';
        insert activity;

        primaryAccount = [SELECT Id, Name, Last_Contact_activity__c FROM Account WHERE Id = :primaryAccount.Id];

        System.debug(LoggingLevel.INFO, primaryAccount.Last_Contact_activity__c);
    }

    @IsTest
    static void testOnLead() {

        Account primaryAccount = [SELECT Id, Name FROM Account WHERE Name = 'Test Account'];

        Lead l = new Lead();
        l.LastName = 'Sample';
        l.Company = 'Test';
        l.PrimaryAccount__c = primaryAccount.Id;
        insert l;

        Task activity = new Task();
        activity.Subject = 'Outbound Call - Prospecting';
        activity.Task_Outcome__c = 'Provided Quote - Customer';
        activity.Status = 'Completed';
        activity.WhoId = l.Id;
        activity.Activity_Type__c = 'Outbound';
        insert activity;

        primaryAccount = [SELECT Id, Name, Last_Contact_activity__c FROM Account WHERE Id = :primaryAccount.Id];

        System.debug(LoggingLevel.INFO, primaryAccount.Last_Contact_activity__c);
    }

    @IsTest
    static void testOnAccountWithFollowUpOutcome() {

        Account primaryAccount = [SELECT Id, Name FROM Account WHERE Name = 'Test Account'];

        Task activity = new Task();
        activity.Subject = 'Outbound Call - Prospecting';
        activity.Task_Outcome__c = 'Follow-up - Customer';
        activity.Status = 'Completed';
        activity.WhatId = primaryAccount.Id;
        activity.Activity_Type__c = 'Outbound';
        insert activity;

        primaryAccount = [SELECT Id, Name, Last_Contact_activity__c FROM Account WHERE Id = :primaryAccount.Id];

        System.debug(LoggingLevel.INFO, primaryAccount.Last_Contact_activity__c);
    }
}