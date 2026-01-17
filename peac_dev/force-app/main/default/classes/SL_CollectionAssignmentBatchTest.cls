@isTest
public class SL_CollectionAssignmentBatchTest {
    
    @isTest
    static void scenario1() {
        SL_SCTestData.createAccountAndContracts(3, 3);
        List<Contract__c> contracts = [SELECT Id, Name, Delinquency_Status_Code__c FROM Contract__c];
        contracts[2].Delinquency_Status_Code__c = '151';
        contracts[4].Delinquency_Status_Code__c = '91';
        contracts[6].Delinquency_Status_Code__c = '01';
        contracts[6].Lessor_Code__c = '111'; // Causes IsXBS__c to be true
        contracts[6].First_Payment_Default__c = false;
        Test.startTest();
        update contracts;
        Database.executeBatch(new SL_CollectionAssignmentBatch());
        Database.executeBatch(new SL_CollectionAssignmentBatchNew(true));

        System.enqueueJob(new SL_CollectionAssignmentQ(contracts));
        Test.stopTest();
        List<Account> acctsAfter = [SELECT Id, Collection_Group__c, XBS_Collection_Group__c FROM Account];
        //System.assertEquals('Pre-Charge Off', acctsAfter[0].Collection_Group__c);
        System.assertEquals('91', acctsAfter[1].Collection_Group__c);
        System.Assert.areEqual('XBS Dialer Regular', acctsAfter[2].XBS_Collection_Group__c, 'highest delinquency contract is XBS so queue must be XBS');// SL-2792
    }
    
    @isTest
    static void scenario2() {
        SL_SCTestData.createAccountAndContracts(1, 3);
        List<Contract__c> contracts = [SELECT Id, Name, Delinquency_Status_Code__c FROM Contract__c];
        contracts[0].Delinquency_Status_Code__c = '151';
        contracts[1].Delinquency_Status_Code__c = '91';
        contracts[2].Delinquency_Status_Code__c = '31';
        Test.startTest();
        update contracts;
        Database.executeBatch(new SL_CollectionAssignmentBatch());
        Test.stopTest();
        List<Account> acctsAfter = [SELECT Id, Collection_Group__c FROM Account];
        //System.assertEquals('Pre-Charge Off', acctsAfter[0].Collection_Group__c);
    }
    @isTest
    static void scenario3() {
        SL_SCTestData.createAccountAndContracts(1, 8);
        List<Contract__c> contracts = [SELECT Id, Name, Delinquency_Status_Code__c FROM Contract__c];
        contracts[0].Delinquency_Status_Code__c = '151';
        contracts[1].Delinquency_Status_Code__c = '91';
        contracts[2].Delinquency_Status_Code__c = '31';
        contracts[3].Delinquency_Status_Code__c = '01';
        contracts[4].Delinquency_Status_Code__c = '00';
        contracts[5].Delinquency_Status_Code__c = '61';
        contracts[6].Delinquency_Status_Code__c = '181';
        contracts[7].Delinquency_Status_Code__c = '121';
        Id worstCriminal = contracts[6].Id;
        Test.startTest();
        update contracts;
        Database.executeBatch(new SL_CollectionAssignmentBatch());
        Test.stopTest();
        List<Account> acctsAfter = [SELECT Id, Highest_Delinquency_Contract__c FROM Account];
        System.assertEquals(worstCriminal, acctsAfter[0].Highest_Delinquency_Contract__c);
    }

