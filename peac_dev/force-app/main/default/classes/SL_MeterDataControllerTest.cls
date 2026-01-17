/**
 * Tests for SL_MeterDataController 
 */
@IsTest(SeeAllData=true)
public with sharing class SL_MeterDataControllerTest {

    @IsTest
    static void getMeterReadDataTest(){
        String result = '';
		String dealer = '000111222333';
        User user = [SELECT Id, Name FROM User WHERE Profile.Name='OEG Dealer' AND isActive=true LIMIT 1];
        Test.startTest();
        system.runAs(user) {
            result = SL_MeterDataController.getMeterReadData(dealer);
            }
        Test.stopTest();
        System.debug('RESULT '+result);
        Assert.isTrue(result != '');
        
    }


    @IsTest
    static void dwCSVtoJsonTest(){
        List<String> CSVfieldName= new List<String>{'ContractNo','MeterAcct','Method','ReadCycle','NextRead','Descrip','Serial', 'PrevRead', 'CurrentReadValue', 'CopyCreditsCount', 'DealerInvoiceNumber', 'CustName', 'Asset', 'ReadDate', 'ShortDesc'}; 

        String base64 = '77u/Q29udHJhY3QgTm8uLE1ldGVyIEFjY291bnQsUmVhZGluZyBNZXRob2QsUmVhZCBEYXRhLFJlYWRpbmcgRGF0ZSxEZXNjcmlwdGlvbixTZXJpYWwgTm8uLFByaW9yIFJlYWRpbmcsQ3VycmVudCBSZWFkIFZhbHVlLENvcHkgQ3JlZGl0cyBDb3VudCxEZWFsZXIgSW52b2ljZSBOdW1iZXIsQ3VzdG9tZXIgTmFtZSxBc3NldCBJRCxQcmlvciBSZWFkaW5nIERhdGUsTWV0ZXIgVHlwZQoiNDAxLTEzOTYyMzEtMDAxIiwiIiwsIlF1YXJ0ZXJseSIsIjIwMjMtMDQtMDUiLCJCVyIsIlI0VjI3Mzc0NDkiLCIyNzUwLjAwIiwsLCwiQnVybnMgTW90b3JzIExURCIsIjQwMDI3NTEiLCIyMDIzLTA0LTA0IiwiQlciCiI0MDEtMTM5NjIzMS0wMDEiLCIiLCwiUXVhcnRlcmx5IiwiMjAyMy0wNC0wNSIsIkNPTCIsIlI0VjI3Mzc0NDkiLCIzNTAwLjAwIiwsLCwiQnVybnMgTW90b3JzIExURCIsIjQwMDI3NTEiLCIyMDIzLTA0LTA0IiwiQ09MIgoiNDAxLTEzOTYyMzEtMDAxIiwiIiwsIlF1YXJ0ZXJseSIsIjIwMjMtMDQtMDUiLCJCVyIsIlI0VjI3Mzc0NDkiLCIyNzUwLjAwIiwsLCwiQnVybnMgTW90b3JzIExURCIsIjQwMDI3NTEiLCIyMDIzLTA0LTA0IiwiQlciCiI0MDEtMTM5NjIzMS0wMDEiLCIiLCwiUXVhcnRlcmx5IiwiMjAyMy0wNC0wNSIsIkNPTCIsIlI0VjI3Mzc0NDkiLCIzNTAwLjAwIiwsLCwiQnVybnMgTW90b3JzIExURCIsIjQwMDI3NTEiLCIyMDIzLTA0LTA0IiwiQ09MIgoiNDAxLTEzOTYyMzEtMDAxIiwiIiwsIlF1YXJ0ZXJseSIsIjIwMjMtMDQtMDUiLCJCVyIsIlI0VjI3Mzc0MzEiLCIzNjAwLjAwIiwsLCwiQnVybnMgTW90b3JzIExURCIsIjQwMDI3NTIiLCIyMDIzLTA0LTA0IiwiQlciCiI0MDEtMTM5NjIzMS0wMDEiLCIiLCwiUXVhcnRlcmx5IiwiMjAyMy0wNC0wNSIsIkNPTCIsIlI0VjI3Mzc0MzEiLCIxODAwLjAwIiwsLCwiQnVybnMgTW90b3JzIExURCIsIjQwMDI3NTIiLCIyMDIzLTA0LTA0IiwiQ09MIgoiNDAxLTEzOTYyMzEtMDAxIiwiIiwsIlF1YXJ0ZXJseSIsIjIwMjMtMDQtMDUiLCJCVyIsIlI0VjI3Mzc0MzEiLCIzNjAwLjAwIiwsLCwiQnVybnMgTW90b3JzIExURCIsIjQwMDI3NTIiLCIyMDIzLTA0LTA0IiwiQlciCiI0MDEtMTM5NjIzMS0wMDEiLCIiLCwiUXVhcnRlcmx5IiwiMjAyMy0wNC0wNSIsIkNPTCIsIlI0VjI3Mzc0MzEiLCIxODAwLjAwIiwsLCwiQnVybnMgTW90b3JzIExURCIsIjQwMDI3NTIiLCIyMDIzLTA0LTA0IiwiQ09MIg==';
        String result = '';
        Test.startTest();
        result = SL_MeterDataController.dwCSVtoJson(base64);
        Test.stopTest();
        System.debug('RESULT '+result);
        Assert.isTrue(result != '');
        for(String field : CSVfieldName)
        {
            Assert.isTrue(result.contains(field));
        }
        
    }


    @IsTest
    static void sendMeterFileTest(){

        String csv = 'CSV';
        Test.startTest();
        SL_MeterDataController.sendMeterFile(csv, '000111222333');
        Test.stopTest();        
    }

    @IsTest
    static void getLogFilesTest(){
        String result = '';
        User user = [SELECT Id, Name FROM User WHERE Profile.Name='OEG Dealer' AND isActive=true LIMIT 1];
        Test.startTest();
        system.runAs(user) {
             SL_MeterDataController.getLogFiles('000111222333', 'MISC');
            }
        Test.stopTest();

    }


    @IsTest
    static void generateFileLinkTest(){
        User user = [SELECT Id, Name FROM User WHERE Profile.Name='OEG Dealer' AND isActive=true LIMIT 1];
        String fileName = 'testFile.pdf';
        Test.startTest();
        system.runAs(user) {
        SL_MeterDataController.generateFileLink(fileName, '000111222333', 'MISC');
        }
        Test.stopTest();        
    }
}