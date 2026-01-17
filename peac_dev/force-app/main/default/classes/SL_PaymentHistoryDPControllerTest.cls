@isTest
public class SL_PaymentHistoryDPControllerTest {

    @isTest
    static void testSendPaymentsToApex() {
        Test.startTest();

        List<Map<String, Object>> payments = new List<Map<String, Object>>();
        Map<String, Object> payment1 = new Map<String, Object>();
        payment1.put('PymtKey', '12345'); // Simulated key for test mode
        payments.add(payment1);

        String result = SL_PaymentHistoryDPController.sendPaymentsToApex(payments, true, 1);
        Test.stopTest();

        if (String.isNotBlank(result)) {
            Map<String, Object> resultObj = (Map<String, Object>)JSON.deserializeUntyped(result);
            List<Object> processedPayments = (List<Object>)resultObj.get('processedPayments');

            if (!processedPayments.isEmpty()) {
                Map<String, Object> processedPayment1 = (Map<String, Object>) processedPayments[0];
                // You can add assertions here if needed
            }
        }
    }
}