    @isTest
    static void RRToDialer_Regular_Queue() {
        RR_Queue__mdt dialerQueue = [SELECT Id, Name__c FROM RR_Queue__mdt WHERE Name__c='Dialer'];
        Map<String, List<RR_Assignee__mdt>> testAgents = new Map<String, List<RR_Assignee__mdt>>();
        testAgents.put('Dialer', new List<RR_Assignee__mdt>{
            new RR_Assignee__mdt(Name__c='Wendy Lewis',
                Is_Active__c = true,
                User__c = '0054N000004l13gQAA', // same id on FullCopy
                Last_Assigned__c = null,
                RR_Queue__c = dialerQueue.Id ),
            new RR_Assignee__mdt(Name__c='Robert Fischer',
                Is_Active__c = true,
                User__c = '0054N000004zGBxQAM', // same id on FullCopy
                Last_Assigned__c = null,
                RR_Queue__c = dialerQueue.Id )
        });
        SL_SCTestData.createAccountAndContracts(6, 3);
        List<Contract__c> contracts = [SELECT Id, Name, Delinquency_Status_Code__c, Contract_Balance_Remaining__c FROM Contract__c];
        contracts[0].Delinquency_Status_Code__c = '01';
        contracts[0].Contract_Balance_Remaining__c = 1200;
        contracts[3].Delinquency_Status_Code__c = '01';
        contracts[3].Contract_Balance_Remaining__c = 1200;
        contracts[6].Delinquency_Status_Code__c = '01';
        contracts[6].Contract_Balance_Remaining__c = 1200;
        contracts[9].Delinquency_Status_Code__c = '01';
        contracts[9].Contract_Balance_Remaining__c = 1200;
        contracts[12].Delinquency_Status_Code__c = '01';
        contracts[12].Contract_Balance_Remaining__c = 1200;
        contracts[15].Delinquency_Status_Code__c = '01';
        contracts[15].Contract_Balance_Remaining__c = 1200;
        update contracts;
        Integer ExpectedLoad = 3;
        Test.startTest();
        Database.executeBatch(new SL_CollectionAssignmentBatch(testAgents));
        Test.stopTest();
        Integer actualLoad = [SELECT COUNT() FROM Account WHERE Collection_Agent__c = '0054N000004l13gQAA'];
        System.assertEquals(ExpectedLoad, actualLoad);
    }

    @isTest
    static void RRToWCLoan_Queue() {
        RR_Queue__mdt workingCLQueue = [SELECT Id, Name__c FROM RR_Queue__mdt WHERE Name__c='Working_Capital_Delinquency'];
        Map<String, List<RR_Assignee__mdt>> testAgents = new Map<String, List<RR_Assignee__mdt>>();
        testAgents.put('Working_Capital_Delinquency', new List<RR_Assignee__mdt>{
            new RR_Assignee__mdt(Name__c='Wendy Lewis',
                Is_Active__c = true,
                User__c = '0054N000004l13gQAA', // same id on FullCopy
                Last_Assigned__c = null,
                RR_Queue__c = workingCLQueue.Id ),
            new RR_Assignee__mdt(Name__c='Robert Fischer',
                Is_Active__c = true,
                User__c = '0054N000004zGBxQAM', // same id on FullCopy
                Last_Assigned__c = null,
                RR_Queue__c = workingCLQueue.Id )
        });
        Id workingCL = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName()
                .get('Working_Capital_Loan').getRecordTypeId();
        SL_SCTestData.createAccountAndContracts(1, 3);
        List<Contract__c> contracts = [SELECT Id, RecordTypeId FROM Contract__c];
        contracts[0].RecordTypeId = workingCL;
        contracts[0].Current_Days_Delinquent__c = 1;
        contracts[1].RecordTypeId = workingCL;
        contracts[1].Current_Days_Delinquent__c = 1;
        contracts[2].RecordTypeId = workingCL;
        contracts[2].Current_Days_Delinquent__c = 1;
        update contracts;
        Integer ExpectedLoad = 2;
        Test.startTest();
        Database.executeBatch(new SL_CollectionAssignmentBatch(testAgents));
        Test.stopTest();
        Integer actualLoad = [SELECT COUNT() FROM Contract__c WHERE OwnerId = '0054N000004l13gQAA'];
        System.assertEquals(ExpectedLoad, actualLoad);
        Integer totalLoad = [SELECT COUNT() FROM Contract__c WHERE OwnerId IN ('0054N000004l13gQAA', '0054N000004zGBxQAM')];
        System.assertEquals(3, totalLoad);
    }

