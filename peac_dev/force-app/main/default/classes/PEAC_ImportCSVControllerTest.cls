/**************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This test class is used to import csv file into Salesforce records
@User Story:SAL-5080
@Created Date:January-24-2025
**************************************************************************************************************/

@isTest
private class PEAC_ImportCSVControllerTest {

    Static String str = 'Asset_Description__c,Model__c,Serial_Number__c,List_Price__c,Quantity__c,New_Used__c,Equipment_Code__c,Equipment_Sub_Category__c,Residual_Percentage__c,End_User_Billing_Address__c,Equipment_Street__c,Equipment_Address_2__c,Equipment_City__c,Equipment_State__c,Equipment_Zip__c\n'
				+'Test Asset,New Model,2342324,2300.00,1,New,Automotive Equipment (General),Automotive (General),10,TRUE,Jacone Drive,,Indianapolis,IN,46204';
        
	@testSetup
    static void prepareData()
    {
        SL_SCTestData.createBridgeWareSetting();
     Account acc = new Account (Name = 'testbeni', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId(), Business_Phone__c = '1234567890');
        insert acc;
        
        Contact c = new Contact (AccountId = acc.Id, FirstName = 'test', LastName = 'testbeni', OtherStreet = 'test', OtherCity = 'test', OtherStateCode = 'MN', OtherPostalCode = '11111', Title = 'title', SSN__c = '111111111', BirthDate = Date.today (), Email = 'test@test.com');
        insert c;
        
        insert new Beneficial_Owner__c (Account__c = acc.Id, Contact__c = c.Id, Ownership_Percent__c = 50);

        Test.startTest();
        Opportunity opp = new Opportunity (AccountId = acc.Id
                                           , StageName = 'Quote'
                                           , CloseDate = date.today () + 10
                                           , Name = 'test');

        
        insert opp;
        Test.stopTest(); 
    }
    static testmethod void saveFileTest(){
		
        List<opportunity> oppList = [SELECT ID FROM Opportunity limit 1];
        Test.setMock(HttpCalloutMock.class, new TC_BridgewareSelectZipGeoCalloutMockImpl ());
        TC_BridgewareService service = new TC_BridgewareServiceImpl ();
        
        Test.startTest();       
		PEAC_ImportCSVController.saveFile(JSON.serialize(str),oppList[0].Id, 'Asset__c','Opportunity__c');
		Test.stopTest();
        List<Asset__c> assetList = [SELECT ID FROM Asset__c LIMIT 1];
        Assert.areEqual(assetList.size(), 1, 'There is no asset created on opportunity.');// Positive test case 
        
        String toAddress = 'marlintest@peacsolutions.com'; 
        String status = 'Success';
        List<String> failedAssetList = new List<String>();
        Integer successCount = 1;
        Integer failedCount = 1;
        PEAC_SelectZipGeoCodeBatch batchJob1 = New PEAC_SelectZipGeoCodeBatch(assetList);
        PEAC_SelectZipGeoCodeBatch.sendToUserMail(toAddress,  status, failedAssetList, successCount, failedCount);
        
    }
}