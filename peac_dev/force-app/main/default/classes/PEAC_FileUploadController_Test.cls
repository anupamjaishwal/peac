/**************************************************************************************************************
@Author:D Balakrishna(LTIMindtree)
@Description:Working Test Class aligned with PEAC_FileUploadController.saveXlsxToContractStrict implementation.
@User Story:SL-2897
@Created Date:December-02-2025
**************************************************************************************************************/
@IsTest
private class PEAC_FileUploadController_Test {
	@TestSetup
    static void setupData() {
        // Factory may do User/PermSet DML; isolate it in @testSetup to avoid mixed DML later.
        SL_SCTestData.createAccountAndContracts(1, 1);
    }
    
    @IsTest
    static void test_success_plainBase64() {
        
        Contract__c c = [SELECT Id, Name FROM Contract__c LIMIT 1];

        String b64 = EncodingUtil.base64Encode(Blob.valueOf('hello-xlsx'));

        Test.startTest();
        PEAC_FileUploadController.SaveFileResult res =
            PEAC_FileUploadController.saveXlsxToContractStrict(c.Id, b64);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, res, 'Result should not be null');
        System.assertNotEquals(null, res.contentDocumentId, 'ContentDocumentId should be set');
        System.assertNotEquals(null, res.downloadUrl, 'downloadUrl should be set');
        System.assert(res.fileName.endsWith('.xlsx'), 'File name should end with .xlsx');
        System.assertEquals(c.Name, res.usedPrefix, 'Prefix should match Contract__c.Name');

        // Verify ContentVersion exists and linked
        ContentVersion cv = [
            SELECT Id, ContentDocumentId, Title, PathOnClient, ContentSize
            FROM ContentVersion
            WHERE ContentDocumentId = :res.contentDocumentId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals(res.fileName, cv.PathOnClient, 'PathOnClient should match returned filename');
        System.assertEquals(res.fileName, cv.Title, 'Title should match returned filename');

        // Verify ContentDocumentLink exists (without strict ID comparison)
        List<ContentDocumentLink> cdlList = [
            SELECT Id, LinkedEntityId, ShareType, Visibility
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :res.contentDocumentId
            LIMIT 1
        ];
        System.assert(!cdlList.isEmpty(), 'ContentDocumentLink should exist');
        ContentDocumentLink cdl = cdlList[0];
        System.assertEquals('AllUsers', cdl.Visibility, 'Visibility should be AllUsers');
    }

    @IsTest
    static void test_invalidBase64_throws() {
        Contract__c c = [SELECT Id FROM Contract__c LIMIT 1];
        try {
            Test.startTest();
            PEAC_FileUploadController.saveXlsxToContractStrict(c.Id, 'NOT_BASE64!!!');
            Test.stopTest();
            System.assert(false, 'Expected exception for invalid base64');
        } catch (Exception e) {
            System.assert(e.getMessage() != null, 'Should provide an error message for invalid base64');
        }
    }

    @IsTest
    static void test_nullContractId_throws() {
        String b64 = EncodingUtil.base64Encode(Blob.valueOf('content'));
        // Act + Assert
        try {
            Test.startTest();
            PEAC_FileUploadController.saveXlsxToContractStrict(null, b64);
            Test.stopTest();
            System.assert(false, 'Expected AuraHandledException for null contractId');
        } catch (AuraHandledException ahe) {
            System.assert(true, 'ContractId and file content are required');

        }
    }

    @IsTest
    static void test_blankBase64_throws() {
        Contract__c c = [SELECT Id FROM Contract__c LIMIT 1];

        try {
            Test.startTest();
            PEAC_FileUploadController.saveXlsxToContractStrict(c.Id, '');
            Test.stopTest();
            System.assert(false, 'Expected AuraHandledException for blank base64');
        } catch (AuraHandledException ahe) {
            System.assert(true, 'ContractId and file content are required');
        }
    }

    @IsTest
    static void test_filename_format_uses_prefix_and_now() {
        
        Contract__c c = [SELECT Id, Name FROM Contract__c LIMIT 1];
       
        String b64 = EncodingUtil.base64Encode(Blob.valueOf('xlsx-dummy'));

        Test.startTest();
        PEAC_FileUploadController.SaveFileResult res =
            PEAC_FileUploadController.saveXlsxToContractStrict(c.Id, b64);
        Test.stopTest();

        // Assert: filename starts with prefix and ends with .xlsx
        System.assert(res.fileName.startsWith('MassUpload_' + c.Name + '_'),
            'Filename should start with the contract Name prefix followed by underscore');
        System.assert(res.fileName.endsWith('.xlsx'),
            'Filename should end with .xlsx extension');
    }
}