    @isTest
    static void RRTo31FirstPay(){
        RR_Queue__mdt dialerQueue = [SELECT Id, Name__c FROM RR_Queue__mdt WHERE Name__c='X31_First_Payment_Default'];
        Map<String, List<RR_Assignee__mdt>> testAgents = new Map<String, List<RR_Assignee__mdt>>();
        testAgents.put('X31_First_Payment_Default', new List<RR_Assignee__mdt>{
            new RR_Assignee__mdt(Name__c='Wendy Lewis',
                Is_Active__c = true,
                User__c = '0054N000004l13gQAA', // same id on FullCopy
                Last_Assigned__c = null,
                RR_Queue__c = dialerQueue.Id ),
            new RR_Assignee__mdt(Name__c='Robert Fischer',
                Is_Active__c = true,
                User__c = '0054N000004zGBxQAM', // same id on FullCopy
                Last_Assigned__c = null,
                RR_Queue__c = dialerQueue.Id ),
            new RR_Assignee__mdt(Name__c='Valerie McMillen',
                Is_Active__c = true,
                User__c = '0054N000004zGQnQAM', // same id on FullCopy
                Last_Assigned__c = null,
                RR_Queue__c = dialerQueue.Id )
        });
        SL_SCTestData.createAccountAndContracts(7, 3);
        List<Contract__c> contracts = [SELECT Id, Name, Delinquency_Status_Code__c, Contract_Balance_Remaining__c FROM Contract__c];
        List<Integer> contractIndexes = new List<Integer>{0, 3, 6, 9, 12, 15, 18};
        for(Integer i = 0; i <contractIndexes.size(); i++){
            contracts[contractIndexes[i]].Delinquency_Status_Code__c = '31';
            contracts[contractIndexes[i]].Facility_Code__c = '2.27';
            contracts[contractIndexes[i]].Contract_Balance_Remaining__c = 21000;
            contracts[contractIndexes[i]].First_Payment_Default__c = true;
            contracts[contractIndexes[i]].Lessor_Code__c = '401';
        }
        
        update contracts;
        Integer ExpectedLoad = 3;
        Test.startTest();
        Database.executeBatch(new SL_CollectionAssignmentBatch(testAgents));
        Test.stopTest();
        Integer actualLoad = [SELECT COUNT() FROM Account WHERE Collection_Agent__c = '0054N000004l13gQAA'];
        System.assertEquals(ExpectedLoad, actualLoad);
        Integer secondLoad = [SELECT COUNT() FROM Account WHERE Collection_Agent__c = '0054N000004zGBxQAM'];
        System.assertEquals(2, secondLoad);
        Integer thirdLoad = [SELECT COUNT() FROM Account WHERE Collection_Agent__c = '0054N000004zGQnQAM'];
        System.assertEquals(2, thirdLoad);
        Integer unassignedAccounts = [SELECT COUNT() FROM Account WHERE (NOT Collection_Agent__c IN ('0054N000004l13gQAA', '0054N000004zGBxQAM', '0054N000004zGQnQAM'))];
        System.assertEquals(0, unassignedAccounts);
        Integer assignedAccounts = [SELECT COUNT() FROM Account WHERE Collection_Agent__c IN ('0054N000004l13gQAA', '0054N000004zGBxQAM', '0054N000004zGQnQAM')];
        System.assertEquals(7, assignedAccounts);
        Integer contractLoad = [SELECT COUNT() FROM Contract__c WHERE OwnerId  IN ('0054N000004l13gQAA', '0054N000004zGBxQAM', '0054N000004zGQnQAM')];
        System.assertEquals(7, contractLoad);
    }

