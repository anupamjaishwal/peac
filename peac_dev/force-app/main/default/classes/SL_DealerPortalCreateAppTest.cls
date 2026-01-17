@isTest
public with sharing class SL_DealerPortalCreateAppTest {
    @isTest
    public static void getAccountByDUNS() {
        String dunsNumber = '987654321';
        SL_SCTestData.createAccountAndContracts(3, 1);
        Account acc = SL_SCTestData.testAccounts[0];
        acc.DUNS__c = dunsNumber;
        SL_SCTestData.testAccounts[1].Business_Address__c = '23 street';
        update SL_SCTestData.testAccounts;
        Profile portalProfileCTI = [SELECT Id, UserLicense.Name
        FROM Profile WHERE Name = 'CT&I Dealer' AND UserLicense.Name = 'Partner Community' LIMIT 1];
        
        String result1 = '', result2 = '', result3 = '';
        Test.startTest();
        result1 = SL_DealerPortalCreateApp.hubExecute('getAccountByDUNS', new List<String>{dunsNumber, '', '', '23 street',
            '', '', '', '', '0', '', '23 street',''});
        result2 = SL_DealerPortalCreateApp.hubExecute('getAccountByDUNS', new List<String>{'876543210', '', 'different test Customer', '23 street',
            '', 'Alaska', '', '', '0', '', '23 street',''});// why Texas ?
        result3 = SL_DealerPortalCreateApp.hubExecute('getAccountByDUNS', new List<String>{'876543210', '', '3 test Customer', '23 street',
            '', 'Alaska', '', '', '0', '', '23 street',''});
        SL_DealerPortalCreateApp.upsertAccountForApp(SL_SCTestData.testAccounts);
        Account notFoundAcc = SL_SCTestData.testAccounts[2];
        notFoundAcc.Tax_ID__c = '';
        notFoundAcc.Name = 'different name to have a new one';
        notFoundAcc.Business_Phone__c = '0116031793';
        notFoundAcc.Legal_Entity_Name__c = notFoundAcc.Name;
        SL_DealerPortalCreateApp.upsertAccountForApp(new List<Account>{notFoundAcc});
        Test.stopTest();
        system.debug(result1);
        System.Assert.isTrue(result1.contains(String.valueOf(acc.Id)));
        System.Assert.isFalse(result2.contains(',"Id":'), 'it Should be a new Account');
        System.Assert.isTrue(result3.contains(',"Id":'), 'it should bring the Account Id found');
        System.Assert.isTrue(result3.contains(String.valueOf(SL_SCTestData.testAccounts[2].Id)));
    }

    @isTest
    public static void upsertContactForApp() {
        SL_SCTestData.createAccountAndContracts(2, 1);
        Account acc = SL_SCTestData.testAccounts[0];
        Account acc2 = SL_SCTestData.testAccounts[1];
        Profile portalProfileCTI = [SELECT Id, UserLicense.Name
            FROM Profile WHERE Name = 'CT&I Dealer' AND UserLicense.Name = 'Partner Community' LIMIT 1];
        User u = null;
        // u.Id = null;
        // u.Email = 'test.partner.user.upsertContactForApp@email.box';
        // u.Username = 'test.partner.user.upsertContactForApp20230817@email.box';
        // u.ProfileId = portalProfileCTI.Id;
        // u.CommunityNickname = 'upsertContactForApp20230817';
        // u.ContactId = SL_SCTestData.testContacts[0].Id;
        // System.runAs(SL_SCTestData.testUser){
        //     Id userId = Site.createExternalUser(u, acc.Id);
        // }
        System.runAs(SL_SCTestData.testUser){
            Account portalAccount = acc;
            u = SL_SCTestData.createDPDataForUser(portalAccount);
        }
        String result1 = '', result2 = '';
        System.runAs(u){
            Test.startTest();
            SL_DealerPortalCAContact.upsertContactForApp(new List<Contact>{SL_SCTestData.testContacts[1]});
            Test.stopTest();
        }
        
        // System.Assert.areEqual(acc.Id, Id.valueOf(result1));
        // System.Assert.areEqual('', result2);
    }
    
    @isTest
    public static void shareOppWithUser() {
        SL_SCTestData.createAccountAndContracts(3, 1);
        Account acc = SL_SCTestData.testAccounts[0];
        Account acc2 = SL_SCTestData.testAccounts[1];
        Account manufacturer = SL_SCTestData.setManufacturerData(SL_SCTestData.testAccounts[2]);
        Profile portalProfileCTI = [SELECT Id, UserLicense.Name
            FROM Profile WHERE Name = 'CT&I Dealer' AND UserLicense.Name = 'Partner Community' LIMIT 1];
        User u = SL_SCTestData.testUser;
        //u.Id = null;
        u.Email = 'test.partner.user.upsertContactForApp@email.box';
        u.Username = 'test.partner.user.upsertContactForApp20230817@email.box';
        u.ProfileId = portalProfileCTI.Id;
        u.CommunityNickname = 'upsertContactForApp20230817';
        u.ContactId = SL_SCTestData.testContacts[0].Id;
        //Id userId = Site.createExternalUser(u, acc.Id);
        acc2.OwnerId = u.Id;
        update new List<Account>{acc2, manufacturer};
        SL_SCTestData.manufacturerId = manufacturer.Id;
        String result1 = '', result2 = '';
        System.runAs(u){
            SL_SCTestData.createOpportunitiesAndAssets(acc2.Id, 1, 1);
            SL_SCTestData.testOpportunities[0].OwnerId = u.Id;
            update SL_SCTestData.testOpportunities[0];
            Test.startTest();
            try{
                SL_DealerPortalCAOppInfo.shareOppWithUser(SL_SCTestData.testOpportunities);
            }catch(Exception e){

            }
            Test.stopTest();
        }
        
        // System.Assert.areEqual(acc.Id, Id.valueOf(result1));
        // System.Assert.areEqual('', result2);
    }

    @isTest
    public static void opportunityAttachment() {
        SL_SCTestData.createAccountAndContracts(2, 1);
        Account acc = SL_SCTestData.testAccounts[0];
        Account acc2 = SL_SCTestData.testAccounts[1];
        SL_SCTestData.createOpportunitiesAndAssets(acc.Id, 1, 1);
        Opportunity opp = SL_SCTestData.testOpportunities[0];
        Opportunity_Attachment__c oppAttachment = new Opportunity_Attachment__c(Opportunity__c = opp.Id, Type__c = 'CR - Credit Application');
        insert oppAttachment;
        Attachment attachment = new Attachment();
        attachment.body = EncodingUtil.base64Decode(EncodingUtil.urlDecode('fileBody', 'UTF-8'));
        attachment.name = 'test fileName';
        attachment.parentId = oppAttachment.Id;
        insert attachment;
        String result1 = '', result2 = '', result3 = '', result4 = '', result5 = '';
        Test.startTest();
        result1 = SL_DealerPortalCAAttachment.hubExecute('updateOppAttachment', new List<String>{oppAttachment.Id, attachment.Id});
        result2 = SL_DealerPortalCAAttachment.hubExecute('getOppAttachments', new List<String>{opp.Id});
        result3 = SL_DealerPortalCAAttachment.hubExecute('createAttachment', new List<String>{oppAttachment.Id, 'test fileName', EncodingUtil.base64Encode(Blob.valueOf('fileBody'))});
        result4 = SL_DealerPortalCAAttachment.hubExecute('appendChunk', new List<String>{result3, EncodingUtil.base64Encode(Blob.valueOf('a'.repeat(4000000))), '2', 'true'});
        result5 = SL_DealerPortalCAAttachment.hubExecute('appendChunk', new List<String>{result3, EncodingUtil.base64Encode(Blob.valueOf('a'.repeat(2000000))), '2', 'true'});
        Test.stopTest();
        Opportunity_Attachment__c oppAttAfter = ((List<Opportunity_Attachment__c>)JSON.deserialize(result1, List<Opportunity_Attachment__c>.class))[0];
        System.Assert.areEqual(oppAttachment.Id, oppAttAfter.Id);
        System.Assert.isTrue(result2.contains('Opportunity_Attachment__c'));
    }
    @isTest
    public static void submitGDSOnApp() {
        Marlin_Configuration__c config = new Marlin_Configuration__c(Loan_Salary_Amount__c = 231, Lease_Salary_Amount__c = 71, Loan_Operating_Expense_Amount__c = 27, Lease_Operating_Expense_Amount__c = 0);
        insert config;
        insert new Quick_App_Settings__c (Broker_Record_Type_Label__c = 'Broker Account'
                                              , CCG_Junction_Record_Type_Label__c = 'Corporate'
                                              , Dealer_Record_Type_Label__c = 'Dealer Account'
                                              , End_User_Record_Type_Label__c = 'End User Account'
                                              , Franchiosor_Record_Type_Label__c = 'Franchisor Account'
                                              , PG_Junction_Record_Type_Label__c = 'Personal');
        SL_SCTestData.createAccountAndContracts(2, 1);
        Account acc = SL_SCTestData.testAccounts[0];
        Account acc2 = SL_SCTestData.testAccounts[1];
        SL_SCTestData.createOpportunitiesAndAssets(acc.Id, 2, 1);
        List<Opportunity> opps = SL_SCTestData.testOpportunities;
        // insert new Guarantor__c(Opportunity__c = opps[1].Id, Contact__c = SL_SCTestData.testContacts[1].Id); cannot do this unless the soql limit problem gets fixed
        Test.startTest();
        SL_DealerPortalCAGDSScore.submitAppForGDSScore(new List<Opportunity>{opps[0]});
        // TC_DwhStoredProcedureRespBean respBean = new TC_DwhStoredProcedureRespBean();
        // TC_DwhStoredProcedureRespBean.resultBean resultBean = new TC_DwhStoredProcedureRespBean.resultBean();
        // resultBean.CustomerType = 'EXISTING';
        // resultBean.BizInfoMatch = '10';
        // resultBean.RunNewCustomerFlow = '0';
        // resultBean.DealerDistance = 1;
        // respBean.results.add(resultBean);

        // GoogleGeoCodeResponse geoCodeResp = new GoogleGeoCodeResponse();
        // GoogleGeoCodeResponse.Result res = new GoogleGeoCodeResponse.Result();
        // GoogleGeoCodeResponse.Location location = new GoogleGeoCodeResponse.Location();
        // location.lat = '37.52132';
        // location.lng = '-123.12312';
        // res.geometry.location = location;
        // geoCodeResp.results = new List<GoogleGeoCodeResponse.Result> { res };



        // List<TC_LoanApplicationCtrlTest.MockCallOutDefinition> defList = new List<TC_LoanApplicationCtrlTest.MockCallOutDefinition>();
        // defList.add(new TC_LoanApplicationCtrlTest.MockCallOutDefinition(new Map<String, String> {'Content-Type' => 'JSON'}, JSON.serialize(respBean), 200));
        // defList.add(new TC_LoanApplicationCtrlTest.MockCallOutDefinition(new Map<String, String> {'Content-Type' => 'JSON'}, JSON.serialize(geoCodeResp), 200));
        // defList.add(new TC_LoanApplicationCtrlTest.MockCallOutDefinition(new Map<String, String> {'Content-Type' => 'JSON'}, JSON.serialize(geoCodeResp), 200));
        // defList.add(new TC_LoanApplicationCtrlTest.MockCallOutDefinition(new Map<String, String> {'Content-Type' => 'JSON'}, JSON.serialize(respBean), 200));

        
        // Test.setMock(HttpCalloutMock.class,  new TC_LoanApplicationCtrlTest.MockCallOut(defList));
        System.enqueueJob(new SL_DealerPortalCreateAppQ('callDwhAndAutoPgApi', opps[1], true));// replace with the line below if we can insert guarantors
        // SL_DealerPortalCAGDSScore.submitAppForGDSScore(new List<Opportunity>{opps[1]});
        System.enqueueJob(new SL_DealerPortalCreateAppQ('lastUpdateToApp', opps[1], true));
        Test.stopTest();
        // System.Assert.areEqual(oppAttachment.Id, oppAttAfter.Id);
    }
    @isTest
    public static void EmailDupeCheckTest(){
        SL_SCTestData.createAccountAndContracts(2,1);
        List<Contact> testCon = new List<Contact>();
        List<Contact> result;
        testCon.add(SL_SCTestData.testContacts[1]);
        SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[1].Id, 1, 1);
        Test.startTest();
        SL_DealerPortalContactDupeCheck.EmailDuplicateCheck(testCon);
        List<Guarantor__c> guarantorsCreated = new List<Guarantor__c>();
        List<SL_DealerPortalCAGuarantor.CreateGuarantorContactParameters> parameters = new List<SL_DealerPortalCAGuarantor.CreateGuarantorContactParameters>();
        SL_DealerPortalCAGuarantor.CreateGuarantorContactParameters parameterObj = new SL_DealerPortalCAGuarantor.CreateGuarantorContactParameters();
        parameterObj.theOpportunityId = SL_SCTestData.testOpportunities[0].Id;
        parameterObj.guarantorContact = testCon[0];
        parameters.add(parameterObj);
        Id accId = SL_SCTestData.testAccounts[0].Id;
        User dpUser = null;
        // System.runAs(SL_SCTestData.testUser){
        //     dpUser = SL_SCTestData.createDPUser(accId);
        // }
        System.runAs(SL_SCTestData.testUser){
            Account portalAccount = SL_SCTestData.testAccounts[0];
            dpUser = SL_SCTestData.createDPDataForUser(portalAccount);
        }
        System.runAs(dpUser){
            guarantorsCreated = SL_DealerPortalCAGuarantor.createGuarantorContact(parameters);
        }
        Integer contactsCreated = [SELECT COUNT() FROM Contact];
        System.Assert.areEqual(3, contactsCreated, 'must used the existing dupe');// 3 contacts already exist as prep data
        Contact c = new Contact (AccountId = accId, FirstName = 'new test',
                 LastName = 'testbeni new', OtherStreet = 'test new', OtherCity = 'test', 
                 OtherStateCode = 'MN', OtherPostalCode = '05030', Title = 'title new', 
                 SSN__c = '050305251', BirthDate = Date.today (),
                 Email = 'test@email05030525.com', Validity_Verify__Status__c = 'Valid');
        parameters.clear();
        parameterObj.guarantorContact = c;
        parameters.add(parameterObj);
        guarantorsCreated = SL_DealerPortalCAGuarantor.createGuarantorContact(parameters);
        Opportunity opp = SL_SCTestData.testOpportunities[0].clone(false,false,false);
        List<Opportunity> createdOpp = SL_DealerPortalCAAllowSave.updateOpp(new List<Opportunity>{opp});
        SL_DealerPortalCAAllowSave.updateOpp(createdOpp);
        Test.stopTest();
        contactsCreated = [SELECT COUNT() FROM Contact];
        System.Assert.areEqual(4, contactsCreated, 'must insert a second one');
        System.Assert.areEqual(1, guarantorsCreated.size(), 'must create a guarantor anyways');
        
    }

}