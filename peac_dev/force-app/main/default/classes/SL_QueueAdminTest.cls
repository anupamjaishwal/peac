@isTest
public with sharing class SL_QueueAdminTest {
    @isTest
    public static void getRole() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Services Admin'];
        UserRole role = [SELECT Id, DeveloperName,name FROM UserRole WHERE DeveloperName = 'Customer_Service_Management'];
        User u = new User(Alias = 'testuser', Email = 'marlinbusiness@silverlinecrm.com', EmailEncodingKey='UTF-8',
                LastName = 'testing', FirstName = 'user', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = p.Id, UserRoleId = role.Id, TimeZoneSidKey = 'America/Los_Angeles',
                Username = 'service.admin.test.user@silverlinecrm.com.test', Doc_Fee_Exception_Approver__c = true);
        UserRole roleColl = [SELECT Id, DeveloperName,name FROM UserRole WHERE DeveloperName = 'Collections_Manager'];
        User u2 = new User(Alias = 'testuse2', Email = 'marlinbusiness@silverlinecrm.com', EmailEncodingKey='UTF-8',
                        LastName = 'testing', FirstName = 'user', LanguageLocaleKey = 'en_US',
                        LocaleSidKey = 'en_US', ProfileId = p.Id, UserRoleId = roleColl.Id, TimeZoneSidKey = 'America/Los_Angeles',
                        Username = 'service2.admin.test.user@silverlinecrm.com.test2', Doc_Fee_Exception_Approver__c = true);
        insert u;
        insert u2;
        
        String result = '', result2 = '';
        Test.startTest();
        System.runAs(u) {
            result = SL_QueueAdmin.hubExecute('getRole', new List<String>());
        }
        system.runAs(u2){
            result2 = SL_QueueAdmin.hubExecute('getRole', new List<String>());
        }
        Test.stopTest();
        system.assert(!result.contains('{"error":'));
        system.assert(!result2.contains('{"error":'));
        
    }
    @isTest
    public static void getRole_error() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Services Admin'];
        User u = new User(Alias = 'testuser', Email = 'marlinbusiness@silverlinecrm.com', EmailEncodingKey='UTF-8',
                LastName = 'testing', FirstName = 'user', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles',
                Username = 'service.admin.test.user@silverlinecrm.com.test', Doc_Fee_Exception_Approver__c = true);
        insert u;
        System.runAs(u) {
            String result = '';
            Test.startTest();
            result = SL_QueueAdmin.hubExecute('getRole', new List<String>());
            Test.stopTest();
            system.assert(result.contains('{"error":'));
        }
    }

    @isTest
    public static void getGroupMembers() {
        Group queue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName LIKE 'X31%' LIMIT 1];
        String result = '';
        Test.startTest();
        result = SL_QueueAdmin.hubExecute('getGroupMembers', new List<String>{String.valueOf(queue.Id)});
        Test.stopTest();
        system.assert(result.contains('{"members": '));
    }
    @isTest
    public static void saveGroupMembers() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Services Admin'];
        UserRole role = [SELECT Id, DeveloperName,name FROM UserRole WHERE DeveloperName = 'Customer_Service_Management'];
        User u = new User(Alias = 'testuser', Email = 'marlinbusiness@silverlinecrm.com', EmailEncodingKey='UTF-8',
                LastName = 'testing', FirstName = 'user', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = p.Id, UserRoleId = role.Id, TimeZoneSidKey = 'America/Los_Angeles',
                Username = 'service.admin.test.user@silverlinecrm.com.test', Doc_Fee_Exception_Approver__c = true);
        insert u;
        Group queue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName LIKE 'X31%' LIMIT 1];
        String result = '', thenDelete = '';
        Test.startTest();
        result = SL_QueueAdmin.hubExecute('saveGroupMembers', new List<String>{String.valueOf(queue.Id),
            String.valueOf(u.Id),
            'Case'});
        thenDelete =  SL_QueueAdmin.hubExecute('saveGroupMembers', new List<String>{String.valueOf(queue.Id),
            '',
            'Case'});
        Test.stopTest();
        system.assertEquals('{"success": true}', result);
        system.assertEquals('{"success": true}', thenDelete);
    }
    @isTest
    public static void saveGroupMembers_Collections() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Services Admin'];
        UserRole roleColl = [SELECT Id, DeveloperName,name FROM UserRole WHERE DeveloperName = 'Collections_Manager'];
        User u2 = new User(Alias = 'testuse2', Email = 'marlinbusiness@silverlinecrm.com', EmailEncodingKey='UTF-8',
                        LastName = 'testing', FirstName = 'user', LanguageLocaleKey = 'en_US',
                        LocaleSidKey = 'en_US', ProfileId = p.Id, UserRoleId = roleColl.Id, TimeZoneSidKey = 'America/Los_Angeles',
                        Username = 'service2.admin.test.user@silverlinecrm.com.test2', Doc_Fee_Exception_Approver__c = true);
        insert u2;
        Group queue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName LIKE 'X31%' LIMIT 1];
        String result = '';
        Test.startTest();
        result = SL_QueueAdmin.hubExecute('saveGroupMembers', new List<String>{String.valueOf(queue.Id),
            String.valueOf(u2.Id),
            'Contract__c'});
        Test.stopTest();
        system.assert(result.contains('{"success": true'));
    }

    @isTest
    public static void addRRAssignees() {
        String result = '';
        Test.startTest();
        result = SL_QueueAdmin.hubExecute('addRRAssignees', new List<String>());
        Test.stopTest();
        system.assertEquals('success', result);
    }
}