    @isTest
    static void RRToDialerReg_factorLock() {
        RR_Queue__mdt dialerQueue = [SELECT Id, Name__c FROM RR_Queue__mdt WHERE Name__c='Dialer'];
        Map<String, List<RR_Assignee__mdt>> testAgents = new Map<String, List<RR_Assignee__mdt>>();
        testAgents.put('Dialer', new List<RR_Assignee__mdt>{
            new RR_Assignee__mdt(Name__c='Wendy Lewis',
                Is_Active__c = true,
                User__c = '0054N000004l13gQAA', // same id on FullCopy
                Last_Assigned__c = null,
                RR_Queue__c = dialerQueue.Id ),
            new RR_Assignee__mdt(Name__c='Robert Fischer',
                Is_Active__c = true,
                User__c = '0054N000004zGBxQAM', // same id on FullCopy
                Last_Assigned__c = null,
                RR_Queue__c = dialerQueue.Id )
        });
        SL_SCTestData.createAccountAndContracts(3, 3);
        List<Contract__c> contracts = [SELECT Id, Name, Delinquency_Status_Code__c, Contract_Balance_Remaining__c FROM Contract__c];
        contracts[0].Delinquency_Status_Code__c = '01';
        contracts[0].Contract_Balance_Remaining__c = 1200;
        contracts[1].Agent_Lock__c = true;
        contracts[2].Delinquency_Status_Code__c = '01';
        contracts[2].Contract_Balance_Remaining__c = 1200;
        contracts[3].Delinquency_Status_Code__c = '01';
        contracts[3].Contract_Balance_Remaining__c = 1200;
        contracts[3].Agent_Lock__c = true;
        contracts[6].Delinquency_Status_Code__c = '01';
        contracts[6].Contract_Balance_Remaining__c = 1200;
        contracts[6].Agent_Lock__c = true;
        contracts[7].Agent_Lock__c = true;
        contracts[8].Agent_Lock__c = true;
        update contracts;
        Integer ExpectedLoad = 3;
        Test.startTest();
        Database.executeBatch(new SL_CollectionAssignmentBatch(testAgents));
        Test.stopTest();
        Integer actualLoad = [SELECT COUNT() FROM Account WHERE Collection_Agent__c = '0054N000004l13gQAA' OR Collection_Agent__c = '0054N000004zGBxQAM'];
        Integer lockedContracts = [SELECT COUNT() FROM Contract__c WHERE Agent_Lock__c = TRUE and OwnerId != '0054N000004l13gQAA' AND OwnerId != '0054N000004zGBxQAM'];
        Integer assignedContracts = [SELECT COUNT() FROM Contract__c WHERE Agent_Lock__c = FALSE and (OwnerId = '0054N000004l13gQAA' OR OwnerId = '0054N000004zGBxQAM')];
        System.assertEquals(ExpectedLoad, actualLoad);
        System.assertEquals(5, lockedContracts);
        System.assertEquals(2, assignedContracts);
    }

