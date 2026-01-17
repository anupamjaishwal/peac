@isTest
public class SL_DelayedEmailTest {
    @isTest
    static void getOWEmailAddresses(){
        SL_SCTestData.createAccountAndContracts(1, 1);
        String result;
        Test.startTest();
        result = SL_DelayedEmail.hubExecute('getOWEmailAddresses', new List<String>{SL_SCTestData.testContracts[0].Id});
        Test.stopTest();
        System.assert(result.length() > 0);
    }

    @isTest
    static void getToAddress(){
        SL_SCTestData.createAccountAndContracts(1, 1);
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        c.Email = 'marlinbusiness@silverlinecrm.com';
        update c;
        String positiveResult;
        String negativeResult;
        Test.startTest();
        positiveResult = SL_DelayedEmail.hubExecute('getToAddress', new List<String>{c.Id});
        negativeResult = SL_DelayedEmail.hubExecute('getToAddress', new List<String>{null});
        Test.stopTest();
        System.assert(positiveResult.contains('{"toAddress": "'));
        System.assert(negativeResult.contains('{"error": "'));
    }


    @isTest
    static void getScheduledQBs(){
        SL_SCTestData.createAccountAndContracts(1, 1);
        Contact contact = SL_SCTestData.testContacts[0];
        OrgWideEmailAddress owea = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = :'noreply@peacsolutions.com'][0];
        Integer jobsBefore = [SELECT COUNT() FROM crontrigger WHERE CronJobDetail.Name LIKE 'Buyout Email for Contract Id: %' AND State!='DELETED'];
        Id templateId = [SELECT Id FROM EmailTemplate WHERE Folder.DeveloperName='DelayedBuyouts' LIMIT 1][0].Id;
        contact.email = 'marlinbusiness@silverlinecrm.com';
        update contact;
        SL_SCTestData.testNow = Datetime.newInstance(2022, 11, 9, 9, 0, 0);
        System.runAs(SL_SCTestData.testUser) {
            SL_DelayedEmail.hubExecute('scheduleDelivery', new String[]{
                owea.Address,
                'marlinbusiness@silverlinecrm.com',
                contact.Id,
                templateId,
                SL_SCTestData.testContracts[0].Id,
                'fileName.pdf',
                'fileBody'
            });            
        }
      
        List<EmailMessage> mails = [SELECT Id FROM EmailMessage];
        String result1, result2;
        Test.startTest();
        result1 = SL_DelayedEmail.hubExecute('getScheduledQBs', new String[]{
            SL_SCTestData.testContracts[0].Id
        });
        result2 = SL_DelayedEmail.hubExecute('cancelScheduledQB', new String[]{
            SL_SCTestData.testContracts[0].Id,
            mails[0].Id
        });
        Test.stopTest();

        //System.assertEquals(Datetime.newInstance(2022, 11, 14, 8, 0, 0), toCheckTime[0].NextFireTime);
    }
}