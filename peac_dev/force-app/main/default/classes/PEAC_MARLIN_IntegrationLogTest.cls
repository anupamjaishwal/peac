/**
 * Class Name : PEAC_MARLIN_IntegrationLogTest
 * Description: Used to provide rest coverage for PEAC_MARLIN_IntegrationLog
 *
 * Author: Manish Suwalka
 * Date: 08-05-2026
 */
@IsTest
public class PEAC_MARLIN_IntegrationLogTest {

    @IsTest
    static void testLogException_NoDML() {
        
        Test.startTest();

        // Call method under test
        MARLIN_IntegrationLog.LogException(
            'TestIntegration',
            '006000000000001AAA',
            'Failure',
            'Sample Request Message',
            'Sample Response Message',
            'ERR-500',
            'Something went wrong'
        );

        Test.stopTest();
    }


    @IsTest
    static void testLogExceptionAsynch_NoDML() {


        Test.startTest();

        // Call the @future method
        MARLIN_IntegrationLog.LogExceptionAsynch(
            'TestIntegration',
            '006000000000001AAA',
            'Failure',
            'Sample Request',
            'Sample Response',
            'ERR-500',
            'Async error'
        );
        Test.stopTest();

    }

    
    /* ----------------------------------------------------------
     * Test: startDurationTimer()
     * ---------------------------------------------------------- */
    @IsTest
    static void testStartDurationTimer() {

        Test.startTest();
        MARLIN_IntegrationLog.startDurationTimer();
        Test.stopTest();

        // ✅ Cannot assert exact CPU time, just ensure no exception
    }

    /* ----------------------------------------------------------
     * Test: endDurationTimer()
     * ---------------------------------------------------------- */
    @IsTest
    static void testEndDurationTimer() {

        Test.startTest();
        MARLIN_IntegrationLog.startDurationTimer();
        MARLIN_IntegrationLog.endDurationTimer();
        Test.stopTest();
    }

    /* ----------------------------------------------------------
     * Test: addLog() - normal message (NO file creation)
     * ---------------------------------------------------------- */
    @IsTest
    static void testAddLog_NormalMessage() {

        Test.startTest();

        MARLIN_IntegrationLog.startDurationTimer();
        MARLIN_IntegrationLog.endDurationTimer();

        MARLIN_IntegrationLog.addLog(
            'TestIntegration',
            '006000000000001AAA',
            'Success',
            'Short request',
            'Short response',
            null,
            null
        );

        Test.stopTest();
    }

    /* ----------------------------------------------------------
     * Test: addLog() - oversize request triggers createLogFile()
     * ---------------------------------------------------------- */
    @IsTest
    static void testAddLog_LargeRequestMessage() {

        // Create >131070 chars string
        String largeRequest = 'A'.repeat(131071);
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        Opportunity o = makeOpp('Opp-01', false, PEAC_ConstantClass.OPPORTUNITY_STAGENAME_BOOKING,
                                0.0, 0.0, DateTime.now(), (Date)null, 0.0, (String)null, false, false,0.0);

        Test.startTest();

        MARLIN_IntegrationLog.startDurationTimer();
        MARLIN_IntegrationLog.endDurationTimer();

        MARLIN_IntegrationLog.addLog(
            'LargePayloadIntegration',
            o.Id,
            'Failure',
            largeRequest,
            'Response',
            '500',
            'Big payload error'
        );

        Test.stopTest();
    }
    private static Opportunity makeOpp(
        String name,
        Boolean loanRecordType,
        String stage,
        Decimal totalPaymentsSent,
        Decimal totalPaymentsSentLoan,
        DateTime bookedDt,
        Date commencementDt,
        Decimal floridaSum,
        String purchaseOptions,
        Boolean readyToDoc,
        Boolean manualFunding,
        Decimal secDeposit
    ) {
        Opportunity o = new Opportunity(
            Name = name,
            StageName = stage,
            Opportunity_Booked_Date__c = bookedDt,
            Commencement_Date__c = commencementDt,
            Purchase_Options__c = purchaseOptions,
            Ready_to_Doc__c = readyToDoc ? PEAC_ConstantClass.Yes : PEAC_ConstantClass.No,
            Manual_Funding__c = manualFunding,
            Security_Deposit__c = secDeposit,
            closeDate = DateTime.now().Date()
        );
        Account acc = TestDataFactory.createTestAccount();
        Contact con = TestDataFactory.createTestContact(acc.Id);
        Opportunity opp = TestDataFactory.createTestOpp(acc.Id);
        return opp;
    }

}