    @isTest
    static void RRToDialerReg_oneAssignee() {
        RR_Queue__mdt dialerQueue = [SELECT Id, Name__c FROM RR_Queue__mdt WHERE Name__c='Dialer'];
        Map<String, List<RR_Assignee__mdt>> testAgents = new Map<String, List<RR_Assignee__mdt>>();
        testAgents.put('Dialer', new List<RR_Assignee__mdt>{
            new RR_Assignee__mdt(Name__c='Robert Fischer',
                Is_Active__c = true,
                User__c = '0054N000004zGBxQAM', // same id on FullCopy
                Last_Assigned__c = null,
                RR_Queue__c = dialerQueue.Id )
        });
        SL_SCTestData.createAccountAndContracts(3, 3);
        List<Contract__c> contracts = [SELECT Id, Name, Delinquency_Status_Code__c, Contract_Balance_Remaining__c FROM Contract__c];
        contracts[0].Delinquency_Status_Code__c = '01';
        contracts[0].Contract_Balance_Remaining__c = 1200;
        contracts[1].Agent_Lock__c = true;
        contracts[3].Delinquency_Status_Code__c = '01';
        contracts[3].Contract_Balance_Remaining__c = 1200;
        contracts[3].Agent_Lock__c = true;
        contracts[6].Delinquency_Status_Code__c = '01';
        contracts[6].Contract_Balance_Remaining__c = 1200;
        contracts[6].Agent_Lock__c = true;
        contracts[7].Agent_Lock__c = true;
        contracts[8].Agent_Lock__c = true;
        update contracts;
        Integer ExpectedLoad = 3;
        Test.startTest();
        Database.executeBatch(new SL_CollectionAssignmentBatch(testAgents));
        Test.stopTest();
        Integer actualLoad = [SELECT COUNT() FROM Account WHERE Collection_Agent__c = '0054N000004zGBxQAM'];
        Integer lockedContracts = [SELECT COUNT() FROM Contract__c WHERE Agent_Lock__c = TRUE and OwnerId != '0054N000004zGBxQAM'];
        Integer assignedContracts = [SELECT COUNT() FROM Contract__c WHERE Agent_Lock__c = FALSE AND (NOT Status__c LIKE '%Disposed%')
            AND delinquency_status_code__c != '00' AND delinquency_status_code__c != null AND OwnerId = '0054N000004zGBxQAM'];
        System.assertEquals(ExpectedLoad, actualLoad);
        System.assertEquals(5, lockedContracts);
        System.assertEquals(1, assignedContracts);
    }

    @isTest
    static void RRToWCLoan_FactorLock() {
        RR_Queue__mdt workingCLQueue = [SELECT Id, Name__c FROM RR_Queue__mdt WHERE Name__c='Working_Capital_Delinquency'];
        Map<String, List<RR_Assignee__mdt>> testAgents = new Map<String, List<RR_Assignee__mdt>>();
        testAgents.put('Working_Capital_Delinquency', new List<RR_Assignee__mdt>{
            new RR_Assignee__mdt(Name__c='Wendy Lewis',
                Is_Active__c = true,
                User__c = '0054N000004l13gQAA', // same id on FullCopy
                Last_Assigned__c = null,
                RR_Queue__c = workingCLQueue.Id ),
            new RR_Assignee__mdt(Name__c='Robert Fischer',
                Is_Active__c = true,
                User__c = '0054N000004zGBxQAM', // same id on FullCopy
                Last_Assigned__c = null,
                RR_Queue__c = workingCLQueue.Id )
        });
        Id workingCL = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName()
                .get('Working_Capital_Loan').getRecordTypeId();
        SL_SCTestData.createAccountAndContracts(1, 3);
        List<Contract__c> contracts = [SELECT Id, RecordTypeId FROM Contract__c];
        contracts[0].RecordTypeId = workingCL;
        contracts[0].Current_Days_Delinquent__c = 1;
        contracts[1].RecordTypeId = workingCL;
        contracts[1].Current_Days_Delinquent__c = 1;
        contracts[1].Agent_Lock__c = true;
        contracts[2].RecordTypeId = workingCL;
        contracts[2].Current_Days_Delinquent__c = 1;
        update contracts;
        Integer ExpectedLoad = 2;
        Test.startTest();
        Database.executeBatch(new SL_CollectionAssignmentBatch(testAgents));
        Test.stopTest();
        Integer actualLoad = [SELECT COUNT() FROM Contract__c WHERE OwnerId = '0054N000004l13gQAA' OR OwnerId = '0054N000004zGBxQAM'];
        Integer lockedContracts = [SELECT COUNT() FROM Contract__c WHERE Agent_Lock__c = TRUE and OwnerId != '0054N000004l13gQAA' AND OwnerId != '0054N000004zGBxQAM'];
        System.assertEquals(ExpectedLoad, actualLoad);
        System.assertEquals(1, lockedContracts);
    }
    @isTest
    static void sendErrorsMail() {
        Test.startTest();
        SL_CollectionAssignmentBatch.sendErrorsMail('bad@mail.com', 'Completed', 'No Errors');
        Test.stopTest();
        System.assert(true);
    }
    
    @isTest
    static void RRToXBS_oneAssignee() {
        RR_Queue__mdt dialerQueue = [SELECT Id, Name__c FROM RR_Queue__mdt WHERE Name__c='XBS_Low_Balance'];
		Profile p = [SELECT Id FROM Profile WHERE Name = 'Services Admin'];
		User u = new User(Alias = 'userXBS1', Email = 'marlinbusinessXBRlb@silverlinecrm.com', EmailEncodingKey='UTF-8',
                LastName = 'testing', FirstName = 'user', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = p.Id,  TimeZoneSidKey = 'America/Los_Angeles',
                Username = 'service.admin.test.userXBSrr@silverlinecrm.com.test');
        insert u;
        
        Map<String, List<RR_Assignee__mdt>> testAgents = new Map<String, List<RR_Assignee__mdt>>();
        testAgents.put('XBS_Low_Balance', new List<RR_Assignee__mdt>{
            new RR_Assignee__mdt(Name__c='Robert Fischer',
                Is_Active__c = true,
                User__c = u.id, // same id on FullCopy
                Last_Assigned__c = null,
                RR_Queue__c = dialerQueue.Id )
        });
        SL_SCTestData.createAccountAndContracts(3, 3);
        List<Contract__c> contracts = [SELECT Id, Name, Delinquency_Status_Code__c, Contract_Balance_Remaining__c FROM Contract__c];
        contracts[0].Delinquency_Status_Code__c = '01';
        contracts[0].Contract_Balance_Remaining__c = 1000;
        contracts[0].Lessor_Code__c = '111'; // Causes IsXBS__c to be true
        contracts[0].First_Payment_Default__c = false;
        contracts[0].Net_Investment__c = 4000;
        contracts[1].Agent_Lock__c = true;
        contracts[3].Delinquency_Status_Code__c = '01';
        contracts[3].Contract_Balance_Remaining__c = 1000;
        contracts[3].Agent_Lock__c = true;
        contracts[3].Lessor_Code__c = '111'; // Causes IsXBS__c to be true
        contracts[3].First_Payment_Default__c = false;
        contracts[3].Net_Investment__c = 4000;
        contracts[6].Delinquency_Status_Code__c = '01';
        contracts[6].Contract_Balance_Remaining__c = 1000;
        contracts[6].Agent_Lock__c = true;
        contracts[6].Lessor_Code__c = '111'; // Causes IsXBS__c to be true
        contracts[6].First_Payment_Default__c = false;
        contracts[6].Net_Investment__c = 4000;
        contracts[7].Agent_Lock__c = true;
        contracts[8].Agent_Lock__c = true;
        update contracts;
        Integer ExpectedLoad = 3;
        Test.startTest();
		Database.executeBatch(new SL_CollectionAssignmentBatch(testAgents));
        Test.stopTest();
        Integer actualLoad = [SELECT COUNT() FROM Account WHERE XBS_Collection_Agent__c = :u.id];
        Integer lockedContracts = [SELECT COUNT() FROM Contract__c WHERE Agent_Lock__c = TRUE and OwnerId != :u.id];
        Integer assignedContracts = [SELECT COUNT() FROM Contract__c WHERE Agent_Lock__c = FALSE AND (NOT Status__c LIKE '%Disposed%')
            AND delinquency_status_code__c != '00' AND delinquency_status_code__c != null AND OwnerId = :u.id];
        System.assertEquals(ExpectedLoad, actualLoad);
        System.assertEquals(5, lockedContracts);
        System.assertEquals(1, assignedContracts);
    }
}